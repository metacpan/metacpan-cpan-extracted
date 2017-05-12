# Creation date: 2007-02-19 16:54:44
# Authors: don
#
# Copyright (c) 2007-2010 Don Owens <don@regexguy.com>.  All rights reserved.
#
# This is free software; you can redistribute it and/or modify it under
# the Perl Artistic license.  You should have received a copy of the
# Artistic license with this distribution, in the file named
# "Artistic".  You may also obtain a copy from
# http://regexguy.com/license/Artistic
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.

# $Revision: 1737 $

# TODO
#   * support surrogate pairs as described in http://www.ietf.org/rfc/rfc4627.txt
#   * check for first surrogate: 0xD800 => 0xDBFF
#   * check for second surrogate: 0xDC00 => 0xDFFF
#   * take code point - 0x10000, add lower 10 bits to second surrogate, add upper 10 bits to first

=pod

=head1 NAME

JSON::DWIW - JSON converter that Does What I Want

=head1 SYNOPSIS

 use JSON::DWIW;
 my $json_obj = JSON::DWIW->new;
 my $data = $json_obj->from_json($json_str);
 my $str = $json_obj->to_json($data);
 
 my ($data, $error_string) = $json_obj->from_json($json_str);
 
 my $data = JSON::DWIW::deserialize($json_str);
 my $error_str = JSON::DWIW::get_error_string();
 
 use JSON::DWIW qw/deserialize_json from_json/
 my $data = deserialize_json($json_str);
 my $error_str = JSON::DWIW::get_error_string();
 
 my $error_string = $json_obj->get_error_string;
 my $error_data = $json_obj->get_error_data;
 my $stats = $json_obj->get_stats;
 
 my $data = $json_obj->from_json_file($file)
 my $ok = $json_obj->to_json_file($data, $file);
 
 my $data = JSON::DWIW->from_json($json_str);
 my $str = JSON::DWIW->to_json($data);
 
 my $data = JSON::DWIW->from_json($json_str, \%options);
 my $str = JSON::DWIW->to_json($data, \%options);
 
 my $true_value = JSON::DWIW->true;
 my $false_value = JSON::DWIW->false;
 my $data = { var1 => "stuff", var2 => $true_value,
              var3 => $false_value, };
 my $str = JSON::DWIW->to_json($data);

 my $data = JSON::DWIW::deserialize($str, { start_depth => 1,
                                            start_depth_handler => $handler });


=head1 DESCRIPTION

Other JSON modules require setting several parameters before
calling the conversion methods to do what I want.  This module
does things by default that I think should be done when working
with JSON in Perl.  This module also encodes and decodes faster
than L<JSON>.pm and L<JSON::Syck> in my benchmarks.

This means that any piece of data in Perl (assuming it's valid
unicode) will get converted to something in JSON instead of
throwing an exception.  It also means that output will be strict
JSON, while accepted input will be flexible, without having to
set any options.

For a list of changes in recent versions, see the documentation
for L<JSON::DWIW::Changes>.

This module can be downloaded from L<http://www.cpan.org/authors/id/D/DO/DOWENS/>.

=head2 Encoding

Perl objects get encoded as their underlying data structure, with
the exception of L<Math::BigInt> and L<Math::BigFloat>, which will be
output as numbers, and L<JSON::DWIW::Boolean>, which will get output
as a true or false value (see the true() and false() methods).
For example, a blessed hash ref will be represented as an object
in JSON, a blessed array will be represented as an array. etc.  A
reference to a scalar is dereferenced and represented as the
scalar itself.  Globs, Code refs, etc., get stringified, and
undef becomes null.

Scalars that have been used as both a string and a number will be
output as a string.  A reference to a reference is currently
output as an empty string, but this may change.

You may notice there is a deserialize function, but not a
serialize one.  The deserialize function was written as a full
rewrite (the parsing is in a separate, event-based library now)
of from_json (now from_json calls deserialize).  In the future,
there will be a serialize function that is a rewrite of to_json.

=head2 Decoding

