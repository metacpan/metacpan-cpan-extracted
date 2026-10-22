#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Tags ();
use EO::TagsX ();
use EO::Twin qw(imp twin_is fresh);

no strict 'refs';
$EO::Twin::BASE = 'EO::Tags';

{
    my $p = fresh();
    is( imp('EO::Tags', $p, '!a1'), undef, 'a leading negation' );
    ok( !defined &{"${p}::a1"}, '... removes the name' );
    ok( defined &{"${p}::a2"}, '... from :DEFAULT' );
}

{
    my $p = fresh();
    is( imp('EO::Tags', $p, ':both', '!b1'), undef, 'a tag less a name' );
    ok( defined &{"${p}::a1"} && !defined &{"${p}::b1"}, '... is the rest of the tag' );
}

{
    my $p = fresh();
    is( imp('EO::Tags', $p, '!:both'), undef, 'a negated tag first' );
    ok( !defined &{"${p}::a1"} && defined &{"${p}::a2"}, '... is :DEFAULT less the tag' );
}

{
    my $p = fresh();
    is( imp('EO::Tags', $p, 'b1', '!b1', 'b2'), undef, 'add, remove, add' );
    ok( !defined &{"${p}::b1"} && defined &{"${p}::b2"}, '... in order' );

    $p = fresh();
    is( imp('EO::Tags', $p, 'b2', '!b1', 'b1'), undef, 'remove then add again' );
    ok( defined &{"${p}::b1"}, '... the last word wins' );
}

twin_is( 'a leading negation',       '!a1' );
twin_is( 'a tag less a name',        ':both', '!b1' );
twin_is( 'a negated tag first',      '!:both' );
twin_is( ':DEFAULT less a variable', ':DEFAULT', '!$sa' );
twin_is( 'add, remove, add',         'b1', '!b1', 'b2' );
twin_is( 'remove then add',          'b2', '!b1', 'b1' );
twin_is( 'a negated bad name',       'b1', '!nope' );
twin_is( 'a negated undefined tag',  '!:nosuch' );
twin_is( 'everything removed',       '!:DEFAULT' );

done_testing;
