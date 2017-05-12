package HTML::ExtractContent::Util;
use strict;
use warnings;
use utf8;

# cpan
use Exporter::Lite;
use HTML::Entities qw(decode_entities);
use HTML::Strip ();

sub strip {
    my $str = shift;
    $str =~ s/(^\s+|\s+$)//gs;
    return $str;
}

sub strip_tags {
    my $page = shift;
    my $hs = HTML::Strip->new;
    return $hs->parse($page);
}

sub eliminate_tags {
    my ($page, $tag) = @_;
    $page =~ s/<$tag[\s>].*?<\/$tag\s*>//igs;
    return $page;
}

sub eliminate_links {
    return eliminate_tags shift, 'a';
}

sub eliminate_forms {
    return eliminate_tags shift, 'form';
}

sub eliminate_br {
    my $page = shift;
    $page =~ s/<br[^>]*>/ /igs;
    return $page;
}

sub eliminate_invisible {
    my $page = shift;
    my $patterns = [
        qr/<!--.*?-->/is,
        qr/<(script|style|select|noscript)[^>]*>.*?<\/\1\s*>/is,
        qr/<div\s[^>]*(id|class)\s*=\s*['"]?\S*(more|menu|side|navi)\S*["']?[^>]*>/is,
    ];
    for my $pat (@$patterns) {
        $page =~ s/$pat//igs;
    }
    return $page;
}

sub extract_alt {
    my $page = shift;
    $page =~ s{
        # no backgrack or otherwise the time complexity will become O(n^2)
        <img \s [^>]* \b alt \s* = \s* (?>
            " ([^"]*) " | ' ([^']*) ' | ([^\s"'<>]+)
        ) [^>]* >
    }{
        defined $1 ? $1 : defined $2 ? $2 : $3
    }xigse;
    return $page;
}

sub unescape {
    my $page = shift;
    decode_entities($page);
}

sub reduce_ws {
    my $page = shift;
    $page =~ s/[ \t]+/ /g;
    $page =~ s/\n\s*/\n/gs;
    return $page;
}

sub decode {
    return strip (reduce_ws (unescape (strip_tags (eliminate_br shift))));
}

sub to_text {
    my ($html, $opts) = @_;
    $opts ||= {};
    $html = extract_alt $html if $opts->{with_alt};
    return decode $html;
}

sub match_count {
    my ($str, $exp) = @_;
    my @list = ($str =~ $exp);
    return $#list + 1;
}

our @EXPORT = qw/strip strip_tags eliminate_tags eliminate_links eliminate_forms eliminate_br eliminate_invisible extract_alt unescape reduce_ws decode to_text match_count/;

1;