Input is expected to utf-8.  When decoding, null, true, and false
become undef, 1, and 0, repectively.  Numbers that appear to be
too long to be supported natively are converted to L<Math::BigInt>
or L<Math::BigFloat> objects, if you have them installed.
Otherwise, long numbers are turned into strings to prevent data
loss.

The parser is flexible in what it accepts and handles some
things not in the JSON spec:

=over 4

=item quotes

Both single and double quotes are allowed for quoting a string, e.g.,

=for pod2rst next-code-block: javascript

    [ "string1", 'string2' ]

=item bare keys

Object/hash keys can be bare if they look like an identifier, e.g.,

=for pod2rst next-code-block: javascript

    { var1: "myval1", var2: "myval2" }

=item extra commas

Extra commas in objects/hashes and arrays are ignored, e.g.,

=for pod2rst next-code-block: javascript

    [1,2,3,,,4,]

becomes a 4 element array containing 1, 2, 3, and 4.

=item escape sequences

Latin1 hexadecimal escape sequences (\xHH) are accepted, as in
Javascript.  Also, the vertical tab escape \v is recognized (\u000b).

=item comments

C, C++, and shell-style comments are accepted.  That is

=for pod2rst next-code-block: c++

 /* this is a comment */
 // this is a comment

 # this is also a comment

=back

=cut

use strict;
use warnings;

use 5.006_00;

use JSON::DWIW::Boolean;

package JSON::DWIW;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# work around utf-8 weirdness in Perl < 5.8
use utf8;

require Exporter;
require DynaLoader;
@ISA = qw(DynaLoader);

@EXPORT = ( );
@EXPORT_OK = ();
%EXPORT_TAGS = (all => [ 'to_json', 'from_json', 'deserialize_json' ]);

Exporter::export_ok_tags('all');

# change in POD as well!
our $VERSION = '0.47';

JSON::DWIW->bootstrap($VERSION);


{
    package JSON::DWIW::Exporter;
    use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA = qw(Exporter);

    *EXPORT = \@JSON::DWIW::EXPORT;
    *EXPORT_OK = \@JSON::DWIW::EXPORT_OK;
    *EXPORT_TAGS = \%JSON::DWIW::EXPORT_TAGS;

    *deserialize_json = \&JSON::DWIW::deserialize_json;

    sub import {
        JSON::DWIW::Exporter->export_to_level(2, @_);
    }

    sub to_json {
        return JSON::DWIW->to_json(@_);
    }

    sub from_json {
        # return JSON::DWIW->from_json(@_);
        return JSON::DWIW::deserialize(@_);
    }
}

sub import {
    JSON::DWIW::Exporter::import(@_);
}

{
    # workaround for weird importing bug on some installations
    local($SIG{__DIE__}); 
    eval qq{ 
        use Math::BigInt; 
        use Math::BigFloat;
    };
} 


=pod

=head1 METHODS

=head2 C<new(\%options)>

Create a new L<JSON::DWIW> object.

C<%options> is an optional hash of parameters that will change the
bahavior of this module when encoding to JSON.  You may also
pass these options as the second argument to C<to_json()> and
C<from_json()>.  The following options are supported:

=head3 I<bare_keys>

If set to a true value, keys in hashes will not be quoted when
converted to JSON if they look like identifiers.  This is valid
Javascript in current browsers, but not in JSON.

=head3 I<use_exceptions>

If set to a true value, errors found when converting to or from
JSON will result in C<die()> being called with the error message.
The default is to not use exceptions.

=head3 I<bad_char_policy>

This options indicates what should be done if bad characters are
found, e.g., bad utf-8 sequence.  The default is to return an
error and drop all the output.

The following values for bad_char_policy are supported:

=head4 I<error>

default action, i.e., drop any output built up and return an error

=head4 I<convert>

Convert to a utf-8 char using the value of the byte as a code
point.  This is basically the same as assuming the bad character
is in latin-1 and converting it to utf-8.

=head4 I<pass_through>

Ignore the error and pass through the raw bytes (invalid JSON)

