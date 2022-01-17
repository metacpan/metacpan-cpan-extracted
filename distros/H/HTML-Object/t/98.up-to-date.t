#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
	unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
	{
		plan(skip_all => 'These tests are for author or release candidate testing');
	}
    use constant ELEMENTS_URL => 'https://developer.mozilla.org/en-US/docs/Web/HTML/Element';
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use Data::Dump;
    use DateTime;
    use DateTime::Format::Strptime;
    use Devel::Confess;
    use HTML::Entities ();
    use HTML::Object::DOM;
    use HTML::Object::DOM::Element::Shared;
    use JSON;
    use LWP::UserAgent;
    use Module::Generic::Array;
    use Module::Generic::File qw( file );
    use Nice::Try;
    use URI;
    use constant MOZILLA_BASE_URL => 'https://developer.mozilla.org';
    use open ':std' => ':utf8';
    our $MODULES_EXISTS = {};
};

our $base_dir = file( __FILE__ )->parent->parent;
# my $ua_name = "HTML::Object/$VERSION";
my $ua_name = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:95.0) Gecko/20100101 Firefox/95.0';
our $j = JSON->new->relaxed->pretty->canonical->allow_nonref->allow_blessed->convert_blessed;
our $ua = LWP::UserAgent->new(
    agent   => $ua_name,
    timeout => 5,
);
my $cache_dir = file('./dev/mozilla_doc');
$cache_dir->mkdir if( !$cache_dir->exists );
my $elements_cache_file = $cache_dir->child( 'elements.html' );
my $dict_file = file( './lib/HTML/html_tags_dict.json' );
my $dict_data = $dict_file->load_utf8;
my $repo = $j->decode( $dict_data );
my $dict = $repo->{dict};

our $mod_elements_base_dir = $base_dir->child( './lib/HTML/Object/DOM/Element' );
my $mod_shared = $mod_elements_base_dir->child( 'Shared.pm' );

my $p = HTML::Object::DOM->new;
# my $dict = $p->dictionary;
my $doc = &_check_cache_http({ file => $elements_cache_file, uri => ELEMENTS_URL });

my $art = $doc->getElementById( 'content' );
if( !$art )
{
    die( "Unable to find the article tag with id \"content\".\n" );
}
my $links = $art->getElementsByTagName( 'a' );
diag( sprintf( "%d links found.", $links->length ) );
my $tags = Module::Generic::Array->new;
my $seen = {};
$links->foreach(sub
{
    my $uri = $_->href;
    if( $uri->path =~ /\/Element\/([a-zA-Z]+)$/ )
    {
        my $tag = $1;
        # Avoid duplicates
        next if( ++$seen->{ $tag } > 1 );
        my $def = 
        {
            uri => $uri->abs( ELEMENTS_URL ),
            tag => $tag,
        };
        # diag( sprintf( "Found tag \"$tag\" with url \"%s\".", $def->{uri} ) );
        ok( exists( $dict->{ $tag } ), "tag \"$tag\" exists in our dictionary" );
        $tags->push( $def ) if( !exists( $dict->{ $tag } ) );
    }
});

done_testing();

