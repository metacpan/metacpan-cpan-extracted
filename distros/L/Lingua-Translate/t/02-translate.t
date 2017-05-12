#!/usr/bin/perl

use Test::More tests => 6;

use_ok("Lingua::Translate");

my $xl8r = Lingua::Translate->new(src => "en",
				  dest => "de");

# test with default back-end
ok(UNIVERSAL::isa($xl8r, "Lingua::Translate"),
   "Lingua::Translate->new()");

my $english = "I would like some cigarettes and a box of matches";

my $german = $xl8r->translate($english);

eval "use Unicode::MapUTF8 qw(from_utf8);";

if ( $@ ) {
    # No Unicode::MapUTF8
    like($german,
	 qr/m..?chte.*Zigaretten.*(bereinstimmungen|Gleichem)/,
	 "Lingua::Translate->translate [en -> de]");

    # "skip" doesn't seem to be reliable
    ok("No Unicode::MapUTF8!");

} else {

    like(from_utf8({-string=>$german, -charset=>"ISO-8859-1"}),
	 qr/m.chte.*Zigaretten/,
	 "Lingua::Translate->translate [en -> de]");

    # test Unicode
    my $jap_xl8r = Lingua::Translate->new(src => "en", dest => "ja",
					  dest_enc => "euc-jp");
    my $japanese = $jap_xl8r->translate
	("I would like some cigarettes and a box of matches");

    # just look for some likely euc-jp byte sequence.  The translation
    # from Babelfish seems to change regularly.
    my $seq = pack ('C*', 187, 228, 164);
    like($japanese, qr/$seq/, "Set destination character set (euc-jp)");

    my $zhong_xl8r = Lingua::Translate->new(src => "en", dest => "zt",
					    dest_enc => "big5");

    my $zhongyu = $zhong_xl8r->translate
	("My hovercraft is full of eels");

    $seq = pack('C*', 0xa7, 0xda, 0xaa, 0xba);
    like($zhongyu, qr/$seq/, "Set destination charset (big5)");
    #diag($zhongyu);
    #diag(join(", ",map { sprintf("0x%.2x", $_) } unpack("C*", $zhongyu) )
	#);
}

$xl8r = Lingua::Translate->new(src => "en",
                               dest => "pt")
     or die "No translation server available for en -> pt";

my $portugese = $xl8r->translate($english); # dies or croaks on error

# prints "Meu hovercraft esta' cheio das enguias"
like($portugese, qr/cigarros.*caixa de/,
     "Lingua::Translate->translate [en -> pt]");



