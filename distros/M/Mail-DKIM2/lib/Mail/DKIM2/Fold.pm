package Mail::DKIM2::Fold;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.34';

use Carp ();
use Mail::DKIM2::Util ();

use Exporter 'import';
our @EXPORT_OK = qw(
    fold_header
);

# fold_header($line, [$margin], %opts): fold a header field we are creating
# -- never one read from elsewhere -- to $margin characters (default 72).
# $line is the whole field, "DKIM2-Signature: i=1; ..."; the result has
# "\r\n\t" between its lines. A tab shows as 8 columns, so continuation
# lines take $margin - 8 characters. It folds after a tag's ";" where it
# can, and otherwise only where the field's grammar allows FWS
# (_dkim2_fold_ok); a token that cannot fold stays whole on a long line.
sub fold_header {
    my ($line, $margin, %opts) = @_;
    Mail::DKIM2::Util::check_options('fold_header', \%opts, qw(delimiters_only));
    $margin //= 72;
    # delimiters_only: break only after a ";" or a "," -- never at a space,
    # never mid-token. For X-DKIM2-Info (draft-gondwana-dkim2-debug-header-01
    # Section 5): a consumer ignores whitespace next to ";" and ",", and an
    # emitter MUST NOT fold inside a token, so a hex digest or a quoted detail
    # that will not fit stays whole on an over-long line (RFC 5322's 78 is a
    # SHOULD; its 998 is the MUST, and nothing here approaches it).
    my $delimiters_only = $opts{delimiters_only};
    my $cont_margin = $margin - 8;  # content chars on continuation lines

    return $line if length($line) <= $margin;

    my @folded;
    my $remaining = $line;
    my $limit = $margin;
    my %fold_state;    # where the emitted text ends: see _dkim2_fold_feed

    while (length($remaining) > $limit) {
        # Find the best break point: prefer "; " boundaries, then
        # any space.  Look backwards from the limit.
        my $break = -1;

        # Try to break at "; " (tag boundary)
        my $search = substr($remaining, 0, $limit);
        my $pos = rindex($search, '; ');
        if ($pos > 0) {
            # Break after the semicolon, before the space
            $break = $pos + 1;
        }

        # If no tag boundary, try breaking at any space
        if ($break < 0 && !$delimiters_only) {
            $pos = rindex($search, ' ');
            $break = $pos if $pos > 0;
        }

        # If a space occurs within 2 chars before the limit, fold at
        # the space rather than leaving a 1-2 char orphan before the
        # next forced break.
        if (!$delimiters_only && ($break < 0 || $limit - $break <= 2)) {
            # Check for a space near the limit
            for my $i (reverse ($limit - 3)..($limit - 1)) {
                next if $i < 0 || $i >= length($remaining);
                if (substr($remaining, $i, 1) eq ' ') {
                    $break = $i;
                    last;
                }
            }
        }

        # A list-valued tag (the hn= header-name list in X-DKIM2-Info) has
        # no spaces at all, so break after a comma rather than in the middle
        # of a name: "lis" + "t-help" is not a header field that exists.
        if ($break < 0 && $delimiters_only) {
            $pos = rindex($search, ',');
            $break = $pos + 1 if $pos > 0;
        }

        # Delimiters only and none before the limit: take the first one
        # after it, or give up and leave the rest whole.
        if ($break < 0 && $delimiters_only) {
            my ($semi, $comma) = (index($remaining, ';', $limit), index($remaining, ',', $limit));
            my @after = sort { $a <=> $b } grep { $_ >= 0 } $semi, $comma;
            last unless @after && $after[0] < length($remaining) - 1;
            $break = $after[0] + 1;
        }

        # A DKIM2 field: the latest point before the limit where its grammar
        # allows FWS (_dkim2_fold_ok), else the first one after it. A token
        # with no such point -- a long d= Domain -- stays whole on an
        # over-long line rather than being split into a different value
        # (follow-up review F2). One pass, carrying the tag state forward a
        # character at a time: an s= of thousands of items folds in linear
        # time.
        if ($break < 0) {
            my %st = %fold_state;
            for my $i (1 .. length($remaining) - 1) {
                last if $i > $limit && $break >= 0;
                my $prev = substr($remaining, $i - 1, 1);
                _dkim2_fold_feed(\%st, $prev);
                next unless $prev eq ';' || _dkim2_fold_ok(\%st, $prev, substr($remaining, $i, 1));
                if ($i <= $limit) { $break = $i; next }
                $break = $i if $break < 0;
                last;
            }
            last if $break < 0;
        }

        my $chunk = substr($remaining, 0, $break);
        $remaining = substr($remaining, $break);

        # Strip trailing WSP from chunk, leading WSP from remainder
        $chunk =~ s/\s+$//;
        $remaining =~ s/^\s+//;

        _dkim2_fold_feed(\%fold_state, $_) for split //, $chunk;
        push @folded, $chunk;
        $limit = $cont_margin;
    }
    push @folded, $remaining if length($remaining);

    # RFC 5322 §2.1.1: 998 is a MUST. Nothing a DKIM2 signer emits has a
    # token that long, so this is a caller error, not a field to send.
    if (!$delimiters_only) {
        for (@folded) {
            Carp::croak("fold_header: a line exceeds 998 characters with no place to fold")
                if length > 998;
        }
    }

    return join("\r\n\t", @folded);
}

