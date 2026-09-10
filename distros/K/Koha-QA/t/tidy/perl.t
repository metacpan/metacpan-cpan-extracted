use Modern::Perl;

use Test::NoWarnings;
use Test::More tests => 6;
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

subtest 'Non-existing perltidyrc file passed' => sub {
    plan tests => 1;

    my $input = <<INPUT;
File does not exist
INPUT

    my $nonexistent_perltidyrc = q{.this-should-not-exist};
    my @errors                 = check_tidy( $input, { perltidyrc => $nonexistent_perltidyrc } );
    is_deeply(
        \@errors,
        [ { error => 'no_perltidyrc', message => qq{perltidyrc file not found: $nonexistent_perltidyrc} } ]
    );
};
