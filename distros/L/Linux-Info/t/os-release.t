use warnings;
use strict;
use Test::Most 0.38;

plan tests => 16;

my $class = 'Linux::Info::Distribution::OSRelease';
require_ok($class);
can_ok( $class,
    qw(parse parse_from_file _parse get_source new _handle_missing) );
isa_ok( $class, 'Linux::Info::Distribution' );
ok( $class->DEFAULT_FILE, 'DEFAULT_FILE returns a value' );
is( ref( $class->parse_from_file ), 'HASH', 'class parse call works' );

SKIP: {
    skip 'default file not available on the file system', 2
      unless ( -f $class->DEFAULT_FILE );
    my $obj = $class->new;
    ok( $obj, 'it is possible to create a new instance without arguments' );
    isa_ok( $obj, $class );
    is( $obj->get_source, $class->DEFAULT_FILE,
        'get_source is an alias to DEFAULT_FILE' )
      or diag( explain($obj) );
}

my $fixture = 't/samples/os-release';
note("Using custom file $fixture");
my $instance = $class->new($fixture);
ok( $instance, 'can create an instance with a custom file' );
isa_ok( $instance, $class );
is( $instance->get_name,       'Ubuntu', 'get_name works' );
is( $instance->get_version_id, '22.04',  'get_version_id works' );
is(
    $instance->get_version,
    '22.04.4 LTS (Jammy Jellyfish)',
    'get_version works'
);
is( $instance->get_id,     'ubuntu', 'get_id works' );
is( $instance->get_source, $fixture, 'get_source returns the custom value' );

$fixture = 't/samples/os-releases/raspbian';
note("Using custom file $fixture to force a failure");
dies_ok { $class->new($fixture) } "dies due missing fields in $fixture";
