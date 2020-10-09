=head1 NAME

Mac::PropertyList::SAX - work with Mac plists at a low level, fast

=cut

package Mac::PropertyList::SAX;

=head1 SYNOPSIS

See L<Mac::PropertyList|Mac::PropertyList>

=head1 DESCRIPTION

L<Mac::PropertyList|Mac::PropertyList> is useful, but very slow on large files
because it does XML parsing itself, intead of handing it off to a dedicated
parser. This module uses L<XML::SAX::ParserFactory|XML::SAX::ParserFactory> to
select a parser capable of doing the heavy lifting, reducing parsing time on
large files by a factor of 30 or more.

This module does not replace L<Mac::PropertyList|Mac::PropertyList>: it depends
on it for some package definitions and plist printing routines. You should,
however, be able to replace all C<use Mac::PropertyList>
lines with C<use Mac::PropertyList::SAX>, without changing anything else, and
notice an immediate improvement in performance on large input files.

Performance will depend largely on the parser that
L<XML::SAX::ParserFactory|XML::SAX::ParserFactory> selects for you. By default,
L<XML::SAX::Expat|XML::SAX::Expat> is used; to change the parser used, set the
environment variable C<MAC_PROPERTYLIST_SAX_PARSER> to a value accepted by
$XML::SAX::ParserPackage from
L<XML::SAX::ParserFactory|XML::SAX::ParserFactory> (or set
C<$XML::SAX::ParserPackage> directly).

=cut

use strict;
use warnings;

use Carp qw(carp);
use HTML::Entities qw(encode_entities_numeric);
use HTML::Entities::Numbered qw(hex2name name2hex_xml);
# Passthrough function
use Mac::PropertyList qw(plist_as_string);
use XML::SAX::ParserFactory;

use base qw(Exporter);

our @EXPORT_OK = qw(
    parse_plist 
    parse_plist_fh
    parse_plist_file
    parse_plist_string
    plist_as_string
    create_from_ref
    create_from_hash
    create_from_array
    create_from_string
);

our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    create => [ qw(create_from_ref create_from_hash create_from_array create_from_string plist_as_string) ],
    parse  => [ qw(parse_plist parse_plist_fh parse_plist_file parse_plist_string) ],
);

our $VERSION = '0.90';



=head1 CLASS VARIABLES

Class scoped variables that control the packages settings.

=over 4

=item ENCODE_ENTITIES

Allows the XHTML encoding of the data to be turned off. Default = C<1>

=item ENCODE_UNSAFE_CHARS

A Perl character class definition containing the only characters to be
XHTML encoded. See HTML::Entities::encode_entities for description of
the $unsafe_chars parameter. Default = C<undef>

=cut

our $ENCODE_ENTITIES     = 1;
our $ENCODE_UNSAFE_CHARS = undef;

=item OLD_BEHAVIOR

Restores the old behavior of double encoding output data. Default = C<0>

=cut

our $OLD_BEHAVIOR = 0;

=item XML::SAX::ParserPackage

Parser to use. Can also be set with environment variable
C<MAC_PROPERTYLIST_SAX_PARSER>. Default = C<"XML::SAX::Expat">

=cut

$XML::SAX::ParserPackage = $ENV{MAC_PROPERTYLIST_SAX_PARSER} || "XML::SAX::Expat";

=back

=head1 EXPORTS

By default, no functions are exported. Specify individual functions to export
as usual, or use the tags ':all', ':create', and ':parse' for the appropriate
sets of functions (':create' includes the create* functions as well as
plist_as_string; ':parse' includes the parse* functions).

=head1 FUNCTIONS

=over 4

=item parse_plist_file

See L<Mac::PropertyList/parse_plist_file>

=cut

sub parse_plist_file {
    my $file = shift;

    if (ref $file) {
        parse_plist_fh($file);
    } else {
        carp("parse_plist_file: file [$file] does not exist!"), return unless -e $file;
        _parse("parse_uri", $file);
    }
}

=item parse_plist_fh

See L<Mac::PropertyList/parse_plist_fh>

=cut

sub parse_plist_fh { _parse("parse_file", @_) }

=item parse_plist

See L<Mac::PropertyList/parse_plist>

=cut

sub parse_plist { _parse("parse_string", @_) }

=item parse_plist_string

An alias to parse_plist, provided for better regularity compared to Perl SAX.

=cut

*parse_plist_string = \&parse_plist;

