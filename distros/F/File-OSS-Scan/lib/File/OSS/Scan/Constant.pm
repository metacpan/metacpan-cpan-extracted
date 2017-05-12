=head1 NAME

File::OSS::Scan::Constant - define constants

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use File::OSS::Scan::Constant qw(:all);

=head1 DESCRIPTION

This is an internal module used by L<File::OSS::Scan> to get defined constants
imported, and should not be called directly.

=head1 SEE ALSO

=over 4

=item * L<File::OSS::Scan>

=back

=head1 AUTHOR

Harry Wang <harry.wang@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Harry Wang.

This is free software, licensed under:

    Artistic License 1.0

=cut

package File::OSS::Scan::Constant;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.04';

use base qw(Exporter);

my @all_constants = do {
    no strict 'refs';
    grep { exists &$_ } keys %{ __PACKAGE__ . '::' };
};

our @EXPORT_OK = ( @all_constants );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


# -------------------------
# Universal constants
# -------------------------
use constant UNI_TRUE                   => 1;
use constant UNI_FALSE                  => 0;

# -------------------------
# Verbose level
# -------------------------
use constant VERBOSE_SILIENT            => 0;
use constant VERBOSE_NORMAL             => 1;
use constant VERBOSE_CHATTY             => 2;

# -------------------------
# Cache level
# -------------------------
use constant CACHE_NONE                 => 0;
use constant CACHE_USE                  => 1;
use constant CACHE_REFRESH              => 2;

# -------------------------
# Log formatting constants
# -------------------------
use constant WIDTH_FILENAME             => 30;
use constant WIDTH_SIZE                 => 10;
use constant WIDTH_MTIME                => 20;
use constant WIDTH_BAR                  => 100;
use constant WIDTH_INFO_KEY             => 30;
use constant WIDTH_INFO_VAL             => 100;

# -------------------------
# Return status
# -------------------------
use constant SUCCESS                    => 0;
use constant FAIL                       => 99;
use constant SKIP                       => 98;

# -------------------------
# level of certainty
# -------------------------
use constant CERTAINTY_SURE             => 100;




1;
