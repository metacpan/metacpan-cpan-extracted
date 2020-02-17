use warnings;
use strict;

# Regression unearthed via Acme::Backwards

use Test::More;
use Keyword::Declare;

sub _esle {_backwards('else','',shift)}
sub _fisle {shift=~m/\s*((?&PerlExpression))\s*(.*?;) $PPR::GRAMMAR/gxm;_backwards('elsif', $1, $2);}
sub _backwards {sprintf"%s %s { %s }",@_;}

keytype OKAY is m{(?:fisle (?&PerlNWS)(?&PerlExpression).*?;|esle (?&PerlNWS).*?;)?+}xms;

keyword fi (Expr $test, /.+?;/ $code, OKAY @next) {
    _backwards('if', $test, $code) . _process_backwards(@next);
}
keyword sselnu (Expr $test, /.+?;/ $code, OKAY @next) {
    _backwards('unless', $test, $code) . _process_backwards(@next);
}

sub _process_backwards {
    no strict 'refs';
    join ' ', map { $_=~m/(fisle|esle)(.*)$/; return "_$1"->($2) } @_;
}


fi (ok(1)) ok(1);
sselnu (ok(1)) ok(1);

fi (0 == 1) ok(0);
esle ok(1);

fi (0 == 1) ok(0);
fisle (1 == 0) ok(0);
fisle (1 == 1) ok(1);
esle ok(0);

done_testing(4);
