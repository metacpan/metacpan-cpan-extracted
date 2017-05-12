#!perl 


use strict;
use warnings;
use HTML::Miner ;

use Test::More tests => 23;



my $html = do{local $/;<DATA>};
my $html_miner = HTML::Miner->new ( 

    CURRENT_URL      => "my_domain_to_mine.com/my_page_to_mine.pl" , 
    CURRENT_URL_HTML => $html
    
);    




my $meta_data =  $html_miner->get_meta_elements() ;

ok( $meta_data->{ TITLE } eq "SiteTitle",    'Site title Extraction'       );
ok( $meta_data->{ DESC } eq "desc of site",  'Site Description Extraction' );
ok( $meta_data->{ KEYWORDS } ->[0] eq "kw1", 'Site Keyword Extraction' );
ok( $meta_data->{ RSS }->[0]->{TYPE} eq "application/atom+xml", 'Site Description Extraction' );




my $links = $html_miner->get_links();

ok( $links->[0]->{ DOMAIN } eq "linkone.com", 'Link Domain Extraction' );
ok( $links->[0]->{ ANCHOR } eq "Link1",       'Link Anchor Extraction' );
ok( $links->[2]->{ ABS_URL } eq "http://my_domain_to_mine.com/link3", 'Link Absolute URL Extraction' );
ok( $links->[1]->{ DOMAIN_IS_BASE } == 1, 'Link Domain Extraction' );
ok( $links->[1]->{ TITLE } eq "title2", 'Link Title Extraction' );





my $images = $html_miner->get_images();

ok( $images->[0]->{ IMG_LOC } eq "http://my_domain_to_mine.com/logo_plain.jpg", 'Image Location Extraction' );
ok( $images->[2]->{ ALT } eq "link3", 'Image ALT Extraction' );
ok( $images->[0]->{ IMG_DOMAIN } eq "my_domain_to_mine.com", 'Image Domain Extraction' );
ok( $images->[3]->{ ABS_LOC } eq "http://my_domain_to_mine.com/image3.jpg", 'Image Absolute Location Extraction' );





my ( $clear_url, $protocol, $domain, $uri ) = $html_miner->break_url();  

ok( $clear_url eq "http://my_domain_to_mine.com/my_page_to_mine.pl", 'URL Clean' );
ok( $protocol eq "http", 'URL protocol Extraction' );
ok( $domain eq "my_domain_to_mine.com", 'URL Domain Extraction' );
ok( $uri eq "/my_page_to_mine.pl", 'URL URI Extraction' );





SKIP: { 

    skip( "get_redirect_destination - requires Internet access", 1 );
    
    is( HTML::Miner::get_redirect_destination( "redirectingurl_here.html" ), 'redirected_to', 'Redirection of URL' );

}





my $out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/", "../../about/" );
ok( $out eq "http://www.perl.com/about/", 'ABS URL type 1' );

$out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/index.html", "index2.html" );
ok( $out eq "http://www.perl.com/help/faq/index2.html", 'ABS URL type 2' );

$out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/", "../../index.html" );
ok( $out eq "http://www.perl.com/index.html", 'ABS URL type 3' );

$out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/", "/about/" );
ok( $out eq "http://www.perl.com/about/", 'ABS URL type 4' );

$out = HTML::Miner::get_absolute_url( "www.perl.comhelp/faq/", "http://othersite.com" );
ok( $out eq "http://othersite.com/", 'ABS URL type 5' );









eval { 
    require LWP::UserAgent;
    require HTTP::Request;
}; 

if( $@ ) {
    
    warn "
WARNING:
 
        HTML::Miner requires LWP::UserAgent and HTTP::Request when URLs are to be fetched!
            Without both of these Modules some features may not work.

";

}









__DATA__

<html>
<head>
    <title>SiteTitle</title>
    <meta name="description" content="desc of site" />
    <meta name="keywords"    content="kw1, kw2, kw3" />
    <link rel="alternate" type="application/atom+xml" title="Title" href="http://www.my_domain_to_mine.com/feed/atom/" />
    <link rel="alternate" type="application/rss+xml" title="Title" href="http://www.othersite.com/feed/" />
    <link rel="alternate" type="application/rdf+xml" title="Title" href="my_domain_to_mine.com/feed/" /> 
    <link rel="alternate" type="text/xml" title="Title" href="http://www.other.org/feed/rss/" />
</head>
<body>

<a href="http://linkone.com">Link1</a>
<a href="link2.html" TITLE="title2" >Link2</a>
<a href="/link3">Link3</a>


<img src="http://my_domain_to_mine.com/logo_plain.jpg" >
<img alt="image2" src="http://my_domain_to_mine.com/image2.jpg" />
<img src="http://my_other.com/image3.jpg" alt="link3">
<img src="image3.jpg" alt="link3">


</body>
</html>
