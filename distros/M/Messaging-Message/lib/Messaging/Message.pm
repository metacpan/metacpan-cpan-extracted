#+##############################################################################
#                                                                              #
# File: Messaging/Message.pm                                                   #
#                                                                              #
# Description: abstraction of a message                                        #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Messaging::Message;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.25 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Encode qw(encode decode FB_CROAK LEAVE_SRC);
use JSON qw();
use MIME::Base64 qw(encode_base64 decode_base64);
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate validate_pos :types);

#
# global variables
#

our(
    %_LoadedModule,        # hash of successfully loaded modules
    %_CompressionModule,   # known compression modules
    $_CompressionAlgos,    # known compression algorithms
    $_JSON,                # JSON object
);

%_CompressionModule = (
    "lz4"    => "LZ4",
    "snappy" => "Snappy",
    "zlib"   => "Zlib",
);
$_CompressionAlgos = join("|", sort(keys(%_CompressionModule)));
$_JSON = JSON->new();

#+++############################################################################
#                                                                              #
# helper functions                                                             #
#                                                                              #
#---############################################################################

#
# make sure a module is loaded
#

sub _require ($) {
    my($module) = @_;

    return if $_LoadedModule{$module};
    eval("require $module"); ## no critic 'ProhibitStringyEval'
    if ($@) {
        $@ =~ s/\s+at\s.+?\sline\s+\d+\.?$//;
        dief("failed to load %s: %s", $module, $@);
    } else {
        $_LoadedModule{$module} = 1;
    }
}

#
# evaluate some code with fatal warnings
#

sub _eval ($&;$) {
    my($what, $code, $arg) = @_;

    eval {
        local $SIG{__WARN__} = sub { die($_[0]) };
        $code->($arg);
    };
    return unless $@;
    $@ =~ s/\s+at\s.+?\sline\s+\d+\.?$//;
    dief("%s failed: %s", $what, $@);
}

#
# helpers for body encoding and compression
#

sub _maybe_base64_encode ($) {
    my($object) = @_;

    return unless $object->{"body"} =~ /[^\t\n\r\x20-\x7e]/;
    # only if it contains more than printable ASCII characters (plus \t \n \r)
    _eval("Base64 encoding", sub {
        $object->{"body"} = encode_base64($object->{"body"}, "");
    });
    $object->{"encoding"}{"base64"}++;
}

sub _maybe_utf8_encode ($) {
    my($object) = @_;
    my($tmp);

    _eval("UTF-8 encoding", sub {
        $tmp = encode("UTF-8", $object->{"body"}, FB_CROAK|LEAVE_SRC);
    });
    return if $tmp eq $object->{"body"};
    $object->{"body"} = $tmp;
    $object->{"encoding"}{"utf8"}++;
}

sub _do_compress ($$) {
    my($object, $algo) = @_;
    my($compress, $tmp);

    $compress = \&{"Compress::$_CompressionModule{$algo}::compress"};
    _eval("$_CompressionModule{$algo} compression", sub {
        $tmp = $compress->(\$object->{"body"});
    });
    $object->{"body"} = $tmp;
    $object->{"encoding"}{$algo}++;
}

#+++############################################################################
#                                                                              #
# object oriented interface                                                    #
#                                                                              #
#---############################################################################

#
# normal constructor
#

my %new_options = (
    "header" => {
        type => HASHREF,
        callbacks => {
            "hash of strings" =>
                sub { grep(!defined($_)||ref($_), values(%{$_[0]})) == 0 },
        },
        optional => 1,
    },
    "body" => {
        type => SCALAR,
        optional => 1,
    },
    "body_ref" => {
        type => SCALARREF,
        optional => 1,
    },
    "text" => {
        type => BOOLEAN,
        optional => 1,
    },
);

