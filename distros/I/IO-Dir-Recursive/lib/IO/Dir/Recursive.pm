package IO::Dir::Recursive;

use strict;
use warnings;
use Symbol;
use IO::All;
use IO::Dir qw(DIR_UNLINK);
use File::Spec;

our @ISA = qw(IO::Dir);

our $VERSION = '0.03';

=head1 NAME

IO::Dir::Recursive - IO::Dir working recursive

=head1 SYNOPSIS

  use IO::Dir::Recursive;
  
  my $dh = IO::Dir::Recursive->new('.');
  print "$_\n" while $dh->read();

  tie my %dir, 'IO::Dir::Recursive', '.';
  
  print $dir{subdir1}->{subdir2}->{file}->slurp();

=head1 DESCRIPTION

IO::Dir::Recursive gives IO::Dir the ability to work recursive.

=head1 EXPORT

The following constans may be imported on request.

=over 2

=item * DIR_NOUPWARDS

This constant can be passed as option to tie to strip out parent directories.

=item * DIR_UNLINK

This is inherited from IO::Dir. Deleting an element from the hash will delete
the corresponding file or subdirectory if this constant is passed as a tie
option.

=cut

our @EXPORT_OK = qw(DIR_NOUPWARDS);

sub DIR_NOUPWARDS () { 2 }

=head1 METHODS

IO::Dir::Recursive inherits from IO::Dir and therefor inherits all its methods
with the following exceptions.

=head2 read 

 my $item = $dh->read();

Reads the next item in $dh and returns the coresponding object for the item: an
IO::Dir::Recursive instance for directories, an IO::All instance for files or
undef if there are no other items left.

=cut

sub read {
	my $dh = shift;
	return $dh->_create_io_obj(scalar $dh->_read(@_));
}

=head2 _read

 my $next = $dh->_read();

Same as read() above, but returns a string describing the next item instead of
an object. Mainly for internal use, but maybe it's useful in some other places,
too.

=cut

sub _read {
	my $dh = shift;
	return $dh->SUPER::read();
}

sub _create_io_obj {
	my ($dh, $key) = @_;
	return undef unless $key;
	return $dh if $key eq '.';

	my $file = File::Spec->catdir(${*$dh}{io_dir_path}, $key);
	return IO::Dir::Recursive->new(File::Spec->updir($file)) if $key eq '..';

	if (-d $file) {
		tie my %subdir, 'IO::Dir::Recursive', $file, (${*$dh}{io_dir_unlink} | ${*$dh}{io_dir_noupwards});
		return \%subdir;
	}

	$file = File::Spec->catfile(${*$dh}{io_dir_path}, $key);
	return IO::All->new($file) if -e $file;

	return undef;
}

sub TIEHASH {
	my ($class, $dir, $options) = @_;
	
	my $dh = $class->new($dir) or return undef;
	
	$options ||= 0;

	${*$dh}{io_dir_unlink} = $options & DIR_UNLINK;
	${*$dh}{io_dir_noupwards} = $options & DIR_NOUPWARDS;
	return $dh;
}

sub FIRSTKEY {
	my $dh = shift;
	$dh->rewind();
	my $key = $dh->_read(@_);
	return undef unless defined $key;
	while (${*$dh}{io_dir_noupwards} && defined $key && ($key eq '.' || $key eq '..')) {
		$key = $dh->NEXTKEY(@_);
	}
	return $key;
}

sub NEXTKEY {
	my $dh = shift;
	my $key;
	{
		$key = $dh->_read(@_);
		return undef unless defined $key;
		redo if ${*$dh}{io_dir_noupwards} && ($key eq '.' || $key eq '..');
	}
	return $key;
}

sub FETCH {
	my ($dh, $key) = @_;
	$dh->_create_io_obj($key);
}

1;

=head1 SEE ALSO

L<IO::Dir>, L<IO::All>

=head1 AUTHOR

Florian Ragwitz, E<lt>flora@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Florian Ragwitz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
