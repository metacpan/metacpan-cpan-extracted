use strict;
eval 'use warnings';
use Cwd qw(abs_path);
use File::Spec;
use Test::More;

my $has_unidecode = eval "require 5.008; require Text::Unidecode; 1";

# describe the tests
my @one_result_tests = (
    {
        args     => [ File::Spec->catfile(qw(t samples empty)) ], 
        expected => '', 
    }, 
    {
        args     => [ File::Spec->catfile(qw(t samples space)) ], 
        expected => ' ', 
    }, 
    {
        args     => [ File::Spec->catfile(qw(t samples newline)) ], 
        expected => $/, 
    }, 
    {
        args     => [ File::Spec->catfile(qw(t samples pi)) ], 
        expected => "3.14159265358979\n", 
    }, 
    {
        args     => [ File::Spec->catfile(qw(t samples hello)) ], 
        expected => 'Hello', 
    }, 
    {
        args     => [ File::Spec->catfile(qw(t samples world)) ], 
        expected => "world\n",
    }, 
    {
        args     => [ File::Spec->catfile(qw(t samples hello)), 
                      File::Spec->catfile(qw(t samples space)), 
                      File::Spec->catfile(qw(t samples world)), 
                    ], 
        expected => "Hello world\n", 
    }, 
    {
        args     => [ File::Spec->catfile(qw(t samples jerkcity2630)) ], 
        expected => "DEUCE: PLEASE DO THESE STEPS IN THE FOLLOWING ORDERS:\n" .
                    "DEUCE: 1. SHUT UP\n" .
                    "DEUCE: 2. GET THE FUCK OUT\n",
    }, 
    {
        args     => [ File::Spec->catfile(qw(t samples config)) ], 
        expected => "# something that looks like a configuration file\n" .
                    "# with a few comments, and some empty lines\n" .
                    "\n" .
                    "# enable debug\n" .
                    "debug = 1\n" .
                    "\n" .
                    "# be verbose\n" .
                    "verbose = 1\n",
    }, 
    {
        args     => [ { skip_comments => 1 }, File::Spec->catfile(qw(t samples config)) ], 
        expected => "\n" .
                    "debug = 1\n" .
                    "\n" .
                    "verbose = 1\n",
    }, 
    {
        args     => [ { skip_blanks => 1 }, File::Spec->catfile(qw(t samples config)) ], 
        expected => "# something that looks like a configuration file\n" .
                    "# with a few comments, and some empty lines\n" .
                    "# enable debug\n" .
                    "debug = 1\n" .
                    "# be verbose\n" .
                    "verbose = 1\n",
    }, 
    {
        args     => [ { skip_comments => 1, skip_blanks => 1 }, 
                      File::Spec->catfile(qw(t samples config)) ], 
        expected => "debug = 1\n" .
                    "verbose = 1\n",
    }, 
    {
        args     => [ { to_ascii => 1 }, File::Spec->catfile(qw(t samples latin1)) ], 
        expected => $has_unidecode ?    # Text::Unidecode is available
                    "agrave:a  aelig:ae  eacute:e  szlig:ss  eth:d   thorn:th   mu:u\n" .
                    "pound:PS   laquo:<<  raquo:>>   sect:SS   para:P  middot:*\n"
                    : # Text::Unidecode isn't available, non-ASCII chars should be deleted
                    "agrave:  aelig:  eacute:  szlig:  eth:   thorn:   mu:\n" .
                    "pound:   laquo:  raquo:   sect:   para:  middot:\n"
                    ,
    }, 
    {
        args     => [ { as_root => 1 }, 
                      File::Spec->catfile(qw(t samples hello)) ], 
        expected => "ROOT:Hello",
    }, 
);

my @many_results_tests = (
    {
        args     => [ File::Spec->catfile(qw(t samples empty)), 
                      File::Spec->catfile(qw(t samples newline)), 
                      File::Spec->catfile(qw(t samples space)) ], 
        expected => [ '', $/, ' ' ], 
    }, 
    {
        args     => [ { aggregate => 0 }, File::Spec->catfile(qw(t samples jerkcity2630)) ], 
        expected => [ "DEUCE: PLEASE DO THESE STEPS IN THE FOLLOWING ORDERS:\n", 
                      "DEUCE: 1. SHUT UP\n", 
                      "DEUCE: 2. GET THE FUCK OUT\n" ]
    }, 
);


# determine the path of the current perl(1)
my $perl = abs_path($^X) || $^X;
$perl = qq{"$perl"} if $perl =~ m/\s/;

# "I love it when a plan comes together"
plan tests => 7 + @one_result_tests * 2 + @many_results_tests * 3;

# load File::Read
use_ok( "File::Read", "cmd=$perl -pe s/^/ROOT:/" );

# check that the advertised functions are present
can_ok( 'File::Read' => qw(read_file read_files) );

# check that the exported functions are available in the current package
can_ok( __PACKAGE__, qw(read_file read_files) );


# check diagnostics
eval { read_file() };
like( $@, '/^error: This function needs at least one path/', 
    "calling read_file() with no argument" );

eval { read_files() };
like( $@, '/^error: This function needs at least one path/', 
    "calling read_files() with no argument" );

eval { read_file('not/such/file') };
like( $@, q{/^error: read_file 'not/such/file' - /}, 
    "calling read_file() with a file that does not exist" );

eval { read_files({ err_mode => 'pwadak' }) };
like( $@, q{/^error: Bad value 'pwadak' for option 'err_mode'/}, 
    "calling read_files() with invalid value for option 'err_mode'" );


# having Data::Dumper might be useful
eval 'use Data::Dumper';
$Data::Dumper::Indent = 0;
$Data::Dumper::Indent = 0;

# read files, returning one result
for my $test (@one_result_tests) {
    (eval { Dumper($test->{args}) } || '') =~ /\[(.+)\];$/;
    my $args_str = $1 || "@{$test->{args}}";

    my $file = eval { read_file( @{$test->{args}} ) };
    is( $@, '', "calling read_file() with args: $args_str" );
    is( $file, $test->{expected}, "checking result" );
}

# read files, returning several results
for my $test (@many_results_tests) {
    (eval { Dumper($test->{args}) } || '') =~ /\[(.+)\];$/;
    my $args_str = $1 || "@{$test->{args}}";

    my @files = eval { read_file( @{$test->{args}} ) };
    is( $@, '', "calling read_file() with args: $args_str" );
    is( @files, scalar @{ $test->{expected} }, "checking results: number of elements" );
    is_deeply( \@files, $test->{expected}, "checking results: deep compare" );
}