sub new : method {
    my($class, %option, $body, $self);

    $class = shift(@_);
    %option = validate(@_, \%new_options) if @_;
    dief("new(): options body and body_ref are mutually exclusive")
        if exists($option{"body"}) and exists($option{"body_ref"});
    # default message
    $body = "";
    $self = { "header" => {}, "body_ref" => \$body, "text" => 0 };
    # handle options
    $self->{"header"} = $option{"header"}     if exists($option{"header"});
    $self->{"body_ref"} = $option{"body_ref"} if exists($option{"body_ref"});
    $self->{"body_ref"} = \$option{"body"}    if exists($option{"body"});
    $self->{"text"} = $option{"text"} ? 1 : 0 if exists($option{"text"});
    # so far so good!
    bless($self, $class);
    return($self);
}

#
# normal accessors
#

sub header : method {
    my($self);

    $self = shift(@_);
    return($self->{"header"}) if @_ == 0;
    validate_pos(@_, $new_options{"header"});
    $self->{"header"} = $_[0];
    return($self);
}

sub body_ref : method {
    my($self);

    $self = shift(@_);
    return($self->{"body_ref"}) if @_ == 0;
    validate_pos(@_, $new_options{"body_ref"})
        unless @_ == 1 and defined($_[0]) and ref($_[0]) eq "SCALAR";
    $self->{"body_ref"} = $_[0];
    return($self);
}

sub text : method {
    my($self);

    $self = shift(@_);
    return($self->{"text"}) if @_ == 0;
    validate_pos(@_, $new_options{"text"})
        unless @_ == 1 and (not defined($_[0]) or ref($_[0]) eq "");
    $self->{"text"} = $_[0] ? 1 : 0;
    return($self);
}

#
# extra accessors
#

sub header_field : method {
    my($self);

    $self = shift(@_);
    if (@_ >= 1 and defined($_[0]) and ref($_[0]) eq "") {
        return($self->{"header"}{$_[0]}) if @_ == 1;
        if (@_ == 2 and defined($_[1]) and ref($_[1]) eq "") {
            $self->{"header"}{$_[0]} = $_[1];
            return($self);
        }
    }
    # so far so bad :-(
    validate_pos(@_, { type => SCALAR }, { type => SCALAR, optional => 1 });
}

sub body : method {
    my($self, $body);

    $self = shift(@_);
    return(${ $self->{"body_ref"} }) if @_ == 0;
    validate_pos(@_, $new_options{"body"})
        unless @_ == 1 and defined($_[0]) and ref($_[0]) eq "";
    $body = $_[0]; # copy
    $self->{"body_ref"} = \$body;
    return($self);
}

#
# extra methods
#

sub copy : method {
    my($self, %header, $body, $copy);

    $self = shift(@_);
    validate_pos(@_) if @_;
    %header = %{ $self->{"header"} }; # copy
    $body = ${ $self->{"body_ref"} }; # copy
    $copy = {
        "header"   => \%header,
        "body_ref" => \$body,
        "text"     => $self->{"text"},
    };
    bless($copy, ref($self));
    return($copy);
}

sub size : method {
    my($self, $size, $key, $value);

    $self = shift(@_);
    validate_pos(@_) if @_;
    $size = 1 + length(${ $self->{"body_ref"} });
    while (($key, $value) = each(%{ $self->{"header"} })) {
        $size += 2 + length($key) + length($value);
    }
    return($size);
}

#+++############################################################################
#                                                                              #
# (de)jsonification                                                            #
#                                                                              #
#---############################################################################

#
# jsonify (= transform into a JSON object)
#

my %jsonify_options = (
    "compression" => {
        type     => SCALAR,
        regex    => qr/^($_CompressionAlgos)?!?$/o,
        optional => 1,
    },
);

sub _jsonify_text ($$$$$) {
    my($self, $object, $algo, $force, $len) = @_;

    if ($algo and $force) {
        # always compress
        _maybe_utf8_encode($object);
        _do_compress($object, $algo);
        _maybe_base64_encode($object);
    } elsif ($algo and $len > 255) {
        # maybe compress
        _maybe_utf8_encode($object);
        _do_compress($object, $algo);
        _maybe_base64_encode($object);
        if (length($object->{"body"}) >= $len) {
            # not worth it
            $object->{"body"} = ${ $self->{"body_ref"} };
            delete($object->{"encoding"});
        }
    } else {
        # do not compress
    }
}

