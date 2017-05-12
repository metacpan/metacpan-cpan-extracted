package JSON::SL::Boolean;

use overload
   "0+"     => sub { ${$_[0]} },
   "++"     => sub { $_[0] = ${$_[0]} + 1 },
   "--"     => sub { $_[0] = ${$_[0]} - 1 },
   fallback => 1;
1;


package JSON::SL;
use warnings;
use strict;
our $VERSION;
use base qw(Exporter);
our @EXPORT_OK = qw(decode_json unescape_json_string);

BEGIN {
    $VERSION = '1.0.6';
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
}

sub CLONE_SKIP {
    return 1;
}

sub unescape_settings {
    my ($self,$c) = @_;
    if (!defined $c) {
        require JSON::SL::EscapeTH;
        my $ret = {};
        tie(%$ret, 'JSON::SL::EscapeTH', $self);
        return $ret;
    } else {
        $c = ord($c);
        if (@_ == 3) {
            return $self->_escape_table_chr($c, $_[2]);
        } else {
            return $self->_escape_table_chr($c);
        }
    }
}

1;

__END__

=head1 NAME

JSON::SL - Fast, Streaming, and Searchable JSON decoder.

=head1 SYNOPSIS

    use JSON::SL;
    use Data::Dumper;
    
    my $txt = <<'EOT';
    {
        "some" : {
            "partial" : 42.42
        },
        "other" : {
            "partial" : "a string"
        },
        "complex" : {
            "partial": {
                "a key" : "a value"
            }
        },
        "more" : {
            "more" : "stuff"
    EOT
    
    my $json = JSON::SL->new();
    my $jpath = "/^/partial";
    $json->set_jsonpointer( [$jpath] );
    my @results = $json->feed($txt);
    
    foreach my $result (@results) {
        printf("== Got result (path %s) ==\n", $result->{Path});
        printf("Query was %s\n", $result->{JSONPointer});
        my $value = $result->{Value};
        if (!ref $value) {
            printf("Got scalar value %s\n", $value);
        } else {
            printf("Got reference:\n");
            print Dumper($value);
        }
        print "\n";
    }
    
Produces:

    == Got result (path /some/partial) ==
    Query was /^/partial
    Got scalar value 42.42
    
    == Got result (path /other/partial) ==
    Query was /^/partial
    Got scalar value a string
    
    == Got result (path /complex/partial) ==
    Query was /^/partial
    Got reference:
    $VAR1 = {
              'a key' => 'a value'
            };

    
=head2 DESCRIPTION

JSON::SL was designed from the ground up to be easily accessible and
searchable for partially received streamining content.

It uses an embedded C library (C<jsonsl>) to do the streaming and most
of the dirty work.

JSON::SL allows you to use the
L<JSONPointer|http://tools.ietf.org/html/draft-pbryan-zyp-json-pointer-02>
URI/path syntax to tell it about certain objects and elements which are of
interest to you. JSON::SL will then incrementally parse the input stream,
returning those selected objects to you as soon as they arrive.

In addition, the objects are returned with extra context information, which is
itself another JSONPointer path specifying the path from the root of the JSON
stream until the current object.

Since I hate SAX's callback interface, and since almost all the boilerplate
for a SAX interface needs to be done for just about every usage case, I have
decided to move over the core work of state stacking and such to the C library
itself. This means minimal boilerplate and ultra fast performance on your part.

=head2 GENERIC METHODS

=head3 new()

=head3 new($max_levels)

Creates a new C<JSON::SL> object

If C<$max_levels> is provided, then it is taken as the maximum recursion depth
the parser will be able to descend. This can only be set during construction time
as it affects the amount of memory allocated for the internal structures.

The amount of memory allocated for each structure is around 64 bytes on 64-bit
(i.e. C<sizeof (char*) == 8>) systems
and around 48 bytes on 32 bit (i.e. C<sizeof (char*) == 4>) systems.

The default is 512, or a total of 32KB allocated

=head3 set_jsonpointer(["/arrayref/of", "/json/paths/^"])

Set the I<JSONPointer> query paths for this object. Note this can only be
done once per the object's lifetime, and only before you have started calling
the L</feed> method.

The JSONPointer notation is quite simple, and follows URI scheme conventions.
Each C</> represents a level of descent into an object, and each path component
represents a hash key or array index (whether something is indeed a key or an
index is derived from the context of the JSON stream itself, in case you were
wondering).

http://tools.ietf.org/html/draft-pbryan-zyp-json-pointer-02 Contains the draft
for the JSONPointer specification.

As an extension to the specification, C<JSON::SL> allows you to use the C<^>
(caret) character as a wildcard. Placing the lone C<^> in any path component
means to match any value in the current level, effectively providing glob-style
semantics.

=head3 feed($input_text)

=head3 incr_parse($input_text)

This is the meat and potatoes of C<JSON::SL>. Call it with C<$input> being a
JSON input stream, with likely partial data.

The module will do its magic and decode elements for you according to the queries
set in L</set_jsonpointer>.

If called in scalar context, returns one matching item from the partial stream.
If called in list context, returns all remaining matching items.
If called in void context, the JSON is still decoded, but nothing is returned.

The return value is one or a list of (depending on the context) hash references
with the following keys

=over

=item Value

This is the actual value selected by the query. This can be a string, number,
hash reference, array reference, undef, or a C<JSON::SL::Boolean> object.

=item Path

This is a JSONPointer path, which can be used to get context information (and
perhaps be able to locate 'neighbors' in the object graph using L</root>).

=item JSONPointer

The original matching query path used to select this object. Can be used to
associate this object with some extra user-defined context.

=back

N.B. C<incr_parse> is an alias to this method, for familiarity.

=head3 fetch()

Returns remaining decoded JSON objects. Returns the same kinds of things that
L</feed> does (with the same semantics dependent on scalar and list context),
except that it does not accept any arguments. This is helpful for a usage pattern
as such:

    $sl->feed($large_json);
    while (my ($res = $sl->fetch)) {
        # do something with the result object..
    }


=head3 reset()

Resets the state. Any cached objects, result queues, and such are deleted and
freed. Note that the JSONPointer query will still remain (and is static for
the duration of the JSON::SL instance).

=head2 OBJECT GRAPH INSPECTION AND MANIPULATION

One of C<JSON::SL>'s features is the ability to get a perl-representation of
incomplete JSON data. As soon as a JSON element can be converted to some kind of
shell which resembles a Perl object, it is inserted into the object graph, or
object tree

=head3 root()

This returns the partial object graph formed from the JSON stream. In other words,
this is the object tree.

Items whihc have been selected to be filtered via L</set_jsonpointer> are not
present in this object graph, and neither are incomplete strings.

It is an error to modify anything in the object returned by root, and Perl will
croak if you try so with an 'attempted modification of read-only value' error.
(but see L</make_referrent_writeable> for a way to override this)

Nevertheless it is useful to get a glimpse of the 'rest' of the JSON document
not returned via the feed method

B<NOTE> This method is deprecated. Use the L</root_callback> method instead.

=head3 root_callback($cb)

Invoked when the root object is first created. It is passed a reference to the
root object. Use this method instead of C<root>, as the root object will no
longer be available via C<root()> once the parsing of the current tree is
completed. Using a callback oriented mechanism proviedes a better guarantee
of being able to keep a reference to the root.

=head3 referrent_is_writeable($ref)

Returns true if the object pointed to by C<$ref> has the C<SvREADONLY> flag
off. In other words, if the flag is off then it is safe to modify its contents.

=head3 make_referrent_writeable($ref)

=head3 make_referrent_readonly($ref)

Convenience methods to make the perl variable referred to by C<$ref> read-only
or writeable.

C<make_referrent_writeable> will make the object pointed to by C<$ref> as
writeable, and C<make_referrent_readonly> will make the object pointed to by
C<$ref> as readonly.

You may 'poll' to see when an object has become writeable by doing the following

    1) Locate your initial object in the object graph using my $v = $sl->root()
    2) Check its initial status by using $sl->referrent_is_writeable($v)
    3) Stash the reference somewhere, and repeat step 2 as necessary.
    
