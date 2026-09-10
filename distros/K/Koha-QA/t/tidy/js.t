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
use Test::More tests => 6;
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

subtest 'Non-existing prettierrc file passed' => sub {
    plan tests => 1;

    my $input = <<INPUT;
File does not exist
INPUT

    my $nonexistent_prettierrc = q{.this-should-not-exist};
    my @errors                 = check_tidy( $input, { prettierrc => $nonexistent_prettierrc } );
    is_deeply(
        \@errors,
        [ { error => 'no_prettierrc', message => qq{prettierrc file not found: $nonexistent_prettierrc} } ]
    );
};

had_no_warnings();
