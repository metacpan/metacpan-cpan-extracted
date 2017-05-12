package Google::Data::JSON;

use warnings;
use strict;

use version; our $VERSION = qv('0.1.10');

use File::Slurp;
use JSON::Any;
use List::MoreUtils qw( any uniq );
use Perl6::Export::Attrs;
use Storable qw(dclone);
use UNIVERSAL::require;
use XML::Simple;

## XML::Simple
my $CONFIG = {
    XMLin => {
	KeepRoot     => 1,
	ContentKey   => '$t',
	KeyAttr      => [],
	ForceArray   => 0,
	ForceContent => 1,
    },
    XMLout => {
	KeepRoot     => 1,
	ContentKey   => '$t',
	KeyAttr      => [],
	XMLDecl      => '<?xml version="1.0" encoding="utf-8"?>',
	NoSort       => 1,
    }
};

use vars qw( $ERROR );

sub error {
    my $msg = $_[1] || '';
    $msg .= "\n" unless $msg =~ /\n$/;
    if (ref($_[0])) {
        $_[0]->{_errstr} = $msg;
    } else {
        $ERROR = $msg;
    }
    return;
}

sub errstr { ref($_[0]) ? $_[0]->{_errstr} : $ERROR }

sub new {
    my $class  = shift;
    my ($type, $stream);
    if (@_ > 1) {
        ($type, $stream) = @_;
        if ($type eq 'file') {
            $stream = read_file $stream;
            $type = get_type_as_dwim($stream);
        }
    }
    else {
        warn 'DWIM-style constructor is DEPRECATED';
        ($stream) = @_;
        $stream = read_file $stream if $stream !~ /[\r\n]/ && -f $stream;
        $type = get_type_as_dwim($stream);
    }
    return __PACKAGE__->error("Bad type: $type")
        unless $type eq 'xml' || $type eq 'json' || $type eq 'hash' || $type eq 'atom';
    return __PACKAGE__->error("Bad stream: $type => $stream")
        if ($type eq 'xml'  && $stream !~ /^</)
        || ($type eq 'json' && $stream !~ /^\{/)
        || ($type eq 'hash' && !UNIVERSAL::isa($stream, 'HASH'))
        || ($type eq 'atom' && !UNIVERSAL::isa($stream, 'XML::Atom::Base'));
    bless { $type => $stream }, $class;
}

sub get_type_as_dwim {
    my ($stream) = @_;
    return UNIVERSAL::isa($stream, 'XML::Atom::Base') ? 'atom'
         : UNIVERSAL::isa($stream, 'HASH')            ? 'hash'
         : $stream  =~ /^\{/                          ? 'json'
         : $stream  =~ /^</                           ? 'xml'
         : __PACKAGE__->error("Bad stream: $stream");
}

sub gdata :Export { __PACKAGE__->new(@_) }

sub as_xml {
    my $self = shift;
    if ( $self->{xml} ) {
	return $self->{xml};
    }
    elsif ( $self->{atom} ) {
	return $self->{xml} = atom_to_xml( $self->{atom} );
    }
    elsif ( $self->{hash} ) {
	return $self->{xml} = hash_to_xml( $self->{hash} );
    }
    elsif ( $self->{json} ) {
	$self->{hash} = json_to_hash( $self->{json} );
	return $self->{xml} = hash_to_xml( $self->{hash} );
    }
}

sub as_atom {
    my $self = shift;
    if ( $self->{atom} ) {
	return $self->{atom};
    }
    elsif ( $self->{xml} ) {
	return $self->{atom} = xml_to_atom( $self->{xml} );
    }
    elsif ( $self->{hash} ) {
	$self->{xml} = hash_to_xml( $self->{hash} );
	return $self->{atom} = xml_to_atom( $self->{xml} );
    }
    elsif ( $self->{json} ) {
	$self->{hash} = json_to_hash( $self->{json} );
	$self->{xml} = hash_to_xml( $self->{hash} );
	return $self->{atom} = xml_to_atom( $self->{xml} );
    }
}

sub as_hash {
    my $self = shift;
    if ( $self->{hash} ) {
	return $self->{hash};
    }
    elsif ( $self->{json} ) {
	return $self->{hash} = json_to_hash( $self->{json} );
    }
    elsif ( $self->{xml} ) {
	return $self->{hash} = xml_to_hash( $self->{xml} );
    }
    elsif ( $self->{atom} ) {
	$self->{xml} = atom_to_xml( $self->{atom} );
	return $self->{hash} = xml_to_hash( $self->{xml} );
    }
}

sub as_json {
    my $self = shift;
    if ( $self->{json} ) {
	return $self->{json};
    }
    elsif ( $self->{hash} ) {
	return $self->{json} = hash_to_json( $self->{hash} );
    }
    elsif ( $self->{xml} ) {
	$self->{hash} = xml_to_hash( $self->{xml} );
	return $self->{json} = hash_to_json( $self->{hash} );
    }
    elsif ( $self->{atom} ) {
	$self->{xml} = atom_to_xml( $self->{atom} );
	$self->{hash} = xml_to_hash( $self->{xml} );
	return $self->{json} = hash_to_json( $self->{hash} );
    }
}

sub xml_to_atom :Export { 
    my ($xml) = shift;
    my ($root) = $xml =~ /<\?xml[^>]+?\?>\s*<(?:\w+:)?(\w+)/ms;
    my $module = 'XML::Atom::' . ucfirst($root);
    "$module"->require or return __PACKAGE__->error($@);
    return $module->new(\$xml);
}

sub xml_to_hash :Export { fix_ns( XMLin( $_[0], %{ $CONFIG->{XMLin} } ) ) }

sub xml_to_json :Export { hash_to_json( xml_to_hash(@_) ) }

sub atom_to_xml :Export { $_[0]->as_xml }

sub atom_to_hash :Export { xml_to_hash( atom_to_xml(@_) ) }

sub atom_to_json :Export { xml_to_json( atom_to_xml(@_) ) }

sub hash_to_xml :Export { XMLout( fix_ns2(dclone $_[0]), %{ $CONFIG->{XMLout} } ) }

sub hash_to_atom :Export { xml_to_atom( hash_to_xml(@_) ) }

sub hash_to_json :Export { JSON::Any->objToJson( $_[0] ) }

sub json_to_xml :Export { hash_to_xml( json_to_hash(@_) ) }

sub json_to_atom :Export { hash_to_atom( json_to_hash(@_) ) }

sub json_to_hash :Export { JSON::Any->jsonToObj( $_[0] ) }

sub as_hashref {
    warn 'as_hashref is DEPRECATED and renamed to as_hash';
    $_[0]->as_hash;
}

sub xml_to_hashref :Export {
    warn 'xml_to_hashref is DEPRECATED and renamed to xml_to_hash';
    xml_to_hash(@_);
}

sub atom_to_hashref :Export {
    warn 'xml_to_hashref is DEPRECATED and renamed to atom_to_hash';
    atom_to_hash(@_);
}

sub json_to_hashref :Export {
    warn 'xml_to_hashref is DEPRECATED and renamed to json_to_hash';
    json_to_hash(@_);
}

sub fix_ns {
    my ($h) = shift;
    for my $k (keys %$h) {
        if (UNIVERSAL::isa($h->{$k}, 'HASH')) {
            $h->{$k} = fix_ns($h->{$k});
        }
        elsif (UNIVERSAL::isa($h->{$k}, 'ARRAY')) {
            $h->{$k} = [ map fix_ns($_), @{ $h->{$k} } ];
        }
        if ($k =~ /(.+):(.+)/) {
            $h->{"$1\$$2"} = $h->{$k};
            delete $h->{$k};
        }
    }
    return $h;
}

sub fix_ns2 {
    my ($h) = shift;
    for my $k (keys %$h) {
        if (UNIVERSAL::isa($h->{$k}, 'HASH')) {
            $h->{$k} = fix_ns2($h->{$k});
        }
        elsif (UNIVERSAL::isa($h->{$k}, 'ARRAY')) {
            $h->{$k} = [ map fix_ns2($_), @{ $h->{$k} } ];
        }
        if ($k =~ /(.+)\$(.+)/) {
            $h->{"$1:$2"} = $h->{$k};
            delete $h->{$k};
        }
    }
    return $h;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Google::Data::JSON - General XML-JSON converter based on Google Data APIs


=head1 SYNOPSIS

    use Google::Data::JSON;

    ## Convert an XML document into a JSON and a Perl HASH.
    $gdata = Google::Data::JSON->new(xml => $xml);
    $json  = $gdata->as_json;
    $hash  = $gdata->as_hash;

    ## Convert a JSON into an XML document and an Atom object.
    $gdata = Google::Data::JSON->new(json => $json);
    $xml   = $gdata->as_xml;
    $atom  = $gdata->as_atom;

=head1 DESCRIPTION

B<Google::Data::JSON> provides several methods to convert an XML feed 
into a JSON feed, and vice versa. The JSON format is defined in Google 
Data APIs, http://code.google.com/apis/gdata/json.html .

This module is not restricted to Atom Feed.
Any XML documents can be converted into JSON-format, and vice versa.

The following rules are described in Google Data APIs:

=head2 Basic

- The feed is represented as a JSON object; each nested element or attribute 
is represented as a name/value property of the object.

- Attributes are converted to String properties.

- Child elements are converted to Object properties.

- Elements that may appear more than once are converted to Array properties.

- Text values of tags are converted to $t properties.

=head2 Namespace

- If an element has a namespace alias, the alias and element are concatenated 
using "$". For example, ns:element becomes ns$element.

=head2 XML

- XML version and encoding attributes are converted to attribute version and 
encoding of the root element, respectively.


=head1 METHODS

=head2 Google::Data::JSON->new($type => $stream)

Creates a new parser object from I<$stream> of I<$type>,
and returns the new Google::Data::JSON object.
On failure, return "undef";

I<$type> must be one of the followings:

=over 4

=item xml

I<$stream> must be a string containing XML.

=item json

I<$stream> must be a string containing JSON.

=item atom

I<$stream> must be an XML::Atom object, such as XML::Atom::Feed,
XML::Atom::Entry, XML::Atom::Service, and XML::Atom::Categories.

=item hash

I<$stream> must be a Perl hash referece, strictly saying,
that is a reference to a data structure combined with HASH and ARRAY.

=item file

I<$stream> must be a filename of XML or JSON.

=back

=head2 gdata($stream or type => $stream)

Shortcut for Google::Data::JSON->new(...).

=head2 $gdata->as_xml

Converts into a string of XML.

=head2 $gdata->as_json

Converts into a string of JSON.

=head2 $gdata->as_atom

Converts into an XML::Atom object.

=head2 $gdata->as_hash

Converts into a Perl HASH.

=head2 $gdata->as_hashref

DEPRECATED

=head2 Google::Data::JSON->errstr or $gdata->errstr

Returns an error message.


=head1 INTERNAL METHODS

=head2 error($message)

=head2 get_type_as_dwim($stream)

=head2 xml_to_json($xml)

=head2 xml_to_atom($xml)

=head2 xml_to_hash($xml)

=head2 json_to_xml($json)

=head2 json_to_atom($json)

=head2 json_to_hash($json)

=head2 atom_to_xml($atom)

=head2 atom_to_json($atom)

=head2 atom_to_hash($atom)

=head2 hash_to_xml($hash)

=head2 hash_to_json($hash)

=head2 hash_to_atom($hash)

=head2 atom_to_hashref

DEPRECATED

=head2 json_to_hashref

DEPRECATED

=head2 xml_to_hashref

DEPRECATED

=head2 fix_ns($hash)

=head2 fix_ns2($hash)

=head1 EXPORT

None by default.

=head1 EXAMPLE OF XML and JSON

The following example shows XML and JSON versions of the same document:

=head2 XML

    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom"
          xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
      <title>Test Feed</title>
      <id>tag:example.com,2007:1</id>
      <updated>2007-01-01T00:00:00Z</updated>
      <link rel="self" href="http://example.com/feed.atom"/>
      <openSearch:startIndex>1</openSearch:startIndex>
      <entry>
        <title>Test Entry 1</title>
        <id>tag:example.com,2007:2</id>
        <updated>2007-02-01T00:00:00Z</updated>
        <published>2007-02-01T00:00:00Z</published>
        <link rel="alternate" href="http://example.com/1"/>
        <link rel="edit" href="http://example.com/edit/1"/>
        <author>
          <name>Foo</name>
          <email>foo@example.com</email>
        </author>
        <content type="xhtml">
          <div xmlns="http://www.w3.org/1999/xhtml">
            <span>Test 1</span>
          </div>
        </content>
      </entry>
      <entry>
        <title>Test Entry 2</title>
        <id>tag:example.com,2007:3</id>
        <updated>2007-03-01T00:00:00Z</updated>
        <published>2007-03-01T00:00:00Z</published>
        <link rel="alternate" href="http://example.com/2"/>
        <link rel="edit" href="http://example.com/edit/2"/>
        <author>
          <name>Bar</name>
          <email>bar@example.com</email>
        </author>
        <content type="xhtml">
          <div xmlns="http://www.w3.org/1999/xhtml">
            <span>Test 2</span>
          </div>
        </content>
      </entry>
    </feed>

=head2 JSON

    {
      "feed" : {
        "xmlns" : "http://www.w3.org/2005/Atom",
        "xmlns$openSearch" : "http://a9.com/-/spec/opensearchrss/1.0/",
        "title" : {
          "$t" : "Test Feed"
        },
        "id" : {
          "$t" : "tag:example.com,2007:1"
        },
        "updated" : {
          "$t" : "2007-01-01T00:00:00Z"
        },
        "link" : {
          "rel" : "self",
          "href" : "http://example.com/feed.atom"
        },
        "openSearch$startIndex" : {
          "$t" : "1"
        },
        "entry" : [
          {
            "published" : {
              "$t" : "2007-02-01T00:00:00Z"
            },
            "link" : [
              {
                "rel" : "alternate",
                "href" : "http://example.com/1"
              },
              {
                "rel" : "edit",
                "href" : "http://example.com/edit/1"
              }
            ],
            "content" : {
              "div" : {
                "xmlns" : "http://www.w3.org/1999/xhtml",
                "span" : {
                  "$t" : "Test 1"
                }
              },
              "type" : "xhtml"
            },
            "title" : {
              "$t" : "Test Entry 1"
            },
            "id" : {
              "$t" : "tag:example.com,2007:2"
            },
            "updated" : {
              "$t" : "2007-02-01T00:00:00Z"
            },
            "author" : {
              "email" : {
                "$t" : "foo@example.com"
              },
              "name" : {
                "$t" : "Foo"
              }
            }
          },
          {
            "published" : {
              "$t" : "2007-03-01T00:00:00Z"
            },
            "link" : [
              {
                "rel" : "alternate",
                "href" : "http://example.com/2"
              },
              {
                "rel" : "edit",
                "href" : "http://example.com/edit/2"
              }
            ],
            "content" : {
              "div" : {
                "xmlns" : "http://www.w3.org/1999/xhtml",
                "span" : {
                  "$t" : "Test 2"
                }
              },
              "type" : "xhtml"
            },
            "title" : {
              "$t" : "Test Entry 2"
            },
            "id" : {
              "$t" : "tag:example.com,2007:3"
            },
            "updated" : {
              "$t" : "2007-03-01T00:00:00Z"
            },
            "author" : {
              "email" : {
                "$t" : "bar@example.com"
              },
              "name" : {
                "$t" : "Bar"
              }
            }
          }
        ]
      }
    }

=head1 SEE ALSO

L<XML::Atom>

=head1 AUTHOR

Takeru INOUE  C<< <takeru.inoue _ gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

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

=cut
