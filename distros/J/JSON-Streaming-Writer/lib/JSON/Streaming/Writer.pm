
package JSON::Streaming::Writer;

use strict;
use warnings;
use IO::File;
use Carp;
use B;

use constant ROOT_STATE => {};

our $VERSION = '0.03';

sub for_stream {
    my ($class, $fh) = @_;

    my $self = bless {}, $class;

    $self->{fh} = $fh;
    $self->{state} = ROOT_STATE;
    $self->{state_stack} = [];
    $self->{used} = 0;
    $self->{pretty} = 0;
    $self->{indent_level} = 0;

    return $self;
}

sub for_file {
    my ($class, $filename) = @_;

    my $fh = IO::File->new($filename, O_WRONLY);
    return $class->for_stream($fh);
}

sub for_stdout {
    my ($class, $filename) = @_;

    return $class->for_stream(\*STDOUT);
}

sub pretty_output {
    my $self = shift;

    if (@_) {
        $self->{pretty} = $_[0] ? 1 : 0;
    }

    $self->{pretty};
}

sub start_object {
    my ($self) = @_;

    Carp::croak("Can't start_object here") unless $self->_can_start_value;

    $self->_make_separator();
    $self->_print("{");
    my $state = $self->_push_state();
    $state->{in_object} = 1;
    $self->_indent();
    return undef;
}

sub end_object {
    my ($self) = @_;

    Carp::croak("Can't end_object here: not in an object") unless $self->_in_object;
    $self->_outdent();
    $self->_make_end_block();
    $self->_pop_state();
    $self->_print("}");
    $self->_print("\n") if $self->_state == ROOT_STATE && $self->pretty_output;

    $self->_state->{made_value} = 1 unless $self->_state == ROOT_STATE;
}

sub start_property {
    my ($self, $name) = @_;

    Carp::croak("Can't start_property here") unless $self->_can_start_property;

    $self->_make_separator();
    my $state = $self->_push_state();
    $state->{in_property} = 1;
    $self->_print($self->_json_string($name), ":");
}

sub end_property {
    my ($self) = @_;

    Carp::croak("Can't end_property here: not in a property") unless $self->_in_property;
    Carp::croak("Can't end_property here: haven't generated a value") unless $self->_made_value;

    $self->_pop_state();
    $self->_state->{made_value} = 1;

    # end_property requires no output
}

sub start_array {
    my ($self) = @_;

    Carp::croak("Can't start_array here") unless $self->_can_start_value;

    $self->_make_separator();
    $self->_print("[");
    my $state = $self->_push_state();
    $self->_indent();
    $state->{in_array} = 1;
    return undef;
}

sub end_array {
    my ($self) = @_;

    Carp::croak("Can't end_array here: not in an array") unless $self->_in_array;
    $self->_outdent();
    $self->_make_end_block();
    $self->_pop_state();
    $self->_print("]");
    $self->_print("\n") if $self->_state == ROOT_STATE && $self->pretty_output;

    $self->_state->{made_value} = 1 unless $self->_state == ROOT_STATE;
}

sub add_string {
    my ($self, $value) = @_;

    Carp::croak("Can't add_string here") unless $self->_can_start_simple_value;

    $self->_make_separator();
    $self->_print($self->_json_string($value));
    $self->_state->{made_value} = 1;
}

sub add_number {
    my ($self, $value) = @_;

    Carp::croak("Can't add_number here") unless $self->_can_start_simple_value;

    $self->_make_separator();
    $self->_print($value+0);
    $self->_state->{made_value} = 1;
}

sub add_boolean {
    my ($self, $value) = @_;

    Carp::croak("Can't add_boolean here") unless $self->_can_start_simple_value;

    $self->_make_separator();
    $self->_print($value ? 'true' : 'false');
    $self->_state->{made_value} = 1;
}

sub add_null {
    my ($self) = @_;

    Carp::croak("Can't add_null here") unless $self->_can_start_simple_value;

    $self->_make_separator();
    $self->_print('null');
    $self->_state->{made_value} = 1;
}

