package Mail::DKIM2::Wrap;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.21';

use Exporter 'import';
use Crypt::PRNG qw(random_bytes);

our @EXPORT_OK = qw(wrap_single_part);

my $EOL = "\015\012";

sub _random_boundary { '=_dkim2_' . unpack('H*', random_bytes(12)) }

sub wrap_single_part {
    my ($message, %opt) = @_;
    my $gen = $opt{Boundary} // \&_random_boundary;

    # Nothing to wrap: undef, and in list context the reason.
    my $none = sub { wantarray ? (undef, $_[0]) : undef };

    my $sep = index($message, "$EOL$EOL");
    return $none->('no-header-end') if $sep < 0;
    my $head = substr($message, 0, $sep + 2);
    my $body = substr($message, $sep + 4);

    my @fields = $head =~ /\G([^\r\n]*\r\n(?:[ \t][^\r\n]*\r\n)*)/g;
    return $none->('unparsable-header') unless join('', @fields) eq $head;
    my @parsed;
    for my $f (@fields) {
        my ($name) = $f =~ /^([^:\s]+)[ \t]*:/ or return $none->('unparsable-header');
        push @parsed, [$name, $f];
    }

    my ($ct) = grep { lc $_->[0] eq 'content-type' } @parsed;
    return $none->('multipart') if $ct && $ct->[1] =~ /^[^:]+:\s*multipart\//i;

    my $boundary;
    for (1 .. 10) {
        my $c = $gen->();
        if (index($body, "--$c") < 0) { $boundary = $c; last }
    }
    return $none->('boundary') unless defined $boundary;

    my @content = grep { $_->[0] =~ /^content-/i } @parsed;
    my $new_body = "--$boundary$EOL" . join('', map { $_->[1] } @content)
                 . $EOL . $body . "$EOL--$boundary--$EOL";
    my $ct_value = qq{multipart/mixed; boundary="$boundary"};

    my (%count, @deletes, @out, $changed);
    for my $p (@parsed) {
        my $lc = lc $p->[0];
        my $i = ++$count{$lc};
        if ($lc eq 'content-type' && $i == 1) {
            push @out, "$p->[0]: $ct_value$EOL";
            $changed = 1;
        } elsif ($lc =~ /^content-/) {
            push @deletes, { op => 'delete', name => $p->[0], index => $i };
        } else {
            push @out, $p->[1];
        }
    }
    my @edits = reverse @deletes;
    push @edits, { op => 'change', name => 'Content-Type', index => 1, value => $ct_value }
        if $changed;
    my @adds;
    push @adds, ['Content-Type', $ct_value] unless $changed;
    push @adds, ['MIME-Version', '1.0'] unless $count{'mime-version'};
    for my $a (@adds) {
        push @out, "$a->[0]: $a->[1]$EOL";
        push @edits, { op => 'add', name => $a->[0], value => $a->[1] };
    }

    return {
        message  => join('', @out) . $EOL . $new_body,
        body     => $new_body,
        boundary => $boundary,
        edits    => \@edits,
    };
}

1;

__END__

=head1 NAME

Mail::DKIM2::Wrap - wrap a single-part message in a one-part multipart/mixed

=head1 SYNOPSIS

    use Mail::DKIM2::Wrap qw(wrap_single_part);
    my $w = wrap_single_part($message) or return;   # undef: already multipart
    # $w->{message}, $w->{body}, $w->{boundary}, $w->{edits}

=head1 DESCRIPTION

A list manager that adds a footer to a single-part C<text/plain> post
re-encodes the whole body, and the change can then only be described by a
null body Recipe. Wrapping the post first -- its C<Content-*> fields and its
body, byte for byte, become the only part of a C<multipart/mixed> -- makes
the footer an extra part instead. C<dkim2-milter --wrap-single-part> applies
this at ingress for stock Mailman.

=head1 FUNCTIONS

=head2 wrap_single_part($message, %options)

C<$message> is a whole message with CRLF line ends. Returns C<undef> when it
wraps nothing -- in list context C<(undef, $reason)>, the reason being
C<multipart> (already C<multipart/*>, the normal case), C<no-header-end> (no
blank line after the header), C<unparsable-header> (a header line that is not
a field), or C<boundary> (no boundary clear of the body) -- else a hash
reference: C<message> (the wrapped message), C<body> (its new body),
C<boundary>, and C<edits>, the header changes as milter operations: deletes
(C<name>, 1-based C<index> among fields of that name, last first), then the
change of the first C<Content-Type>, then additions (C<Content-Type> if there
was none, C<MIME-Version: 1.0> if absent). Option C<Boundary> is a code
reference returning a candidate boundary; the default is random. A
candidate that occurs in the body is skipped.

=cut
