package Fcntl::Packer;

our $VERSION = '0.03';

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(pack_fcntl_flock       unpack_fcntl_flock
                    pack_fcntl_f_owner_ex  unpack_fcntl_f_owner_ex);

require XSLoader;
XSLoader::load('Fcntl::Packer', $VERSION);

1;

__END__

=head1 NAME

Fcntl::Packer - Build packed structures for passing into fcntl.

=head1 SYNOPSIS

  use Fcntl::Packer;

  my $p = pack_fcntl_flock { type => F_WRLCK, whence => SEEK_SET,
                             start => 1024, len => 512 };

  fcntl($fh, F_SETLK, $p);

  my $out = pack_fcntl_flock {};
  fcntl($fh, $_GETLK, $out);
  print Dumper unpack_fcntl_flock($out);

=head1 DESCRIPTION

POSIX L<fcntl(2)> function accepts some structures that may be
difficult to build from Perl in a portable way (for instance,
C<struct flock>).

This module implements pairs of methods to pack/unpack these
structures.

=head2 EXPORT

The following subroutines can be exported from this module:

=over 4

=item $str = pack_fcntl_flock \%data;

=item $hash = unpack_fcntl_flock $data;

=item $str = pack_f_owner_ex \%data;

=item $hash = unpack_f_owner_ex $data;

=back

=head1 SEE ALSO

L<fcntl(2)>, L<perlfunc/fcntl>, L<Fcntl>.

There are several modules on CPAN providing high level wrappers for
the functionality available through L<fcntl(2)>. I.e,
L<IPC::SRLock::Fcntl> or L<File::FcntlLock>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
