package GoSaveTool::Text;

use 5.010;
use strict;
use warnings;
use feature qw(unicode_strings);
use utf8;
use Exporter 'import';
use Unicode::Normalize qw(NFKD);

our $VERSION = '1.000';
our @EXPORT_OK = qw(stats limits words upper lower title sentence slug camel snake kebab clean %LIMITS @LIMIT_ORDER);

# Character limits of common fields; SEO values are the length search results show before cutting
our @LIMIT_ORDER = qw(x-post instagram-caption tiktok-caption youtube-title youtube-description linkedin-post pinterest-description seo-title meta-description);
our %LIMITS = (
    'x-post'                => 280,
    'instagram-caption'     => 2200,
    'tiktok-caption'        => 4000,
    'youtube-title'         => 100,
    'youtube-description'   => 5000,
    'linkedin-post'         => 3000,
    'pinterest-description' => 500,
    'seo-title'             => 60,
    'meta-description'      => 160,
);

my %SMALL = map { $_ => 1 } qw(a an and as at but by for in nor of on or so the to up yet via vs);

sub stats {
    my ($s) = @_;
    my $words = () = $s =~ /[\p{L}\p{N}][\p{L}\p{N}'\x{2019}_-]*/g;
    (my $no_spaces = $s) =~ s/\s//g;
    my $sentences = () = $s =~ /[^.!?\x{2026}]+[.!?\x{2026}]+/g;
    return {
        words         => $words,
        chars         => length $s,
        charsNoSpaces => length $no_spaces,
        lines         => $s eq '' ? 0 : scalar(() = split /\r\n|\r|\n/, $s, -1),
        sentences     => $sentences,
        # 238 words a minute: the average silent reading speed for English non-fiction
        readSeconds   => int($words / 238 * 60 + 0.5),
    };
}

sub limits {
    my ($s, @only) = @_;
    my $used = length $s;
    my %want = map { $_ => 1 } @only;
    my %out;
    for my $k (@LIMIT_ORDER) {
        next if @only && !$want{$k};
        $out{$k} = { limit => $LIMITS{$k}, used => $used, left => $LIMITS{$k} - $used, fits => ($used <= $LIMITS{$k} ? 1 : 0) };
    }
    return \%out;
}

sub words {
    my ($s) = @_;
    $s =~ s/([\p{Ll}\p{N}])(\p{Lu})/$1 $2/g;
    return grep { length } split /[^\p{L}\p{N}]+/, $s;
}

sub upper { return uc $_[0] }
sub lower { return lc $_[0] }

sub _capitalize {
    my ($w) = @_;
    return uc(substr $w, 0, 1) . substr($w, 1);
}

sub title {
    my ($s) = @_;
    my $low = lc $s;
    my ($out, $last, $first) = ('', 0, 1);
    while ($low =~ /([\p{L}\p{N}][\p{L}\p{N}'\x{2019}]*)/g) {
        my ($w, $start, $end) = ($1, $-[0], $+[0]);
        my $after_colon = substr($low, 0, $start) =~ /[:.!?]\s*\z/;
        $out .= substr($low, $last, $start - $last) . ($first || $after_colon || !$SMALL{$w} ? _capitalize($w) : $w);
        ($last, $first) = ($end, 0);
    }
    return $out . substr($low, $last);
}

sub sentence {
    my ($s) = @_;
    (my $low = lc $s) =~ s/(\A\s*|[.!?\x{2026}]\s+)(\p{L})/$1 . uc $2/ge;
    return $low;
}

my %SLUG = (qw(ı i İ i ş s Ş s ğ g Ğ g ç c Ç c ö o Ö o ü u Ü u ß ss æ ae ø o đ d ł l));

sub slug {
    my ($s) = @_;
    $s =~ s/([ıİşŞğĞçÇöÖüÜßæøđł])/$SLUG{$1}/g;
    my $plain = NFKD($s);
    $plain =~ s/[\x{300}-\x{36f}]//g;
    $plain = lc $plain;
    $plain =~ s/[^a-z0-9]+/-/g;
    $plain =~ s/^-+|-+$//g;
    return $plain;
}

sub camel {
    my @w = words($_[0]);
    return join '', map { $_ == 0 ? lc $w[$_] : _capitalize(lc $w[$_]) } 0 .. $#w;
}

sub snake { return join '_', map { lc } words($_[0]) }
sub kebab { return join '-', map { lc } words($_[0]) }

sub clean {
    my ($s) = @_;
    my $nl = index($s, "\r\n") >= 0 ? "\r\n" : "\n";
    my @lines = map { (my $l = $_) =~ s/[ \t]+\z//; $l =~ s/(\S)[ \t]{2,}/$1 /g; $l } split /\r\n|\n/, $s, -1;
    my $out = join $nl, @lines;
    my $q = quotemeta $nl;
    $out =~ s/(?:$q){3,}/$nl$nl/g;
    return $out;
}

1;

__END__

=encoding utf8

=head1 NAME

GoSaveTool::Text - Word count, reading time, social media limits, Title Case, slugs and whitespace cleanup

=head1 SYNOPSIS

    use utf8;
    use GoSaveTool::Text qw(stats limits title slug);

    my $st = stats('Hello world. It’s 2026!');
    # { words => 4, chars => 23, charsNoSpaces => 20, lines => 1, sentences => 2, readSeconds => 1 }

    print limits($caption)->{'instagram-caption'}{left}, " characters left\n";
    print title('the lord of the rings'), "\n";   # The Lord of the Rings
    print slug('Ölçü Birimi & Çeviri!'), "\n";    # olcu-birimi-ceviri

=head1 DESCRIPTION

The Perl version of the C<@gosavetool/text> JavaScript package, from
L<GoSaveTool|https://www.gosavetool.com/>, free online tools for creators.
The same counter is online at L<https://www.gosavetool.com/character-counter>.

All functions take and return character strings (decode your input first, for
example with C<< open my $fh, '<:encoding(UTF-8)', $file >>). Characters are
Unicode code points, so an emoji counts as one.

=head1 FUNCTIONS

Nothing is exported by default.

=over 4

=item stats($text)

Hash reference with C<words>, C<chars>, C<charsNoSpaces>, C<lines>,
C<sentences> and C<readSeconds> (at 238 words a minute).

=item limits($text, @fields)

Hash reference of C<< { limit, used, left, fits } >> for each field of
C<%LIMITS>, or only the given fields: C<x-post>, C<instagram-caption>,
C<tiktok-caption>, C<youtube-title>, C<youtube-description>, C<linkedin-post>,
C<pinterest-description>, C<seo-title>, C<meta-description>.

=item title($text), sentence($text), upper($text), lower($text)

Case changes. Title Case keeps short words (a, of, the, and...) in lower case
unless they start the text or follow a colon.

=item slug($text), camel($text), snake($text), kebab($text)

C<olcu-birimi-ceviri>, C<bestPostingTime>, C<best_posting_time>,
C<best-posting-time>.

=item words($text)

The words C<camel>, C<snake> and C<kebab> join.

=item clean($text)

Removes trailing spaces, runs of spaces and more than one blank line in a row.

=back

=head1 SEE ALSO

L<GoSaveTool::Subtitles>

=head1 AUTHOR

GoSaveTool L<https://www.gosavetool.com/>

=head1 LICENSE

MIT License. See the LICENSE file.

=cut
