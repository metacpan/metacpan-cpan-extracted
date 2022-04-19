##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object.pm
## Version v0.1.4
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/20
## Modified 2022/04/16
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use curry;
    use Devel::Confess;
    use Encode ();
    use Filter::Util::Call;
    use HTML::Object::Closing;
    use HTML::Object::Comment;
    use HTML::Object::Declaration;
    use HTML::Object::Document;
    use HTML::Object::Element;
    use HTML::Object::Space;
    use HTML::Object::Text;
    use HTML::Parser;
    use JSON;
    use Module::Generic::File qw( file );
    use Nice::Try;
    use Scalar::Util ();
    our $VERSION = 'v0.1.4';
    our $DICT = {};
    our $LINK_ELEMENTS = {};
    our $FATAL_ERROR = 0;
};

INIT
{
    my $me = file( __FILE__ );
    my $path = $me->parent;
    my $dict_json = 'html_tags_dict.json';
    my $tags_repo = $path->child( $dict_json );
    if( $tags_repo->exists )
    {
        try
        {
            my $json = $tags_repo->load_utf8 ||
                die( "Unable to open html tags json dictionary \"$tags_repo\": ", $tags_repo->error, "\n" );
            my $j = JSON->new->relaxed->utf8;
            my $hash = $j->decode( $json );
            die( "No html tags found inside dictionary file \"$tags_repo\"\n" ) if( !scalar( keys( %{$hash->{dict}} ) ) );
            $DICT = $hash->{dict};
            for( keys( %$DICT ) )
            {
                if( exists( $_->{link_in} ) )
                {
                    $LINK_ELEMENTS->{ $_ } = $_->{link_in};
                }
            }
        }
        catch( $e )
        {
            die( "Fatal error occurred while trying to load html tags json dictionary \"$tags_repo\": $e\n" );
        }
    }
    else
    {
        die( "Missing core file \"$dict_json\"\n" );
    }
};

sub import
{
    my $class = shift( @_ );
    my $hash = {};
    for( my $i = 0; $i < scalar( @_ ); $i++ )
    {
        if( $_[$i] eq 'debug' || 
            $_[$i] eq 'debug_code' || 
            $_[$i] eq 'debug_file' ||
            $_[$i] eq 'fatal_error' ||
            $_[$i] eq 'global_dom' ||
            $_[$i] eq 'try_catch' )
        {
            $hash->{ $_[$i] } = $_[$i+1];
            CORE::splice( @_, $i, 2 );
            $i--;
        }
    }
    local $Exporter::ExportLevel = 1;
    Exporter::import( $class, @_ );
    $hash->{debug} = 0 if( !CORE::exists( $hash->{debug} ) );
    $hash->{global_dom} = 0 if( !CORE::exists( $hash->{global_dom} ) );
    $hash->{debug_code} = 0 if( !CORE::exists( $hash->{debug_code} ) );
    $hash->{fatal_error} = 0 if( !CORE::exists( $hash->{fatal_error} ) );
    $hash->{try_catch} = 0 if( !CORE::exists( $hash->{try_catch} ) );
    if( $hash->{fatal_error} )
    {
        $FATAL_ERROR = 1;
    }
    
    if( $hash->{try_catch} )
    {
        # Nice::Try is among our dependency, so we can load it safely
        require Nice::Try;
        Nice::Try->export_to_level( 1, @_ );
    }
    
    if( $hash->{global_dom} )
    {
        Filter::Util::Call::filter_add( bless( $hash => ( ref( $class ) || $class ) ) );
        require HTML::Object::XQuery;
        HTML::Object::XQuery->export_to_level( 1, @_ );
        # Same as Firefox, Chrome or Safari do: default dom for blank page
        our $GLOBAL_DOM = __PACKAGE__->new( debug => $hash->{debug} )->parse( <<EOT );
<html><head></head><body></body></html>
EOT
    }
}

