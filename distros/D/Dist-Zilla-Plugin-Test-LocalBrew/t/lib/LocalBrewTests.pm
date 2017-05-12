package LocalBrewTests::CustomHarness;

use strict;
use warnings;
use parent 'TAP::Harness';

use MRO::Compat;

sub make_parser {
    my $self = shift;

    my ( $parser, $session ) = $self->next::method(@_);

    $parser->callback(ALL => sub {
        my ( $result ) = @_;

        push @{ $self->{'lines' } }, $result->raw;
    });

    return ( $parser, $session );
}

sub output {
    my ( $self ) = @_;

    return join("\n", @{ $self->{'lines' }});
}

package LocalBrewTests;

use strict;
use warnings;

use Test::More;

use parent 'Exporter';

our @EXPORT_OK = qw(tests_fail tests_pass test_has_no_tests);

sub tests_fail {
    my ( $test_file ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tap = LocalBrewTests::CustomHarness->new({
        verbosity => -3,
        merge     => 1,
    });

    my $agg = $tap->runtests($test_file . '');
    ok $agg->failed, "running $test_file should fail";
    isnt $agg->get_status, 'NOTESTS', "running $test_file shouldn't skip anything";

    if(!$agg->failed || $agg->get_status eq 'NOTESTS') {
        my $output = $tap->output;
        $output    =~ s/^/  /mg;
        diag("TAP Output:\n$output");
    }
}

sub tests_pass {
    my ( $test_file ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tap = LocalBrewTests::CustomHarness->new({
        verbosity => -3,
        merge     => 1,
    });

    my $agg = $tap->runtests($test_file . '');
    ok !$agg->failed, "running $test_file should pass";
    isnt $agg->get_status, 'NOTESTS', "running $test_file shouldn\'t skip anything";

    if($agg->failed || $agg->get_status eq 'NOTESTS') {
        my $output = $tap->output;
        $output    =~ s/^/  /mg;
        diag("TAP Output:\n$output");
    }
}

sub test_has_no_tests {
    my ( $test_file ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tap = LocalBrewTests::CustomHarness->new({
        verbosity => -3,
        merge     => 1,
    });

    my $agg = $tap->runtests($test_file . '');
    is $agg->get_status, 'NOTESTS', "running $test_file should skip tests";

    if($agg->get_status ne 'NOTESTS') {
        my $output = $tap->output;
        $output    =~ s/^/  /mg;
        diag("TAP Output:\n$output");
    }
}

1;
