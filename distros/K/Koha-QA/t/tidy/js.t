use Modern::Perl;

use File::ShareDir qw(dist_file dist_dir);
use File::Spec;
use IPC::Run3;

use Koha::QA::Tidy::JS;

BEGIN {
    # Check if prettier is available via node
    my ( $stdout, $stderr );
    my $available = Koha::QA::Tidy::JS->_has_prettier();
    unless ($available) {
        print "1..0 # skip prettier is not available\n";
        exit 0;
    }
}

use Test::NoWarnings qw(had_no_warnings);
use Test::More tests => 9;
use Test::Warn;
use File::Temp qw(tempfile);

sub check_tidy {
    my ( $content, $params ) = @_;
    $params ||= {};
    my $checker = Koha::QA::Tidy::JS->new( { content => $content, %$params } );
    $checker->check();
    return $checker->errors();
}

subtest 'File tidy should pass tidy check' => sub {
    plan tests => 1;

    my $input = <<'INPUT';
for (const user of ["Alice", "Bob", "Charlie"]) {
    console.log(user);
}
INPUT

    my @errors = check_tidy($input);
    is( scalar @errors, 0 );
};

subtest 'File not tidy should not pass tidy check' => sub {
    plan tests => 1;

    my $input = <<'INPUT';
for ( const user of ["Alice", "Bob", "Charlie"] ) {
    console.log( user );

}
INPUT

    my @errors = check_tidy($input);
    is_deeply(
        \@errors,
        [
            {
                message => 'JavaScript file is not tidy',
                error   => 'tidy_js'
            }
        ]
    );
};

subtest 'Fix content' => sub {
    plan tests => 2;

    my $tidy_input = <<INPUT;
for (const user of ["Alice", "Bob", "Charlie"]) {
    console.log(user);
}
INPUT

    my $untidy_input = <<INPUT;
for ( const user of ["Alice", "Bob", "Charlie"] ) {
    console.log( user );

}
INPUT

    subtest 'File is tidy' => sub {
        plan tests => 2;
        my $checker = Koha::QA::Tidy::JS->new( { content => $tidy_input } );
        $checker->check();
        is( $checker->fix, $tidy_input, "check called before fix" );

        $checker = Koha::QA::Tidy::JS->new( { content => $tidy_input } );
        is( $checker->fix, $tidy_input, "check not called before fix" );
    };

    subtest 'File is not tidy' => sub {
        plan tests => 2;
        my $checker = Koha::QA::Tidy::JS->new( { content => $untidy_input } );
        $checker->check();
        is( $checker->fix, $tidy_input, "check called before fix" );

        $checker = Koha::QA::Tidy::JS->new( { content => $untidy_input } );
        is( $checker->fix, $tidy_input, "check not called before fix" );
    };
};

subtest 'Specific .perltidyrc' => sub {
    plan tests => 2;

    my ( $fh, $filename ) = tempfile( SUFFIX => '.js', UNLINK => 0, TEMPDIR => 1 );
    print $fh "module.exports = {tabWidth: 2};";
    close $fh;

    my $untidy_input = <<'INPUT';
for (const user of ["Alice", "Bob", "Charlie"]) {
    console.log(user);
}
INPUT

    my $tidy_input = <<'INPUT';
for (const user of ["Alice", "Bob", "Charlie"]) {
  console.log(user);
}
INPUT

    my $checker  = Koha::QA::Tidy::JS->new( { content => $untidy_input, prettierrc => $filename } );
    my $is_valid = $checker->check();
    my @errors   = $checker->errors();
    is_deeply(
        \@errors,
        [
            {
                message => 'JavaScript file is not tidy',
                error   => 'tidy_js'
            }
        ]
    );

    is( $checker->fix, $tidy_input, "check called before fix" );
};

subtest 'File passed via file parameter' => sub {
    plan tests => 2;

    my $tidy_input = <<INPUT;
for (const user of ["Alice", "Bob", "Charlie"]) {
    console.log(user);
}
INPUT

    my $untidy_input = <<INPUT;
for ( const user of ["Alice", "Bob", "Charlie"] ) {
    console.log( user );

}
INPUT

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.js' );
    print $fh $tidy_input;
    close $fh;

    my $checker = Koha::QA::Tidy::JS->new( { file => $filename } );
    my @errors  = $checker->errors() if $checker->check();
    is( scalar @errors, 0, 'Tidy file passed via file parameter should pass tidy check' );

    ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.js' );
    print $fh $untidy_input;
    close $fh;

    $checker = Koha::QA::Tidy::JS->new( { file => $filename } );
    $checker->check();
    is( $checker->fix, $tidy_input, 'Untidy file passed via file parameter should be fixed' );
};

subtest 'Non-existing prettierrc file passed' => sub {
    plan tests => 2;

    my $input = <<INPUT;
File does not exist
INPUT

    my $nonexistent_prettierrc = q{.this-should-not-exist};
    my $checker = Koha::QA::Tidy::JS->new( { content => $input, prettierrc => $nonexistent_prettierrc } );
    $checker->check();
    is_deeply(
        [ $checker->errors ],
        [ { error => 'no_prettierrc', message => qq{prettierrc file not found: $nonexistent_prettierrc} } ]
    );
    is( $checker->fix, undef, 'fix() returns undef rather than silently truncating the file' );
};

subtest 'Broken prettierrc fails the check' => sub {
    plan tests => 5;

    my ( $fh, $broken_prettierrc ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.js' );
    print $fh "this is not valid javascript {{{\n";
    close $fh;

    my $input = <<INPUT;
var x = 1;
INPUT

    my $checker = Koha::QA::Tidy::JS->new( { content => $input, prettierrc => $broken_prettierrc } );
    my $is_valid;
    warning_like { $is_valid = $checker->check() } qr/\[error\]/,
        "check() warns with prettier's config error";
    is( $is_valid, 0, 'check() reports failure' );
    is_deeply(
        [ $checker->errors ],
        [
            {
                error   => 'tidy_js_prettier_failed',
                message => 'prettier failed to process the file, the original content was kept'
            }
        ],
        'check() reports the prettier-failed error, not "not tidy"'
    );

    my $fixed;
    warning_like { $fixed = $checker->fix } qr/\[error\]/, 'fix() re-running check() warns again';
    is( $fixed, undef, 'fix() returns undef rather than silently truncating the file' );
};

subtest 'Prettier fail to parse the content' => sub {
    plan tests => 3;

    my $input = <<'INPUT';
function foo( { console.log("bad");
INPUT

    my $checker = Koha::QA::Tidy::JS->new( { content => $input } );
    my $is_valid;

    warning_like { $is_valid = $checker->check } qr/SyntaxError/,
        "check() warns with prettier's parse error";

    ok( !$is_valid, 'check() reports the file as not tidy when prettier fails to parse it' );
    is_deeply(
        [ $checker->errors ],
        [
            {
                message => 'prettier failed to process the file, the original content was kept',
                error   => 'tidy_js_prettier_failed'
            }
        ],
        'the parse failure is reported'
    );
};

had_no_warnings();