sub _parse {
    # shift off first param in case we use `goto` later (leaving @_ with $data)
    my $sub = shift;
    my ($data) = @_;

    my $first;
    my $fh;
    my $delegate;

    # read initial bytes of file
    # if we have a binary plist, delegate to Mac::PropertyList
    if ($sub eq "parse_uri") {
        open $fh, "<", $_[0];
        $sub = "parse_file";
        $_[0] = $fh;
        # delegate will be set below
    }

    if ($sub eq "parse_file") {
        read $_[0], $first, length "bplist";
        seek $_[0], 0, 0 or die "Can't seek given filehandle"; # seek back to beginning
        $delegate = \&Mac::PropertyList::parse_plist_fh;
    } elsif ($sub eq "parse_string") {
        $first = $_[0];
        $delegate = \&Mac::PropertyList::parse_plist;
    }

    if ($first =~ /^bplist/) {
        # binary plist -- delegate to non-SAX module
        goto $delegate;
    } else {
        my $handler = Mac::PropertyList::SAX::Handler->new;
        XML::SAX::ParserFactory->parser(Handler => $handler)->$sub($data);

        return $handler->{struct};
    }
}

=item create_from_ref( HASH_REF | ARRAY_REF )

Create a plist from an array or hash reference.

The values of the hash can be simple scalars or references. Hash and array
references are handled recursively, and L<Mac::PropertyList|Mac::PropertyList> objects are output
correctly. All other scalars are treated as strings (use L<Mac::PropertyList|Mac::PropertyList>
objects to represent other types of scalars).

Returns a string representing the reference in serialized plist format.

=cut

sub create_from_ref {
    sub _handle_value {
        my ($val) = @_;

        sub _handle_hash {
            my ($hash) = @_;
            Mac::PropertyList::SAX::dict->write_open,
                (map { "\t$_" } map {
                    Mac::PropertyList::SAX::dict->write_key($OLD_BEHAVIOR ? _escape($_) : $_),
                    _handle_value($hash->{$_}) } keys %$hash),
                Mac::PropertyList::SAX::dict->write_close
        }

        sub _handle_array {
            my ($array) = @_;
            Mac::PropertyList::SAX::array->write_open,
                (map { "\t$_" } map { _handle_value($_) } @$array),
                Mac::PropertyList::SAX::array->write_close
        }

        # We could hand off serialization of all Mac::PropertyList::Item objects
        # but there is no 'write' method defined for it (though all its
        # subclasses have one). Let's just handle Scalars, which are safe.
           if (UNIVERSAL::can($val, 'write')) { $val->write }
        elsif (UNIVERSAL::isa($val,  'HASH')) { _handle_hash ($val) }
        elsif (UNIVERSAL::isa($val, 'ARRAY')) { _handle_array($val) }
        else { Mac::PropertyList::SAX::string->new($OLD_BEHAVIOR ? _escape($val) : $val)->write }
    }

    Mac::PropertyList::XML_head() .
        (join "\n", _handle_value(shift)) . "\n" .
        Mac::PropertyList::XML_foot();
}

=item create_from_hash( HASH_REF )

Provided for backward compatibility with L<Mac::PropertyList|Mac::PropertyList>: aliases
create_from_ref.

=cut

*create_from_hash = \&create_from_ref;

=item create_from_array( ARRAY_REF )

Provided for backward compatibility with L<Mac::PropertyList|Mac::PropertyList>: aliases
create_from_ref.

=cut

*create_from_array = \&create_from_ref;

=item create_from_string( STRING )

Provided for backward compatibility with L<Mac::PropertyList|Mac::PropertyList>: aliases C<Mac::PropertyList::create_from_string()>.

=cut

*create_from_string = \&Mac::PropertyList::create_from_string;

=item _escape( STRING )

B<Internal use only.> Escapes illegal characters into XML entities.

=cut

sub _escape {
    my $string = join("\n",grep(defined,@_));
    $ENCODE_ENTITIES && 
        return name2hex_xml(hex2name(encode_entities_numeric($string,
                                                             $ENCODE_UNSAFE_CHARS)));
    return $string;
}

package Mac::PropertyList::SAX::Handler;

use strict;
use warnings;
# State definitions
use enum qw(S_EMPTY S_TOP S_FREE S_DICT S_ARRAY S_KEY S_TEXT);

use Carp qw(carp croak);
use MIME::Base64;

# Element-name definitions
use constant +{ qw( ROOT  plist
                    KEY   key
                    DATA  data
                    DICT  dict
                    ARRAY array ) };

