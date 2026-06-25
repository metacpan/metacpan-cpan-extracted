#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Lilith') or BAIL_OUT('Lilith failed to load');

# new() requires dsn — should die without it
dies_ok { Lilith->new() } 'new() dies when dsn is not provided';
dies_ok { Lilith->new( user => 'lilith' ) } 'new() dies when dsn is missing but other opts given';

# minimal valid construction
my $lilith;
lives_ok {
    $lilith = Lilith->new( dsn => 'dbi:Pg:dbname=test' );
} 'new() lives with only dsn';

isa_ok( $lilith, 'Lilith' );

# verify defaults
is( $lilith->{user}, 'lilith', 'default user is "lilith"' );
is( $lilith->{pass}, undef,    'default pass is undef' );

# verify ignore arrays default to empty arrayrefs
foreach my $key (qw( sid_ignore class_ignore suricata_sid_ignore suricata_class_ignore sagan_sid_ignore sagan_class_ignore )) {
    is( ref( $lilith->{$key} ), 'ARRAY', "$key defaults to an arrayref" );
    is( scalar( @{ $lilith->{$key} } ), 0, "$key default arrayref is empty" );
}

# explicit values passed through
my $lilith2 = Lilith->new(
    dsn  => 'dbi:Pg:dbname=test',
    user => 'myuser',
    pass => 'secret',
);
is( $lilith2->{user}, 'myuser', 'explicit user is stored' );
is( $lilith2->{pass}, 'secret', 'explicit pass is stored' );

# ignore arrays passed explicitly
my @sids = ( 1001, 1002 );
my $lilith3 = Lilith->new(
    dsn        => 'dbi:Pg:dbname=test',
    sid_ignore => \@sids,
);
is_deeply( $lilith3->{sid_ignore}, \@sids, 'sid_ignore array is stored correctly' );

# class_map is populated
ok( exists $lilith->{class_map}, 'class_map is populated' );
ok( scalar( keys %{ $lilith->{class_map} } ) > 0, 'class_map has entries' );

# derived maps are built
ok( exists $lilith->{lc_class_map},     'lc_class_map is built' );
ok( exists $lilith->{rev_class_map},    'rev_class_map is built' );
ok( exists $lilith->{lc_rev_class_map}, 'lc_rev_class_map is built' );
ok( exists $lilith->{snmp_class_map},   'snmp_class_map is built' );

done_testing();