=head3 I<escape_multi_byte>

If set to a true value, escape all multi-byte characters (e.g.,
\u00e9) when converting to JSON.

=head3 I<ascii>

Synonym for escape_multi_byte

=head3 I<pretty>

Add white space to the output when calling to_json() to make the
output easier for humans to read.

=head3 I<convert_bool>

When converting from JSON, return objects for booleans so that
"true" and "false" can be maintained when encoding and decoding.
If this flag is set, then "true" becomes a L<JSON::DWIW::Boolean>
object that evaluates to true in a boolean context, and "false"
becomes an object that evaluates to false in a boolean context.
These objects are recognized by the to_json() method, so they
will be output as "true" or "false" instead of "1" or "0".

=head3 I<bare_solidus>

Don't escape solidus characters ("/") in strings.  The output is
still legal JSON with this option turned on.

=head3 I<minimal_escaping>

Only do required escaping in strings (solidus and quote).  Tabs,
newlines, backspaces, etc., will not be escaped with this
optioned turned on (but the output will still be valid JSON).

=head3 I<sort_keys>

Set to a true value to sort hash keys (alphabetically) when converting to JSON.

=head3 I<parse_number>

A subroutine reference to call when parsing a number.  The
subroutine will be provided one string that is the number being
parsed.  The return value from the subroutine will be used to
populate the return data instead of converting to a number.

E.g.,

  my $json = '{ "a": 6.3e-10 }';
  my $cb = sub { my ($val) = @_; return "I got the number '$val'"; };
 
  my $data = JSON::DWIW::deserialize($json, { parse_number => $cb });

=head3 I<parse_constant>

A subroutine reference to call when parsing a constant (true,
false, or null).  The subroutine will be provided one string that
is the constant being parsed.  The return value from the
subroutine will be used to populate the return data instead of
converting to a boolean or undef.  See the "parse_number" option.

=head3 I<start_depth>

Depth at which C<start_depth_handler> should be called.  See L</start_depth_handler>.

=head3 I<start_depth_handler>

A reference to a subroutine to called when parsing and at level
I<start_depth> in the data structure.  When specified along with I<start_depth>, the
parser does not return the entire data structure.  Instead, it
calls I<start_depth_handler> for each element in the array when
the parser is at level I<start_depth>.  This is useful for
parsing a very large array without loading all the data into
memory (especially when using C<deserialize_file>).

E.g., with I<start_depth> set to 1 and I<start_depth_handler> set to C<$handler>:

    my $str = '[ { "foo": "bar", "cat": 1 }, { "concat": 1, "lambda" : [ "one", 2, 3 ] } ]';
 
    my $foo = { foo => [ ] };
    my $handler = sub { push @{$foo->{foo}}, $_[0]; return 1; };
 
    my $data = JSON::DWIW::deserialize($str, { start_depth => 1,
                                               start_depth_handler => $handler });
    print STDERR Data::Dumper->Dump([ $foo ], [ 'foo' ]) . "\n";
    print STDERR Data::Dumper->Dump([ $data ], [ 'leftover_data' ]) . "\n";

    # Output
    $foo = {
             'foo' => [
                        {
                          'cat' => 1,
                          'foo' => 'bar'
                        },
                        {
                          'lambda' => [
                                      'one',
                                      2,
                                      3
                                    ],
                          'concat' => 1
                        }
                      ]
           };


    $leftover_data = [];

=cut

sub new {
    my $proto = shift;

    my $self = bless {}, ref($proto) || $proto;
    my $params = shift;
    
    return $self unless $params;

    unless (defined($params) and UNIVERSAL::isa($params, 'HASH')) {
        return $self;
    }

    foreach my $field (qw/bare_keys use_exceptions bad_char_policy dump_vars pretty
                          escape_multi_byte convert_bool detect_circular_refs
                          ascii bare_solidus minimal_escaping
                          parse_number parse_constant sort_keys start_depth start_depth_handler/) {
        if (exists($params->{$field})) {
            $self->{$field} = $params->{$field};
        }
    }

    return $self;
}

