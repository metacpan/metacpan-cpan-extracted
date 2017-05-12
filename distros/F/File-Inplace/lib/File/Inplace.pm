package File::Inplace;
use strict;

use Carp qw/carp croak/;
use File::Basename qw/dirname/;
use File::Temp qw/tempfile/;
use File::Copy;
use IO::File;
use IO::Handle;

our $VERSION = '0.20';

my @allowed_options = qw/chomp regex separator suffix file/;
my %allowed_options = map { $_ => 1 } @allowed_options;

sub new {
  my $class = shift;
  my %params = @_;

  for my $opt (keys %params) {
    croak "Invalid constructor option '$opt'" unless exists $allowed_options{$opt};
  }
  croak "Required parameter 'file' not specified in constructor"
    unless exists $params{file};

  my $self = bless \%params, $class;

  $params{chomp} = 1 unless exists $params{chomp};
  $params{regex} = $params{regex} || $params{separator} || qr/\s+/;
  $params{separator} ||= ' ';

  if ($self->{suffix}) {
    $self->{backup_name} = $self->{file} . $self->{suffix};
    copy($self->{file} => $self->{backup_name})
      or croak "error creating backup: $!";
  }

  $self->_open_input_file;
  $self->_open_output_file;

  $self->{current_line} = undef;

  return $self;
}

sub has_lines {
  my $self = shift;

  return 1 if not $self->{infh}->eof();
  return 0;
}

sub next_line {
  my $self = shift;

  $self->_write_current_line;

  $self->{current_line} = $self->_read_next_line();

  if (wantarray) {
    if (defined $self->{current_line}) {
      return ($self->{current_line});
    }
    else {
      return ();
    }
  }

  return $self->{current_line};
}

sub next_line_split {
  my $self = shift;

  my $line = $self->next_line;

  return split $self->{regex}, $line;
}

sub all_lines {
  my $self = shift;

  croak "cannot use all_lines after any lines have been read"
    if defined $self->{current_line};

  my @ret;
  while (1) {
    my $line = $self->_read_next_line;
    last unless defined $line;
    push @ret, $line;
  }

  return @ret;
}

sub replace_line {
  my $self = shift;

  if (@_ == 1) {
    $self->{current_line} = shift;
  }
  else {
    $self->{current_line} = join($self->{separator}, @_);
  }
}

sub replace_lines {
  my $self = shift;
  my @lines = @_;

  my $fh = $self->{outfh};
  for my $line (@lines) {
    $fh->print($line);
    if ($self->{chomp}) {
      $fh->print($/);
    }
  }
}

sub _open_input_file {
  my $self = shift;

  $self->{infh} = new IO::File("<$self->{file}");
  croak "open $self->{file}: $!" if not $self->{infh};
}

sub _open_output_file {
  my $self = shift;

  my $dir = dirname $self->{file};
  my ($tmpfh, $tmpname) = tempfile(DIR => $dir);
  $self->{outfh} = bless $tmpfh, "IO::Handle";
  $self->{tmpfile} = $tmpname;
}

sub _write_current_line {
  my $self = shift;

  my $fh = $self->{outfh};
  if (defined $self->{current_line}) {
    $fh->print($self->{current_line});
    if ($self->{chomp}) {
      $fh->print($/);
    }
  }
}

sub _read_next_line {
  my $self = shift;

  my $fh = $self->{infh};
  return undef unless $fh;
  my $line = $fh->getline;
  if (not defined $line) {
    $fh->close;
    delete $self->{infh};
  }

  if (defined $line and $self->{chomp}) {
    chomp $line;
  }

  return $line;
}

sub commit {
  my $self = shift;

  $self->_write_current_line;

  rename $self->{tmpfile} => $self->{file}
    or croak "Can't rename $self->{tmpname} => $self->{file}: $!";

  $self->_close_all();
}

sub commit_to_backup {
  my $self = shift;

  $self->_write_current_line;

  croak "cannot commit_to_backup if no backup file is in use"
    unless $self->{backup_name};

  rename $self->{tmpfile} => $self->{backup_name}
    or croak "Can't rename $self->{tmpname} => $self->{backup_name}: $!";

  $self->_close_all();
}

sub rollback {
  my $self = shift;

  $self->_close_all();
  unlink $self->{tmpfile};
}

sub DESTROY {
  my $self = shift;

  $self->_close_all();
  unlink $self->{tmpfile};
}

sub _close_all {
  my $self = shift;

  for my $handle (qw/infh outfh/) {
    $self->{$handle}->close()
      if $self->{$handle};
  }
}

1;
__END__
=head1 NAME

File::Inplace - Perl module for in-place editing of files

=head1 SYNOPSIS

  use File::Inplace;

  my $editor = new File::Inplace(file => "file.txt");
  while (my ($line) = $editor->next_line) {
    $editor->replace_line(reverse $line);
  }
  $editor->commit;


=head1 DESCRIPTION

File::Inplace is a perl module intended to ease the common task of
editing a file in-place.  Inspired by variations of perl's -i option,
this module is intended for somewhat more structured and reusable
editing than command line perl typically allows.  File::Inplace
endeavors to guarantee file integrity; that is, either all of the
changes made will be saved to the file, or none will.  It also offers
functionality such as backup creation, automatic field splitting
per-line, automatic chomping/unchomping, and aborting edits partially
through without affecting the original file.

=head1 CONSTRUCTOR

File::Inplace offers one constructor that accepts a number of
parameters, one of which is required.

=over 4

=item File::Inplace->new(file => "filename", ...)

=over 4

=item file

The one required parameter.  This is the name of the file to edit.

=item suffix

The suffix for backup files.  If not specified, no backups are made.

=item chomp

If set to zero, then automatic chomping will not be performed.
Newlines (actually, the contents of $/) will remain in strings
returned from C<next_line>.  Additionally, the contents of $/ will not
be appended when replacing lines.

=item regex

If specified, then each line will be split by this parameter when
using C<next_line_split> method.  If unspecified, then this defaults
to \s+.

=item separator

The default character used to join each line when replace_line is
invoked with a list instead of a single value.  Defaults to a single
space.

=back

=head1 INSTANCE METHODS

=item $editor->next_line ()

In scalar context, it returns the next line of the input file, or
undef if there is no line.  In an array context, it returns a single
value of the line, or an empty list if there is no line.

=item $editor->replace_line (value)

Replaces the current line in the output file with the specified value.
If passed a list, then each valie is joined by the C<separator>
specified at construction time.

=item $editor->next_line_split ()

Line C<next_line>, except splits based on the C<regex> specified in
the constructor.

=item $editor->has_lines ()

Returns true if the file contains any further lines.

=item $editor->all_lines ()

Returns an array of all lines in the file being edited.

=item $editor->replace_all_lines (@lines)

Replaces B<all> remaining lines in the file with the specified @lines.

=item $editor->commit ()

Completes the edit operation and saves the changes to the edited file.

=item $editor->rollback ()

Aborts the edit process.

=item $editor->commit_to_backup ()

Saves edits to the backup file instead of the original file.

=back

=head1 AUTHOR

Chip Turner, E<lt>chipt@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Chip Turner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
