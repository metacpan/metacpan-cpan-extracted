package Filename::KeyValue;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
use Perinci::Object;
use Perinci::Sub::Util qw(gen_modified_sub);
use URI::Escape qw();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-05-28'; # DATE
our $DIST = 'Filename-KeyValue'; # DIST
our $VERSION = '0.004'; # VERSION

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
            schema => 'filename*',
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
            args => {filename=>'foo.jpg'},
            summary => 'No key=value pairs',
        },
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

    $filename =~ s!/+\z!!;

    length($filename) or return [400, "Filename cannot be empty"];
    $filename =~ s/\.(\w+)\z// and $res->{ext} = $1;

    $filename =~ /
                  \A
                  (?:
                      (.+?)                                     # optional prefix (part before the first key)
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
        $res->{prefix} =~ /-\z/ or return [400, "Invalid filename syntax, must be in PREFIX-(KW=VAL)*(.EXT)? format (2)"];
    }

    if (length $res->{kv_raw}) {
        while ($res->{kv_raw} =~ /([A-Za-z_][^=]*)=([^-]+)/g) {
            $res->{kv}{$1} = _decode_val($opts, $res->{kv}, $1, $2);
        }
    }
    [200, "OK", $res];
}

sub _normalize {
    my $parse_res = shift;

    my @kv = map {
        my $key = $_;
        "$key=" .
            join(
                ",",
                map { URI::Escape::uri_unescape($_) }
                @{ $parse_res->[2]{kv}{$key} }
            )} sort keys %{ $parse_res->[2]{kv} };

    return [
        200,
        "OK",
        join(
            "",
            $parse_res->[2]{prefix},
            (@kv ? "-" : ""),
            join("-", @kv),
            (defined $parse_res->[2]{ext} ? "." : ""),
            $parse_res->[2]{ext},
        ),
    ];
}

$SPEC{normalize_keyvalue_filename} = {
    v => 1.1,
    summary => 'Normalize filename that has the key-values following the KeyValue naming scheme',
    description => <<'MARKDOWN',

This routine will:

- sort the key-value using keys asciibetically;
- (NOT YET IMPLEMENTED) optionally sort the values asciibetically;
- (NOT YET IMPLEMENTED) customize key sorting using SortKey.
- (NOT YET IMPLEMENTED) customize value sorting using SortKey.

MARKDOWN
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {
            args => {filename=>'foo-bar-kw2=val2-kw1=val1.jpg'},
            summary => 'Sort keys',
        },
    ],
};
sub normalize_keyvalue_filename {
    my %args = @_;

    defined(my $filename = $args{filename}) or return [400, "Please specify filename"];
    my $parse_res = parse_keyvalue_filename(
        filename => $filename,
        decode_value => 1,
        array_value => 2,
    );
    return [500, "Can't parse filename: $parse_res->[0] - $parse_res->[1]"]
        unless $parse_res->[0] == 200;

    _normalize($parse_res);
}

$SPEC{modify_keyvalue_filename} = {
    v => 1.1,
    summary => 'Add/remove/replace key-values in filename that follow KeyValue naming scheme',
    description => <<'MARKDOWN',

This routine will:

- sort the key-value using keys asciibetically;
- (NOT YET IMPLEMENTED) optionally sort the values asciibetically;
- (NOT YET IMPLEMENTED) customize key sorting using SortKey.
- (NOT YET IMPLEMENTED) customize value sorting using SortKey.

MARKDOWN
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        add => {
            summary => 'List of key=>value pairs to add',
            schema => 'hash*',
        },
        remove => {
            summary => 'List of keys to remove',
            schema => ['array*', of=>'str*'],
        },
        replace => {
            summary => 'List of key=>value pairs to replace',
            schema => ['hash*'],
        },
    },
    examples => [
        {
            args => {filename=>'foo-bar-kw1=val1.jpg', add=>{kw2=>"val2"}},
            summary => 'Add a key',
        },
    ],
};
sub modify_keyvalue_filename {
    my %args = @_;

    defined(my $filename = $args{filename}) or return [400, "Please specify filename"];
    my $parse_res = parse_keyvalue_filename(
        filename => $filename,
        decode_value => 1,
        array_value => 2,
    );
    return [500, "Can't parse filename: $parse_res->[0] - $parse_res->[1]"]
        unless $parse_res->[0] == 200;

    if ($args{add} && keys %{$args{add}}) {
        for my $key (sort keys %{ $args{add} }) {
            $parse_res->[2]{kv}{$key} //= [];
            push @{ $parse_res->[2]{kv}{$key} }, $args{add}{$key};
        }
    }

    if ($args{remove} && @{$args{remove}}) {
        for my $key (@{ $args{remove} }) {
            delete $parse_res->[2]{kv}{$key};
        }
    }

    if ($args{replace} && keys %{$args{replace}}) {
        for my $key (sort keys %{ $args{replace} }) {
            $parse_res->[2]{kv}{$key} = $args{replace}{$key};
        }
    }

    _normalize($parse_res);
}

my $wrap_code = sub {
    my $orig = shift;

    my %args = @_;
    my $filenames = delete $args{filename};

    my $res_multi = envresmulti();
    for my $filename (@$filenames) {
        unless (-f $filename) {
            $res_multi->add_result(412, "Can't find file", {item_id=>$filename});
            next;
        }

        my $res = $orig->(%args, filename=>$filename);
        unless ($res->[0] == 200) {
            $res_multi->add_result(500, "Can't rename: $res->[0] - $res->[1]", {item_id=>$filename});
            next;
        }
        if ($res->[2] eq $filename) {
            $res_multi->add_result(304, "Not modified", {item_id=>$filename});
            next;
        }

        log_debug "Renaming %s to %s ...", $filename, $res->[2];
        if (rename $filename, $res->[2]) {
            $res_multi->add_result(200, "OK", {item_id=>$filename});
        } else {
            $res_multi->add_result(500, "Can't rename $filename to $res->[2]: $!", {item_id=>$filename});
        }
    }

    $res_multi->as_struct;
};