sub filter
{
    my( $self ) = @_ ;
    my( $status, $last_line );
    my $line = 0;
    my $code = '';
    if( !$self->{global_dom} )
    {
        Filter::Util::Call::filter_del();
        $status = 1;
        $self->message( 3, "Skipping filtering." );
        return( $status );
    }
    while( $status = Filter::Util::Call::filter_read() )
    {
        return( $status ) if( $status < 0 );
        $line++;
        if( /^__(?:DATA|END)__/ )
        {
            last;
        }
        
        s{
            (?<!\\)\$\(
        }
        {
            "xq("
        }gexs;
    }
    if( $self->{debug_file} )
    {
        if( open( my $fh, ">$self->{debug_file}" ) )
        {
            binmode( $fh, ':utf8' );
            print( $fh $_ );
            close( $fh );
        }
    }
    return( $line );
}

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $this->{_exception_class} = 'HTML::Object::Exception' unless( CORE::exists( $self->{_exception_class} ) );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $p = HTML::Parser->new(
        api_version => 3,
        start_h => [ $self->curry::add_start, 'self, tagname, attr, attrseq, text, column, line, offset, offset_end'],
        end_h   => [ $self->curry::add_end,   'self, tagname, attr, attrseq, text, column, line, offset, offset_end' ],
        marked_sections => 1,
        comment_h => [ $self->curry::add_comment, 'self, text, column, line, offset, offset_end'],
        declaration_h => [ $self->curry::add_declaration, 'self, text, column, line, offset, offset_end'],
        default_h => [ $self->curry::add_default, 'self, tagname, attr, attrseq, text, column, line, offset, offset_end'],
        text_h => [ $self->curry::add_text, 'self, text, column, line, offset, offset_end'],
        # This is not activated, because as per the documentation, this will call an 'end tag' caller, and this could imply <br></br> for other unknown tags, whereas with <br /> we know for sure this is an empty tag
        # empty_element_tags => 1,
        unbroken_text => 1,
    );
    $self->{document} = '';
    $self->{current_parent} = '';
    $self->{_parser} = $p;
    $self->{_elems}  = [];
    return( $self );
}

sub add_comment
{
    my $self = shift( @_ );
    my @args = @_;
    my $opts = {};
    my @p = qw( p raw col line offset offset_end );
    @$opts{ @p } = @args;
    my $parent = $self->current_parent;
    $self->message( 4, "Adding comment: '$opts->{raw}' at line $opts->{line} and column $opts->{col} with parent '$parent'" );
    my $val = $opts->{raw};
    $val =~ s,^\<\!\-\-|\-\-\>$,,gs;
    my $e = $self->new_comment({
        column   => $opts->{col},
        line     => $opts->{line},
        offset   => $opts->{offset},
        original => $opts->{raw},
        parent   => $parent,
        value    => $val,
        debug    => $self->debug,
    }) || return;
    $parent->children->push( $e );
    return( $e );
}

sub add_declaration
{
    my $self = shift( @_ );
    my @args = @_;
    my $opts = {};
    my @p = qw( p raw col line offset offset_end );
    @$opts{ @p } = @args;
    $self->message( 4, "Adding declaration: '$opts->{raw}' at line $opts->{line} and column $opts->{col}" );
    my $parent = $self->current_parent;
    return if( !$self->_is_a( $parent => 'HTML::Object::DOM::Document' ) );
    my $e = $self->new_declaration({
        column   => $opts->{col},
        line     => $opts->{line},
        offset   => $opts->{offset},
        original => $opts->{raw},
        parent   => $parent,
        debug    => $self->debug,
    });
    # $parent->children->push( $e );
    $self->document->declaration( $e );
    $parent->children->push( $e );
    return( $e );
}