Using the C<make_referrent_writeable> you may modify the object graph as needed.
Modification of the object graph is not always safe and performing disallowed
modifications can make your application crash (which is why incomplete objects
are marked as read-only in the first place).

In the event where you need to make modifications to the object graph, following
these guidelines will prevent an application crash:

=over

=item Strings, Integers, Booleans

These are always safe to modify (and will never be read-only) because they are
only inserted into the object graph once they have completed.

=item Hash Keys

Deleting hash keys which point to placeholders (represented as C<undef>) will
change the hash key for the real value, once that value is completed.

=item Hashes, Arrays

Removing an array element or hash value which is 1) a container (hash or array),
and 2) was read-only I<will crash your application>. Perl will destroy the
container when it goes out of scope from your function. However, C<JSON::SL> will
continue to reference it inside its internal structures, so do not do this.

Adding a hash value/key to the hash is permitted, but the value may become
clobbered when and if an actual key-value pair is detected from the JSON input
stream.

I<Prepending> (i.e. C<unshift>ing) to an array is permitted. I<Appending>
(i.e. C<push>ing) to an array is only safe if you are sure that none of the
elements of the array are potential I<JSONPointer> query matches. JSONPointer
matches for array indices will internall pop the current (i.e. last) element
of the array and return it from L</feed>.

