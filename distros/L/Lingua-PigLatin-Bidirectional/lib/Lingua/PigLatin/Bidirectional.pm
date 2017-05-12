package Lingua::PigLatin::Bidirectional;
use 5.008005;
use strict;
use warnings;
use utf8;

use base qw(Exporter);
our @EXPORT = qw(to_piglatin from_piglatin);

our $VERSION = "0.01";

sub to_piglatin {
    my $str = shift;

    $str =~ s{\b                 # See if each given word starts w/ or w/o
                ( qu             # 1. qu (e.g. question => estionquay)
                | [cgpstw]h      # 2. digraphs
                | [^\W0-9_aeiou] # 3. any "word" character other than
                                 #    0-9, _ and vowels
                )?
                ( [a-z]+ )       # and then alphabet character(s)
            }
            {
                if ( my $pre = $1 ) {
                    # if the first rule applies, append former part and add -ay
                    my $post = $2;
                    $pre =~ /\A [A-Z]/x
                        ? ucfirst($post) . lcfirst($pre) . 'ay' 
                        : $post . $pre . 'ay' ;
                }
                else {
                    # otherwise add -way
                    $2 . 'way';
                }
            }iegxms;

    return $str;
}

sub from_piglatin {
    my $str = shift;

    $str =~ s{                  # See if each given word consists of...
               ( [a-z]+ )way    # alphabet character(s) followed by "way"
             |                  # OR...
               ( [a-z]+? )      # zero or alphabet character(s) followed by...
               ( qu             # 1. qu
               | [cgpstw]h      # 2. digraphs
               | [^\W0-9_aeiou] # 3. any "word" character other than
                                #    0-9, _ and vowels
               )ay              # and trailing "ay"
            \b}
            {
                if ($1) {
                    $1;
                }
                else {
                    my $pre  = $2;
                    my $post = $3;
                    $pre =~ m/\A [A-Z]/x
                        ? ucfirst($post) . lcfirst($pre)
                        : $post . $pre ;
                }
            }iegxms;

    return $str;
}

1;
__END__

=encoding utf-8

=head1 NAME

Lingua::PigLatin::Bidirectional - Translates English sentences to Pig Latin, and vice versa.

=head1 SYNOPSIS

    use Lingua::PigLatin::Bidirectional;

    warn to_piglatin('hello');     # ellohay
    warn from_piglatin('ellohay'); # hello

=head1 DESCRIPTION

Lingua::PigLatin::Bidirectional translates to and from Pig Latin. This module
is originally inspired by Lingua::PigLatin, but this also handles 
re-translation from Pig Latin, hense the name.

Additionally, it cares case sensitivity.

=head1 METHODS

=over 4

=item to_piglatin

Returns a Pig-Latinized sentence.

=item from_piglatin

Re-Translate a Pig-Latinized sentence and returns plain English sentence.

=back

=head1 LICENSE

Copyright (C) Oklahomer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Oklahomer E<lt>hagiwara.go@gmail.comE<gt>

=cut

