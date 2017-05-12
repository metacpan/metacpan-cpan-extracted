use strict;
use Test::More;
use Data::Dumper;
use Exception::Class::TryCatch 1.10;
use Getopt::Lucid ':all';
use Getopt::Lucid::Exception;
use lib ".";
use t::ErrorMessages;

# Work around win32 console buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

sub why {
    my %vars = @_;
    $Data::Dumper::Sortkeys = 1;
    return "\n" . Data::Dumper->Dump([values %vars],[keys %vars]) . "\n";
}

#--------------------------------------------------------------------------#
# Test cases
#--------------------------------------------------------------------------#

my ($num_tests, @bad_specs, @good_specs);

BEGIN {

    push @good_specs, {
        label => "single short switch",
        spec  => [
            Switch("-v"),
        ],
        cases => [
            {
                argv    => [ qw( -v ) ],
                result  => { "v" => 1 },
                desc    => "switch present"
            },
            {
                argv    => [ qw( ) ],
                result  => { "v" => 0 },
                desc    => "switch missing"
            },
            {
                argv    => [ qw( -t ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("-t"),
                desc    => "invalid command line"
            },
        ]
    };

    push @good_specs, {
        label => "multiple short switches",
        spec  => [
            Switch("-v"),
            Switch("-t"),
        ],
        cases => [
            {
                argv    => [ qw( -v -t ) ],
                result  => { "v" => 1, "t" => 1 },
                desc    => "both switches present"
            },
            {
                argv    => [ qw( -v ) ],
                result  => { "v" => 1, "t" => 0 },
                desc    => "one switch present"
            },
            {
                argv    => [ qw( ) ],
                result  => { "v" => 0, "t" => 0 },
                desc    => "both switches missing"
            },
            {
                argv    => [ qw( -f ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("-f"),
                desc    => "invalid command line"
            },
        ]
    };

    push @good_specs, {
        label => "bundled short switches",
        spec  => [
            Switch("-v"),
            Switch("-t"),
            Switch("-r"),
        ],
        cases => [
            {
                argv    => [ qw( -vrt ) ],
                result  => { "v" => 1, "r" => 1, "t" => 1 },
                desc    => "three switches present"
            },
            {
                argv    => [ qw( -vt ) ],
                result  => { "v" => 1, "r" => 0, "t" => 1 },
                desc    => "two switches present"
            },
            {
                argv    => [ qw( -vfrt ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("-f"),
                desc    => "invalid command line"
            },
        ]
    };

    push @good_specs, {
        label => "short and long switches",
        spec  => [
            Switch("--verbose"),
            Switch("--test"),
            Switch("-r"),
        ],
        cases => [
            {
                argv    => [ qw( --verbose -r --test ) ],
                result  => { "verbose" => 1, "test" => 1, "r" => 1 },
                desc    => "three switches present (2 long and 1 short)"
            },
            {
                argv    => [ qw( -r --test ) ],
                result  => { "verbose" => 0, "test" => 1, "r" => 1 },
                desc    => "two switches present (long and short)"
            },
            {
                argv    => [ qw( --test ) ],
                result  => { "verbose" => 0, "test" => 1, "r" => 0 },
                desc    => "only long switch present"
            },
            {
                argv    => [ qw( --test -v ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("-v"),
                desc    => "invalid command line"
            },
        ]
    };

    push @good_specs, {
        label => "option name aliasing",
        spec  => [
            Switch("--verbose|-v"),
            Switch("--test|--debug|-d"),
            Switch("-r|-s"),
        ],
        cases => [
            {
                argv    => [ qw( -v -s --debug ) ],
                result  => { "verbose" => 1, "test" => 1, "r" => 1 },
                desc    => "three switch aliases used"
            },
            {
                argv    => [ qw( -r -d ) ],
                result  => { "verbose" => 0, "test" => 1, "r" => 1 },
                desc    => "two switches present (alias and regular)"
            },
            {
                argv    => [ qw( --verbose -v ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _switch_twice("--verbose"),
                desc    => "switch used more than once"
            },
        ]
    };

    push @good_specs, {
        label => "'--' terminates options",
        spec  => [
            Switch("--verbose"),
            Switch("--test"),
            Switch("-r"),
        ],
        cases => [
            {
                argv    => [ qw( --verbose -r -- --test ) ],
                result  => { "verbose" => 1, "test" => 0, "r" => 1 },
                after   => [ qw( --test ) ],
                desc    => "stop after two"
            },
            {
                argv    => [ qw( -- -r --test ) ],
                result  => { "verbose" => 0, "test" => 0, "r" => 0 },
                after   => [ qw(-r --test ) ],
                desc    => "stop right away"
            },
        ]
    };

    push @good_specs, {
        label => "two counter",
        spec  => [
            Counter("--verbose|-v"),
            Counter("--count"),
        ],
        cases => [
            {
                argv    => [ qw( --count --verbose -vv --count ) ],
                result  => { "verbose" => 3, "count" => 2 },
                desc    => "one counter used twice, other used thrice"
            },
            {
                argv    => [ qw( --verbose -v ) ],
                result  => { "verbose" => 2, "count" => 0 },
                desc    => "one counter used twice"
            },
            {
                argv    => [ qw( -- ) ],
                result  => { "verbose" => 0, "count" => 0 },
                desc    => "no counters used"
            },
        ]
    };

    push @good_specs, {
        label => "parameter w/o '='",
        spec  => [
            Counter("--verbose|-v"),
            Param("--input|-i"),
        ],
        cases => [
            {
                argv    => [ qw( -- ) ],
                result  => { "verbose" => 0, "input" => undef },
                desc    => "no options"
            },
            {
                argv    => [ qw( --input 42 -vv ) ],
                result  => { "verbose" => 2, "input" => 42 },
                desc    => "counters and long-style parameter"
            },
            {
                argv    => [ qw( -vi 42 ) ],
                result  => { "verbose" => 1, "input" => 42 },
                desc    => "bundled counter and short-style parameter"
            },
            {
                argv    => [ qw( -i 42 --input 3 ) ],
                result  => { "verbose" => 0, "input" => 3 },
                desc    => "repeated param value"
            },
            {
                argv    => [ qw( --input ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _no_value("--input"),
                desc    => "missing param value"
            },
            {
                argv    => [ qw( -i -v ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _param_ambiguous("--input","-v"),
                desc    => "ambiguous param value"
            },
        ]
    };

    push @good_specs, {
        label => "parameter w '='",
        spec  => [
            Switch("--test|-t"),
            Counter("--verbose|-v"),
            Param("--input|-i"),
        ],
        cases => [
            {
                argv    => [ qw( -- ) ],
                result  => { "verbose" => 0, "input" => undef, "test" => 0 },
                desc    => "no options"
            },
            {
                argv    => [ qw( --input=42 -vv ) ],
                result  => { "verbose" => 2, "input" => 42, "test" => 0 },
                desc    => "counters and long-style parameter"
            },
            {
                argv    => [ qw( -vi=42 ) ],
                result  => { "verbose" => 1, "input" => 42, "test" => 0 },
                desc    => "bundled counter and short-style parameter"
            },
            {
                argv    => [ qw( -i=-v ) ],
                result  => { "verbose" => 0, "input" => "-v", "test" => 0 },
                desc    => "ambiguous param value ok w '='"
            },
            {
                argv    => [ qw( --test=42 ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _switch_value("--test","42"),
                desc    => "switch with equals"
            },
            {
                argv    => [ qw( --verbose=42 ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _counter_value("--verbose","42"),
                desc    => "counter with equals"
            },
        ]
    };

    push @good_specs, {
        label => "lists (w or w/o '=')",
        spec  => [
            Counter("--verbose|-v"),
            List("--input|-i"),
        ],
        cases => [
            {
                argv    => [ qw( -- ) ],
                result  => { "verbose" => 0, "input" => [] },
                desc    => "no options"
            },
            {
                argv    => [ qw( --input 42 -vv ) ],
                result  => { "verbose" => 2, "input" => [42] },
                desc    => "counters and one list arg"
            },
            {
                argv    => [ qw( --input 42 -vvi=twelve ) ],
                result  => { "verbose" => 2, "input" => [42,"twelve"] },
                desc    => "counters and two list args"
            },
            {
                argv    => [ qw( -i -v ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _param_ambiguous("--input","-v"),
                desc    => "ambiguous param value"
            },
            {
                argv    => [ qw( -i=-v --input=-i) ],
                result  => { "verbose" => 0, "input" => ["-v", "-i"] },
                desc    => "ambiguous param value ok w '='"
            },
        ]
    };

    push @good_specs, {
        label => "pass through non-switch args",
        spec  => [
            Switch("-v"),
        ],
        cases => [
            {
                argv    => [ qw( word1 -v word2 ) ],
                result  => { "v" => 1 },
                after   => [ qw( word1 word2 ) ],
                desc    => "switch in middle"
            },
            {
                argv    => [ qw( word1 -v -- -t ) ],
                result  => { "v" => 1 },
                after   => [ qw( word1 -t ) ],
                desc    => "switch before '--' and arg"
            },
            {
                argv    => [ qw( -v - ) ],
                result  => { "v" => 1 },
                after   => [ qw( - ) ],
                desc    => "single dash"
            },
            {
                argv    => [ qw( -v -t ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("-t"),
                desc    => "invalid command line"
            },
        ]
    };

    push @good_specs, {
        label => "keypairs (w or w/o =)",
        spec  => [
            Counter("--verbose|-v"),
            Keypair("--input|-i"),
        ],
        cases => [
            {
                argv    => [ qw( -- ) ],
                result  => { "verbose" => 0, "input" => {} },
                desc    => "no options"
            },
            {
                argv    => [ qw( --input n=42 -vv ) ],
                result  => { "verbose" => 2, "input" => { n => 42} },
                desc    => "counters and one keypair arg"
            },
            {
                argv    => [ qw( --input n=42 -vvi=p=twelve ) ],
                result  => {
                    "verbose" => 2,
                    "input" => { n => 42, p => "twelve"}
                },
                desc    => "counters and two keypair args"
            },
            {
                argv    => [ qw( -i -v ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _keypair("--input"),
                desc    => "keypair missing value (no '=')"
            },
            {
                argv    => [ qw( -i=-v --input=-i) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _keypair("--input"),
                desc    => "keypair missing value (w '=')"
            },
            {
                argv    => [ qw( -i==-v ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _keypair("--input"),
                desc    => "keypair missing key (w '=')"
            },
        ]
    };

    push @good_specs, {
        label => "bareword options",
        spec  => [
            Counter("verbose|v"),
            Param("input|i"),
        ],
        cases => [
            {
                argv    => [ qw( -- ) ],
                result  => { "verbose" => 0, "input" => undef },
                desc    => "no options"
            },
            {
                argv    => [ qw( input 42 v v ) ],
                result  => { "verbose" => 2, "input" => 42 },
                desc    => "counters and longstyle parameter"
            },
            {
                argv    => [ qw( i 42 input 3 ) ],
                result  => { "verbose" => 0, "input" => 3 },
                desc    => "repeated param value"
            },
        ]
    };

    push @good_specs, {
        label => "required options",
        spec  => [
            Counter("--verbose|-v"),
            Param("--input|-i")
        ],
        cases => [
            {
                argv    => [ qw( -v ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _required("--input"),
                required => ['input'],
                desc    => "missing required option"
            },
            {
                argv    => [ qw( --input 42 -vv ) ],
                required => ['input'],
                result  => { "verbose" => 2, "input" => 42 },
                desc    => "required option present"
            },
            {
                argv    => [ qw( --input info -v ) ],
                required => ['input'],
                result  => { "verbose" => 1, "input" => 'info' },
                desc    => "required option param similar to option name"
            },
        ]
    };

    push @good_specs, {
        label => "default values",
        spec  => [
            Switch("--quick")->default(1),
            Counter("--verbose|-v")->default(1),
            Param("--input")->default(42),
            List("--lib")->default(qw( one two )),
            Keypair("--flag")->default(answer => 42),
        ],
        cases => [
            {
                argv    => [ qw(  ) ],
                result  => {
                    "quick" => 1,
                    "verbose" => 1,
                    "input" => 42,
                    "lib" => [qw( one two )],
                    "flag" => { answer => 42 },
                },
                desc    => "no options"
            },
            {
                argv    => [ qw( -v ) ],
                result  => {
                    "quick" => 1,
                    "verbose" => 2,
                    "input" => 42,
                    "lib" => [qw( one two )],
                    "flag" => { answer => 42 },
                },
                desc    => "one option given, other default"
            },
            {
                argv    => [ qw( --input 23 -vv ) ],
                result  => {
                    "quick" => 1,
                    "verbose" => 3,
                    "input" => 23,
                    "lib" => [qw( one two )],
                    "flag" => { answer => 42 },
                },
                desc    => "two options given"
            },
        ]
    };

    push @good_specs, {
        label => "case insensitive",
        spec  => [
            Counter("--verbose|-v")->default(1)->anycase,
            Param("--input|-i|-r")->default(42),
        ],
        cases => [
            {
                argv    => [ qw(  ) ],
                result  => { "verbose" => 1, "input" => 42, },
                desc    => "no options"
            },
            {
                argv    => [ qw( -v ) ],
                result  => { "verbose" => 2, "input" => 42, },
                desc    => "two lower case options given"
            },
            {
                argv    => [ qw( --verBose -vV -r 23 ) ],
                result  => { "verbose" => 4, "input" => 23, },
                desc    => "mixed cases for case insensitive (alt)"
            },
            {
                argv    => [ qw( --verBose -vV --input 23 ) ],
                result  => { "verbose" => 4, "input" => 23, },
                desc    => "mixed cases for case insensitive"
            },
            {
                argv    => [ qw( --INPUT ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _invalid_argument("--INPUT"),
                desc    => "bad case for case sensitive option"
            },
        ]
    };

    push @good_specs, {
        label => "validate w/ regex",
        spec  => [
            Counter("--verbose|-v")->default(1),
            Param("--input|-i", qr/\d+/)->default(42),
            List("--lib", qr/\w*/),
            Keypair("--def", qr/(os)*/, qr/^(win32|linux|mac)/),
        ],
        cases => [
            {
                argv    => [ qw(  ) ],
                result  => {
                    "verbose" => 1,
                    "input" => 42,
                    "lib" => [],
                    "def" => {},
                },
                desc    => "no options"
            },
            {
                argv    => [ qw( --input 23 ) ],
                result  => {
                    "verbose" => 1,
                    "input" => 23,
                    "lib" => [],
                    "def" => {},
                },
                desc    => "param input validates"
            },
            {
                argv    => [ qw( --lib foo --lib bar ) ],
                result  => {
                    "verbose" => 1,
                    "input" => 42,
                    "lib" => [qw(foo bar)],
                    "def" => {},
                },
                desc    => "list input validates"
            },
            {
                argv    => [ qw( --def os=linux ) ],
                result  => {
                    "verbose" => 1,
                    "input" => 42,
                    "lib" => [],
                    "def" => { os => "linux" },
                },
                desc    => "keypair input validates"
            },
            {
                argv    => [ qw( --input twenty-three ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _param_invalid("--input","twenty-three"),
                desc    => "param input not validating"
            },
            {
                argv    => [ qw( --lib foo --lib % ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _list_invalid("--lib","%"),
                desc    => "list input not validating"
            },
            {
                argv    => [ qw( --def os=amiga ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _keypair_invalid("--def","os","amiga"),
                desc    => "keypair value not validating"
            },
            {
                argv    => [ qw( --def arch=i386 ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _keypair_invalid("--def","arch","i386"),
                desc    => "keypair key not validating"
            },
        ]
    };

    push @good_specs, {
        label => "validate but allow missing options",
        spec  => [
            Param( "mode|m", qr/test|live/ )
        ],
        cases => [
            {
                argv    => [ qw() ],
                result  => {
                    "mode" => undef,
                },
                desc    => "no param validates"
            },
            {
                argv    => [ qw( --mode test ) ],
                result  => {
                    "mode" => 'test',
                },
                desc    => "param input validates"
            },
            {
                argv    => [ qw( --mode foo ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _param_invalid("mode","foo"),
                desc    => "param mode not validating"
            },
        ]
    };

    push @good_specs, {
        label => "validate w/ string alternation regex",
        spec  => [
            Param( "mode|m", qr/test|live/ ),
        ],
        cases => [
            {
                argv    => [ qw( --mode test ) ],
                required => ['mode'],
                result  => {
                    "mode" => 'test',
                },
                desc    => "param input validates"
            },
            {
                argv    => [ qw( --mode foo ) ],
                required => ['mode'],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _param_invalid("mode","foo"),
                desc    => "param mode not validating"
            },
        ]
    };

    push @good_specs, {
        label => "validate only keypair key",
        spec  => [
            Keypair("--def", qr/(os)*/),
        ],
        cases => [
            {
                argv    => [ qw( --def os=linux ) ],
                result  => {
                    "def" => { os => "linux" },
                },
                desc    => "keypair input validates"
            },
            {
                argv    => [ qw( --def arch=i386 ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _keypair_invalid("--def","arch", "i386"),
                desc    => "key not validating"
            },
        ]
    };

    push @good_specs, {
        label => "validate only keypair value",
        spec  => [
            Keypair("--def", undef, qr/(linux|win32)*/),
        ],
        cases => [
            {
                argv    => [ qw( --def os=linux ) ],
                result  => {
                    "def" => { os => "linux" },
                },
                desc    => "keypair input validates"
            },
            {
                argv    => [ qw( --def os=amiga ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _keypair_invalid("--def","os","amiga"),
                desc    => "value not validating"
            },
        ]
    };

    push @good_specs, {
        label => "validate w/ code refs",
        spec  => [
            Counter("--verbose|-v")->default(1),
            Param("--input|-i", sub { /\d+/ })->default(42),
            Param("--answer", sub { $_ < 43  })->default(23),
        ],
        cases => [
            {
                argv    => [ qw(  ) ],
                result  => { "verbose" => 1, "input" => 42, "answer" => 23 },
                desc    => "no options"
            },
            {
                argv    => [ qw( --input 23 ) ],
                result  => { "verbose" => 1, "input" => 23, "answer" => 23 },
                desc    => "input validates"
            },
            {
                argv    => [ qw( --answer 60 ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _param_invalid("--answer","60"),
                desc    => "input failing to validate"
            },
        ]
    };

    push @good_specs, {
        label => "single dependency",
        spec  => [
            Param("--question"),
            Switch("--guess")->needs("--answer"),
            Param("--answer|-a"),
        ],
        cases => [
            {
                argv    => [ qw( --question 5 ) ],
                result  => { "question" => 5, "guess" => 0, "answer" => undef },
                desc    => "single, unrelated option"
            },
            {
                argv    => [ qw( --guess ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _prereq_missing("--guess", "--answer"),
                desc    => "missing prereq"
            },
            {
                argv    => [ qw( --guess --answer 3 ) ],
                result  => { "question" => undef, "guess" => 1, "answer" => "3" },
                desc    => "prereq present"
            },
            {
                argv    => [ qw( --guess -a 3 ) ],
                result  => { "question" => undef, "guess" => 1, "answer" => "3" },
                desc    => "prereq present as alias"
            },
        ]
    };

    push @good_specs, {
        label => "multiple dependencies",
        spec  => [
            Switch("--guess")->needs(qw( --answer --wager )),
            Param("--wager|-w"),
            Param("--answer|-a"),
        ],
        cases => [
            {
                argv    => [ qw( ) ],
                result  => { "guess" => 0, "answer" => undef, wager => undef },
                desc    => "no options"
            },
            {
                argv    => [ qw( --guess ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _prereq_missing("--guess", "--answer"),
                desc    => "missing both prereqs"
            },
            {
                argv    => [ qw( --guess --answer 5 ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _prereq_missing("--guess", "--wager"),
                desc    => "missing one prereq"
            },
            {
                argv    => [ qw( --guess --answer 3 --wager 10 ) ],
                result  => { "guess" => 1, "answer" => 3, "wager" => 10 },
                desc    => "prereq present"
            },
        ]
    };

    push @good_specs, {
        label => "single dependency with alias",
        spec  => [
            Param("--question"),
            Switch("--guess")->needs("-a"),
            Param("--answer|-a"),
        ],
        cases => [
            {
                argv    => [ qw( --guess ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _prereq_missing("--guess", "--answer"),
                desc    => "missing prereq"
            },
            {
                argv    => [ qw( --guess --answer 3 ) ],
                result  => { "question" => undef, "guess" => 1, "answer" => "3" },
                desc    => "prereq present"
            },
            {
                argv    => [ qw( --guess -a 3 ) ],
                result  => { "question" => undef, "guess" => 1, "answer" => "3" },
                desc    => "prereq present as alias"
            },
        ]
    };

    push @good_specs, {
        label => "dash and underscore options",
        spec  => [
            Switch("--dash-style"),
            Switch("--underscore_style"),
        ],
        cases => [
            {
                argv    => [ qw( --dash-style ) ],
                result  => { "dash-style" => "1", "underscore_style" => "0" },
                desc    => "dash-style name works",
            },
            {
                argv    => [ qw( --underscore_style ) ],
                result  => { "dash-style" => "0", "underscore_style" => "1" },
                desc    => "underscore_style name works",
            },
        ]
    };

    push @good_specs, {
        label => "Null Param,List,Keypair",
        spec  => [
            Param("--param"),
            List("--list"),
            Keypair("--key-pair"),
        ],
        cases => [
            {
                argv    => [ qw( --param ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _no_value("--param"),
                desc    => "parameter with no value",
            },
            {
                argv    => [ qw( --list ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _no_value("--list"),
                desc    => "list with no value",
            },
            {
                argv    => [ qw( --key-pair ) ],
                exception   => "Getopt::Lucid::Exception::ARGV",
                error_msg => _no_value("--key-pair"),
                desc    => "keypair with no value",
            },

        ]
    };


    # Bad specification testing

    push @bad_specs, {
        spec  => [
            Switch("-v|--verbose"),
            Switch("--verbose"),
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _name_not_unique("--verbose"),
        label => "duplicate name and alias in spec"
    };

    push @bad_specs, {
        spec  => [
            Switch("--quick|-q"),
            Switch("--quiet|-q"),
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _name_not_unique("-q"),
        label => "duplicate aliases in spec"
    };

    push @bad_specs, {
        spec  => [
            Switch("--quick"),
            Switch("quick"),
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _name_not_unique("quick"),
        label => "duplicate name bareword and long"
    };

    push @bad_specs, {
        spec  => [
            Switch("-vv"),
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _name_invalid("-vv"),
        label => "bad option name in spec - short w/ > 1 letter"
    };

    push @bad_specs, {
        spec  => [
            Switch("--%%"),
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _name_invalid("--%%"),
        label => "bad option name in spec - symbols"
    };

    push @bad_specs, {
        spec  => [
            { name => "-v", badtype => "badtype" },
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _key_invalid("badtype"),
        label => "bad spec key"
    };

    push @bad_specs, {
        spec  => [
            { name => "-v", type => "badtype" }
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _type_invalid("badtype"),
        label => "bad spec type"
    };

    push @bad_specs, {
        spec  => [
            { name => "-v", type => "alist" },
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _type_invalid("alist"),
        label => "bad spec type w valid substring"
    };

    push @bad_specs, {
        spec  => [
            Keypair("-v")->default([]),
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _default_keypair("-v"),
        label => "keypair default not hash reference"
    };

    push @bad_specs, {
        spec  => [
            Param("-v", qr/[a-z]+/)->default(1),
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _default_invalid("-v","1"),
        label => "provided default not validating vs regex"
    };

    push @bad_specs, {
        spec  => [
            Switch("--guess")->needs(qw( --answer --wager )),
            Switch("--answer|-a"),
        ],
        exception => "Getopt::Lucid::Exception::Spec",
        error_msg => _unknown_prereq("--wager","--guess"),
        label => "unknown prereq",
    };
    

} #BEGIN

$num_tests = 2 * @bad_specs;
for my $t (@good_specs) {
    $num_tests += 1 + 2 * @{$t->{cases}};
}

plan tests => $num_tests;

#--------------------------------------------------------------------------#
# Test good specs
#--------------------------------------------------------------------------#

my $trial;

while ( $trial = shift @good_specs ) {
    try eval { Getopt::Lucid->new($trial->{spec}) };
    catch my $err;
    is( $err, undef, "$trial->{label}: spec should validate" );
    SKIP: {
        if ($err) {
            my $num_tests = 2 * @{$trial->{cases}};
            skip "because $trial->{label} spec did not validate", $num_tests;
        }
        for my $case ( @{$trial->{cases}} ) {
            my $gl = Getopt::Lucid->new($trial->{spec});
            @ARGV = @{$case->{argv}};
            my %opts;
            my $valid_args = $case->{required}  ? {requires => $case->{required}}
                                                : {};
            try eval { %opts = $gl->getopt->validate($valid_args)->options };
            catch my $err;
            if (defined $case->{exception}) { # expected
                ok( $err && $err->isa( $case->{exception} ),
                    "$trial->{label}: $case->{desc} throws exception" )
                    or diag why( got => ref($err), expected => $case->{exception});
                is( $err, $case->{error_msg},
                    "$trial->{label}: $case->{desc} error msg ok");
            } elsif ($err) { # unexpected
                fail( "$trial->{label}: $case->{desc}")
                    or diag "Threw exception: '$err'";
                pass("$trial->{label}: skipping \@ARGV check");
            } else { # no exception
                is_deeply( \%opts, $case->{result},
                    "$trial->{label}: $case->{desc}" ) or
                    diag why( got => \%opts, expected => $case->{result});
                my $argv_after = $case->{after} || [];
                is_deeply( \@ARGV, $argv_after,
                    "$trial->{label}: \@ARGV correct afterwards") or
                    diag why( got => \@ARGV, expected => $argv_after);
            }
        }
    }
}

#--------------------------------------------------------------------------#
# Test bad specs
#--------------------------------------------------------------------------#

while ( $trial = shift @bad_specs ) {
    try eval { Getopt::Lucid->new($trial->{spec}) };
    catch my $err;
    ok( $err && $err->isa( $trial->{exception} ),
        "$trial->{label} throws exception" )
        or diag why( got => ref($err), expected => $trial->{exception});
    is( $err, $trial->{error_msg}, "$trial->{label} error msg ok");
}


