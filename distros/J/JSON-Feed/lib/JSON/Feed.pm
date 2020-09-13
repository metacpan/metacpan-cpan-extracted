package JSON::Feed;
our $VERSION = '1.001';
use Moo;
use namespace::clean;
use JSON qw<to_json from_json>;
use JSON::Feed::Types qw<JSONFeed JSONFeedItem>;

has feed => (
    is      => 'ro',
    default => sub {
        return +{
            version => "https://jsonfeed.org/version/1",
            title   => 'Untitle',
            items   => [],
        };
    },
    isa => JSONFeed,
);

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;
    return +{
        feed => +{
            version => "https://jsonfeed.org/version/1",
            items   => [],
            %args
        }
    };
};

sub get {
    my ( $self, $attr_name ) = @_;
    return $self->feed->{$attr_name};
}

sub set {
    my ( $self, $attr_name, $v ) = @_;
    return $self->feed->{$attr_name} = $v;
}

sub add_item {
    my ( $self, %item ) = @_;
    my $item = \%item;
    JSONFeedItem->assert_valid($item);
    push @{ $self->feed->{items} }, $item;
}

sub to_string {
    my ($self) = @_;
    my $feed = $self->feed;
    if (exists $feed->{expired}) {
        $feed->{expired} = $feed->{expired} ? JSON::true : JSON::false;
    }
    return to_json( $feed );
}

sub from_string {
    my ( $class, $text ) = @_;
    my $data = from_json($text);
    return $class->new( %$data );
}

1;

=head1 NAME

JSON::Feed - Syndication with JSON.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<JSON Feed|https://jsonfeed.org/> is a simple format for website syndication
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

=head1 METHODS

=over 4

=item set( $attr, $value )

The C<$attr> here must be a name from one top-level attribute
from L<v1 spec|https://jsonfeed.org/version/1>.

The passed C<$value> thus must be the corresponding value.

Most of the values from spec are strings and that maps to a perl scalar veraible.
The term `object` in the spec is mapped to a perl HashRef.

Be aware that the spec allows feed extensions by prefixng attributes with
underscore character. Thus, all strings begin with C<'_'> are valid. Whatever
those extented attributes mapped to are left as-is.

=item get( $attr )

Retrieve the value of the given top-level varible.

=item add_item( JSONFeedItem $item )

Apend the given C<$item> to the C<items> attribute. The type of input C<$item>
is described in the "Items" section of L<the spec|https://jsonfeed.org/version/1>.

=item to_string()

Stringify this JSON Feed. At this moment, the feed structure is checked and if
it is invalid, an exception is thrown.

=item from_string( $json_text )

Take a reference to a string that is assumed to be a valid json feed and
produce an object from it. Exception will be thrown if the input is not a
valid JSON feed.

This method is supposed to be consume the output of C<to_string> method
without throwing exceptions.

=back

=head1 References

JSON Feed spec v1 L<https://jsonfeed.org/version/1>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 LICENSE

CC0
