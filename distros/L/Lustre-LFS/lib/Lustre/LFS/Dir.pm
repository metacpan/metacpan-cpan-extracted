#
# PurePerl implementation glue to '/usr/sbin/lfs'
#
# (C) 2010 Adrian Ulrich - <adrian.ulrich@id.ethz.ch>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#

package Lustre::LFS::Dir;
use strict;
use Lustre::LFS;
use IO::File;
use base 'IO::File';


########################################################################
# Return stripe information for opened file
sub get_stripe {
	my($self) = @_;
	return Lustre::LFS::_parse_get_stripe_dir($self);
}

########################################################################
# Set stripe information for current folder
sub set_stripe {
	my($self, %args) = @_;
	my $fname = Lustre::LFS::_lfs_get_path($self);
	my $ssize = delete($args{Size});
	my $soff  = delete($args{Offset});
	my $scount= delete($args{Count});
	my $spool = delete($args{Pool});
	my @arglist = ("setstripe");
	
	return $fname unless defined $fname;
	
	push(@arglist, "--size"  , int($ssize))  if defined $ssize;
	push(@arglist, "--offset", int($soff))   if defined $soff;
	push(@arglist, "--count" , int($scount)) if defined $scount;
	push(@arglist, "--pool"  , $spool)       if defined $spool;
	push(@arglist, "--"      , $fname);
	
	return ( Lustre::LFS::_lfs_system(@arglist) ? 0 : 1 );
}


########################################################################
# Remove stripe
sub delete_stripe {
	my($self) = @_;
	my $path = Lustre::LFS::_lfs_get_path($self);
	return $path unless defined $path;
	return ( Lustre::LFS::_lfs_system("setstripe", "-d", "--", $path) ? 0 : 1);
}

1;

__END__

=head1 NAME

Lustre::LFS::Dir - IO::Dir like module with lustre support

=head1 SYNOPSIS

  use strict;
  use Lustre::LFS::Dir;
  
  my $fh = Lustre::LFS::Dir;
  $d = Lustre::LFS::Dir->new(".");
  my $stripes = $d->get_stripe;
  $d->delete_stripe; # delete default striping
  $d->set_stripe(Count=>3);
  
=head1 DESCRIPTION

"Lustre::LFS::Dir" inherits from "IO::Dir" (which inherits from "IO::Handle"), so 
a C<Lustre::LFS::Dir> reference can do everything that an "IO::Dir" ref could do.

=head1 CONSTRUCTOR

=over 4

See C<IO::Dir> for details.

=back

=head1 METHODS

=over 4

=item get_stripe

Returns striping information about the opened directory as reported by C<lfs getstripe --verbose>. 
Returns undef on error.

=item set_stripe ( [ARGS] )

Updates the stripe settings for the opened directory. Valid key-value pairs are:

  Size     Stripe size to use
  Offset   OST Offset
  Count    How many stripes the files in this directory shall use
  Pool     Put directory into a specific pool

Returns FALSE on error.

=item delete_stripe

Remove any custom stripe settings from current directory. Returns FALSE on error (0 or undef)

=back

=head1 AUTHOR

Copyright (C) 2010, Adrian Ulrich E<lt>adrian.ulrich@id.ethz.chE<gt>

=head1 SEE ALSO

L<Lustre::LFS>,
L<Lustre::LFS::File>,
L<IO::File>,
L<IO::Handle>,
L<Lustre::Info>,
L<http://www.lustre.org>

=cut