use base qw(XML::SAX::Base);

# From the plist DTD
our (%types, %simple_types, %complex_types, %numerical_types);
{
    my @complex_types   = (DICT, ARRAY);
    my @numerical_types = qw(real integer true false);
    my @simple_types    = qw(data date real integer string true false);
    my @types           = (@complex_types, @numerical_types, @simple_types);

    my $atoh = sub { map { $_ => 1 } @_ };

    %types           = $atoh->(@          types);
    %simple_types    = $atoh->(@   simple_types);
    %complex_types   = $atoh->(@  complex_types);
    %numerical_types = $atoh->(@numerical_types);
}

sub new {
    my %args = (
        accum   => "",
        context => S_EMPTY,
        key     => undef,
        stack   => [ ],
        struct  => undef,
    );

    shift->SUPER::new(%args, @_)
}

sub start_element {
    my $self = shift;
    my ($data) = @_;
    my $name = $data->{Name};

    # State transition definitions
         if ($self->{context} == S_EMPTY and $name eq ROOT) {
             $self->{context}  = S_TOP;
    } elsif ($self->{context} == S_TOP or $types{$name} or $name eq KEY) {
        push @{ $self->{stack} }, {
            key     => $self->{key},
            context => $self->{context},
            struct  => $self->{struct},
        };

        if ($complex_types{$name}) {
            $self->{struct} = "Mac::PropertyList::SAX::$name"->new;
            $self->{context} = eval "S_" . uc $name;
            delete $self->{key};
        }
        elsif ($simple_types{$name}) { $self->{context} = S_TEXT }
        elsif ($name eq KEY) {
            croak "<key/> in improper context $self->{context}" unless $self->{context} == S_DICT;
            $self->{context} = S_KEY;
        }
        else { croak "Top-level element '$name' in plist is not recognized" }
    } else {
        croak "Received invalid start element '$name'";
    }
}

sub end_element {
    my $self = shift;
    my ($data) = @_;
    my $name = $data->{Name};

    if ($name ne ROOT) { # Discard plist element
        my $elt = pop @{ $self->{stack} };

        my $value = $self->{struct};
        ($self->{struct}, $self->{key}, $self->{context}) = @{$elt}{qw(struct key context)};

        if ($simple_types{$name}) {
            # Wrap accumulated character data in an object
            $value = "Mac::PropertyList::SAX::$name"->new(
                exists $self->{accum}
                    ? $name eq DATA
                        ? MIME::Base64::decode_base64($self->{accum})
                        : $self->{accum}
                    : ""
                );

            delete $self->{accum};
        } elsif ($name eq KEY) {
            $self->{key} = $self->{accum};
            delete $self->{accum};
            return;
        }

           if ($self->{context} == S_DICT ) {         $self->{struct}{$self->{key}} = $value }
        elsif ($self->{context} == S_ARRAY) { push @{ $self->{struct} },              $value }
        elsif ($self->{context} == S_TOP  ) {         $self->{struct}               = $value }
        else { croak "Bad context $self->{context}" }
    }
}

sub characters {
    my $self = shift;
    my ($data) = @_;
    $self->{accum} .= $data->{Data} if $self->{context} == S_TEXT or $self->{context} == S_KEY;
}

# Convenient subclasses
package Mac::PropertyList::SAX::array;
use base qw(Mac::PropertyList::array);
package Mac::PropertyList::SAX::dict;
use base qw(Mac::PropertyList::dict);
sub write_key { "<key>" . (Mac::PropertyList::SAX::_escape($_[1]) || '') . "</key>" }
package Mac::PropertyList::SAX::Scalar;
use base qw(Mac::PropertyList::Scalar);
sub write {
    $_[0]->write_open .
        (Mac::PropertyList::SAX::_escape($_[0]->value) || '') .
            $_[0]->write_close
}
use overload '""' => sub { $_[0]->as_basic_data };
package Mac::PropertyList::SAX::date;
use base qw(Mac::PropertyList::date Mac::PropertyList::SAX::Scalar);
package Mac::PropertyList::SAX::real;
use base qw(Mac::PropertyList::real Mac::PropertyList::SAX::Scalar);
package Mac::PropertyList::SAX::integer;
use base qw(Mac::PropertyList::integer Mac::PropertyList::SAX::Scalar);
package Mac::PropertyList::SAX::string;
use base qw(Mac::PropertyList::string Mac::PropertyList::SAX::Scalar);
sub write { $_[0]->Mac::PropertyList::SAX::Scalar::write }
use overload '""' => sub { $_[0]->as_basic_data };
package Mac::PropertyList::SAX::data;
use base qw(Mac::PropertyList::data Mac::PropertyList::SAX::Scalar);
package Mac::PropertyList::SAX::Boolean;
use Object::MultiType;
use base qw(Mac::PropertyList::Boolean Object::MultiType);
use overload '""' => sub { shift->value };
sub new {
    my $class = shift;
    my ($type) = $class =~ /::([^:]+)$/;
    my $b = lc $type eq "true";
    bless Object::MultiType->new(scalar => $type, bool => $b) => $class
}
sub value { ${${$_[0]}->scalar} }
package Mac::PropertyList::SAX::true;
use base qw(Mac::PropertyList::SAX::Boolean Mac::PropertyList::true);
package Mac::PropertyList::SAX::false;
use base qw(Mac::PropertyList::SAX::Boolean Mac::PropertyList::true);

