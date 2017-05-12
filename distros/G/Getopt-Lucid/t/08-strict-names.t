use strict;
use Test::More;
use Data::Dumper;
use Exception::Class::TryCatch;

# Work around win32 console buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

use Getopt::Lucid ':all';
use Getopt::Lucid::Exception;
use lib ".";
use t::ErrorMessages;

sub why {
    my %vars = @_;
    $Data::Dumper::Sortkeys = 1;
    return "\n" . Data::Dumper->Dump([values %vars],[keys %vars]) . "\n";
}

#--------------------------------------------------------------------------#
# Test cases
#--------------------------------------------------------------------------#

my ($num_tests, @good_specs);

BEGIN {

    push @good_specs, {
        label => "mixed format names in spec",
        spec  => [
            Counter("ver-bose|-v"),
            Counter("--test|-t"),
            Counter("-r"),
            Param("f"),
        ],
        cases => [
            {
                argv    => [ qw( ver-bose -v -rtv f=test -r --test -- test ) ],
                result  => {
                    "ver-bose" => 3,
                    "test" => 2,
                    "r" => 2,
                    "f" => "test",
                },
                after   => [qw( test )],
                desc    => "all three types in command line"
            },
            {
                argv    => [ qw( ver-bose -v -rtv f test -r --test -- test ) ],
                result  => {
                    "ver-bose" => 3,
                    "test" => 2,
                    "r" => 2,
                    "f" => "test",
                },
                after   => [qw( test )],
                desc    => "bare param with bare like long-form in spec"
            },
            {
                argv    => [ qw( ver-bose -v -rtv f=test -r test ) ],
                result  => {
                    "ver-bose" => 3,
                    "test" => 1,
                    "r" => 2,
                    "f" => "test",
                },
                after   => [qw( test )],
                desc    => "bareword like long-form in spec passed through"
            },
            {
                argv    => [ qw( -test ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("-e"),
                desc    => "single dash with word"
            },
            {
                argv    => [ qw( --ver-bose ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("--ver-bose"),
                desc    => "long form like bareword in spec"
            },
            {
                argv    => [ qw( --r ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("--r"),
                desc    => "long form like short in spec"
            },
            {
                argv    => [ qw( -f=--test ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("-f"),
                desc    => "shoft form like bare in spec"
            },
        ]
    };


} #BEGIN

for my $t (@good_specs) {
    $num_tests += 1 + 2 * @{$t->{cases}};
}

plan tests => $num_tests;

#--------------------------------------------------------------------------#
# Test good specs
#--------------------------------------------------------------------------#

my ($trial, @cmd_line);

while ( $trial = shift @good_specs ) {
    try eval { Getopt::Lucid->new($trial->{spec}, \@cmd_line, {strict => 1}) };
    catch my $err;
    is( $err, undef, "$trial->{label}: spec should validate" );
    SKIP: {
        if ($err) {
            my $num_tests = 2 * @{$trial->{cases}};
            skip "because $trial->{label} spec did not validate", $num_tests;
        }
        for my $case ( @{$trial->{cases}} ) {
            my $gl = Getopt::Lucid->new($trial->{spec}, \@cmd_line, {strict => 1});
            @cmd_line = @{$case->{argv}};
            my %opts;
            try eval { %opts = $gl->getopt->options };
            catch my $err;
            if (defined $case->{exception}) { # expected
                ok( $err && $err->isa( $case->{exception} ),
                    "$trial->{label}: $case->{desc} should throw exception" )
                    or diag why( got => ref($err), expected => $case->{exception});
                is( $err, $case->{error_msg},
                    "$trial->{label}: $case->{desc} error message correct");
            } elsif ($err) { # unexpected
                fail( "$trial->{label}: $case->{desc} threw an exception")
                    or diag "Exception is '$err'";
                pass("$trial->{label}: skipping \@ARGV check");
            } else { # no exception
                is_deeply( \%opts, $case->{result},
                    "$trial->{label}: $case->{desc}" ) or
                    diag why( got => \%opts, expected => $case->{result});
                my $argv_after = $case->{after} || [];
                is_deeply( \@cmd_line, $argv_after,
                    "$trial->{label}: \@cmd_line correct after processing") or
                    diag why( got => \@cmd_line, expected => $argv_after);
            }
        }
    }
}