=pod

=head2 C<to_json>

Returns the JSON representation of $data (arbitrary
datastructure).  See http://www.json.org/ for details.

Called in list context, this method returns a list whose first
element is the encoded JSON string and the second element is an
error message, if any.  If $error_msg is defined, there was a
problem converting to JSON.  You may also pass a second argument
to to_json() that is a reference to a hash of options -- see
new().

     my $json_str = JSON::DWIW->to_json($data);
 
     my ($json_str, $error_msg) = JSON::DWIW->to_json($data);
 
     my $json_str = JSON::DWIW->to_json($data, { use_exceptions => 1 });

Aliases: toJson, toJSON, objToJson

=cut

sub to_json {
    my $proto = shift;
    my $data;
    
    my $self;
    if (UNIVERSAL::isa($proto, 'JSON::DWIW')) {
        $data = shift;
        my $options = shift;
        if ($options) {
            if (ref($proto) and $proto->isa('HASH')) {
                if (UNIVERSAL::isa($options, 'HASH')) {
                    $options = { %$proto, %$options };
                }
            }

            $self = $proto->new($options, @_);
        }
        else {
            $self = ref($proto) ? $proto : $proto->new(@_);
        }
    }
    else {
        $data = $proto;
        $self = JSON::DWIW->new(@_);
    }

    my $error_msg;
    my $error_data;
    my $stats_data = { };
    my $str = _xs_to_json($self, $data, \$error_msg, \$error_data, $stats_data);

    if ($stats_data) {
        $JSON::DWIW::Last_Stats = $stats_data;
        $self->{last_stats} = $stats_data;
    }

    $JSON::DWIW::LastError = $error_msg;
    $self->{last_error} = $error_msg;

    $JSON::DWIW::LastErrorData = $error_data;
    $self->{last_error_data} = $error_data;

    if (defined($error_msg) and $self->{use_exceptions}) {
        die $error_msg;
    }
    return wantarray ? ($str, $error_msg) : $str;
}
{
    no warnings 'once';
    
    *toJson = \&to_json;
    *toJSON = \&to_json;
    *objToJson = \&to_json;
}

sub serialize {
    my $data = shift;
    my $options = shift || { };

    my $error_msg;
    my $error_data;
    my $stats_data = { };
    my $str = _xs_to_json($options, $data, \$error_msg, \$error_data, $stats_data);

    if ($stats_data) {
        $JSON::DWIW::Last_Stats = $stats_data;
    }

    $JSON::DWIW::LastError = $error_msg;

    $JSON::DWIW::LastErrorData = $error_data;

    return $str;
}

# total process size in pages
sub get_proc_size {
    if ($^O eq 'linux') {
        my $statm_path = "/proc/$$/statm";
        if (-e $statm_path) {
            open(my $in_fh, '<', $statm_path) or return undef;
            my $statm = <$in_fh>;
            close $in_fh;
            
            my @fields = split /\s+/, $statm;
            
            return $fields[0];
        }
    }

    return undef;
}

=pod

=head2 C<deserialize($json_str, \%options)>

Returns the Perl data structure for the given JSON string.  The
value for true becomes 1, false becomes 0, and null gets
converted to undef.

This function should not be called as a method (for performance
reasons).  Unlike C<from_json()>, it returns a single value, the
data structure resulting from the conversion.  If the return
value is undef, check the result of the C<get_error_string()>
function/method to see if an error is defined.

=head2 C<deserialize_file($file, \%options)>

Same as deserialize, except that it takes a file as an argument.
On Unix, this mmap's the file, so it does not load a big file
into memory all at once, and does less buffer copying.

=cut

=pod

=head2 C<from_json>

Similar to C<deserialize()>, but expects to be called as a method.

Called in list context, this method returns a list whose first
element is the data and the second element is the error message,
if any.  If C<$error_msg> is defined, there was a problem parsing
the JSON string, and C<$data> will be undef.  You may also pass a
second argument to C<from_json()> that is a reference to a hash of
options -- see C<new()>.

     my $data = from_json($json_str)
 
     my ($data, $error_msg) = from_json($json_str)


