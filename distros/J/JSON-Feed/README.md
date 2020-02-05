[![Build Status](https://travis-ci.org/gugod/JSON-Feed.svg?branch=master)](https://travis-ci.org/gugod/JSON-Feed) [![Coverage Status](http://codecov.io/github/gugod/JSON-Feed/coverage.svg?branch=master)](https://codecov.io/github/gugod/JSON-Feed?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/JSON-Feed.svg)](https://metacpan.org/release/JSON-Feed)
# NAME

JSON::Feed - Syndication with JSON.

# SYNOPSIS

Parsing:

    JSON::Feed->from_string( $json_text );

Generating:

    # Initialize, with some content.
    my $feed = JSON::Feed->new(
        title    => "An example of JSON feed",
        feed_url => "https://example.com/feed.json",
        items    => [
            +{
                id => 42,
                url => 'https://example.com/item/42',
                summary => 'An item with some summary',
                date_published: "2019-03-06T09:24:03+09:00"
            },
            +{
                id => 623,
                url => 'https://example.com/item/623',
                summary => 'An item with some summary',
                date_published: "2019-03-07T06:22:51+09:00"
            },
        ]
    );

    # Mutate
    $feed->set( description => 'Some description here.' );
    $feed->add_item(
        id => 789,
        title => "Another URL-less item here",
        summary => "Another item here. Lorem ipsum yatta yatta yatta.",
    );

    # Output
    print $fh $feed->to_string;

# DESCRIPTION

[JSON Feed](https://jsonfeed.org/) is a simple format for website syndication
with JSON, instead of XML.

This module implements minimal amout of API for parsing and/or generating such
feeds. The users of this module should glance over the jsonfeed spec in order
to correctly generate a JSON::Feed.

Here's a short but yet comprehensive Type mapping between jsonfeed spec and
perl.

    | jsonfeed | perl                       |
    |----------+----------------------------|
    | object   | HashRef                    |
    | boolean  | JSON::true, or JSON::false |
    | string   | Str                        |
    | array    | ArrayRef                   |

# METHODS

- set( $attr, $value )

    The `$attr` here must be a name from one top-level attribute
    from [v1 spec](https://jsonfeed.org/version/1).

    The passed `$value` thus must be the corresponding value.

    Most of the values from spec are strings and that maps to a perl scalar veraible.
    The term \`object\` in the spec is mapped to a perl HashRef.

    Be aware that the spec allows feed extensions by prefixng attributes with
    underscore character. Thus, all strings begin with `'_'` are valid. Whatever
    those extented attributes mapped to are left as-is.

- get( $attr )

    Retrieve the value of the given top-level varible.

- add\_item( JSONFeedItem $item )

    Apend the given `$item` to the `items` attribute. The type of input `$item`
    is described in the "Items" section of [the spec](https://jsonfeed.org/version/1).

- to\_string()

    Stringify this JSON Feed. At this moment, the feed structure is checked and if
    it is invalid, an exception is thrown.

- from\_string( $json\_text )

    Take a reference to a string that is assumed to be a valid json feed and
    produce an object from it. Exception will be thrown if the input is not a
    valid JSON feed.

    This method is supposed to be consume the output of `to_string` method
    without throwing exceptions.

# References

JSON Feed spec v1 [https://jsonfeed.org/version/1](https://jsonfeed.org/version/1)

# AUTHOR

Kang-min Liu <gugod@gugod.org>

# LICENSE

CC0
