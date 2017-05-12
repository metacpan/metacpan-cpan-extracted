package Lingua::JA::Fold;

use 5.008;
use strict;
use warnings;
use utf8;

our $VERSION = '0.08'; # 2008-03-19 (since 2003-03-26)

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    fold
);
our @EXPORT_OK = qw(
    length_full length_half
    tab2space kana_half2full
);

use Encode;
use Carp;

=head1 NAME

Lingua::JA::Fold - to fold a Japanese text.

=head1 SYNOPSIS

 use utf8;
 use Lingua::JA::Fold qw(fold tab2space kana_half2full);
 
 my $text = 'ｱｲｳｴｵ	漢字';
 
 # replace a [TAB] with four [SPACE]s.
 $text = tab2space('text' => $text, 'space' => 4);
 # convert a half-width 'Kana' character to a full-width one.
 $text = kana_half2full($text);
 
 # fold a text under full-width two characters par a line.
 $text = fold('text' => $text, 'length' => 2);
 
 # output the result
 utf8::encode($text);
 print $text;

=head1 DESCRIPTION

This module is used to fold a Japanese text and so on.

The Japanese (the Chinese and the Korean would be the same) text has traditionally unique manner in representing. Basically those characters are used to be represented in two kind of size which is 'full-width' or 'half-width'. Width and Height of full-width characters are the same size (regular square). At the point, it is different from the alphabet characters which have normally variable (slim) width in representing. Roughly say, we call width of alphabet characters and Arabic numbers as a half, and do the width of other characters as a full. In a Japanese text which is mixed with alphabet and Arabic numbers, a character has a width, it would be full or half.

For such reasons, to fold a Japanese text is rather complicate thing.

=head1 FUNCTIONS

=over

=item fold('text' => $text, 'length' => $i [, 'mode' => $mode])

Function. To fold a string within specified length of $i.

The way in which to calculate length is differs by a mode.

 'full-width' : culculated for a full-width character.
 'traditional': culculated for a full-width character; reflects traditional manner of composition.
 (not given)  : igore size difference between a full and a half.

=cut

sub fold {
    my %param = @_;
    
    # check parameters
    unless ($param{'text'}) {
        return undef;
    }
    if (not $param{'length'} or $param{'length'} =~ m/\D/) {
        croak "length must be given as an integer value of more than 1";
    }
    
    # UTF-8 flag on
    utf8::decode( $param{'text'} );
    
    # newline character unification
    $param{'text'} =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
    
    # split a text to lines
    my @line;
    while ($param{'text'}) {
        if ($param{'text'} !~ m/\n/) {
            # single line; end without newline
            push @line, $param{'text'};
            last;
        }
        else {
            # single line; end with newline
            # multi line; end with/without newline
            $param{'text'} =~ s/^[^\n]*?\n//s;
            push @line, $&;
        }
    }
    
    # folding mode junction
    if (not $param{'mode'}) {
        &fold_1($param{'length'}, \@line);
    }
    elsif ($param{'mode'} eq 'full-width') {
        &fold_2($param{'length'}, \@line);
    }
    elsif ($param{'mode'} eq 'traditional') {
        &fold_3($param{'length'}, \@line);
    }
    
    return join '', @line;
}

sub fold_1 {
    my($length, $ref) = @_;
    
    # fold each lines
    foreach my $line ( @{$ref} ) {
        my @folded;
        while ($line) {
            if (length($line) > $length) {
                my $newfold;
                ($newfold, $line) = cutter_1($length, $line);
                push(@folded, $newfold);
            }
            else {
                last;
            }
        }
        my $folded = join("\n", @folded);
        if ($folded) {
            $line = "$folded\n$line";
        }
    }
    
    return 1;
}
sub cutter_1 {
    my($length, $string) = @_;
    my $folded = substr($string, 0, $length);
    my $unfold = substr($string, $length);
    return $folded, $unfold;
}

sub fold_2 {
    my($length, $ref) = @_;
    
    # fold each lines
    foreach my $line ( @{$ref} ) {
        my @folded;
        while ($line) {
            if (length_full($line) > $length) {
                my $newfold;
                ($newfold, $line) = cutter_2($length, $line);
                push(@folded, $newfold);
            }
            else {
                last;
            }
        }
        my $folded = join("\n", @folded);
        if ($folded) {
            $line = "$folded\n$line";
        }
    }
    
    return 1;
}
sub cutter_2 {
    my($length, $string) = @_;
    my $chars = $length;
    my $folded = substr($string, 0, $chars);
    my $shortage = $length - length_full($folded);
    while ($shortage != 0) {
        if ($shortage < 0) {
            $chars -= 1;
            $folded = substr($string, 0, $chars);
            last;
        }
        else {
            $chars += int($shortage + 0.5);
            $folded = substr($string, 0, $chars);
            $shortage = $length - length_full($folded);
            next;
        }
    }
    my $unfold = substr($string, $chars);
    return $folded, $unfold;
}

=item The Japanese Traditional Manner of Composition

This formal manner is another saying as the forbidden rule. The rule is: 1) a termination mark like Ten "," and Maru ".", 2) a closing mark -- brace or parenthesis or bracket -- like ")", "}", "]", ">" and etc., 3) a repeat mark, those should not be placed at the top of a line. If it would be occured, such mark should be moved to the next to the bottom of the previous line.

