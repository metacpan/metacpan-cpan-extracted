# NAME

HTML::Obj2HTML - Create HTML from a arrays and hashes

# SYNOPSYS

    use HTML::Obj2HTML (components => 'path/to/components', default_currency => 'GBP', mode => 'XHTML', warn_on_unknown_tag => 1, html_fromarrayref_format => 0)

- `components`

    This is the relative path from the current working directory to components.
    Obj2HTML will find all \*.po files and automatically register elements that when
    called within your object executes the file. (See `fetch()`)

- `default_currency`

    Which currency to format output for when encountering the built in `currency`
    element.

- `mode`

    XHTML or HTML

- `warn_on_unknown_tag`

    Whether or not to print a warning to STDERR (using carp) when encountering an
    element that doesn't look like an HTML element, or registered extension element

- `html_fromarrayref_format`

    This module accepts two formats for conversion; one is an HTML::FromArrayref
    style arrayref, one is a variation. Differences are noted below.

## Usage

    set_opt('opt-name','value');
    set_dictionary(\%dictionary);
    add_dictionary_items(\%dictionary_items);
    set_snippet('snippet-name', \@Obj2HTMLItems);
    register_extension('element-name', \%definition);

    $result_html = gen(\@Obj2HTMLItems);

An Obj2HTML arrayref is a structure that when processed is turned into HTML.
Without HTML::FromArrayref format eanbled, it looks like this:

    [
       doctype => "HTML",
       html => [
         head => [
           script => { ... },
         ],
         body => { class => 'someclass', _ => [
           h1 => "Test page",
           p => "This is my test page!"
         ]}
       ]
    ];

## Builtin Features

- Add a snippet with \_snippet-name syntax

        [
          div => _snippet
        ]

- Execute a subroutine at generate time

        [
          div => \&generate_something
        ]

- Ignore things that don't look like elements at all; treat them like content

        [
          p => [
            "I really ",
            b => "really",
            " want an ice-cream"
          ]
        ]

- Add raw content to the mix

        [
          div => [
            raw => "<h1>Add some HTML directly</h1>"
          ]
        ]

- Add conditional output

        [
          div => [
            if => { cond => $loggedin, true => "You are logged in!", false => "Log in now!" }
          ]
        ]

    You can also use \[cond,true,false\] syntax.

        [
          div => [
            if => [$loggedin, "You are logged in!", "Log in now!"]
          ]
        ]

- Switch statement

        [
          div => [
            switch => { val => $permissionlvl, user => "You are a normal user", admin => "You are an admin! Well done you!" }
          ]
        ]

- Add Markdown with Text::Markdown

        [
          div => [
             md => "**What** do you think you're doing?"
          ]
        ]

- Or Plain text

        [
          div => [
            plain => "This is unformated text"
          ]
        ]

- Format Currency with Locale::Currency::Format

        [
          div => [
            "You own us ",
            currency => $amount
          ],
          div => [
            "Or if you'd rather pay in USD, ",
            currency => { currency => "USD", _ => $converted_amount}
          ]
        ]

- Pluralize with Text::Pluralize

        [
          div => [
            pluralize => ["You have %d item(s) in your basket", $items]
          ]
        ]

- Include other files that output Obj2HTML formatted objects

        [
           div => include("path/to/file")
        ]

- Add some javascript

          [
            javascript => q`
      $(function) {
        alert("Hi");
      };
      `
          ]

- Or include a javascript file (&lt;script src=...>)

        [
          head => [
            includejs => "uri/to/js"
          ]
        ]

- Conditions in element attributes (experimental)

        [
          div => { if => { cond => $loggedin, true => { class => "green"}, false => { class => "red" } } _ => "My Account" }
        ]

- Code instead of element attributes (expects back hashref)

        [
          div => \&gen_attributes
        ]

- Registering Components

    You can break apart complex sections of your page into reusable components.
    Suppose you create some login modal form and wish to include it on every page
    if the user is not logged in. You might therefore define a file called
    `components/account/loginform.po` and then reference the component from your
    Obj2HTML object:

        [
          if => [$loggedin, account::loginform => { session => $session }, []]
        ]

    Whenever you use a component in this way the contents of the hashref are passed
    to the component as $args.

    The component is called using a perl 'do'. If the result of calling the file
    is a coderef, the coderef is cached and the file is not called directly again.
    The coderef is then called with a single argument, the $args hashref.