Aliases: fromJson, fromJSON, jsonToObj

=cut

sub from_json {
    my $proto = shift;
    my $json;
    my $self;

    if (UNIVERSAL::isa($proto, 'JSON::DWIW')) {
        $json = shift;
        my $options = shift;
        if ($options) {
            if (ref($proto) and $proto->isa('HASH')) {
                if (UNIVERSAL::isa($options, 'HASH')) {
                    $options = { %$proto, %$options };
                }
            }

            $self = $proto->new($options, @_);
        }
        else {
            $self = ref($proto) ? $proto : $proto->new(@_);
        }
    }
    else {
        $json = $proto;
        $self = JSON::DWIW->new(@_);
    }

    my $data;
    if (%$self) {
        $data = JSON::DWIW::deserialize($json, $self);
    }
    else {
        $data = JSON::DWIW::deserialize($json);
    }

    $self->{last_error} = $JSON::DWIW::LastError;
    $self->{last_error_data} = $JSON::DWIW::LastErrorData;
    $self->{last_stats} = $JSON::DWIW::Last_Stats;

    if (defined($JSON::DWIW::LastError) and $self->{use_exceptions}) {
        die $JSON::DWIW::LastError;
    }

    return wantarray ? ($data, $JSON::DWIW::LastError) : $data;
}

{
    no warnings 'once';
    *jsonToObj = \&from_json;
    *fromJson = \&from_json;
    *fromJSON = \&from_json;
}

=pod

=head2 C<from_json_file>

Similar to C<deserialize_file()>, except that it expects to be
called a a method, and it also returns the error, if any, when called
in list context.

my ($data, $error_msg) = $json->from_json_file($file, \%options)

=cut
sub from_json_file {
    my $proto = shift;
    my $file;
    my $self;
        
    if (UNIVERSAL::isa($proto, 'JSON::DWIW')) {
        $file = shift;
        my $options = shift;
        if ($options) {
            if (ref($proto) and $proto->isa('HASH')) {
                if (UNIVERSAL::isa($options, 'HASH')) {
                    $options = { %$proto, %$options };
                }
            }

            $self = $proto->new($options, @_);
        }
        else {
            $self = ref($proto) ? $proto : $proto->new(@_);
        }
    }
    else {
        $file = $proto;
        $self = JSON::DWIW->new(@_);
    }

    my $data;
    if (%$self) {
        $data = JSON::DWIW::deserialize_file($file, $self);
    }
    else {
        $data = JSON::DWIW::deserialize_file($file);
    }

    $self->{last_error} = $JSON::DWIW::LastError;
    $self->{last_error_data} = $JSON::DWIW::LastErrorData;
    $self->{last_stats} = $JSON::DWIW::Last_Stats;

    if (defined($JSON::DWIW::LastError) and $self->{use_exceptions}) {
        die $JSON::DWIW::LastError;
    }

    return wantarray ? ($data, $JSON::DWIW::LastError) : $data;
}

=pod

=head2 C<to_json_file>

Converts C<$data> to JSON and writes the result to the file C<$file>.
Currently, this is simply a convenience routine that converts
the data to a JSON string and then writes it to the file.

 my ($ok, $error) = $json->to_json_file($data, $file, \%options);