sub add_default
{
    my $self = shift( @_ );
    my @args = @_;
    my $opts = {};
    my @p = qw( p tag attr seq raw col line offset offset_end );
    @$opts{ @p } = @args;
    $self->message( 4, "Received arguments: ", sub{ $self->SUPER::dump( \@args ) });
    $self->message( 3, "Processing tag '", ( $opts->{tag} // '' ), "': '", ( $opts->{raw} // '' ), "' at line ", ( $opts->{line} // '' ), " and column ", ( $opts->{col} // '' ) );
    return if( !CORE::length( $opts->{raw} ) && !defined( $opts->{tag} ) );
    # Unknown tag, so we check if there is a "/>" to determine if this is an empty (void) tag or not
    my $attr = $opts->{attr};
    my $def = {};
    $def->{is_empty} = exists( $attr->{'/'} ) ? 1 : 0;
    my $parent = $self->current_parent;
    if( !length( $opts->{tag} ) )
    {
        return( $self->add_text( @args ) );
    }
    # Check the current parent and see if we need to close it.
    # If this new tag is a non-empty tag (i.e. non-void) and the current parent has not been closed, 
    # implicitly close it now, by setting that tag's parent as the current parent
    # This is what Mozilla does:
    # Ref: <https://bugzilla.mozilla.org/show_bug.cgi?id=820926>
    # XXX This needs to be done in post processing not during initial parsing, because at this point in the process we have not yet seen the closing tag, and we might see it later, so making guesses here is ill-advised.
#     if( !$parent->is_closed && 
#         !$def->{is_empty} && 
#         $parent && 
#         !$parent->isa( 'HTML::Object::Document' ) &&
#         $parent->tag ne 'html' )
#     {
#         $self->message( 3, "Implicitly closing current parent tag \"", $parent->tag, "\": ", $parent->original );
#         $parent = $parent->parent;
#     }
    my $e = $self->new_element({
        attributes => $opts->{attr},
        attributes_sequence => $opts->{seq},
        column   => $opts->{col},
        is_empty => $def->{is_empty},
        line     => $opts->{line},
        offset   => $opts->{offset},
        original => $opts->{raw},
        parent   => $parent,
        tag      => $opts->{tag},
        debug    => $self->debug,
    }) || return;
    $parent->children->push( $e );
    if( !$def->{is_empty} )
    {
        $self->message( 4, "Setting current tag \"", $e->tag, "\" as current parent from now on." );
        $self->current_parent( $e );
    }
    return( $e );
}

sub add_end
{
    my $self = shift( @_ );
    my @args = @_;
    my $opts = {};
    my @p = qw( p tag attr seq raw col line offset offset_end );
    @$opts{ @p } = @args;
    $self->message( 4, "Adding closing tag for tag '$opts->{tag}': '$opts->{raw}' at line $opts->{line} and column $opts->{col}" );
    my $me = $self->current_parent;
    my $parent = $me->parent;
    if( $opts->{tag} ne $me->tag )
    {
        warnings::warn( "Oops, something is wrong in the parsing. I was expecting a closing tag for \"", $me->tag, "\" that started at line \"", $me->line, "\" but instead found a closing tag for \"$opts->{tag}\" at line \"$opts->{line}\" and column \"$opts->{col}\": $opts->{raw}\n" ) if( warnings::enabled() );
    }
    else
    {
        my $e = $self->new_closing({
            attributes => $opts->{attr},
            attributes_sequence => $opts->{seq},
            column   => $opts->{col},
            line     => $opts->{line},
            offset   => $opts->{offset},
            original => $opts->{raw},
            tag      => $opts->{tag},
            debug    => $self->debug,
        }) || return;
        $me->is_closed(1);
        $me->close_tag( $e );
        # $parent->children->push( $e );
        $self->current_parent( $parent );
        $self->message( 4, "Parent is set back to '$parent' (", $parent->tag, ")" );
    }
}

sub add_space
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $parent = $self->current_parent;
    $self->message( 4, "Adding space '$opts->{original}' at line $opts->{line} and column $opts->{column} with parent '$parent'" );
    my $e = $self->new_space( $opts ) || return;
    $parent->children->push( $e );
    return( $e );
}

sub add_start
{
    my $self = shift( @_ );
    my @args = @_;
    my $opts = {};
    my @p = qw( p tag attr seq raw col line offset offset_end );
    @$opts{ @p } = @args;
    my $parent = $self->current_parent;
    if( $opts->{tag} =~ s,/,, )
    {
        $opts->{attr}->{'/'} = '/';
    }
    $self->message( 4, "Adding opening tag for '$opts->{tag}': '$opts->{raw}' at line $opts->{line} and column $opts->{col} with parent '$parent' and attributes -> ", sub{ $self->dump( $opts->{attr} ) } );
    my $def = $self->get_definition( $opts->{tag} );
    $self->message( 4, "Found dictionary definition for tag '$opts->{tag}: ", sub{ $self->SUPER::dump( $def )} );
    # Make some easy guess
    if( !scalar( keys( %$def ) ) )
    {
        $def->{is_empty} = 1 if( CORE::exists( $opts->{attr}->{'/'} ) );
        # "Return HTMLUnknownElement"
        # <https://html.spec.whatwg.org/multipage/dom.html#htmlunknownelement>
        $def->{class} = 'HTML::Object::DOM::Unknown';
    }
    $def->{is_empty} = 0 unless( CORE::exists( $def->{is_empty} ) );
    # Check the current parent and see if we need to close it.
    # If this new tag is a non-empty tag (i.e. non-void) and the current parent has not been closed, 
    # implicitly close it now, by setting that tag's parent as the current parent
    # This is what Mozilla does:
    # Ref: <https://bugzilla.mozilla.org/show_bug.cgi?id=820926>
    # XXX This needs to be done in post processing not during initial parsing, because at this point in the process we have not yet seen the closing tag, and we might see it later, so making guesses here is ill-advised.
#     if( !$parent->is_closed && 
#         !$def->{is_empty} && 
#         $parent && 
#         !$parent->isa( 'HTML::Object::Document' ) &&
#         $parent->tag ne 'html' )
#     {
#         $self->message( 3, "Implicitly closing current parent tag \"", $parent->tag, "\": ", $parent->original );
#         $parent = $parent->parent;
#     }
    $self->message( 4, "Adding new element for tag '$opts->{tag}' with is_empty? ", $def->{is_empty} ? 'yes' : 'no' );
    $def->{class} //= '';
    my $e;
    my $params = 
    {
    attributes => $opts->{attr},
    attributes_sequence => $opts->{seq},
    column   => $opts->{col},
    is_empty => $def->{is_empty},
    line     => $opts->{line},
    offset   => $opts->{offset},
    original => $opts->{raw},
    parent   => $parent,
    tag      => $opts->{tag},
    # and
    debug    => $self->debug,
    };
    
    # If this tag is handled by a special class, instantiate the object by this class
    if( $def->{class} )
    {
        $e = $self->new_special( $def->{class} => $params ) || return;
    }
    else
    {
        $e = $self->new_element( $params ) || return;
    }
    $self->message( 5, "Pushing new element to parent's children stack." );
    $parent->children->push( $e );
    # If this element is an element that, by nature, can contain other elements we mark it as the last element seen so it can be used as a parent. When we close it, we switch the parent to its parent .
    if( !$def->{is_empty} )
    {
        $self->message( 4, "Setting current tag \"", $e->tag, "\" as current parent from now on." );
        $self->current_parent( $e );
    }
    return( $e );
}

sub add_text
{
    my $self = shift( @_ );
    my @args = @_;
    my $opts = {};
    my @p = qw( p raw col line offset offset_end );
    @$opts{ @p } = @args;
    $self->message( 4, "Called with raw '\Q$opts->{raw}\E' at line $opts->{line} with parent '", $self->current_parent, "'" );
    my $parent = $self->current_parent ||
        return( $self->error( "You must create a document first using the new_document() method first before adding text." ) );
    my $e;
    # Text can be either some space or letters, digits (non-space characters)
    # HTML::Parser does not make the difference, but we do
    if( $opts->{raw} =~ /^[[:blank:]\h\v]*$/ )
    {
        $self->message( 4, "Adding space element with parent '$parent'." );
        $e = $self->add_space(
            original => $opts->{raw},
            column   => $opts->{col},
            line     => $opts->{line},
            offset   => $opts->{offset},
            parent   => $parent,
            value    => $opts->{raw},
            debug    => $self->debug,
            # No 'value' set on purpose, because if none, then 'original' will be used by
            # as_string
        ) || return;
    }
    else
    {
        $self->message( 4, "Adding text: '$opts->{raw}' at line $opts->{line} and column $opts->{col}" );
        $e = $self->new_text({
            column   => $opts->{col},
            line     => $opts->{line},
            offset   => $opts->{offset},
            original => $opts->{raw},
            parent   => $parent,
            value    => $opts->{raw},
            debug    => $self->debug,
        }) || return;
        $parent->children->push( $e );
    }
    return( $e );
}

sub current_parent { return( shift->_set_get_object_without_init( 'current_parent', 'HTML::Object::Element', @_ ) ); }

sub dictionary { return( $DICT ); }

sub document { return( shift->_set_get_object( 'document', 'HTML::Object::Document', @_ ) ); }

sub get_definition
{
    my $self = shift( @_ );
    my $tag  = shift( @_ );
    return( $self->error( "No tag was provided to get its definition." ) ) if( !length( $tag ) );
    # Just to be sure
    $tag = lc( $tag );
    return( {} ) if( !exists( $DICT->{ $tag } ) );
    return( $DICT->{ $tag } );
}

sub new_closing
{
    my $self = shift( @_ );
    my $e = HTML::Object::Closing->new( @_ ) ||
        return( $self->pass_error( HTML::Object::Closing->error ) );
    return( $e );
}

sub new_comment
{
    my $self = shift( @_ );
    my $e = HTML::Object::Comment->new( @_ ) ||
        return( $self->pass_error( HTML::Object::Comment->error ) );
    return( $e );
}

sub new_declaration
{
    my $self = shift( @_ );
    my $e = HTML::Object::Declaration->new( @_ ) ||
        return( $self->pass_error( HTML::Object::Declaration->error ) );
    return( $e );
}

sub new_document
{
    my $self = shift( @_ );
    my $e = HTML::Object::Document->new( @_ ) ||
        return( $self->pass_error( HTML::Object::Document->error ) );
    return( $e );
}

sub new_element
{
    my $self = shift( @_ );
    my $e = HTML::Object::Element->new( @_ ) ||
        return( $self->pass_error( HTML::Object::Element->error ) );
    return( $e );
}

sub new_space
{
    my $self = shift( @_ );
    my $e = HTML::Object::Space->new( @_ ) ||
        return( $self->pass_error( HTML::Object::Space->error ) );
    return( $e );
}

sub new_special
{
    my $self = shift( @_ );
    my $class = shift( @_ );
    $self->_load_class( $class ) || return( $self->pass_error );
    my $e = $class->new( @_ ) || return( $self->pass_error( $class->error ) );
    return( $e );
}

sub new_text
{
    my $self = shift( @_ );
    my $e = HTML::Object::Text->new( @_ ) ||
        return( $self->pass_error( HTML::Object::Text->error ) );
    return( $e );
}

sub parse
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( ref( $this ) eq 'CODE' || ref( $this ) eq 'GLOB' || "$this" =~ /<\w+/ || CORE::length( "$this" ) > 1024 )
    {
        return( $self->parse_data( $this, $opts ) );
    }
    elsif( ref( $this ) )
    {
        return( $self->error( "I was provided a reference (", overload::StrVal( $this ), ") to parse html data, but I do not know what to do with it." ) );
    }
    else
    {
        return( $self->parse_file( $this, $opts ) );
    }
}

