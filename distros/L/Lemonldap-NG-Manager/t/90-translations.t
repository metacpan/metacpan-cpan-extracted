# Verify that languages translation cover all `trspan`

use Test::More;
use JSON;
use strict;

my $langDir = 'site/htdocs/static/languages';

my $count = 0;
use_ok('Lemonldap::NG::Manager::Build::Tree');
use_ok('Lemonldap::NG::Manager::Build::CTrees');
use_ok('Lemonldap::NG::Manager::Build::Attributes');
$count += 3;

ok( opendir( D, $langDir ), 'Found languages dir' );
my @langs = grep { /\.json$/ and $_ ne 'en.json' } readdir D;
close D;
ok( open( F, "$langDir/en.json" ), 'Found en.json' );
my $en;
ok( $en = join( '', <F> ), 'en.json is not empty' );
close F;
ok( @langs, 'Found other languages' );
my $keys;
ok( $keys = from_json($en), 'en.json contains JSON' );
$en = undef;
$count += 5;

foreach my $lang (@langs) {
    ok( open( F, "$langDir/$lang" ), "Found $lang" );
    my $j;
    ok( $j = join( '', <F> ), "$lang is not empty" );
    my $l;
    ok( $l = from_json($j), "$lang contains JSON" . ( $@ ? " ($@)" : "" ) );
    $lang =~ s/\.json$//;
    my @l1 = sort keys %$keys;
    my @l2 = sort keys %$l;
    ok( $#l1 == $#l2,
        "'$lang' and 'en' have the same count (" . @l2 . '/' . @l1 . ")" );

    my @unTr;
    while (@l1) {
        if ( $l1[0] eq $l2[0] ) {
            shift @l1;
            shift @l2;
        }
        elsif ( $l1[0] eq $l2[1] ) {
            push @unTr, shift(@l2);
        }
        elsif ( $l1[1] eq $l2[0] ) {
            push @unTr, shift(@l1);
        }
        else {
            die "To many errors in $lang.json (at $l1[0]/$l2[0])";
        }
    }
    ok( @unTr == 0,
        "All keys translated for '$lang'" . ( @unTr ? " (@unTr)" : "" ) );
    $count += 5;
}

my $tree;
ok( $tree = Lemonldap::NG::Manager::Build::Tree::tree(), 'Get tree' );
my @nodes = @{ getNodes($tree) };

my @unTr;
foreach (@nodes) {
    my $node = $_;
    $node =~ s/^\*//;
    push @unTr, $node unless ( $keys->{$node} );
}
ok( @unTr == 0,
    'All attributes translated for Tree.pm' . ( @unTr ? " (@unTr)" : "" ) );
$count += 2;

my ( $type, $ctrees );
@unTr = ();
ok( $ctrees = Lemonldap::NG::Manager::Build::CTrees::cTrees(), 'Get cTrees' );
while ( ( $type, $tree ) = each %$ctrees ) {
    @nodes = @{ getNodes($tree) };
    foreach (@nodes) {
        push @unTr, $_ unless ( $keys->{$_} );
    }
}
ok( @unTr == 0,
    'All attributes translated for Tree.pm' . ( @unTr ? " (@unTr)" : "" ) );
$count += 2;

ok(
    open( F,
q#perl -ne 'print if(s/.*trspan="(\w+)".*/$1/g)' site/templates/manager.tpl site/htdocs/static/forms/*|sort -u|#
    ),
    'Find HTML docs'
);
my @trspan = ();
while (<F>) {
    chomp;
    push @trspan, $_;
}
ok( @trspan > 1, 'Found "trspan" attributes' );
@unTr = ();
foreach (@trspan) {
    push @unTr, $_ unless ( $keys->{$_} );
}
ok( @unTr == 0,
    'All "trspan" attribute translated' . ( @unTr ? " (@unTr)" : "" ) );
$count += 3;

# Check for flag icons
foreach my $lang (@langs) {
    ok( -f "site/htdocs/static/logos/$lang.png", "Flag icon found for $lang" );
    $count += 1;
}

done_testing($count);

sub getNodes {
    my $tree = shift;
    my @res;
    foreach my $k (@$tree) {
        if ( ref($k) ) {
            push @res, $k->{title}, @{ getNodes( $k->{nodes} ) },
              @{ getNodes( $k->{nodes_cond} ) };
        }
        else {
            push @res, $k;
        }
    }
    return \@res;
}
