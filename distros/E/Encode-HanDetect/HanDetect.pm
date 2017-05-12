# $File: //member/autrijus/Encode-HanDetect/HanDetect.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 4051 $ $DateTime: 2003/01/30 22:34:14 $

use 5.008;
package Encode::HanDetect;
$Encode::HanDetect::VERSION = '0.01';

use strict;
use base qw(Encode::Encoding);
use Encode qw(find_encoding);
use Lingua::ZH::HanDetect qw(han_detect);

__PACKAGE__->Define('HanDetect');

sub needs_lines { 1 }
sub perlio_ok { 0 }

my $Variant = '';

sub import {
    my $class = shift;
    if ($_[0]) {
	die "Unknown variant: $_[0]" unless $_[0] =~ /^[st]/i;
	$Variant = lc(substr($_[0], 0, 1));
    }
}

sub decode($$;$){
    my ($obj, $octet, $chk) = @_;
    my ($encoding, $variant) = han_detect($octet);
    my $guessed = find_encoding($encoding);

    unless (ref($guessed)){
	require Encode::Guess;
	$guessed = find_encoding('Guess');
    }

    my $utf8 = $guessed->decode($octet, $chk || 0);
    if ($Variant and substr($variant, 0, 1) ne $Variant) {
	require Encode::HanConvert;
	if ($Variant eq 's') {
	    $utf8 = Encode::HanConvert::trad_to_simp($utf8);
	}
	else {
	    $utf8 = Encode::HanConvert::simp_to_trad($utf8);
	}
    }
    $_[1] = $octet if $chk;
    return $utf8;
}

1;

__END__

=head1 NAME

Encode::HanDetect - Cross-encoding, cross-variant Chinese decoder

=head1 VERSION

This document describes version 0.01 of Encode::HanDetect, released
January 31, 2003.

=head1 SYNOPSIS

    use Encode;
    use Encode::HanDetect;
    use Encode::Guess qw(utf8 latin1);	    # fallbacks

    my $utf8 = decode("HanDetect", $data);
    my $data = encode("HanDetect", $utf8);  # this won't work

    use Encode::HanDetect 'traditional'	    # auto-convert to traditional

=head1 DESCRIPTION

B<Encode::HanDetect> is a thin wrapper around B<Lingua::ZH::HanDetect>,
providing the ability to treat any incoming Chinese data equally,
regardless of its encoding.

If a string beginning with either C<t> or C<s> is specified in the C<use>
line, all incoming data streams will be converted to that variant using
B<Encode::HanConvert>.

When B<Lingua::ZH::HanDetect> cannot detect the encoding (most likely
because it contains no Chinese characters), it simply falls back to the
C<Guess> encoding provided by B<Encode::Guess>.

=head1 EXAMPLES

If you use C<less> as pager, setting your C<LESSOPEN> environment to
C<"perl -0777 -MEncode::HanDetect=trad -MEncode::Guess=utf8,iso8859-15
/usr/local/bin/piconv -f HanDetect %s E<gt> /tmp/less; echo /tmp/less">
will automatically convert all Chinese files Traditional Chinese
(while leaving non-Chinese text encoded in C<utf8> or <iso8859-15>
intact), and displayed in the encoding specified by my current locale.

Simplified Chinese users can simply replace the C<=trad> above to
C<=simp>, or omit it if your terminal can display both variants.

=head1 SEE ALSO

L<Encode>, L<Encode::Guess>

L<Encode::HanConvert>, L<Lingua::ZH::HanDetect>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
