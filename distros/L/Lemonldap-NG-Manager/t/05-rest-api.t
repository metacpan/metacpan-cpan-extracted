# Test REST API with valid and invalid requests.
# Check also metadatas request (root of a conf)

use Test::More;
use JSON;
use strict;

require 't/test-lib.pm';
my $struct = 'site/htdocs/static/struct.json';

my @bad = qw(
  /confs/1567
  /confs/abc
  /confs/1/virtualHosts/unknown/locationRules
  /confs/1/virtualHosts/test1.example.com
  /confs/1/virtualHosts/test1.example.com/vhostPorts
  /confs/1/samlIDPMetaDataNodes/unknown
  /confs/1/samlSPMetaDataNodes/unknown
  /confs/1/samlSPMetaDataNodes/unknown/key
  /confs/1/applicationList/unknown
  /confs/1/portal/unknown
);
my @good = qw(
  /confs/latest
  /confs/1
  /confs/1/portal
  /confs/1/virtualHosts
  /confs/1/virtualHosts/test1.example.com/locationRules
  /confs/1/virtualHosts/new__new.example.com/locationRules
  /confs/1/virtualHosts/test1.example.com/vhostPort
  /confs/1/samlIDPMetaDataNodes
  /confs/1/samlSPMetaDataNodes
  /confs/1/applicationList
);

foreach my $query (@good) {
    my $href = &client->jsonResponse($query);
}

foreach my $query (@bad) {
    my $res = &client->_get( $query, '' );
    ok( $res->[0] == 400, "Request reject for $query" )
      or print STDERR "# Receive a $res->[0] code";
    my $href;

    ok( $href = from_json( $res->[2]->[0] ), 'Response is JSON' );
    ok( $href->{error}, "Receive an explanation message ($href->{error})" );
    count(3);
}

open F, $struct or die "Unable to open $struct";
my @hkeys;
my $hstruct = '';
while (<F>) {
    push @hkeys, ( $_ =~ /cnodes":"([^"]+)/g );
    $hstruct .= $_;
}
close F;

ok( $hstruct = from_json($hstruct), 'struct.json is JSON' );
ok( ref $hstruct eq 'ARRAY',        'struct.json is an array' )
  or print STDERR "Expected: ARRAY, got: " . ( ref $hstruct ) . "\n";
count(2);

foreach my $query (@hkeys) {
    my $href = &client->jsonResponse( "/confs/1/$query", '' );
    ok( (
            ( ref $href eq 'ARRAY' )
              or (  ( ref $href eq 'HASH' )
                and ( $href->{error} =~ /setDefault$/ ) )
        ),
        'Response is an array'
    );
    count(1);
    next if ( ( ref $href eq 'HASH' ) and ( $href->{error} =~ /setDefault$/ ) );
    foreach my $k (@$href) {
        ok( defined $k->{title}, 'Title defined' );
        ok( defined $k->{id},    'Id defined' );
        count(2);
    }
}

# Metadatas
{
    my $href = &client->jsonResponse( 'confs/1', '' );
    foreach (qw(cfgNum cfgAuthor cfgAuthorIP cfgDate)) {
        ok( exists( $href->{$_} ), "Key $_ exists" );
    }
    ok( $href->{cfgNum} == 1, 'cfgNum is set to 1' );
    count(5);
}

done_testing( count() );