sub parse_data
{
    my $self = shift( @_ );
    my $html = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    try
    {
        if( $opts->{utf8} )
        {
            $html = Encode::decode( 'utf8', $html, Encode::FB_CROAK );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error found while utf8 decoding ", length( $html ), " bytes of html data provided." ) );
    }
    
    my $e;
    if( length( $self->{current_parent} ) && $self->_is_object( $self->{current_parent} ) )
    {
        $e = $self->current_parent;
    }
    else
    {
        $e = $self->new_document( debug => $self->debug );
        $self->document( $e );
        $self->current_parent( $e );
        if( $self->isa( 'HTML::Object::DOM' ) )
        {
            if( my $code = $self->onload )
            {
                $e->onload( $code );
            }
            if( my $code = $self->onreadystatechange )
            {
                $e->onreadystatechange( $code );
            }
        }
    }
    $self->message( 4, "Setting current parent to '$e'" );
    my $doc = $self->document;
    my $p = $self->parser;
    $self->_set_state( 'loading' => $doc );
    $p->parse( $html );
    $self->_set_state( 'interactive' => $doc );
    $self->post_process( $e );
    $self->_set_state( 'complete' => $doc );
    $p->eof;
    return( $e );
}

sub parse_file
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file to parse was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $f = $self->new_file( $file );
    if( !$f->exists )
    {
        return( $self->error( "File to parse \"$file\" does not exist." ) );
    }
    elsif( $f->is_empty )
    {
        return( $self->error( "File to parse \"$file\" is empty." ) );
    }
    my $params = {};
    $params->{binmode} = 'utf8' if( $opts->{utf8} );
    my $io = $f->open( '<', $params ) ||
        return( $self->error( "Unable to open file to parse \"$file\": ", $f->error ) );
    my $e = $self->new_document( _last_modified => $f->mtime );
    $self->document( $e );
    if( $self->isa( 'HTML::Object::DOM' ) )
    {
        if( my $code = $self->onload )
        {
            $e->onload( $code );
        }
        if( my $code = $self->onreadystatechange )
        {
            $e->onreadystatechange( $code );
        }
    }
    $self->current_parent( $e );
    $self->_set_state( 'loading' => $e );
    my $p = $self->parser;
    $p->parse_file( $io );
    $io->close;
    $self->_set_state( 'interactive' => $e );
    $self->post_process( $e );
    $self->_set_state( 'complete' => $e );
    return( $e );
}

