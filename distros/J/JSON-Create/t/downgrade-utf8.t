# This tests the ->downgrade_utf8 method of JSON::Create, which
# switches on and off automatic downgrading of character encoding.
use FindBin '$Bin';
use lib "$Bin";
use JCT;

my $jc = JSON::Create->new ();

# Test that the option actually exists. It had not been implemented in
# JSON::Create::PP, causing failures in testing the JSON::Server
# module:

# http://www.cpantesters.org/cpan/report/be2bace2-6980-11eb-8167-6d411f24ea8f

eval {
    # This was causing crashes with JSON::Create::PP via JSON::Server.
    $jc->downgrade_utf8 (1);
};
ok (! $@, "No errors from calling downgrade_utf8 method");

if ($ENV{JSONCreatePP}) {
    # This is for JSON::Create::PP (pure perl) only.
    ok ($jc->{_downgrade_utf8}, "Downgrade flag is on");
}

# Random UTF-8 characters. The "use JCT;" above has turned on "use
# utf8;" here.

my $unicode = '馬場部ビボ'; 
my $output = $jc->create ({unicode => $unicode});
ok (! utf8::is_utf8 ($output), "output is not utf8");

# Test that we can turn the option off 

$jc->downgrade_utf8 (undef);
my $output_utf8 = $jc->create ({unicode => $unicode});
ok (utf8::is_utf8 ($output_utf8), "output is utf8, test turning option off");

done_testing ();
