## Name

FCGI::Buffer - Verify, Cache and Optimise FCGI Output

## Version

Version 0.23

## Synopsis

FCGI::Buffer verifies the HTML that you produce by passing it through
`HTML::Lint`.

FCGI::Buffer optimises FCGI programs by reducing, filtering and compressing
output to speed up the transmission and by nearly seamlessly making use of
client and server caches.

To make use of client caches, that is to say to reduce needless calls
to your server asking for the same data:

```perl
use FCGI;
use FCGI::Buffer;
# ...
my $request = FCGI::Request();
while($request->FCGI::Accept() >= 0) {
    my $buffer = FCGI::Buffer->new();
    $buffer->init(
            optimise_content => 1,
            lint_content => 0,
    );
    # ...
}
```

To also make use of server caches, that is to say,
to save regenerating output when different clients ask you for the same data,
you will need to create a cache.
But that's simple:

```perl
use FCGI;
use CHI;
use FCGI::Buffer;

# ...
my $request = FCGI::Request();
while($request->FCGI::Accept() >= 0) {
    my $buffer = FCGI::Buffer->new();
    $buffer->init(
        optimise_content => 1,
        lint_content => 0,
        cache => CHI->new(driver => 'File')
    );
    if($buffer->is_cached()) {
        # Nothing has changed - use the version in the cache
        $request->Finish();
        next;
    # ...
    }
}
```

To temporarily prevent the use of server-side caches, for example, whilst
debugging before publishing a code change, set the NO\_CACHE environment variable
to any value.

## Subroutines/Methods

### New

Create an FCGI::Buffer object.
Do one of these for each FCGI::Accept.

Takes the same options as init(), as a hash or a reference to a hash.

#### Api Specification

##### Input

```perl
    {
            generate_etag => { type => 'boolean', optional => 1 },
            generate_last_modified => { type => 'boolean', optional => 1 },
            generate_304 => { type => 'boolean', optional => 1 },
            compress_content => { type => 'boolean', optional => 1 },
            optimise_content => { type => 'integer', min => 0, max => 2, optional => 1 },
            lint_content => { type => 'boolean', optional => 1 },
            cache => { type => 'object', can => [ 'get_object', 'set', 'remove' ], optional => 1 },
            cache_key => { type => 'string', optional => 1 },
            cache_duration => { type => 'string', optional => 1 },
            save_to => { type => 'hashref', optional => 1 },
            info => { type => 'object', optional => 1 },
            lingua => { type => 'object', can => 'language', optional => 1 },
            logger => { type => 'object', can => [ 'trace', 'debug', 'info', 'warn', 'error' ], optional => 1 },
    }
```

##### Output

```perl
    { type => 'object', isa => 'FCGI::Buffer' }
```

Returns undef, with a warning, if it's called as a function or is given an odd
number of arguments.

#### Formal Specification

```
    new
      args? : OPTION -+-> VALUE
      self! : BUFFER
      selected : FILEHANDLE
      ---
      self!.old_buf = selected
      selected' = self!.buf
      self!.generate_etag = args?.generate_etag
        if generate_etag is in dom args?,
        otherwise it is true exactly when the protocol is conditional
```

### Init

Set various options and override default values.

```perl
# Put this toward the top of your program before you do anything
# By default, generate_etag, generate_304 and compress_content are ON,
# optimise_content and lint_content are OFF.  Set optimise_content to 2 to
# do aggressive JavaScript optimisations which may fail.
use FCGI::Buffer;

my $buffer = FCGI::Buffer->new()->init({
    generate_etag => 1,     # make good use of client's cache
    generate_last_modified => 1,    # more use of client's cache
    compress_content => 1,  # if gzip the output
    optimise_content => 0,  # optimise your program's HTML, CSS and JavaScript
    cache => CHI->new(driver => 'File'),    # cache requests
    cache_key => 'string',  # key for the cache
    cache_duration => '10 minutes', # how long to store responses in the cache
    logger => $self->{logger},
    lint_content => 0,      # Pass through HTML::Lint
    generate_304 => 1,      # When appropriate, generate 304: Not modified
    save_to => { directory => '/var/www/htdocs/save_to', ttl => 600, create_table => 1, max_pages => 10000 },
    info => CGI::Info->new(),
    lingua => CGI::Lingua->new(),
});
```

If no cache\_key is given, one will be generated which may not be unique.
The cache\_key should be a unique value dependent upon the values set by the
browser.

