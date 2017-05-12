# JOAP - Perl Extension for the Jabber Object Access Protocol
#
# Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

# tag: JOAP main module

package JOAP;
use base qw/Exporter/;

use 5.008;
use strict;
use warnings;

BEGIN {
    use Net::Jabber::Protocol;

    our %EXPORT_TAGS = ( 'all' => [ qw// ] );
    our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
    our @EXPORT = qw//;

    our $VERSION = '0.01';
    our $NS = 'http://www.jabber.org/jeps/jep-0075.html#0.3';

    my %spaces =
      ($JOAP::NS =>
       [{name=>'Read',
         type=>'master'},
        {name=>'Edit',
         type=>'master'},
        {name=>'Add',
         type=>'master'},
        {name=>'Delete',
         type=>'master'},
        {name=>'Search',
         type=>'master'},
        {name=>'Describe',
         type=>'master'},
        {name=>'Name',          # read req
         type=>'array',
         path=>'name/text()'},
        {name=>'Attribute',     # read resp, edit/add/search req
         type=>'children',
         path=>'attribute',
         child=>['Query', '__netjabber__:' . $JOAP::NS . ':attribute'],
         calls=>['Get', 'Defined', 'Add']},
        {name=>'Timestamp',
         path=>'timestamp/text()'}, # read/describe resp
        {name=>'NewAddress',    # add/edit resp
         path=>'newAddress/text()'},
        {name=>'Item',          # search resp
         type=>'array',
         path=>'item/text()'},
        {name=>'Desc',          # describe resp
         type=>'array',
         path=>'desc/text()'},
        {name=>'Class',         # describe resp
         type=>'array',
         path=>'class/text()'},
        {name=>'Superclass',    # describe resp
         type=>'array',
         path=>'superclass/text()'},
        {name=>'AttributeDescription', # describe resp
         type=>'children',
         path=>'attributeDescription',
         child=>['Query', '__netjabber__:' . $JOAP::NS . ':attributeDescription'],
         calls=>['Get', 'Defined', 'Add']},
        {name=>'MethodDescription', # describe resp
         type=>'children',
         path=>'methodDescription',
         child=>['Query', '__netjabber__:' . $JOAP::NS . ':methodDescription'],
         calls=>['Get', 'Defined', 'Add']}],

       '__netjabber__:' . $JOAP::NS . ':attribute' =>
       [{name=>'Attribute',
         type=>'master'},
        {name=>'Name',
         path=>'name/text()'},
        {name=>'Value',
         path=>'value',
         type=>'children',
         child=>['Query', '__netjabber__:iq:rpc:value'],
         calls=>['Get', 'Add', 'Defined']},
        {name=>'RPCValue',
         path=>'value',
         type=>'children',
         child=>['Query', '__netjabber__:iq:rpc:value'],
         calls=>['Get', 'Add', 'Defined']}],

       '__netjabber__:' . $JOAP::NS . ':attributeDescription' =>
       [{name=>'AttributeDescription',
         type=>'master'},
        {name=>'Name',
         path=>'name/text()'},
        {name=>'Type',
         path=>'type/text()'},
        {name=>'Desc',
         type=>'array',
         path=>'desc/text()'},
        {name=>'Required',
         path=>'@required'},
        {name=>'Writable',
         path=>'@writable'},
        {name=>'Allocation',
         path=>'@allocation'}],

       '__netjabber__:' . $JOAP::NS . ':methodDescription' =>
       [{name=>'MethodDescription',
         type=>'master'},
        {name=>'Name',
         path=>'name/text()'},
        {name=>'ReturnType',
         path=>'returnType/text()'},
        {name=>'Desc',
         path=>'desc/text()'},
        {name=>'Params',
         path=>'params',
         type=>'children',
         child=>['Query', '__netjabber__:' . $JOAP::NS . ':params'],
         calls=>['Get','Defined','Add']},
        {name=>'Allocation',
         path=>'@allocation'}],

       '__netjabber__:' . $JOAP::NS . ':params' =>
       [{name=>'Params',
         path=>'param',
         type=>'children',
         child=>['Query', '__netjabber__:' . $JOAP::NS . ':param'],
         calls=>['Get', 'Defined']},
        {name=>'Param',
         path=>'param',
         type=>'node',
         child=>['Query', '__netjabber__:' . $JOAP::NS . ':param'],
         calls=>['Add']}],

       '__netjabber__:' . $JOAP::NS . ':param' =>
       [{name=>'Param',
         type=>'master'},
        {name=>'Name',
         path=>'name/text()'},
        {name=>'Type',
         path=>'type/text()'},
        {name=>'Desc',
         path=>'desc/text()'}]
      );

    my ($ns, $funcs);

    while (($ns, $funcs) = each %spaces) {

        # XXX: This is stupid. Trying to fake out the OO syntax, we're
        # gonna get bit.

        Net::Jabber::Protocol->DefineNamespace(undef,
                                               xmlns=>$ns,
                                               type=>'Query',
                                               functions=>$funcs);
    }

    %spaces = ();
}

# A regular expression for XML Schema dateTime stuff

my $dt = '^(-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$';

# utilities to encode datur

sub encode {

    my $self = shift;
    my $type = shift;
    my $value = shift;

    if (!$type) {
        $type = $self->guess_type($value);
    }

    my $jval = new Net::Jabber::Query('value');
    $jval->SetXMLNS('__netjabber__:iq:rpc:value');

    my $realvalue = JOAP->coerce($type, $value);

    if ($type eq 'int' || $type eq 'i4') {
        $jval->SetI4($realvalue);
    } elsif ($type eq 'boolean') {
        $jval->SetBoolean($realvalue);
    } elsif ($type eq 'dateTime.iso8601') {
        $jval->SetDateTime($realvalue); # XXX: deal with numbers, arrays, Date::* objects, etc
    } elsif ($type eq 'double') {
        $jval->SetDouble($realvalue);
    } elsif ($type eq 'string') {
        $jval->SetString($realvalue);
    } elsif ($type eq 'array') {
        my $arr = $jval->AddArray();
        my $do = $arr->AddData();

        foreach my $data (@$value) {
            $do->AddValue($self->guess_type($data) => $data);
        }
    } elsif ($type eq 'struct') {
        my $str = $jval->AddStruct();
        my $name;
        my $val;

        while (($name, $val) = each %$value) {
            $str->AddMember(name => $name)->AddValue($self->guess_type($val) => $val);
        }
    }
    else {
        throw Error::Simple("Unknown type: $type\n");
    }

    return $jval;
}

sub guess_type {

    my($self) = shift;
    my($value) = shift;
    my($type);

    if ($value =~ /^[+-]?\d+$/) {
        $type = 'i4';
    } elsif ($value =~ /^(-?(?:\d+(?:\.\d*)?|\.\d+)|([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?)$/) {
        $type = 'double';
    } elsif ($value =~ /$dt/) {
        $type = 'dateTime.iso8601';
    } else {
        $type = 'string';
    }

    return $type;
}

sub decode {

    my($self) = shift;
    my($jval) = shift;

    if ($jval->DefinedI4()) {
        return $jval->GetI4() + 0;
    } elsif ($jval->DefinedDouble()) {
        return $jval->GetDouble() + 0.0;
    } elsif ($jval->DefinedDateTime()) {
        return $jval->GetDateTime();
    } elsif ($jval->DefinedBoolean()) {
        return ($jval->GetBoolean()) ? 1 : 0;
    } elsif ($jval->DefinedString()) {
        return $jval->GetString();
    } elsif ($jval->DefinedStruct()) {
        my $results = {};
        foreach my $member ($jval->GetStruct->GetMembers()) {
            $results->{$member->GetName} = $self->decode($member->GetValue);
        }
        return $results;
    } elsif ($jval->DefinedArray()) {
        my $results = [];
        foreach my $value ($jval->GetArray()->GetDatas()->GetValue()) {
            push @$results, $self->decode($value);
        }
        return $results;
    }
}

sub copy_value {

    my $self = shift;
    my $from = shift;
    my $to = shift;

    if ($from->DefinedI4()) {
        $to->SetI4($from->GetI4() + 0);
    } elsif ($from->DefinedDouble()) {
        $to->SetDouble($from->GetDouble() + 0.0);
    } elsif ($from->DefinedDateTime()) {
        $to->SetDateTime($from->GetDateTime());
    } elsif ($from->DefinedBoolean()) {
        $to->SetBoolean(($from->GetBoolean()) ? 1 : 0);
    } elsif ($from->DefinedString()) {
        $to->SetString($from->GetString());
    } elsif ($from->DefinedStruct()) {
	my $str = $to->AddStruct;
        foreach my $member ($from->GetStruct->GetMembers()) {
	    my $v = $str->AddMember(name => $member->GetName)->AddValue;
	    $self->copy_value($member->GetValue, $v);
        }
    } elsif ($from->DefinedArray()) {
	my $arr = $to->AddArray;
	my $d = $arr->AddData;
        foreach my $value ($from->GetArray()->GetDatas()->GetValue()) {
	    my $v = $d->AddValue;
	    $self->copy_value($value, $v);
        }
    }
}

sub value_type {

    my $self = shift;
    my $value = shift;

    if ($value->DefinedI4) {
	return 'i4';
    }
    elsif ($value->DefinedBoolean) {
	return 'boolean';
    }
    elsif ($value->DefinedString) {
	return 'string';
    }
    elsif ($value->DefinedDouble) {
	return 'double';
    }
    elsif ($value->DefinedDateTime) {
	return 'dateTime.iso8601';
    }
    elsif ($value->DefinedStruct) {
	return 'struct';
    }
    elsif ($value->DefinedBase64) {
	return 'base64';
    }
    elsif ($value->DefinedArray) {
	return 'array';
    }
}

# coerce a perl value into the right shape for the given type

sub coerce {

    my($self) = shift;
    my($type) = shift;
    my $value = shift;

    if ($type eq 'string') {
        return (defined $value) ? $value . '' : '';
    } elsif ($type eq 'int' || $type eq 'i4') {
        no warnings;            # turn off non-numeric warnings
        return (defined $value) ? ($value + 0) : 0;
    } elsif ($type eq 'double') {
        no warnings;            # turn off non-numeric warnings
        return (defined $value) ? ($value + 0.0) : 0.0;
    } elsif ($type eq 'boolean') {
        return ($value) ? 1 : 0;
    } elsif ($type eq 'array') {
        return (defined $value) ? $value : [];
    } elsif ($type eq 'struct') {
        return (defined $value) ? $value : {};
    } elsif ($type eq 'base64') {
        return $value;          # FIXME: base64 the thing
    } elsif ($type eq 'dateTime.iso8601') {
        my $default = '0001-00-00T00:00:00Z';
        if (!defined($value)) {
            return $default;
        } elsif (ref($value) eq "ARRAY") {
            if (scalar(@$value) >= 6) { # looks more or less like a gmtime thingy
                return $self->array_to_datetime($value);
            } else {
                return $default;
            }
        } elsif (ref($value)) { # we don't know what to do with other refs
            return $default;
        } elsif ($value =~ /$dt/) {
            return $value;
        } elsif ($value =~ /^\d+/) { # looks like an int
            return $self->int_to_datetime($value);
        } else {
            return $default;
        }
    } else {
        throw Error::Simple("Unknown type: $type");
    }
}

sub int_to_datetime {
    my $self = shift;
    my $val = shift;
    my $int = $self->coerce('i4', $val);

    return $self->array_to_datetime([gmtime($int)]);
}

sub array_to_datetime {

    my $self = shift;
    my $arr = shift;

    return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $arr->[5] + 1900,
                   $arr->[4] + 1, $arr->[3], $arr->[2], $arr->[1],
                   $arr->[0]);
}

# converts a datetime string to a gmtime-style array

sub datetime_to_array {

    my $self = shift;
    my $in = shift;

    my @parts = $in =~ /$dt/;

    if (!@parts) {
        return ();
    } else {
        return ($parts[5], $parts[4], $parts[3],
                $parts[2], $parts[1] - 1, $parts[0] - 1900);
    }
}

1;

__END__

=head1 NAME

JOAP - Perl extension for the Jabber Object Access Protocol (JOAP)

=head1 SYNOPSIS

    use Net::Jabber qw(Client);
    use JOAP;

    # have fun here. B-)

=head1 ABSTRACT

The Jabber Object Access Protocol (JOAP) allows object attributes and
methods to be accessed over the Jabber network. This Perl package
implements JOAP in Perl. It lets developers define their own JOAP
servers and classes in Perl, and it also lets them use remote servers
and classes in a transparent and Perlish way.

=head1 DESCRIPTION

This module is the entry-point for JOAP programming in Perl. Most of
the interesting JOAP functionality is implemented in other
packages. The SEE ALSO section below points out some important ones
you should start with.

When loaded, this module sets up the Jabber libraries to be ready for
JOAP. Most developers don't need to do much programming at the Jabber
library level, since the JOAP libraries take care of most of this for
you. But if you're interested, look at L<JOAP::NetJabber> for more
information.

This module also provides some important data marshalling services to
other JOAP modules. You shouldn't need to worry about these in normal
JOAP programming; they're documented here for reference by people
working on this package. If you're not doing that, I<please> jump to
the L<SEE ALSO> section to get started with JOAP.

=head2 Package Variables

The JOAP package has one package variable of any importance.

=over

=item $JOAP::NS

This is a string representation of the JOAP XML namespace. When and if
JOAP becomes a Jabber standard, this will be 'jabber:iq:joap'. Until
then, this is set to a temporary namespace, as recommended by the JOAP
specification. This lets us interoperate with other implementations
that are experimenting with JOAP, without causing problems in the
future if (when) the specification changes.

The other JOAP libraries use this variable pretty consistently.

Mucking around with this variable is done at your peril, and the peril
of other software that talks JOAP to yours. Don't do it.

=back

=head2 Class Methods

The JOAP package provides some data marshalling services that make it
a little easier to convert Perl data to JOAP data and vice versa.

=over

=item JOAP->encode($type, $pval)

Encode the Perl value $pval to a JOAP value of type $type. See
L<JOAP::Types> for a discussion of the JOAP type system. Returns a
JOAP value element that can be used with C<JOAP->copy_value> below.

=item JOAP->decode($jval)

Decode the JOAP value $jval, and returns its Perl value. Since JOAP
values contain type information, you don't need to pass in a type.

=item JOAP->copy_value($from, $to)

Copy JOAP value $from to JOAP value $to. This is kind of a hack, but I
had a hard time making the Net::Jabber libraries take a JOAP value as
an argument.

=item JOAP->value_type($jval)

Returns a string containing the name of the type of JOAP value
$value. See L<JOAP::Types>.

=item JOAP->coerce($type, $pval)

Gets a Perl value, Perl-equivalent to $pval, that will encode cleanly
into a JOAP value of type $type. By "Perl-equivalent", I mean all the
tricky stuff that happens when you evaluate a Perl value in different
contexts.

For example,

     JOAP->coerce('boolean', '0 but true')

...will return '1', since that's the JOAP equivalent of the Perl
boolean value of '0 but true'. On the other hand,

     JOAP->coerce('int', '54 horses')

...will return '54', since that's the JOAP equivalent of the integer
value of '54 horses'.

     JOAP->coerce('dateTime.iso8601', time)

...will return the current time as an ISO 8601-formatted string.

The whole point here is to let Perl hackers do all the crazy,
wigged-out and intuitive tricks they want with their custom JOAP code,
and have it go out in clean and acceptable fashion onto the wire. It's
probably a quixotic dream, but it works for a lot of stuff.

=item JOAP->int_to_datetime($int)

Converts (Perl) integer $int to an ISO 8601-formatted datetime string,
where $int is considered in seconds-past-the-epoch, as is returned by
L<perlfunc/time>.

=item JOAP->array_to_datetime($arrayref)

Converts a reference to time array in L<perlfunc/gmtime> format to a
formatted ISO 8601 datetime string.

=item JOAP->datetime_to_array($datetime)

Converts a formatted ISO 8601 datetime string to a time array in
L<perlfunc/gmtime> format. Note that it returns an array, not a
reference to an array.

=back

=head2 EXPORT

None by default.

=head1 BUGS and CAVEATS

An important caveat is that JOAP is still an immature protocol, and
this is an early, experimental implementation. You can do some
interesting hacking with this package, but you should track the future
development of the package, since it will probably go through a number
of revisions in the near future.

The marshalling code is usable but still pretty shaky with compound
types like arrays and structs, and doesn't handle object types well at
all.

Badly-formatted datetimes (e.g., '19930207T120000Z') will be evaluated
as integers, with some disturbing results. Be careful with datetimes.

=head1 SEE ALSO

If you're interested in creating a JOAP server, you should probably
start off looking at L<JOAP::Server> and L<JOAP::Server::Class>.

If you're interested in creating a JOAP client, you will probably want
to take a look at the documentation for
L<JOAP::Proxy::Package::Server> and L<JOAP::Proxy::Package::Class>.

A discussion of the JOAP type system is in L<JOAP::Types>.

Information on using 'raw' JOAP Jabber stanzas can be found in
L<JOAP::NetJabber>.

There's a Web page for this project on JabberStudio, which you can find here:

        http://joap-perl.jabberstudio.org/

You can file bug reports with the cool bug reporting facility here:

        http://www.jabberstudio.org/projects/joap-perl/bugs/

...and make feature requests here:

        http://www.jabberstudio.org/projects/joap-perl/features/

There's a mailing list which you can sign up for here:

        http://www.jabberstudio.org/cgi-bin/mailman/listinfo/joap-perl-dev/

Messages should be sent to joap-perl-dev@jabberstudio.org.

There's a Jabber conference for the project here:

        joap-perl@conference.jabberstudio.org

I can personally be contacted at evan@prodromou.san-francisco.ca.us by
email, and at EvanProdromou@jabber.org by Jabber.

More information on Jabber itself can be found here:

        http://www.jabber.org/

The definition of the Jabber Object Access Protocol is here:

        http://www.jabber.org/jeps/jep-0075.html

This implementation conforms to version 0.3 of the protocol.

=head1 AUTHOR

Evan Prodromou, E<lt>evan@prodromou.san-francisco.ca.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003, Evan Prodromou E<lt>evan@prodromou.san-francisco.ca.usE<gt>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

=cut