sub parse_url
{
    my $self = shift( @_ );
    my $uri;
    if( ( scalar( @_ ) == 1 && ref( $_[0] ) ne 'HASH' ) ||
        ( scalar( @_ ) > 1 && 
          ( 
            ( @_ % 2 ) || 
            ( scalar( @_ ) == 2 && ref( $_[1] ) eq 'HASH' )
          )
        ) )
    {
        $uri = shift( @_ );
    }
    my $opts = $self->_get_args_as_hash( @_ );
    $uri = CORE::delete( $opts->{uri} ) if( defined( $opts->{uri} ) && CORE::length( $opts->{uri} ) );
    if( !$self->_load_class( 'LWP::UserAgent', { version => '6.49' } ) )
    {
        return( $self->error( "LWP::UserAgent version 6.49 or higher is required to use load()" ) );
    }
    if( !$self->_load_class( 'URI', { version => '1.74' } ) )
    {
        return( $self->error( "URI version 1.74 or higher is required to use load()" ) );
    }
    $opts->{timeout} //= 10;
    try
    {
        $uri = URI->new( "$uri" );
    }
    catch( $e )
    {
        return( $self->error( "Bad url provided \"$uri\": $e" ) );
    }
    
    my $content;
    try
    {
        my $ua = LWP::UserAgent->new(
            agent   => "HTML::Object/$VERSION",
            timeout => $opts->{timeout},
        );
        $self->message( 4, "Making a GET query to uri '$uri'" );
        my $resp = $ua->get( $uri, ( CORE::exists( $opts->{headers} ) && defined( $opts->{headers} ) && ref( $opts->{headers} ) eq 'HASH' && scalar( keys( %{$opts->{headers}} ) ) ) ? %{$opts->{headers}} : () );
        $self->message( 4, "http query yields returned code '", $resp->code, "' with message '", $resp->message, "'" );
        if( $resp->header( 'Client-Warning' ) || !$resp->is_success )
        {
            return( $self->error({
                code => $resp->code,
                message => $resp->message,
            }) );
        }
        $content = $resp->decoded_content;
        $self->response( $resp );
    }
    catch( $e )
    {
        return( $self->error( "Error making a GET request to $uri: $e" ) );
    }
    my $doc = $self->parse_data( $content );
    $doc->uri( $uri );
    return( $doc );
}