=cut
sub to_json_file {
    my $proto = shift;
    my $file;
    my $data;
    my $self;
        
    if (UNIVERSAL::isa($proto, 'JSON::DWIW')) {
        $data = shift;
        $file = shift;
        my $options = shift;
        if ($options) {
            if (ref($proto) and $proto->isa('HASH')) {
                if (UNIVERSAL::isa($options, 'HASH')) {
                    $options = { %$proto, %$options };
                }
            }

            $self = $proto->new($options, @_);
        }
        else {
            $self = ref($proto) ? $proto : $proto->new(@_);
        }
    }
    else {
        $data = $proto;
        $file = shift;
        $self = JSON::DWIW->new(@_);
    }

    my $out_fh;
    unless (open($out_fh, '>', $file)) {
        my $msg = "JSON::DWIW v$VERSION - couldn't open output file $file";
        if ($self->{use_exceptions}) {
            die $msg;
        } else {
            return wantarray ? ( undef, $msg ) : undef;
        }
    }

    if ($] >= 5.008) {
        binmode($out_fh, 'utf8');
    }

    my $error_msg;
    my $error_data;
    my $stats_data = { };
    my $str = _xs_to_json($self, $data, \$error_msg, \$error_data, $stats_data);

    if ($stats_data) {
        $JSON::DWIW::Last_Stats = $stats_data;
        $self->{last_stats} = $stats_data;
    }

    $JSON::DWIW::LastError = $error_msg;
    $self->{last_error} = $error_msg;

    $JSON::DWIW::LastErrorData = $error_data;
    $self->{last_error_data} = $error_data;


    if (defined($error_msg) and $self->{use_exceptions}) {
        die $error_msg;
    }

    if ($error_msg) {
        return wantarray ? (undef, $error_msg) : undef;
    }

    print $out_fh $str;
    close $out_fh;

    return wantarray ? (1, $error_msg) : 1;
}

sub parse_mmap_file {
    my $proto = shift;
    my $file = shift;

    my $error_msg;
    my $self = $proto->new;

    my $data = _parse_mmap_file($self, $file, \$error_msg);
    if ($error_msg) {
        return wantarray ? (undef, $error_msg) : undef;
    }
}

=pod

=head2 C<get_error_string>

Returns the error message from the last call, if there was one, e.g.,

 my $data = JSON::DWIW->from_json($json_str)
     or die "JSON error: " . JSON::DWIW->get_error_string;
 
 my $data = $json_obj->from_json($json_str)
     or die "JSON error: " . $json_obj->get_error_string;


Aliases: get_err_str(), errstr()

=cut
sub get_error_string {
    my $self = shift;

    if (ref($self)) {
        return $self->{last_error};
    }
    
    return $JSON::DWIW::LastError;
}
*get_err_str = \&get_error_string;
*errstr = \&get_error_string;

=pod

=head2 C<get_error_data>

Returns the error details from the last call, in a hash ref, e.g.,

 $error_data = {
                'byte' => 23,
                'byte_col' => 23,
                'col' => 22,
                'char' => 22,
                'version' => '0.15a',
                'line' => 1
              };

This is really only useful when decoding JSON.

Aliases: get_error(), error()

=cut
sub get_error_data {
    my $self = shift;

    if (ref($self)) {
        return $self->{last_error_data};
    }

    return $JSON::DWIW::LastErrorData;
}
*get_error = \&get_error_data;
*error = \&get_error_data;

=pod

=head2 C<get_stats>

Returns statistics from the last method called to encode or
decode.  E.g., for an encoding (C<to_json()> or C<to_json_file()>),

    $stats = {
               'bytes' => 78,
               'nulls' => 1,
               'max_string_bytes' => 5,
               'max_depth' => 2,
               'arrays' => 1,
               'numbers' => 6,
               'lines' => 1,
               'max_string_chars' => 5,
               'strings' => 6,
               'bools' => 1,
               'chars' => 78,
               'hashes' => 1
             };

=cut
sub get_stats {
    my $self = shift;
    if (ref($self)) {
        return $self->{last_stats};
    }

    return $JSON::DWIW::Last_Stats;
}
*stats = \&get_stats;


=pod

=head2 C<true>

Returns an object that will get output as a true value when encoding to JSON.

=cut

sub true {
    return JSON::DWIW::Boolean->true;
}

=pod

=head2 C<false>

Returns an object that will get output as a false value when encoding to JSON.

=cut

sub false {
    return JSON::DWIW::Boolean->false;
}