Actually by this module what is detect as a forbidden mark are listed next:

 ’”、。〃々〉》」』】〕〟ゝゞヽヾ），．］｝

Note that all of these marks are full-width Japanese characters.

=cut

my $Forbidden = '’”、。〃々〉》」』】〕〟ゝゞヽヾ），．］｝';
# my $Forbidden = '\x{2019}\x{201D}\x{3001}-\x{3003}\x{3005}\x{3009}\x{300B}\x{300D}\x{300F}\x{3011}\x{3015}\x{301F}\x{309D}\x{309E}\x{30FD}\x{30FE}\x{FF09}\x{FF0C}\x{FF0E}\x{FF3D}\x{FF5D}';

sub fold_3 {
    my($length, $ref) = @_;
    
    # fold each lines
    foreach my $line ( @{$ref} ) {
        my @folded;
        while ($line) {
            if (length_full($line) > $length) {
                my $newfold;
                ($newfold, $line) = cutter_3($length, $line);
                push(@folded, $newfold);
            }
            else {
                last;
            }
        }
        my $folded = join "\n", @folded;
        if ($folded) {
            if ( length($line) ) {
                if ($line eq "\n") {
                    $line = "$folded$line";
                }
                else {
                    $line = "$folded\n$line";
                }
            }
            else {
                $line = $folded;
            }
        }
    }
    
    return 1;
}
sub cutter_3 {
    my($length, $string) = @_;
    
    my $chars = $length;
    my $folded = substr($string, 0, $chars);
    my $shortage = $length - length_full($folded);
    while ($shortage != 0) {
        if ($shortage < 0) {
            $chars -= 1;
            $folded = substr($string, 0, $chars);
            last;
        }
        else {
            $chars += int($shortage + 0.5);
            $folded = substr($string, 0, $chars);
            $shortage = $length - length_full($folded);
            next;
        }
    }
    my $unfold = substr($string, $chars);
    
    while ($unfold) {
        my $char_top = substr($unfold, 0, 1);
        if ($char_top =~ /[$Forbidden]/) {
            $folded .= $char_top;
            $unfold = substr($unfold, 1);
            next;
        }
        else {
            last;
        }
    }
    
    return $folded, $unfold;
}

=item length_half($text)

Function. Exportable. This is for counting length of a text for a half-width character. 

=cut

sub length_half ($) {
    my $string = shift;
    
    # remove all ASCII controls except for [SPACE]
    $string =~ tr/\x00-\x1F\x7F//d;
    
    # ascii: arabic numbers, alphabets, marks
    my $ascii     = $string =~ tr/\x20-\x7E//d;
    # half-width characters in the Unicode compatibility area
    my $halfwidth = $string =~ tr/\x{FF61}-\x{FF9F}\x{FFE0}-\x{FFE5}//d;
    # the rest: full-width characters
    my $rest = length($string);
    
    return $ascii + $halfwidth + $rest * 2;
}

=item length_full($text)

Function. Exportable. This is for counting length of a text for a full-width character. 

=cut

sub length_full ($) {
    my $string = shift;
    
    # remove all ASCII controls except for [SPACE]
    $string =~ tr/\x00-\x1F\x7F//d;
    
    # ascii: arabic numbers, alphabets, marks
    my $ascii     = $string =~ tr/\x20-\x7E//d;
    # half-width characters in the Unicode compatibility area
    my $halfwidth = $string =~ tr/\x{FF61}-\x{FF9F}\x{FFE0}-\x{FFE5}//d;
    # the rest: full-width characters
    my $rest = length($string);
    
    return ($ascii + $halfwidth) * 0.5 + $rest;
}

# sub _length_full_fixed {}

=item tab2space('text' => $text, 'space' => $i)

Function. Exportable. To replace a [TAB] character in a text with given number of [SPACE]s.

=cut

sub tab2space {
    my %param = @_;
    
    # check parameters
    unless ($param{'text'}) {
        return undef;
    }
    if (not $param{'space'} or $param{'space'} =~ m/\D/) {
        croak "space must be given as an integer value of more than 1";
    }
    
    my $spaces = ' ';
    $spaces x= $param{'space'};
    
    # replacement
    $param{'text'} =~ s/\t/$spaces/g;
    
    return $param{'text'};
}

=item kana_half2full($text)

Function. Exportable. To convert a character in a text from half-width 'Kana' to full-width one.

=cut

sub kana_half2full {
    my $text = shift;
    
    $text = encode('iso-2022-jp', $text);
    $text = decode('iso-2022-jp', $text);
    
    return $text;
}

########################################################################
1;
__END__

=back

=head1 SEE ALSO

=over

=item module: L<utf8>

=item module: L<Encode>

=back

=head1 NOTE

This module runs under Unicode/UTF-8 environment (hence Perl5.8 or later is required), you should input text as UTF-8 flaged string. Specify the C<use utf8;> pragma in your source code and use utf8::decode() method to UTF-8 flag on.

=head1 AUTHOR

Masanori HATA L<http://www.mihr.net/> (Saitama, JAPAN)

=head1 COPYRIGHT

Copyright ©2003-2008 Masanori HATA. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

