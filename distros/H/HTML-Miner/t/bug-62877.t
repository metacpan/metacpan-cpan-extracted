#!perl 

use strict;
use warnings;
use HTML::Miner ;

use Test::More tests => 19;


my $html_miner = HTML::Miner->new ( 

    CURRENT_URL      => "http://87.230.9.12" , 
    CURRENT_URL_HTML => 'Super html <a href="http://www.cpan.org">cpan</a>' 
    
);    


my @links = @{ $html_miner->HTML::Miner::get_links() };

ok( $links[0]->{ ABS_URL        } eq  "http://www.cpan.org/" ,    'OO access of get_links - ABS_URL       '       );
ok( $links[0]->{ ANCHOR         } eq  "cpan"                 ,    'OO access of get_links - ANCHOR        '       );
ok( $links[0]->{ DOMAIN         } eq  "www.cpan.org"         ,    'OO access of get_links - DOMAIN        '       );
ok( $links[0]->{ DOMAIN_IS_BASE } eq  0                      ,    'OO access of get_links - Domain_Is_Base'       );
ok( $links[0]->{ PROTOCOL       } eq  "http"                 ,    'OO access of get_links - PROTOCOL      '       );
ok( $links[0]->{ TITLE          } eq  ""                     ,    'OO access of get_links - TITLE         '       );
ok( $links[0]->{ URI            } eq  "/"                    ,    'OO access of get_links - URI           '       );
ok( $links[0]->{ URL            } eq  "http://www.cpan.org"  ,    'OO access of get_links - URL           '       );





@links = @{ HTML::Miner::get_links( 'http://87.230.9.12', 'Super html <a href="http://www.cpan.org">cpan</a>' ) };

ok( $links[0]->{ ABS_URL        } eq  "http://www.cpan.org/" ,    'NON-OO access of get_links - ABS_URL       '       );
ok( $links[0]->{ ANCHOR         } eq  "cpan"                 ,    'NON-OO access of get_links - ANCHOR        '       );
ok( $links[0]->{ DOMAIN         } eq  "www.cpan.org"         ,    'NON-OO access of get_links - DOMAIN        '       );
ok( $links[0]->{ DOMAIN_IS_BASE } eq  0                      ,    'NON-OO access of get_links - Domain_Is_Base'       );
ok( $links[0]->{ PROTOCOL       } eq  "http"                 ,    'NON-OO access of get_links - PROTOCOL      '       );
ok( $links[0]->{ TITLE          } eq  ""                     ,    'NON-OO access of get_links - TITLE         '       );
ok( $links[0]->{ URI            } eq  "/"                    ,    'NON-OO access of get_links - URI           '       );
ok( $links[0]->{ URL            } eq  "http://www.cpan.org"  ,    'NON-OO access of get_links - URL           '       );



my( $url, $protocol, $domain ) = HTML::Miner::_convert_to_valid_url( 'http://87.230.9.12' ) ;
ok( $url      eq "http://87.230.9.12/",    '_convert_to_valid_url URL'      );
ok( $protocol eq "http"               ,    '_convert_to_valid_url PROTOCOL' );
ok( $domain   eq "87.230.9.12"        ,    '_convert_to_valid_url DOMAIN'   );
