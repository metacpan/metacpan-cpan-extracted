package HTTP::StructuredField;

use v5.20;
use warnings;

use Hash::Ordered;
use HTTP::libsfparse qw( :index );
use Ref::Util qw( is_plain_arrayref );
use Sub::Util ();

use experimental qw( postderef signatures );

our $VERSION = 'v0.0.5';

# ABSTRACT: parse RFC 9651 HTTP Structured Fields

sub parse_item($class, $str) {
    my $self = HTTP::libsfparse::parse_item($str);
    bless $self, $class;
}


sub parse_dictionary( $class, $str) {
    my $list = HTTP::libsfparse::parse_dictionary($str);
    my $dict = Hash::Ordered->new( map { $_->[SFP_KEY] => bless $_->[SFP_ITEM], $class; } $list->@* );
    return $dict;
}


sub parse_list($class, $str) {
    my $list = HTTP::libsfparse::parse_list($str);
    return [ map { bless $_, $class } $list->@* ];
}


sub value($self) {
    if ( $self->is_inner_list ) {
        my $class = ref($self);
        return [ map { bless $_, $class } $self->[SFP_VALUE]->@* ];
    }
    else {
        return $self->[SFP_VALUE];
    }
}


sub params($self) {
    my $class = ref($self);
    my $list = $self->[SFP_PARAMS];
    my $params = Hash::Ordered->new( map { $_->[SFP_KEY] => bless $_->[SFP_ITEM], $class; } $list->@* );
    return $params;
}


sub has_params($self) {
    return ( $self->[SFP_PARAMS]->@* ) > 0;
}


sub type($self) {
    return $self->[SFP_TYPE];
}

{

    my %names;

    for my $name (@HTTP::libsfparse::TYPES) {

        no strict 'refs';

        my $fn   = "HTTP::libsfparse::${name}";
        my $code = $fn->();

        my ($suffix) = $name =~ /_((?:INNER_)?[A-Z]+)\z/a;
        my $method = "is_" . lc($suffix);

        *$method = Sub::Util::set_subname __PACKAGE__ . "::$method" => sub($self) { $self->type == $code };

        $names{$code} = lc($suffix);

    }

    sub type_name($self) {
        return $names{ $self->type };

    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::StructuredField - parse RFC 9651 HTTP Structured Fields

=head1 VERSION

version v0.0.1

=head1 SYNOPSIS

    use HTTP::StructuredField;

    try {

        my $dict = HTTP::StructuredField->parse_dictionary( $msg->header("signature-input") );
        for my $key ( $dist->keys ) {

            my $input = $dict->get($key);
            $input->is_inner_list or die "list expected";

            my @items = $input->value->@*;

      }


    }
    catch ($error) {
      ...
    }

=head1 DESCRIPTION

This is an object-oriented wrapper around L<HTTP::libsfparse>, for correctly parsing
L<RFC 9651|https://www.rfc-editor.org/info/rfc9651/> HTTP Structured Fields.

=head1 NAME

HTTP::StructuredField - parse RFC 9651 HTTP Structured Fields

=head1 METHODS

=head2 parse_item

This parses a string as an C<HTTP::StructuredField> item.

=head2 parse_dictionary

This parses a string as a dictionary.
The result is L<Hash::Ordered> object where the values are C<HTTP::StructuredField> items.

=head2 parse_list

This parses a string as a list.
The result is a list reference where the elements are C<HTTP::StructuredField> items.

=head2 value

This returns the value of the item.

=head2 params

This returns a L<Hash::Ordered> object of the item's parameters.
The values are C<HTTP::StructuredField> items.

=head2 has_params

This returns true if the item has L</params>.

=head2 type_name

The returns the name of the type as a short string.

=head2 type

This returns the numeric type id, which will correspond to one of the constants from L<HTTP::libsfparse>.

Generally you'll want to check the L</type_name> or use a predicate such as L</is_boolean>.

=head2 is_boolean

Returns true if the value is a boolean.

=head2 is_byteseq

Returns true if the value is a byte sequence.

=head2 is_decimal

Returns true if the value is a decimal number.

=head2 is_dispstring

Returns true if the value is a Unicode string, a.k.a. a display string.

Note that the value will be surrounded by double quotes, unless it is an element of an inner list or parameter value.

=head2 is_integer

Returns true if the value is an integer.

=head2 is_inner_list

Returns true if the value is an inner list.
The value will be an array reference to a list of unblessed items.

=head2 is_string

Returns true if the value is a 7-bit ASCII string.

Note that the value will be surrounded by double quotes, unless it is an element of an inner list or parameter value.

=head2 is_token

Returns true if the value is a token.

Tokens are short textual words that begin with an alphabetic character or "*", followed by zero to many token characters, which are the same as those allowed by the L<HTTP "token"|https://www.rfc-editor.org/info/rfc9110/#section-5.6.2> plus the ":" and "/" characters.


=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-HTTP-StructuredField>
and may be cloned from L<https://github.com/robrwo/perl-HTTP-StructuredField.git>

=head1 SUPPORT

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-HTTP-StructuredField/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

=head1 CONTRIBUTOR

Paul Johnson <paul@pjcj.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

  The MIT (X11) License

=cut
