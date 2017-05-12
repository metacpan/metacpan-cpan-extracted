#!perl 


use strict;
use warnings;
use HTML::Miner ;

use Test::More tests => 10;


my $html = do{local $/;<DATA>} ; 


my $html_miner = HTML::Miner->new ( 
    CURRENT_URL                   => 'www.perl.org'   , 
    CURRENT_URL_HTML              => $html 
    );


my $retun_element = $html_miner->get_page_css_and_js(
    CONVERT_URLS_TO_ABS       =>    0
    );

ok( $$retun_element{ 'CSS' }[0] eq "http://static.mycssdomain.com/frameworks/style/main.css",        'CSS URL Extraction'  );
ok( $$retun_element{ 'JS'  }[0] eq "http://static.myjsdomain.com/frameworks/barlesque.js"   ,        'JS  URL Extraction'  );
ok( $$retun_element{ 'JS'  }[1] eq "http://js.revsci.net/gateway/gw.js?csid=J08781"         ,  'Funny JS  URL Extraction'  );


$retun_element = $html_miner->get_page_css_and_js(
    CONVERT_URLS_TO_ABS       =>    1
    );

ok( $$retun_element{ 'CSS' }[1] eq "http://www.perl.org/rel_cssfile.css",        'CSS ABS URL Conversion'       );
ok( $$retun_element{ 'JS'  }[2] eq "http://www.perl.org/about/rel_jsfile.js",    'JS  ABS URL Conversion'       );




$retun_element = HTML::Miner::get_page_css_and_js(
    URL                       =>    'www.perl.org' ,
    HTML                      =>    $html          ,
    CONVERT_URLS_TO_ABS       =>    0
    );

ok( $$retun_element{ 'CSS' }[0] eq "http://static.mycssdomain.com/frameworks/style/main.css",        'Direct CSS URL Extraction'  );
ok( $$retun_element{ 'JS'  }[0] eq "http://static.myjsdomain.com/frameworks/barlesque.js"   ,        'Direct JS  URL Extraction'  );
ok( $$retun_element{ 'JS'  }[1] eq "http://js.revsci.net/gateway/gw.js?csid=J08781"         ,  'Direct Funny JS  URL Extraction'  );


$retun_element = HTML::Miner::get_page_css_and_js(
    URL                       =>    'www.perl.org' ,
    HTML                      =>    $html          ,
    CONVERT_URLS_TO_ABS       =>    1
    );

ok( $$retun_element{ 'CSS' }[1] eq "http://www.perl.org/rel_cssfile.css",        'Direct CSS ABS URL Conversion'       );
ok( $$retun_element{ 'JS'  }[2] eq "http://www.perl.org/about/rel_jsfile.js",    'Direct JS  ABS URL Conversion'       );


exit() ;

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
          <script type="text/javascript" src="http://static.myjsdomain.com/frameworks/barlesque.js"></script>
          <script type="text/javascript" src="http://js.revsci.net/gateway/gw.js?csid=J08781"></script>
          <script type="text/javascript" src="/about/rel_jsfile.js"></script>
          <link rel="stylesheet" type="text/css" href="http://static.mycssdomain.com/frameworks/style/main.css"  />
          <link rel="stylesheet" type="text/css" href="/rel_cssfile.css"  />
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
