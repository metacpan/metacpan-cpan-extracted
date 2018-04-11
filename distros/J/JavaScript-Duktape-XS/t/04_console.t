use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;
use Test::Output;
use JavaScript::Duktape::XS;

sub test_console {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my @texts = (
        q<'Hello Gonzo'>,
        q<'this is a string', 1, [], {}>,
    );
    foreach my $text (@texts) {
        my $expected = $text;
        $expected =~ s/[',]//g;
        $expected = quotemeta($expected);

        foreach my $func (qw/ log debug trace info /) {
            stdout_like sub { $duk->eval("console.$func($text)"); },
                        qr/$expected/,
                        "got correct stdout from $func for <$text>";
        }

        foreach my $func (qw/ warn error exception /) {
            stderr_like sub { $duk->eval("console.$func($text)"); },
                        qr/$expected/,
                        "got correct stderr from $func for <$text>";
        }
    }
}

sub main {
    test_console();
    done_testing;
    return 0;
}

exit main();
