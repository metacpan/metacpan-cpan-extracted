package Developer::Dashboard::HtmlEscape;

use strict;
use warnings;

our $VERSION = '6.06';

our $XS_LOADED = 0;

{
    my $loaded = eval {
        require XSLoader;
        XSLoader::load( 'Developer::Dashboard', $VERSION );
        1;
    };
    if ($loaded) {
        $XS_LOADED = 1;
    }
    elsif ( $@ !~ /Can't locate loadable object for module Developer::Dashboard\b/ ) {
        die $@ || 'Unable to load the Developer::Dashboard XS extension';
    }
}

use Exporter 'import';

our @EXPORT_OK = qw(_escape_html _escape_html_attr);

# _escape_html($text)
# Escapes HTML-sensitive text with the native scalar backend when available,
# otherwise using the Perl fallback and preserving overloaded stringification.
# Input: raw text, possibly undefined.
# Output: escaped text string.
sub _escape_html {
    my ($text) = @_;
    if ( $XS_LOADED && !ref($text) ) {
        return _xs_escape_html($text) if !defined $text;
        my $first = index( $text, '&' );
        my $lt    = index( $text, '<' );
        my $gt    = index( $text, '>' );
        $first = $lt if $lt >= 0 && ( $first < 0 || $lt < $first );
        $first = $gt if $gt >= 0 && ( $first < 0 || $gt < $first );
        return $text if $first < 0;
        if ( $first <= 64 ) {
            return _xs_escape_html($text) if length($text) <= 64;
            my $prefix = substr( $text, 0, 16 );
            my $early_escape_count = $prefix =~ tr/&<>/&<>/;
            return _xs_escape_html($text) if $early_escape_count >= 4;
        }
        return _xs_escape_html_chunked($text);
    }
    $text = '' if !defined $text;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    return $text;
}

# _escape_html_perl($text)
# Escapes an HTML body string using Perl substitutions, including overloaded
# references for which the native scalar-only implementation is not suitable.
# Input: raw text value, possibly undefined or an overloaded reference.
# Output: text with ampersands and angle brackets escaped.
sub _escape_html_perl {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    return $text;
}

# _escape_html_attr($value)
# Escapes one value for safe output inside a quoted HTML attribute.
# Quotes are what _escape_html deliberately leaves alone, and a quote is
# exactly what closes an attribute early, so attribute context needs its
# own escaper. Plain scalar values of at least twelve characters take a
# read-only metacharacter scan and return unchanged instead of running five
# substitution passes; shorter values retain the low-overhead substitution path.
# Input: raw value, possibly undefined.
# Output: escaped value safe between either kind of attribute quote.
sub _escape_html_attr {
    my ($value) = @_;
    return _xs_escape_html_attr($value) if $XS_LOADED && !ref($value);
    return $value
      if defined $value
      && !ref($value)
      && length($value) >= 12
      && index( $value, '&' ) < 0
      && index( $value, '<' ) < 0
      && index( $value, '>' ) < 0
      && index( $value, '"' ) < 0
      && index( $value, "'" ) < 0;
    $value = _escape_html($value);
    $value =~ s/"/&quot;/g;
    $value =~ s/'/&#39;/g;
    return $value;
}

1;

__END__

=head1 NAME

Developer::Dashboard::HtmlEscape - shared HTML-escaping helpers

=head1 SYNOPSIS

  use Developer::Dashboard::HtmlEscape qw(_escape_html _escape_html_attr);
  my $body = _escape_html($raw_text);                # for HTML body content
  my $attr = _escape_html_attr($raw_value);           # for a quoted attribute

=head1 DESCRIPTION

Provides C<_escape_html> and C<_escape_html_attr>, the single home for two
HTML-escaping helpers that used to be written out identically in
C<Developer::Dashboard::Web::App> and C<Developer::Dashboard::Zipper>
(DD-898) - the same "small helper reimplemented per file instead of
shared" pattern this project already fixed several times (DD-762, DD-785,
DD-888, DD-891, DD-894). Notably, this specific duplication was created
deliberately: DD-892 mirrored C<Web::App>'s existing pair into C<Zipper>
as its own private copy rather than extracting a shared module at the
time - a duplication being intentional when created does not mean it
should stay duplicated.

When the distribution's XS extension is built, body strings with no escapable
bytes are returned unchanged. Inputs of at most 64 characters with an escape,
or longer inputs with at least four escapable bytes in the first 16 characters,
use the direct compiled C loop. Longer strings with fewer early escapes use a
native chunk-copy pass; this avoids sending long, early-but-rare input through
the direct loop. A source checkout without the compiled extension applies the
equivalent Perl substitutions directly in C<_escape_html>, avoiding a second
helper dispatch on that path. Overloaded references use Perl stringification
so native scalar conversion does not change their behavior. A missing extension
is the only load condition that selects the documented Perl path; other XS
load errors remain visible. Attribute values use a separate single-pass XS
loop that handles body metacharacters and both quote characters together. All
XS paths retain the Perl UTF-8 flag and taint state.

=head1 PURPOSE

Give every module that needs to escape text for HTML output one canonical
pair of implementations to call, rather than each maintaining its own
private copy that can silently drift.

=head1 WHY IT EXISTS

C<Web::App>'s and C<Zipper>'s escaping pairs were byte-for-byte identical,
with no reason for the two copies to ever diverge and no mechanism to
notice if one changed and the other did not. Extracting the shared
behavior removes that latent-drift risk before an edit to one copy
silently stops matching the other - the same reasoning that produced
C<TextUtils.pm> (DD-891) and C<TimeUtils.pm> (DD-894).

=head1 WHEN TO USE

Any module in this codebase that needs to escape text for HTML body
content or a quoted HTML attribute should C<use> this module rather than
writing private C<_escape_html>/C<_escape_html_attr> subs.

=head1 HOW TO USE

  use Developer::Dashboard::HtmlEscape qw(_escape_html _escape_html_attr);
  my $safe_body = _escape_html($raw_text);
  my $safe_attr = _escape_html_attr($raw_value);

C<_escape_html_attr> uses the single-pass native implementation for scalar
inputs when XS is loaded, and the Perl implementation for overloaded references
or source-only operation. In the Perl path, plain scalar attribute strings of
at least twelve characters return after a metacharacter scan when no escaping
is needed; shorter values keep the substitution path. Use it for anything
placed inside a quoted HTML attribute, and C<_escape_html> alone for plain body
content.

=head1 WHAT USES IT

C<Developer::Dashboard::Web::App> and C<Developer::Dashboard::Zipper>, at
the call sites the DD-898 extraction migrated.

=head1 EXAMPLES

  _escape_html('<x>')            # '&lt;x&gt;'
  _escape_html_attr('"quoted"')  # '&quot;quoted&quot;'

=cut
