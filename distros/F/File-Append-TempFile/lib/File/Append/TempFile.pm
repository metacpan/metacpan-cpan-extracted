package File::Append::TempFile;

use v5.010;
use strict;
use warnings;

=head1 NAME

File::Append::TempFile - Perl extension for appending data to files

=head1 SYNOPSIS

  use File::Append::TempFile;

  $f = new File::Append::TempFile();
  $f->begin_work('/etc/hosts') or die "Appending: ".$f->err();
  $f->add_line("127.0.0.2 localhvost\n");
  $f->commit();

  $f->begin_work('/etc/hosts') or die "Appending: ".$f->err();
  $f->add_line("...\n");
  $f->rollback();

=head1 DESCRIPTION

The C<File::Append::TempFile> module provides an OOP interface to appending
data to files using a temporary file, in order to ensure the atomicity of
the updates.

An append session is initiated by invoking the C<begin_work()> method and
passing it the name of the file.  At this point, a temporary file is
created in the same directory as the original file and the original's
contents is copied to the temporary.  More data is added to the temporary
file using the C<add_line()> method.  When done appending, the C<commit()>
method will atomically move the temporary file over the original.
If something goes wrong, the C<rollback()> method will remove the temporary
file without affecting the original in any way.

=cut

use File::Basename qw(basename dirname);
use File::Temp;

our @ISA = qw();

our $VERSION = '0.07';

our $debug = 0;

my %tempfiles;

=head1 METHODS

The C<File::Append::TempFile> class defines the following methods:

=over 4

=item new ()

Create a new C<File::Append::TempFile> object.  No file processing is
done at this point.

=cut

sub new
{
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $self;

	$self = {
		fname => undef,
		f => undef,
		err => undef,
		debug => undef
	};
	bless $self, $class;
	$tempfiles{$self} = $self;
	return $self;
}

=item err ( [MESSAGE] )

Set or obtain an error message describing the last error that occurred
during the processing of the current C<File::Append::TempFile> object.

=cut

sub err($ $)
{
	my ($self, $err) = @_;

	$self->{err} = $err if @_ > 1;
	return $self->{err};
}

=item diag ([FLAG])

Set or obtain the diagnostic output flag.  If it is set, the methods
will display diagnostic information on the standard error stream.

=cut

sub diag($ $)
{
	my ($self, $debug) = @_;

	$self->{debug} = $debug if @_ > 1;
	return $self->{debug};
}

=item begin_work (FILENAME)

Creates a temporary file in the same directory as the specified one and
copies the original's contents over to the new file.  Further data may
be added using the C<add_line()> method and then either stored as the
original with the C<commit()> method, or discarded with the C<rollback()>
method.

=cut

sub begin_work($ $)
{
	my ($self, $fname) = @_;
	my ($orig, $f);
	my @stat;

	if ($self->{f}) {
		return undef unless $self->rollback();
	}
	$self->{fname} = $self->{f} = undef;

	if (!open $orig, '<', $fname) {
		$self->err("Opening $fname: $!");
		return undef;
	}
	@stat = stat $orig;
	$f = File::Temp->new(basename($fname).'.XXXXXX',
	    DIR => dirname($fname));
	if (!defined $f) {
		$self->err("Creating a temporary file for $fname: $!");
		return undef;
	}
	return undef unless $self->do_copy($orig, $f);
	close $orig;

	$self->{fname} = $fname;
	$self->{f} = $f;
	$self->{stat} = [ @stat ];
	return 1;
}

=item add_line (DATA)

Append data to the temporary file.  This does not affect the original in
any way until C<commit()> is invoked.

=cut

sub add_line($ $)
{
	my ($self, $line) = @_;
	my $f = $self->{f};

	if (!defined $f) {
		$self->err("Cannot add_line() to an unopened tempfile");
		return undef;
	}
	$self->debug("RDBG about to add a line to $f for $self->{fname}\n");
	if (!(print $f $line)) {
		$self->err("Could not add to the tempfile: $!");
		return undef;
	}
	return 1;
}

