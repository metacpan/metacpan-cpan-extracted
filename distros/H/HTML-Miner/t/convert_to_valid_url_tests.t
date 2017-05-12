#!perl 

use strict                 ;
use warnings               ;
use HTML::Miner            ;

use Test::More             ;

plan tests => 6            ;


my ( $url, $protocol, $domain_name, $uri ) ; 

( $url, $protocol, $domain_name, $uri ) = HTML::Miner::_convert_to_valid_url( 'a1111.COM.au'               ) ;
ok( "$url, $protocol, $domain_name, $uri" eq 'http://a1111.COM.au/, http, a1111.COM.au, /'                 ) ;

( $url, $protocol, $domain_name, $uri ) = HTML::Miner::_convert_to_valid_url( 'http://a1111.COM.au'        ) ;
ok( "$url, $protocol, $domain_name, $uri" eq 'http://a1111.COM.au/, http, a1111.COM.au, /'                 ) ;

( $url, $protocol, $domain_name, $uri ) = HTML::Miner::_convert_to_valid_url( '1234.com'                   ) ;
ok( "$url, $protocol, $domain_name, $uri" eq 'http://1234.com/, http, 1234.com, /'                         ) ;

( $url, $protocol, $domain_name, $uri ) = HTML::Miner::_convert_to_valid_url( '1234.com.au'                ) ;
ok( "$url, $protocol, $domain_name, $uri" eq 'http://1234.com.au/, http, 1234.com.au, /'                   ) ;

( $url, $protocol, $domain_name, $uri ) = HTML::Miner::_convert_to_valid_url( 'www.1234.com'               ) ;
ok( "$url, $protocol, $domain_name, $uri" eq 'http://www.1234.com/, http, www.1234.com, /'                 ) ;

( $url, $protocol, $domain_name, $uri ) = HTML::Miner::_convert_to_valid_url( 'www.1234.com/index.pl'      ) ;
ok( "$url, $protocol, $domain_name, $uri" eq 'http://www.1234.com/index.pl, http, www.1234.com, /index.pl' ) ;


done_testing() ;

exit()         ;
