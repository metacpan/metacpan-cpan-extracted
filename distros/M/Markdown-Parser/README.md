# NAME

Markdown::Parser - Markdown Parser Only

# SYNOPSIS

    use Markdown::Parser;
    my $p = Markdown::Parser->new;
    # Maybe with some callback?
    my $p = Markdown::Parser->new( callback => sub
    {
        my $obj = shift( @_ );
        # Do some processing with that Markdown object..
    });
    my $doc = $p->parse( $some_markdown_string ) || 
        die( $p->error );
    my $doc = $p->parse_file( $some_file ) ||
        die( $p->error );
    # Each element is an object inheriting from Markdown::Parser::Element
    printf( "%d children object collected.\n", $doc->children->length );
    my $markdown = $doc->as_markdown;
    my $html = $doc->as_string;
    my $pod = $doc->as_pod;

# VERSION

    v0.4.0

# DESCRIPTION

[Markdown::Parser](https://metacpan.org/pod/Markdown%3A%3AParser) is an object oriented [Markdown parser](https://daringfireball.net/projects/markdown/syntax) and manipulation interface.

It provides 2 modes: 1) strict and 2) extended

In strict mode, it conform rigorously to the Markdown specification as set out by its original author John Gruber and the extended mode, it accept and recognises extended Markdown syntax as set out in [PHP Markdown Extra](https://michelf.ca/projects/php-markdown/extra/) by [Michel Fortin](https://michelf.ca/home/)

# CONSTRUCTOR

## new

To instantiate a new [Markdown::Parser](https://metacpan.org/pod/Markdown%3A%3AParser) object, pass an hash reference of following parameters:

- abbreviation\_case\_sensitive

    Boolean value to determine if abbreviation, that are extended markdown, should be case sensitive or not.
    Default is false, i.e. they are not case sensitive, so an abbreviation declaration like:

    \*\[HTML4\] Hypertext Markup Language Version 4

    would match either `HTML4` or `html4` or even `hTmL4`

- callback

    Provided with a code reference, and this will register it as a callback to be triggered for every Markdown object encountered while parsing the data provided.

    You can also provide `undef`

- css\_grid

    A boolean value to set whether to return the tables as a [css grid](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout) rather than as an [html table](https://developer.mozilla.org/en-US/docs/Learn/HTML/Tables/Basics).

    This boolean value is passed to the ["create\_table" in Markdown::Parser::Element](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3AElement#create_table) in the ["parse\_table"](#parse_table) method.

    [CSS grids](https://medium.com/@js_tut/css-grid-tutorial-filling-in-the-gaps-c596c9534611) offer more flexibility and power than their conventional html counterparts.

    To achieve this, this module uses [CSS::Object](https://metacpan.org/pod/CSS%3A%3AObject) and inserts necessary css rules to be added to an inline style in the head section of the html document.

    Once the parsing is complete, you can get the [CSS::Object](https://metacpan.org/pod/CSS%3A%3AObject) object with ["css"](#css) method.

- _debug_

    This is an integer. The bigger it is and the more verbose is the output.

- _mode_

    This can be either _strict_ or _extended_. By default it is set to _strict_

# EXCEPTION HANDLING

Whenever an error has occurred, [Markdown::Parser](https://metacpan.org/pod/Markdown%3A%3AParser) will set a [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) object containing the detail of the error and return undef.

The error object can be retrieved with the inherited ["error" in Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric#error) method. For example:

    my $p = Markdown::Parser->new( debug => 3 ) || die( Markdown::Parser->error );

# METHODS

## abbreviation\_case\_sensitive

Boolean value that affects the way abbreviation are retrieved with ["get\_abbreviation" in Markdown::Parser::Document](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ADocument#get_abbreviation)

## callback

Sets or gets a code reference, and this will register it as a callback to be triggered for every Markdown object encountered while parsing the data provided.

You can also set `undef` to deactivate this feature.

## charset

Sets or gets the character set for the document. Typically something like `utf-8`

## code\_highlight

Takes a boolean value.

This is currently unused.

## create\_document

Creates and returns a [Markdown::Parser::Document](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ADocument) object. This is a special object which is the top element.

## css

Sets or get the [CSS::Object](https://metacpan.org/pod/CSS%3A%3AObject) objects. If one is set already, it is returned, or else an object is instantiated.

## css\_builder

This is a shortcut for the ["builder" in CSS::Object](https://metacpan.org/pod/CSS%3A%3AObject#builder) method.

## css\_grid

A boolean value to set whether to return the tables as a [css grid](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout) rather than as an [html table](https://developer.mozilla.org/en-US/docs/Learn/HTML/Tables/Basics).

## default\_email

Sets or gets the default email address to use, such as when setting up anti-spam measures.

See ["as\_string" in Markdown::Parser::Link](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ALink#as_string)

## document

Contains the [Markdown::Parser::Document](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ADocument) object. An [Markdown::Parser::Document](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ADocument) object is created by ["parser"](#parser) to contain all the parsed markdown elements.

## email\_obfuscate\_class

The css class to use when obfuscating email address.

See ["as\_string" in Markdown::Parser::Link](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ALink#as_string)

## email\_obfuscate\_data\_host

The fake host to use when performing email obfuscation.

See ["as\_string" in Markdown::Parser::Link](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ALink#as_string)

## email\_obfuscate\_data\_user

The fake user to use when performing email obfuscation.

See ["as\_string" in Markdown::Parser::Link](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ALink#as_string)

## encrypt\_email

Boolean value to mark e-mail address found to be encrypted. See [Markdown::Parser::Link](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ALink) for more information.

## footnote\_ref\_sequence

This is more an internal method used to keep track of the footnote reference found, i.e. something like:

    Here's a simple footnote,[^1] and here's a longer one.[^bignote]

So that the counter can be used to auto-generate number visible for those reference to footnotes.

This is differente from the footnote reference id i.e. the link from footnote back to the point where they are linked. For example:

    Here’s a simple footnote,1 and here’s a longer one.2

        1. This is the first footnote. ↩ # <-- Backlink is here

        2. Here’s one with multiple paragraphs and code. ↩ # <-- and here also

Here `1` and `2` are provided thanks to the ["footnote\_ref\_sequence"](#footnote_ref_sequence) and allocated to each [Markdown::Parser::FootnoteReference](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3AFootnoteReference)

## from\_html

Provided with an [HTML::Object::Element](https://metacpan.org/pod/HTML%3A%3AObject%3A%3AElement), presumably an [HTML::Object::Document](https://metacpan.org/pod/HTML%3A%3AObject%3A%3ADocument) object, and this will do its best to import it as a [Markdown::Parser::Document](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ADocument) object.

It returns a [Markdown::Parser::Document](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ADocument) object upon success, and if an [error](https://metacpan.org/pod/Module%3A%3AGeneric) occurred, it returns `undef`

## katex\_delimiter

Sets or gets an array reference.

The delimiter to use with `katex`

Returns an array object ([Module::Generic::Array](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray))

## list\_level

Sets or gets the list level. This takes an integer and is used during parsing of lists.

This method can be accessed as a regular method, or as a lvalue method, such as:

    $parser->list_level( 2 );
    # or
    $parser->list_level = 2;
    # or even
    $parser->list_level++;

## mode

Sets or gets the mode for the parser. Possible value is `strict` or `extended`

If set to `extended`, the the scope of the parser will included non-standard markdown formattings.

## parse

Provided with a string and some optional argument passed as an hash reference, and this will parse the string, create all the necessary object to represent the extent of the markdown document.

It returns the [Markdown::Parser::Document](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ADocument) object.

Possible arguments are:

- _element_

    A [Markdown::Parser::Element](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3AElement) subclass object that is used to store all newly created object from the parsing of the string provided.

    ["parse"](#parse) is called recursively, so this makes it possible to set sub element as the container element in parsing.

- _scope_

    Can be a string or an array reference defining the extent of the scope within which the parser operates. For example, if it is set to `strict`, it will only parse standard markdown formatting and ignore the rest.

    But, if we wanted to only parse paragraph and blockquotes and nothing else, its value would be:

        [qw( paragraph blockquote )]

- _scope\_cond_

    Sets whether the scope item specified are to be understood as `any one of them` or `all of them` Thius possible value is `any` or `all`.

## parse\_file

Given a file path, and this will check if it can access the resource, and open the file and call ["parse"](#parse) on the content retrieved.

If for some reason, the file content could not be accessed, it returns undef and set an error using ["error" in Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric#error) that this package inherits.

## parse\_list\_item

This method is called when the parser encounters a markdown list.

It takes a string representing the entire list and an optional hash reference of options.

Possible options are:

- _doc_

    The [Markdown::Parser::Element](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3AElement) object to be used as container of all the item found during parsing.

- _pos_

    An integer representation the position at which the parsing should start.

It returns a [Markdown::Parser::Document](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ADocument) object.

## parse\_list\_item

This method is called from within ["parse"](#parse) when an ordered or unordered list is found. It recursively parse the list data.

## parse\_table

This method is called from within ["parse"](#parse) when a table is found.

It will create a [Markdown::Parser::Table](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ATable) and associated objects, such as [Markdown::Parser::TableHeader](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ATableHeader), [Markdown::Parser::TableBody](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ATableBody) and [Markdown::Parser::Caption](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ACaption)

There can be one to 2 lines of headers and multiple table bodies. Table headers and table bodies contain [table rows](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ATableRow), who, in turn, contain [Markdown::Parser::TableCell](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ATableCell) objects.

## parse\_table\_row

Provided with a string representing a table row, along with optional hash reference of options and this willparse the string and return an array reference of [Markdown::Parser::TableRow](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ATableRow) objects. Each [Markdown::Parser::TableRow](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ATableRow) object contains one or multiple instance of [Markdown::Parser::TableCell](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3ATableCell) objects.

## scope

Returns the [Markdown::Parser::Scope](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3AScope) which is used during parsing to determine whether each element is part of the scope of not. During parsing, the scope may vary and may include only block element while sometime, the scope is limited to inline elements. For speed, the scope method ["has" in Markdown::Parser::Scope](https://metacpan.org/pod/Markdown%3A%3AParser%3A%3AScope#has) is cached.

## scope\_block

Get a new scope parameter, in the form of an array reference, that has a scope for block elements.

## scope\_inline

Get a new scope parameter, in the form of an array reference, that has a scope for inline elements.

## whereami

Provided with a scalar, an integer representing a position in the scalar, and an optional hash reference of options, and this method will print out or return a formatted string to visually show where exactly is the cursor in the string.

This is used solely for debugging and is resource intensive, so this along with the rest of the debugging method should not be used in live production.

This is activated when the parser object debug value is greater or equal to 3.

# PRIVATE METHODS

## \_total\_trailing\_new\_lines

Count how many trailing new lines there are in the given string and returns the number.

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[Regexp::Common::Markdown](https://metacpan.org/pod/Regexp%3A%3ACommon%3A%3AMarkdown) for the regular expressions used in this distribution.

[Text::Markdown::Discount](https://metacpan.org/pod/Text%3A%3AMarkdown%3A%3ADiscount) for a fast markdown to html converter using C code.

[Text::Markdown](https://metacpan.org/pod/Text%3A%3AMarkdown) for a version in pure perl.

# COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
