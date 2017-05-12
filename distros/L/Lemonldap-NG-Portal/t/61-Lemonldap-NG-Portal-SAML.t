# Unit tests for common SAML functions

use Test::More tests => 4;

# Test Lasso presence and load _SAML module
SKIP: {
    eval "use Lasso;";
    skip "Lasso is not installed, can't test SAML features", 4 if ($@);
    use_ok('Lemonldap::NG::Portal::Simple');

    # Portal object
    $ENV{SCRIPT_NAME}     = '/test.pl';
    $ENV{SCRIPT_FILENAME} = '/tmp/test.pl';
    $ENV{REQUEST_METHOD}  = 'GET';
    $ENV{REQUEST_URI}     = '/';
    $ENV{QUERY_STRING}    = '';

    my $p = Lemonldap::NG::Portal::Simple->new(
        {
            globalStorage  => 'Apache::Session::File',
            domain         => 'example.com',
            authentication => 'SAML',
            userDB         => 'SAML',
            issuerDB       => 'Null',
            passwordDB     => 'Null',
            registerDB     => 'Null',
        }
    );

    # Date/timestamp conversion
    my $timestamp  = "1273653920";
    my $samldate   = "2010-05-12T08:45:20Z";
    my $samldatems = "2010-05-12T08:45:20.123456Z";

    ok(
        $p->timestamp2samldate($timestamp) eq $samldate,
        "Timestamp conversion into SAML2 date"
    );
    ok(
        $p->samldate2timestamp($samldate) eq $timestamp,
        "SAML2 date conversion into timestamp"
    );
    ok(
        $p->samldate2timestamp($samldatems) eq $timestamp,
        "SAML2 date (with ms) conversion into timestamp"
    );

}

