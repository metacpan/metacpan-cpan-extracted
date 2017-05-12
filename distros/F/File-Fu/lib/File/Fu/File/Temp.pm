package File::Fu::File::Temp;
$VERSION = v0.0.8;

use warnings;
use strict;
use Carp;

=head1 NAME

File::Fu::File::Temp - temporary files

=head1 SYNOPSIS

  use File::Fu;
  my $handle = File::Fu->temp_file;

=cut

use File::Temp ();
# XXX should be File::Fu::Handle;
#use base 'File::Temp';

=head2 new

The directory argument is required, followed by an optional template
argument and/or flags.  The template may contain some number of 'X'
characters.  If it does not, ten of them will be appended.

  my $handle = File::Fu::File::Temp->new($dir, 'foo');
  my $file = $handle->name;

By default, the file will be deleted when the handle goes out of scope.
Optionally, it may be deleted immediately after creation or just not
deleted.

  my $handle = File::Fu::File::Temp->new($dir, 'foo', -secure);

  my $handle = File::Fu::File::Temp->new($dir, -noclean);
  # also $handle->noclean;

=over

=item -secure

Delete the named file (if the OS supports it) immediately after opening.

Calling name() on this sort of handle throws an error.

=item -nocleanup

Don't attempt to remove the file when the $handle goes out of scope.

=back

=cut

{
my %argmap = (
  secure => [],
  nocleanup => [UNLINK => 0],
);
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my ($dir, $send, $opt) = $class->_validate(\%argmap, @_);

  my ($self, $fn);
  if($opt->{secure}) {
    $self = File::Temp::tempfile(@$send);
    $class .= '::HasNoFileName';
  }
  else {
    ($self, $fn) = File::Temp::tempfile(@$send);
    ${*$self} = $dir->file_class->new($fn);
  }
  %{*$self} = %$opt;
  bless($self, $class);
  return($self);
}} # end subroutine new definition
########################################################################

=for internal head2 _validate
  my ($dir, $send, $opt) = $class->_validate(\%map, @_);

=cut

sub _validate {
  my $class = shift;
  my %argmap = %{shift(@_)};
  my ($dir, @opt) = @_;
  croak("invalid directory '$dir' ")
    unless(eval {$dir->can('e')} and $dir->e);

  my @send;
  my %opt;
  for(my $i = 0; $i < @opt; $i++) {
    ($opt[$i] =~ s/^-//) or next;
    my ($key) = splice(@opt, $i, 1); $i--;
    my $do = $argmap{$key} or croak("invalid argument '$key'");
    push(@send, @$do);
    $opt{$key} = 1;
  }
  if(@opt) {
    my $template = shift(@opt);
    croak("invalid arguments '@opt'") if(@opt);

    $template .= $class->XXX unless($template =~ m/X/);
    # XXX File::Temp specific
    unshift(@send, $template);
  }
  $opt{auto_delete} = ! delete($opt{nocleanup});

  push(@send, DIR => "$dir");

  return($dir, \@send, \%opt);
} # end subroutine _validate definition
########################################################################

=head2 name

  my $file_obj = $handle->name;

=cut

sub name {
  my $self = shift;
  return(${*$self});
} # end subroutine name definition
########################################################################

=head2 nocleanup

Disable autocleanup.

  $handle->nocleanup;

=cut

sub nocleanup {
  my $self = shift;
  my %opt = %{*$self};
  $opt{auto_delete} = 0;
} # end subroutine nocleanup definition
########################################################################

=head2 write

Write @content to the tempfile and close it.

  $handle = $handle->write(@content);

=cut

sub write {
  my $self = shift;
  my (@content) = @_;
  do {
    local $SIG{__WARN__} = sub { # ugh
      my $x = shift;
      local $Carp::Level = 1;
      if($x =~ m/^print\(\) on closed filehandle/) {
        croak("write() on closed tempfile");
      }
      my $file = __FILE__;
      $x =~ s/ at \Q$file\E .*\n//;
      warn Carp::shortmess($x);
    };
    print $self @content;
  };
  close($self) or croak("write '" . $_->name . "' failed: $!");
  return $self;
} # write ##############################################################

=head2 do

Execute subref with $handle as $_.  If you chain this with the
constructor, the destructor cleanup will happen immediately after sub
has returned.

  my @x = $handle->do(sub {something($_->name); ...});

=cut

sub do {
  my $self = shift;
  my ($sub) = @_;
  local $_ = $self;
  return $sub->();
} # do #################################################################

=head2 DESTROY

Called automatically when the handle goes out of scope.

  $handle->DESTROY;

=cut

sub DESTROY {
  my $self = shift;
  my %opt = %{*$self};
  return if($opt{secure} or ! $opt{auto_delete});
  $self->name->unlink;
} # end subroutine DESTROY definition
########################################################################

=head2 XXX

Constant representing a chunk of X characters.

=cut

use constant XXX => 'X'x10;

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