- Registering Extensions

    Components are called when needed. A better approach for heavily used, more
    complex elements would be to create a plugin from which you define your element
    as an extention.

    Within your Plugin you would:

         HTML::Obj2HTML::register_extension("grid", {
           tag => "div",
           attr => { class => "ui grid" }
         }, END_TAG_REQUIRED);

         HTML::Obj2HTML::register_extension("column", {
           tag => "div",
           attr => { class => "column" }
         }, END_TAG_REQUIRED);

    Then within your Obj2HTML object, you can:

        [
          grid => [
            column => "Hello World!"
          ]
        ]

    Which renders to:

        <div class='ui grid'><div class='column'>Hello World!</div></div>

# Plugins

Plugins provide a way to extend what is understood as an element in the
Obj2HTML structure. The format for creating extensions is as follows:

    HTML::Obj2HTML::register_extension($element_name, \%definition, $type);

- `$element_name` is a string; this is what the element is called
- `\%definition` is a hashref containing elements to define what happens
when an element with this name is encountered
- `$type` is a set of flags defining special conditions for the element

## Plugin Definition

- before => &before\_sub

    When the element is encountered, the attribute that follows the element is
    passed to the function before\_sub, and whatever is returned from before\_sub
    is added to the HTML stream before the tag being processed is added. Note
    that you can further supress generation of the current element by setting the
    `tag` element to an empty string.

        HTML::Obj2HTML::register_extension("line", {
            tag => "hr",
            before => sub {
              return [ div => "Here comes a line!" ];
            }
        }, END_TAG_FORBIDDEN);

    When parsing the following:

        [
          line => {}
        ]

    Will generate:

        <div>Here comes a line!</div><hr />

- tag => $string

    This will translate your `$element_name` into `$tag`. For example:

        HTML::Obj2HTML::register_extension("line", {
            tag => "hr"
        }, END_TAG_FORBIDDEN);

    When parsing the following:

        [
          div => [
            line
          ]
        ]

    Will generate:

        <div><hr /></div>

    Setting $string to an empty string (`tag =` "">) results in no HTML being
    generated, aside that produced from before, replace and after.

- attr => \\%attributes

    The attributes defined here will be combined with the attributes given in
    the parsed Obj2HTML object. For example:

        HTML::Obj2HTML::register_extension("line", {
            tag => "hr",
            attr => { class => "ui seperator", style => "display: block" }
        }, END_TAG_FORBIDDEN);

    When parsing the following:

        [
          div => [
            line => { class => "red", "data-lineid" => 1 }
          ]
        ]

    Will generate:

        <div><hr class = "ui seperator red" style = "display: block" data-lineid = "1" /></div>

- scalarattr => $string

    If a scalar is passed with the element in the Obj2HTML object, this will be
    used as the value for the attribute called $string. For example:

        HTML::Obj2HTML::register_extension("line", {
            tag => "hr",
            scalarattr => "class"
        }, END_TAG_FORBIDDEN);

    When parsing the following:

        [
          div => [
            line => "red"
          ]
        ]

    Will generate:

        <div><hr class = "red" /></div>

- replace => \\&replace\_sub

    The entire element is replaced with the output of replace\_sub($attr), where
    $attr is whatever was passed after the original element in the Obj2HTML.

    If the return value of the replace\_sub is an arrayref, it is passed back through
    HTML::Obj2HTML::gen.

    This will automatically set tag to an empty string, so the original element
    is not generated.

- after => \\&after\_sub

    Similar to before, this defines code that will run after the tag has been
    inserted.

## Ordering is important!