sub _jsonify_binary ($$$$$) {
    my($self, $object, $algo, $force, $len) = @_;

    if ($algo and $force) {
        # always compress
        _do_compress($object, $algo);
        _maybe_base64_encode($object);
    } elsif ($algo and $len > 255) {
        # maybe compress
        $len *= 4/3 if $object->{"body"} =~ /[^\t\n\r\x20-\x7e]/;
        _do_compress($object, $algo);
        _maybe_base64_encode($object);
        if (length($object->{"body"}) >= $len) {
            # not worth it
            $object->{"body"} = ${ $self->{"body_ref"} };
            delete($object->{"encoding"});
            _maybe_base64_encode($object);
        }
    } else {
        # do not compress
        _maybe_base64_encode($object);
    }
}

sub jsonify : method {
    my($self, %option, %object, $algo, $force, $len);

    $self = shift(@_);
    %option = validate(@_, \%jsonify_options) if @_;
    if ($option{"compression"} and $option{"compression"} =~ /^(\w+)(!?)$/) {
        ($algo, $force) = ($1, $2);
    }
    # check compression availability
    _require("Compress::$_CompressionModule{$algo}") if $algo;
    # build the JSON object
    $object{"text"} = JSON::true if $self->{"text"};
    $object{"header"} = $self->{"header"} if keys(%{ $self->{"header"} });
    $len = length(${ $self->{"body_ref"} });
    return(\%object) unless $len;
    $object{"body"} = ${ $self->{"body_ref"} };
    # handle non-empty body
    if ($self->{"text"}) {
        # text body
        _jsonify_text($self, \%object, $algo, $force, $len);
    } else {
        # binary body
        _jsonify_binary($self, \%object, $algo, $force, $len);
    }
    # set the encoding string
    $object{"encoding"} = join("+", sort(keys(%{ $object{"encoding"} })))
        if $object{"encoding"};
    # so far so good!
    return(\%object);
}

#
# dejsonify (= alternate constructor using the JSON object)
#

my %dejsonify_options = (
    "header" => $new_options{"header"},
    "body" => {
        type => SCALAR,
        optional => 1,
    },
    "text" => {
        type => OBJECT,
        callbacks => {
            "JSON::is_bool" => sub { JSON::is_bool($_[0]) },
        },
        optional => 1,
    },
    "encoding" => {
        type => SCALAR,
        optional => 1,
    },
);

sub dejsonify : method {
    my($class, $object, $encoding, $self, $tmp, $len, $uncompress);

    $class = shift(@_);
    validate_pos(@_, { type => HASHREF })
        unless @_ == 1 and defined($_[0]) and ref($_[0]) eq "HASH";
    validate(@_, \%dejsonify_options);
    $object = $_[0];
    $encoding = $object->{"encoding"} || "";
    dief("invalid encoding: %s", $encoding)
        unless $encoding eq ""
            or "${encoding}+" =~ /^((base64|utf8|$_CompressionAlgos)\+)+$/o;
    _require("Compress::$_CompressionModule{$1}")
        if $encoding =~ /($_CompressionAlgos)/o;
    # construct the message
    $self = $class->new();
    $self->{"text"} = 1 if $object->{"text"};
    $self->{"header"} = $object->{"header"}
        if $object->{"header"} and keys(%{ $object->{"header"} });
    if (exists($object->{"body"})) {
        $tmp = $object->{"body"};
        if ($encoding =~ /base64/) {
            # body has been Base64 encoded, compute length to detect unexpected
            # characters (this is because MIME::Base64 silently ignores them)
            $len = length($tmp);
            dief("invalid Base64 data: %s", $object->{"body"}) if $len % 4;
            $len = $len * 3 / 4;
            $len -= substr($tmp, -2) =~ tr/=/=/;
            _eval("Base64 decoding", sub {
                $tmp = decode_base64($tmp);
            });
            dief("invalid Base64 data: %s", $object->{"body"})
                unless $len == length($tmp);
        }
        if ($encoding =~ /($_CompressionAlgos)/o) {
            # body has been compressed
            $uncompress = \&{"Compress::$_CompressionModule{$1}::uncompress"};
            _eval("$_CompressionModule{$1} decompression", sub {
                $tmp = $uncompress->(\$tmp);
            });
            dief("invalid $_CompressionModule{$1} compressed data!")
                unless defined($tmp);
        }
        if ($encoding =~ /utf8/) {
            # body has been UTF-8 encoded
            _eval("UTF-8 decoding", sub {
                $tmp = decode("UTF-8", $tmp, FB_CROAK);
            });
        }
        $self->{"body_ref"} = \$tmp;
    }
    # so far so good!
    return($self);
}

