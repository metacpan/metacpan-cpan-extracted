package JSON::Color;

use 5.010001;
use strict;
use warnings;

our $sul_available = eval { require Scalar::Util::LooksLikeNumber; 1 } ? 1:0;
use Term::ANSIColor qw(:constants);

# PUSHCOLOR and LOCALCOLOR cannot be used, they are functions, not escape codes

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(encode_json);

our $VERSION = '0.12'; # VERSION

our %theme = (
    start_quote         => BOLD . BRIGHT_GREEN,
    end_quote           => RESET,
    start_string        => GREEN,
    end_string          => RESET,
    start_string_escape => BOLD,
    end_string_escape   => RESET . GREEN, # back to string
    start_number        => BOLD . BRIGHT_MAGENTA,
    end_number          => RESET,
    start_bool          => CYAN,
    end_bool            => RESET,
    start_null          => CYAN,
    end_null            => RESET,
    start_object_key    => MAGENTA,
    end_object_key      => RESET,
    start_object_key_escape => BOLD,
    end_object_key_escape   => RESET . MAGENTA, # back to object key
    start_linum         => REVERSE . WHITE,
    end_linum           => RESET,
);

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
sub _string {
    my ($value, $opts) = @_;

    my ($sq, $eq, $ss, $es, $sse, $ese);
    if ($opts->{obj_key}) {
        $sq  = $theme{start_object_key};
        $eq  = $theme{end_object_key};
        $ss  = $theme{start_object_key};
        $es  = $theme{end_object_key};
        $sse = $theme{start_object_key_escape};
        $ese = $theme{end_object_key_escape};
    } else {
        $sq  = $theme{start_quote};
        $eq  = $theme{end_quote};
        $ss  = $theme{start_string};
        $es  = $theme{end_string};
        $sse = $theme{start_string_escape};
        $ese = $theme{end_string_escape};
    }

    $value =~ s/([\x22\x5c\n\r\t\f\b])|([\x00-\x08\x0b\x0e-\x1f])/
        join("",
             $sse,
             $1 ? $esc{$1} : '\\u00' . unpack('H2', $2),
             $ese,
         )
            /eg;

    return join(
        "",
        $sq, '"', $eq,
        $ss, $value, $es,
        $sq, '"', $eq,
    );
}

sub _number {
    my ($value, $opts) = @_;

    return join(
        "",
        $theme{start_number}, $value, $theme{end_number},
    );
}

sub _null {
    my ($value, $opts) = @_;

    return join(
        "",
        $theme{start_null}, "null", $theme{end_null},
    );
}

sub _bool {
    my ($value, $opts) = @_;

    return join(
        "",
        $theme{start_bool}, "$value", $theme{end_bool},
    );
}

sub _array {
    my ($value, $opts) = @_;

    return "[]" unless @$value;
    my $indent  = $opts->{pretty} ? "   " x  $opts->{_indent}    : "";
    my $indent2 = $opts->{pretty} ? "   " x ($opts->{_indent}+1) : "";
    my $nl      = $opts->{pretty} ? "\n" : "";
    local $opts->{_indent} = $opts->{_indent}+1;
    return join(
        "",
        "[$nl",
        (map {
            $indent2,
            _encode($value->[$_], $opts),
            $_ == @$value-1 ? $nl : ",$nl",
        } 0..@$value-1),
        $indent, "]",
    );
}

sub _hash {
    my ($value, $opts) = @_;

    return "{}" unless keys %$value;
    my $indent  = $opts->{pretty} ? "   " x  $opts->{_indent}    : "";
    my $indent2 = $opts->{pretty} ? "   " x ($opts->{_indent}+1) : "";
    my $nl      = $opts->{pretty} ? "\n" : "";
    my $colon   = $opts->{pretty} ? ": " : ":";
    my @res;

    push @res, "{$nl";
    my @k;
    if ($opts->{sort_by}) {
        @k = sort { $opts->{sort_by}->() } keys %$value;
    } else {
        @k = sort keys(%$value);
    }
    local $opts->{_indent} = $opts->{_indent}+1;
    for (0..@k-1) {
        my $k = $k[$_];
        push @res, (
            $indent2,
            _string($k, {obj_key=>1}),
            $colon,
            _encode($value->{$k}, $opts),
            $_ == @k-1 ? $nl : ",$nl",
        );
    }
    push @res, $indent, "}";
    join "", @res;
}