Here's an example of using before and after to produce tabs:

    my @tabs = ();
    my @content = ();
    HTML::Obj2HTML::register_extension("tabsection", {
      tag => "",
      before => sub {
        my $obj = shift;
        @curtabs = ();
        @content = ();
        return HTML::Obj2HTML::gen($obj);
      },
      after => sub {
        my $obj = shift;
        my $divinner = {
          class => "ui tabular menu",
          _ => \@tabs
        };
        if (ref $obj eq "HASH") {
          foreach my $k (%{$obj}) {
            if (defined $divinner->{$k}) { $divinner->{$k} .= " ".$obj->{$k}; } else { $divinner->{$k} = $obj->{$k}; }
          }
          return HTML::Obj2HTML::gen([ div => $divinner, \@content ]);
        } else {
          return HTML::Obj2HTML::gen([ div => { class => "ui top attached tabular menu", _ => \@tabs }, \@content ]);
        }
      }
    });
    HTML::Obj2HTML::register_extension("tab", {
      tag => "",
      before => sub {
        my $obj = shift;
        if ($obj->{class}) { $obj->{class} .= " "; }
        if ($obj->{active}) { $obj->{class} .= "active "; }
        push(@tabs, div => { class => $obj->{class}."item", "data-tab" => $obj->{tab}, _ => $obj->{label} });
        push(@content, div => { class => $obj->{class}."ui bottom attached tab segment", "data-tab" => $obj->{tab}, _ => $obj->{content} });
        return "";
      }
    });

Now all I need to do to generate tabs and contents is:

    [
      tabsection => [
        tab => { active => 1, tab => "intro", label => "Introduction", content => "Here's my intro" },
        tab => { tab => "detail", label => "Detail", content => "And some content!" }
      ]
    ]

This produces a &lt;div> containing the tabs themselves, then each individual tab
content in it's own &lt;div>. See the Semantic UI tabs examples for details!

# WHY

Have you ever built a really complex web page, with many parts replicated with
other pages, sections of page that should only be shown in some circumstances?

Do you get frustrated making edits to HTML to add or remove an element level,
and needing to try to figure out where the end tag should go/needs to be removed
from?

Then this module is for you. This module allows you to build up an HTML like
page, using manipulatable array and hash refs, with added features like
embedding conditionals and coderefs that will only be executed right at the
last moment, while rendering the HTML. This allows true separation of
controller and view!

One of my favorite features is defining a single view that contains a form, but
changing the form into a readonly display of the data simply by performing a
`set_opt("readonly",1)`. And I don't just mean adding readonly to the form
elements - I mean removing the form elements entirely and leaving just the
values!

## Benefits

1\. Providing a more extensible way of parsing a perl objects into HTML objects,
including being able to create framework specific "plugins" that broaden what
you can do

2\. Providing the option to provide the content from within an attributes hash.
This simplifies parsing and allows you to do something like:

    div => { class => "segment", _ => "Some text" }

    div => { segment => [ "Some text" ] }

But you can tell this module to use the HTML::FromArrayref syntax, in which case
you would need to do:

    div => { class => "segment" }, "Some text"

This module is also aware of tags that should not have an end tag; you don't
need to provide anything more than the element name

    p => [ "My first paragraph", br, "The next line" ]

But you can of course still provide attributes:

    hr => { class => "ui seperator" }

3\. Providing extensions via plugins

Using HTML::Obj2HTML::register\_extension you can define your own element and how it
should be treated. It can be a simple substitution:

    HTML::Obj2HTML::register_extension("line", {
        tag => "hr",
        attr => { class => "ui seperator" }
    });

Therefore:

    line => { class => "red" }

Would yield:

    <hr class='ui seperator red' />

Or you can define "before" and "after" subroutines to be executed, which can
return larger pieces of rat HTML or an HTML::Obj2HTML object to be processed.

4\. Providing components. Via a plugin you can also create full compents in files
that are execute as perl scripts. These can return HTML::Obj2HTML objects to be
further processed.

All in all, this looks a feels a bit like React, but for Perl (and with vastly
different syntax).

# SEE ALSO

Previous attempts to do this same sort of thing:

- `HTML::LoL (last updated 2002)`
=item \* `HTML::FromArrayref (last updated 2013)`
=item \* `XML::FromArrayref (last updated 2013)`

How this is used in Dancer: `Dancer2::Template::Obj2HTML`

And a different way of routing based on the presence of files, which are
processed as `HTML::Obj2HTML` objects if they return an arrayref:
`Dancer2::Plugin::DoFile`
