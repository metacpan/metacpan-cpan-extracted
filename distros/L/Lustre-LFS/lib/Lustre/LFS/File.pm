#
# PurePerl implementation glue to '/usr/sbin/lfs'
#
# (C) 2010 Adrian Ulrich - <adrian.ulrich@id.ethz.ch>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#

package Lustre::LFS::File;
use strict;
use Lustre::LFS;
use IO::File;
use base 'IO::File';


########################################################################
# Return stripe information for opened file
sub get_stripe {
	my($self) = @_;
	return Lustre::LFS::_parse_get_stripe_file($self);
}

########################################################################
# This is not implemented yet
sub join_objects {
	return undef;
}

########################################################################
# Creates a new file with specified striping parameters
sub lfs_create {
	my($self, %args) = @_;
	my $fname = delete($args{File}) or return undef;
	my $ssize = delete($args{Size});
	my $soff  = delete($args{Offset});
	my $scount= delete($args{Count});
	my $spool = delete($args{Pool});
	
	my @arglist = ("setstripe");
	
	push(@arglist, "--size"  , int($ssize))  if defined $ssize;
	push(@arglist, "--offset", int($soff))   if defined $soff;
	push(@arglist, "--count" , int($scount)) if defined $scount;
	push(@arglist, "--pool"  , $spool)       if defined $spool;
	push(@arglist, "--", $fname);
	
	Lustre::LFS::_lfs_system(@arglist) ||
	$self->open("+> $fname")           &&
	return 1;
	# else
	return 0;
}



1;

__END__

=head1 NAME

Lustre::LFS::File - IO::File like module with lustre support

=head1 SYNOPSIS

  use strict;
  use Lustre::LFS::File;
  
  my $fh = Lustre::LFS::File;
  $fh->open("> some.file") or die;
  print $fh "Hello World!\n";
  my $stripes = $fh->get_stripe;
  $fh->close;
  
=head1 DESCRIPTION

"Lustre::LFS::File" inherits from "IO::File" (which inherits from "IO::Handle"), so 
a C<Lustre::LFS::File> reference can do everything that an "IO::File" ref could do.

=head1 CONSTRUCTOR

=over 4

See C<IO::File> for details.

=back

=head1 METHODS

=over 4

=item get_stripe

Returns striping information about the opened file as reported by C<lfs getstripe --verbose>. 
Returns undef on error.

=item lfs_create( [ARGS] )

Try to create a new file with non standard striping/pool settings. Valid key-value pairs are:

  File     File that you would like to create
  Size     Stripe size to use
  Offset   OST Offset
  Count    How many stripes the file shall use
  Pool     Put file into a specific pool

Please note that you can not change the stripe settings of an existing file. This is a limitation/feature of lustre itself.

The function will return 1 if everything went well. In this case the file should also be opened on your current filehandle

=item join_objects(B_File)

Try to append B_File to your current filehandle. B_File can be a scalar (= path) or an IO::Handle object.
Note that this function will always return 0 as it is not implemented yet. The reason for this is that C<lfs join> simply
does not work for me and i have no way to test this feature.

=back

=head1 AUTHOR

Copyright (C) 2010, Adrian Ulrich E<lt>adrian.ulrich@id.ethz.chE<gt>

=head1 SEE ALSO

L<Lustre::LFS>,
L<Lustre::LFS::Dir>,
L<IO::File>,
L<IO::Handle>,
L<Lustre::Info>,
L<http://www.lustre.org>

=cut
