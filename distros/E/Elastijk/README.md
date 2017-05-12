[![Build Status](https://travis-ci.org/gugod/Elastijk.svg?branch=master)](https://travis-ci.org/gugod/Elastijk) [![Coverage Status](https://img.shields.io/coveralls/gugod/Elastijk/master.svg?style=flat)](https://coveralls.io/r/gugod/Elastijk?branch=master)
# NAME

Elastijk - A specialized Elasticsearch client.

# SYNOPSIS

    use Elastijk;

    my ($status, $response) = Elastijk::request({
        host => "localhost",
        port => "9200",
        method => "GET",

        index => "blog",
        type => "article",
        command => "_search",

        uri_param => { search_type => "dfs_query_then_fetch" }
        body => {
            query => { match => { "body" => "cpan" } }
        }
    });

    if ($status eq "200") {
        for my $hit (@{ $response->{hits}{hits} }) {
            say $hit->{url};
        }
    }

# DESCRIPTION

Elastijk is a Elasticsearch client library. It uses [Hijk](https://metacpan.org/pod/Hijk), a HTTP client that
implements a tiny subset of HTTP/1.1 just enough to talk to Elasticsearch via
HTTP.

Elastijk provided low-level functions that are almost identical as using HTTP
client, and an object-oriented sugar layer to make it a little bit easier to
use. The following documentation describe the low-level function first.

# FUNCTIONS

## Elastijk::request( $args :HashRef ) : ($status :Int, $response :HashRef)

Making a request to the Elasticsearch server specified in `$args`. It returns 2
values. `$status` is the HTTP status code of the response, and the `$response`
decoded as HashRef. Elasticsearch API always respond a single HashRef as JSON
text, this might or might not be changed in the future, if it is changed then
this function will be adjusted accordingly.

The `$args` is a HashRef takes contains the following key-value pairs:

    host  => Str
    port  => Str
    index => Str
    type  => Str
    id    => Str
    command => Str
    uri_param => HashRef
    body  => HashRef | ArrayRef | Str
    method => "GET" | "POST" | "HEAD" | "PUT" | "DELETE"

The 4 values of `index`, `type`, `id`, `command` are used to form the URI
path following Elasticsearch's routing convention:

    /${index}/${type}/${id}/${command}

All these path parts are optional, when that is the case, Elstaijk properly
remove `/` in between to form the URL that makes sense, for example:

    /${index}/${type}/${id}
    /${index}/${command}

The value of `uri_param` is used to form the query\_string part in the URI, some
common ones for Elasticsearch are `q`, `search_type`, and `timeout`.  But the
accepted list is different for different commands.

The value of `method` corresponds to HTTP verbs, and is hard-coded to match
Elasticsearch API. Users generally do not need to provide this value, unless you
are calling `request` directly, in which case, the default value is 'GET'.

For all cases, Elastijk simply bypass the value it receive to the server without
doing any parameter validation. If that generates some errors, it'll be on
server side.

## Elastijk::request\_raw( $args :HashRef ) : ($status :Int, $response :Str)

Making a request to the Elasticsearch server specified in `$args`. The main
difference between this function and `Elastijk::request` is that
`$args-`{body}> s expected to be a String scalar, rather then a HashRef. And
the $response is not decoded from JSON. This function can be used if users wish
to use their own JSON parser to parse response, or if they wish to delay the
parsing to be done latter in some bulk-processing pipeline.

# OBJECT

## PROPERTIES

An Elastijk object is constructed like this:

    my $es = Elastijk->new(
        host => "es1.example.com",
        port => "9200"
    );

Under the hood, it is only a blessed hash, while all key-value pairs in the hash
are the properties. Users could break the packaging and modify those values, but
it is fine. All key-value pairs are shallow-copied from \`new\` method.

Here's a full list of key-value pairs that are consumed:

    host  => Str "localhost"
    port  => Str "9200"
    index => Str (optional)
    type  => Str (optional)

The values for `index` and `type` act like a "default" value and they are only
used in methods that could use them. Which is handy to save some extra typing.
Given objects constructed with different default of `index` attribute:

    $es0 = Elastijk->new();
    $es1 = Elastijk->new( index => "foo" );

... calling the same `search` method with the same arguments will generate
different request:

    my @args = (uri_param => { q => "nihao" });
    $es0->search( @args  ); # GET /_search?q=nihao
    $es1->search( @args  ); # GET /foo/_search?q=nihao

This behavior is consistent for all methods.

# METHODS

All methods takes the same key-value pair HashRef as
`Elastijk::request` function, and returns 2 values that are HTTP
status code, and the body hashref. The boilerplate of checking the
return values is something like:

    my ($status, $res) = $es->search(...);
    if (substr($status,0,1) eq '2') { # 2xx = successful
        ... $res->{hits} ...
    }

The `$res` contains the parsed response and it should be always a
HashRef, but it may be an ArrayRef. Elasticsearch server mostly
respond with a HTTP Body that is a valid JSON document -- but some
past version of Elasticsearch does not always follow that convention in
some APIs. Please consult the Elasticsearch API document link for the
hints of value type. Elastijk is a thin client, and that means itself
only assumes Elasticsearch servers response back with a valid JSON
document, and it decodes it to a perl data structure. Elastijk does as
little data transformation as possible to keep it a stupid, thin
client.

Due to how Perl handles multiple return values, you can omit the status
check and just do:

    my $res = $es->search(...);
    ... $res->{hits} ...

This style is by design for the convenience of developers, who can
either worry about error checking latter, or throw the program away if
it's just a one-timer.

Many of of methods are named after an server command. For example, the command
`_search` corresponds to method `search`, the command `_bulk` corresponds to
method `bulk`.

The status code is used for error-checking purposes. Elasticsearch should respond
with status 4XX when the relevant thing is missing, and 5XX when there are some
sort of errors. To check if a request is successful, test if it is 200 or 201.

Due to the fact the value of a lists is the last value of element, it is a
little bit shorter if status check could be ignored:

    my $res = $es->search(...);
    for (@{ $res->{hits}{hits} }) {
        ...
    }

`count` and `exists` method modified `$res` to be a scalar (instead of
HashRef) to allow these intuitive use cases:

    if ($es->exists(...)) { ... }
    if ($es->count(...) > 10) { ... }

... the original response body are discarded.

## request( ... )

This is a low-level method that just bypass things, but it is useful when, say,
newer Elasticsearch version introduce a new command, and there are no
corresponding method in the Client yet. The only difference between using this
method and calling `Elasijk::request` directly, is that the values of
`host`,`port`,`index`, and &lt;type> ind the object context are consumed.

## head(...), get(...), put(...), post(...), delete(...)

Shorthands for the HTTP verbs. All these are just direct delegate to `request`
method.

## search( body => {...}, uri\_param => {...} )

This method invokes [the search api](https://www.elastic.co/guide/guide/en/elasticsearch/reference/current/search-search.html).

The arguments are key-value pairs from the API documents.

## count( body => {...}, uri\_param => {...} )

This method corresponds to [the search count api](https://www.elastic.co/guide/guide/en/elasticsearch/reference/current/search-count.html)

## exists( index => Str, type => Str, id => Str )

Check if the given thing exists. Which can be a document, a type, and an index.
Due to the nature of their dependency, here's the combination you would need
to check the existence of different things:

    document: index => "foo", type => "bar", id => "beer"
    type:     index => "foo", type => "bar"
    index:    index => "foo"

See also [https://www.elastic.co/guide/guide/en/elasticsearch/reference/current/indices-exists.html](https://www.elastic.co/guide/guide/en/elasticsearch/reference/current/indices-exists.html) ,
[https://www.elastic.co/guide/guide/en/elasticsearch/reference/current/indices-types-exists.html#indices-types-exists](https://www.elastic.co/guide/guide/en/elasticsearch/reference/current/indices-types-exists.html#indices-types-exists) , and [https://www.elastic.co/guide/guide/en/elasticsearch/guide/current/doc-exists.html](https://www.elastic.co/guide/guide/en/elasticsearch/guide/current/doc-exists.html)

## scan\_scroll( ..., on\_response => sub {} )

A way to perform [scan and scroll](https://www.elastic.co/guide/guide/en/elasticsearch/guide/current/scan-scroll.html).

The boilerplate to use it is something like:

    $es->scan_scroll(
        index => "tweet",
        body => { query => { match_all => {} }, size => 1000 },
        on_response => sub {
            my ($status,$res) = @_;
            for my $hit (@{ $res->{hits}{hits} }) {
                ...
            }
        }
    );

The "search\_type" is forced to be "scan" in this method.

The very last value to the `on_response` key is a callback subroutine that is
called after each HTTP request. The arguments are HTTP status code and response
body hash just like other methods.

## bulk( ..., body => ArrayRef\[ HashRef \], ... )

The `bulk` method is for doing commands via Elasticsearch bulk API
[https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html).

Unlike other methods, The `bulk` method requires the value to the
`body` key to be an ArrayRef. The elements of such ArrayRef are
HashRef that correspond to the request content described in the bulk
API document.

Notice that the request body of bulk API is not a valid JSON document
as a whole, but just a naive concatenation of multiple JSON documents.

# AUTHORS

- Kang-min Liu <gugod@gugod.org>
- Borislav Nikolov <jack@sofialondonmoskva.com>

# COPYRIGHT

Copyright (c) 2013-2016 Kang-min Liu `<gugod@gugod.org>`.

# LICENCE

The MIT License

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