# XXX
# $tags->push({ tag => 'canvas', uri => URI->new( 'https://developer.mozilla.org/en-US/docs/Web/HTML/Element/canvas' ) });
exit(0) unless( !$tags->is_empty );
diag( sprintf( "Procssing %d missing tag.", $tags->length ) );
$tags->foreach(sub
{
    my $def = shift( @_ );
    $def = &fetch( $def );
    my $this = {};
    $this->{description} = ( $def->{description} // '' );
    $this->{is_empty} = ( $def->{is_empty} // \0 );
    $this->{is_inline} = ( $def->{is_inline} // \0 );
    $this->{ref} = exists( $def->{ref} ) ? delete( $def->{ref} ) : delete( $def->{uri} );
    $this->{is_deprecated} = delete( $def->{is_deprecated} ) if( exists( $def->{is_deprecated} ) );
    $this->{is_svg} = delete( $def->{is_svg} ) if( exists( $def->{is_svg} ) );
    $this->{link_in} = delete( $def->{link_in} ) if( exists( $def->{link_in} ) && ref( $def->{link_in} ) eq 'ARRAY' );
    $dict->{ $def->{tag} } = $this;
    diag( "Adding tag \"", $def->{tag}, "\" with data: ", Data::Dump::dump( $this ) );
});

if( !$tags->is_empty )
{
    diag( "Backing up the tag json dictionary file \"$dict_file\" to \"${dict_file}.bak" );
    $dict_file->copy( "${dict_file}.bak" ) || die( $dict_file->error );
    my $json = $j->encode( $repo );
    $dict_file->open( '>', { binmode => 'utf-8', autoflush => 1 }) || die( $dict_file->error );
    $dict_file->print( $json );
    $dict_file->close;
}

sub fetch
{
    my $opts = shift( @_ );
    my $tag = $opts->{tag};
    my $uri = $opts->{uri};
    my $def = { tag => $tag, 'ref' => $uri };
    
    my $cache_file = $cache_dir->child( "tag_$tag.html" );
    my $doc = &_check_cache_http({ file => $cache_file, uri => $uri });
    
    # Try to find the article element
    my $art = $doc->look_down( _tag => 'article', class => 'main-page-content' )->first;
    die( "No tag 'article' with class 'main-page-content' found in html data for tag \"$tag\" at url \"$uri\"\n" ) if( !$art );
    
    my $desc_divs = $art->look_down( _tag => 'div' );
    diag( sprintf( "Found %d divs for tag \"$tag\".", $desc_divs->length ) );
    my $desc_div;
    foreach( @$desc_divs )
    {
        if( $_->attr( 'class' ) eq 'notecard deprecated' )
        {
            $def->{is_deprecated} = \1;
            next;
        }
        else
        {
            $desc_div = $_;
            last;
        }
    }
    
    if( $desc_div )
    {
        my $desc = $desc_div->as_trimmed_text;
        # diag( "Description text found is: '$desc'" );
        my @phrases = split( /(?<=\S)\.(?=[[:blank:]\h])/, $desc );
        $def->{description} = _cleanup( $phrases[0] );
    }
    
    my $table = $art->look_down( _tag => 'table', class => 'properties' )->first;
    # No need to go further
    if( !$table )
    {
        diag( "No table property found for tag \"$tag\"." );
        return( $def );
    }
    my $tr = $table->look_down( _tag => 'tr' )->last;
    die( "Cannot find any row in the property table for tag \"$tag\" at url \"$uri\".\n" ) if( !$tr );
    my $th = $tr->look_down( _tag => 'th' )->first;
    die( "Cannot find any <th> in the last row of table property for tag \"$tag\" at url \"$uri\".\n" ) if( !$th );
    my $th_text = $th->as_trimmed_text;
    die( "I was expecting this last <th> in table property for tag \"$tag\" to contain 'DOM interface', but instead I found '${th_text}'.\n" ) if( $th_text ne 'DOM interface' );
    my $class_links = $tr->look_down( _tag => 'a' );
    diag( sprintf( "%d link(s) found.", $class_links->length ) );
    my $class_link;
    my $class;
    # There should not be more than 1, but let us not assume
    foreach( @$class_links )
    {
        # e.g.: /en-US/docs/Web/API/HTMLCanvasElement
        if( $_->href->path =~ /\/API\/([a-zA-Z]+)$/ )
        {
            $class_link = $_;
            $class = $1;
            last;
        }
    }
    if( !defined( $class ) )
    {
        die( "Unable to find any class link for tag \"$tag\" at url \"$uri\".\n" );
    }
    $class =~ s/^HTML((?>(?!Element).)+)Element$/$1/;
    $def = &fetch_class({ tag => $tag, class => $class, uri => $class_link->href->abs( $uri ) });
}

sub fetch_class
{
    my $opts = shift( @_ );
    my $tag   = $opts->{tag} || die( "No tag name was provided.\n" );
    my $class = $opts->{class} || die( "No class name provided.\n" );
    $opts->{uri} //= "https://developer.mozilla.org/en-US/docs/Web/API/HTML${class}Element";
    my $url = $opts->{uri};

    my $cache_file = $cache_dir->child( "$class.html" );
    our $log = $cache_dir->child( 'mozilla_doc_log_${class}.txt' );
    my $json_file = $cache_dir->child( "$class.json" );
    
    my $mod_file = $mod_elements_base_dir->child( "${class}.pm" );
    
    $log->open( '>', { binmode => 'utf-8', autoflush => 1 } ) || die( $log->error );
    our $json = {};
    if( $json_file->exists )
    {
        my $json_data = $json_file->load_utf8;
        try
        {
            $json = $j->decode( $json_data );
            $json_file->close;
            local $crawl = sub
            {
                my $ref = shift( @_ );
                foreach my $this ( keys( %$ref ) )
                {
                    if( ref( $ref->{ $this } ) eq 'ARRAY' )
                    {
                        $ref->{ $this } = Module::Generic::Array->new( $ref->{ $this } );
                    }
                    elsif( ref( $ref->{ $this } ) eq 'HASH' )
                    {
                        $crawl->( $ref->{ $this } );
                    }
                }
            };
            $crawl->( $json );
        }
        catch( $e )
        {
            die( "An error occurred while trying to decode json: $e\n" );
        }
    }
    else
    {
        $json->{properties} = {};
        $json->{methods} = {};
        $json->{events} = {};
        $json->{handlers} = {};
    }
    
    &log( "Resource url for tag \"$tag\" class \"$class\" is: $url\n" );
    my $doc = &_check_cache_http({ uri => $url, file => $cache_file });

    my $art = $doc->look_down( _tag => 'article', class => 'main-page-content' )->first;
    die( "Unable to find the article tag with class 'main-page-content'\n" ) if( !$art );
    my $title = $art->getElementsByTagName( 'h1' )->first;
    my $desc_div = $title->nextElementSibling;
    die( "Unable to find a div containing the class description.\n" ) if( !ref( $desc_div ) );
    die( "Element found to contain the class description is not a div -> '", $desc_div->getName, "'\n" ) if( $desc_div->getName ne 'div' );
    my $desc_p = $desc_div->getElementsByTagName( 'p' )->first;
    die( "No paragraph containing the description could be found.\n" ) if( !ref( $desc_p ) );
    my $desc = $desc_p->as_trimmed_text;
    $desc =~ s/\bThe[[:blank:]\h]+HTML${class}Element[[:blank:]\h]+interface\b/This interface/g;
    $desc = _cleanup( $desc );
    
    my $props = {};
    my $prop_title = $art->getElementById( 'properties' );
    if( !$prop_title )
    {
        warn( "Warning only: unable to find the div with id 'properties'\n" );
    }
    else
    {
        # XXX
        # $prop_title->debug(4);
        my $prop_div = $prop_title->nextElementSibling;
        die( "Unable to get a next sibling to id 'properties'\n" ) if( !$prop_div );
        die( "Element found to contain properties is not a div: '", $prop_div->getName, "' (", overload::StrVal( $prop_div ), ")\n" ) if( $prop_div->getName ne 'div' );
        # This one contains a link whose text is the class name and property name separated by a dot.
        my $dts = $prop_div->getElementsByTagName( 'dt' );
        # This one contains soem paragraph and links, which we ignore and we get the overall as pure text to serve as property description.
        my $dds = $prop_div->getElementsByTagName( 'dd' );
        &logf( "%d properties found and %d definitions\n", $dts->length, $dds->length );
        die( "Number of properties does not match the total definitions found.\n" ) if( $dts->length != $dds->length );
        $dts->for(sub
        {
            my( $i, $elem ) = @_;
            my $firstElem = $elem->firstElementChild;
            my $link;
            my $def = {};
            my $prop;
            if( $firstElem->getName eq 'a' )
            {
                $link = $firstElem;
                $prop = $firstElem->as_trimmed_text;
            }
            # alternatively, there is a <code> enclosing the property name
            elsif( $firstElem->getName eq 'code' )
            {
                $prop = $firstElem->as_trimmed_text;
            }
            else
            {
                die( "Unknown first element for property in tag '", $firstElem->tag, "': ", $elem->as_string, "; I was expecting either <a> or <code>\n" );
            }
            ( my $html_class, $prop ) = split( /\./, $prop, 2 ) if( index( $prop, '.' ) != -1 );
            &logf( "%d. $prop\n", $i + 1 );
            if( exists( $json->{properties}->{ $prop } ) )
            {
                $props->{ $prop } = $json->{properties}->{ $prop };
                &log( "\tFound cache data in json for property \"$prop\".\n" );
                return(1);
            }
        
            if( defined( $link ) && $link->attr( 'class' ) ne 'page-not-created' )
            {
                $def->{link} = $link->getAttribute( 'href' );
                die( "No link found for property: ", $elem->as_string, "\n" ) if( !$def->{link} );
                my $uri = URI->new_abs( $def->{link}, MOZILLA_BASE_URL );
                $def->{link} = $uri;
                my $prop_cache_file = $cache_dir->child( "${class}_${prop}.html" );
                &log( "Fetching detail property \"$prop\" information from $uri\n" );
                my $codes = _get_detail_page_info( $uri => $prop_cache_file, { referrer => $url } );
                $def->{codes} = $codes;
            }
            else
            {
                my $u2 = $url->clone;
                $u2->path( $u2->path . "/$prop" );
                $def->{link} = $u2;
                $def->{no_link}++;
            }
            my $ro = $elem->look_down( _tag => 'span', class => qr/\breadonly\b/ );
            $def->{is_readonly} = ( $ro->length && lc( $ro->first->as_trimmed_text ) eq 'read only' ) ? 1 : 0;
            &log( "\tIs $prop read-only ? ", ( $def->{is_readonly} ? 'yes' : 'no' ), "\n" );
            $def->{property} = $prop;
            $def->{class} = $html_class;
            my $prop_desc = $dds->[$i]->as_trimmed_text;
            $prop_desc = join( "\n", split( /[[:blank:]\h]*\n[[:blank:]\h]*/, $prop_desc ) );
            $prop_desc =~ s/[[:blank:]\h]{2,}/ /gs;
            $prop_desc = _cleanup( $prop_desc );
            $def->{description} = $prop_desc;
            $props->{ $prop } = $def;
            $json->{properties} = $props;
            _save_to_json( $json => $json_file );
            return(1);
        });
    }
    
    my $methods = {};
    my $meth_title = $art->getElementById( 'methods' );
    if( !$meth_title )
    {
        warn( "Unable to find the div with id 'methods'\n" );
    }
    else
    {
        my $meth_div = $meth_title->nextElementSibling;
        die( "Unable to get a next sibling to id 'methods'\n" ) if( !$meth_div );
        die( "Element found to contain methods is not a div: '", $meth_div->getName, "' (", overload::StrVal( $meth_div ), ")\n" ) if( $meth_div->getName ne 'div' );
        $dts = $meth_div->getElementsByTagName( 'dt' );
        $dds = $meth_div->getElementsByTagName( 'dd' );
        &logf( "%d methods found and %d definitions\n", $dts->length, $dds->length );
        die( "Number of methods does not match the total definitions found.\n" ) if( $dts->length != $dds->length );
        $dts->for(sub
        {
            my( $i, $elem ) = @_;
            my $link = $elem->getElementsByTagName( 'a' )->first;
            die( "No link found for method in tag: ", $elem->as_string, "\n" ) if( !ref( $link ) );
            my $def = {};
            my $meth = $link->as_trimmed_text;
            ( my $html_class, $meth ) = split( /\./, $meth, 2 ) if( index( $meth, '.' ) != -1 );
            $meth =~ s/\(\)$//;
            &logf( "%d. $meth\n", $i + 1 );
            if( exists( $json->{methods}->{ $meth } ) )
            {
                $methods->{ $meth } = $json->{methods}->{ $meth };
                &log( "\tFound cache data in json for method \"$meth\".\n" );
                return(1);
            }
        
            if( $link->attr( 'class' ) ne 'page-not-created' )
            {
                $def->{link} = $link->getAttribute( 'href' );
                die( "No link found for method: ", $elem->as_string, "\n" ) if( !$def->{link} );
                my $uri = URI->new_abs( $def->{link}, MOZILLA_BASE_URL );
                $def->{link} = $uri;
                my $meth_cache_file = $cache_dir->child( "${class}_${meth}.html" );
                &log( "Fetching detail method \"$meth\" information from $uri\n" );
                my $codes = _get_detail_page_info( $uri => $meth_cache_file, { referrer => $url } );
                $def->{codes} = $codes;
            }
            else
            {
                my $u2 = $url->clone;
                $u2->path( $u2->path . "/$meth" );
                $def->{link} = $u2;
                $def->{no_link}++;
            }
            $def->{method} = $meth;
            $def->{class} = $html_class;
            my $meth_desc = $dds->[$i]->as_trimmed_text;
            $meth_desc = join( "\n", split( /[[:blank:]\h]*\n[[:blank:]\h]*/, $meth_desc ) );
            $meth_desc =~ s/[[:blank:]\h]{2,}/ /gs;
            $meth_desc = _cleanup( $meth_desc );
            $def->{description} = $meth_desc;
            $methods->{ $meth } = $def;
            $json->{methods} = $methods;
            _save_to_json( $json => $json_file );
            return(1);
        });
    }
    
    my $events = {};
    my $events_title = $art->getElementById( 'events' );
    if( !$events_title )
    {
        &log( "No events found.\n" );
    }
    else
    {
        my $events_div = $events_title->nextElementSibling;
        die( "Unable to get a next sibling to id 'events'\n" ) if( !$events_div );
        die( "Element found to contain events is not a div: '", $events_div->getName, "' (", overload::StrVal( $events_div ), ")\n" ) if( $events_div->getName ne 'div' );
        $dts = $events_div->getElementsByTagName( 'dt' );
        $dds = $events_div->getElementsByTagName( 'dd' );
        # Try searching for event subsections
        my $sub_events = $art->look_down( _tag => 'h3', id => qr/_events$/ );
        &logf( "Found %d event subsections.", $sub_events->length );
        foreach my $section ( @$sub_events )
        {
            my $sub_div = $section->nextElementSibling;
            if( !$sub_div )
            {
                warn( "Could not find a following div for this event sub section with id '", $section->id, "'\n" );
                &log( "** Could not find a following div for this event sub section with id '", $section->id. "\n" );
                next;
            }
            elsif( $sub_div->tag ne 'div' )
            {
                warn( "Following element found for this event sub section with id '", $section->id, "' is not a div.\n" );
                &log( "Following element found for this event sub section with id '", $section->id, "' is not a div.\n" );
                next;
            }
            my $sub_dts = $sub_div->getElementsByTagName( 'dt' );
            my $sub_dds = $sub_div->getElementsByTagName( 'dd' );
            if( $sub_dts->length != $sub_dds->length )
            {
                warn( "Total number of dt tags (", $sub_dts->length, ") does not match the total number of dd tags (", $sub_dds->length, ") for event sub section with id '", $section->id, "'.\n" );
                &log( "Total number of dt tags (", $sub_dts->length, ") does not match the total number of dd tags (", $sub_dds->length, ") for event sub section with id '", $section->id, "'.\n" );
                next;
            }
            $dts->push( $sub_dts->list );
            $dds->push( $sub_dds->list );
            &logf( "%d events added from sub section '%s'\n", $sub_dts->length, $section->id );
        }
        
        &logf( "%d events found and %d definitions\n", $dts->length, $dds->length );
        die( "Number of events does not match the total definitions found.\n" ) if( $dts->length != $dds->length );
        $dts->for(sub
        {
            my( $i, $elem ) = @_;
            my $link = $elem->getElementsByTagName( 'a' )->first;
            my $def = {};
            my $event;
            if( !ref( $link ) )
            {
                warn( "Warning only: no link found for event in tag: ", $elem->as_string, "\n" );
                my $firstElem = $elem->firstElementChild();
                $event = $firstElem->as_trimmed_text;
            }
            else
            {
                $event = $link->as_trimmed_text;
            }
            ( my $html_class, $event ) = split( /\./, $event, 2 ) if( index( $event, '.' ) != -1 );
            &logf( "%d. $event\n", $i + 1 );
            if( exists( $json->{events}->{ $event } ) )
            {
                $events->{ $event } = $json->{events}->{ $event };
                &log( "\tFound cache data in json for event \"$event\".\n" );
                return(1);
            }
        
            if( $link->attr( 'class' ) ne 'page-not-created' )
            {
                $def->{link} = $link->getAttribute( 'href' );
                die( "No link found for event: ", $elem->as_string, "\n" ) if( !$def->{link} );
                my $uri = URI->new_abs( $def->{link}, MOZILLA_BASE_URL );
                $def->{link} = $uri;
                my $event_cache_file = $cache_dir->child( "${class}_${event}.html" );
                &log( "Fetching detail event \"$event\" information from $uri\n" );
                my $codes = _get_detail_page_info( $uri => $event_cache_file, { referrer => $url } );
                $def->{codes} = $codes;
            }
            else
            {
                my $u2 = $url->clone;
                $u2->path( $u2->path . "/$event" );
                $def->{link} = $u2;
                $def->{no_link}++;
            }
            $def->{event} = $event;
            $def->{class} = $html_class;
            my $event_desc = $dds->[$i]->as_trimmed_text;
            $event_desc = join( "\n", split( /[[:blank:]\h]*\n[[:blank:]\h]*/, $event_desc ) );
            $event_desc =~ s/[[:blank:]\h]{2,}/ /gs;
            $event_desc = _cleanup( $event_desc );
            $def->{description} = $event_desc;
            $events->{ $event } = $def;
            &log( "\tDescription: $event_desc\n" );
            $json->{events} = $events;
            _save_to_json( $json => $json_file );
        });
    }
    
    my $handlers = {};
    my $handlers_title = $doc->getElementById( 'event_handlers' );
    if( !$handlers_title )
    {
        &log( "No event handlers found.\n" );
    }
    else
    {
        my $handlers_div = $handlers_title->nextElementSibling;
        die( "Unable to get a next sibling to id 'event_handlers'\n" ) if( !$handlers_div );
        die( "Element found to contain event handlers is not a div: '", $handlers_div->getName, "' (", overload::StrVal( $handlers_div ), ")\n" ) if( $handlers_div->getName ne 'div' );
        $dts = $handlers_div->getElementsByTagName( 'dt' );
        $dds = $handlers_div->getElementsByTagName( 'dd' );
        &logf( "%d event handlers found and %d definitions\n", $dts->length, $dds->length );
        die( "Number of event handlers does not match the total definitions found.\n" ) if( $dts->length != $dds->length );
        $dts->for(sub
        {
            my( $i, $elem ) = @_;
            my $firstElem = $elem->firstElementChild();
            my $link = $elem->getElementsByTagName( 'a' )->first;
            my $def = {};
            my $handler;
            if( !ref( $link ) )
            {
                warn( "Warning only: no link found for event handler in tag: ", $elem->as_string, "\n" );
                $handler = $firstElem->as_trimmed_text;
            }
            else
            {
                $handler = $link->as_trimmed_text;
            }
            ( my $html_class, $handler ) = split( /\./, $handler, 2 ) if( index( $handler, '.' ) != -1 );
            &logf( "%d. $handler\n", $i + 1 );
            if( exists( $json->{handlers}->{ $handler } ) )
            {
                $handlers->{ $handler } = $json->{handlers}->{ $handler };
                &log( "\tFound cache data in json for event handler \"$handler\".\n" );
                return(1);
            }
        
            if( defined( $link ) && $link->attr( 'class' ) ne 'page-not-created' )
            {
                $def->{link} = $link->getAttribute( 'href' );
                die( "No link found for event handler: ", $elem->as_string, "\n" ) if( !$def->{link} );
                my $uri = URI->new_abs( $def->{link}, MOZILLA_BASE_URL );
                $def->{link} = $uri;
                my $handler_cache_file = $cache_dir->child( "${class}_${handler}.html" );
                &log( "Fetching detail event handler \"$handler\" information from $uri\n" );
                my $codes = _get_detail_page_info( $uri => $handler_cache_file, { referrer => $url } );
                $def->{codes} = $codes;
            }
            else
            {
                my $u2 = $url->clone;
                $u2->path( $u2->path . "/$handler" );
                $def->{link} = $u2;
                $def->{no_link}++;
            }
            $def->{handler} = $handler;
            $def->{class} = $html_class;
            my $handler_desc = $dds->[$i]->as_trimmed_text;
            $handler_desc = join( "\n", split( /[[:blank:]\h]*\n[[:blank:]\h]*/, $handler_desc ) );
            $handler_desc =~ s/[[:blank:]\h]{2,}/ /gs;
            $handler_desc = _cleanup( $handler_desc );
            $def->{description} = $handler_desc;
            $handlers->{ $handler } = $def;
            &log( "\tDescription: $handler_desc\n" );
            $json->{handlers} = $handlers;
            _save_to_json( $json => $json_file );
        });
    }
    
    &logf( "Results: %d properties, %d methods, %d events and %d event handlers found.\n", scalar( keys( %$props ) ), scalar( keys( %$methods ) ), scalar( keys( %$events ) ), scalar( keys( %$handlers ) ) );
    my $subs = $p->new_array( [sort( keys( %$props ) )] );
    $subs = $subs->push( keys( %$methods ) )->unique(1)->sort;
    my $handlers2 = { %$handlers };
    if( scalar( keys( %$handlers ) ) || scalar( keys( %$events ) ) )
    {
        $subs->push( keys( %$handlers ) );
        foreach my $e ( sort( keys( %$events ) ) )
        {
            $subs->push( "on${e}" );
            unless( exists( $handlers2->{ "on${e}" } ) )
            {
                $handlers2->{ "on${e}" } = $events->{ $e };
            }
        }
        $subs = $subs->unique(1)->sort;
    }
    
    # Check if we have method to inherit
    my $has_inheritance = 0;
    foreach my $meth ( @$subs )
    {
        $has_inheritance++ if( HTML::Object::DOM::Element::Shared->can( $meth ) );
    }
    
    if( $mod_file->exists )
    {
        &log( "Creating backup for \"${mod_file}\" to \"${mod_file}.bak\".\n" );
        $mod_file->copy( "${mod_file}.bak" ) || die( $mod_file->error, "\n" );
    }
    
    &log( "Writing to module file \"${mod_file}\".\n" );
    $mod_file->open( '>', { binmode => 'utf-8', autoflush => 1 }) || die( $mod_file->error, "\n" );
    my $today = DateTime->now;
    my $ymd = $today->strftime( '%Y/%m/%d' );
    my $year = $today->year;
    my $rel_file = $mod_file->relative( $base_dir );
    $mod_file->print( <<EOT );
##----------------------------------------------------------------------------
## HTML Object - ~/${rel_file}
## Version v0.1.0
## Copyright(c) ${year} DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack\@deguest.jp>
## Created ${ymd}
## Modified ${ymd}
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::${class};
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
EOT
    if( $has_inheritance )
    {
        $mod_file->print( <<EOT );
    use HTML::Object::DOM::Element::Shared qw( :\L${class}\E );
EOT
    }
    $mod_file->print( <<EOT );
    our \$VERSION = 'v0.1.0';
};

sub init
{
    my \$self = shift( \@_ );
    \$self->{_init_strict_use_sub} = 1;
    \$self->SUPER::init( \@_ ) || return( \$self->pass_error );
    \$self->{tag} = '\L${class}\E' if( !CORE::length( "\$self->{tag}" ) );
    return( \$self );
}

EOT
    
    my @inherited = ();
    foreach my $meth ( @$subs )
    {
        if( exists( $props->{ $meth } ) )
        {
            my $def = $props->{ $meth };
            if( HTML::Object::DOM::Element::Shared->can( $meth ) )
            {
                $mod_file->print( "# Note: property $meth", ( $def->{is_readonly} ? ' read-only' : '' ), " is inherited\n\n" );
                push( @inherited, $meth );
            }
            else
            {
                $mod_file->print( "# Note: property $meth", ( $def->{is_readonly} ? ' read-only' : '' ), "\n" );
                $mod_file->print( "sub $meth : lvalue { return( shift->_set_get_property( '\L$meth\E', \@_ ) ); }\n\n" );
            }
        }
        elsif( exists( $handlers2->{ $meth } ) )
        {
            my $def = $handlers2->{ $meth };
            my $event = substr( $meth, 2 );
            $meth = lc( $meth );
            $mod_file->print( <<EOT );
sub $meth : lvalue { return( shift->on( '$event', \@_ ) ); }

EOT
        }
        else
        {
            my $def = $methods->{ $meth };
            if( HTML::Object::DOM::Element::Shared->can( $meth ) )
            {
                $mod_file->print( "# Note method $meth is inherited\n\n" );
                push( @inherited, $meth );
            }
            else
            {
                $mod_file->print( <<EOT );
sub $meth
{
    my \$self = shift( \@_ );
    return( \$self );
}

EOT
            }
        }
    }
    
    $mod_file->print( <<EOT );
1;
# XXX POD
\__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::${class} - HTML Object DOM ${class} Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::${class};
    my \$\L$class\E = HTML::Object::DOM::Element::${class}->new || 
        die( HTML::Object::DOM::Element::${class}->error, "\\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

$desc

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

EOT

    foreach my $prop ( sort( keys( %$props ) ) )
    {
        my $def = $props->{ $prop };
        $mod_file->print( "=head2 $prop\n\n" );
        if( $def->{is_readonly} )
        {
            $mod_file->print( "Read-only.\n\n" );
        }
        $mod_file->print( $def->{description}, "\n\n" ) if( $def->{description} );
        my $codes = $def->{codes};
        # print( "# \$codes is '$codes'\n" );
        if( $codes && !$codes->is_empty )
        {
            $mod_file->print( "Example:\n\n" );
            $codes->for(sub
            {
                my( $i, $ref ) = @_;
                my $formatted = "    " . join( "\n    ", split( /\n/, $ref->{perl} ) );
                # Remove empty space, because perl pod would produce warnings
                $formatted =~ s/\n[[:blank:]\h]+\n/\n\n/gs;
                $mod_file->print( $formatted, "\n\n" );
                if( $i > 0 && $i != $codes->size )
                {
                    $mod_file->print( "Another example:\n\n" );
                }
            });
        }
        if( $def->{link} )
        {
            $mod_file->printf( "See also L<Mozilla documentation|%s>\n\n", $def->{link} );
        }
    }
    
    $mod_file->print( "=head1 METHODS\n\n" );
    $mod_file->print( "Inherits methods from its parent L<HTML::Object::DOM::Element>\n\n" );
    foreach my $meth ( sort( keys( %$methods ) ) )
    {
        my $def = $methods->{ $meth };
        $mod_file->print( "=head2 $meth\n\n" );
        $mod_file->print( $def->{description}, "\n\n" ) if( $def->{description} );
        my $codes = $def->{codes};
        if( $codes && !$codes->is_empty )
        {
            $mod_file->print( "Example:\n\n" );
            $codes->for(sub
            {
                my( $i, $ref ) = @_;
                my $formatted = "    " . join( "\n    ", split( /\n/, $ref->{perl} ) );
                # Remove empty space, because perl pod would produce warnings
                $formatted =~ s/\n[[:blank:]\h]+\n/\n\n/gs;
                $mod_file->print( $formatted, "\n\n" );
                if( $i > 0 && $i != $codes->size )
                {
                    $mod_file->print( "Another example:\n\n" );
                }
            });
        }
        if( $def->{link} )
        {
            $mod_file->printf( "See also L<Mozilla documentation|%s>\n\n", $def->{link} );
        }
    }
    
    if( scalar( keys( %$events ) ) )
    {
        $mod_file->print( <<EOT );
=head1 EVENTS

Event listeners for those events can also be found by prepending C<on> before the event type:

C<click> event listeners can be set also with C<onclick> method:

    \$e->onclick(sub{ # do something });
    # or as an lvalue method
    \$e->onclick = sub{ # do something };

EOT
        foreach my $event ( sort( keys( %$events ) ) )
        {
            my $def = $events->{ $event };
            $mod_file->print( "=head2 $event\n\n" );
            $mod_file->print( $def->{description}, "\n\n" ) if( $def->{description} );
            my $codes = $def->{codes};
            if( $codes && !$codes->is_empty )
            {
                $mod_file->print( "Example:\n\n" );
                $codes->for(sub
                {
                    my( $i, $ref ) = @_;
                    my $formatted = "    " . join( "\n    ", split( /\n/, $ref->{perl} ) );
                    # Remove empty space, because perl pod would produce warnings
                    $formatted =~ s/\n[[:blank:]\h]+\n/\n\n/gs;
                    $mod_file->print( $formatted, "\n\n" );
                    if( $i > 0 && $i != $codes->size )
                    {
                        $mod_file->print( "Another example:\n\n" );
                    }
                });
            }
            if( $def->{link} )
            {
                $mod_file->printf( "See also L<Mozilla documentation|%s>\n\n", $def->{link} );
            }
        }
    }
    
    if( scalar( keys( %$handlers ) ) )
    {
        $mod_file->print( "=head1 EVENT HANDLERS\n\n" );
        foreach my $handler ( sort( keys( %$handlers ) ) )
        {
            my $def = $handlers->{ $handler };
            $mod_file->print( "=head2 $handler\n\n" );
            $mod_file->print( $def->{description}, "\n\n" ) if( $def->{description} );
            my $codes = $def->{codes};
            if( $codes && !$codes->is_empty )
            {
                $mod_file->print( "Example:\n\n" );
                $codes->for(sub
                {
                    my( $i, $ref ) = @_;
                    my $formatted = "    " . join( "\n    ", split( /\n/, $ref->{perl} ) );
                    # Remove empty space, because perl pod would produce warnings
                    $formatted =~ s/\n[[:blank:]\h]+\n/\n\n/gs;
                    $mod_file->print( $formatted, "\n\n" );
                    if( $i > 0 && $i != $codes->size )
                    {
                        $mod_file->print( "Another example:\n\n" );
                    }
                });
            }
            if( $def->{link} )
            {
                $mod_file->printf( "See also L<Mozilla documentation|%s>\n\n", $def->{link} );
            }
        }
    }
    $mod_file->print( <<EOT );
=head1 AUTHOR

Jacques Deguest E<lt>F<jack\@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozila documentation|${url}>, L<Mozilla documentation on \L${class}\E element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/\L${class}\E>

=head1 COPYRIGHT & LICENSE

Copyright(c) ${year} DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

EOT
    $log->close;
    if( scalar( @inherited ) && CORE::exists( $HTML::Object::DOM::Element::Shared::EXPORT_TAGS{ $tag } ) )
    {
        diag( "Found an existing entry in HTML::Object::DOM::Element::Shared EXPORT_TAGS for tag \"$tag\"." );
        if( "@inherited" eq join( ' ', @{$HTML::Object::DOM::Element::Shared::EXPORT_TAGS{ $tag }} ) )
        {
            diag( "\tBoth our version and the existing version in HTML::Object::DOM::Element::Shared are the same." );
        }
        else
        {
            diag( "\tOur methods are: '@inherited' and HTML::Object::DOM::Element::Shared's ones are: '", join( ' ', @{$HTML::Object::DOM::Element::Shared::EXPORT_TAGS{ $tag }} ), "'" );
        }
    }
    elsif( scalar( @inherited ) )
    {
        my $lines = $mod_shared->lines;
        diag( sprintf( "Parsing %d lines from \"$mod_shared\".", $lines->length ) );
        my $found_export = 0;
        my $last;
        my $ok = 0;
        my $len = $lines->length;
        my $spaces;
        if( length( $class ) < 8 )
        {
            $spaces = ( ' ' x ( 8 - length( $class ) ) );
        }
        else
        {
            $spaces = "    ";
        }
        my $new_line = "        \L${class}\E${spaces}=> [qw( @inherited )],\n";
        
        for( my $i = 0; $i < $len; $i++ )
        {
            if( $found_export )
            {
                if( $lines->[$i] =~ /^[[:blank:]]+\)\;/ )
                {
                    # Add the new line just before
                    diag( "Adding new line '$new_line' at line No ", ( $i + 1 ), " in file \"$mod_shared\"." );
                    $lines->splice( $i, 0, $new_line );
                    $ok++;
                    last;
                }
                
                if( $lines->[$i] =~ /^[[:blank:]\h]+([a-z]+)[[:blank:]\h]+\=\>[[:blank:]\h]+\[qw\(/ )
                {
                    my $def = { 'pos' => $i => tag => $1 };
                    my $rv = ( $tag cmp $def->{tag} );
                    if( $rv == 0 )
                    {
                        diag( "It seems tag \"$tag\" already exists in \"$mod_shared\"." );
                        last;
                    }
                    # This tag has an alphabetical value higher than our own
                    # We insert our line just before
                    elsif( $rv == -1 )
                    {
                        diag( "Adding new line '$new_line' at line No ", ( $i + 1 ), " in file \"$mod_shared\"." );
                        $lines->splice( $i, 0, $new_line );
                        $ok++;
                        last;
                    }
                }
            }
            
            if( $lines->[$i] =~ /^[[:blank:]\h]+our[[:blank:]\h]+\%EXPORT_TAGS/ )
            {
                $found_export++;
            }
        }
        
        if( $ok )
        {
            diag( "Backing up \"$mod_shared\" to \"${mod_shared}.bak\"." );
            $mod_shared->copy( "${mod_shared}.bak" );
            diag( "Writing to \"$mod_shared\"." );
            $mod_shared->open( '>', { binmode => 'utf-8', autoflush => 1 }) || die( $mod_shared->error );
            $mod_shared->print( $lines->list );
            $mod_shared->close;
            diag( sprintf( "Wrote %d lines to shared module \"$mod_shared\".", $lines->length ) );
        }
    }
    exit(0);
}

sub log
{
    CORE::print( @_ );
    $log->print( @_ );
}

sub logf
{
    CORE::printf( @_ );
    $log->printf( @_ );
}

sub _save_to_json
{
    my $data = shift( @_ );
    my $file = shift( @_ );
    try
    {
        my $json_data = $j->encode( $data );
        $file->unload_utf8( $json_data );
        $file->close;
    }
    catch( $e )
    {
        die( "An error occurred while trying to encode and save json data to file \"$file\": $e\n" );
    }
}

sub _get_detail_page_info
{
    my $link = shift( @_ );
    my $cache = shift( @_ );
    my $opts = shift( @_ );
    $opts->{referrer} //= '';
    my $html;
    if( $cache->exists )
    {
        &log( "\tRe-using cache for detail page: $cache\n" );
        $html = $cache->load_utf8;
    }
    else
    {
        &log( "\tNo cache yet, making a query to $link\n" );
        my $resp = $ua->get( $link, ( $opts->{referrer} ? ( 'Referer' => $opts->{referrer} ) : () ) );
        die( "Unable to get url \"$link\": ", $resp->status_line, "\n" ) if( !$resp->is_success );
        $html = $resp->decoded_content;
        $cache->unload_utf8( $html );
    }
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $html );
    my $art = $doc->look_down( _tag => 'article', class => 'main-page-content' )->first;
    die( "Unable to find the article section\n" ) if( !ref( $art ) );
    # XXX
    $art->debug(4);
    my $codes = $art->getElementsByClassName( 'code-example' );
    $art->debug(0);
    &logf( "%d code examples found for $link\n", $codes->length );
    my $ref = $p->new_array;
    $codes->foreach(sub
    {
        my $pre = $_->getElementsByTagName( 'pre' )->first;
        die( "Could not find the tag pre inside the code: ", $_->as_string, "\n" ) if( !ref( $pre ) );
        my $code = $pre->as_trimmed_text;
        die( "Code is empty!\n" ) if( !length( $code ) );
        my $vars = {};
        my $perl = HTML::Entities::decode_entities( $code );
        $perl =~ s{
            \b(?:var|let|const)\b[[:blank:]\h]+(\S+)
        }{
            $vars->{ $1 } = '$' . $1;
            "my \$$1";
        }gexs;
        # Save this so it does not get caught in JavaScript method regexp
        $perl =~ s/developer.mozilla.org/#DOMAIN#/gs;
        $perl =~ s/\bdocument\./\$doc\./gs;
        $perl =~ s/\b(console.log|alert)\(/say\(/gs;
        # Change arrays
        $perl =~ s/\b([[:alpha:]]+)\[([^\]]+)\]\.([[:alpha:]]+)\b/$1\-\>\[$2\]\-\>$3/gs;
        $perl =~ s/\b([[:alpha:]]+)\[([^\]]+)\]/$1\-\>\[$2\]/gs;
        1 while( $perl =~ s/([[:alpha:]]+)\.((?!mp3|mp4|png|jpg|jpeg|gif|html|pdf)\w+)/$1\-\>$2/gs );
        # getElementById( 'myid' ).elements
        $perl =~ s/\)\.([[:alpha:]]+)/\)\-\>$1/gs;
        # No such thing in perl as ===
        $perl =~ s/\={3}/==/gs;
        # Comments
        $perl =~ s,[[:blank:]\h]//, #,gs;
        # Start of line comments
        $perl =~ s,^//,#,gms;
        $perl =~ s/developer.mozilla.org/example.org/gs;
        # change spacing from 2 to 4:
        $perl =~ s/[[:blank:]\h]{2}/    /gs;
        $perl =~ s/\,[[:blank:]\h]+function\(\)/, sub/gs;
        $perl =~ s/for\([[:blank:]\h]*my[[:blank:]\h]+(\$\w+)[[:blank:]\h]*=[[:blank:]\h]*0\;[[:blank:]\h]*(\w+)[[:blank:]\h]*<[[:blank:]\h]*(.*?)\; (\w+)\+{2}[[:blank:]\h]*\)[[:blank:]\h]*\{/for\( my $1 = 0; \$$2 < $3; \$$4\+\+ ) {/gs;
        $perl =~ s{
            \b(?:(?<!\<)|(?<!\"))(?<!\$)(\w+)\b
        }{
            if( exists( $vars->{ $1 } ) )
            {
                $vars->{ $1 };
            }
            else
            {
                $1;
            }
        }gexs;
        $perl =~ s/\belse[[:blank:]\h]+if\b/elsif/gs;
        $perl =~ s/\bfunction[[:blank:]\h]+(\w+)/sub $1/gs;
        $perl =~ s/#DOMAIN#/example.org/gs;
        $ref->push({ original => $code, perl => $perl });
    });
    return( $ref );
}

sub _cleanup
{
    my $str = shift( @_ );
    my $map =
    {
    DOMTokenList    => 'HTML::Object::TokenList',
    HTMLCollection  => 'HTML::Object::DOM::Collection',
    VTTCue          => 'HTML::Object::DOM::VTTCue',
    };
    $str =~ s/\b(?:DOMString|USVString)\b/string/g;
    $str = HTML::Entities::decode_entities( $str );
    $str =~ s/\bHTMLElement\b/L<HTML::Object::DOM::Element>/gs;
    $str =~ s/\bnull\b/C\<undef\>/gs;
    $str =~ s{
        \bHTML((?>(?!Element).)+)Element\b
    }{
        my $class = $1;
        if( !exists( $MODULES_EXISTS->{ $class } ) )
        {
            my $f = $mod_elements_base_dir->child( "${class}.pm" );
            $MODULES_EXISTS->{ $class } = $f->exists ? 1 : 0;
        }
        
        if( $MODULES_EXISTS->{ $class } )
        {
            "L<HTML::Object::DOM::Element::${class}>";
        }
        else
        {
            "HTML${class}Element";
        }
    }gexs;
    $str =~ s{
        \b([A-Z][a-z]+[A-Z](?:\w+))\b
    }{
        if( exists( $map->{ $1 } ) )
        {
            'L<' . $map->{ $1 } . '>';
        }
        else
        {
            "C<$1>";
        }
    }gexs;
    # e.g.: <html> -> C<html>
    $str =~ s,(<[a-z]+>),C$1,gs;
    return( $str );
}

sub _set_datetime_formatter_for_http
{
    my $dt = shift( @_ );
    # HTTP Date format
    my $dt_fmt = DateTime::Format::Strptime->new(
        pattern => '%a, %d %b %Y %H:%M:%S GMT',
        locale => 'en_GB',
        time_zone => 'GMT',
    );
    $dt->set_formatter( $dt_fmt );
    return( $dt );
}

sub _check_cache_http
{
    my $opts = shift( @_ );
    my $uri  = $opts->{uri} || die( "No uri was provided.\n" );
    my $file = $opts->{file} || die( "No file was provided,\n" );
    my $headers = {};
    my $mtime;
    if( $file->exists )
    {
        $mtime = $file->mtime;
        &_set_datetime_formatter_for_http( $mtime );
        $headers->{ 'If-Modified-Since' } = "$mtime";
        diag( "Cache file \"$file\" exists. Setting http header If-Modified-Since to '$mtime'" );
    }
    else
    {
        diag( "No cache file \"$file\" yet." );
    }
    diag( "Making query to \"$uri\"." );
    my $resp = $ua->get( $uri, %$headers );
    my $last_mod = $resp->header( 'Last-Modified' );
    my $data = $resp->decoded_content( default_charset => 'utf-8', alt_charset => 'utf-8' );
    diag( sprintf( "Retrieved %d bytes of html data.", length( $data ) ) );
    my $parser = HTML::Object::DOM->new;
    diag( "Last-Modified header value found: '$last_mod'" );
    if( $last_mod )
    {
        $last_mod = $parser->new->_parse_timestamp( $last_mod )->set_time_zone( 'local' );
    }
    else
    {
        $last_mod = DateTime->now( time_zone => 'local' );
    }
    my $epoch = $last_mod->epoch;
    my $code = $resp->code;
    diag( "Returned code for \"$uri\" is '$code' and modification time is '$last_mod'" );
    my $doc;
    if( $code == 304 || 
        ( !$file->is_empty && defined( $mtime ) && $mtime == $epoch ) )
    {
        diag( "Remote html page at url \"$uri\" has not changed since last time on $mtime." );
        my $html = $file->load_utf8;
        $doc = $parser->parse_data( $html ) || die( $parser->error );
    }
    elsif( $code ne 200 )
    {
        die( "Failed to get to access \"$uri\". Server responded with code '$code': ", $resp->as_string, "\n" );
    }
    elsif( !length( $data ) )
    {
        die( "Remote server returned no data for url \"$uri\".\n" );
    }
    else
    {
        diag( "Saving ", length( $data ), " bytes of data to file \"$file\"." );
        $file->lock;
        $file->unload_utf8( $data ) || 
            die( "Unable to open html file \"$file\" in write mode: ", $file->error );
        $file->unlock;
        $file->utime( $epoch, $epoch );
        $doc = $parser->parse_data( $data ) || die( $parser->error );
    }
    return( $doc );
}

__END__

