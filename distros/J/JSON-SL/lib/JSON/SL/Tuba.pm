package JSON::SL::Tuba;
use strict;
use warnings;
use JSON::SL;
use base qw(Exporter);
our @EXPORT;

my (%ActionMap,%TypeMap);
my $_cg_typehash;
my $_cg_modehash;

BEGIN {
    %ActionMap = (
    '+' => 'start',
    '-' => 'end',
    '>' => 'on'
    );
    %TypeMap = (
    '{' => 'object',
    '[' => 'list',
    'c' => 'data',
    'D' => 'json',
    '#' => 'key',
    '"' => 'string',
    '^' => 'special',
    '?' => 'boolean',
    '=' => 'number',
    '~' => 'null'
    );

    while (my ($sym,$name) = each %ActionMap) {
        $_cg_modehash->{uc($name)} = ord($sym);
    }
    while (my ($sym,$name) = each %TypeMap) {
        $_cg_typehash->{uc($name)} = ord($sym);
    }
}

use Constant::Generate $_cg_typehash, prefix => "TUBA_TYPE_", export => 1;
use Constant::Generate $_cg_modehash, prefix => "TUBA_MODE_", export =>1;

our %CloseTokens = (
    '{' => '}',
    '"' => '"',
    '[' => ']'
);

sub new {
    my ($cls,%options) = @_;
    my $o = $cls->_initialize();
    
    unless (exists $options{accum_kv} and
        not delete $options{accum_kv}) {
        $o->accum_kv(1);
    }
    unless (exists $options{accum_all}and
        not delete $options{accum_all}) {
        $o->accum_all(1);
    }
    while (my ($k,$v) = each %options) {
        $o->can($k)->($o,$v);
    }
    return $o;
}

# TODO: I can't think why I've hidden this?
{
    no warnings 'once';
    *parse = *_parse;
}

