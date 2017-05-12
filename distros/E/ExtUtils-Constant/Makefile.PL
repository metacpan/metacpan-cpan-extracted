use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'ExtUtils::Constant',
    'VERSION_FROM' => 'lib/ExtUtils/Constant.pm', # finds $VERSION
    # Added to the core somewhere around 5.7.2.
    INSTALLDIRS    => ($] >= 5.007002 && $] <= 5.012) ? 'perl' : 'site',
);

if ($] > 5.005_50 && $] < 5.006001) {
  warn <<"EORANT";

The tests for this module will fail on perl 5.6.0
Perl 5.6.0 contains many many Unicode bugs fixed in 5.6.1 which are impossible
to work round. Please upgrade to at least 5.6.1, preferably 5.8.0.

Bug reports from 5.6.0 users (even users on OS X dependent on Apple to ship
5.6.1) will be acknowledged, tested on 5.6.1, and if not repeatable on 5.6.1
will be noted as known failures due to 5.6.0, with no further action taken.

I am sorry if this sounds unhelpful, but I have better things to do with
the limited free time I can donate to this module than to go chasing bugs
known to already have a fix.

EORANT
}