gen_modified_sub(
    die => 1,
    output_name => 'rename_add_keyvalue_filenames',
    base_name => 'modify_keyvalue_filename',
    remove_args => [qw/replace remove/],
    modify_args => {
        filename => sub {
            $_[0]{schema} = ["array*", of=>"str*"],
            $_[0]{slurpy} = 1;
        },
    },
    modify_meta => sub {
        my $meta = shift;
        delete $meta->{examples};
    },
    summary => 'Rename file by adding key=value pairs',
    wrap_code => $wrap_code,
);

gen_modified_sub(
    die => 1,
    output_name => 'rename_remove_keyvalue_filenames',
    base_name => 'modify_keyvalue_filename',
    remove_args => [qw/add replace/],
    modify_args => {
        filename => sub {
            $_[0]{schema} = ["array*", of=>"str*"],
            $_[0]{slurpy} = 1;
        },
    },
    modify_meta => sub {
        my $meta = shift;
        delete $meta->{examples};
    },
    summary => 'Rename file by removing keys',
    wrap_code => $wrap_code,
);

1;
# ABSTRACT: Parse filename using the KeyValue naming scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::KeyValue - Parse filename using the KeyValue naming scheme

=head1 VERSION

This document describes version 0.004 of Filename::KeyValue (from Perl distribution Filename-KeyValue), released on 2026-05-28.

=head1 SYNOPSIS

 use Filename::KeyValue qw(
     parse_keyvalue_filename
     normalize_keyvalue_filename
     modify_keyvalue_filename
     rename_add_keyvalue_filenames
     rename_remove_keyvalue_filenames
 );

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 modify_keyvalue_filename

Usage:

 modify_keyvalue_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

AddE<sol>removeE<sol>replace key-values in filename that follow KeyValue naming scheme.

Examples:

=over

=item * Add a key:

 modify_keyvalue_filename(filename => "foo-bar-kw1=val1.jpg", add => { kw2 => "val2" });

Result:

 [200, "OK", "foo-bar--kw1=val1-kw2=val2.jpg", {}]

=back

This routine will:

=over

=item * sort the key-value using keys asciibetically;

=item * (NOT YET IMPLEMENTED) optionally sort the values asciibetically;

=item * (NOT YET IMPLEMENTED) customize key sorting using SortKey.

=item * (NOT YET IMPLEMENTED) customize value sorting using SortKey.

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add> => I<hash>

List of key=E<gt>value pairs to add.

=item * B<filename>* => I<filename>

(No description)

=item * B<remove> => I<array[str]>

List of keys to remove.

=item * B<replace> => I<hash>

List of key=E<gt>value pairs to replace.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 normalize_keyvalue_filename

Usage:

 normalize_keyvalue_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Normalize filename that has the key-values following the KeyValue naming scheme.

Examples:

=over

=item * Sort keys:

 normalize_keyvalue_filename(filename => "foo-bar-kw2=val2-kw1=val1.jpg");

Result:

 [200, "OK", "foo-bar--kw1=val1-kw2=val2.jpg", {}]

=back

This routine will:

=over

=item * sort the key-value using keys asciibetically;

=item * (NOT YET IMPLEMENTED) optionally sort the values asciibetically;

=item * (NOT YET IMPLEMENTED) customize key sorting using SortKey.

=item * (NOT YET IMPLEMENTED) customize value sorting using SortKey.

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

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



=head2 parse_keyvalue_filename

Usage:

 parse_keyvalue_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse filename using the KeyValue naming scheme.

Examples:

=over

=item * No key=value pairs:

 parse_keyvalue_filename(filename => "foo.jpg");

Result:

 [
   200,
   "OK",
   { ext => "jpg", kv => {}, kv_raw => "", prefix => "foo" },
   {},
 ]

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
     prefix => "foo-bar-",
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
     prefix => "foo-bar-",
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
     prefix => "foo-bar-",
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
     prefix => "foo-bar-",
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
     prefix => "foo-bar-",
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
     prefix => "foo-bar-",
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
     prefix => "foo-bar-",
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

=item * B<filename>* => I<filename>

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



=head2 rename_add_keyvalue_filenames

Usage:

 rename_add_keyvalue_filenames(%args) -> [$status_code, $reason, $payload, \%result_meta]

Rename file by adding key=value pairs.

This routine will:

=over

=item * sort the key-value using keys asciibetically;

=item * (NOT YET IMPLEMENTED) optionally sort the values asciibetically;

=item * (NOT YET IMPLEMENTED) customize key sorting using SortKey.

=item * (NOT YET IMPLEMENTED) customize value sorting using SortKey.

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add> => I<hash>

List of key=E<gt>value pairs to add.

=item * B<filename>* => I<array[str]>

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



=head2 rename_remove_keyvalue_filenames

Usage:

 rename_remove_keyvalue_filenames(%args) -> [$status_code, $reason, $payload, \%result_meta]

Rename file by removing keys.

This routine will:

=over

=item * sort the key-value using keys asciibetically;

=item * (NOT YET IMPLEMENTED) optionally sort the values asciibetically;

=item * (NOT YET IMPLEMENTED) customize key sorting using SortKey.

=item * (NOT YET IMPLEMENTED) customize value sorting using SortKey.

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<array[str]>

(No description)

=item * B<remove> => I<array[str]>

List of keys to remove.


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

=head1 CONTRIBUTOR

=for stopwords perlancar

perlancar <perlancar@gmail.com>

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
