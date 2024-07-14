# NAME

Geo::FIT - Decode Garmin FIT files

# SYNOPSIS

    use Geo::FIT;

Create an instance, assign a FIT file to it, open it:

    my $fit = Geo::FIT->new();
    $fit->file( $fname );
    $fit->open or die $fit->error;

Register a callback to get some info on where we've been and when:

    my $record_callback = sub {
        my ($self, $descriptor, $values) = @_;

        my $time= $self->field_value( 'timestamp',     $descriptor, $values );
        my $lat = $self->field_value( 'position_lat',  $descriptor, $values );
        my $lon = $self->field_value( 'position_long', $descriptor, $values );

        print "Time was: ", join("\t", $time, $lat, $lon), "\n"
        };

    $fit->data_message_callback_by_name('record', $record_callback ) or die $fit->error;

    my @header_things = $fit->fetch_header;

    1 while ( $fit->fetch );

    $fit->close;

# DESCRIPTION

`Geo::FIT` is a Perl class to provide interfaces to decode Garmin FIT files (\*.fit).

The module also provides a script to read and print the contents of FIT files ([fitdump.pl](https://metacpan.org/pod/fitdump.pl)), a script to convert FIT files to TCX files ([fit2tcx.pl](https://metacpan.org/pod/fit2tcx.pl)), and a script to convert a locations file to GPX format ([locations2gpx.pl](https://metacpan.org/pod/locations2gpx.pl)).

## Constructor Methods

- new()

    creates a new object and returns it.

- clone()

    Returns a copy of a `Geo::FIT` instance.

    `clone()` is experimental and support for it may be removed at any time. Use with caution particularly if there are open filehandles, it which case it is recommended to `close()` before cloning.

    It also does not return a full deep copy if any callbacks are registered, it creates a reference to them. There is no known way to make deep copies of anonymous subroutines in Perl (if you know of one, please make a pull request).

    The main use for c&lt;clone()> is immediately after `new()`, and `file()`, to create a copy for later use.

## Class methods

- profile\_version\_string()

    returns a string representing the .FIT profile version on which this class based.

## Object methods

- file( $filename )

    returns the name of a .FIT file. Sets the name to _$filename_ if called with an argument (raises an exception if the file does not exist).

- open()

    opens the .FIT file.

- fetch\_header()

    reads .FIT file header, and returns an array of the file size (excluding the trailing CRC-16), the protocol version, the profile version, extra octets in the header other than documented 4 values, the header CRC-16 recorded in the header, and the calculated header CRC-16.

- fetch()

    reads a message in the .FIT file, and returns `1` on success, or `undef` on failure or EOF. `fetch_header()` must have been called before the first attempt to `fetch()` after opening the file.

    If a data message callback is registered, `fetch()` will return the value returned by the callback. It is therefore important to define explicit return statements and values in any callback (this includes returning true if that is the desired outcome after `fetch()`).

- error()

    returns an error message recorded by a method.

- crc()

    CRC-16 calculated from the contents of a .FIT file.

- crc\_expected()

    CRC-16 attached to the end of a .FIT file. Only available after all contents of the file has been read.

- trailing\_garbages()

    number of octets after CRC-16, 0 usually.

- data\_message\_callback\_by\_num(_message number_, _callback function_\[, _callback data_, ...\])

    register a function _callback function_ which is called when a data message with the messag number _message number_ is fetched.

- data\_message\_callback\_by\_name(_message name_, _callback function_\[, _callback data_, ...\])

    register a function _callback function_ which is called when a data message with the name _message name_ is fetched.

- switched(_data message descriptor_, _array of values_, _data type table_)

    returns real data type attributes for a C's union like field.

- fields\_list( $descriptor \[, keep\_unknown => $boole )

    Given a data message descriptor (_$descriptor_), returns the list of fields described in it. If `keep_unknown` is set to true, unknown field names will also be listed.

- fields\_defined( $descriptor, $values )

    Given a data message descriptor (_$descriptor_) and a corresponding data array reference of values (_$values_), returns the list of fields whose value is defined. Unknow field names are never listed.

- field\_value( _$field_, _$descriptor_, _$values_ )

    Returns the value of the field named _$field_ (a string).

    The other arguments consist of the data message descriptor (_$descriptor_, a hash reference) and the values fetched from a data message (_$values_, an array reference). These are simply the references passed to data message callbacks by `fetch()`, if any are registered, and are simply to be passed on to this method (please do not modifiy them).

    For example, we can define and register a callback for `file_id` data messages and get the name of the manufacturer of the device that recorded the FIT file:

        my $file_id_callback = sub {
            my ($self, $descriptor, $values) = @_;
            my $value = $self->field_value( 'manufacturer', $descriptor, $values );

            print "The manufacturer is: ", $value, "\n"
            };

        $fit->data_message_callback_by_name('file_id', $file_id_callback ) or die $fit->error;

        1 while ( $fit->fetch );

- field\_value\_as\_read( _$field_, _$descriptor_, _$value_ \[, $type\_name\_or\_aref \] )

    Converts the value parsed and returned by `field_value()` back to what it was when read from the FIT file and returns it.

    This method is mostly for developers or if there is a particular need to inspect the data more closely, it should seldomly be used. Arguments are similar to `field_value()` except that a single value _$value_ is passed instead of an array reference. That value corresponds to the value the former method has or would have returned.

    As an example, we can obtain the actual value recorded in the FIT file for the manufacturer by adding these lines to the callback defined above:

            my $as_read = $self->field_value_as_read( 'manufacturer', $descriptor, $value );
            print "The manufacturer's value as recorded in the FIT file is: ", $as_read, "\n"

    The method will raise an exception if _$value_ would have been obtained by `field_value()` via an internal call to `switched()`. In that case, the type name or the original array reference of values that was passed to the callback must be provided as the last argument. Otherwise, there is no way to guess what the value read from the file may have been.

- value\_cooked(_type name_, _field attributes table_, _invalid_, _value_)

    This method is now deprecated and is no longer supported. Please use `field_value()` instead.

    converts _value_ to a (hopefully) human readable form.

- value\_uncooked(_type name_, _field attributes table_, _invalid_, _value representation_)

    This method is now deprecated and is no longer supported. Please use `field_value_as_read()` instead.

    converts a human readable representation of a datum to an original form.

- use\_gmtime(_boolean_)

    sets the flag which of GMT or local timezone is used for `date_time` type value conversion. Defaults to true.

- unit\_table(_unit_ => _unit conversion table_)

    sets _unit conversion table_ for _unit_.

- semicircles\_to\_degree(_boolean_)
- mps\_to\_kph(_boolean_)

    wrapper methods of `unit_table()` method. `semicircle_to_deg()` defaults to true.

- close()

    closes opened file handles.

- profile\_version\_string()

    Returns a string representation of the profile version used by the device or application that created the FIT file opened in the instance.

    `fetch_header()` must have been called at least once for this method to be able to return a value, will raise an exception otherwise.

## Functions

The following functions are provided. None are exported, they may be called as `Geo::FIT::message_name(20)`, `Geo::FIT::field_name('device_info', 4)` `Geo::FIT::field_number('device_info', 'product')`, etc.

- message\_name(_message spec_)

    returns the message name for _message spec_ or undef.

- message\_number(_message spec_)

    returns the message number for _message spec_ or undef.

- field\_name(_message spec_, _field spec_)

    returns the field name for _field spec_ in _message spec_ or undef.

- field\_number(_message spec_, _field spec_)

    returns the field index for _field spec_ in _message spec_ or undef.

## Constants

Following constants are exported: `FIT_ENUM`, `FIT_SINT8`, `FIT_UINT8`, `FIT_SINT16`, `FIT_UINT16`, `FIT_SINT32`, `FIT_UINT32`, `FIT_SINT64`, `FIT_UINT64`, `FIT_STRING`, `FIT_FLOAT16`, `FIT_FLOAT32`, `FIT_UINT8Z`, `FIT_UINT16Z`, `FIT_UINT32Z`, `FIT_UINT64Z`.

Also exported are:

- FIT\_BYTE

    numbers representing base types of field values in data messages.

- FIT\_BASE\_TYPE\_MAX

    the maximal number representing base types of field values in data messages.

- FIT\_HEADER\_LENGTH

    length of a .FIT file header.

## Data message descriptor

When `fetch` method meets a definition message, it creates a hash which includes various information about the corresponding data message. We call the hash a data message descriptor. It includes the following key value pairs.

- _field index_ => _field name_

    in a global .FIT profile.

- `local_message_type` => _local message type_

    necessarily.

- `message_number` => _message number_

    necessarily.

- `message_name` => _message name_

    only if the message is documented.

- `callback` => _reference to an array_

    of a callback function and callback data, only if a `callback` is registered.

- `endian` => _endian_

    of multi-octets data in this message, where 0 for littel-endian and 1 for big-endian.

- `template` => _template for unpack_

    used to convert the binary data to an array of Perl representations.

- `i_`_field name_ => _offset in data array_

    of the value(s) of the field named _field name_.

- `o_`_field\_name_ => _offset in binary data_

    of the value(s) of the field named _field name_.

- `c_`_field\_name_ => _the number of values_

    of the field named _field name_.

- `s_`_field\_name_ => _size in octets_

    of whole the field named _field name_ in binary data.

- `a_`_field name_ => _reference to a hash_

    of attributes of the field named _field name_.

- `t_`_field name_ => _type name_

    only if the type of the value of the field named _field name_ has a name.

- `T_`_field name_ => _a number_

    representing base type of the value of the field named _field name_.

- `N_`_field name_ => _a number_

    representing index of the filed named _field name_ in the global .FIT profile.

- `I_`_field name_ => _a number_

    representing the invalid value of the field named _field name_, that is, if the value of the field in a binary datum equals to this number, the field must be treated as though it does not exist in the datum.

- `endian_converter` => _reference to an array_

    used for endian conversion.

- `message_length` => _length of binary data_

    in octets.

- `array_length` => _length of data array_

    of Perl representations.

## Callback function

When `fetch` method meets a data message, it calls a _callback function_ registered with `data_message_callback_by_name` or `data_message_callback_by_num`,
in the form

- _callback function_->(_object_, _data message descriptor_, _array of field values_, _callback data_, ...).

    The return value of the function becomes the return value of `fetch`. It is expected to be `1` on success, or `undef` on failure status.

## Developer data

Fields in devloper data are given names of the form _developer data index_`_`_field definition number_`_`_converted field name_, and related informations are included _data message descriptors_ in the same way as the fields defined in the global .FIT profile.

Each _converted field name_ is made from the value of `field_name` field in the corresponding _field description message_, after the following conversion rules:

- (1) Each sequence of space characters is converted to single `_`.
- (2) Each of remaining non-word-constituend characters is converted to `_` + 2 column hex representation of `ord()` of the character + `_`.

## 64bit data

If your perl lacks 64bit integer support, you need the module `Math::BigInt`.

# DEPENDENCIES

Nothing in particular so far.

# SEE ALSO

[fit2tcx.pl](https://metacpan.org/pod/fit2tcx.pl), [fitdump.pl](https://metacpan.org/pod/fitdump.pl), [locations2gpx.pl](https://metacpan.org/pod/locations2gpx.pl), [Geo::TCX](https://metacpan.org/pod/Geo%3A%3ATCX), [Geo::Gpx](https://metacpan.org/pod/Geo%3A%3AGpx).

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to `bug-geo-gpx@rt.cpan.org`, or through the web interface at [http://rt.cpan.org](http://rt.cpan.org).

# AUTHOR

Originally written by Kiyokazu Suto `suto@ks-and-ks.ne.jp` with contributions by Matjaz Rihtar.

This version is maintained by Patrick Joly `<patjol@cpan.org>`.

Please visit the project page at: [https://github.com/patjoly/geo-fit](https://github.com/patjoly/geo-fit).

# VERSION

1.13

# LICENSE AND COPYRIGHT

Copyright 2022, Patrick Joly `patjol@cpan.org`. All rights reserved.

Copyright 2016-2022, Kiyokazu Suto `suto@ks-and-ks.ne.jp`. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
