# NAME

Geo::FIT - Decode Garmin FIT files

# SYNOPSIS

    use Geo::FIT;
    $fit = Geo::FIT->new();
    $fit->file( $fname )
    $fit->open;
    $fit->fetch_header;
    $fit->fetch;
    $fit->data_message_callback_by_name( $message name,   \&callback_function [, \%callback_data, ... ] );
    $fit->data_message_callback_by_num(  $message number, \&callback_function [, \%callback_data, ... ] );
    $fit->close;

# DESCRIPTION

`Geo::FIT` is a Perl class to provide interfaces to decode Garmin FIT files (\*.fit).

The module also provides a script to read and print the contents for FIT files (`fitdump.pl`), as well as a script to convert FIT files to TCX files (`fit2tcx.pl`).

## Constructor

- new()

    creates a new object and returns it.

## Class methods

- version\_string()

    returns a string representing the version of this class.

- message\_name(_message spec_)

    returns the message name for _message spec_ or undef.

- message\_number(_message spec_)

    returns the message number for _message spec_ or undef.

- field\_name(_message spec_, _field spec_)

    returns the field name for _field spec_ in _message spec_ or undef.

- field\_number(_message spec_, _field spec_)

    returns the field index for _field spec_ in _message spec_ or undef.

- cat\_header(_protocol version_, _profile version_, _file length_\[, _refrencne to a scalar_\])

    composes the binary form of a .FIT file header, concatenates the scalar and it, and returns the reference to the scalar. If the 4th argument is omitted, it returns the reference to the binary form. _file length_ is assumed not to include the file header and trailing CRC.

- crc\_of\_string(_old CRC_, _reference to a scalar_, _offset in scalar_, _counts_)

    calculate CRC-16 of the specified part of the scalar.

- my\_endian

    returns the endian (0 for little endian and 1 for big endian) of the current system.

## Object methods

- file(_file name_)

    sets the name _file name_ of a .FIT file.

- open()

    opens the .FIT file.

- fetch\_header()

    reads .FIT file header, and returns an array of the file size (excluding the trailing CRC-16), the protocol version, the profile version, extra octets in the header other than documented 4 values, the header CRC-16 recorded in the header, and the calculated header CRC-16.

- fetch()

    reads a message in the .FIT file, and returns `1` on success, or `undef` on failure or EOF.

- unit\_table(_unit_ => _unit conversion table_)

    sets _unit conversion table_ for _unit_.

- semicircles\_to\_degree(_boolean_)
- mps\_to\_kph(_boolean_)

    wrapper methods of `unit_table()` method.

- use\_gmtime(_boolean_)

    sets the flag which of GMT or local timezone is used for `date_time` type value conversion.

- protocol\_version\_string()

    returns a string representing the .FIT protocol version on which this class based.

- protocol\_version\_string(_version number_)

    returns a string representing the .FIT protocol version _version number_.

- profile\_version\_string()

    returns a string representing the .FIT protocol version on which this class based.

- profile\_version\_string(_version number_)()

    returns a string representing the .FIT profile version _version number_.

- data\_message\_callback\_by\_name(_message name_, _callback function_\[, _callback data_, ...\])

    register a function _callback function_ which is called when a data message with the name _message name_ is fetched.

- data\_message\_callback\_by\_num(_message number_, _callback function_\[, _callback data_, ...\])

    register a function _callback function_ which is called when a data message with the messag number _message number_ is fetched.

- switched(_data message descriptor_, _array of values_, _data type table_)

    returns real data type attributes for a C's union like field.

- string\_value(_array of values_, _offset in the array_, _counts_)

    converts an array of character codes to a Perl string.

- value\_cooked(_type name_, _field attributes table_, _invalid_, _value_)

    converts _value_ to a (hopefully) human readable form.

- value\_uncooked(_type name_, _field attributes table_, _invalid_, _value representation_)

    converts a human readable representation of a datum to an original form.

- error()

    returns an error message recorded by a method.

- crc\_expected()

    CRC-16 attached to the end of a .FIT file. Only available after all contents of the file has been read.

- crc()

    CRC-16 calculated from the contents of a .FIT file.

- trailing\_garbages()

    number of octets after CRC-16, 0 usually.

- close()

    closes opened file handles.

- cat\_definition\_message(_data message descriptor_\[, _reference to a scalar_\])

    composes the binary form of a definition message after _data message descriptor_, concatenates the scalar and it, and returns the reference to the scalar. If the 2nd argument is omitted, returns the reference to the binary form.

- endian\_convert(_endian converter_, _reference to a scalar_, _offset in the scalar_)

    apply _endian converter_ to the specified part of the scalar.

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

[Geo::TCX](https://metacpan.org/pod/Geo%3A%3ATCX)

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to `bug-geo-gpx@rt.cpan.org`, or through the web interface at [http://rt.cpan.org](http://rt.cpan.org).

# AUTHOR

Originally written by Kiyokazu Suto `suto@ks-and-ks.ne.jp` with contributions by Matjaz Rihtar.

This version is maintained by Patrick Joly `<patjol@cpan.org>`.

Please visit the project page at: [https://github.com/patjoly/geo-fit](https://github.com/patjoly/geo-fit).

# VERSION

1.03

# LICENSE AND COPYRIGHT

Copyright 2022, Patrick Joly `patjol@cpan.org`. All rights reserved.

Copyright 2016-2022, Kiyokazu Suto `suto@ks-and-ks.ne.jp`. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
