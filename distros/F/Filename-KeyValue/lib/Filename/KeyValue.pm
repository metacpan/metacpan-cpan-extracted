package Filename::KeyValue;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
use URI::Escape qw();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-27'; # DATE
our $DIST = 'Filename-KeyValue'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       parse_keyvalue_filename
               );
                       # normalize_keyvalue_filename

our %SPEC;

sub _decode_val {
    my ($opts, $kv, $key, $val) = @_;

    my @old_vals = exists($kv->{$key}) ? (ref($kv->{$key}) eq 'ARRAY' ? @{ $kv->{$key} } : ($kv->{$key})) : ();
    my @new_vals = split /,/, ($opts->{decode_value} ? URI::Escape::uri_unescape($val) : $val);
    my @vals = (@old_vals, @new_vals);
    if ($opts->{array_value} || @vals > 1) {
        $val = \@vals;
    } else {
        $val = $vals[0];
    }
}

$SPEC{parse_keyvalue_filename} = {
    v => 1.1,
    summary => 'Parse filename using the KeyValue naming scheme',
    description => <<'MARKDOWN',

The KeyValue naming scheme puts key=value pairs at the end of filename. Filename
must match this regex:

    /\A
     (?:
      (.+?)                                 # optional prefix (part before the first key)
      -
     )?
     (
     (?:
       ([A-Za-z_][A-Za_z0-9_]*)              # key
       =
       ([^-]*)                               # value
     )
     (?:
       -
       ([A-Za-z_][A-Za_z0-9_]*)
       =
       ([^-]*)
     )*
     (\.\w+)?                                # optional filename extension
     \z/x

KeyValue naming scheme is used in the AssetView media assets organization scheme
(see <pm:Media::AssetView>).

This routine parses a filename and return a structure containing parsed
elements.

MARKDOWN
    args => {
        filename => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        array_value => {
            summary => 'Always/never/maybe return value as array',
            schema => ['int*', in => [0,1,2]],
            default => 1,
            description => <<'MARKDOWN',

The default (1) is to return a scalar when there is a single value, or an array
if there are multiple values, for example:

    foo-kw1=val1-kw2=val2,val2b-kw3=val3-kw1=val1b.jpg

then:

    kw1 = ['val1', 'val1b']
    kw2 = ['val2', 'val2b']
    kw3 = 'val3'

The setting 0 means to never return array, so will return a comma-separated
string instead. However, if the value is URI-decoded then this can potentially
be ambiguous:

    kw1=val1,val2-kw1=val3%2cval4.jpg

under array_value=0 and decode_value=1 will return:

    kw1 = 'val1,val2,val3,val4'

while under array_value=1 or 2 will return 3 elements:

    kw1 = ['val1', 'val2', 'val3,val4']

MARKDOWN
        },
        decode_value => {
            summary => 'Whether to decode value with URI-encoding',
            schema => 'bool*',
            default => 1,
        },
        # opt: case_insensitive
        # opt: check duplicate key
        # opt: required_keys
        # opt: required_value or schema for values
    },
    examples => [
        {
            args => {filename=>'foo-bar-kw1=val1.jpg'},
            summary => 'A single key=value pair',
        },
        {
            args => {filename=>'foo-bar-kw1=val1-kw2=val2.jpg'},
            summary => 'Two key=value pairs',
        },
        {
            args => {filename=>'foo-bar-kw1=val1,val1b.jpg'},
            summary => 'A single key=value pair containing two values',
        },
        {
            args => {filename=>'foo-bar-kw1=val1-kw2=val2,val2b,val2c-kw3=val3.jpg'},
            summary => 'Three key=value pairs, one containing multiple values',
        },
        {
            args => {filename=>'foo-bar-kw1=-kw2=-kw3=val.jpg'},
            summary => 'Empty key=value pairs',
        },
        {
            args => {filename=>'foo-bar-kw1_containing_dash=containing%2ddash-kw2_also_containing_dash=containing%2Dtwo%2Ddashes.jpg'},
            summary => 'A value containing dash',
        },
        {
            args => {filename=>'foo-bar-kw1=containing%2ccomma.jpg'},
            summary => 'A value containing comma',
        },
    ],
};
sub parse_keyvalue_filename {
    my %args = @_;

    defined(my $filename = $args{filename}) or return [400, "Please specify filename"];
    my $res = {};

    my $opts = {};
    $opts->{array_value}  = delete($args{array_value}) // 0;
    $opts->{decode_value} = delete($args{decode_value}) // 1;

    length($filename) or return [400, "Filename cannot be empty"];
    $filename =~ s/\.(\w+)\z// and $res->{ext} = $1;

    $filename =~ /
                  \A
                  (?:
                      (.+?)                                     # optional prefix (part before the first key)
                      -
                  )?
                  (?:
                      (
                          (?:
                              (?:[A-Za-z_][A-Za-z0-9_]*)        # key
                              =
                              (?:[^-]*)                         # value
                          )
                          (?:
                              -
                              (?:
                                  (?:[A-Za-z_][A-Za-z0-9_]*)        # key
                                  =
                                  (?:[^-]*)                         # value
                              )
                          )*?
                      )
                  )?
                  \z/x
                      or return [400, "Invalid filename syntax, must be in (PREFIX-)?(KW=VAL)*(.EXT)? format"];
    $res->{prefix} = $1 // '';
    $res->{kv_raw} = $2 // '';
    $res->{kv} = {};
    if (length $res->{kv_raw}) {
        while ($res->{kv_raw} =~ /([A-Za-z_][^=]*)=([^-]+)/g) {
            $res->{kv}{$1} = _decode_val($opts, $res->{kv}, $1, $2);
        }
    }
    [200, "OK", $res];
}

1;
# ABSTRACT: Parse filename using the KeyValue naming scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::KeyValue - Parse filename using the KeyValue naming scheme

=head1 VERSION

This document describes version 0.001 of Filename::KeyValue (from Perl distribution Filename-KeyValue), released on 2026-04-27.

=head1 SYNOPSIS

 use Filename::KeyValue qw(
     parse_keyvalue_filename
     normalize_keyvalue_filename
 );

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 parse_keyvalue_filename

Usage:

 parse_keyvalue_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse filename using the KeyValue naming scheme.

Examples:

=over

=item * A single key=value pair:

 parse_keyvalue_filename(filename => "foo-bar-kw1=val1.jpg");

Result:

 [
   200,
   "OK",
   {
     ext => "jpg",
     kv => { kw1 => ["val1"] },
     kv_raw => "kw1=val1",
     prefix => "foo-bar",
   },
   {},
 ]

=item * Two key=value pairs:

 parse_keyvalue_filename(filename => "foo-bar-kw1=val1-kw2=val2.jpg");

Result:

 [
   200,
   "OK",
   {
     ext => "jpg",
     kv => { kw1 => ["val1"], kw2 => ["val2"] },
     kv_raw => "kw1=val1-kw2=val2",
     prefix => "foo-bar",
   },
   {},
 ]

=item * A single key=value pair containing two values:

 parse_keyvalue_filename(filename => "foo-bar-kw1=val1,val1b.jpg");

Result:

 [
   200,
   "OK",
   {
     ext => "jpg",
     kv => { kw1 => ["val1", "val1b"] },
     kv_raw => "kw1=val1,val1b",
     prefix => "foo-bar",
   },
   {},
 ]

=item * Three key=value pairs, one containing multiple values:

 parse_keyvalue_filename(filename => "foo-bar-kw1=val1-kw2=val2,val2b,val2c-kw3=val3.jpg");

Result:

 [
   200,
   "OK",
   {
     ext => "jpg",
     kv => { kw1 => ["val1"], kw2 => ["val2", "val2b", "val2c"], kw3 => ["val3"] },
     kv_raw => "kw1=val1-kw2=val2,val2b,val2c-kw3=val3",
     prefix => "foo-bar",
   },
   {},
 ]

=item * Empty key=value pairs:

 parse_keyvalue_filename(filename => "foo-bar-kw1=-kw2=-kw3=val.jpg");

Result:

 [
   200,
   "OK",
   {
     ext => "jpg",
     kv => { kw3 => ["val"] },
     kv_raw => "kw1=-kw2=-kw3=val",
     prefix => "foo-bar",
   },
   {},
 ]

=item * A value containing dash:

 parse_keyvalue_filename(filename => "foo-bar-kw1_containing_dash=containing%2ddash-kw2_also_containing_dash=containing%2Dtwo%2Ddashes.jpg");

Result:

 [
   200,
   "OK",
   {
     ext => "jpg",
     kv => {
       kw1_containing_dash      => ["containing-dash"],
       kw2_also_containing_dash => ["containing-two-dashes"],
     },
     kv_raw => "kw1_containing_dash=containing%2ddash-kw2_also_containing_dash=containing%2Dtwo%2Ddashes",
     prefix => "foo-bar",
   },
   {},
 ]

=item * A value containing comma:

 parse_keyvalue_filename(filename => "foo-bar-kw1=containing%2ccomma.jpg");

Result:

 [
   200,
   "OK",
   {
     ext => "jpg",
     kv => { kw1 => ["containing", "comma"] },
     kv_raw => "kw1=containing%2ccomma",
     prefix => "foo-bar",
   },
   {},
 ]

=back

The KeyValue naming scheme puts key=value pairs at the end of filename. Filename
must match this regex:

 /\A
  (?:
   (.+?)                                 # optional prefix (part before the first key)
   -
  )?
  (
  (?:
    ([A-Za-z_][A-Za_z0-9_]*)              # key
    =
    ([^-]*)                               # value
  )
  (?:
    -
    ([A-Za-z_][A-Za_z0-9_]*)
    =
    ([^-]*)
  )*
  (\.\w+)?                                # optional filename extension
  \z/x

KeyValue naming scheme is used in the AssetView media assets organization scheme
(see L<Media::AssetView>).

This routine parses a filename and return a structure containing parsed
elements.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<array_value> => I<int> (default: 1)

AlwaysE<sol>neverE<sol>maybe return value as array.

The default (1) is to return a scalar when there is a single value, or an array
if there are multiple values, for example:

 foo-kw1=val1-kw2=val2,val2b-kw3=val3-kw1=val1b.jpg

then:

 kw1 = ['val1', 'val1b']
 kw2 = ['val2', 'val2b']
 kw3 = 'val3'

The setting 0 means to never return array, so will return a comma-separated
string instead. However, if the value is URI-decoded then this can potentially
be ambiguous:

 kw1=val1,val2-kw1=val3%2cval4.jpg

under array_value=0 and decode_value=1 will return:

 kw1 = 'val1,val2,val3,val4'

while under array_value=1 or 2 will return 3 elements:

 kw1 = ['val1', 'val2', 'val3,val4']

=item * B<decode_value> => I<bool> (default: 1)

Whether to decode value with URI-encoding.

=item * B<filename>* => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-KeyValue>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-KeyValue>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-KeyValue>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