#+++############################################################################
#                                                                              #
# (de)stringification                                                          #
#                                                                              #
#---############################################################################

#
# stringify (= transform into a text string)
#

sub stringify : method {
    my($self, $tmp);

    $self = shift(@_);
    $tmp = $self->jsonify(@_);
    _eval("JSON encoding", sub {
        $tmp = $_JSON->encode($tmp);
    });
    return($tmp);
}

sub stringify_ref : method {
    my($self, $tmp);

    $self = shift(@_);
    $tmp = $self->jsonify(@_);
    _eval("JSON encoding", sub {
        $tmp = $_JSON->encode($tmp);
    });
    return(\$tmp);
}

#
# destringify (= alternate constructor using the stringified representation)
#

sub destringify : method {
    my($class, $tmp);

    $class = shift(@_);
    validate_pos(@_, { type => SCALAR })
        unless @_ == 1 and defined($_[0]) and ref($_[0]) eq "";
    _eval("JSON decoding", sub {
        $tmp = $_JSON->decode(${ $_[0] });
    }, \$_[0]);
    return($class->dejsonify($tmp));
}

sub destringify_ref : method {
    my($class, $tmp);

    $class = shift(@_);
    validate_pos(@_, { type => SCALARREF })
        unless @_ == 1 and defined($_[0]) and ref($_[0]) eq "SCALAR";
    _eval("JSON decoding", sub {
        $tmp = $_JSON->decode(${ $_[0] });
    }, $_[0]);
    return($class->dejsonify($tmp));
}

#+++############################################################################
#                                                                              #
#  (de)serialization                                                           #
#                                                                              #
#---############################################################################

#
# serialize (= transform into a binary string)
#

sub serialize : method {
    my($self, $tmp);

    $self = shift(@_);
    $tmp = $self->stringify_ref(@_);
    _eval("UTF-8 encoding", sub {
        $tmp = encode("UTF-8", ${ $tmp }, FB_CROAK);
    });
    return($tmp);
}

sub serialize_ref : method {
    my($self, $tmp);

    $self = shift(@_);
    $tmp = $self->stringify_ref(@_);
    _eval("UTF-8 encoding", sub {
        $tmp = encode("UTF-8", ${ $tmp }, FB_CROAK);
    });
    return(\$tmp);
}

#
# deserialize (= alternate constructor using the serialized representation)
#

sub deserialize : method {
    my($class, $tmp);

    $class = shift(@_);
    validate_pos(@_, { type => SCALAR })
        unless @_ == 1 and defined($_[0]) and ref($_[0]) eq "";
    return($class->destringify($_[0])) unless $_[0] =~ /[^[:ascii:]]/;
    _eval("UTF-8 decoding", sub {
        $tmp = decode("UTF-8", ${ $_[0] }, FB_CROAK|LEAVE_SRC);
    }, \$_[0]);
    return($class->destringify($tmp));
}