sub _escape_xml_body {
    my ($text) = @_;
    return undef unless defined $text;

    # FIXME: benchmark this and test fully
    #         $text =~ s/([&<>"'])/$Escape_Map->{$1}/eg;
    #         return $text;
        
    $text =~ s/\&/\&amp;/g;
    $text =~ s/</\&lt;/g;
    $text =~ s/>/\&gt;/g;

    return $text;
}

sub _escape_xml_attr {
    my ($text) = @_;
    return undef unless defined $text;

    # FIXME: benchmark this and test fully
    #         $text =~ s/([&<>"'])/$Escape_Map->{$1}/eg;
    #         return $text;
        
    $text =~ s/\&/\&amp;/g;
    $text =~ s/</\&lt;/g;
    $text =~ s/>/\&gt;/g;
    $text =~ s/\"/\&quot;/g;

    return $text;
}

sub _to_xml {
    my ($data, $level, $params, $parent_tag) = @_;

    return '' unless defined $data;
    
    $params = { } unless $params and UNIVERSAL::isa($params, 'HASH');
    $level ||= 0;
    
    my $xml = '';

    my $ref = ref($data);

    unless ($ref) {
        # string
        return _escape_xml_body($data);
    }

    my $indent = $params->{pretty} ? ('  ' x $level) : '';
    my $nl = $params->{pretty} ? "\n" : '';
    my $start = ($params->{pretty} and $level) ? "\n" : '';
    my $end = ($params->{pretty} and $level >= 2) ? ('  ' x ($level - 1)) : '';
    my $first = 1;

    if ($ref eq 'ARRAY') {
        foreach my $e (@$data) {
            $xml .= "$start$indent<$parent_tag>";
            $xml .= _to_xml($e, $level + 1, $params, $parent_tag);
            $xml .= "</$parent_tag>$nl$end";
        }
        continue {
            $first = 0;
        }

        return $xml;
    }
    elsif ($ref eq 'HASH') {
        foreach my $k (sort keys %$data) {
            $start = '' unless $first;
            (my $tag = $k) =~ s/[^\w-]/_/g;
            my $this_ref = ref($data->{$k});
            if ($this_ref and $this_ref eq 'ARRAY') {
                $xml .= _to_xml($data->{$k}, $level, $params, $tag);
                next;
            }
            
            $xml .= "$start$indent<$tag>";
            $xml .= _to_xml($data->{$k}, $level + 1, $params, $tag);
            $xml .= "</$tag>$nl$end";
        }
        continue {
            $first = 0;
        }

        return $xml;
    }
    else {
        # make sure objects are stringified, e.g., Math::BigInt
        return _escape_xml_body($data . '');
    }

    return $xml;
}

sub _data_to_xml {
    my ($data, $params) = @_;
    
    return _to_xml($data, 0, $params);
}


=pod

=head2 C<json_to_xml($json, \%params)>

This function (not a method) converts the given JSON to XML.
Hash/object keys become tag names.  Arrays that are hash values
are output as multiple tags with the hash key as the tag name.

Any characters in hash keys not in C<[\w-]> (i.e., letters, numbers,
underscore, or dash), get converted to underscore ("_") when
output as XML tags.

Valid parameters in C<\%params> are the same as for passing
to C<deserialize()> or C<from_json()>, plus the C<pretty> option, which
will add newlines and indentation to the XML to make it more
human-readable.

=cut
sub json_to_xml {
    my ($json, $params) = @_;

    my $data;
    if ($params) {
        $data = JSON::DWIW::deserialize($json, $params);
    }
    else {
        $data = JSON::DWIW::deserialize($json);
    }

    my $ref = ref($data);
    if ($ref and $ref eq 'ARRAY') {
        warn "top level of data must be an object/hash ref in json_to_xml() call";
        return undef;
    }

    return _data_to_xml($data, $params);
}

sub jsonml_to_xml {
    my ($jsonml) = @_;

    my $elements = JSON::DWIW::deserialize($jsonml);
    return undef unless defined $elements;

    return _jsonml_xml($elements);
}

