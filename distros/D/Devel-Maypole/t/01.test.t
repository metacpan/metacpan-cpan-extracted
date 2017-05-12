#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 42;

use Devel::Maypole qw/:test/;

use lib '/home/dave/distributions/cpan/Test-WWW-Mechanize-Maypole/lib';
use lib '/home/dave/distributions/cpan/Maypole-Plugin-AutoUntaint/lib';
    
my ( $database, $application );

BEGIN { 

    $ENV{MAYPOLE_CONFIG}    = 'config/beerdb.simple.yaml';
    $ENV{MAYPOLE_TEMPLATES} = 't/templates';

    $database = database( ddl  => 'sql/ddl/beerdb.simple.sql',
                          data => 'sql/data/beerdb.simple.sql',
                          #unlink => 0,
                          );
    $application = application( #unlink => 0,
                                plugins => [ qw( Config::YAML AutoUntaint Relationship ) ],
                                );    
}

use Test::WWW::Mechanize::Maypole $application, $database;

# For testing classmetadata
eval <<CODE;
    sub $application\::Beer::classdata: Exported {};
    sub $application\::Beer::list_columns  { return qw/score name price style brewery url/};
CODE

die $@ if $@;

# tests from Test::WWW::Mechanize::Maypole

# frontpage
{   

    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb/");
    
    $mech->content_contains( 'This is the frontpage' );
    
    is($mech->ct, "text/html");
    is($mech->status, 200);
}

# view - beer
{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb/beer/view/1");
    $mech->content_contains( 'Begin object list' );
    $mech->content_contains( 'Organic Best Bitter' );
    is($mech->ct, "text/html");
    is($mech->status, 200);
    #warn $mech->content;
}

# view - brewery
{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb/brewery/view/1");
    $mech->content_contains( 'Begin object list' );
    $mech->content_contains( 'St Peter\'s Brewery' );
    is($mech->ct, "text/html");
    is($mech->status, 200);
    #warn $mech->content;
}

# list - beers
{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb/beer/list");
    $mech->content_contains( 'Begin object list' );
    $mech->content_contains( 'Organic Best Bitter' );
    is($mech->ct, "text/html");
    is($mech->status, 200);
    #warn $mech->content;
}

# list - breweries
{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb/brewery/list");
    $mech->content_contains( 'Begin object list' );
    $mech->content_contains( 'St Peter\'s Brewery' );
    is($mech->ct, "text/html");
    is($mech->status, 200);
    #warn $mech->content;
}

# classdata
{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb/beer/classdata");

    my %classdata = split /\n/, $mech->content;
    
    is ($classdata{plural}, 'beers', 'classdata.plural');
    is ($classdata{moniker},'beer','classdata.moniker');
    like ($classdata{cgi},qr/^HTML::Element/,'classdata.cgi');
    is ($classdata{table},'beer','classdata.table');
    is ($classdata{name},"$application\::Beer",'classdata.name');
    is ($classdata{colnames},'Abv','classdata.colnames');
    is($classdata{columns}, 'abv brewery id name notes price score style url',
        'classdata.columns');
    is($classdata{list_columns}, 'score name price style brewery url',
        'classdata.list_columns');
    is ($classdata{related_accessors},'pubs','classdata.related_accessors');
}


# Test the effect of trailing slash on config->uri_base and request URI
(my $uri_base = $application->config->uri_base) =~ s:/$::;
$application->config->uri_base($uri_base);

{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb/");
    $mech->content_like( qr/frontpage/, "Got frontpage, trailing '/' on request but not uri_base");
}
    
{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb");
    $mech->content_like( qr/frontpage/, "Got frontpage, no trailing '/' on request or uri_base");
}
    
$application->config->uri_base($uri_base . '/');

{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb/");
    $mech->content_like( qr/frontpage/, "Got frontpage, trailing '/' on uri_base and request");
}

{
    my $mech = Test::WWW::Mechanize::Maypole->new;
    $mech->get_ok("http://localhost/beerdb");
    $mech->content_like( qr/frontpage/, "Got frontpage, trailing '/' on uri_base but not request");
}