1;

__END__

=back

=head1 BUGS / CAVEATS

Any sane XML parser you can find to use with this module will decode
XHTML-encoded entities in the original property list;
L<Mac::PropertyList|Mac::PropertyList> doesn't touch them. Also, your XML
parser may convert accented/special characters into '\x{ff}' sequences; these
are preserved in their original encoding by
L<Mac::PropertyList|Mac::PropertyList>.

Before version 0.80 of this module, characters invalid in XML were not
serialized properly from create_from_ref(); before version 0.82, they were not
serialized properly in plist_as_string(). Thanks to Jon Connell for pointing
out these problems.

Unlike L<Mac::PropertyList|Mac::PropertyList> and old versions (< 0.60) of
Mac::PropertyList::SAX, this module does not trim leading and trailing
whitespace from plist elements. The difference in behavior is thought to be
rarely noticeable; in any case, I believe this module's current behavior is the
more correct. Any documentation that covers this problem would be appreciated.

The behavior of create_from_hash and create_from_array has changed: these
functions (which are really just aliases to the new create_from_ref function)
are now capable of recursively serializing complex data structures. That is:
for inputs that L<Mac::PropertyList|Mac::PropertyList>'s create_from_*
functions handled, the output should be the same, I<but> this module supports
inputs that L<Mac::PropertyList|Mac::PropertyList> does not.

Before version 0.83, this module left the selection of a SAX-based parser
entirely to the discretion of
L<XML::SAX::ParserFactory|XML::SAX::ParserFactory>. Unfortunately, it seems
impossible to guarantee that the parser returned even supports XML
(L<XML::SAX::RTF|XML::SAX::RTF> could be returned), so it has become necessary
to select a parser by default: L<XML::SAX::Expat|XML::SAX::Expat>, which is now
part of the dependencies of this module. If you know you will use another
parser of a specific name, you can force installation without
L<XML::SAX::Expat|XML::SAX::Expat> and always specify the parser you wish to
use by setting $XML::SAX::ParserPackage or the MAC_PROPERTYLIST_SAX_PARSER
environment variable (see L</"DESCRIPTION">).

Before version 0.85, this module contained a bug that caused double encoding of
special characters as X[HT]ML entities. Thanks to Bion Pohl and
L<http://ingz-inc.com/> for reporting this issue and supplying a fixed version.
The implementation of the C<$ENCODE_ENTITIES> variable and the addition of the
C<$ENCODE_UNSAFE_CHARS> variable are also due to Bion Pohl and / or
L<http://ingz-inc.com/>.

Before version 0.86, this module did not handle binary plists. Now it delegates
binary plists to L<Mac::PropertyList|Mac::PropertyList>, but if used with
filehandles, requires seekable streams (\*STDIN will work but only if it points
to a seekable file, rather than a pipe).

=head1 SUPPORT

Please contact the author with bug reports or feature requests.

=head1 AUTHOR

Darren M. Kulp, C<< <kulp @ cpan.org> >>

=head1 THANKS

brian d foy, who created the L<Mac::PropertyList|Mac::PropertyList> module
whose tests were appropriated for this module.

Bion Pohl and L<http://ingz-inc.com>, for bug report and patch submission.

=head1 SEE ALSO

L<Mac::PropertyList|Mac::PropertyList>, the inspiration for this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2017 by Darren Kulp

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

# vi: set et ts=4 sw=4: #
