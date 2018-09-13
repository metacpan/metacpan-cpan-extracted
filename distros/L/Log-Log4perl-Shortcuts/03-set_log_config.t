#/usr/bin/env perl
use TestUtils;
use Test::More;
use Test::Warn;
use Test::Fatal;
use Data::Dumper;
use Test::Exception;
use Test::NoWarnings;
use ____;
diag( "Running my tests" );






my $tests = 3; # keep on line 17 for ,i (increment and ,d (decrement)

my @modules = qw/ /;
my @methods = qw/ /;
my %attribs = ('' => {
                        type => '',
                        lazy => 0,
                        read => '',
                        req  => 1,
                     },
);

plan tests => $tests;

# class tests
subtest 'module checks' => \&module_check, @modules;
subtest 'attribute check' => \&attrib_check, ('___', \%attribs);
subtest 'method check' => \&method_check, ('___', @methods);

# create an object
my $obj = ____->new( );

# change as appropriate
dies_ok { my $obj = ___->new() } 'Should die when not passed an argument';
#livesok { my $obj = ___->new() } 'Should live when not passed an argument';


# more tests here below

