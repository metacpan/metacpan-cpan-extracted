use Modern::Perl;

use Test::More tests => 4;
use Test::NoWarnings;
use File::Temp qw(tempfile);
use Koha::QA::PodChecker;

my $expected_messages = {};

sub check_pod {
    my ( $content, $params ) = @_;
    $params ||= {};
    my $checker = Koha::QA::PodChecker->new( { content => $content, %$params } );
    $checker->check();
    return $checker->errors();
}

subtest 'Valid POD' => sub {
    plan tests => 1;
    my $input = <<'INPUT';
=head1 NAME

Koha::QA - Quality Assurance utilities for Koha

=head1 SYNOPSIS

    use Koha::QA;

=head1 DESCRIPTION

This is a namespace for Koha Quality Assurance modules.

It provides reusable QA checks and utilities.

=cut
INPUT

    my @errors = check_pod($input);
    is( scalar @errors, 0, 'Valid Perl code should have no errors' );
};

subtest 'Invalid POD - error' => sub {
    plan tests => 1;
    my $input = <<'INPUT';
=head2 NAME

Koha::QA - Quality Assurance utilities for Koha

=cut
INPUT

    my @errors = check_pod($input);
    is_deeply(
        \@errors,
        [
            {
                error       => "pod_checker_warning",
                message     => "=head2 without preceding higher level",
                line        => "=head2 NAME",
                line_number => 1,
            }
        ]
    );

};

subtest 'Invalid POD - warning' => sub {
    plan tests => 1;
    my $input = <<'INPUT';
=had2 NAME

Koha::QA - Quality Assurance utilities for Koha

=cut
INPUT

    my @errors = check_pod($input);
    is_deeply(
        \@errors,
        [
            {
                error       => "pod_checker_error",
                message     => "Unknown directive: =had2",
                line        => "=had2 NAME",
                line_number => 1,
            }
        ]
    );
};
