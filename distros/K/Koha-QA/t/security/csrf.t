use Modern::Perl;
use Test::NoWarnings;
use Test::More tests => 11;
use File::Temp qw(tempfile);
use Koha::QA::Security::CSRF;

my $expected_messages = {
    missing_csrf_token => q{Some forms with POST method are missing CSRF token (bug 22990)},
    missing_op         => q{Form with POST method is missing op parameter (see bug 34478)},
    invalid_op_value   => q{op parameter value should start with "cud-" or be a TT variable (see bug 34478)},
};

sub check_csrf {
    my ($content) = @_;
    my $checker = Koha::QA::Security::CSRF->new( { content => $content } );
    $checker->check();
    return $checker->errors();
}

subtest 'Forms with POST method missing CSRF token and op' => sub {
    plan tests => 1;
    my $input = <<INPUT;
<form method="post" action="/cgi-bin/koha/foo.pl">
    <input type="text" name="bar" />
</form>
INPUT

    my @errors = check_csrf($input);
    is_deeply(
        \@errors,
        [
            {
                error       => 'missing_csrf_token',
                message     => $expected_messages->{missing_csrf_token},
                line        => '<form method="post" action="/cgi-bin/koha/foo.pl">',
                line_number => 1,
            },
            {
                error       => 'missing_op',
                message     => $expected_messages->{missing_op},
                line        => '<form method="post" action="/cgi-bin/koha/foo.pl">',
                line_number => 1,
            }
        ],
        'POST form without CSRF token and op parameter detected'
    );
};

subtest 'Forms with POST method and CSRF token but missing op' => sub {
    plan tests => 2;
    my $input = <<INPUT;
<form method="post" action="/cgi-bin/koha/foo.pl">
    [% INCLUDE 'csrf-token.inc' %]
    <input type="text" name="bar" />
</form>
INPUT

    my @errors = check_csrf($input);
    is_deeply(
        \@errors,
        [
            {
                error       => 'missing_op',
                message     => $expected_messages->{missing_op},
                line        => '<form method="post" action="/cgi-bin/koha/foo.pl">',
                line_number => 1,
            }
        ],
        'POST form with CSRF token but missing op parameter'
    );

    $input = <<'INPUT';
<form method="post" action="/cgi-bin/koha/foo.pl">
    <input type="hidden" name="csrf_token" value="${csrf_token}" />
    <input type="text" name="bar" />
</form>
INPUT

    @errors = check_csrf($input);
    is_deeply(
        \@errors,
        [
            {
                error       => 'missing_op',
                message     => $expected_messages->{missing_op},
                line        => '<form method="post" action="/cgi-bin/koha/foo.pl">',
                line_number => 1,
            }
        ],
        'POST form with csrf_token input but missing op parameter'
    );
};

subtest 'GET forms should not require CSRF token' => sub {
    plan tests => 1;
    my $input = <<INPUT;
<form method="get" action="/cgi-bin/koha/foo.pl">
    <input type="text" name="bar" />
</form>
INPUT

    my @errors = check_csrf($input);
    is_deeply( \@errors, [], 'GET form does not require CSRF token' );
};

subtest 'Multiple forms on same page' => sub {
    plan tests => 1;
    my $input = <<INPUT;
<form method="post" action="/cgi-bin/koha/foo.pl">
    <input type="text" name="bar" />
</form>
<form method="post" action="/cgi-bin/koha/baz.pl">
    [% INCLUDE 'csrf-token.inc' %]
    <input type="text" name="qux" />
</form>
INPUT

    my @errors = check_csrf($input);
    is_deeply(
        \@errors,
        [
            {
                error       => 'missing_csrf_token',
                message     => $expected_messages->{missing_csrf_token},
                line        => '<form method="post" action="/cgi-bin/koha/foo.pl">',
                line_number => 1,
            },
            {
                error       => 'missing_op',
                message     => $expected_messages->{missing_op},
                line        => '<form method="post" action="/cgi-bin/koha/foo.pl">',
                line_number => 1,
            },
            {
                error       => 'missing_op',
                message     => $expected_messages->{missing_op},
                line        => '<form method="post" action="/cgi-bin/koha/baz.pl">',
                line_number => 4,
            }
        ],
        'Multiple forms: first missing both CSRF and op, second missing op'
    );
};