sub add_value {
    my ($self, $value) = @_;

    my $type = ref($value);

    if (! defined($value)) {
        $self->add_null();
    }
    elsif (! $type) {
        my $b_obj = B::svref_2object(\$value);
        my $flags = $b_obj->FLAGS;

        if (($flags & B::SVf_IOK or $flags & B::SVp_IOK or $flags & B::SVf_NOK or $flags & B::SVp_NOK) and !($flags & B::SVf_POK )) {
            $self->add_number($value);
        }
        else {
            $self->add_string($value);
        }
    }
    elsif ($type eq 'ARRAY') {
        $self->start_array();
        foreach my $item (@$value) {
            $self->add_value($item);
        }
        $self->end_array();
    }
    elsif ($type eq 'HASH') {
        $self->start_object();
        foreach my $k (sort keys %$value) {
            $self->add_property($k, $value->{$k});
        }
        $self->end_object();
    }
    elsif ($type eq 'SCALAR') {
        if ($$value eq '1') {
            $self->add_boolean(1);
        }
        elsif ($$value eq '0') {
            $self->add_boolean(0);
        }
        else {
            Carp::croak("Don't know what to generate for $value");
        }
    }
    else {
        Carp::croak("Don't know what to generate for $value");
    }
}

sub add_property {
    my ($self, $key, $value) = @_;

    $self->start_property($key);
    $self->add_value($value);
    $self->end_property();
}

sub intentionally_ending_early {
    my ($self) = @_;
    $self->{intentionally_ending_early} = 1;
}

sub _print {
    my ($self, @data) = @_;

    $self->{fh}->print(join('', @data));
}

sub _push_state {
    my ($self) = @_;

    Carp::croak("Can't add anything else: JSON output is complete") if $self->_state == ROOT_STATE && $self->{used};

    $self->{used} = 1;

    push @{$self->{state_stack}}, $self->{state};

    $self->{state} = {
        in_object => 0,
        in_array => 0,
        in_property => 0,
        made_value => 0,
    };

    return $self->{state};
}

sub _pop_state {
    my ($self) = @_;

    my $state = pop @{$self->{state_stack}};
    return $self->{state} = $state;
}

sub _state {
    my ($self) = @_;

    return $self->{state};
}

sub _in_object {
    return $_[0]->_state->{in_object} ? 1 : 0;
}

sub _in_array {
    return $_[0]->_state->{in_array} ? 1 : 0;
}

sub _in_property {
    return $_[0]->_state->{in_property} ? 1 : 0;
}

sub _made_value {
    return $_[0]->_state->{made_value} ? 1 : 0;
}

sub _can_start_value {

    return 0 if $_[0]->_in_property && $_[0]->_made_value;

    return $_[0]->_in_object ? 0 : 1;
}

sub _can_start_simple_value {
    # Can't generate simple values in the root state
    return $_[0]->_can_start_value && $_[0]->_state != ROOT_STATE;
}

sub _can_start_property {
    return $_[0]->_in_object ? 1 : 0;
}

sub _make_separator {
    $_[0]->_print(",") if $_[0]->_made_value;
    if ($_[0]->pretty_output) {
        if ($_[0]->_in_property) {
            $_[0]->_print(" ");
        }
        else {
            $_[0]->_print("\n");
            $_[0]->_make_indent();
        }
    }
}

sub _make_end_block {
    return unless $_[0]->pretty_output;

    if ($_[0]->_made_value) {
        $_[0]->_print("\n");
        $_[0]->_make_indent();
    }
}

sub _make_indent {
    $_[0]->_print("    " x $_[0]->{indent_level});
}

sub _indent {
    $_[0]->{indent_level}++;
}

sub _outdent {
    $_[0]->{indent_level}--;
}

my %esc = (
    "\n" => '\n',
    "\r" => '\r',
    "\t" => '\t',
    "\f" => '\f',
    "\b" => '\b',
    "\"" => '\"',
    "\\" => '\\\\',
    "\'" => '\\\'',
);
sub _json_string {
    my ($class, $value) = @_;

    $value =~ s/([\x22\x5c\n\r\t\f\b])/$esc{$1}/eg;
    $value =~ s/\//\\\//g;
    $value =~ s/([\x00-\x08\x0b\x0e-\x1f])/'\\u00' . unpack('H2', $1)/eg;

    return '"'.$value.'"';
}

sub DESTROY {
    my ($self) = @_;

    if ($self->_state != ROOT_STATE && ! $self->{intentionally_ending_early}) {
        warn "JSON::Streaming::Writer object was destroyed with incomplete output";
    }
}

1;

=head1 NAME

JSON::Streaming::Writer - Generate JSON output in a streaming manner

