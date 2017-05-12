package HTML::Miner          ;

use 5.006                    ;

use strict                   ;
use warnings FATAL => 'all'  ;

use Carp                     ;

use Exporter                 ;


=head1 NAME

HTML::Miner - This Module 'Mines' (hopefully) useful information for an URL or HTML snippet.

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.03';

=head1 SYNOPSIS

HTML::Miner 'Mines' (hopefully) useful information for an URL or HTML snippet. The following is a 
list of HTML elements that can be extracted:

=over 5

=item * 

Find all links and for each link extract:

=over 7

=item URL Title    

=item URL href

=item URL Anchor Text

=item URL Domain

=item URL Protocol

=item URL URI

=item URL Absolute location

=back

=item * 

Find all images and for each image extract:

=over 3

=item IMG Source URL

=item IMG Absolute Source URL

=item IMG Source Domain

=back 

=item * 

Extracts Meta Elements such as 

=over 4

=item Page Title

=item Page Description 

=item Page Keywords

=item Page RSS Feeds

=back 

=item *

Finds the final destination URL of a potentially redirecting URL.

=item * 

Find all JS and CSS files used within the HTML and find their absolute URL if required.

=back 


=head2 Example ( Object Oriented Usage )

    use HTML::Miner;

    my $html = "some html";
    # or $html = do{local $/;<DATA>}; with __DATA__ provided

    my $html_miner = HTML::Miner->new ( 

      CURRENT_URL                   => 'www.perl.org'   , 
      CURRENT_URL_HTML              => $html 

    );


    my $meta_data =  $html_miner->get_meta_elements()   ;
    my $links     = $html_miner->get_links()            ;
    my $images    = $html_miner->get_images()           ;

    my ( $clear_url, $protocol, $domain, $uri ) = $html_miner->break_url();  

    my $css_and_js =  $html_miner->get_page_css_and_js() ;

    my $out = HTML::Miner::get_redirect_destination( "redirectingurl_here.html" ) ;

    my $out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/", "../../about/" );


=head2 Example ( Direct access of Methods )    

    use HTML::Miner;

    my $html = "some html";
    # or $html = do{local $/;<DATA>}; with __DATA__ provided

    my $url = "http://www.perl.org";

    my $meta_data  = HTML::Miner::get_meta_elements( $url, $html ) ;
    my $links      = HTML::Miner::get_links( $url, $html )         ;
    my $images     = HTML::Miner::get_images( $url, $html )        ;

    my ( $clear_url, $protocol, $domain, $uri ) = HTML::Minerbreak_url( $url );  

    my $css_and_js = get_page_css_and_js( 
           URL                       =>    $url                     , 
           HTML                      =>    $optionally_html_of_url  ,   
           CONVERT_URLS_TO_ABS       =>    0/1                      ,  [ Optional argument, default is 1 ]
    );

    my $out = HTML::Miner::get_redirect_destination( "redirectingurl_here.html" ) ;

    my $out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/", "../../about/" );




=head2 Test Data 

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
          <script type="text/javascript" src="/about/other.js"></script>
          <link rel="stylesheet" type="text/css" href="http://static.mycssdomain.com/frameworks/style/main.css"  />
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


=head2 Example Output:


    my $meta_data =  $html_miner->get_meta_elements() ;

    # $meta_data->{ TITLE }             =>   "SiteTitle"
    # $meta_data->{ DESC }              =>   "desc of site"
    # $meta_data->{ KEYWORDS }->[0]     =>   "kw1"
    # $meta_data->{ RSS }->[0]->{TYPE}  =>   "application/atom+xml"



    my $links = $html_miner->get_links();

    # $links->[0]->{ DOMAIN }         =>   "linkone.com"
    # $links->[0]->{ ANCHOR }         =>   "Link1"
    # $links->[2]->{ ABS_URL   }      =>   "http://my_domain_to_mine.com/link3"
    # $links->[1]->{ DOMAIN_IS_BASE } =>   1
    # $links->[1]->{ TITLE }          =>   "title2"



    my $images = $html_miner->get_images();

    # $images->[0]->{ IMG_LOC }     =>  "http://my_domain_to_mine.com/logo_plain.jpg"
    # $images->[2]->{ ALT }         =>  "link3"
    # $images->[0]->{ IMG_DOMAIN }  =>  "my_domain_to_mine.com"
    # $images->[3]->{ ABS_LOC }     =>  "http://my_domain_to_mine.com/image3.jpg"



    my $css_and_js =  $html_miner->get_page_css_and_js(
         CONVERT_URLS_TO_ABS       =>    0
    );

    # $css_and_js will contain:
    #    {
    #      CSS => [
    #         "http://static.mycssdomain.com/frameworks/style/main.css",
    # 	      "/rel_cssfile.css",
    #        ],
    #      JS  => [
    # 	       "http://static.myjsdomain.com/frameworks/barlesque.js",
    #          "http://js.revsci.net/gateway/gw.js?csid=J08781",
    #          "/about/rel_jsfile.js",
    #        ],
    #    }


    my $css_and_js =  $html_miner->get_page_css_and_js(
         CONVERT_URLS_TO_ABS       =>    1
    );

    # $css_and_js will contain:
    #    {
    #      CSS => [
    #         "http://static.mycssdomain.com/frameworks/style/main.css",
    # 	      "http://www.perl.org/rel_cssfile.css",
    #        ],
    #      JS  => [
    # 	       "http://static.myjsdomain.com/frameworks/barlesque.js",
    #          "http://js.revsci.net/gateway/gw.js?csid=J08781",
    #          "http://www.perl.org/about/rel_jsfile.js",
    #        ],
    #    }



    my ( $clear_url, $protocol, $domain, $uri ) = $html_miner->break_url();  

    # $clear_url   =>  "http://my_domain_to_mine.com/my_page_to_mine.pl"
    # $protocol    =>  "http"
    # $domain      =>  "my_domain_to_mine.com"
    # $uri         =>  "/my_page_to_mine.pl"


    HTML::Miner::get_redirect_destination( "redirectingurl_here.html" ) => 'redirected_to'



    my $out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/", "../../about/" );
    # $out    => "http://www.perl.com/about/"

    $out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/index.html", "index2.html" );
    # $out    => "http://www.perl.com/help/faq/index2.html"

    $out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/", "../../index.html" );
    # $out    => "http://www.perl.com/index.html"

    $out = HTML::Miner::get_absolute_url( "www.perl.com/help/faq/", "/about/" );
    # $out    => "http://www.perl.com/about/"

    $out = HTML::Miner::get_absolute_url( "www.perl.comhelp/faq/", "http://othersite.com" );
    # $out    => "http://othersite.com/"




