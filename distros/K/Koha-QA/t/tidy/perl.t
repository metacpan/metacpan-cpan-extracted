use Modern::Perl;

use Test::NoWarnings;
use Test::More tests => 9;
use Test::Warn;
use File::Temp qw(tempfile);
use Koha::QA::Tidy::Perl;

sub check_tidy {
    my ( $content, $params ) = @_;
    $params ||= {};
    my $checker = Koha::QA::Tidy::Perl->new( { content => $content, %$params } );
    $checker->check();
    return $checker->errors();
}

subtest 'File tidy should pass tidy check' => sub {
    plan tests => 1;

    my $input = <<INPUT;
use Modern::Perl;
print "hello";
INPUT

    my @errors = check_tidy($input);
    is( scalar @errors, 0 );
};

subtest 'File not tidy should not pass tidy check' => sub {
    plan tests => 1;

    my $input = <<INPUT;
use Modern::Perl;
    print "hello";
INPUT

    my @errors = check_tidy($input);
    is_deeply(
        \@errors,
        [
            {
                message => 'Perl file is not tidy',
                error   => 'tidy_perl'
            }
        ]
    );
};

subtest 'Fix content' => sub {
    plan tests => 2;

    my $tidy_input = <<INPUT;
use Modern::Perl;
print "hello";
INPUT

    my $untidy_input = <<INPUT;
use Modern::Perl;
    print "hello";
INPUT

    subtest 'File is tidy' => sub {
        plan tests => 2;
        my $checker = Koha::QA::Tidy::Perl->new( { content => $tidy_input } );
        $checker->check();
        is( $checker->fix, $tidy_input, "check called before fix" );

        $checker = Koha::QA::Tidy::Perl->new( { content => $tidy_input } );
        is( $checker->fix, $tidy_input, "check not called before fix" );
    };

    subtest 'File is not tidy' => sub {
        plan tests => 2;
        my $checker = Koha::QA::Tidy::Perl->new( { content => $untidy_input } );
        $checker->check();
        is( $checker->fix, $tidy_input, "check called before fix" );

        $checker = Koha::QA::Tidy::Perl->new( { content => $untidy_input } );
        is( $checker->fix, $tidy_input, "check not called before fix" );
    };
};

subtest 'Specific .perltidyrc' => sub {
    plan tests => 2;

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1 );
    print $fh "--maximum-line-length=20";
    close $fh;

    my $untidy_input = <<'INPUT';
use Modern::Perl;
foo($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l);
INPUT

    my $tidy_input = <<'INPUT';
use Modern::Perl;
foo(
    $a, $b, $c,
    $d, $e, $f,
    $g, $h, $i,
    $j, $k, $l
);
INPUT

    my $checker  = Koha::QA::Tidy::Perl->new( { content => $untidy_input, perltidyrc => $filename } );
    my $is_valid = $checker->check();
    my @errors   = $checker->errors();
    is_deeply(
        \@errors,
        [
            {
                message => 'Perl file is not tidy',
                error   => 'tidy_perl'
            }
        ]
    );

    is( $checker->fix, $tidy_input, "check called before fix" );
};

subtest 'File passed via file parameter' => sub {
    plan tests => 2;

    my $tidy_input = <<INPUT;
use Modern::Perl;
print "hello";
INPUT

    my $untidy_input = <<INPUT;
use Modern::Perl;
    print "hello";
INPUT

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.pl' );
    print $fh $tidy_input;
    close $fh;

    my $checker = Koha::QA::Tidy::Perl->new( { file => $filename } );
    my @errors  = $checker->errors() if $checker->check();
    is( scalar @errors, 0, 'Tidy file passed via file parameter should pass tidy check' );

    ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.pl' );
    print $fh $untidy_input;
    close $fh;

    $checker = Koha::QA::Tidy::Perl->new( { file => $filename } );
    $checker->check();
    is( $checker->fix, $tidy_input, 'Untidy file passed via file parameter should be fixed' );
};

subtest 'Non-existing perltidyrc file passed' => sub {
    plan tests => 2;

    my $input = <<INPUT;
File does not exist
INPUT

    my $nonexistent_perltidyrc = q{.this-should-not-exist};
    my $checker = Koha::QA::Tidy::Perl->new( { content => $input, perltidyrc => $nonexistent_perltidyrc } );
    $checker->check();
    is_deeply(
        [ $checker->errors ],
        [ { error => 'no_perltidyrc', message => qq{perltidyrc file not found: $nonexistent_perltidyrc} } ]
    );
    is( $checker->fix, undef, 'fix() returns undef rather than silently truncating the file' );
};

subtest 'Broken perltidyrc must fail the check, not be reported as ordinary untidiness' => sub {
    plan tests => 5;

    # A broken (but existing) perltidyrc makes perltidy exit non-zero without writing
    # anything to stdout; this must be reported as a tool failure, not folded into
    # "the file needs the (empty) fix produced" (tidy_perl_empty_output) or, worse,
    # ordinary untidiness (tidy_perl).
    my ( $fh, $broken_perltidyrc ) = tempfile( UNLINK => 0, TEMPDIR => 1 );
    print $fh "--this-is-not-a-valid-option\n";
    close $fh;

    my $input = <<INPUT;
use Modern::Perl;
print "hello";
INPUT

    my $checker = Koha::QA::Tidy::Perl->new( { content => $input, perltidyrc => $broken_perltidyrc } );
    my $is_valid;
    warning_like { $is_valid = $checker->check() } qr/Unknown option/,
        'check() warns with perltidy\'s config error';
    is( $is_valid, 0, 'check() reports failure' );
    is_deeply(
        [ $checker->errors ],
        [
            {
                error   => 'tidy_perl_perltidy_failed',
                message => 'perltidy failed to process the file, the original content was kept'
            }
        ],
        'check() reports the perltidy-failed error, not "not tidy"'
    );

    # fix() hasn't cached a result since check() returned early, so it re-runs
    # check() (and perltidy) rather than reusing the failure
    my $fixed;
    warning_like { $fixed = $checker->fix } qr/Unknown option/, 'fix() re-running check() warns again';
    is( $fixed, undef, 'fix() returns undef rather than silently truncating the file' );
};

subtest 'Perltidy fail to parse the content' => sub {
    plan tests => 3;

    my $input = <<'INPUT';
sub foo {
    print "no closing brace";
INPUT

    my $checker = Koha::QA::Tidy::Perl->new( { content => $input } );
    my $is_valid;

    warning_like { $is_valid = $checker->check } qr/Please see file/,
        "check() warns with perltidy's error notice";

    ok( !$is_valid, 'check() reports the file as not tidy when perltidy fails to parse it' );
    is_deeply(
        [ $checker->errors ],
        [
            {
                message => 'perltidy failed to process the file, the original content was kept',
                error   => 'tidy_perl_perltidy_failed'
            }
        ],
        'the parse failure is reported'
    );
};