sub deserialize_ref : method {
    my($class, $tmp);

    $class = shift(@_);
    validate_pos(@_, { type => SCALARREF })
        unless @_ == 1 and defined($_[0]) and ref($_[0]) eq "SCALAR";
    return($class->destringify_ref($_[0])) unless ${ $_[0] } =~ /[^[:ascii:]]/;
    _eval("UTF-8 decoding", sub {
        $tmp = decode("UTF-8", ${ $_[0] }, FB_CROAK|LEAVE_SRC);
    }, $_[0]);
    return($class->destringify($tmp));
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    %exported = ("_require" => 1);
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

Messaging::Message - abstraction of a message

=head1 SYNOPSIS

  use Messaging::Message;

  # constructor + setters
  $msg = Messaging::Message->new();
  $msg->body("hello world");
  $msg->header({ subject => "test" });
  $msg->header_field("message-id", 123);

  # fancy constructor
  $msg = Messaging::Message->new(
      body => "hello world",
      header => {
          "subject"    => "test",
          "message-id" => 123,
      },
  );

  # getters
  if ($msg->body() =~ /something/) {
      ...
  }
  $id = $msg->header_field("message-id");

=head1 DESCRIPTION

This module provides an abstraction of a "message", as used in messaging,
see for instance:
L<http://en.wikipedia.org/wiki/Enterprise_messaging_system>.

A Python implementation of the same messaging abstractions is available at
L<https://github.com/cern-mig/python-messaging> so messaging components can
be written in different programming languages.

A message consists of header fields (collectively called "the header
of the message") and a body.

Each header field is a key/value pair where the key and the value are
text strings. The key is unique within the header so we can use a hash
table to represent the header of the message.

The body is either a text string or a binary string. This distinction
is needed because text may need to be encoded (for instance using
UTF-8) before being stored on disk or sent across the network.

To make things clear:

=over

=item *

a I<text string> (aka I<character string>) is a sequence of Unicode
characters

=item *

a I<binary string> (aka I<byte string>) is a sequence of bytes

=back

Both the header and the body can be empty.

=head1 JSON MAPPING

In order to ease message manipulation (e.g. exchanging between
applications, maybe written in different programming languages), we
define here a standard mapping between a Messaging::Message object and
a JSON object.

A message as defined above naturally maps to a JSON object with the
following fields:

=over

=item header

the message header as a JSON object (with all values being JSON
strings)

=item body

the message body as a JSON string

=item text

a JSON boolean specifying whether the body is text string (as opposed
to binary string) or not

=item encoding

a JSON string describing how the body has been encoded (see below)

=back

All fields are optional and default to empty/false if not present.

Since JSON strings are text strings (they can contain any Unicode
character), the message header directly maps to a JSON object. There
is no need to use encoding here.

For the message body, this is more complex. A text body can be put
as-is in the JSON object but a binary body must be encoded beforehand
because JSON does not handle binary strings. Additionally, we want to
allow body compression in order to optionally save space. This is
where the encoding field comes into play.

The encoding field describes which transformations have been applied
to the message body. It is a C<+> separated list of transformations
that can be:

=over

=item C<base64>

Base64 encoding (for binary body or compressed body)

=item C<utf8>

UTF-8 encoding (only needed for a compressed text body)

=item C<lz4> or C<snappy> or C<zlib>

LZ4 or Snappy or Zlib compression (only one can be specified)

=back

Here is for instance the JSON object representing an empty message
(i.e. the result of Messaging::Message->new()):

  {}

Here is a more complex example, with a binary body:

  {
    "header":{"subject":"demo","destination":"/topic/test"},
    "body":"YWJj7g==",
    "encoding":"base64"
  }

You can use the jsonify() method to convert a Messaging::Message
object into a hash reference representing the equivalent JSON object.

Conversely, you can create a new Messaging::Message object from a
compatible JSON object (again, a hash reference) with the dejsonify()
method.

Using this JSON mapping of messages is very convenient because you can
easily put messages in larger JSON data structures. You can for
instance store several messages together using a JSON array of these
messages.

Here is for instance how you could construct a message containing in
its body another message along with error information:

  use JSON qw(to_json);
  # get a message from somewhere...
  $msg1 = ...;
  # jsonify it and put it into a simple structure
  $body = {
      message => $msg1->jsonify(),
      error   => "an error message",
      time    => time(),
  };
  # create a new message with this body
  $msg2 = Messaging::Message->new(body => to_json($body));
  $msg2->header_field("content-type", "message/error");
  $msg2->text(1);

A receiver of such a message can easily decode it:

  use JSON qw(from_json);
  # get a message from somewhere...
  $msg2 = ...;
  # extract the body which is a JSON object
  $body = from_json($msg2->body());
  # extract the inner message
  $msg1 = Messaging::Message->dejsonify($body->{message});

=head1 STRINGIFICATION AND SERIALIZATION

In addition to the JSON mapping described above, we also define how to
stringify and serialize a message.

A I<stringified message> is the string representing its equivalent
JSON object. A stringified message is a text string and can for
instance be used in another message. See the stringify() and
destringify() methods.

A I<serialized message> is the UTF-8 encoding of its stringified
representation. A serialized message is a binary string and can for
instance be stored in a file. See the serialize() and deserialize()
methods.

For instance, here are the steps needed in order to store a message
into a file:

=over

=item 1

transform the programming language specific abstraction of the message
into a JSON object

=item 2

transform the JSON object into its (text) string representing

=item 3

transform the JSON text string into a binary string using UTF-8
encoding

=back

"1" is called I<jsonify>, "1 + 2" is called I<stringify> and "1 + 2 +
3" is called I<serialize>.

To sum up:

        Messaging::Message object
                 |  ^
       jsonify() |  | dejsonify()
                 v  |
    JSON compatible hash reference
                 |  ^
     JSON encode |  | JSON decode
                 v  |
             text string
                 |  ^
    UTF-8 encode |  | UTF-8 decode
                 v  |
            binary string

=head1 METHODS

The following methods are available:

=over

=item new([OPTIONS])

return a new Messaging::Message object (class method)

=item dejsonify(HASHREF)

return a new Messaging::Message object from a compatible JSON object
(class method)

=item destringify(STRING)

return a new Messaging::Message object from its stringified representation
(class method)

=item deserialize(STRING)

return a new Messaging::Message object from its serialized representation
(class method)

=item jsonify([OPTIONS])

return the JSON object (a hash reference) representing the message

=item stringify([OPTIONS])

return the text string representation of the message

=item serialize([OPTIONS])

return the binary string representation of the message

=item body([STRING])

get/set the body attribute, which is a text or binary string

=item header([HASHREF])

get/set the header attribute, which is a hash reference
(note: the hash reference is used directly, without any deep copy)

=item header_field(NAME[, VALUE])

get/set the given header field, identified by its name

=item text([BOOLEAN])

get/set the text attribute, which is a boolean indicating whether the
message body is a text string or not, the default is false (so binary
body)

=item size()

get the approximate message size, which is the sum of the sizes of its
components: header key/value pairs and body, plus framing

=item copy()

return a new message which is a copy of the given one, with deep copy
of the header and body

=back

The jsonify(), stringify() and serialize() methods can be given options.

Currently, the only supported option is C<compression> and it can
contain either an algorithm name like C<zlib> (meaning: use this
algorithm only of the compressed body is indeed smaller) or an
algorithm name followed by an exclamation mark to always force
compression.

Here is for instance how to serialize a message, with forced
compression:

  $bytes = $msg->serialize(compression => "zlib!");

In addition, in order to avoid string copies, the following methods
are also available:

=over

=item body_ref([STRINGREF])

=item stringify_ref([OPTIONS])

=item destringify_ref(STRINGREF)

=item serialize_ref([OPTIONS])

=item deserialize_ref(STRINGREF)

=back

They work like their counterparts but use as input or output string
references instead of strings, which can be more efficient for large
strings. Here is an example:

  # get a copy of the body, yielding to internal string copy
  $body = $msg->body();
  # get a reference to the body, with no string copies
  $body_ref = $msg->body_ref();

=head1 SEE ALSO

L<Compress::Snappy>,
L<Compress::LZ4>,
L<Compress::Zlib>,
L<Encode>,
L<JSON>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2021
