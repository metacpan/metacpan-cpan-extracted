# NAME

HTML::Object - HTML Parser, Modifier and Query Interface

# SYNOPSIS

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

To enable fatal error and also implement try-catch (using [Nice::Try](https://metacpan.org/pod/Nice%3A%3ATry)) :

    use HTML::Object fatal_error => 1, try_catch => 1;

# VERSION

    v0.2.10

# DESCRIPTION

This module is yet another HTML parser, manipulation and query interface, but probably the most comprehensive one. It uses the C parser from [HTML::Parser](https://metacpan.org/pod/HTML%3A%3AParser) and has the unique particularity that it does not try to decode the entire html document tree only to re-encode it when printing out its data as string like so many other html parsers out there do. Instead, it modifies only the parts required. The rest is returned exactly as it was found in the HTML. This is faster and safer.

This module contains 144 modules to closely implement the HTML standard as documented on [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/HTML_DOM_API).

It uses an external json data dictionary file of html tags (`html_tags_dict.json`).

There are 3 ways to manipulate and query the html data:

- 1. [HTML::Object::Element](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AElement)

    This is lightweight and simple

- 2. [HTML::Object::DOM](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADOM)

    This is an alternative HTML parser also based on [HTML::Parser](https://metacpan.org/pod/HTML%3A%3AParser), and that implements fully the Web API with DOM (Data Object Model), so you can query the HTML with perl equivalent to JavaScript methods of the Web API. It has been designed to be strictly identical to the Web API.

- 3. [HTML::Object::XQuery](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AXQuery)

    This interface provides a jQuery like API and requires the use of [HTML::Object::DOM](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADOM). However, this is not designed to be a perl implementation of JavaScript, but rather a perl implementation of DOM manipulation methods found in jQuery.

Note that this interface does not enforce HTML standard. It is up to you the developer to decide what value to use and where the HTML elements should go in the HTML tree and what to do with it.

# METHODS

## new

Instantiate a new [HTML::Object](https://metacpan.org/pod/HTML%3A%3AObject) object.

You need to instantiate a new object prior to parse any new document. It cannot be re-used to parse another document, or if you really wanted to, you would first need to unset ["document"](#document) and unset ["current\_parent"](#current_parent):

    $p->document( undef );
    $p->current_parent( undef );

But, it is just as fast to do:

    $p = HTML::Object->new;

## add\_comment

This is a parser method called that will add a comment to the stack of html elements.

## add\_declaration

This is a parser method called that will add a declaration to the stack of html elements.

## add\_default

This is a parser method called that will add a default html tag to the stack of html elements.

## add\_end

This is a parser method called that will add a closing html tag to the stack of html elements.

## add\_space

This is a parser method called that will add a space to the stack of html elements.

## add\_start

This is a parser method called that will add a starting html tag to the stack of html elements.

## add\_text

This is a parser method called that will add a text to the stack of html elements.

## current\_parent

Sets or gets the current parent, which must be an [HTML::Object::Element](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AElement) object or an inheriting class.

## dictionary

Returns an hash reference containing the HTML tags dictionary. Its structure is:

- dict

    This property reflects an hash containing all the known tags. Each tag has the following possible properties:

    - description

        String

    - is\_deprecated

        Boolean value

    - is\_empty

        Boolean value

    - is\_inline

        Boolean value

    - is\_svg

        Boolean value that describes whether this is a tag dedicated to svg.

    - link\_in

        Array reference of HTML attributes containing links

    - ref

        The reference URL to the online web documentation for this tag.

- meta

    This property holds an hash reference containing the following meta information:

    - author

        String

    - updated

        ISO 8601 datetime

    - version

        Version number

## document

Sets or gets the document [HTML::Object::Document](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADocument) object.

## get\_definition

Get the hash definition for a given tag (case does not matter).

The tags definition is taken from the external file `html_tags_dict.json` that is provided with this package.

## new\_closing

Creates and returns a new closing html element [HTML::Object::Closing](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AClosing), passing it any arguments provided.

## new\_comment

Creates and returns a new closing html element [HTML::Object::Comment](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AComment), passing it any arguments provided.

## new\_declaration

Creates and returns a new closing html element [HTML::Object::Declaration](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADeclaration), passing it any arguments provided.

## new\_document

Creates and returns a new closing html element [HTML::Object::Document](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADocument), passing it any arguments provided.

## new\_element

Creates and returns a new closing html element [HTML::Object::Element](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AElement), passing it any arguments provided.

## new\_space

Creates and returns a new closing html element [HTML::Object::Space](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ASpace), passing it any arguments provided.

## new\_special

Provided with an HTML tag class name and hash or hash reference of options and this will load that class and instantiate an object passing it the options provided. It returns the object thus Instantiated.

This is used to instantiate object for special class to handle certain HTML tag, such as `a`

## new\_text

Creates and returns a new closing html element [HTML::Object::Text](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AText), passing it any arguments provided.

## parse

Provided with some `data` (see below), and some options as hash or hash reference and this will parse it and return a new [HTML::Object::Document](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADocument) object.

Possible accepted data are:

- _code_

    ["parse\_data"](#parse_data) will be called with it.

- _glob_

    ["parse\_data"](#parse_data) will be called with it.

- _string_

    ["parse\_file"](#parse_file) will be called with it.

Other reference will return an error.

## parse\_data

Provided with some `data` and some options as hash or hash reference and this will parse the given data and return a [HTML::Object::Document](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADocument) object.

If the option _utf8_ is provided, the `data` received will be converted to utf8 using ["decode" in Encode](https://metacpan.org/pod/Encode#decode). If an error occurs decoding the data into utf8, the error will be set as an [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) object and undef will be returned.

## parse\_file

Provided with a file path and some options as hash or hash reference and this will parse the file.

If the option _utf8_ is provided, the file will be opened with ["binmode" in perlfunc](https://metacpan.org/pod/perlfunc#binmode) set to `utf8`

It returns a new [HTML::Object::Document](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADocument)

## parse\_url

Provided with an URI supported by [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) and this will issue a GET query and parse the resulting HTML data, and return a new [HTML::Object::Document](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADocument) or [HTML::Object::DOM::Document](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADOM%3A%3ADocument) depending on which interface you use (either [HTML::Object](https://metacpan.org/pod/HTML%3A%3AObject) or [HTML::Object::DOM](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADOM).

If an error occurred, this will set an [error](https://metacpan.org/pod/Module%3A%3AGeneric#error) and return `undef`.

You can get the [response](https://metacpan.org/pod/HTTP%3A%3AResponse) object with ["response"](#response)

## parser

Sets or gets a [HTML::Parser](https://metacpan.org/pod/HTML%3A%3AParser) object.

## post\_process

Provided with an [HTML::Object::Element](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AElement) and this will post process its parsing.

## response

Get the latest [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object from the HTTP query made using ["parse\_url"](#parse_url)

## sanity\_check

Provided with an [HTML::Object::Element](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AElement) and this will perform some sanity checks and report the result on `STDOUT`.

## set\_dom

Provided with a [HTML::Object::Document](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADocument) object and this sets the global variable `$GLOBAL_DOM`. This is particularly useful when using [HTML::Object::XQuery](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AXQuery) to do things like:

    my $collection = $('div');

# CREDITS

Throughout the documentation of this distribution, a lot of descriptions, references and examples have been borrowed from Mozilla. I have also contributed to improving their documentation by fixing bugs and typos on their site.

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[HTML::Object::DOM](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADOM), [HTML::Object::Element](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AElement), [HTML::Object::XQuery](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AXQuery)

# COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.
