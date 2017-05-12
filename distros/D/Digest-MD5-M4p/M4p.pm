package Digest::MD5::M4p;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);
$VERSION = '0.01';

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(md5 md5_hex md5_base64);

require DynaLoader;
@ISA=qw(DynaLoader);

eval {
    require Digest::base;
    push(@ISA, 'Digest::base');
};
if ($@) {
    my $err = $@;
    *add_bits = sub { die $err };
}


eval {
    Digest::MD5::M4p->bootstrap($VERSION);
};
if ($@) {
    my $olderr = $@;
    eval {
	# Try to load the pure perl version which does not exist so far
	require Digest::Perl::MD5::M4p;

	Digest::Perl::MD5::M4p->import(qw(md5 md5_hex md5_base64));
	push(@ISA, "Digest::Perl::MD5");  # make OO interface work
    };
    if ($@) {
	# restore the original error
	die $olderr;
    }
}
else {
    *reset = \&new;
}

1;
__END__

=head1 NAME

Digest::MD5::M4p - Perl interface to a variant of the MD5 algorithm

=head1 SYNOPSIS

 See Digest::MD5.

=head1 AUTHORS

The original C<MD5> interface was written by Neil Winton
(C<N.Winton@axion.bt.co.uk>).

The current C<Digest::MD5> module was written by Gisle Aas <gisle@ActiveState.com>.

Only minor hacks are required for this !! incompatible !! version.

=cut