sub parser { return( shift->_set_get_object_without_init( '_parser', 'HTML::Parser', @_ ) ); }

sub post_process
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    return if( !$self->_is_object( $elem ) );
    return if( !$elem->isa( 'HTML::Object::Element' ) );
    # Crawl through the tree and look for unclosed tags
    $elem->children->foreach(sub
    {
        my $e = shift( @_ );
        return(1) if( $e->isa( 'HTML::Object::Closing' ) || $e->tag->substr( 0, 1 ) eq '_' );
        if( $e->is_empty && $e->children->length )
        {
            $self->messagef( 3, "Tag \"%s\" should be empty (void), but it has %d children.", $e->tag, $e->children->length );
        }
        elsif( $e->is_empty && !$e->attributes->exists( '/' ) )
        {
            $self->messagef( 3, "Tag \"%s\" at line %d at row %d is an empty (void) tag, but it did not end with />", $e->tag, $e->line, $e->column );
        }
        elsif( !$e->is_empty && !$e->is_closed )
        {
            my $def = $self->get_definition( $e->tag );
            if( !$def->{is_empty} )
            {
                $self->messagef( 3, "Tag \"%s\" at line %d at row %d is an enclosing tag, but it has not been closed.", $e->tag, $e->line, $e->column );
            }
            else
            {
                $self->messagef( 3, "Tag \"%s\" at line %d at row %d is an empty (void) tag, but it did not end with />", $e->tag, $e->line, $e->column );
            }
        }
        $self->post_process( $e ) if( !$e->is_empty );
    });
    return( $self );
}

sub response { return( shift->_set_get_object_without_init( 'response', 'HTTP::Response', @_ ) ); }

sub sanity_check
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    return if( !$self->_is_object( $elem ) );
    return if( !$elem->isa( 'HTML::Object::Element' ) );
    # Crawl through the tree and look for unclosed tags
    $elem->children->foreach(sub
    {
        my $e = shift( @_ );
        return(1) if( $e->isa( 'HTML::Object::Closing' ) || $e->tag->substr( 0, 1 ) eq '_' );
        if( $e->is_empty && $e->children->length )
        {
            printf( STDOUT "Tag \"%s\" should be empty (void), but it has %d children.\n", $e->tag, $e->children->length );
        }
        elsif( $e->is_empty && !$e->attributes->exists( '/' ) )
        {
            printf( STDOUT "Tag \"%s\" at line %d at row %d is an empty (void) tag, but it did not end with />\n", $e->tag, $e->line, $e->column );
        }
        elsif( !$e->is_empty && $e->attributes->exists( '/' ) )
        {
            printf( STDOUT "Tag \"%s\" at line %d at row %d is marked as non-empty (non-void), but it ends with />\n", $e->tag, $e->line, $e->column );
        }
        elsif( !$e->is_empty && !$e->is_closed )
        {
            my $def = $self->get_definition( $e->tag );
            if( !$def->{is_empty} )
            {
                printf( STDOUT "Tag \"%s\" at line %d at row %d is an enclosing tag, but it has not been closed.\n", $e->tag, $e->line, $e->column );
            }
            else
            {
                printf( STDOUT "Tag \"%s\" at line %d at row %d is an empty (void) tag, but it did not end with />\n", $e->tag, $e->line, $e->column );
            }
        }
        $self->sanity_check( $e ) if( !$e->is_empty );
    });
    return( $self );
}