=item commit ()

Replace the original file with the temporary copy, to which data may have
been added using C<add_line()>.

B<NOTE:> This method uninitializes the C<File::Append::TempFile> object,
that is, removes B<any> association between it and the original file and
even file name!  The next method invoked on this C<File::Append::TempFile>
object should be C<begin_work()>.

=cut

sub commit($)
{
	my ($self) = @_;
	my $f = $self->{f};

	if (!defined $f || !defined $self->{fname}) {
		$self->err("Cannot commit an unopened tempfile");
		return undef;
	}
	$self->debug("RDBG about to commit $f to $self->{fname}\n");

	# Fix stuff up
	if (defined $self->{stat}) {
		# Mode
		if (!chmod $self->{stat}->[2], $f) {
			$self->err("Could not chmod $self->{stat}->[2] ".
			    "$f: $!");
			return undef;
		}
		# Owner & group
		if (!chown $self->{stat}->[4], $self->{stat}->[5], $f) {
			$self->err("Could not chown $self->{stat}->[4], ".
			    "$self->{stat}->[5], $f: $!");
			return undef;
		}
	}
	
	if (!rename $f, $self->{fname}) {
		$self->err("Renaming $f to $self->{fname}: $!");
		return undef;
	}
	$f->unlink_on_destroy(0);
	close $f;
	$self->debug("RDBG successfully committed $f to $self->{fname}\n");
	$self->{fname} = $self->{f} = undef;
	return 1;
}

=item rollback ()

Discard all the changes made to the temporary copy and remove it.  This
does not affect the original file in any way.

B<NOTE:> This method uninitializes the C<File::Append::TempFile> object,
that is, removes B<any> association between it and the original file and
even file name!  The next method invoked on this C<File::Append::TempFile>
object should be C<begin_work()>.

=cut

sub rollback($)
{
	my ($self) = @_;

	$self->debug(ref($self)."->rollback() for $self->{fname}\n");
	if (defined $self->{f}) {
		my $f = $self->{f};
		$self->debug("RDBG closing and removing $f\n");
		$f->unlink_on_destroy(1);
		close $f;
		undef $self->{f};
	}
	undef $self->{fname};
	$self->debug("RDBG rollback seems complete\n");
	return 1;
}

=back

There are also several methods used internally by the
C<File::Append::TempFile> routines:

=over 4

=item debug (MESSAGE)

Display a diagnostic message to the standard error stream if the output
of diagnostic messages has been enabled.

=cut

sub debug($ $)
{
	my ($self, $msg) = @_;

	if ($self->{debug} || $debug) {
		print STDERR $msg;
	}
}

=item do_copy (ORIG TEMP)

Actually perform the copying of the original file data into the temporary
file at C<begin_work()> time.  This allows derived classes to modify
the file structure if needed.

The two parameters are the file handles for the original and the
temporary file.

=cut

sub do_copy($ $ $)
{
	my ($self, $orig, $f) = @_;
	
	while (<$orig>) {
		print $f $_;
	}
	return 1;
}

END
{
	print STDERR "RDBG File::Append::TempFile END block\n" if $debug;
	print STDERR "RDBG ".keys(%tempfiles)."\n" if $debug;
	foreach (keys %tempfiles) {
		$tempfiles{$_}->rollback() if $tempfiles{$_}->{f};
	}
}

=back

=head1 SEE ALSO

The C<File::Append::TempFile> website:

  http://devel.ringlet.net/sysutils/file-append-tempfile/

=head1 BUGS

=over 4

=item * Note that the original file may have changed between C<begin_work()>
and C<commit()> - those changes B<will> be lost!

=back

=head1 AUTHOR

Peter Pentchev, E<lt>roam@ringlet.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2015  Peter Pentchev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
