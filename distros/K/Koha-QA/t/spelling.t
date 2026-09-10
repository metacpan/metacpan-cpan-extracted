use Modern::Perl;

use IPC::Run3;

BEGIN {
    # Check if codespell is available
    my ( $stdout, $stderr );
    eval { run3( [ 'codespell', '--version' ], undef, \$stdout, \$stderr ) };
    if ( $@ || $? != 0 ) {
        print "1..0 # skip codespell is not available\n";
        exit 0;
    }
}

use Test::NoWarnings qw(had_no_warnings);
use Test::More tests => 6;
use File::Temp qw(tempfile);

use Koha::QA::Spelling;

my $expected_messages = {};

sub check_spelling {
    my ( $content, $params ) = @_;
    $params ||= {};
    my $checker = Koha::QA::Spelling->new( { content => $content, %$params } );
    $checker->check();
    return $checker->errors();
}

subtest '"Checking" is ok' => sub {
    plan tests => 1;
    my $input = <<INPUT;
Checking is not a spelling error
INPUT

    my @errors = check_spelling($input);
    is( scalar @errors, 0 );
};

subtest '"Checkin" is not ok' => sub {
    plan tests => 1;
    my $input = <<INPUT;
one
two
Checkin is a spelling error
four
INPUT

    my @errors = check_spelling($input);
    is_deeply(
        \@errors,
        [
            {
                error       => 'spelling',
                line_number => 3,
                line        => 'Checkin is a spelling error',
                message     => 'Spelling error: Checkin ==> Checking, Check in',
            }
        ]
    );
};

subtest 'checkin is ok (in the ignore file)' => sub {
    plan tests => 1;

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1 );
    print $fh 'checkin';
    close $fh;

    my $input = <<INPUT;
Checkin is a no longer a spelling error
INPUT

    my @errors = check_spelling( $input, { ignore_file => $filename } );
    is( scalar @errors, 0 );
};

subtest '"isnt(" is an exception' => sub {
    plan tests => 1;

    my $input = <<INPUT;
isnt(1, 0);
INPUT

    my @errors = check_spelling($input);
    is( scalar @errors, 0 );
};

subtest 'Non-existing ignore file passed' => sub {
    plan tests => 2;

    my $input = <<INPUT;
File does not exist
INPUT

    my $nonexistent_ignore = q{.this-should-not-exist};
    my @errors             = check_spelling( $input, { ignore_file => $nonexistent_ignore } );
    is( scalar @errors,        1 );
    is( $errors[0]->{message}, qq{codespell ignore file not found: $nonexistent_ignore} );
};