=head1 EXPORT

This Module does not export anything through @EXPORT, however does export all externally 
available functions through @EXPORT_OK

=cut

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( get_links get_absolute_url break_url get_redirect_destination get_redirect_destination_thread_safe get_images get_meta_elements get_page_css_and_js );

=head1 SUBROUTINES/METHODS

The following functions are all available directly and through the HTML::Miner Object.

=head2 new

The constructor validates the input data and retrieves a URL if the HTML is not provided.

The constructor takes the following parameters:

  my $foo = HTML::Miner->new ( 
      CURRENT_URL                   => 'www.site_i_am_crawling.com/page_i_am_crawling.html'   , # REQUIRED - 'new' will croak 
                                                                                                  #           if this is not provided. 
      CURRENT_URL_HTML              => 'long string here'                                     , # Optional -  Will be extracted 
                                                                                                  #      from CURRENT_URL if not provided. 
      USER_AGENT                    => 'Perl_HTML_Miner/$VERSION'                             , # Optional - default: 
                                                                                                  #      'Perl_HTML_Miner/$VERSION'
      TIMEOUT                       => 5                                                      , # Optional - default: 5 ( Seconds )

      DEBUG                         => 0                                                      , # Optional - default: 0

  );

=cut

sub new {
    
    my $class = shift;
    
    my %parameter_hash;

    my $count = @_;

    my $useage_howto = "

Usage:


  my \$foo = HTML::Miner->new ( 
      CURRENT_URL                   => 'www.site_i_am_crawling.com/page_i_am_crawling.html'   , # REQUIRED - 'new' will croak 
                                                                                                  #           if this is not provided. 
      CURRENT_URL_HTML              => 'long string here'                                     , # Optional -  Will be extracted 
                                                                                                  #      from CURRENT_URL if not provided. 
      USER_AGENT                    => 'Perl_HTML_Miner/$VERSION'                             , # Optional - default: 
                                                                                                  #      'Perl_HTML_Miner/$VERSION'
      TIMEOUT                       => 5                                                      , # Optional - default: 5 ( Seconds )

      DEBUG                         => 0                                                      , # Optional - default: 0

  );

";

    unless( $count > 1 ) { 
	croak( $useage_howto );
    } else {
	%parameter_hash = @_;
    }


    ## Require parameter.
    croak( $useage_howto )       
	unless( $parameter_hash{ CURRENT_URL                    }   ) ;

    ## Setting defaults unless parameters are set.
    my $require_extract = 1      
	unless( $parameter_hash{ CURRENT_URL_HTML               }   ) ;

    $parameter_hash{USER_AGENT} = 'Perl_HTML_Miner/'.$VERSION  
	unless( $parameter_hash{ USER_AGENT                     }   ) ;
    $parameter_hash{TIMEOUT}    = 60                                 
	unless( $parameter_hash{ TIMEOUT                        }   ) ;

    $parameter_hash{DEBUG} = 0   
	unless( $parameter_hash{ DEBUG                          }   ) ;
    
    $parameter_hash{ABSOLUTE_ALL_CONTAINED_URLS} = 0   
	unless( $parameter_hash{ ABSOLUTE_ALL_CONTAINED_URLS    }   ) ;


    ## Require additional modules.

    if( $require_extract ) { 
	
	eval { 
	    require LWP::UserAgent ;
	    require HTTP::Request  ;
	}; croak( "LWP::UserAgent and HTTP::Request are required if the url is to be fetched!" ) 
	    if( $@ );
	
	my $tmp;
	( $parameter_hash{ CURRENT_URL }, $tmp, $tmp, $tmp ) =  _convert_to_valid_url( $parameter_hash{ CURRENT_URL } );

	$parameter_hash{ CURRENT_URL_HTML } = 
	    _get_url_html( 
		$parameter_hash{ CURRENT_URL },
		$parameter_hash{ USERAGENT   },
		$parameter_hash{ TIMEOUT     }
	    );

    }

    ## Check on the correctness of the input url.

    my ( $url, $protocol, $domain_name, $uri ) =  
	_convert_to_valid_url( $parameter_hash{ CURRENT_URL } );

    $parameter_hash{ CURRENT_URL } = $url;

    my $self = {

	CURRENT_URL                  =>   $parameter_hash{ CURRENT_URL                   }        ,
	
	CURRENT_URL_HTML             =>   $parameter_hash{ CURRENT_URL_HTML              }        ,
	
	USER_AGENT                   =>   $parameter_hash{ USER_AGENT                    }        ,
	TIMEOUT                      =>   $parameter_hash{ TIMEOUT                       }        ,
	
	DEBUG                        =>   $parameter_hash{ DEBUG                         }        ,
	
	ABSOLUTE_ALL_CONTAINED_URLS  =>   $parameter_hash{ ABSOLUTE_ALL_CONTAINED_URLS   }        ,
	
	_REQUIRE_EXTRACT             =>   $require_extract                                        ,
	_BASE_PROTOCOL               =>   $protocol                                               ,
	_BASE_DOMAIN                 =>   $domain_name                                            ,
        _BASE_URI                    =>   $uri 
	    
    };


    ## Private and class data here. 

       ## NONE


    bless( $self, $class );

    if( $self->{ DEBUG } == 1 ) { 
	print STDERR "HTML::Miner Object: \n"   ;
	print "$self";                          ;
    }

    return $self;

}