sub _jsonml_xml {
    my ($elements) = @_;

    unless (ref($elements)) {
        # string
        return _escape_xml_body($elements);
    }

    my $name = $elements->[0];
    my $attrs = $elements->[1];
    my $attr_str = '';

    my @rest;
    if (defined $attrs and UNIVERSAL::isa($attrs, 'HASH')) {
        my @keys = sort keys %$attrs;
        my @pairs = map { qq{$_="} . _escape_xml_attr($attrs->{$_}) . qq{"} } @keys;
        $attr_str = ' ' . join(' ', @pairs);
        @rest = @$elements[2 .. $#$elements];
    }
    else {
        $attrs = undef;
        @rest = @$elements[1 .. $#$elements];
    }
    
    my $xml = "<$name$attr_str";

    if (@rest) {
        $xml .= '>';
        foreach my $e (@rest) {
            $xml .= _jsonml_xml($e);
        }
        $xml .= "</$name>";
    }
    else {
        $xml .= '/>';
    }

    return $xml;
}

# used from XS code to sort keys in Perl < 5.8.0 where we don't have
# access to sortsv() from XS
sub _sort_keys {
    return [ sort keys %{ $_[0] } ]
}


=pod

=head1 Utilities

Following are some methods I use for debugging and testing.

=head2 C<flagged_as_utf8($str)>

Returns true if the given string is flagged as utf-8.

=head2 C<flag_as_utf8($str)>

Flags the given string as utf-8.

=head2 C<unflag_as_utf8($str)>

Clears the flag that tells Perl the string is utf-8.

=head2 C<is_valid_utf8($str)>

Returns true if the given string is valid utf-8 (regardless of the flag).

=head2 C<upgrade_to_utf8($str)>

Converts the string to utf-8, assuming it is latin1.  This effects $str itself in place, but also returns $str.

=head2 C<code_point_to_utf8_str($cp)>

Returns a utf8 string containing the byte sequence for the given code point.

=head2 C<code_point_to_hex_bytes($cp)>

Returns a string representing the byte sequence for $cp encoding in utf-8.  E.g.,

 my $hex_bytes = JSON::DWIW->code_point_to_hex_bytes(0xe9);
 print "$hex_bytes\n"; # \xc3\xa9

=head2 C<bytes_to_code_points($str)>

Returns a reference to an array of code points from the given string, assuming the string is encoded in utf-8.

=head2 C<peek_scalar($scalar)>

Dumps the internal structure of the given scalar.

=head1 BENCHMARKS

Need new benchmarks here.

=head1 DEPENDENCIES

Perl 5.6 or later

=head1 BUGS/LIMITATIONS

If you find a bug, please file a tracker request at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=JSON-DWIW>.

When decoding a JSON string, it is a assumed to be utf-8 encoded.
The module should detect whether the input is utf-8, utf-16, or
utf-32.

=head1 AUTHOR

Don Owens <don@regexguy.com>

=head1 ACKNOWLEDGEMENTS

Thanks to Asher Blum for help with testing.

Thanks to Nigel Bowden for helping with compilation on Windows.

Thanks to Robert Peters for discovering and tracking down the source of a number parsing bug.

Thanks to Mark Phillips for helping with a bug under Solaris on Sparc.

Thanks to Josh for helping debug [rt.cpan.org #47344].

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007-2010 Don Owens <don@regexguy.com>.  All rights reserved.

This is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See perlartistic.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.

=head1 SEE ALSO

=over 4

=item The JSON home page: L<http://json.org/>

=item The JSON spec: L<http://www.ietf.org/rfc/rfc4627.txt>

=item  The JSON-RPC spec: L<http://json-rpc.org/wd/JSON-RPC-1-1-WD-20060807.html>

=item L<JSON>

=item L<JSON::Syck> (included in L<YAML::Syck>)

=back

=cut

1;

# Local Variables: #
# mode: perl #
# tab-width: 4 #
# indent-tabs-mode: nil #
# cperl-indent-level: 4 #
# perl-indent-level: 4 #
# End: #
# vim:set ai si et sta ts=4 sw=4 sts=4:
