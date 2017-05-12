package Encode::CNMap;
use 5.008;
use vars qw/$VERSION @EXPORT @EXPORT_OK/;
$VERSION = "0.32";
@EXPORT_OK = @EXPORT = qw(
	simp_to_b5 simp_to_gb trad_to_gb trad_to_gbk
	utf8_to_b5 utf8_to_gb utf8_to_gbk simp_to_utf8 trad_to_utf8
	utf8_to_tradutf8 utf8_to_simputf8 utf8_to_utf8
	simp_to_tradutf8 simp_to_simputf8 trad_to_simputf8 trad_to_tradutf8
);
use base 'Exporter';

use Encode qw( from_to encode decode );
use XSLoader;
XSLoader::load( __PACKAGE__,$VERSION );

sub simp_to_b5($)  { my $t = $_[0]; from_to( $t, "gbk",       "big5-trad"   ); $t; }
sub simp_to_gb($)  { my $t = $_[0]; from_to( $t, "gbk",       "gb2312-simp" ); $t; }
sub trad_to_gb($)  { my $t = $_[0]; from_to( $t, "big5-trad", "gb2312-simp" ); $t; }
sub trad_to_gbk($) { my $t = $_[0]; from_to( $t, "big5-trad", "gbk"         ); $t; }

sub simp_to_utf8($){ decode( "gbk",         $_[0] ); }
sub trad_to_utf8($){ decode( "big5-trad",   $_[0] ); }

sub utf8_to_b5($)  { encode( "big5-trad",   $_[0] ); }
sub utf8_to_gb($)  { encode( "gb2312-simp", $_[0] ); }
sub utf8_to_gbk($) { encode( "gbk",         $_[0] ); }
sub utf8_to_utf8($){ $_[0]; }

sub utf8_to_simputf8($) { decode( "gb2312-simp", encode( "gb2312-simp", $_[0] ) ); }
sub utf8_to_tradutf8($) { decode( "big5-trad",   encode( "big5-trad",   $_[0] ) ); }

sub simp_to_simputf8($) { my $t = $_[0]; from_to( $t, "gbk",       "gb2312-simp" );	decode( "gb2312-simp", $t ); }
sub simp_to_tradutf8($) { my $t = $_[0]; from_to( $t, "gbk",       "big5-trad"   );	decode( "big5-trad",   $t ); }
sub trad_to_simputf8($) { my $t = $_[0]; from_to( $t, "big5-trad", "gb2312-simp" );	decode( "gb2312-simp", $t ); }
sub trad_to_tradutf8($) { decode( "big5-trad", $_[0] ); }

sub cnmapfunc_byopts($) {
	my $opts = $_[0];
	my $from = $opts{s} ? "simp" : $opts{t} ? "trad" : "utf8";
	my $to = $opts{C} ? ( $opts{5} ? "tradutf8" : "simputf8" ) :
		$opts{5} ? "b5" : $opts{k} ? "gbk" : $opts{b} ? "gb" : "utf8";
}

1;
__END__

=head1 NAME

Encode::CNMap - enhanced Chinese encodings with Simplified-Traditional auto-mapping

=head1 SYNOPSIS

    use Encode;
    use Encode::CNMap;
    no warnings;  # disable utf8 output warning
    my $data;

    $data = "中華中华";
    printf "Mix [GBK]  %s\n", $data;
    printf "   -> Simp[GB]   %s\n", simp_to_gb( $data );
    printf "   -> Trad[Big5] %s\n", simp_to_b5( $data );
    printf "   -> Mix [utf8] %s\n", simp_to_utf8( $data );
    printf "   -> Simp[utf8] %s\n", simp_to_simputf8( $data );
    printf "   -> Trad[utf8] %s\n", simp_to_tradutf8( $data );

    $data = "い地い地";
    printf "Trad[Big5] %s\n", $data;
    printf "   -> Simp[GB]   %s\n", trad_to_gb( $data );
    printf "   -> Mix [GBK]  %s\n", trad_to_gbk( $data );
    printf "   -> Mix [utf8] %s\n", trad_to_utf8( $data );
    printf "   -> Simp[utf8] %s\n", trad_to_simputf8( $data );
    printf "   -> Trad[utf8] %s\n", trad_to_tradutf8( $data );

    $data = Encode::decode("gbk", "中華中华");
    printf "Mix [utf8] %s\n", $data;
    printf "   -> Simp[GB]   %s\n", utf8_to_gb( $data );
    printf "   -> Mix [GBK]  %s\n", utf8_to_gbk( $data );
    printf "   -> Trad[Big5] %s\n", utf8_to_b5( $data );
    printf "   -> Mix [utf8] %s\n", utf8_to_utf8( $data );
    printf "   -> Simp[utf8] %s\n", utf8_to_simputf8( $data );
    printf "   -> Trad[utf8] %s\n", utf8_to_tradutf8( $data );

=head1 DESCRIPTION

This module implements China-based Chinese charset encodings.
Encodings supported are as follows.

  Canonical   Alias     Description
  --------------------------------------------------------------------
  gb2312-simp           Enhanced GB2312 simplified chinese encoding
  big5-trad             Enhanced Big5 traditional chinese encoding
  --------------------------------------------------------------------

To find how to use this module in detail, see L<Encode>.

cnmapwx is a GUI interface to cnmap and cnmapdir. Binary distribution
for Microsoft Windows can be down from L<http://bookbot.sourceforge.net/>

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
L<http://bookbot.sourceforge.net/>
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-CNMap>

=head1 SEE ALSO

L<cnmap>, L<cnmapdir>, L<cnmapwx>, L<Encode>, L<Encode::CN>,
L<Encode::HanConvert>, L<Encode::HanExtra>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
