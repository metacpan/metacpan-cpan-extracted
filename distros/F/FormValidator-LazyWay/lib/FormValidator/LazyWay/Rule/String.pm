package FormValidator::LazyWay::Rule::String;

use strict;
use warnings;
use utf8;

sub length {
    my $text = shift;
    my $args = shift;

    die 'you must set max argument' unless exists $args->{max};
    die 'you must set min argument' unless exists $args->{min};

    return ( length $text > $args->{max} or length $text < $args->{min} ) ? 0 : 1;
}

sub stash_test {
    my ( $text, $args, $stash ) = @_;

#     # for debug
#     use Data::Dumper;
# 
#     warn $text;
#     warn Dumper $args;
#     warn Dumper $stash;

    return $stash ? 1 : 0;
}

sub ascii {
    my $text = shift;
    return $text =~ /^[\x20-\x7E]+$/ ? 1 : 0;
}

sub nonsymbol_ascii {
    my ($text, $args) = @_;

    if ( ref $args->{allow} eq 'ARRAY' ) {
        foreach my $allow ( @{$args->{allow}} ) {
            $text =~ s{$allow}{}xmsg;
        }
    }

    return $text =~ /^[a-zA-Z0-9]+$/ ? 1 : 0;
}

sub alphabet {
    my $text = shift;
    return $text =~ /^[a-zA-Z]+$/ ? 1 : 0;
}

sub number {
    my $text = shift;
    return $text =~ /^[0-9]+$/ ? 1 : 0;
}

1;

=head1 NAME

FormValidator::LazyWay::Rule::String - String Rule

=head1 METHOD

=head2 length

=head2 stash_test

=head2 ascii

=head2 nonsymbol_ascii

only alphabets and numbers.

you add $args->{allow} if you accept symbols.

  username:
    rule:
      - String#nonsimbol_ascii:
          args:
            allow:
              - '_'
              - '-'

=head2 alphabet

=head2 number

=cut