# fold_header's view of a DKIM2 field read so far, one character at a time:
# the current tag's name (undef until its "=", with the text before it in
# pending) and how many ":" the current list item has had.
sub _dkim2_fold_feed {
    my ($st, $c) = @_;
    if ($c eq ';') { %$st = (); return }
    if (!defined $st->{name}) {
        $st->{pending} .= $c;
        return unless $c eq '=';
        ($st->{name}) = $st->{pending} =~ /\A\s*(?:[A-Za-z0-9-]+:\s*)?([A-Za-z][A-Za-z0-9_]*)\s*=\z/;
        $st->{name} = defined $st->{name} ? lc $st->{name} : '';
        $st->{colons} = 0;
        return;
    }
    if    ($c eq ',' || $c eq '|') { $st->{colons} = 0 }
    elsif ($c eq ':') { $st->{colons}++ }
}

# May the field fold between $prev and $next, in state $st (_dkim2_fold_feed,
# fed up to and including $prev)? The grammars (-09 §9, §10) allow FWS
# inside a base64string (§2.13) and in a few list positions, and nowhere in
# a Domain, selector, algorithm or hash name, so only these are offered:
#   - between two base64 characters of mf=, rt=, r=, of an h= digest (after
#     the hash name's ":"), or of an s= signature value (after both ":"s);
#   - on either side of a ":" in s= and h=, and of a "," or "|" joining
#     their members (-09 §9.3, §10.9);
#   - after a "," in any other list but rt=: f= allows FWS around commas,
#     and an unknown tag's x-tag-value allows FWS between characters
#     (X-DKIM2-Info's hn= list folds here too). rt= is
#     base64string *("," base64string) (§10.6), and a base64string cannot
#     start with FWS, so its commas take none -- though the generic
#     tag-value grammar (§8) would allow it; rt= folds inside the base64.
sub _dkim2_fold_ok {
    my ($st, $prev, $next) = @_;
    my $name = $st->{name};
    return 0 unless defined $name && length $name;
    # sig-set and hash-set allow FWS on either side of their ":"s, and the
    # lists of them on either side of each "," and "|" (§10.9, §9.3) -- but
    # not after a header hash, before the ":" ending it: its padding is
    # the end of the base64string, and the grammar has no FWS there.
    return 0 if $prev eq '=' && $next eq ':';
    return 1 if ($name eq 's' || $name eq 'h')
             && grep { $_ eq ':' || $_ eq ',' || $_ eq '|' } $prev, $next;
    return 1 if $prev eq ',' && $name ne 'rt';
    return 0 unless $prev =~ m{[A-Za-z0-9+/=]} && $next =~ m{[A-Za-z0-9+/=]};
    return 1 if $name eq 'mf' || $name eq 'rt' || $name eq 'r';
    return $st->{colons} >= 1 if $name eq 'h';
    return $st->{colons} >= 2 if $name eq 's';
    return 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Fold - Fold a DKIM2 header field where its grammar allows

=head1 SYNOPSIS

    use Mail::DKIM2::Fold qw(fold_header);

    my $field = fold_header("DKIM2-Signature: i=1; m=1; ...");

=head1 DESCRIPTION

Only for a header this code is creating. A header read from anywhere else
is never refolded: a fold where there was no whitespace changes its
canonical form and breaks every signature over it.
L<Mail::DKIM2::MessageInstance/as_header()> and
L<Mail::DKIM2::Signature/as_folded_string()> call this for you. Nothing is
exported by default; L<Mail::DKIM2::Common> exports C<fold_header> too, as
it did before it moved here in 0.31.

See L<Mail::DKIM2/CONVENTIONS> for the conventions every module follows.

=head1 FUNCTIONS

=head2 fold_header($line, [$margin], %opts)

Folds a complete header line at C<$margin> characters (default 72) with
CRLF-tab continuations, breaking at C<; > first, then at a space, then
where a DKIM2 field's grammar allows folding whitespace: inside a base64
value (C<mf=>, C<rt=>, C<r=>, an C<h=> digest, an C<s=> signature value),
beside the C<:>s of an C<s=> or C<h=> item, or after a list comma other
than in C<s=>. It never splits a domain, selector,
algorithm or hash name: such a token that will not fit stays whole on a
longer line, and a line that would exceed RFC 5322's 998 characters croaks.
With C<< delimiters_only => 1 >> it breaks
only after C<;> or C<,>, never inside a token, leaving a value that fits
nowhere whole on an over-long line (the rule for X-DKIM2-Info).

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
