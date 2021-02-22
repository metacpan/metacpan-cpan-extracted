use FindBin '$Bin';
use lib "$Bin";
use LJMT;
use Test::More tests => 10;binmode STDOUT, ":utf8";
my $input = <<EOF;
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123
--- expected: およよABCDEFGbfege123123
test: wide2ascii
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
--- expected: オヨヨＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
test: hira2kata
--- input:    "\x{3000}eee"
--- expected: "\x{0020}eee"
test: wide2ascii
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
--- expected: およよＡＢＣＤＥＦＧｂｆｅge１２３123およよおよよ
test: hw2katakana + kata2hira
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
--- expected: およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨオヨヨ
test: hw2katakana
--- input:    ｶﾞ
--- expected: ガ
test:hw2katakana
--- input:    ・･
--- expected: ・・
test:hw2katakana
--- input:    およよＡＢＣＤＥＦＧｂｆｅge１２３123オヨヨｵﾖﾖ
--- expected: およよＡＢＣＤＥＦＧｂｆｅge１２３123ｵﾖﾖｵﾖﾖ
test:katakana2hw
--- input:    ガ
--- expected: ｶﾞ
test: kana2hw
--- input: およよABCDEFGbfe123123
--- expected:    およよＡＢＣＤＥＦＧｂｆｅ１２３１２３
test: ascii2wide
EOF

no strict 'refs';

my @guff = split /\n/, $input;
while (@guff) {
    my $input = shift @guff;
    $input =~ s/^.*input:\s*// or die;
    my $expected = shift @guff;
    $expected =~ s/^.*expected:\s*// or die;
    my $routines = shift @guff;
    $routines =~ s/test:\s*// or die;
    my @routines = split /\s*\+\s*/, $routines;
    my $output = $input;
    for my $routine (@routines) {
        $output = &{$routine} ($output);
    }
    if ($output ne $expected) {
        print "BAD $routines.\n";
        print "A: $output\nB: $expected\n";
    }
    else {
        print "OK $routines.\n";
    }
    ok ($expected eq $output);
}