=back

=head2 OPTION GETTERS AND SETTERS

=head3 utf8()

=head3 utf8(boolean)

Get or set the current status of the C<SvUTF8> flag as it is applied to the strings
returned by C<JSON::SL>. If set to true, then input and output will be assumed to
be encoded in utf8

=head3 noqstr()

=head3 noqstr(boolean)

Get/Set whether the C<JSONPointer> field is populated in the hash returned by
L</feed>. Turning this on (i.e. leaving out the C<JSONPointer> field) may gain
some performance

=head3 nopath()

=head3 nopath(boolean)

Get/Set whether path information (the C<Path> field) is populated in the hash
returned by L</feed>. Turning this on (i.e. leaving out path information) may
boost performance, but will also leave you in the dark in regards to where/what
your object is.

=head3 max_size()

=head3 max_size(limit)

This functions exactly like L<JSON::XS>'s method of the same name.
To quote:

    Set the maximum length a JSON text may have (in bytes) where decoding is
    being attempted. The default is C<0>, meaning no limit. When C<decode>
    is called on a string that is longer then this many bytes, it will not
    attempt to decode the string but throw an exception.
    
    ...
    
    If no argument is given, the limit check will be deactivated (same as when
    C<0> is specified).

    See SECURITY CONSIDERATIONS in L<JSON::XS>, for more info on why this is useful.


=head3 object_drip(boolean)

As an alternative to using JSONPointer, you can use an 'object drip'. With this
setting enabled, all hashes and arrays will be returned via C<feed> or L<fetch>
in reverse order (i.e. the deepest objects are returned first, followed by
their encapsulated objects).

This allows you to inspect complete descendent objects as they arrive.

The objects returned by C<fetch> and C<feed> will still follow the same semantics,
with context/path information stored inside the C<Path> key. The C<JSONPointer>
field is obviously not passed since it is not being used.

