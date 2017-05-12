package argv_tests;

use strict;
use warnings;
use Test::More;

my @tests = (
    {
        name        => 'empty argv',
        argv_before => [],
        expected    => {},
    },
    {
        name        => 'bareword with an equal sign',
        argv_before => ['me=josh'],
        argv_after  => ['me=josh'],
        expected    => {},
    },
    {
        name        => 'single dashed',
        argv_before => ['-a'],
        argv_after  => ['-a'],
        expected    => {},
    },
    {
        name        => 'a basic key/value case',
        argv_before => ['--name=josh'],
        expected    => { name => 'josh' },
    },
    {
        name        => 'two key/value pairs',
        argv_before => [ '--first_name=josh', '--last_name=mcadams' ],
        expected    => { first_name => 'josh', last_name => 'mcadams' },
    },
    {
        name        => 'a flag',
        argv_before => ['--verbose'],
        expected    => { verbose => 1, },
    },
    {
        name        => 'duplicate flags',
        argv_before => ['--verbose', '--verbose'],
        expected    => { verbose => 1, },
    },
    {
        name        => 'triple-dash',
        argv_before => ['---verbose'],
        expected    => { '-verbose' => 1, },
    },
    {
        name        => 'two flags',
        argv_before => [ '--upper', '--strict' ],
        expected    => { upper => 1, strict => 1 },
    },
    {
        name        => 'a key/value pair and a flag',
        argv_before => [ '--language=perl', '--v6' ],
        expected    => { language => 'perl', v6 => 1 },
    },
    {
        name        => 'space in value',
        argv_before => ['--equality=This is a test'],
        expected    => { equality => 'This is a test' },
    },
    {
        name        => 'strage case of two-dashes and an equal sign',
        argv_before => ['--==This is a test'],
        expected    => { '' => '=This is a test' },
    },
    {
        name        => 'lots of crap in value',
        argv_before => ['--equality=This "is" a test-ing value'],
        expected    => { equality => 'This "is" a test-ing value' },
    },
    {
        name        => 'equal sign in value',
        argv_before => ['--equality=4=four'],
        expected    => { equality => '4=four' },
    },
    {
        name        => 'dash in key',
        argv_before => ['--web-site=www.perlcast.com'],
        expected    => { 'web-site' => 'www.perlcast.com' },
    },
    {
        name        => 'identical keys',
        argv_before => [ '--file=x.dat', '--file=y.dat' ],
        expected    => { file => [qw(x.dat y.dat)] },
    },
    {
        name        => 'key/value pair and flag collision (key/value first)',
        argv_before => [ '--file=x.dat', '--file' ],
        expected    => { file => 'x.dat' },
    },
    {
        name        => 'key/value pair and flag collision (flag first)',
        argv_before => [ '--file', '--file=y.dat' ],
        expected    => { file => 'y.dat' },
    },
    {
        name        => 'cut off processing with double-dashes',
        argv_before => [
            '--first-value=uno', '--second-value=dos',
            '--',                '--third-value=tres'
        ],
        argv_after => ['--third-value=tres'],
        expected   => { 'first-value' => 'uno', 'second-value' => 'dos' },
    },
    {
        name        => 'bareword',
        argv_before => ['joshua'],
        argv_after  => ['joshua'],
        expected    => {},
    },
    {
        name        => 'barewords',
        argv_before => [ 'joshua', 'arron', 'mcadams' ],
        argv_after  => [ 'joshua', 'arron', 'mcadams' ],
        expected    => {},
    },
    {
        name        => 'barewords mixed with arguments',
        argv_before =>
          [ 'Joshua', '--career=programmer', 'Arron', '--japh', 'McAdams' ],
        argv_after => [ 'Joshua', 'Arron', 'McAdams' ],
        expected => { career => 'programmer', japh => 1 },
    },
    {
        name => 'barewords mixed with arguments and junk after double-dashes',
        argv_before => [
            'Joe',          '--career=haxtor',
            'Bloe',         '--paid',
            '--',           '--you',
            '--should=see', 'these afterward'
        ],
        argv_after =>
          [ 'Joe', 'Bloe', '--you', '--should=see', 'these afterward' ],
        expected => { career => 'haxtor', paid => 1 },
    },
);

plan tests => scalar(@tests) * 2;

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /Subroutine.+redefined/; };

for my $test (@tests) {
    @ARGV = @{ $test->{argv_before} };
    delete $INC{'Getopt/Whatever.pm'};
    eval "use Getopt::Whatever;";
    die $@ if $@;
    is_deeply( \%ARGV, $test->{expected}, $test->{name} . ' (argv hash)' )
      or die;
    is_deeply(
        \@ARGV,
        ( $test->{argv_after} || [] ),
        $test->{name} . ' (argv array afterward)'
      )
      or die;
    delete $ARGV{$_} for keys %ARGV;
}

1;