sub _encode {
    my ($data, $opts) = @_;

    my $ref = ref($data);

    if (!defined($data)) {
        return _null($data, $opts);
    } elsif ($ref eq 'ARRAY') {
        return _array($data, $opts);
    } elsif ($ref eq 'HASH') {
        return _hash($data, $opts);
    } elsif ($ref eq 'JSON::XS::Boolean' || $ref eq 'JSON::PP::Boolean') {
        return _bool($data, $opts);
    } elsif (!$ref) {
        if ($sul_available &&
                Scalar::Util::LooksLikeNumber::looks_like_number($data) =~
                  /^(4|12|4352|8704)$/o) {
            return _number($data, $opts);
        } else {
            return _string($data, $opts);
        }
    } else {
        die "Can't encode $data";
    }
}

sub encode_json {
    my ($value, $opts) = @_;
    $opts //= {};
    $opts->{_indent} //= 0;
    my $res = _encode($value , $opts);

    if ($opts->{linum}) {
        my $lines = 0;
        $lines++ while $res =~ /^/mog;
        my $fmt = "%".length($lines)."d";
        my $i = 0;
        $res =~ s/^/
            $theme{start_linum} . sprintf($fmt, ++$i) . $theme{end_linum}
                /meg;
    }
    $res;
}

1;
# ABSTRACT: Encode to colored JSON

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Color - Encode to colored JSON

=head1 VERSION

This document describes version 0.12 of JSON::Color (from Perl distribution JSON-Color), released on 2016-08-23.

=head1 SYNOPSIS

 use JSON::Color qw(encode_json);
 say encode_json([1, "two", {three => 4}]);

=head1 DESCRIPTION

This module generates JSON, colorized with ANSI escape sequences.

To change the color, see the C<%theme> in the source code. In theory you can
also modify it to colorize using HTML.

=head1 FUNCTIONS

=head2 encode_json($data, \%opts) => STR

Encode to JSON. Will die on error (e.g. when encountering non-encodeable data
like Regexp or file handle).

Known options:

=over

=item * pretty => BOOL (default: 0)

Pretty-print.

=item * linum => BOOL (default: 0)

Show line number.

=item * sort_by => CODE

If specified, then sorting of hash keys will be done using this sort subroutine.
This is similar to the C<sort_by> option in the L<JSON> module. Note that code
is executed in C<JSON::Color> namespace, example:

 # reverse sort
 encode_json(..., {sort_by => sub { $JSON::Color::b cmp $JSON::Color::a }});

Another example, using L<Sort::ByExample>:

 use Sort::ByExample cmp => {-as => 'by_eg', example => [qw/foo bar baz/]};
 encode_json(..., {sort_by => sub { by_eg($JSON::Color::a, $JSON::Color::b) }});

=back

=head1 FAQ

=head2 What about loading?

Use L<JSON>.

=head2 How to handle non-encodeable data?

Use L<Data::Clean::JSON>.

=head2 Why do numbers become strings?

Example:

 % perl -MJSON::Color=encode_json -E'say encode_json([1, "1"])'
 ["1","1"]

To detect whether a scalar is a number (e.g. differentiate between "1" and 1),
the XS module L<Scalar::Util::LooksLikeNumber> is used. This is set as an
optional prerequisite, so you'll need to install it separately. After the
prerequisite is installed:

 % perl -MJSON::Color=encode_json -E'say encode_json([1, "1"])'
 [1,"1"]

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/JSON-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-JSON-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=JSON-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

To colorize with HTML, you can try L<Syntax::Highlight::JSON>.

L<Syntax::SourceHighlight> can also colorize JSON/JavaScript to HTML or ANSI
escape. It requires the GNU Source-highlight library.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
