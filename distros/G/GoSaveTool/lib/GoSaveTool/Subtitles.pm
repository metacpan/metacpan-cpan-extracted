package GoSaveTool::Subtitles;

use 5.010;
use strict;
use warnings;
use feature qw(unicode_strings);
use Carp qw(croak);
use Exporter 'import';

our $VERSION = '1.000';
our @EXPORT_OK = qw(to_ms from_ms parse is_vtt to_srt to_vtt convert shift_cues repair);

my $STAMP = qr/(?:\d{1,2}:)?\d{1,2}:\d{1,2}[,.]\d{1,3}/;

sub to_ms {
    my ($stamp) = @_;
    return undef unless $stamp =~ /(\d{1,2}:)?(\d{1,2}):(\d{1,2})[,.](\d{1,3})/;
    my $h = defined $1 ? substr($1, 0, -1) : 0;
    my $frac = substr($4 . '00', 0, 3);
    return (($h * 60 + $2) * 60 + $3) * 1000 + $frac;
}

sub from_ms {
    my ($ms, $sep) = @_;
    $sep //= ',';
    # Half up, as JavaScript's Math.round
    $ms = int($ms + 0.5);
    $ms = 0 if $ms < 0;
    return sprintf '%02d:%02d:%02d%s%03d', int($ms / 3600000), int($ms / 60000) % 60, int($ms / 1000) % 60, $sep, $ms % 1000;
}

sub parse {
    my ($src) = @_;
    (my $text = $src) =~ s/\A\x{FEFF}//;
    # "\r\r\n" too: a file saved twice with Windows line endings
    $text =~ s/\r*\n|\r/\n/g;
    my @cues;
    for my $block (split /\n{2,}/, $text) {
        my @lines = split /\n/, $block, -1;
        for my $i (0 .. $#lines) {
            next unless $lines[$i] =~ /^\s*($STAMP)\s*-->\s*($STAMP)(.*)$/;
            my ($from, $to, $settings) = ($1, $2, $3);
            my $body = join "\n", @lines[$i + 1 .. $#lines];
            s/\A\s+|\s+\z//g for $body, $settings;
            push @cues, { start => to_ms($from), end => to_ms($to), settings => $settings, text => $body };
            last;
        }
    }
    return \@cues;
}

sub is_vtt {
    my ($src) = @_;
    return $src =~ /\A\x{FEFF}?WEBVTT/ ? 1 : 0;
}

sub to_srt {
    my ($cues) = @_;
    my $i = 0;
    return join("\n\n", map { ++$i . "\n" . from_ms($_->{start}, ',') . ' --> ' . from_ms($_->{end}, ',') . "\n" . $_->{text} } @$cues) . "\n";
}

sub to_vtt {
    my ($cues) = @_;
    return "WEBVTT\n\n" . join("\n\n", map {
        from_ms($_->{start}, '.') . ' --> ' . from_ms($_->{end}, '.') . (length($_->{settings} // '') ? " $_->{settings}" : '') . "\n" . $_->{text}
    } @$cues) . "\n";
}

sub convert {
    my ($src, $to) = @_;
    return to_vtt(parse($src)) if $to eq 'vtt';
    return to_srt(parse($src)) if $to eq 'srt';
    croak 'the target format must be "srt" or "vtt"';
}

sub shift_cues {
    my ($cues, $ms) = @_;
    my @out;
    for my $c (@$cues) {
        my $end = $c->{end} + $ms;
        $end = 0 if $end < 0;
        next unless $end > 0;
        my $start = $c->{start} + $ms;
        push @out, { %$c, start => ($start < 0 ? 0 : $start), end => $end };
    }
    return \@out;
}

sub repair {
    my ($cues, $min_duration) = @_;
    $min_duration //= 2000;
    my $fixed = grep { $_->{text} eq '' } @$cues;
    my @kept = map { +{%$_} } grep { $_->{text} ne '' } @$cues;
    # Perl's sort is stable (mergesort), so cues with the same start keep their order
    use sort 'stable';
    my @out = sort { $a->{start} <=> $b->{start} } @kept;
    for my $i (0 .. $#out) {
        if ($out[$i]{start} != $kept[$i]{start}) { $fixed++; last }
    }
    for my $i (0 .. $#out) {
        my ($c, $next) = ($out[$i], $out[$i + 1]);
        if (!($c->{end} > $c->{start})) { $c->{end} = $c->{start} + $min_duration; $fixed++ }
        if ($next && $c->{end} > $next->{start}) {
            my $e = $next->{start} - 1;
            $c->{end} = $e > $c->{start} + 1 ? $e : $c->{start} + 1;
            $fixed++;
        }
    }
    return (\@out, $fixed);
}

1;

__END__

=encoding utf8

=head1 NAME

GoSaveTool::Subtitles - Parse, convert, shift and repair SRT and WebVTT subtitles

=head1 SYNOPSIS

    use GoSaveTool::Subtitles qw(parse convert shift_cues repair to_srt to_vtt);

    my $vtt = convert($srt_text, 'vtt');

    my $cues = parse($text);            # [ { start => 1000, end => 3500, settings => '', text => 'Hello' }, ... ]
    my $later = to_srt(shift_cues($cues, 1500));
    my ($fixed_cues, $n) = repair($cues);
    print "$n problems fixed\n";

=head1 DESCRIPTION

The Perl version of the C<@gosavetool/subtitles> JavaScript package, from
L<GoSaveTool|https://www.gosavetool.com/>. Online editor:
L<https://www.gosavetool.com/vtt-subtitle-generator>. No dependencies outside
the core.

=head1 FUNCTIONS

Nothing is exported by default. Times are in milliseconds.

=over 4

=item parse($text)

Array reference of cues (hash references with C<start>, C<end>, C<settings>
and C<text>) of an SRT or WebVTT text. Headers, NOTE and STYLE blocks are
skipped.

=item to_srt($cues), to_vtt($cues), convert($text, 'srt' | 'vtt')

Write cues. WebVTT cue settings are kept.

=item shift_cues($cues, $ms)

New cues moved by C<$ms> (negative = earlier). Cues pushed before zero are
clipped or dropped.

=item repair($cues, $min_duration)

Returns the repaired cues and the number of changes: cues sorted, end times
before the start set to C<$min_duration> (2000) after it, overlapping cues
ended before the next one, empty cues dropped. The input is not changed.

=item to_ms($stamp), from_ms($ms, $separator), is_vtt($text)

C<"00:01:02,500"> to 62500 (undef when it is not a timestamp), back, and
whether the text starts with C<WEBVTT>.

=back

=head1 SEE ALSO

L<GoSaveTool::Text>

=head1 AUTHOR

GoSaveTool L<https://www.gosavetool.com/>

=head1 LICENSE

MIT License. See the LICENSE file.

=cut
