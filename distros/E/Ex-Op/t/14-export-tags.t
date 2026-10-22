#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Tags ();
use EO::TagsX ();
use EO::Twin qw(imp imp_w twin_is fresh);

no strict 'refs';
$EO::Twin::BASE = 'EO::Tags';

{
    my $p = fresh();
    is( imp('EO::Tags', $p, ':both'), undef, 'a tag' );
    is( \&{"${p}::a1"}, \&EO::Tags::a1, '... imports its names' );
    is( \&{"${p}::b1"}, \&EO::Tags::b1, '... all of them' );
    ok( !defined &{"${p}::a2"}, '... and not @EXPORT' );
}

{
    my $p = fresh();
    is( imp('EO::Tags', $p, ':DEFAULT', 'b2'), undef, ':DEFAULT and a name' );
    ok( defined &{"${p}::a1"} && defined &{"${p}::a2"} && defined ${"${p}::sa"}, '... :DEFAULT is @EXPORT' );
    ok( defined &{"${p}::b2"}, '... and the name' );
}

{
    my $p = fresh();
    is( imp('EO::Tags', $p, ':vars'), undef, 'a tag of variables' );
    is( \@{"${p}::arr"}, \@EO::Tags::arr, '... imports them' );
}

{
    my ($err, $warn) = imp_w('EO::Tags', fresh(), ':nosuch');
    like( $err, qr/^Can't continue after import errors at /, 'an undefined tag croaks' );
    is( scalar @$warn, 1, '... after one warning' );
    like( $warn->[0], qr/^"nosuch" is not defined in %EO::Tags::EXPORT_TAGS at /, '... naming the tag' );
}

{
    my $err = imp('EO::Tags', fresh(), ':nonok');
    like( $err, qr/^"notlisted" is not exported by the EO::Tags module\n/, 'a tag name not in the lists is still checked' );
}

{
    my $p = fresh();
    is( imp('EO::Tags', $p, ':empty'), undef, 'an empty tag' );
}

twin_is( 'a tag',                      ':both' );
twin_is( 'two tags overlapping',       ':both', ':DEFAULT' );
twin_is( ':DEFAULT and a name',        ':DEFAULT', 'b2' );
twin_is( 'a tag of variables',         ':vars' );
twin_is( 'an empty tag',               ':empty' );
twin_is( 'an undefined tag',           ':nosuch' );
twin_is( 'an undefined tag and a bad', ':nosuch', 'nope' );
twin_is( 'a tag with an unlisted name', ':nonok' );
twin_is( 'a tag and a bad name',       ':both', 'nope', 'zip' );
twin_is( 'a tag and a version',        ':both', '0.5' );

done_testing;
