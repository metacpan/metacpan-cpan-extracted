package Developer::Dashboard::HtmlEscape;

use strict;
use warnings;

our $VERSION = '4.45';

use Exporter 'import';

our @EXPORT_OK = qw(_escape_html _escape_html_attr);

# _escape_html($text)
# Escapes text for safe output inside HTML body content.
# Input: raw text, possibly undefined.
# Output: escaped text string.
sub _escape_html {
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
# own escaper.
# Input: raw value, possibly undefined.
# Output: escaped value safe between either kind of attribute quote.
sub _escape_html_attr {
    my ($value) = @_;
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

Provides C<_escape_html> and C<_escape_html_attr>, the single home for a
pair of HTML-escaping helpers that used to be written out identically in
C<Developer::Dashboard::Web::App> and C<Developer::Dashboard::Zipper>
(DD-898) - the same "small helper reimplemented per file instead of
shared" pattern this project already fixed several times (DD-762, DD-785,
DD-888, DD-891, DD-894). Notably, this specific duplication was created
deliberately: DD-892 mirrored C<Web::App>'s existing pair into C<Zipper>
as its own private copy rather than extracting a shared module at the
time - a duplication being intentional when created does not mean it
should stay duplicated.

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

C<_escape_html_attr> calls C<_escape_html> internally, then additionally
escapes both quote characters - use it for anything placed inside a
quoted HTML attribute, and C<_escape_html> alone for plain body content.

=head1 WHAT USES IT

C<Developer::Dashboard::Web::App> and C<Developer::Dashboard::Zipper>, at
the call sites the DD-898 extraction migrated.

=head1 EXAMPLES

  _escape_html('<x>')            # '&lt;x&gt;'
  _escape_html_attr('"quoted"')  # '&quot;quoted&quot;'

=cut
