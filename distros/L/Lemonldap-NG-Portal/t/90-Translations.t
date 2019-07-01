use Test::More;
use JSON;
use strict;

my $langDir = 'site/htdocs/static/languages';

my $count = 0;

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
        "'$lang' and 'en' have the same count (" . @l1 . '/' . @l2 . ")" );

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

#ok(
#    open( F,
#q#perl -ne 'print if(s/.*trspan="(\w+)".*/$1/g)' site/templates/manager.tpl site/htdocs/static/forms/*|sort -u|#
#    ),
#    'Find HTML docs'
#);

use File::Find;

my @trspan = ();
my @unTr   = ();
find(
    sub {
        my $f = $File::Find::name;
        return unless ( $_ =~ /tpl$/ and -f $_ and $_ !~ m#mail_# );
        open F, $_;
        while ( my $l = <F> ) {
            push @trspan, ( $l =~ /trspan="(\w+)"/g );
        }
        close F;
    },
    'site/templates'
);

ok( @trspan > 1, 'Found "trspan" attributes' );
@unTr = ();
my $last = '';
foreach ( grep { $last ne $_ ? $last = $_ : undef } sort @trspan ) {
    push @unTr, $_ unless ( $keys->{$_} );
}
ok( @unTr == 0,
    'All "trspan" attribute translated' . ( @unTr ? " (@unTr)" : "" ) );
$count += 2;

foreach my $lang (@langs) {
    ok( -f "site/htdocs/static/common/$lang.png", "Flag icon found for $lang" );
    $count += 1;
}

done_testing($count);
