use Modern::Perl;

use Test::NoWarnings;
use Test::More tests => 5;
use File::Temp qw(tempfile);
use Koha::QA::PerlCritic;

my $expected_messages = {};

sub check_critic {
    my ( $content, $params ) = @_;
    $params ||= {};
    my $checker = Koha::QA::PerlCritic->new( { content => $content, %$params } );
    $checker->check();
    return $checker->errors();
}

subtest '"use strict;" is missing' => sub {
    plan tests => 1;
    my $input = <<INPUT;
use warnings;
print "hello";
INPUT

    my @errors = check_critic($input);
    is_deeply(
        \@errors,
        [
            {
                error       => "perlcritic",
                line        => q{print "hello";},
                line_number => "2",
                message     => "Code before strictures are enabled at line 2, column 1. See page 429 of PBP.",
            }
        ]
    );
};

subtest '"use strict;" not missing' => sub {
    plan tests => 1;
    my $input = <<INPUT;
use strict;
print "hello";
INPUT

    my @errors = check_critic($input);
    is_deeply( \@errors, [], 'use strict; is there' );
};

subtest '"use warnings;" required by specific .perlcriticrc' => sub {
    plan tests => 1;

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1 );
    print $fh
        "severity = 5\ninclude = ProhibitUnusedVariables Objects::ProhibitIndirectSyntax TestingAndDebugging::RequireUseWarnings";
    close $fh;

    my $input = <<INPUT;
use strict;
print "hello";
INPUT

    my @errors = check_critic( $input, { perlcriticrc => $filename } );
    is_deeply(
        \@errors,
        [
            {
                error       => "perlcritic",
                line        => q{print "hello";},
                line_number => 2,
                message     => "Code before warnings are enabled at line 2, column 1. See page 431 of PBP."
            }
        ],
        'use warnings; is required by the specific .perlcriticrc'
    );
};
subtest 'Non-existing perlcriticrc file passed' => sub {
    plan tests => 1;

    my $input = <<INPUT;
File does not exist
INPUT

    my $nonexistent_perlcriticrc = q{.this-should-not-exist};
    my @errors                   = check_critic( $input, { perlcriticrc => $nonexistent_perlcriticrc } );
    is_deeply(
        \@errors,
        [ { error => 'no_perlcriticrc', message => qq{perlcriticrc file not found: $nonexistent_perlcriticrc} } ]
    );
};