Example:

    use JSON::SL;
    use Test::More;
    
    my $sl = JSON::SL->new();
    $sl->object_drip(1);
    
    # create an incomplete JSON object:
    
    my $json = <<'EOJ';
    [ [ { "key1":"foo", "key2":"bar", "key3":"baz" }
    EOJ
    
    my @res = $sl->feed($json);
    
    my $expected = [
        {
            Value => "foo",
            Path => '/0/0/key1',
        },
        {
            Value => "bar",
            Path => '/0/0/key2',
        },
        {
            Value => "baz",
            Path => '/0/0/key3'
        },
        {
            Value => {},
            Path => '/0/0'
        },
    ];
    
    is_deeply(\@res, $expected, "Got expected results for object drip...");


Outer encapsulating objects will have their children removed (as they have
already been returned in previous results).

Only I<complete> objects (i.e. objects which can no longer contain any more data)
will be returned.


=head2 UTILITY FUNCTIONS

These functions are not object methods but rather exported functions.
You may export them on demand or use their fully-qualified name

=head3 decode_json($json)

Decodes a JSON string and returns a Perl object. This really doesn't serve much
use, and L<JSON::XS> is faster than this. Nevertheless it eliminates the need
to use two modules if all you want to do is decode JSON.

=head3 unescape_json_string($string)

Unescapes a JSON string, translating C<\uXXXX> and other compliant escapes
to their actual character/byte representation. Returns the converted string,
undef if the input was empty. Dies on invalid input.

    my $str = "\\u0041";
    my $unescaped = unescape_json_string($str);
    # => "A"
    
Both L</decode_json> and L</feed> output already-unescaped strings, so there is
no need to call this function on strings returned by those methods.

=head1 BUGS & CAVEATS

=head2 Threads

This will most likely not work with threads, although one would wonder why
you would want to use this module across threads.

=head2 Object Trees

When inspecting the object tree, you may see some C<undef> values, and it
is impossible to determine whether those values are JSON C<null>s, or
placeholder values. It would be possible to implement a class e.g.
C<JSON::SL::Placeholder>, but doing so would either be unsafe or incur
additional overhead.


=head2 JSONPointer

The C<^> caret is somewhat obscure as a wildcard character

Currently wildcard matching is all-or-nothing, meaning that constructs such
as C<foo^> will not work.

=head2 Encodings

All input to C<JSON::SL> should be either UTF-8 or ASCII (a subset of UTF-8).

More specifically, the input stream must be any superset of ASCII which uses
octet streams (so this includes Latin1).

Perl itself only natively deals with 8-bit ASCII, Latin1, or UTF8 - so if your
input stream is something else (for example, UTF-16) it will need to be converted
to UTF8 some point in time before it is passed to C<JSON::SL>.

=head1 Speed

C<JSON::SL> aims to be the fastest JSON decoded for Perl. Currently it is only
in second place - being 25% slower than L<JSON::XS> for C<decode_json> and
about 8% slower for incremental parsing.

Additionally, if your input has lots of escapes (not very common in real-world
JSON), C<JSON::SL> will be even slower.

Nevertheless I believe that the benefits provided by JSON::SL save not only human
time, but also machine time - What good is quickly decoding a large JSON stream
if there are no proper facilities to inspect it?.

=head1 TODO

Work is in progress for a SAX-style interface.
See L<JSON::SL::Tuba>

=head1 SEE ALSO

L<JSON::XS> - Still faster than this module, and is also the source of many of
C<JSON::SL>'s ideas and tests.

If you wish to aid in the development of the JSON parser, do B<not> modify
the source files in the perl distribution, they are merely copied over from
here:

L<jsonsl|https://github.com/mnunberg/jsonsl> - C core for JSON::SL

L<JSON|http://www.json.org> - JSON's main page

L<JSON Specification|http://www.ietf.org/rfc/rfc4627.txt?number=4627>

L<JSONPointer Specification|http://tools.ietf.org/html/draft-pbryan-zyp-json-pointer-02>


L<JSON::SL::Tuba> - Same core with an event-oriented interface, like SAX

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2012 M. Nunberg

This module contains extracts from L<JSON::XS>, nevertheless they are both
licensed under the same terms as Perl itself.