=head2 get_links

This function extracts all URLs from a web page.

B<Syntax:>

   When called on an HTML::Miner Object :
 
          $retun_element = $html_miner->get_links();

   When called directly                 :

          $retun_element = get_links( $url, $optionally_html_of_url );

   The direct call is intended to be a simplified version of OO call 
       and so does not allow for customization of the useragent and so on!


B<Output:>

This function ( regardless of how its called ) returns a pointer to an Array of Hashes who's structure is as follows:

    $->Array( 
       Hash->{ 
           "URL"             => "extracted url"                       ,
           "ABS_EXISTS"      => "0_if_abs_url_extraction_failed"      , 
           "ABS_URL"         => "absolute_location_of_extracted_url"  ,
           "TITLE"           => "title_of_this_url"                   , 
           "ANCHOR"          => "anchor_text_of_this_url"             ,
           "DOMAIN"          => "domain_of_this_url"                  ,
           "DOMAIN_IS_BASE"  => "1_if_this_domain_same_as_base_domain ,
           "PROTOCOL"        => "protocol_of_this_domain"             ,
           "URI"             => "URI_of_this_url"                     ,
       }, 
         ... 
    )

So, to access the title of the second URL found you would use (yes the order is maintained):

     @{ $retun_element }[1]->{ TITLE }

B<NOTES:>

    If ABS_EXISTS is 0 then DOMAIN, DOMAIN_IS_BASE, PROTOCOL and URI will be undefined

    To extract URLs from a HTML snippet when one does not care about the url of that page, simply pass some garbage as the URL 
         and ignore everything except URL, TITLE and ANCHOR

    "ANCHOR" might contain HTML such as <span>, use HTML::Strip if required. 

=cut 

