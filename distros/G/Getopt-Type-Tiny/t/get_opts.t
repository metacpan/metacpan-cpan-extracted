#!/usr/bin/env perl

use v5.20.0;
use feature 'postderef';
use Test::Most;
use PerlX::Maybe       qw(maybe);
use Getopt::Type::Tiny qw(get_opts ArrayRef HashRef Str Int Num Bool PositiveInt NonEmptyStr Any InstanceOf);

# Helper package
package Local::Credentials {
    sub new       { my $class = shift; bless { @_ }, $class }
    sub username  { shift->{username} }
    sub password  { shift->{password} }

    sub from_string {
        my $class = shift;
        my ( $u, $p ) = split /:/, shift;
        return $class->new( username => $u, password => $p );
    }
}

my $Credentials = InstanceOf->of('Local::Credentials')->plus_constructors(Str, 'from_string');

# Helper function to simulate command line arguments
sub with_args {
    my %arg_for = @_;
    local @ARGV = $arg_for{argv} ? $arg_for{argv}->@* : ();
    return get_opts( $arg_for{spec} ? $arg_for{spec}->@* : () );
}

my @test_cases = (
    'Basic functionality' => {
        argv => [ '--foo', 'test', '--bar', '42', '--baz' ],
        spec => [
            'foo' => { isa => Str },
            'bar' => { isa => Int },
            'baz',
        ],
        expected => {
            foo => 'test',
            bar => 42,
            baz => 1,
        },
    },
    'Default values' => {
        spec => [
            'foo' => { default => 'default_foo', isa => Str },
            'bar' => { default => 10,            isa => Int },
            'baz' => { default => 0 },
        ],
        expected => {
            foo => 'default_foo',
            bar => 10,
            baz => 0,
        },
    },
    'Required options' => {
        spec     => [ 'foo' => { required => 1, isa => Int } ],
        expected => qr/Required option 'foo' is missing/,
    },
    'Required option provided' => {
        argv     => [ '--foo', 'bar' ],
        spec     => [ foo => { required => 1, isa => Str } ],
        expected => { foo => 'bar' },
    },
    'Type checking' => {
        argv     => [ '--foo', 'not_an_int' ],
        spec     => [ 'foo' => { isa => Int } ],
        expected => qr/Invalid value for option 'foo'/,
    },
    'Renaming options' => {
        argv     => [ '--foo', 'test' ],
        spec     => [ 'foo' => { rename => 'bar', isa => Str } ],
        expected => { bar => 'test' },
    },
    'Boolean options' => {
        argv     => ['--foo'],
        spec     => ['foo'],        # Bool is the default type
        expected => { foo => 1 },
    },
    'Negated boolean options' => {
        argv     => ['--nofoo'],
        spec     => ['foo!'],
        expected => { foo => 0 },
    },
    'Multi-valued options' => {
        argv     => [ '--foo',  'bar', '--foo', 'baz' ],
        spec     => [ 'foo=s@', { isa => ArrayRef [Str] } ],
        expected => { foo => [ 'bar', 'baz' ] },
    },
    'Multi-valued options without options' => {
        argv     => [],
        spec     => [ 'foo=s@', { isa => ArrayRef [Str], default => sub { [] } } ],
        expected => { foo => [] },
    },
    'Backwards compatible explicit syntax' => {
        argv     => [ '--foo', 'bar', '--foo', 'baz' ],
        spec     => [ 'foo=s@' => { isa => ArrayRef [Str] } ],
        expected => { foo => [ 'bar', 'baz' ] },
    },
    'ArrayRef[Str] auto-inference' => {
        argv     => [ '--servers', 'alpha', '--servers', 'beta' ],
        spec     => [ servers => { isa => ArrayRef [Str] } ],
        expected => { servers => [ 'alpha', 'beta' ] },
    },
    'Bare ArrayRef error' => {
        spec     => [ servers => { isa => ArrayRef } ],
        expected => qr/Unsupported type 'ArrayRef' for option 'servers'/,
    },
    'Unsupported inner type error' => {
        spec     => [ data => { isa => ArrayRef [HashRef [Str]] } ],
        expected => qr/Unsupported type 'ArrayRef\[HashRef\[Str\]\]' for option 'data'/,
    },
    'ArrayRef auto-default' => {
        argv     => [],
        spec     => [ servers => { isa => ArrayRef [Str] } ],
        expected => { servers => [] },
    },
    'HashRef auto-default' => {
        argv     => [],
        spec     => [ config => { isa => HashRef [Str] } ],
        expected => { config => {} },
    },
    'User default overrides auto-default' => {
        argv     => [],
        spec     => [ servers => { isa => ArrayRef [Str], default => sub { ['localhost'] } } ],
        expected => { servers => ['localhost'] },
    },
    'ArrayRef[Int] auto-inference' => {
        argv     => [ '--ports', '80', '--ports', '443' ],
        spec     => [ ports => { isa => ArrayRef [Int] } ],
        expected => { ports => [ 80, 443 ] },
    },
    'ArrayRef[Num] auto-inference' => {
        argv     => [ '--values', '1.5', '--values', '2.5' ],
        spec     => [ values => { isa => ArrayRef [Num] } ],
        expected => { values => [ 1.5, 2.5 ] },
    },
    'HashRef[Str] auto-inference' => {
        argv     => [ '--env', 'FOO=bar', '--env', 'BAZ=qux' ],
        spec     => [ env => { isa => HashRef [Str] } ],
        expected => { env => { FOO => 'bar', BAZ => 'qux' } },
    },
    'HashRef[Int] auto-inference' => {
        argv     => [ '--limits', 'cpu=4', '--limits', 'mem=8' ],
        spec     => [ limits => { isa => HashRef [Int] } ],
        expected => { limits => { cpu => 4, mem => 8 } },
    },
    'HashRef[Num] auto-inference' => {
        argv     => [ '--ratios', 'a=0.5', '--ratios', 'b=0.75' ],
        spec     => [ ratios => { isa => HashRef [Num] } ],
        expected => { ratios => { a => 0.5, b => 0.75 } },
    },
    'ArrayRef[PositiveInt] subtype support' => {
        argv     => [ '--ids', '1', '--ids', '2' ],
        spec     => [ ids => { isa => ArrayRef [PositiveInt] } ],
        expected => { ids => [ 1, 2 ] },
    },
    'ArrayRef[PositiveInt] validation failure' => {
        argv     => [ '--ids', '-1' ],
        spec     => [ ids => { isa => ArrayRef [PositiveInt] } ],
        expected => qr/Invalid value for option 'ids'/,
    },
    'ArrayRef[NonEmptyStr] subtype support' => {
        argv     => [ '--names', 'alice', '--names', 'bob' ],
        spec     => [ names => { isa => ArrayRef [NonEmptyStr] } ],
        expected => { names => [ 'alice', 'bob' ] },
    },
    'ArrayRef[Any] uses string modifier' => {
        argv     => [ '--items', 'foo', '--items', '123' ],
        spec     => [ items => { isa => ArrayRef [Any] } ],
        expected => { items => [ 'foo', '123' ] },
    },
    'Bare HashRef error' => {
        spec     => [ config => { isa => HashRef } ],
        expected => qr/Unsupported type 'HashRef' for option 'config'/,
    },
    'HashRef unsupported inner type error' => {
        spec     => [ data => { isa => HashRef [ArrayRef [Str]] } ],
        expected => qr/Unsupported type 'HashRef\[ArrayRef\[Str\]\]' for option 'data'/,
    },
    'HashRef user default override' => {
        argv     => [],
        spec     => [ config => { isa => HashRef [Str], default => sub { { key => 'value' } } } ],
        expected => { config => { key => 'value' } },
    },
    'Mismatch warning issued' => {
        argv     => [ '--nums', '1', '--nums', '2' ],
        spec     => [ 'nums=s@' => { isa => ArrayRef [Int] } ],
        expected => { nums => [ 1, 2 ] },
        warning  => qr/Option 'nums' has explicit spec '=s\@' but type 'ArrayRef\[Int\]' suggests '=i\@'/,
    },
    'Mismatch warning suppressed with nowarn' => {
        argv     => [ '--nums', '1', '--nums', '2' ],
        spec     => [ 'nums=s@' => { isa => ArrayRef [Int], nowarn => 1 } ],
        expected => { nums => [ 1, 2 ] },
    },
    'No warning when explicit spec matches inferred' => {
        argv     => [ '--nums', '1', '--nums', '2' ],
        spec     => [ 'nums=i@' => { isa => ArrayRef [Int] } ],
        expected => { nums => [ 1, 2 ] },
    },
    'Simple coercion' => {
        argv     => [ '--login', 'bob:s3cr3t' ],
        spec     => [ 'login' => { isa => $Credentials, coerce => 1 } ],
        expected => { login => Local::Credentials->new( username => 'bob', password => 's3cr3t' ) },
    },
    'ArrayRef coercion' => {
        argv     => [ '--login', 'bob:s3cr3t', '--login', 'alice:h1dd3n' ],
        spec     => [ 'login' => { isa => ArrayRef[$Credentials], coerce => 1 } ],
        expected => { login => [
            Local::Credentials->new( username => 'bob',   password => 's3cr3t' ),
            Local::Credentials->new( username => 'alice', password => 'h1dd3n' ),
        ] },
    },
);

while ( my ( $test_name, $test_case ) = splice @test_cases, 0, 2 ) {
    subtest $test_name => sub {
        my @args = (
            maybe spec => $test_case->{spec},
            maybe argv => $test_case->{argv},
        );
        if ( 'Regexp' eq ref $test_case->{expected} ) {
            throws_ok(
                sub {
                    with_args(@args);
                },
                $test_case->{expected},
                'Error thrown'
            );
        }
        else {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, shift };
            my %opts = with_args(@args);
            is_deeply(
                \%opts, $test_case->{expected},
                'Options parsed correctly'
            );
            if ( $test_case->{warning} ) {
                ok( @warnings > 0, 'Warning was issued' );
                like( $warnings[0], $test_case->{warning}, 'Warning message matches' );
            }
            elsif ( !$test_case->{allow_warnings} ) {
                is( scalar @warnings, 0, 'No unexpected warnings' )
                  or diag "Unexpected warnings: @warnings";
            }
        }
    };
}

done_testing;
