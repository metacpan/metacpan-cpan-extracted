use warnings;
use strict;
use Test::Most 0.38;

my $class = 'Linux::Info::Distribution';
require_ok($class);
can_ok( $class, qw(get_name get_id get_version get_version_id) );

my $attribs_ref = {
    name       => 'Ubuntu',
    version_id => '22.04',
    version    => '22.04.4 LTS (Jammy Jellyfish)',
    id         => 'ubuntu',
};

my $instance = $class->new($attribs_ref);

ok( $instance, 'can create an instance' );
isa_ok( $instance, $class );
is( $instance->get_name, $attribs_ref->{name}, 'get_name works' );
is(
    $instance->get_version_id,
    $attribs_ref->{version_id},
    'get_version_id works'
);
is( $instance->get_version, $attribs_ref->{version}, 'get_version works' );
is( $instance->get_id,      $attribs_ref->{id},      'get_id works' );

dies_ok { $class->new } 'new dies without the required parameter';
like $@, qr/hash\sreference/, 'got expected error message';

dies_ok { $class->new( {} ) } 'new dies without the required hash keys';
like $@, qr/missing\sthe\skey/, 'got expected error message';

done_testing;
