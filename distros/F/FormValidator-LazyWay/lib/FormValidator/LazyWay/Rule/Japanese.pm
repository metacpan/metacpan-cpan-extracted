package FormValidator::LazyWay::Rule::Japanese;

use strict;
use warnings;
use Encode ();

sub hiragana {
    my $text = shift;
    my $args = shift;

    $text = Encode::decode('utf8', $text)
            if $args->{bytes};

    if ( ref $args->{allow} eq 'ARRAY' ) {
        foreach my $allow ( @{$args->{allow}} ) {
            $allow = Encode::decode('utf8', $allow)
                if $args->{bytes};
            $text =~ s{$allow}{}g;
        }
    }

    return ( $text =~ m{^\p{InHiragana}+$} ) ? 1 : 0;
}

sub hiragana_loose {
    my $text = shift;
    my $args = shift;

    $text = Encode::decode('utf8', $text)
            if $args->{bytes};

    return ( $text =~ m{^(\p{Common}|\p{InHiragana})+$} ) ? 1 : 0;
}

sub katakana {
    my $text = shift;
    my $args = shift;

    $text = Encode::decode('utf8', $text)
            if $args->{bytes};

    if ( ref $args->{allow} eq 'ARRAY' ) {
        foreach my $allow ( @{$args->{allow}} ) {
            $allow = Encode::decode('utf8', $allow)
                if $args->{bytes};
            $text =~ s{$allow}{}g;
        }
    }

    return ( $text =~ m{^\p{InKatakana}+$} ) ? 1 : 0;
}

1;

=head1 NAME

FormValidator::LazyWay::Rule::Japanese - Japanese Rule

=head1 METHOD

=head2 hiragana

=head2 hiragana_loose

=head2 katakana

=cut