# set accumulator parameters:
sub accum {
    my ($tuba,%modes) = @_;
    while (my ($mode,$bool) = each %modes) {
        if ($mode !~ m{[\=\~\?\#"]}) {
            die("Invalid mode '$mode'. Mode must be one of [^#\"]");
        }
        $tuba->_ax_opt(ord("$mode"), $bool);
    }
}

sub accum_enabled_for {
    my ($tuba,$mode) = @_;
    if ($mode !~ m{[\=\~\?\#"]}) {
        die("Invalid type '$mode'. Mode must be one of [^#\"]");
    }
    return $tuba->_ax_opt(ord("$mode"))
}

sub accum_all {
    my ($tuba,$boolean) = @_;
    if (@_ != 2) {
        die("Must have boolean argument!");
    }
    my %opts = map {
        $_, $boolean
    } ('=','~','#','?','"');
    $tuba->accum(%opts);
}

#build convenience methods:
foreach (['key', '#'],
         ['string', '"'],
         ['number', '='],
         ['boolean', '?'],
         ['null', '~']
         ) {

    my ($mode,$sym) = @$_;
    no strict 'refs';
    *{"accum_$mode"} = sub {
        my ($tuba,$bool) = @_;
        $tuba->_ax_opt(ord($sym), $bool);
    }
}

1;

__END__


=head1 NAME

JSON::SL::Tuba - High performance SAX-like interface for JSON

=head1 SYNOPSIS

Create a very naive JSON encoder using JSON::SL::Tuba

    my $JSON ||= <<'EOJ';
    {
    "a" : "b",
    "c" : { "d" : "e" },
    "f" : [ "g", "h", "i", "j" ],
    "a number" : 0.4444444444,
    "a (false) boolean": false,
    "another (true) boolean" : true,
    "a null value" : null,
    "exponential" : 1.3413400E4,
    "an\tescaped key" : "a u-\u0065\u0073caped value", "שלום":"להראות"
    }
    EOJ

    # Split the 'stream' into multiple chunks to demonstrate the streaming
    # feature:
    my @Chunks = unpack("a(8)*", $JSON);

    # Make a subclass and set up the methods..

    package A::Giant::Tuba;
    use base qw(JSON::SL::Tuba);

    sub on_any {
        my ($tuba,$info,$data) = @_;

        #use constant comparisons
        if ($info->{Type} == TUBA_TYPE_JSON) {
            printf STDERR ("JSON DOCUMENT: %c\n\n", $info->{Mode});
            return;
        }

        # or use the mnemonic ones
        if ($info->{Key} && $info->{Mode} =~ m,[>\+],) {
            printf ('"%s" : ', $info->{Key});
        }

        if ($info->{Type} == TUBA_TYPE_STRING) {
            printf('"%s",' . "\n", $data || "<NO DATA>");

        } elsif ($info->{Type} =~ m,[\[\{],) {
            if ($info->{Mode} eq '+') {
                print $info->{Type} . "\n";
            } else {

                print $JSON::SL::Tuba::CloseTokens{$info->{Type}} . ",\n";
            }
        } else {
            if (defined $data) {
                print $data . ",\n"
            } else {
                die ("hrrm.. what have we here?")
                    unless $info->{Type} == TUBA_TYPE_NULL;
                print "null,\n";
            }
        }
    }

    my $o = My::Giant::Tuba->new();
    $o->parse($_) for @Chunks;

Output:

    JSON DOCUMENT: +

    {
    "a" : b,
    "c" : {
    "d" : e,
    },
    "f" : [
    g,
    h,
    i,
    j,
    ],
    "a number" : 0.4444444444,
    "a (false) boolean" : 0,
    "another (true) boolean" : 1,
    "a null value" : null
    "exponential" : 13413.4,
    "an	escaped key" : a u-escaped value,
    "שלום" : להראות,
    },
    JSON DOCUMENT: -

=head1 DESCRIPTION

C<JSON::SL::Tuba> provides an event-based and high performance SAX-like interface
for parsing streaming JSON.

Emphasis when designing C<JSON::SL::Tuba> was the reduction of boilerplate (the
author does not have favorable experiences with SAX APIs) and high performance.

This uses the same core JSON functionality and speed as L<JSON::SL>.

To use C<JSON::SL::Tuba>, simply inherit from it and define one or more
methods to be called when a parse event occurs.

In normal cases (and this is the default), only a single method (see below)
needs to be implemented to be able to receive events.

Of course, if your application requirements are more complex, Tuba is able
to deliver you events to the resolution of a single character.

=head2 CALLBACK ARGUMENTS AND TERMINOLOGY

These are the list of methods which to implement. All methods follow a single
unified calling convention in the form of

    callback($tuba, $info, $data);

where C<$tuba> is the C<JSON::SL::Tuba> instance, C<$info> is a hash reference
containing metadata about the item for which the event was received, and C<$data>
contains the actual 'data' (if applicable)

=head3 Info Hash

This hash contains metadata for determining relevant information about the current
item.

The hash and all its contents are read-only. Their contents are not valid after
the callback returns (see L</CAVEATS>). This is for both performance and
sanity reasons.
    

Its keys and values are as follows

=over

=item C<Type>

This is the type of JSON object for which an event was received.

The following table represents a table of type constants, and their mnemonic
symbols. The value to this key itself is a double-typed scalar which yields either
the character or the numeric value depending on the context.

    Constant            Mnemonic Symbol     Description
    
    === Scalar Types ===
    TUBA_TYPE_STRING        "               "string" value
    TUBA_TYPE_KEY           #               hash key
    TUBA_TYPE_BOOLEAN       ?               JSON boolean atom ('true','false')
    TUBA_TYPE_NUMBER        =               number
    TUBA_TYPE_NULL          ~               JSON 'null' atom
    
    === Container Types ===
    TUBA_TYPE_OBJECT        {               hash (JSON 'object')
    TUBA_TYPE_LIST          [               array (JSON 'list')
    
    === Pseudo Types ===
    TUBA_TYPE_JSON          D               the entire stream
    TUBA_TYPE_SPECIAL       ^               non-string scalar
    TUBA_TYPE_DATA          c               any scalar data
    
    
=item Mode

This is the 'mode' of the callback. The mode is also a magical mnemomic constant
similar to the type.

I use the term I<element> to mean any kind of JSON variable/object - i.e.
anything listed in the above type table.

    Constant            Mnemonic Symbol     Description
    
    TUBA_MODE_START         +               the start of an element
    TUBA_MODE_END           -               completion of an element
    TUBA_MODE_ON            >               data (contents) of an element
    
    
By default, the behavior is as follows:

Complex type events (new hash, new list) are delivered as C<START> events. When
they complete, C<END> events are provided

For Scalar types, the C<START> and C<END> callbacks are not delivered, but their
contents internally accumulated and delivered in whole via a single C<ON> callback.

Almost every aspect of this is entirely configurable, and these are just (what
I hope) sane defaults.


=item Key

By default, keys are not delivered as their own events, but rather attached
to this field for the values which succeed them.

This field, if present, will contain the JSON key.

Only valid if the parent object is a hash.

See the C<accum_kv> option below for a way to make keys be delivered as their
own events.

=item Index

Like key, but instead of a string key, this is a numeric index. Indexes are
never delivered as explicit events (since they are inherently implicit entities).

Only valid if parent object is a list.

=item Escaped

This is a boolean flag. Set to true if the current string needs escaping. This is
never set unless string events are delivered incrementally.

=back

=head3 Data

Nothing much to say here. This is the pure 'data' associated with the callback.

For C<ON>-style callbacks, this will contain a complete string/number/key (the
default), or fragment thereof.

By default, strings are unescaped and numeric formats converted to their Perl
equivalent when they cannot be easily stringified.

Complex (non-scalar) objects will never receive an C<ON>-style callback.

C<START> and C<STOP> callbacks never have any data, either.


=head3 CALLBACKS

If you've read the above section, then the names of the callbacks to be delivered
are relatively consistent.

=over

=item on_any

This is the default and catch-all callback for all events. The subsequent callbacks
in the list do not offer any more capability than this method, but are merely
present for performance and convenience (the dispatching for those methods is
done in pure C, rather than several layers of Perl).

Therefore, the semantics and behavior of C<on_any> depends on the functionality
of the method for which C<on_any> has been made a surrogate.

Determining this can be quite easy. Simply combine the C<Type> and C<Mode>
fields to yield the equivalent function name:

    if ($info->{Type} == TUBA_TYPE_LIST and $info->{Mode} eq '+') {
        my $callback_name = "start_list";
    }
    # etc.

=item start_json

=item end_json

Delivered on the beginning or end of a stream.

=item start_object

=item end_object

Delivered on the beginning and end of a hash

=item start_list

=item stop_list

Delivered on the beginning or end of an array.

=item start_string

=item stop_string

Delivered when a string has started or stopped. More specifically, this means
when the lexer has seen an opening or closing C<">

=item on_string

This is where string-specific data gets delivered. This can be either
an entire string, or a fragment thereof. In the case of the former, the string
is unescaped.

=item on_data

This is an optional (and default) generic callback for incremental mode - fragments
of numbers, booleans, strings, and keys will be delivered here, with the
C<START> and C<STOP> callbacks signalling their beginning and end.

=item start_number

=item stop_number

=item on_number

These three methods follow the same semantics as their C<*_string> equivalents,
except of course, there is no unescaping


=item start_boolean

=item stop_boolean

=item on_boolean

Same behavior as strings and numbers, except that the object (in the default
accumulator mode) is converted to a C<JSON::SL::Boolean>

=item start_null

=item stop_null

=item on_null

Delivered for JSON C<null> atoms. In accumulator mode, these get converted into
C<undef> values.

=back

=head2 OPTIONS

=head3 Accumulators

By default C<JSON::SL::Tuba> uses internal accumulators to buffer your data. This
makes for high level events being delivered efficiently without having to call into
perl with multiple callbacks for very small units of data. This also makes it
easier for you the user, as state handling mechanisms do not need to be as complex.

In addition, Tuba has a special C<kv> (key-value) accumulator which buffers
hash keys internally and only ever delivers them as the C<Key> field within
the informational hash passed to callbacks.

Accumulator settings control whether incremental 'data' callbacks will be
invoked for a specific scalar type or not.

=head4 $tuba->accum(tuba, type => boolean, another_type => boolean, ...)

Set accumulator parameters. Each C<type> argument is one of the 
C<TUBA_TYPE_> constants (or a mnemonic character), and each 
C<boolean> argument is whether data for that type should be accumulated.

=head4 $tuba->accum_kv(boolean)

Gets or sets the status of the key-value accumulator. Note that enabling
the key-value accumulator will also enable the generic key (i.e. C<#>)
but disabling the key-value accumulator will not reverse this effect.

=head4 $tuba->accum_all(boolean)

This enables or disables the accumulator settings for all scalar types (but
not the key-value accumulator)

=head3 Generic Options

=head4 $tuba->cb_unified(boolean)

If only a single callback is being used, set this option to have Tuba call
the C<on_any> callback initially instead of using this as a fallback.

This is not enabled by default as it prevents any other methods from being called,
but should be turned on if you don't care about that fact.

=head4 $tuba->utf8(boolean)

Tell Tuba to set the C<SvUTF8> flag on strings.

=head4 $tuba->allow_unhandled(boolean)

By default, Tuba will croak if it cannot find a handler method for a given event
(this effectively means the C<on_any> method has not been implemented). This is
usually what you want. To disable this behavior, set C<allow_unhandled> to a true
value.

=head2 Parsing Data

There is one method:

=head3 $tuba->parse($json_chunk)

And that's all there is to it. Tuba will parse all data fed to it.

If accumulator mode is not being used, then you will be guaranteed to rhave
processed every bit of data in C<$json_chunk>, leaving nothing buffered.

This method will croak on error (and I have not yet implemented error handling).


=head3 Storing Data in Tuba

The tuba object is a simple hash references. Feel free to use it and abuse it.
One exception is the C<_TUBA> key which contains the pointer to the internal
C structure. You will probably have perl croak for trying to modify this read-only
variable - but if perl doesn't croak, your program will crash - so don't modify
it.


=head1 BUGS AND CAVEATS

It would be nice to provide an error handler.

=head2 Info Hash

The info hash passed to callbacks is read only and volatile. This means
the following:

Trying to access a non-existent key in the hash (i.e. any key not listed in the
section describing this hash) will throw an error about accessing a disallowed key.

Trying to modify any value in the hash will throw and error.

Keeping references to values within the hash, e.g.

    my $ref = \$hash->{Type};
    
will not work as the value will not be consistent after the callback has returned.

It is safe to take a reference to the C<Key> field, though.

=head2 Speed

Considering what Tuba does and the convenience it provides, it's blazingly fast.
Nevertheless, L<JSON::SL> is still at least twice the speed.


=head1 SEE ALSO

L<JSON::SL>

=head1 AUTHOR AND COPYRIGHT

Copyright (C) 2012 M. Nunberg

You may use and distribute this software under the same terms and conditions as
Perl itself.
