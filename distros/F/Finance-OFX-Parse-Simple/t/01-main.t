#!perl -T

use Test::More 'no_plan';
use Finance::OFX::Parse::Simple;

my $parser = Finance::OFX::Parse::Simple->new;

ok( (not defined $parser->parse_file),
    "File parser returns undef with no filename");

ok( (not defined $parser->parse_file("/this/file/does/not/exist")),
    "File parser returns undef for a file which does not exist");

ok( (not defined $parser->parse_scalar),
    "Scalar parser returns undef with no scalar");

my $ofx_data = qq[<OFX>
		  <SIGNONMSGSRSV1>
		  <SONRS>
		  <STATUS>
		  <CODE>0
		  <SEVERITY>INFO
		  </STATUS>
		  <DTSERVER>20081219100804[-5:EST]
		  <LANGUAGE>ENG
		  </SONRS>
		  </SIGNONMSGSRSV1>
		  <BANKMSGSRSV1>
		  <STMTTRNRS>
		  <TRNUID>1
		  <STATUS>
		  <CODE>0
		  <SEVERITY>INFO
		  </STATUS>
		  <STMTRS>
		  <CURDEF>GBP
		  <BANKACCTFROM>
		  <BANKID>999999
		  <ACCTID>1234567
		  <ACCTTYPE>CHECKING
		  </BANKACCTFROM>
		  <BANKTRANLIST>
		  <DTSTART>20080601000000[-5:EST]
		  <DTEND>20080630000000[-5:EST]
		  <STMTTRN>
		  <TRNTYPE>OTHER
		  <DTPOSTED>20080603000000[-5:EST]
		  <TRNAMT>36.05
		  <FITID>+20080603000001
		  <NAME>Transaction $$
		  </STMTTRN>
		  <STMTTRN>
		  <TRNTYPE>OTHER
		  <DTPOSTED>20080603000000[-5:EST]
		  <TRNAMT>36.5
		  <FITID>+20080603000001
		  <NAME>Transaction $$
		  </STMTTRN>
		  </BANKTRANLIST>
		  <LEDGERBAL>
		  <BALAMT>1668.75
		  <DTASOF>20081219000000[-5:EST]
		  </LEDGERBAL>
		  </STMTRS>
		  </STMTTRNRS>
		  </BANKMSGSRSV1>
		  </OFX>
		  ];

my $txn1 = $parser->parse_scalar($ofx_data)->[0]->{transactions}->[0];
my $txn2 = $parser->parse_scalar($ofx_data)->[0]->{transactions}->[1];

ok( (ref($parser->parse_scalar($ofx_data)) eq 'ARRAY'),
    "Parse scalar returns a list reference");

ok( (ref($parser->parse_scalar($ofx_data)->[0]) eq 'HASH'),
    "Parser's list reference contains hash references");

ok( ($txn1->{name} eq "Transaction $$"),
    "OFX data is parsed correctly");

ok( ($txn2->{amount} eq "36.50"),
    "OFX partial decimal data is parsed correctly");

{
    $ofx_data =~ s/(<TRNAMT>\d+)\./$1,/sg or die;

    local $ENV{MON_DECIMAL_POINT} = ',';

    ok( ($parser->parse_scalar($ofx_data)->[0]->{transactions}->[0]->{name} eq "Transaction $$"),
	"OFX data is parsed correctly with alternate decimal point character");

    my $m = $parser->parse_scalar($ofx_data)->[0]->{transactions}->[0]->{amount};

    ok($m == 36.05,
       "OFX amounts are parsed correctly with alternate decimal point character");
}


# Basic tests for parsing <CCSTMTTRNRS> transactions
{
    local $ENV{MON_DECIMAL_POINT} = ',';

    (my $cc_ofx_data = $ofx_data) =~ s!(</?)(STMTTRNRS>)!$1CC$2!g;

    my $cc_parsed = $parser->parse_scalar($cc_ofx_data);
    my $cctxn1 = $cc_parsed->[0]->{transactions}->[0];
    my $cctxn2 = $cc_parsed->[0]->{transactions}->[1];

    ok( (ref($cc_parsed) eq 'ARRAY'),
        "Parse scalar returns a list reference");

    ok( (ref($cc_parsed->[0]) eq 'HASH'),
        "Parser's list reference contains hash references");

    is $cctxn1->{name}, $txn1->{name}, "Name parse ok";
    is $cctxn2->{amount}, $txn2->{amount}, "Amount parse ok";
}
