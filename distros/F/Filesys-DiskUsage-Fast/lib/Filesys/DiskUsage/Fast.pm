package Filesys::DiskUsage::Fast;

# ABSTRACT: A fast disk usage counter (du) with XS

use strict;
use warnings;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK);

$VERSION = '0.04';

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw(du) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

$Filesys::DiskUsage::Fast::Debug = 0;
$Filesys::DiskUsage::Fast::ShowWarnings = 1;
$Filesys::DiskUsage::Fast::SectorSize = 0;

require XSLoader;
XSLoader::load('Filesys::DiskUsage::Fast', $VERSION);

1;

__END__

=encoding utf-8

=head1 NAME

Filesys::DiskUsage::Fast - A fast disk usage counter (du) with XS

=head1 SYNOPSIS

 use Filesys::DiskUsage::Fast qw(du);
 
 my $total = du( $dir );
 my $total = du( $dir1, $dir2, ... );

=head1 DESCRIPTION

A simple but fast disk usage counter implemented as XS module.

=head1 FUNCTIONS

=over 4

=item B<du()>

Returns total byte number contained in directories specified.

  my $total = du("/usr/local");
  my $total = du("/bin", "/sbin", "/usr/bin", "/usr/sbin");

=back

=head1 GLOBAL VARIABLES

=over 4

=item B<$ShowWarnings>

If true, errors will be warn()ed. Default is true.
Set false to suppress warnings (not found, permission denied etc).

  local $Filesys::DiskUsage::Fast::ShowWarnings = 0;
  du(...);

=item B<$SectorSize>

If > 0, the specified size is used to calculate the block size.
Default value is 0, returns real occupied size.

  local $Filesys::DiskUsage::Fast::SectorSize = 4096;
  du(...);

=back

=head1 PERFORMANCE

     s/iter   pp   xs
  pp   1.35   -- -85%
  xs  0.197 584%   --

tested on a directory contains around 11GB 3300+ files, CentOS 5 (HDD).

=head1 CAVEAT

All symbolic links always result 0 byte. Block, FIFO and other special files may not be counted accurately.

=head1 DEPENDENCY

None

=head1 SEE ALSO

Filesys::DiskUsage, Number::Bytes::Human

=head1 REPOSITORY

https://github.com/ryochin/p5-filesys-diskusage-fast

=head1 AUTHOR

Ryo Okamoto E<lt>ryo@aquahill.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
