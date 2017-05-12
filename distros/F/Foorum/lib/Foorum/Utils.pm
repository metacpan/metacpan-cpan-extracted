package Foorum::Utils;

use strict;
use warnings;

our $VERSION = '1.001000';

use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/
    encodeHTML decodeHTML
    is_color
    generate_random_word
    get_page_from_url
    truncate_text
    be_url_part
    get_server_timezone_diff
    /;

use Encode ();

sub encodeHTML {
    my $text = shift;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
    }
    return $text;
}

sub decodeHTML {
    my $text = shift;
    for ($text) {
        s/\&amp;/\&/g;
        s/\&gt;/>/g;
        s/\&lt;/</g;
        s/\&quot;/"/g;
    }
    return $text;
}

sub is_color {
    my $color = shift;
    if ( $color =~ /^\#[0-9a-zA-Z]{6}$/ ) {
        return 1;
    } else {
        return 0;
    }
}

sub generate_random_word {
    my $len = shift;
    my @random_words = ( 'A' .. 'Z', 'a' .. 'z', 0 .. 9 );
    my $random_word;

    $len = 10 unless ($len);

    foreach ( 1 .. $len ) {
        $random_word .= $random_words[ int( rand( scalar @random_words ) ) ];
    }

    return $random_word;
}

sub get_page_from_url {
    my ($url) = @_;

    my $page = 1;
    if ( $url and $url =~ /\/page=(\d+)(\/|$)/ ) {
        $page = $1;
    }
    return $page;
}

sub truncate_text {
    my ( $text, $len ) = @_;

    return $text if ( length($text) <= $len );

    $text = Encode::decode( 'utf-8', $text );
    $text = substr( $text, 0, $len );
    $text = Encode::encode( 'utf-8', $text );
    $text .= ' ...';

    return $text;
}

sub be_url_part {
    my ($str) = @_;

    $str =~ s/\W+/\-/isg;
    $str =~ s/\-+/\-/isg;
    $str =~ s/(^\-|\-$)//isg;

    return $str;
}

sub get_server_timezone_diff {
    my @lmt  = (localtime);
    my @gmt  = (gmtime);
    my $diff = $gmt[2] - $lmt[2];
    if ( $gmt[5] > $lmt[5] || $gmt[7] > $lmt[7] ) {
        $diff += 24;
    } elsif ( $gmt[5] < $lmt[5] || $gmt[7] < $lmt[7] ) {
        $diff -= 24;
    }
    return $diff;
}

1;
__END__

=pod

=head1 NAME

Foorum::Utils - some common functions

=head1 FUNCTIONS

=over 4

=item encodeHTML/decodeHTML

Convert any '<', '>' or '&' characters to the HTML equivalents, '&lt;', '&gt;' and '&amp;', respectively. 

encodeHTML is the same as TT filter 'html'

=item is_color($color)

make sure color is ^\#[0-9a-zA-Z]{6}$

=item generate_random_word($len)

return a random word (length is $len), char is random ('A' .. 'Z', 'a' .. 'z', 0 .. 9)

!#@!$#$^%$ bad English

=item get_page_from_url

since we always use /page=(\d+)/ as in sub/pager.html

=item truncate_text

truncate text using Encode utf8

=item be_url_part

convert (title) string to be an acceptable URL part

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
