use v5.10;

package Mac::PropertyList::WriteBinary;
use strict;
use warnings;

use Encode              ();
use Mac::PropertyList   ();
use Math::BigInt;
use Exporter          qw(import);

=encoding utf8

=head1 NAME

Mac::PropertyList::WriteBinary - pack data into a Mac "binary property list"

=head1 SYNOPSIS

    use Mac::PropertyList::WriteBinary;

    my $data = Mac::PropertyList::dict->new( { ... => ... } );
    my $buf  = Mac::PropertyList::WriteBinary::as_string($data);

=head1 DESCRIPTION

The C<as_string> function converts a property list structure
(composed of instances of C<Mac::PropertyList::dict>,
C<Mac::PropertyList::integer>, etc.)  into a binary format compatible
with the Apple CoreFoundation binary property list functions.

It takes a single argument, the top-level object to write, and returns
a byte string.

The property list can contain the following perl objects:

=over 4

=item C<Mac::PropertyList> value objects

These are written according to their class.

=item Unblessed references to Perl lists and hashes

These are written as arrays and dictionaries, respectively.

=item Perl scalars

All Perl scalars are written as strings; this is similar to the behavior
of writing an oldstyle OpenStep property list, which does not
distinguish between numbers and strings, and then reading it using
CoreFoundation functions.

=item C<undef>

This is written as the null object. CoreFoundation will read this as
C<kCFNull>, but appears to be unable to write it.

=back