subtest 'Forms without method attribute are not flagged' => sub {
    plan tests => 1;
    my $input = <<INPUT;
<form action="/cgi-bin/koha/foo.pl">
    <input type="text" name="bar" />
</form>
INPUT

    my @errors = check_csrf($input);
    is_deeply( \@errors, [], 'Form without method attribute is not flagged' );
};

subtest 'Test with file parameter' => sub {
    plan tests => 2;
    my $input = <<INPUT;
<form method="post" action="/cgi-bin/koha/foo.pl">
    <input type="text" name="bar" />
</form>
INPUT

    my ( $fh, $filename ) = tempfile( SUFFIX => '.tt' );
    print $fh $input;
    close $fh;

    my $checker  = Koha::QA::Security::CSRF->new( { file => $filename } );
    my $is_valid = $checker->check();
    ok( !$is_valid, 'check returns false for form without CSRF token and op' );

    my @errors = $checker->errors();
    is_deeply(
        \@errors,
        [
            {
                error       => 'missing_csrf_token',
                message     => $expected_messages->{missing_csrf_token},
                line        => '<form method="post" action="/cgi-bin/koha/foo.pl">',
                line_number => 1,
            },
            {
                error       => 'missing_op',
                message     => $expected_messages->{missing_op},
                line        => '<form method="post" action="/cgi-bin/koha/foo.pl">',
                line_number => 1,
            }
        ],
        'errors detected with file parameter'
    );

    unlink $filename;
};

subtest 'Forms with valid op parameter (cud-)' => sub {
    plan tests => 1;
    my $input = <<INPUT;
<form method="post" action="/cgi-bin/koha/foo.pl">
    [% INCLUDE 'csrf-token.inc' %]
    <input type="hidden" name="op" value="cud-update" />
    <input type="text" name="bar" />
</form>
INPUT

    my @errors = check_csrf($input);
    is_deeply( \@errors, [], 'POST form with valid cud- op parameter has no errors' );
};

subtest 'Forms with valid op parameter (TT variable)' => sub {
    plan tests => 1;
    my $input = <<INPUT;
<form method="post" action="/cgi-bin/koha/foo.pl">
    [% INCLUDE 'csrf-token.inc' %]
    <input type="hidden" name="op" value="[% op_value %]" />
    <input type="text" name="bar" />
</form>
INPUT

    my @errors = check_csrf($input);
    is_deeply( \@errors, [], 'POST form with TT variable op parameter has no errors' );
};

subtest 'Forms with invalid op parameter value' => sub {
    plan tests => 1;
    my $input = <<INPUT;
<form method="post" action="/cgi-bin/koha/foo.pl">
    [% INCLUDE 'csrf-token.inc' %]
    <input type="hidden" name="op" value="invalid-op" />
    <input type="text" name="bar" />
</form>
INPUT

    my @errors = check_csrf($input);
    is_deeply(
        \@errors,
        [
            {
                error       => 'invalid_op_value',
                message     => $expected_messages->{invalid_op_value},
                line        => '<form method="post" action="/cgi-bin/koha/foo.pl">',
                line_number => 1,
                op_value    => 'invalid-op',
            }
        ],
        'POST form with invalid op parameter value detected'
    );
};

subtest 'Forms with login_op parameter' => sub {
    plan tests => 1;
    my $input = <<INPUT;
<form method="post" action="/cgi-bin/koha/foo.pl">
    [% INCLUDE 'csrf-token.inc' %]
    <input type="hidden" name="login_op" value="cud-login" />
    <input type="text" name="bar" />
</form>
INPUT

    my @errors = check_csrf($input);
    is_deeply( \@errors, [], 'POST form with login_op parameter has no errors' );
};