sub set_dom
{
    my( $this, $html ) = @_;
    if( defined( $html ) )
    {
        if( Scalar::Util::blessed( $html ) && $html->isa( 'HTML::Object::Document' ) )
        {
            $GLOBAL_DOM = $html;
        }
        elsif( CORE::length( $html ) )
        {
            $GLOBAL_DOM = $this->new->parse( $html );
        }
    }
    return( $this );
}

sub _set_state
{
    my $self = shift( @_ );
    my( $state, $elem ) = @_;
    # This feature is only applicable for HTML::Object::DOM
    return( $self ) unless( $self->isa( 'HTML::Object::DOM' ) );
    # ... and only for documents
    return if( !defined( $elem ) || !$self->_is_a( $elem => 'HTML::Object::DOM::Document' ) );
    $elem->readyState( $state );
    require HTML::Object::Event;
    my $event = HTML::Object::Event->new( 'readystate',
        bubbles     => 0,
        cancelable  => 0,
        detail      => { 'state' => $state, document => $elem },
        target      => $elem,
    );
    # $elem->dispatchEvent( $event );
    if( my $eh = $elem->onreadystatechange )
    {
        local $_ = $elem;
        my $code = $eh->code;
        warn( "Value for event handler '$code' is not a code reference.\n" ) if( ref( $code ) ne 'CODE' );
        $code->( $event ) if( ref( $code ) eq 'CODE' );
    }
    if( $state eq 'complete' && ( my $code = $elem->onload ) )
    {
        local $_ = $elem;
        $code->( $event );
    }
    return( $self );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object - HTML Parser, Modifier and Query Interface

=head1 SYNOPSIS

    use HTML::Object;
    my $p = HTML::Object->new( debug => 5 );
    my $doc = $p->parse( $file, { utf8 => 1 } ) || die( $p->error, "\n" );
    print $doc->as_string;

or, using the HTML DOM implementation same as the Web API:

    use HTML::Object::DOM global_dom => 1;
    # then you can also use HTML::Object::XQuery for jQuery like DOM manipulation
    my $p = HTML::Object::DOM->new;
    my $doc = $p->parse_data( $some_html ) || die( $p->error, "\n" );
    $('div.inner')->after( "<p>Test</p>" );
    
    # returns an HTML::Object::DOM::Collection
    my $divs = $doc->getElementsByTagName( 'div' );
    my $new = $doc->createElement( 'div' );
    $new->setAttribute( id => 'newDiv' );
    $divs->[0]->parent->replaceChild( $new, $divs->[0] );
    # etc.

To enable fatal error and also implement try-catch (using L<Nice::Try>) :

    use HTML::Object fatal_error => 1, try_catch => 1;

=head1 VERSION

    v0.1.4

=head1 DESCRIPTION

This module is yet another HTML parser, manipulation and query interface. It uses the C parser from L<HTML::Parser> and has the unique particularity that it does not try to decode the entire html document tree only to re-encode it when printing out its data as string like so many other html parsers out there do. Instead, it modifies only the parts required. The rest is returned exactly as it was found in the HTML. This is faster and safer.

It uses an external json data dictionary file of html tags (C<html_tags_dict.json>).

There are 3 ways to manipulate and query the html data:

=over 4

=item 1. L<HTML::Object::Element>

This is lightweight and simple

=item 2. L<HTML::Object::DOM>

This is an alternative HTML parser also based on L<HTML::Parser>, and that implements fully the Web API with DOM (Data Object Model), so you can query the HTML with perl equivalent to JavaScript methods of the Web API. It has been designed to be strictly identical to the Web API.

=item 3. L<HTML::Object::XQuery>

This interface provides a jQuery like API and requires the use of L<HTML::Object::DOM>. However, this is not designed to be a perl implementation of JavaScript, but rather a perl implementation of DOM manipulation methods found in jQuery.

=back

Note that this interface does not enforce HTML standard. It is up to you the developer to decide what value to use and where the HTML elements should go in the HTML tree and what to do with it.

=head1 METHODS

=head2 new

Instantiate a new L<HTML::Object> object.

=head2 add_comment

This is a parser method called that will add a comment to the stack of html elements.

=head2 add_declaration

This is a parser method called that will add a declaration to the stack of html elements.

=head2 add_default

This is a parser method called that will add a default html tag to the stack of html elements.

=head2 add_end

This is a parser method called that will add a closing html tag to the stack of html elements.

=head2 add_space

This is a parser method called that will add a space to the stack of html elements.

=head2 add_start

This is a parser method called that will add a starting html tag to the stack of html elements.

=head2 add_text

This is a parser method called that will add a text to the stack of html elements.

=head2 current_parent

Sets or gets the current parent, which must be an L<HTML::Object::Element> object or an inheriting class.

=head2 dictionary

Returns an hash reference containing the HTML tags dictionary. Its structure is:

=over 4

=item * dict

This property reflects an hash containing all the known tags. Each tag has the following possible properties:

=over 8

=item * description

String

=item * is_deprecated

Boolean value

=item * is_empty

Boolean value

=item * is_inline

Boolean value

=item * is_svg

Boolean value that describes whether this is a tag dedicated to svg.

=item * link_in

Array reference of HTML attributes containing links

=item * ref

The reference URL to the online web documentation for this tag.

=back

=item * meta

This property holds an hash reference containing the following meta information:

=over 8

=item * author

String

=item * updated

ISO 8601 datetime

=item * version

Version number

=back

=back

=head2 document

Sets or gets the document L<HTML::Object::Document> object.

=head2 get_definition

Get the hash definition for a given tag (case does not matter).

The tags definition is taken from the external file C<html_tags_dict.json> that is provided with this package.

=head2 new_closing

Creates and returns a new closing html element L<HTML::Object::Closing>, passing it any arguments provided.

=head2 new_comment

Creates and returns a new closing html element L<HTML::Object::Comment>, passing it any arguments provided.

=head2 new_declaration

Creates and returns a new closing html element L<HTML::Object::Declaration>, passing it any arguments provided.

=head2 new_document

Creates and returns a new closing html element L<HTML::Object::Document>, passing it any arguments provided.

=head2 new_element

Creates and returns a new closing html element L<HTML::Object::Element>, passing it any arguments provided.

=head2 new_space

Creates and returns a new closing html element L<HTML::Object::Space>, passing it any arguments provided.

=head2 new_special

Provided with an HTML tag class name and hash or hash reference of options and this will load that class and instantiate an object passing it the options provided. It returns the object thus Instantiated.

This is used to instantiate object for special class to handle certain HTML tag, such as C<a>

=head2 new_text

Creates and returns a new closing html element L<HTML::Object::Text>, passing it any arguments provided.

=head2 parse

Provided with some C<data> (see below), and some options as hash or hash reference and this will parse it and return a new L<HTML::Object::Document> object.

Possible accepted data are:

=over 4

=item I<code>

L</parse_data> will be called with it.

=item I<glob>

L</parse_data> will be called with it.

=item I<string>

L</parse_file> will be called with it.

=back

Other reference will return an error.

=head2 parse_data

Provided with some C<data> and some options as hash or hash reference and this will parse the given data and return a L<HTML::Object::Document> object.

If the option I<utf8> is provided, the C<data> received will be converted to utf8 using L<Encode/decode>. If an error occurs decoding the data into utf8, the error will be set as an L<Module::Generic::Exception> object and undef will be returned.

=head2 parse_file

Provided with a file path and some options as hash or hash reference and this will parse the file.

If the option I<utf8> is provided, the file will be opened with L<perlfunc/binmode> set to C<utf8>

It returns a new L<HTML::Object::Document>

=head2 parse_url

Provided with an URI supported by L<LWP::UserAgent> and this will issue a GET query and parse the resulting HTML data, and return a new L<HTML::Object::Document> or L<HTML::Object::DOM::Document> depending on which interface you use (either L<HTML::Object> or L<HTML::Object::DOM>.

If an error occurred, this will set an L<error|Module::Generic/error> and return C<undef>.

You can get the L<response|HTTP::Response> object with L</response>

=head2 parser

Sets or gets a L<HTML::Parser> object.

=head2 post_process

Provided with an L<HTML::Object::Element> and this will post process its parsing.

=head2 response

Get the latest L<HTTP::Response> object from the HTTP query made using L</parse_url>

=head2 sanity_check

Provided with an L<HTML::Object::Element> and this will perform some sanity checks and report the result on C<STDOUT>.

=head2 set_dom

Provided with a L<HTML::Object::Document> object and this sets the global variable C<$GLOBAL_DOM>. This is particularly useful when using L<HTML::Object::XQuery> to do things like:

    my $collection = $('div');

=head1 CREDITS

Throughout the documentation of this distribution, a lot of descriptions, references and examples have been borrowed from Mozilla. I have also contributed to improving their documentation by fixing bugs and typos on their site.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::DOM>, L<HTML::Object::Element>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
