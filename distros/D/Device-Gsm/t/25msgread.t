# Test pdu messages decoding

# The encoding is supposed to be ISO-8859-1 aka LATIN-1
# https://en.wikipedia.org/wiki/ISO/IEC_8859-1

use Test::More tests => 18;

use Device::Gsm;
use Device::Gsm::Sms;
use Device::Gsm::Charset;

my $debug = 0;

my $msg = new Device::Gsm::Sms( header => 'xxx', pdu=> 'xxx');
ok( (! defined $msg && ! ref $msg), 'erroneous message (sms object undef)' );

$msg = new Device::Gsm::Sms(header => '', pdu => '');
ok( (! defined $msg && ! ref $msg), 'empty header/pdu message (sms object undef)' );

my @test_data = (
	"+CMGL: 1,1,,99",
	"0791933385280200040C919333393165040000201151314225405B4936082E2FEBF56F101E946683E0631001444E836C3518A85C97BF9",
	"Il prezzo x il pc \xE8 di 650 eur/H",
	"+CMGL: 2,1,,31",
	"0791932350593900040C919323988277190000208082319082000DC170382C168BC3E1B0582C06",
	"Aaaabbbaaabbb",
	"+CMGL: 4,1,,140",
	"0791932350591900040CD0ECB4B82C7F033900209021319490008AF3F67C14D381C6E9F09B051ABFDB75777A1CD683C8A079596E4FEB8",
	"sms#1: ciao, comunicaz d servi:\xA1",
	"+CMGL: 6,1,,133",
	"0791933385280200040C919333883425580000200150112245408246F9BB0D82CADFF630082A7FDBDF3B05B16C4F8FCBADE3BC0DB2C70",
	"From Prova Provo;\nDevice-Gsm v1\@",
	"+CMGL: 8,1,,106",
	"0791933385280200040C9193335592402700002090424164744063C374F80D2287D9A068BD5C2F839A6177F85C9683A4E5F69BFE0E85C",
    "Ciao dal Queue Manager Remoto!!\xBF",
	"+CMGL: 9,1,,118",
    "0791449737019037040C914497676398780000201121616464007146F9BB0D1286E5EEB0380F82D6E9F4F478BD5310CBF6F4B8DC3ACE1",
	"From Barnaby Puttick;\nDevice-G3\xF2",
	"+CMGL: 10,1,,98",
	"0791933385285200040E850093402399810039002001103103044059C334C85E26A7C3ED3728CC669FD2EE70FD5C9787F5E9B7BB0C22F",
	"Ci vediamo all'inaugurazione \xE8<",
	"+CMGL: 10,1,,96",
	"0791932350591900040C9193239882777900003030621253314058A018CBA5DB857EA8D4AAA57AF500A393A064E2F922DF006910168F65FB7FE2D12197CDB34DB94038A3D3B4C386B7796D7C1B8A7ACDAEB5DD6F5B1FC1E0C3E3F2F98D5EB7E30CFE3B3EAFCFC156",
    " 1,.:;!?()+-*/=\@#'\$\%\&<>_\xA7\xA3\xA4\xA5abc2\xE4\xE0\xC7\xE5\xE6def3\xA4\xE9\xE8ghi4\xEC[\\]^jkl5mno6\xF1\xF2\xF8\xF6pqrs7tuv8\xF9\xFCwxyz90+"
);

while( @test_data ) {

	$msg = new Device::Gsm::Sms(
		header => shift @test_data,
		pdu    => shift @test_data
	);

	$ok_text = shift @test_data;

	ok( defined $msg && ref $msg eq 'Device::Gsm::Sms', 'sms test-set object' );

	if( $ok_text ) {
		$ascii_text = $msg->text;

        print_msg_debug_info($ok_text, $ascii_text) if $debug;

		is( $ascii_text, $ok_text, 'check sms text' );
	}

}

sub print_msg_debug_info {
    my $ok_text = shift;
    my $ascii_text = shift;

    print "Length of ok_text = ", length($ok_text), "\n";
    print "Length of sms_text= ", length($ascii_text), "\n";
    print "\n";

    my $diff = 0;
    for(my $i = 0 ; $i < length($ascii_text) ; $i++ ) {
        next if substr($ascii_text,$i,1) eq substr($ok_text,$i,1);

        print "Pos: $i ", (substr($ascii_text,$i,1) eq substr($ok_text,$i,1) ? 'OK  ' : 'FAIL')." [", substr($ascii_text,$i,1), ': ', ord(substr($ascii_text,$i,1)), "]";
        print " != [", substr($ok_text,$i,1),     ': ', ord(substr($ok_text,$i,1)),     "]\n";

        # Gsm table generation (use with `grep 'CODE' text | cut -b5-`)
        print "CODE \t", '$gsm['.ord(substr($ascii_text,$i,1)).'] = \''.substr($ok_text,$i,1)."';\n";

        $diff++;
    }

    print "$diff differences found on ", length($ascii_text), " chars\n";
}

# end of messages test
# vim: syn=perl ts=4
