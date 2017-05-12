package Digest::MD4;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;
require DynaLoader;

*import = \&Exporter::import;
@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw(md4 md4_hex md4_base64);

$VERSION = '1.1';

eval {
    Digest::MD4->bootstrap($VERSION);
};
if ($@) {
    # Try to load the pure perl version
    require Digest::Perl::MD4;

    Digest::Perl::MD4->import(qw(md4 md4_hex md4_base64));
    push(@ISA, "Digest::Perl::MD4");  # make OO interface work
}
else {
    *reset = \&new;
}

1;

=head1 NAME

Digest::MD4 - Wrapper for Digest::Perl::MD4, see which.

=cut