=head1 SYNOPSIS

    my $jsonw = JSON::Streaming::Writer->for_stream($fh)
    $jsonw->start_object();
    $jsonw->add_simple_property("someName" => "someValue");
    $jsonw->add_simple_property("someNumber" => 5);
    $jsonw->start_property("someObject");
    $jsonw->start_object();
    $jsonw->add_simple_property("someOtherName" => "someOtherValue");
    $jsonw->add_simple_property("someOtherNumber" => 6);
    $jsonw->end_object();
    $jsonw->end_property();
    $jsonw->start_property("someArray");
    $jsonw->start_array();
    $jsonw->add_simple_item("anotherStringValue");
    $jsonw->add_simple_item(10);
    $jsonw->start_object();
    # No items; this object is empty
    $jsonw->end_object();
    $jsonw->end_array();

=head1 DESCRIPTION

Most JSON libraries work in terms of in-memory data structures. In Perl,
JSON serializers often expect to be provided with a HASH or ARRAY ref
containing all of the data you want to serialize.

This library allows you to generate syntactically-correct JSON without
first assembling your complete data structure in memory. This allows
large structures to be returned without requiring those
structures to be memory-resident, and also allows parts of the output
to be made available to a streaming-capable JSON parser while
the rest of the output is being generated, which may improve
performance of JSON-based network protocols.

=head1 RAW API

The raw API allows the caller precise control over the generated
data structure by providing explicit methods for each fundamental JSON
construct.

As a general rule, methods with names starting with C<start_> and C<end_>
methods wrap a multi-step construct and must be used symmetrically, while
methods with names starting with C<add_> stand alone and generate output
in a single step.

The raw API methods are described below

=head2 start_object, end_object

These methods delimit a JSON object. C<start_object> can be called
as the first method call on a writer object to produce a top-level
object, or it can be called in any state where a value is expected
to produce a nested object.

JSON objects contain properties, so only property-related methods
may be used while in the context of an object.

=head2 start_array, end_array

These methods delimit a JSON array. C<start_array> can be called
as the first method call on a writer object to produce a top-level
array, or it can be called in any state where a value is expected
to produce a nested array.

JSON arrays contain properties, so only value-producing methods
may be used while in the context of an array.

=head2 start_property($name), end_property

These methods delimit a property or member of a JSON object.
C<start_property> may be called only when in the context of an
object. The C<$name> parameter, a string, gives the name that
the generated property will have.

Only value-producing methods may be used while in the context
of a property.

Since a property can contain only one value, only a single
value-producing method may be called between a pair of
C<start_property> and C<end_property> calls.

=head2 add_string($value)

Produces a JSON string with the given value.

=head2 add_number($value)

Produces a JSON number whose value is Perl's numeric interpretation of the given value.

=head2 add_boolean($value)

Produces a JSON boolean whose value is Perl's boolean interpretation of the given value.

=head2 add_null

Produces a JSON C<null>.

=head1 DWIM API

The DWIM API allows you to provide normal Perl data structures and have the library
figure out a sensible JSON representation for them. You can mix use of the raw
and DWIM APIs to allow you to exercise fine control where required but use
a simpler API for normal cases.

=head2 add_value($value)

Produces a JSON value representing the given Perl value. This library can handle
Perl strings, integers (i.e. scalars that have most recently been used as numbers),
references to the values 0 and 1 representing booleans and C<undef> representing
a JSON C<null>. It can also accept ARRAY and HASH refs that contain such values
and produce JSON array and object values recursively, much like a non-streaming
JSON producer library would do.

This method is a wrapper around the corresponding raw API calls, so the error
messages it generates will often refer to the underlying raw API.

=head2 add_property($name, $value)

Produces a property inside a JSON object whose value is derived from the provided
value using the same mappings as used by C<add_value>. This can only be used
inside the context of an object, and is really just a wrapper around a C<start_property>,
C<add_value>, C<end_property> sequence for convenience.

=head1 OPTIONS

=head2 Pretty Output

This library can optionally pretty-print the JSON string it produces. To enable this,
call the C<pretty_output> method with a true value as its first argument.

You can enable and disable pretty-printing during output, though if you do the
results are likely to be sub-optimal as the additional whitespace may not be
generated where you'd expect. In particular, where the whitespace is generated
may change in future versions.

=head1 INTERNALS

Internally this library maintains a simple state stack that allows
it to remember where it is without needing to remember the data
it has already generated.

The state stack means that it will use more memory for deeper
data structures.

=head1 LICENSE

Copyright 2009 Martin Atkins <mart@degeneration.co.uk>.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
