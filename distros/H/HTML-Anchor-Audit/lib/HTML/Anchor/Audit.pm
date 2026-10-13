package HTML::Anchor::Audit;

use 5.016;
use strict;
use warnings;
use Carp qw(croak);
use Encode qw(encode decode FB_CROAK FB_DEFAULT);
use Exporter qw(import);
use HTML::Parser 3.72;
use Unicode::Normalize qw(NFC);

our $VERSION = '0.001';
our @EXPORT_OK = qw(audit_html audit_utf8);

sub audit_utf8 {
    my ($bytes, @options) = @_;
    croak 'audit_utf8 expects a scalar of UTF-8 bytes' if !defined($bytes) || ref($bytes);
    croak 'audit_utf8 expects bytes, not a wide-character string' if $bytes =~ /[^\x00-\xFF]/;
    my $text = eval { decode('UTF-8', $bytes, FB_CROAK) };
    croak 'Input is not valid UTF-8' if $@;
    return audit_html($text, @options);
}

sub audit_html {
    my ($html, @options) = @_;
    croak 'audit_html expects a decoded character string' if !defined($html) || ref($html);
    croak 'Options must be key/value pairs' if @options % 2;
    my %opts = @options;
    for my $key (keys %opts) {
        croak "Unknown option: $key" if $key ne 'max_bytes' && $key ne 'max_issues';
        croak "$key must be a positive integer" if !defined($opts{$key}) || ref($opts{$key})
            || $opts{$key} !~ /\A[1-9][0-9]*\z/;
    }
    my $max_bytes = $opts{max_bytes} // (2 * 1024 * 1024);
    my $max_issues = $opts{max_issues} // 500;
    croak "Input exceeds max_bytes ($max_bytes)" if length($html) > $max_bytes;
    my $bytes = eval { encode('UTF-8', $html, FB_CROAK) };
    croak 'Input contains an invalid Unicode character' if $@;
    croak "Input exceeds max_bytes ($max_bytes)" if length($bytes) > $max_bytes;

    my @line_starts = (0);
    while ($bytes =~ /\r\n|\r|\n/g) { push @line_starts, pos($bytes) }
    my (@targets, @refs, @issues);
    my (%ids, %names, %normalized);
    my ($template_depth, $base_href, $out_of_scope, $total_issues) = (0, undef, 0, 0);
    my ($cached_line, $cached_offset, $cached_column) = (-1, 0, 1);
    my $location = sub {
        my ($offset, $tag) = @_;
        my ($lo, $hi) = (0, $#line_starts);
        while ($lo < $hi) {
            my $mid = int(($lo + $hi + 1) / 2);
            if ($line_starts[$mid] <= $offset) { $lo = $mid } else { $hi = $mid - 1 }
        }
        my $start = $cached_line == $lo && $offset >= $cached_offset
            ? $cached_offset : $line_starts[$lo];
        my $base_column = $start == $cached_offset && $cached_line == $lo ? $cached_column : 1;
        my $prefix = substr($bytes, $start, $offset - $start);
        my $column = $base_column + length(decode('UTF-8', $prefix, FB_CROAK));
        ($cached_line, $cached_offset, $cached_column) = ($lo, $offset, $column);
        return { tag => $tag, line => $lo + 1,
            column => $column,
            byte_column => $offset - $line_starts[$lo] + 1, byte_offset => $offset };
    };
    my $add_issue = sub {
        my ($issue) = @_;
        $total_issues++;
        push @issues, $issue if @issues < $max_issues;
    };
    my $parser = HTML::Parser->new(api_version => 3);
    $parser->utf8_mode(1);
    $parser->handler(start => sub {
        my ($tag, $attr, $offset) = @_;
        if ($tag eq 'template') {
            # The template element belongs to the document; its content does not.
            if ($template_depth) { $template_depth++; return }
        } elsif ($template_depth) { return }
        my $loc = $location->($offset, $tag);
        my %values;
        for my $key (qw(id name href)) {
            $values{$key} = decode('UTF-8', $attr->{$key}, FB_CROAK)
                if exists($attr->{$key}) && defined($attr->{$key});
        }
        if (defined($values{id}) && length($values{id})) {
            my $target = { kind => 'id', value => $values{id}, %$loc };
            my $existing = $ids{$values{id}} ||= [];
            if (@$existing) {
                $add_issue->({ code => 'duplicate_id', value => $values{id}, %$loc,
                    related => [ { %{ $existing->[0] } } ] });
            }
            push @$existing, $target;
            push @targets, $target;
            $normalized{NFC($values{id})}{$values{id}} = 1;
        }
        if ($tag eq 'a' && defined($values{name}) && length($values{name})) {
            my $target = { kind => 'name', value => $values{name}, %$loc };
            push @{ $names{$values{name}} ||= [] }, $target;
            push @targets, $target;
            $normalized{NFC($values{name})}{$values{name}} = 1;
        }
        if ($tag eq 'base' && !defined($base_href) && defined($values{href})) {
            my $href = $values{href};
            $href =~ s/[\t\r\n]//g;
            $href =~ s/\A[\x00-\x20]+|[\x00-\x20]+\z//g;
            $base_href = $href;
        }
        if (($tag eq 'a' || $tag eq 'area') && defined($values{href})) {
            my $href = $values{href};
            $href =~ s/[\t\r\n]//g;
            $href =~ s/\A[\x00-\x20]+|[\x00-\x20]+\z//g;
            if (substr($href, 0, 1) eq '#') {
                push @refs, { href => $values{href}, fragment => substr($href, 1), %$loc };
            } else { $out_of_scope++ }
        }
        $template_depth = 1 if $tag eq 'template';
    }, 'tagname,attr,offset');
    $parser->handler(end => sub {
        my ($tag) = @_;
        $template_depth-- if $tag eq 'template' && $template_depth;
    }, 'tagname');
    $parser->parse($bytes);
    $parser->eof;

    my ($checked, $ignored) = (0, 0);
    for my $ref (@refs) {
        if (defined($base_href) && length($base_href)) {
            $ref->{status} = 'ignored'; $ref->{reason} = 'base_href'; $ignored++; next;
        }
        if (index($ref->{fragment}, ':~:') >= 0) {
            $ref->{status} = 'ignored'; $ref->{reason} = 'fragment_directive'; $ignored++; next;
        }
        $checked++;
        if ($ref->{fragment} eq '') { $ref->{status} = 'top'; next }
        my $escaped = encode('UTF-8', $ref->{fragment});
        $escaped =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
        my $decoded = decode('UTF-8', $escaped, FB_DEFAULT);
        $ref->{decoded_fragment} = $decoded;
        my ($matches, $matched_value, $matched_kind);
        for my $value ($ref->{fragment}, $decoded) {
            if ($ids{$value}) { ($matches, $matched_value, $matched_kind) = ($ids{$value}, $value, 'id'); last }
            if ($names{$value}) { ($matches, $matched_value, $matched_kind) = ($names{$value}, $value, 'name'); last }
        }
        if ($matches) {
            my @related = map { { %$_ } } @$matches[0 .. ($#$matches < 9 ? $#$matches : 9)];
            $ref->{status} = @$matches > 1 ? 'ambiguous' : 'matched';
            $ref->{target_value} = $matched_value;
            $ref->{target_kind} = $matched_kind;
            $ref->{target_count} = scalar(@$matches);
            $ref->{targets} = \@related;
            if (@$matches > 1) {
                $add_issue->({ code => 'ambiguous_target', href => $ref->{href}, value => $matched_value,
                    (map { $_ => $ref->{$_} } qw(tag line column byte_column byte_offset)),
                    related_count => scalar(@$matches), related => \@related });
            }
        } elsif ($decoded =~ /\A[Tt][Oo][Pp]\z/) {
            $ref->{status} = 'top';
        } else {
            $ref->{status} = 'missing';
            my @suggestions = sort keys %{ $normalized{NFC($decoded)} || {} };
            my $issue = { code => 'missing_target', href => $ref->{href}, value => $decoded,
                map { $_ => $ref->{$_} } qw(tag line column byte_column byte_offset) };
            $issue->{normalization_candidates} = \@suggestions if @suggestions;
            $add_issue->($issue);
        }
    }
    @issues = sort { $a->{byte_offset} <=> $b->{byte_offset} || $a->{code} cmp $b->{code} } @issues;
    return {
        schema_version => 1, targets => \@targets, references => \@refs, issues => \@issues,
        statistics => { target_count => scalar(@targets), reference_count => scalar(@refs),
            checked_reference_count => $checked, ignored_reference_count => $ignored,
            out_of_scope_href_count => $out_of_scope, issue_count => $total_issues,
            reported_issue_count => scalar(@issues), truncated => $total_issues > @issues ? 1 : 0 },
    };
}

1;

__END__

=encoding UTF-8

=head1 NAME

HTML::Anchor::Audit - offline, source-located diagnostics for HTML fragment links

=head1 SYNOPSIS

    use utf8;
    use HTML::Anchor::Audit qw(audit_html audit_utf8);

    my $report = audit_html(q{
        <a href="#installation">Install</a>
        <h2 id="installation">Installation</h2>
        <a href="#missing">Missing section</a>
    });
    for my $issue (@{ $report->{issues} }) {
        printf "%s at line %d, column %d\n",
            $issue->{code}, $issue->{line}, $issue->{column};
    }

    # Read a local UTF-8 article without modifying it.
    open my $fh, '<:raw', 'article.html' or die $!;
    my $bytes = do { local $/; <$fh> };
    my $utf8_report = audit_utf8($bytes);

=head1 DESCRIPTION

This small library checks fragment-only links in already available HTML.
It returns Perl data structures for editor integrations, pre-publication checks
and static-content pipelines. It does not fetch URLs, open files, modify content
or send telemetry. The bundled C<html-anchor-audit> command reads local files.

The use case is a saved article or HTML fragment, including Gutenberg exports,
where section buttons may outlive their targets. The result includes missing
targets, repeated IDs and references to multiple matching targets, with source
locations usable by an editor. It is independent of WordPress and does not need
access to a WordPress installation.

=head1 FUNCTIONS

Nothing is exported by default. Import either function explicitly.

=head2 audit_html($characters, %options)

Accepts a decoded Perl character string. Decode non-ASCII input before calling;
the function cannot infer whether an unflagged scalar represents bytes or text.
It returns a fresh hash reference and leaves the supplied string unchanged.

=head2 audit_utf8($bytes, %options)

Accepts UTF-8 octets and rejects invalid UTF-8. A leading UTF-8 BOM is retained
for source-location accounting. Files in other encodings must be decoded by the
caller, then supplied to C<audit_html>.

=head2 Options

C<max_bytes> defaults to 2097152, measured after encoding characters to UTF-8.
Larger input throws an exception. C<max_issues> defaults to 500; a larger
diagnostic count sets C<statistics.truncated> and retains the first diagnostics
discovered, which are then sorted by location. Both options require positive
integers. Targets and references are still collected completely within the
input size limit. Unknown options and invalid arguments throw exceptions.

=head1 REPORT FORMAT

The C<schema_version> is C<1>. C<targets>, C<references> and C<issues> are arrays
of hash references. Locations identify the start of the opening tag, rather
than the attribute. C<line> and C<column> are one-based; the column counts
Unicode characters, not screen cells. C<byte_column> is one-based and
C<byte_offset> is zero-based in the UTF-8 source. CR, LF and CRLF are supported.

Targets contain C<kind> (C<id> or legacy C<name>), C<value> and a location.
References contain C<href>, C<fragment>, a location and C<status>: C<matched>,
C<ambiguous>, C<missing>, C<top> or C<ignored>. Resolved references include
C<target_kind>, C<target_value>, C<target_count> and C<targets>. To bound reports
for pathological duplicate IDs, per-reference C<targets> and ambiguity
C<related> list at most the first ten locations; C<target_count> and
C<related_count> retain the full counts. The top-level C<targets> remains
complete. Ignored references have C<reason>
C<base_href> or C<fragment_directive>.

Issue C<code> is C<missing_target>, C<duplicate_id> or C<ambiguous_target>.
The C<value> names the relevant target. C<related> lists target locations for
duplicates and ambiguities. A missing target can include
C<normalization_candidates>: existing values equivalent under Unicode NFC.
These are hints only; Unicode normalization never turns a missing target into
a match. A repeated legacy name is reported when a link resolves ambiguously,
not as a duplicate ID. Multiple targets warn even though a browser may choose
the first one.

C<statistics> contains target/reference counts, checked/ignored reference
counts, C<out_of_scope_href_count>, full C<issue_count>,
C<reported_issue_count> and integer C<truncated> (0 or 1).

=head1 MATCHING RULES AND LIMITS

L<HTML::Parser> tokenizes the source and decodes attribute entities. IDs are
case-sensitive. Only C<a> and C<area> fragment-only C<href> values are checked.
Tabs and line breaks are removed from URLs and surrounding ASCII controls and
spaces are trimmed. An empty fragment points to the top. Exact fragment
matching is tried before a single percent-decoding pass followed by UTF-8
decoding, with replacement for invalid encoded sequences. IDs take priority
over legacy C<a name> targets in each pass. Literal C<+> stays C<+>. An otherwise
unmatched ASCII case-insensitive C<top> fragment points to the top.

Template content is ignored; the template element's own ID remains visible.
Comment and raw-text contents are handled by HTML::Parser. Fragment directives
such as C<#:~:text=...> are ignored. If the first C<base href> is nonempty, all
fragment references are ignored because they may target another document.

The checker does not reconstruct an HTML5 DOM. Malformed nesting, duplicate
attributes, embedded SVG/XML, scripting-dependent C<noscript> content and HTML5
entity edge cases may differ from a browser. Use well-formed static HTML.
IDs produced by JavaScript, theme wrappers or a later renderer are not known.
Other documents, external URLs, CSS selectors and Gutenberg block balancing
are out of scope. This is not a complete HTML validator or a web crawler.

=head1 COMMAND LINE

    html-anchor-audit article.html
    html-anchor-audit --json article.html second-article.html
    html-anchor-audit --max-bytes 4194304 article.html

Input is strictly UTF-8. Exit status is 0 for a complete clean check, 1 if
diagnostics were found, and 2 for a usage, file or input error. JSON output is a
single UTF-8 object with C<version> and C<files>; each file entry has C<file>
and either C<report> or C<error>. Output does not include the full article.
The command has no URL or network mode and never writes the input files.

=head1 SIMILAR TOOLS

L<HTML::SimpleLinkExtor> extracts links. L<HTML::Lint> checks broader HTML
errors. L<WWW::LinkRot> checks remote link status. The
L<W3C Link Checker|https://metacpan.org/dist/W3C-LinkChecker/view/bin/checklink.pod>
already checks duplicate anchors and fragments, with crawling and network
features. Prefer it for site-wide validation. This module offers a narrow,
offline, embeddable API with structured source locations and Unicode hints;
it does not claim to invent fragment checking.

Matching is informed by the
L<HTML Standard fragment-selection algorithm|https://html.spec.whatwg.org/multipage/browsing-the-web.html#scroll-to-fragid>,
within the static-source limits above.

=head1 SUPPORT

Report reproducible issues at
L<the project issue tracker|https://github.com/nedal-dev/html-anchor-audit/issues>.

=head1 AUTHOR

Nedal Shabaan. Developed for article-editing workflows at
L<Idraaak|https://idraaak.com/>.

=head1 LICENSE

Copyright (c) 2026 Nedal Shabaan. Released under the MIT license; see LICENSE.

=cut