Strings are uniqued (two equal strings will be written as references
to the same object). If the same reference appears more than once in
the structure, it will likewise only be represented once in the
output. Although the bplist format can represent circular data
structures, they cannot be written by this module (they will be
detected and result in an error — they wouldn't be read correctly by
CoreFoundation anyway, so you aren't missing much).

=head1 BUGS

C<Mac::PropertyList::date> objects are not handled yet.

Objects other than strings (and null) are not uniqued by value,
only by reference equality. This may change in a future version.

Perl's dictionary keys can only be strings, but a bplist's can be
any scalar object.

There is no way to write the C<UID> objects used by the keyed archiver.

Perls that do not use IEEE-754 format internally for floating point
numbers will produce incorrect output.

=cut

use constant {
    header       => 'bplist00',

    tagInteger   => 0x10,
    tagFloat     => 0x20,
    tagDate      => 0x30,
    tagData      => 0x40,
    tagASCII     => 0x50,
    tagUTF16     => 0x60,
    tagUID       => 0x80,
    tagArray     => 0xA0,
    tagSet       => 0xC0,
    tagDict      => 0xD0,

    # If we can actually represent an integer close to 2^64 with full
    # precision and pack it with 'Q', then we can use that
    havePack64   => ( eval { pack('Q>', 1153202979583557643) eq "\x10\x01\0\0\0\0\0\x0B" } ? 1 : 0 ),
};

our $VERSION = '1.504';
our @EXPORT_OK = qw( as_string );

sub as_string {
    my($value) = @_;
    my($ctxt) = _create_fragments($value);
    my(@offsets, $xref_offset, $offset_size);

    # The header (magic number and version, which is 00)
    my($buf) = header;

    # Write each fragment, making note of its offset in the file
    foreach my $objid (0 .. $ctxt->{nextid}-1) {
        $offsets[$objid] = length $buf;
        $buf .= $ctxt->{fragments}->{$objid};
    }

    # ... and the offset of the beginning of the offsets table
    $xref_offset = length $buf;

    # Figure out how many bytes to use to represent file offsets,
    # and append the offset table
    if ($xref_offset < 256) {
        $buf .= pack('C*', @offsets);
        $offset_size = 1;
    } elsif ($xref_offset < 65536) {
        $buf .= pack('n*', @offsets);
        $offset_size = 2;
    } else {
        $buf .= pack('N*', @offsets);
        $offset_size = 4;
    }

    # Write the file trailer
    $buf .= pack('x5 CCC ' . ( havePack64? 'Q>' : 'x4N' ) x 3,
                 0, $offset_size, $ctxt->{objref_size},
                 $ctxt->{nextid}, $ctxt->{rootid}, $xref_offset);

    $buf;
}

# sub to_file {
#   To consider:
#   It might be useful to have a version of &as_string which writes
#   the fragments directly to a file handle without having to build a
#   single large buffer in RAM. This would be more efficient for
#   larger structures. On the other hand, if you're writing large
#   structures with this module, you're already suffering needlessly,
#   so perhaps it's not worth optimizing overmuch for that case.
# }


# _assign_id is the workhorse function which recursively
# descends the data structure and assigns object ids to each node,
# as well as creating fragments of the final file.
sub _assign_id {
    my($context, $value) = @_;

    # The type of this value
    my($tp) = ref $value;

    # Unblessed scalars are either strings or undef.
    if ($tp eq '') {
        if (!defined $value) {
            $context->{nullid} = $context->{nextid} ++
                unless defined $context->{nullid};
            return $context->{nullid};
        } else {
            $context->{strings}->{$value} = $context->{nextid} ++
                unless exists $context->{strings}->{$value};
            return $context->{strings}->{$value};
        }
    }

    # If we reach here we know that $value is a ref. Keep a table of
    # stringified refs, so that we can re-use the id of an object
    # we've seen before.
    if(exists $context->{refs}{$value}) {
        my($thisid) = $context->{refs}->{$value};
        die "Recursive data structure\n" unless defined $thisid;
        return $thisid;
    }
    $context->{refs}->{$value} = undef;

    # Serialize the object into $fragment if possible. Since we
    # don't yet know how many bytes we will use to represent object
    # ids in the final file, don't serialize those yet–keep them
    # as a list of integers for now.
    my($fragment, @objrefs);

    if($tp eq 'ARRAY') {
        $fragment = _counted_header(tagArray, scalar @$value);
        @objrefs = map { $context->_assign_id($_) } @$value;
    } elsif($tp eq 'HASH') {
        my(@ks) = sort (CORE::keys %$value);
        $fragment = _counted_header(tagDict, scalar @ks);
        @objrefs = ( ( map { $context->_assign_id($_) } @ks ),
                     ( map { $context->_assign_id($value->{$_}) } @ks ) );
    } elsif(UNIVERSAL::can($tp, '_as_bplist_fragment')) {
        ($fragment, @objrefs) = $value->_as_bplist_fragment($context);
    } else {
        die "Cannot serialize type '$tp'\n";
    }

    # As a special case, a fragment of 'undef' indicates that
    # the object ID was already assigned.
    return $objrefs[0] if !defined $fragment;

    # Assign the next object ID to this object.
    my($thisid) = $context->{nextid} ++;
    $context->{refs}->{$value} = $thisid;

    # Store the fragment and unpacked object references (if any).
    $context->{fragments}->{$thisid} = $fragment;
    $context->{objrefs}->{$thisid} = \@objrefs if @objrefs;

    return $thisid;
}

sub _create_fragments {
    my ($value) = @_;

    # Set up the state needed by _assign_id

    my ($ctxt) = bless({
        nextid => 0,       # The next unallocated object ID
        nullid => undef,   # The object id of 'null'
        strings => { },    # Maps string values to object IDs
        refs => { },       # Maps stringified refs to object IDs
        fragments => { },  # Maps object IDs to bplist fragments, except object lists
        objrefs => { },    # Maps object IDs to objref lists
    });

    # Traverse the data structure, and remember the id of the root object
    $ctxt->{rootid} = $ctxt->_assign_id($value);

    # Figure out how many bytes to use to represent an object id.
    my ($objref_pack);
    if ($ctxt->{nextid} < 256) {
        $objref_pack = 'C*';
        $ctxt->{objref_size} = 1;
    } elsif ($ctxt->{nextid} < 65536) {
        $objref_pack = 'n*';
        $ctxt->{objref_size} = 2;
    } else {
        $objref_pack = 'N*';
        $ctxt->{objref_size} = 4;
    }

    my($objid, $reflist, $stringval);

    # Append the unformatted object ids to their corresponding fragments,
    # now that we know how to pack them.
    while (($objid, $reflist) = each %{$ctxt->{objrefs}}) {
        $ctxt->{fragments}->{$objid} .= pack($objref_pack, @$reflist);
    }
    delete $ctxt->{objrefs};

    # Create fragments for all the strings.
    # TODO: If &to_file is written, it would be worth
    # breaking this out so that the conversion can be done on the
    # fly without keeping all of the converted strings in memory.
    {
        my($ascii) = Encode::find_encoding('ascii');
        my($utf16be) = Encode::find_encoding('UTF-16BE');

        while (($stringval, $objid) = each %{$ctxt->{strings}}) {
            my($fragment);

            # Strings may be stored as ASCII (7 bits) or UTF-16-bigendian.
            if ($stringval =~ /\A[\x01-\x7E]*\z/s) {
                # The string is representable in ASCII.
                $fragment = $ascii->encode($stringval);
                $fragment = _counted_header(tagASCII, length $fragment) . $fragment;
            } else {
                $fragment = $utf16be->encode($stringval);
                $fragment = _counted_header(tagUTF16, (length $fragment)/2) . $fragment;
            }

            $ctxt->{fragments}->{$objid} = $fragment;
        }
    }

    # If there's a <null> in the file, create its fragment.
    $ctxt->{fragments}->{$ctxt->{nullid}} = "\x00"
        if defined $ctxt->{nullid};

    $ctxt;
}

sub _counted_header {
    my ($typebyte, $count) = @_;

    # Datas, strings, and container objects have a count/size encoded
    # in the lower 4 bits of their type byte. If the count doesn't fit
    # in 4 bits, the bits are set to all-1s and the actual value
    # follows, encoded as an integer (including the integer's
    # own type byte).

    if ($count < 15) {
        return pack('C',    $typebyte + $count);
    } else {
        return pack('C',    $typebyte + 15) . &_pos_integer($count);
    }
}

sub _pos_integer {
    my($count) = @_;

    if ($count < 256) {
        return pack('CC',  tagInteger + 0, $count);
    } elsif ($count < 65536) {
        return pack('CS>', tagInteger + 1, $count);
    } elsif (havePack64 && ($count > 4294967295)) {
        return pack('Cq>', tagInteger + 3, $count);
    } else {
        return pack('CN',  tagInteger + 2, $count);
    }
}

package Mac::PropertyList::array;

sub _as_bplist_fragment {
    my($context, @items) = ( $_[1], $_[0]->value );
    @items = map { $context->_assign_id($_) } @items;

    return ( Mac::PropertyList::WriteBinary::_counted_header(Mac::PropertyList::WriteBinary::tagArray, scalar @items),
             @items );
}

package Mac::PropertyList::dict;

sub _as_bplist_fragment {
    my($self, $context) = @_;
    my($value) = scalar $self->value;  # Returns a ref in scalar context
    my(@keys) = sort (CORE::keys %$value);

    return ( Mac::PropertyList::WriteBinary::_counted_header(Mac::PropertyList::WriteBinary::tagDict, scalar @keys),
             ( map { $context->_assign_id($_) } @keys ),
             ( map { $context->_assign_id($value->{$_}) } @keys ));

}

package Mac::PropertyList::date;

use Scalar::Util ( 'looks_like_number' );
use Time::Local  ( 'timegm' );

sub _as_bplist_fragment {
    my($value) = scalar $_[0]->value;
    my($posixval);

    if (looks_like_number($value)) {
        $posixval = $value;
    } elsif ($value =~ /\A(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d)\:(\d\d)\:(\d\d(?:\.\d+)?)Z\z/) {
        $posixval = timegm($6, $5, $4, $3, $2 - 1, $1);
    } else {
        die "Invalid plist date '$value'\n";
    }

    # Dates are simply stored as floating-point numbers (seconds since the
    # start of the CoreFoundation epoch) with a different tag value.
    # See the notes in Mac::PropertyList::real on float format.
    return pack('Cd>', Mac::PropertyList::WriteBinary::tagDate + 3,
                $posixval - 978307200);
}

package Mac::PropertyList::real;

# Here we're assuming that the 'd' format for pack produces
# an IEEE-754 double-precision (64-bit) floating point
# representation, because ... it does on practically every
# system. However, this will not be portable to systems which
# don't natively use IEEE-754 format!

sub _as_bplist_fragment {
    my($self) = shift;

    return pack('Cd>', Mac::PropertyList::WriteBinary::tagFloat + 3, $self->value);
}

package Mac::PropertyList::integer;

use constant tagInteger => 0x10;

sub _as_bplist_fragment {
    my($value) = $_[0]->value;

    # Per comments in CFBinaryPList.c, only 8-byte integers (and
    # 16-byte integers, if they're supported, which they're not) are
    # interpreted as signed. Shorter integers are always unsigned.
    # Therefore all negative numbers must be written as 8-byte
    # integers.

    if ($value < 0) {
        if (Mac::PropertyList::WriteBinary::havePack64) {
            return pack('Cq>', tagInteger + 3, $value);
        } else {
            return pack('CSSl>', tagInteger + 3, 65535, 65535, $value);
        }
    } else {
        return Mac::PropertyList::WriteBinary::_pos_integer($value);
    }
}

package Mac::PropertyList::uid;

use constant tagUID => Mac::PropertyList::WriteBinary->tagUID;

sub _as_bplist_fragment {
    my( $value ) = $_[0]->value;

    # TODO what about UIDs longer than 16 bytes? Or are there none?
    return pack 'CH*', tagUID + length( $value ) / 2 - 1, $value;
}

package Mac::PropertyList::string;

sub _as_bplist_fragment {
    # Returning a fragment of 'undef' indicates we've already assigned
    # an object ID.
    return ( undef, $_[1]->_assign_id($_[0]->value) );
}

package Mac::PropertyList::ustring;

sub _as_bplist_fragment {
    # Returning a fragment of 'undef' indicates we've already assigned
    # an object ID.
    return ( undef, $_[1]->_assign_id($_[0]->value) );
}

package Mac::PropertyList::data;

sub _as_bplist_fragment {
    my($value) = $_[0]->value;
    return (&Mac::PropertyList::WriteBinary::_counted_header(Mac::PropertyList::WriteBinary::tagData, length $value) .
            $value);
}

package Mac::PropertyList::true;

sub _as_bplist_fragment { return "\x09"; }

package Mac::PropertyList::false;

sub _as_bplist_fragment { return "\x08"; }

=head1 AUTHOR

Wim Lewis, C<< <wiml@cpan.org> >>

Copyright © 2012-2021 Wim Lewis. All rights reserved.

Tom Wyant added support for UID types.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mac::PropertyList::ReadBinary> for the inverse operation.

Apple's partial published CoreFoundation source code:
L<http://opensource.apple.com/source/CF/>

=cut

"One more thing";