The cache object will be an object that understands get\_object(),
set(), remove() and created\_at() messages, such as an [CHI](https://metacpan.org/pod/CHI) object. It is
used as a server-side cache to reduce the need to rerun database accesses.

Items stay in the server-side cache by default for 10 minutes, the default can
be changed by the cache\_duration argument to init().
An item that has expired is no longer used.
The max-age directive of the client's Cache-Control HTTP header overrides this
if it's a number no larger than 600 seconds.
A larger value or something that isn't a number is ignored,
so a client can't fill your cache with items that are kept for years.

Responses are not stored in the server-side cache if the script's headers
include Set-Cookie,
or a Cache-Control of no-store, no-cache or private,
or a Content-Encoding,
or a Vary on anything except Accept-Encoding
(and Accept-Language, if a lingua argument has been given),
or if the output is an HTML page with an &lt;html> tag but no &lt;/html> tag,
which suggests that the script died part way through.
If your script finds an error after printing other types of content,
turn off the cache and save\_to as described below.

Save\_to is feature which stores output of dynamic pages to your
htdocs tree and replaces future links that point to that page with static links
to avoid going through CGI at all.
Ttl is set to the number of seconds that the static pages are deemed to
be live for, the default is 10 minutes.
If set to 0, the page is live forever.
A page that has passed its ttl is saved again the next time it's requested,
and is removed when any page is requested.
Max\_pages is the most static pages to keep, the default is 10000, and 0 means no
limit.
It stops a client from filling your disc by asking for many different arguments.
Create\_table says to create the table in the database if it doesn't exist.
To enable save\_to, info and cache arguments must also be given,
and a lingua argument should be given if the output depends on the language.
Without a cache no static pages are written.
The directory must be inside the document root,
otherwise the static pages can't be linked to, so save\_to is turned off and a
warning given once.
Only use where output is guaranteed to be the same with a given set of arguments
(the same criteria for enabling generate\_304).
Only HTML pages are saved.
Pages generated for clients that send cookies (other than Google Analytics
cookies and `csrf_token`) or have logged in, or those that aren't stored in the server-side
cache for the reasons above, are not saved,
since the static page would be given to everyone.
Those cookies don't change which entry in the server-side cache is used,
so a script whose output depends on one must send a Set-Cookie header with that
output.
A page that includes the value of the `csrf_token` cookie is never stored.
Links can give the arguments of a page in any order.
Several virtual hosts can share a directory.
You can turn it off on a case by case basis thus:

```perl
my $params = CGI::Info->new()->params();
if($params->{'send_private_email'}) {
    $buffer->init('save_to' => undef);
}
```

Info is an optional argument to give information about the FCGI environment, e.g.
a [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) object.

Logger will be an object that understands trace(), debug(), info(), warn() and
error(), such as an [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) object.
A logger without those is ignored, with a warning.
is\_debug() is also used, if it's there.

A Last-Modified header is generated if you give a cache object or an info
object, since the time comes from when the cache entry was created or from the
script's file.

Init allows a reference of the options to be passed. So both of these work:

```perl
use FCGI::Buffer;
#...
my $buffer = FCGI::Buffer->new();
$buffer->init(generate_etag => 1);
$buffer->init({ generate_etag => 1, info => CGI::Info->new() });
```

Generally speaking, passing by reference is better since it copies less on to
the stack.

If you give a cache to init() then later give cache => undef,
the server-side cache is no longer used.
This is useful when you find an error condition when creating your HTML
and decide that you no longer wish to store the output in the cache.

Init always returns the object, so that calls can be chained.
If the save\_to argument can't be used,
for example if the directory can't be written to,
a warning is given once and the page is sent without save\_to.

#### Api Specification

##### Input

The same as new(), where save\_to is:

```perl
    {
            directory => { type => 'string' },
            ttl => { type => 'integer', min => 0, optional => 1 },
            create_table => { type => 'boolean', optional => 1 },
            max_pages => { type => 'integer', min => 0, optional => 1 },
    }
```

##### Output

```perl
    { type => 'object', isa => 'FCGI::Buffer' }
```

#### Messages

```
    +------------------------------------+------------------------------+--------------------------+
    | Message                            | Meaning                      | Resolution               |
    +------------------------------------+------------------------------+--------------------------+
    | Too late to call init              | Output was printed first     | Call init earlier        |
    | save_to must be a hash reference   | Another type was given       | Give a hash reference    |
    | save_to needs a directory          | The directory key is missing | Give a directory         |
    | D isn't a directory                | It can't be created          | Check the path           |
    | D isn't writeable                  | Permissions                  | Check the permissions    |
    | D is not under the document root   | Pages could not be linked to | Move it under the root   |
    | The logger doesn't understand M    | Missing method               | Use another logger       |
    +------------------------------------+------------------------------+--------------------------+
```

#### Formal Specification

```perl
    init
      params? : OPTION -+-> VALUE
      self, self' : BUFFER
      ---
      dom params? is a subset of OPTION
      self'.save_to is defined =>
        can_cache(self) and writeable(self'.save_to.directory) and
        under(rootdir, self'.save_to.directory)
      params?.cache = undef => self'.cache is undefined
      result! = self'
```

### Set\_Options

Synonym for init, kept for historical reasons.

#### Api Specification

##### Input

The same as init().

##### Output

```perl
    { type => 'object', isa => 'FCGI::Buffer' }
```

#### Formal Specification

```
    set_options == init
```

### Can\_Cache

Returns true if the server is allowed to store the results locally.
This is the value of X-Cache in the returned header.

The cache isn't used if the NO\_CACHE or NO\_STORE environment variables are set,
if the request method isn't GET or HEAD,
if the client has logged in (the Authorization header or REMOTE\_USER is set),
or if the client's Cache-Control header includes any of no-store, no-cache,
private or max-age=0.
The answer is decided on the first call, and doesn't change for the rest of the
request.

#### Api Specification

##### Input

None.

##### Output

```perl
    { type => 'boolean' }
```

#### Formal Specification

```perl
    can_cache
      env : NAME -+-> STRING
      result! : BOOLEAN
      ---
      result! = true <=>
        NO_CACHE, NO_STORE, HTTP_AUTHORIZATION, REMOTE_USER are not in dom env and
        (REQUEST_METHOD is not in dom env or env(REQUEST_METHOD) is in {GET, HEAD}) and
        directives(env(HTTP_CACHE_CONTROL)) has none of {no-store, no-cache, private, max-age=0}
```

### Is\_Cached

Returns true if the output is cached. If it is then it means that all of the
expensive routines in the FCGI script can be by-passed because we already have
the result stored in the cache.

```perl
# Put this toward the top of your program before you do anything

# Example key generation - use whatever you want as something
# unique for this call, so that subsequent calls with the same
# values match something in the cache
use CGI::Info;
use CGI::Lingua;
use FCGI::Buffer;

my $i = CGI::Info->new();
my $l = CGI::Lingua->new(supported => ['en']);

# To use server-side caching you must give the cache argument, however
# the cache_key argument is optional - if you don't give one then one will
# be generated for you
my $buffer = FCGI::Buffer->new();
if($buffer->can_cache()) {
    $buffer->init(
        cache => CHI->new(driver => 'File'),
        cache_key => $i->domain_name() . '/' . $i->script_name() . '/' . $i->as_string() . '/' . $l->language()
    );
    if($buffer->is_cached()) {
        # Output will be retrieved from the cache and sent automatically
        exit;
    }
}
# Not in the cache, so now do our expensive computing to generate the
# results
print "Content-type: text/html\n";
# ...
```

An entry that has expired isn't cached,
and neither is any entry if the script's file has changed since,
or if the age of the script can't be determined.
If the cache fails, a warning is given and the output isn't cached.

#### Api Specification

##### Input

None.

##### Output

```perl
    { type => 'boolean' }
```

#### Formal Specification

```perl
    is_cached
      cache : KEY -+-> ENTRY
      key : KEY
      script_mtime : TIME
      now : TIME
      result! : BOOLEAN
      ---
      result! = true <=>
        key is in dom cache and
        cache(key).value is defined and
        cache(key).expires_at > now and
        script_mtime <= cache(key).created_at
```

## How the Output Is Sent

- Compression

    The first encoding listed by the client (in Accept-Encoding, or TE) that
    FCGI::Buffer can produce is used.
    Encodings with q=0 are skipped.

    Premise 1: the client is happy with any of the encodings that it lists.
    Premise 2: an encoding can only be produced if its module is installed.
    Conclusion: an encoding whose module isn't installed is passed over for the
    next one, rather than failing the request.
    If none can be used, the output is sent uncompressed.

    Only text is compressed, and not output for which the script has given its own
    Content-Encoding.
    A Vary: Accept-Encoding header is sent with anything that could be compressed.

- Character encoding

    The module works on what your script prints.

    If your script prints bytes, such as UTF-8 that hasn't been decoded,
    they are sent exactly as they are.

    If your script prints a string of characters,
    that is to say one with Perl's UTF-8 flag set,
    it's encoded as UTF-8.
    There's no need for you to set a layer on the file handle,
    and you should say so in your Content-Type header with a charset.

    So multibyte content is safe either way,
    but it's best not to join the two in one string,
    since Perl would then treat the bytes as Latin-1 characters.

    Offsets in a Range request, the Content-Length header and the ETag are all
    worked out from the bytes that are sent.

- Range

    A single range of bytes, such as `bytes=0-99`, `bytes=100-` or
    `bytes=-100` (the last 100 bytes), is honoured with a 206 status and a
    Content-Range header.
    A range which starts after the end of the page, or `bytes=-0`,
    can't be satisfied and gets a 416 status with no body.
    Anything else, such as several ranges or a backwards range, is ignored and the
    whole page is sent.

    A range is only honoured for a GET request with a status of 200 and when no
    server-side cache has been given, otherwise the whole page is sent,
    which RFC 9110 allows.
    An If-Range header is honoured.
    A part of a page is never compressed, so it has the ETag of the uncompressed
    version.
    It is a part of the page after any links have been changed to point to static
    pages.

- Conditional requests

    If-None-Match may be a list of ETags, weak ETags or "\*".
    If it is given, If-Modified-Since isn't looked at.
    The ETag is of the page as it's sent, so it changes when a link is changed to
    point to a static page.
    Last-Modified is when the page was put into the cache and doesn't change,
    so a client that only sends If-Modified-Since can be given a 304 and keep the
    old links.
    Browsers send both.
    For methods other than GET and HEAD a match gives a 412 status, although the
    script will have already run,
    and If-Modified-Since is ignored.

    If there would be more than one Expires header,
    because the script gave one and there are links to static pages,
    only the earliest is sent.

    The ETag of compressed output ends with the name of the encoding,
    e.g. `"0123456789abcdef0123456789abcdef-gzip"`, since it isn't the same bytes
    as the uncompressed version.
    If-None-Match treats them as a match, but If-Range doesn't.

- Headers

    The module sends one Status header, and works out Content-Length itself even
    if the script has given one, since the output may have changed.
    Header lines can end in either CRLF or LF.

- Failures

    Nothing that goes wrong with the cache, the save\_to database or the logger stops
    the page from being sent.
    A warning is given,
    and if the page can't be processed further it's sent as the script printed it.
    If the script printed nothing because it relied upon the cache,
    the status is 500.

- Optimisation

    optimise\_content leaves the contents of &lt;pre> and &lt;textarea> alone.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Bugs

FCGI::Buffer should be safe even in scripts that produce lots of different
output, e.g. e-commerce situations.
On such pages, however, I strongly urge setting generate\_304 to 0 and
sending the HTTP header "Cache-Control: no-cache".

When using [Template](https://metacpan.org/pod/Template), ensure that you don't use it to output to STDOUT,
instead,
you will need to capture into a variable and print that.
For example:

```perl
my $output;
$template->process($input, $vars, \$output) || ($output = $template->error());
print $output;
```

Can produce buggy JavaScript if you use the &lt;!-- HIDING technique.
This is a bug in [JavaScript::Packer](https://metacpan.org/pod/JavaScript%3A%3APacker), not FCGI::Buffer.

Mod\_deflate can confuse this when compressing output.
Ensure that deflation is off for .pl files:

```
SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|pl)$ no-gzip dont-vary
```

If you request compressed output then uncompressed output (or vice
versa) on input that produces the same output, the status will be 304.
The letter of the spec says that's wrong, so I'm noting it here, but
in practice, you should not see this happen or have any difficulties
because of it.

FCGI::Buffer has not been tested against FastCGI.

I advise adding FCGI::Buffer as the last use statement so that it is
cleared up first.  In particular, it should be loaded after
[Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl), if you're using that, so that any messages it
produces are printed after the HTTP headers have been sent by
FCGI::Buffer;

Save\_to doesn't understand links in JavaScript, which means that if you use self-calling
CGIs loaded as a static page,
they may point to the wrong place.
The workaround is to avoid self-calling CGIs in JavaScript

Please report any bugs or feature requests to `bug-fcgi-buffer at rt.cpan.org`
or through the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FCGI-Buffer](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FCGI-Buffer).
I will be notified, and then you'll automatically be notified of the progress on
your bug as I make changes.

The lint operation only works on HTML4, because of a restriction in [HTML::Lint](https://metacpan.org/pod/HTML%3A%3ALint).

## See Also

[CGI::Buffer](https://metacpan.org/pod/CGI%3A%3ABuffer),
[HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker),
[HTML::Lint](https://metacpan.org/pod/HTML%3A%3ALint)

## Support

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

```
perldoc FCGI::Buffer
```

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=FCGI-Buffer](http://rt.cpan.org/NoAuth/Bugs.html?Dist=FCGI-Buffer)

- Search CPAN

    [http://search.cpan.org/dist/FCGI-Buffer/](http://search.cpan.org/dist/FCGI-Buffer/)

## Acknowledgements

The inspiration and code for some of this is cgi\_buffer by Mark
Nottingham: [https://www.mnot.net/blog/2003/04/24/etags](https://www.mnot.net/blog/2003/04/24/etags).

## License and Copyright

The licence for cgi\_buffer is:

```
"(c) 2000 Copyright Mark Nottingham <mnot@pobox.com>

This software may be freely distributed, modified and used,
provided that this copyright notice remain intact.

This software is provided 'as is' without warranty of any kind."
```

The rest of the program is Copyright 2015-2026 Nigel Horne,
and is released under the following licence: GPL2