sub get_links { 

    my $tmp = shift  ;

    my $self         ;
    my $url          ;
    my $html         ;

    my @result_arr   ;

    my $user_agent = "Html_Miner/$VERSION" ;
    my $timeout    = 60                    ; 


    ## First extract all required information.

    if( UNIVERSAL::isa( $tmp, 'HTML::Miner' )  ) { 

	$self = $tmp                        ;

	$url  = $self->{ CURRENT_URL      } ;
	$html = $self->{ CURRENT_URL_HTML } ;

    } else { 
	
	$url = $tmp                         ;

	## Check for validity of url! 
	my ( $tmp, $protocol, $domain_name, $uri ) =  
	    _convert_to_valid_url( $url )   ;
	$url = $tmp                         ;

	my @params               = @_       ;
	my $html_has_been_passed = @params  ;

	
	if( $html_has_been_passed ) { 
	    $html = shift                   ;
	} else { 

	    ## Need to retrieve html 
	
	    eval { 
		require LWP::UserAgent      ;
		require HTTP::Request       ;
	    }; 
	    croak( "LWP::UserAgent and HTTP::Request are required if the url is to be fetched!" ) 
		if( $@ );


	    $html = _get_url_html( $url, $user_agent, $timeout )   ;
	    
	} ## HTML Not passed


    }  ## Not called on Object.


    ## Now start extracting the URLs
    
    while( $html =~ m/(<\s*?a\s+?href\s*?=(\"|\')([^(\"|\')]*?)(\"|\')([^>]*?)>(.*?)<\s*?\/a\s*?>)/gis ){

	my $this_url    = $3 ;
	my $this_anchor = $6 ;

	my $match      = $1 ;
	my $this_title = "" ;
	if( $match =~ m/title=(\"|\')([^(\"|\')]*?)(\"|\')/is ) {
	    $this_title = $2;
	}

	my $this_abs_url        = "" ;
	my $this_abs_url_exists =  1 ;
	eval{ 

	    $this_abs_url = get_absolute_url( $url, $this_url );

	}; $this_abs_url_exists = 0 if( $@ );

	my $this_domain                 ;
	my $this_domain_is_base_domain  ;
	my $this_protocol               ;
	my $this_uri                    ;
	if( $this_abs_url_exists ) {

	    my $tmp;
	    eval {
		( $tmp, $this_protocol, $this_domain, $this_uri ) =  
		    _convert_to_valid_url( $this_abs_url ) ;
	    }; $this_abs_url_exists = 0 if( $@ );
	    

	    my ( $protocol, $domain, $uri );
	    eval {
		( $tmp, $protocol, $domain, $uri ) =  
		    _convert_to_valid_url( $url ) ;
	    }; croak( "Unexpected Error - Giving up!" ) if( $@ );
	    

	    $this_domain_is_base_domain = ( $domain eq $this_domain ) ? 1 : 0; 

	}

	my %this_url_hash = ( 
	    "URL"             => $this_url                        ,
	    "ABS_EXISTS"      => $this_abs_url_exists             ,
	    "ABS_URL"         => $this_abs_url                    ,  
	    "TITLE"           => $this_title                      ,
	    "ANCHOR"          => $this_anchor                     ,
	    "DOMAIN"          => $this_domain                     ,
	    "DOMAIN_IS_BASE"  => $this_domain_is_base_domain      ,
	    "PROTOCOL"        => $this_protocol                   ,
	    "URI"             => $this_uri
	    );

	push( @result_arr, \%this_url_hash );

    }


    return \@result_arr;

}


=head2 get_page_css_and_js

This function extracts all CSS style sheets and JS Script files use on a web page.

B<Syntax:>

   When called on an HTML::Miner Object :
 
          $retun_element = $html_miner->get_page_css_and_js(
               CONVERT_URLS_TO_ABS       =>    0/1                         [ B<Optional> argument, default is 1 ]
          );

   When called directly                 :

          $retun_element = get_page_css_and_js( 
               URL                       =>    $url                     , 
               HTML                      =>    $optionally_html_of_url  ,  [ B<Optional> argument, html extracted if not provided ] 
               CONVERT_URLS_TO_ABS       =>    0/1                      ,  [ B<Optional> argument, default is 1                   ]
          );

   The direct call is intended to be a simplified version of OO call 
       and so does not allow for customization of the useragent and so on!


B<Output:>

This function ( regardless of how its called ) returns a pointer to a Hash [ JS or CSS ] of Arrays containing the URLs

    $->HASH->{ 
          "CSS"   => Array( "extracted url1", "extracted url2", .. )
          "JS"    => Array( "extracted url1", "extracted url2", .. )
      }

So, to access the URL of the second CSS style sheet found you would use (again the order is maintained):

     $$retun_element{ "CSS" }[1];

Or
     $css_data = @{ $retun_element->{ "CSS" } }    ;
     $second_css_url_found = $css_data[1]          ;

B<NOTES:>

To extract CSS and JS links from a HTML snippet when one does not care about the url of that page, simply set CONVERT_URLS_TO_ABS to 0 and everything should be fine. 


=cut 

sub get_page_css_and_js { 

    my $number_of_arguments = @_ ;

    my $self                     ;
    unless( int( $number_of_arguments / 2 ) * 2 == $number_of_arguments ) { # Odd number of elems, Must have been called on Obj.
	$self = shift               ;
    }

    my %params = @_   ;

    $params{ CONVERT_URLS_TO_ABS } = 1 unless( defined( $params{ CONVERT_URLS_TO_ABS } ) );

    my $url          ;
    my $html         ;

    my $user_agent = "Perl_Html_Miner/$VERSION" ;
    my $timeout    = 60                         ;

    ## First extract all required information.

    if( defined( $self ) ) { 
	if( UNIVERSAL::isa( $self, 'HTML::Miner' )  ) { 
	    $url  = $self->{ CURRENT_URL      } ;
	    $html = $self->{ CURRENT_URL_HTML } ;
	} else { 
	    croak( "get_page_css_and_js called with params I can't understand!" );
	}
    } else { 
	
	$url = $params{ URL }               ;

	## Check for validity of url! 
	my ( $tmp, $protocol, $domain_name, $uri ) =  
	    _convert_to_valid_url( $url )   ;
	$url = $tmp                         ;

	my $html_has_been_passed = defined( $params{ HTML } ) ? 1 : 0 ;

	
	if( $html_has_been_passed ) { 
	    $html = $params{ HTML }         ;
	} else { 

	    ## Need to retrieve html 
	
	    eval { 
		require LWP::UserAgent      ;
		require HTTP::Request       ;
	    }; 
	    croak( "LWP::UserAgent and HTTP::Request are required if the url is to be fetched!" ) 
		if( $@ );

	    $html = _get_url_html( $url, $user_agent, $timeout )   ;
	    
	} ## HTML Not passed


    }  ## Not called on Object.


    ## Now start extracting the URLs

    ## CSS

    my @css_files ;
    while ( $html =~ m/(<link [^<]*?href=\"([^\"]+?\.css[^"]*?)\")/gis) {  
	my $css_url = $2 ;
	if( $params{ CONVERT_URLS_TO_ABS } ) { 
	    $css_url = get_absolute_url( $url, $2 ) ;
	} 
	push @css_files, $css_url ;
    }



    ## JS

    my @js_files  ;
    while ( $html =~ m/(<script [^<]*?src=\"([^\"]+?\.js[^"]*?)\")/gis) {  
	my $css_url = $2 ;
	if( $params{ CONVERT_URLS_TO_ABS } ) { 
	    $css_url = get_absolute_url( $url, $2 ) ;
	} 
	push @js_files, $css_url ;
    }


    my %result_hash       ;
    $result_hash{ 'CSS' } = \@css_files ;
    $result_hash{ 'JS'  } = \@js_files  ;

    return \%result_hash  ;

}


=head2 get_absolute_url 

This function takes as arguments the base URL whithin the HTML of which a second (possibly relative URL ) URL was found, and returns the absolute location of that second URL.

B<Example:>
    
    my $out = HTML::Miner::get_absolute_url( "www.perl.com/help/fag/", "../../about/" )

    Will return:

          www.perl.com/about/


B<NOTE:>

    This function cannot be called on the HTML::Miner Object. 
    The function get_links does this for all URLs found on a webpage. 


=cut


sub get_absolute_url {

    my $contained_page_url    = shift ;
    my $possible_relative_url = shift ;

    if( UNIVERSAL::isa( $contained_page_url, 'HTML::Miner' )  ) { 
	croak( "'get_absolute_url' is not to be called on the HTML::Miner object - please see documentation for usage." );
    }

    my $absolute_url                  ;

    my ( $tmp, $protocol, $domain_name, $uri ) =  
	_convert_to_valid_url( $contained_page_url ) ;
    $contained_page_url = $tmp                    ;


    ## First check if the $possible_relative_url is already absolute.

    if( $possible_relative_url =~ /http(s)?:\/\// ) {

	eval {

	    my $tmp;
	    ( $possible_relative_url, $tmp, $tmp, $tmp ) =  
		_convert_to_valid_url( $possible_relative_url ) ;
	}; 
	if( $@ ) {
	    croak( "Relative url is of a form I do not understand!" ) ;
	} else {
	    return $possible_relative_url;
	}

    }
    
    
    ## The different kinds of Relative URLs are as follows:
    ##     (../)*something
    ##     ./something
    ##     /something
    ##     #something
    ##     something



    if( $possible_relative_url =~ m/^#.+/ ) { 

	$absolute_url = $contained_page_url;
	$absolute_url = $absolute_url.$possible_relative_url;

	## Redundant check - but I just think else if makes code messy!!

	eval {
	    my ( $tmp_rel, $protocol_rel, $domain_name_rel, $uri_rel ) =  
		_convert_to_valid_url( $absolute_url ) ;
	}; croak( "Relative url is of a form I do not understand!" ) if( $@ );

	return $absolute_url;

    }

    if( $possible_relative_url =~ m/^\// or $possible_relative_url =~ m/^\.\// ) { 
	
	$possible_relative_url =~ s/^\.//;
	$absolute_url = $protocol."://".$domain_name.$possible_relative_url;
	

	eval {
	    my ( $tmp_rel, $protocol_rel, $domain_name_rel, $uri_rel ) =  
		_convert_to_valid_url( $absolute_url ) ;
	}; croak( "Relative url is of a form I do not understand!" ) if( $@ );

	return $absolute_url;

    }


    if( $possible_relative_url =~ /^\.\./ )   { 

	my $dirs = $uri;
	$dirs =~ s/[^\/]*?$//g;
	$dirs =~ s/^\///g;

	my @path_info = split( /\//, $dirs );

	my $back_track = $possible_relative_url;
	my @back_track = split( /\.\.\//, $back_track );

	my $times_to_back_track = @back_track;
	$times_to_back_track--;

	for( my $count = 0; $count < $times_to_back_track; $count++ ) { 
	    pop( @path_info );
	}

	my $dir_to_absolute_path = join( '/', @path_info, );
	
	my $additional_dir_to_absolute_path = $possible_relative_url;
	$additional_dir_to_absolute_path =~ s/[^\/]*?$//g;

	$additional_dir_to_absolute_path =~ s/(\.\.\/)+//g;

	my $absolute_url_file_name = $possible_relative_url;
	$absolute_url_file_name =~ s/^.*\///g;

	$absolute_url = "$protocol://".
	    "$domain_name".
	    "$dir_to_absolute_path/".
	    "$additional_dir_to_absolute_path".
	    "$absolute_url_file_name";


	eval {
	    my ( $tmp_rel, $protocol_rel, $domain_name_rel, $uri_rel ) =  
		_convert_to_valid_url( $absolute_url ) ;
	}; croak( "Relative url is of a form I do not understand!" ) if( $@ );

	return $absolute_url;

    } 



    ## Check if possible_relative_url is of for something.

    $absolute_url = $contained_page_url;
    $absolute_url =~ s/[^\/]+$//;
    $absolute_url = $absolute_url.$possible_relative_url;
    
    eval {
	my ( $tmp_rel, $protocol_rel, $domain_name_rel, $uri_rel ) =  
	    _convert_to_valid_url( $absolute_url ) ;
    }; 
    if( $@ ) {
	croak( "Relative url is of a form I do not understand!" ) ;
    } else { 
	return $absolute_url;
    }

    croak( "Relative url is of a form I do not understand!" ) ;
    
}



=head2 break_url

This function, given an URL, returns the Domain, Protocol, URI and the input URL in its 'standard' form.


B<Syntax:>

It is called on the HTML::Miner Object as follows:

    my ( $clear_url, $protocol, $domain, $uri ) = $break_url();

    NOTE: This will return the details of the 'CURRENT_URL'


It is called directly as follows:
    
    my ( $clear_url, $protocol, $domain, $uri ) = $break_url( 'www.perl.org/help/faq/' );


B<Output:>

    Input
   
         www.perl.org/help/faq

    Output
      
         clean_url --> http://www.perl.org/help/faq/
         protocol  --> http
         domain    --> www.perl.org
         uri       --> help/faq/


=cut

sub break_url {

    my $tmp = shift  ;

    my $self         ;
    my $url          ;

    ## First extract all required information.
    if( UNIVERSAL::isa( $tmp, 'HTML::Miner' )  ) { 

	$self = $tmp;
	$url = $self->{ CURRENT_URL };

    } else { 
	
	$url = $tmp ;

    }

    
    return _convert_to_valid_url( $url );

}


=head2 get_redirect_destination

This function takes, as argument, an URL that is potentially redirected to another and another and ... URL
and returns the FINAL destination URL.

This function REQUIRES access to the web.

B<Example:>

    my $destination_url = HTML::Miner::get_redirect_destination( 
       'http://rss.cnn.com/~r/rss/edition_world/~3/403863461/index.html' , 
       'optional_user_agent',
       'optional_timeout'
    );

    $destination_url will contain:

       "http://edition.cnn.com/2008/WORLD/americas/09/26/russia.chavez/index.html?eref=edition_world"

B<NOTES:> 

   This function CANNOT be called on the HTML::Miner Object.

B<WARNING:>

   This function is NOT thread safe, use get_redirect_destination_thread_safe ( described below ) if this function is 
     being used within a thread and there is a chance that any of the interim redirect URLs are HTTPS.

=cut

sub get_redirect_destination {

    my $url         =  shift ;
    my $user_agent  =  shift ;
    my $timeout     =  shift ;

    $user_agent = "Perl_HTML_Miner/$VERSION" unless( $user_agent                ) ;
    $timeout    = 60                         unless( $timeout and $timeout != 0 ) ;

    if( UNIVERSAL::isa( $url, 'HTML::Miner' )  ) { 
	croak( "'get_redirect_destination' is not to be called on the HTML::Miner object - please see documentation for usage." );
    }

    eval { 
	my( $unused1, $unused2, $unused3, $unused4 ) = 	    
	    _convert_to_valid_url( $url ) ;
    }; croak( $@ ) if( $@ );

    eval {

	require HTTP::Request  ;
	require LWP::UserAgent ;

    }; croak( "'get_redirect_destination' requires HTTP::Request and LWP::UserAgent, please see documentation for more details." ) if( $@ );

    
    my $request = HTTP::Request->new(
	GET => $url
	);

    my $ua = LWP::UserAgent->new  ;
    $ua->timeout( $timeout )      ;
    $ua->env_proxy                ;
    $ua->agent( $user_agent )     ;
    
    my $response     = $ua->request( $request ) ;
    my $redirect_url = $response->base          ;
    
    return ( $redirect_url );

}


=head2 get_redirect_destination_thread_safe

This function takes, as argument, an URL that is potentially redirected to another and another and ... URL
and returns the FINAL destination URL and is thread safe.

This function REQUIRES access to the web.

B<Example:>

    my $destination_url = HTML::Miner::get_redirect_destination( 
       'on.fb.me/qoBoK' , 
       'optional_user_agent',
       'optional_timeout'
    );

    $destination_url will contain:

       "https://www.facebook.com"

B<NOTES:> 

   This function CANNOT be called on the HTML::Miner Object.
   This function hits the web for each redirect that it tracks - So to find the redirect of an URL that redirects 15 times it will
        access the web 15 times. Do NOT use this function instead of get_redirect_destination unless you have to. 

=cut

sub get_redirect_destination_thread_safe {

    my $url         =  shift ;
    my $user_agent  =  shift ;
    my $timeout     =  shift ;
    my $attempts    =  shift ;

    if( UNIVERSAL::isa( $url, 'HTML::Miner' )  ) { 
	croak( "'get_redirect_destination_thread_safe' is not to be called on the HTML::Miner object - please see documentation for usage." );
    }

    eval { 
	my( $unused1, $unused2, $unused3, $unused4 ) = 	    
	    _convert_to_valid_url( $url ) ;
    }; croak( $@ ) if( $@ );

    eval {

	require HTTP::Request  ;
	require LWP::UserAgent ;

    }; croak( "'get_redirect_destination_thread_safe' requires HTTP::Request and LWP::UserAgent, please see documentation for more details." ) if( $@ );

    ## Critical for thread safe ... Can not find redirect of https locations.
    if( $url =~ /^https/ ) { 
	return $url ;
    }

    { 
	# Check if url is just http://something.something... with no slash at all - redirect beyond that is no point. 
	my $no_http_url = $url            ;
	$no_http_url    =~ s/http:\/\///g ;
	return $url unless( $no_http_url =~ /\// ) ;
    }


    $user_agent = "Perl_HTML_Miner/$VERSION" unless( $user_agent                ) ;
    $timeout    = 60                         unless( $timeout and $timeout != 0 ) ;
    $attempts   = 0                          unless( $attempts                  ) ;

    my $request = HTTP::Request->new(
        GET => $url
        );

    my $ua = LWP::UserAgent->new  ;
    $ua->timeout( $timeout )      ;
    $ua->env_proxy                ;
    $ua->agent( $user_agent )     ;
    $ua->max_redirect( 0 )        ;

    my $response      =  $ua->request( $request ) ;

    my $response_code =  $response->{ _rc }       ;

    if( $response_code == 200 or !( $response_code > 299 and $response_code < 400 ) or $attempts > 7 ) { # Slightly redundant with the 200 but the are separate cases.
	return $url ;
    }

    return get_redirect_destination_thread_safe( $response->{ _headers }{ location }, $user_agent, $timeout, ++$attempts ) ;

}



=head2 get_images

This function extracts all images from a web page.

B<Syntax:>

   When called on an HTML::Miner Object :
 
          $retun_element = $html_miner->get_images();

   When called directly                 :

          $retun_element = get_images( $url, $optionally_html_of_url );

   The direct call is intended to be a simplified version of OO call 
       and so does not allow for customization of the useragent and so on!


B<Output:>

This function ( regardless of how its called ) returns a pointer to an Array of Hashes who's structure is as follows:

    $->Array( 
       Hash->{ 
           "IMG_LOC"         => "extracted_image"                        ,
           "ALT"             => "alt_text_of_this_image"                 ,
           "ABS_EXISTS"      => "0_if_abs_url_extraction_failed"         , 
           "ABS_LOC"         => "absolute_location_of_extracted_image"   ,
           "IMG_DOMAIN"      => "domain_of_this_image"                   ,
           "DOMAIN_IS_BASE"  => "1_if_this_domain_same_as_base_domain    ,
       }, 
         ... 
    
)

So, to access the alt text of the second image found you would use (yes the order is maintained):

     @{ $retun_element }[1]->{ TITLE }

B<NOTE:>

    If ABS_EXISTS is 0 then IMG_DOMAIN and DOMAIN_IS_BASE will be undefined

    To extract images from a HTML snippet when one does not care about the URL of that page, simply pass some garbage as 
           the URL and ignore everything except absolute locations and domains.

=cut 

sub get_images { 

    my $tmp = shift  ;

    my $self         ;
    my $url          ;
    my $html         ;

    my @result_arr   ;

    my $user_agent = "Perl_Html_Miner/$VERSION" ;
    my $timeout    = 60                         ;  

    my $domain       ;
    

    ## First extract all required information.

    if( UNIVERSAL::isa( $tmp, 'HTML::Miner' )  ) { 

	$self = $tmp                        ;

	$url     =  $self->{ CURRENT_URL      } ;
	$html    =  $self->{ CURRENT_URL_HTML } ;
	$domain  =  $self->{ _BASE_DOMAIN     } ;

    } else { 
	
	$url = $tmp                         ;

	## Check for validity of url! 
	my ( $tmp, $protocol, $domain, $uri ) =  
	    _convert_to_valid_url( $url )   ;
	$url = $tmp                         ;

	my @params               = @_       ;
	my $html_has_been_passed = @params  ;

	
	if( $html_has_been_passed ) { 
	    $html = shift                   ;
	} else { 

	    ## Need to retrieve html 
	
	    eval { 
		require LWP::UserAgent      ;
		require HTTP::Request       ;
	    }; 
	    croak( "LWP::UserAgent and HTTP::Request are required if the url is to be fetched!" ) 
		if( $@ );


	    $html = _get_url_html( $url, $user_agent, $timeout )   ;
	    
	} ## HTML Not passed


    }     ## Not called on Object.




    ## Now start extracting the images
    ##   img tags can be of different forms and they are split up below for readability.
    ##     1. <img src=something alt=something />
    ##     2. <img alt=something src=something />
    ##     3. <img src=someting />


    while( $html =~ m/(<\s*?img.*?src\s*?=[\"|\']([^(\"|\')]*?)[\"|\'].*?\>)/gis ){

	my $complete_image_link = $1;

	my $this_img ;
	my $this_alt ;

	if( $complete_image_link =~ m/src=[\'\"](.*?)[\'\"]/is ) { 
	    $this_img = $1;
	}

	if( $complete_image_link =~ m/alt=[\'\"](.*?)[\'\"]/is ) { 
	    $this_alt = $1;
	}
	
	my $this_abs_url        = "" ;
	my $this_abs_url_exists =  1 ;
	eval{ 

	    $this_abs_url = get_absolute_url( $url, $this_img );

	}; $this_abs_url_exists = 0 if( $@ );
	

	my $this_domain                 ;
	my $this_domain_is_base_domain  ;
	if( $this_abs_url_exists ) {

	    my $tmp;
	    eval {
		( $tmp, $tmp, $this_domain, $tmp ) =  
		    _convert_to_valid_url( $this_abs_url ) ;
	    }; $this_abs_url_exists = 0 if( $@ );
	    
	    $this_domain_is_base_domain = ( $domain eq $this_domain ) ? 1 : 0; 

	}


	my %this_img_hash = ( 
	    "IMG_LOC"         => $this_img                        ,
	    "ALT"             => $this_alt                        ,
	    "ABS_EXISTS"      => $this_abs_url_exists             ,
	    "ABS_LOC"         => $this_abs_url                    ,  
	    "IMG_DOMAIN"      => $this_domain                     ,
	    "DOMAIN_IS_BASE"  => $this_domain_is_base_domain      
	    );

	push( @result_arr, \%this_img_hash );

    }


    return \@result_arr;

}


=head2 get_meta_elements

This function retrieves the following meta elements for a given URL (or HTML snippet)

    Page Title
    Meta Description
    Meta Keywords
    Page RSS Feeds


B<Syntax:>

It is called through the HTML::Miner Object as follows:

    $return_hash = $html_miner->get_meta_elements( );

It is called directly as follows:

    $return_hash = $html_miner->get_meta_elements( 
                                    URL   => "url_of_page"  ,
                                    HTML  => "html_of_page
                                );

    Note: The above function requires either the html of the url. If the 
          HTML is provided then the URL is used to retrieve the HTML.
          If both are not provided this function will croak.

          Again this function does not allow for customization of User Agent
          and timeout when called directly. 



B<Output:>

In either case the returned hash is of the following structure:
    
    $return_hash = ( 
               TITLE     =>   'title_of_page'         ,
               DESC      =>   'description_of_page'   ,
               KEYWORDS  =>   
                    'pointer to array of words'       ,
               RSS       => 
                    'pointer to Array of Hashes of RSS links' as below
     )


    $return_hash->{ RSS } = (
             [
               TYPE      => 'eg: application/atom+xml',
               TITLE     => 'Title of this RSS Feed'  ,
               URL       => 'URL of this RSS Feed'
             ],
                 ...
    )



=cut


sub get_meta_elements {

    my @tmp = @_                       ;

    croak( "'get_meta_elements' requires either the URL or the page HTML when not called on the HTML::Miner Object!" )
	unless( $tmp[0] )              ;
    
    my $html                               ;

    my $user_agent = "Perl_Html_Miner/$VERSION" ;
    my $timeout    = 60                         ; 
    

    ## Extract parameters
    if( UNIVERSAL::isa( $tmp[0], 'HTML::Miner' )  ) { 

	my $self = $tmp[0]                         ;
	$html    = $self->{ CURRENT_URL_HTML }     ;

    } else {

	no warnings;
	my ( %params ) = @tmp ;
	use warnings;

	unless( $params{ URL } or $params{ HTML } ) {
	    croak( "When not called on the HTML::Miner Object 'get_meta_elements' expects a Hash with either URL or HTML - Please see the documentation for details.\n" );
	}

	$html = $params{ HTML };

	unless( $html ) { 

	    my $url = $params{ URL };
	    
	    eval {
		my ( $unused1, $unused2, $unused3 );
		( $url, $unused1, $unused2, $unused3 ) = 	    
		    _convert_to_valid_url( $url ) ;
	    }; croak( $@ ) if( $@ );
	    
	    eval{

		require HTTP::Request  ;
		require LWP::UserAgent ;

	    }; croak( "'get_meta_elements' requires HTTP::Request and LWP::UserAgent, when called with URL only - please see documentation for more details." ) if( $@ );

	    $html = _get_url_html( $url, $user_agent, $timeout );

	} ## End of unless( $html );
	    

    }     ## End of else (non-object call)

    

    ## Now that we have the HTML we extract the meta elements.


    ## Just in case there are multiple "head" blocks in the page - 
    ##    I know, I know - but some people do that!
    my $head;
    while( $html =~ m/<head.*?>(.*?)<\/head>/gis ) { 

	$head = $head.$1;

    }
	

    my $title;
    if( $head =~ m/<title.*?>(.*?)<\/title>/gis ) { 
	$title = $1 ;
    }


    my $description;
    if( $head =~ m/<meta\s+name=[\'\"]description[\'\"].*?content=[\'\"](.*?)[\'\"].*?\/>/is ) { 
	$description = $1;
    }

    ## Again keywords someetimes come in multiple entries!
    my $keywords_string = "";
    while( $head =~ m/<meta\s+name=[\'\"]keywords[\'\"].*?content=[\'\"](.*?)[\'\"].*?\/>/gis ) { 
	$keywords_string = $keywords_string.",".$1;
    }

    my @keywords = split( ",", $keywords_string );

    my @tmp_str;
    foreach my $tmp ( @keywords ) { 

	$tmp =~ s/^\s+//;
	$tmp =~ s/\s+$//;
	push @tmp_str, $tmp if( $tmp );

    }
    @keywords = @tmp_str;

    
    my @page_rss;
    while( $head =~ m/<link\s+rel=[\'\"]alternate[\'\"].*?type=[\'\"](application.*?)[\'\"].*?title=[\"\'](.*?)[\"\'].*?href=[\"\'](.*?)[\"\'].*?\/>/gis ) { 
	my %this_feed;
	$this_feed{ TYPE  }  = $1 ;
	$this_feed{ TITLE }  = $2 ;
	$this_feed{ LINK  }  = $3 ;

	push @page_rss, \%this_feed;
    }


    my %return_hash;
    $return_hash{ TITLE    } = $title       ;
    $return_hash{ DESC     } = $description ;
    $return_hash{ KEYWORDS } = \@keywords   ;
    $return_hash{ RSS      } = \@page_rss   ;


    return \%return_hash ;

}

=head1 INTERNAL SUBROUTINES/METHODS

These functions are used by the module. They are not meant to be called directly using the Net::XMPP::Client::GTalk object although 
there is nothing stoping you from doing that. 

=head2 _get_url_html

This is an internal function and is not to be used externally.

=cut

sub _get_url_html { 

    my $url        =  shift ;
    my $user_agent =  shift ;
    my $timeout    =  shift ;

    my $request = HTTP::Request->new(
	GET => $url
	);
    
    
    my $ua = LWP::UserAgent->new      ;
    $ua->timeout( $timeout )          ;
    $ua->env_proxy                    ;
    $ua->agent( $user_agent )         ;
    
	    
    my $response = $ua->request( $request );
    
    croak $response->status_line  unless ($response->is_success) ;
    
    my $url_content   =  $response->content                   ;

    ## Currently not used.
    my $last_modified =  $response->header( 'last_modified' ) ;
    my $expires       =  $response->header( 'expires'       ) ;

    return $url_content ;

}



=head2 _convert_to_valid_url 

This is an internal function and is not to be used externally.

=cut

sub _convert_to_valid_url {

    my $url = shift ;

    croak "URL - Malformed beyond recognition!\n" unless( $url );

    # If missing add trailing slash as per URI rules
    unless( ( $url =~ /\/$/ ) or ( $url =~ /([^\/]\/[^\/]+\.[^\/]+)/ ) ) { 
	$url = $url."/"; 
    }
    
    # If missing add http:// as per URI rules.
    unless( $url =~ /^http:\/\// or $url =~ /^https:\/\// ) {
	$url = "http://".$url;
    }

    ## Now break the url into its parts - failure here will imply that the url is beyond repair!
    my $protocol        ;
    my $domain_name     ;
    my $tmp             ;
    my $uri             ;

    if( $url =~ m|(\w+)://([^/:]+)(:\d+)?/(.*)| ) {

        $protocol      =       $1 ;
        $domain_name   =       $2 ;
        $uri           = "/" . $4 ;
	
	my $domain_name_for_checkes = $domain_name ;
	$domain_name_for_checkes    = lc( $domain_name_for_checkes ) ;

	croak "URL - $url - Malformed! Sorry I tried to fix it but could not!\n"
	    unless( 
		( $domain_name_for_checkes =~ m/[a-z0-9-]+(\.[a-z])+/ )
		or
		( $domain_name_for_checkes =~ m/\d+\.\d+\.\d+\.\d+/   ) ## Bug id 62877
	    );

    } else {
        croak "URL - $url - Malformed! Sorry I tried to fix it but could not!\n";
    }

    
    return ( $url, $protocol, $domain_name, $uri ) ;

}    



=head1 AUTHOR

Harish T Madabushi, C<< <harish.tmh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-miner at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Miner>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Miner


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Miner>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Miner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Miner>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Miner/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to user B<ultranerds> from L<http://perlmonks.org/?node_id=721567> for suggesting and helping with JS and CSS extraction.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 Harish Madabushi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of HTML::Miner
