package JSON::Color;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-24'; # DATE
our $DIST = 'JSON-Color'; # DIST
our $VERSION = '0.133'; # VERSION

our $sul_available = eval { require Scalar::Util::LooksLikeNumber; 1 } ? 1:0;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(encode_json);

use Color::ANSI::Util qw(ansi_reset);
use ColorThemeRole::ANSI (); # for scan_prereqs

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

    my $ct = $opts->{_color_theme_obj};
    my $c_reset = ansi_reset(1);
    my ($c_q, $c_s, $c_e);
    if ($opts->{obj_key}) {
        $c_s  = $ct->get_item_color_as_ansi('object_key');
        $c_q  = $ct->get_item_color_as_ansi('object_key_quote');
        $c_e  = $ct->get_item_color_as_ansi('object_key_escape');
    } else {
        $c_s  = $ct->get_item_color_as_ansi('string');
        $c_q  = $ct->get_item_color_as_ansi('string_quote');
        $c_e  = $ct->get_item_color_as_ansi('string_escape');
    }

    for ($c_q, $c_s, $c_e) { $_ //= "" }

    $value =~ s/([\x22\x5c\n\r\t\f\b])|([\x00-\x08\x0b\x0e-\x1f])/
        join("",
             $c_e,
             $1 ? $esc{$1} : '\\u00' . unpack('H2', $2),
             ($c_e ? $c_reset : ""), $c_s,
         )
            /eg;

    return join(
        "",
        $c_q, '"', ($c_q ? $c_reset : ""),
        $c_s, $value, ($c_s ? $c_reset : ""),
        $c_q, '"', ($c_q ? $c_reset : ""),
    );
}

sub _number {
    my ($value, $opts) = @_;

    my $ct = $opts->{_color_theme_obj};
    my $c_reset = ansi_reset(1);
    my $c_s = $ct->get_item_color_as_ansi('number') // "";
    return join(
        "",
        $c_s,
        $value,
        ($c_s ? $c_reset : ""),
    );
}

sub _null {
    my ($value, $opts) = @_;

    my $ct = $opts->{_color_theme_obj};
    my $c_reset = ansi_reset(1);
    my $c_s = $ct->get_item_color_as_ansi('null') // "";
    return join(
        "",
        $c_s,
        "null",
        ($c_s ? $c_reset : ""),
    );
}

sub _bool {
    my ($value, $opts) = @_;

    my $ct = $opts->{_color_theme_obj};
    my $c_reset = ansi_reset(1);
    my $c_s = $ct->get_item_color_as_ansi($value ? 'true' : 'false') // "";
    return join(
        "",
        $c_s,
        "$value",
        ($c_s ? $c_reset : ""),
    );
}

sub _array {
    my ($value, $opts) = @_;

    #my $ct = $opts->{_color_theme_obj};
    return "[]" unless @$value;
    my $indent  = $opts->{pretty} ? "   " x  $opts->{_indent}    : "";
    my $indent2 = $opts->{pretty} ? "   " x ($opts->{_indent}+1) : "";
    my $nl      = $opts->{pretty} ? "\n" : "";
    local $opts->{_indent} = $opts->{_indent}+1;
    return join(
        "",
        "[$nl",
        (map {(
            $indent2,
            _encode($value->[$_], $opts),
            $_ == @$value-1 ? $nl : ",$nl",)
        } 0..@$value-1),
        $indent, "]",
    );
}

sub _hash {
    my ($value, $opts) = @_;

    #my $ct = $opts->{_color_theme_obj};
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
            _string($k, {%$opts, obj_key=>1}),
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
    } elsif ($sul_available &&
             Scalar::Util::blessed($data) && $data->can('TO_JSON')) {
        return _encode($data->TO_JSON, $opts);
    } else {
        die "Can't encode $data";
    }
}

sub encode_json {
    my ($value, $opts) = @_;
    $opts //= {};
    $opts->{_indent} //= 0;
    $opts->{color_theme} //=
        (defined $ENV{NO_COLOR} ? "NoColor" : undef) //
        $ENV{JSON_COLOR_COLOR_THEME} //
        $ENV{COLOR_THEME} //
        "default_ansi";

    require Module::Load::Util;
    my $ct = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefixes=>["ColorTheme::JSON::Color", "ColorTheme", ""]},
        $opts->{color_theme},
    );
    require Role::Tiny;
    Role::Tiny->apply_roles_to_object($ct, 'ColorThemeRole::ANSI');
    $opts->{_color_theme_obj} = $ct;

    my $res = _encode($value , $opts);

    if ($opts->{linum}) {
        my $lines = 0;
        $lines++ while $res =~ /^/mog;
        my $fmt = "%".length($lines)."d";
        my $i = 0;
        $res =~ s/^/
            $ct->get_item_color('linum') . sprintf($fmt, ++$i) . ansi_reset(1)
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

This document describes version 0.133 of JSON::Color (from Perl distribution JSON-Color), released on 2021-11-24.

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

=item * color_theme => STR

Pick a color theme, which is a L<ColorTheme>-confirming color theme module. The
default is L<JSON::Color::ColorTheme::default>. For example: L<ColorTheme::Lens::Lighten>

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

=head1 ENVIRONMENT

=head2 NO_COLOR

If defined, will set default color theme to L<ColorTheme::NoColor>. See
L<https://no-color.org/> for more details.

=head2 JSON_COLOR_COLOR_THEME

Set default color theme. Has precedence over L</COLOR_THEME>.

=head2 COLOR_THEME

Set default color theme.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/JSON-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-JSON-Color>.

=head1 SEE ALSO

To colorize with HTML, you can try L<Syntax::Highlight::JSON>.

L<Syntax::SourceHighlight> can also colorize JSON/JavaScript to HTML or ANSI
escape. It requires the GNU Source-highlight library.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016, 2015, 2014, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=JSON-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
