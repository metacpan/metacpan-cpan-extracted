use utf8;
use strict;
use warnings;
package Lingua::FuzzyTrans::PT2GL;
# ABSTRACT: Translates Portuguese words to Galician using fuzzy replacements
$Lingua::FuzzyTrans::PT2GL::VERSION = '0.001';
sub translate {
    my ($pt) = @_;

    my @subs = qw'ID
                A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                AA AB AC AD AE AF AG AH AI AJ AK AL AM AN';


    my $tmp;
    my $subs = {
                ID => sub { },
                A => sub { s/ss/s/gi for @$_  },
                B => sub { s/j/x/gi  for @$_},
                C => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/uição$/ución/i for @$one;
                    s/ção$/ción/i for @$one;

                    s/ção$/zón/i  for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                D => sub { s/ç/z/gi  for @$_},
                E => sub { s/nh/ñ/gi  for @$_ },
                F => sub { s/dizer$/dicir/i for @$_ },
                G => sub { s/z(?=[eiéíêî])/c/gi  for @$_},
                H => sub { s/lh/ll/gi  for @$_},
                I => sub { s/vr/br/gi  for @$_},
                J => sub { s/agem$/axe/i  for @$_},
                K => sub { s/g(?=[eiéíêî])/x/ig  for @$_},
                L => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/ável$/able/i for @$one;
                    s/ável$/ábel/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                M => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/ível$/ible/i for @$one;
                    s/ível$/íbel/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                N => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/velmente$/belmente/i for @$one;
                    s/velmente$/blemente/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                O => sub { s/eio$/eo/i    for @$_},
                P => sub { s/ância$/ancia/i  for @$_},
                Q => sub { s/ência$/encia/i  for @$_},
                R => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/aria$/ería/i for @$one;
                    s/aria$/aría/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                S => sub { s/ário$/ario/i  for @$_},
                T => sub { s/óri([oa])$/ori$1/i for @$_},
                U => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/são$/sión/i for @$one;
                    s/são$/són/i  for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                V => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/rão$/rón/i for @$one;
                    s/rão$/rán/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                W => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/mão$/món/i for @$one;
                    s/mão$/mán/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                X => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/ião$/ión/i for @$one;
                    s/ião$/ián/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                Y => sub { s/ício$/icio/i for @$_ },
                Z => sub { s/óide$/oide/i for @$_ },
                AA => sub { s/ídio$/idio/i for @$_ },
                AB => sub { s/ânico$/ánico/i for @$_ },
                AC => sub { s/édia$/edia/i for @$_ },
                AD => sub { s/(.)cimento$/$1cemento/i for @$_ },
                AE => sub { s/m$/n/i for @$_ },
                AF => sub { s/crever$/cribir/i for @$_ },
                AG => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/u$/o/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                AH => sub { s/var$/bar/i for @$_ },
                AI => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/^im/inm/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                AJ => sub { 
                    #s/qua/cua/i for @$_;
                    my $one = [@$_];
                    my $two = [@$_];
                    s/^qua/cua/i for @$one;
                    s/^qua/ca/i  for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                AK => sub { s/qua/cua/i for @$_ },
                AL => sub { #s/xão$/xión/i for @$_
                    my $one = [@$_];
                    my $two = [@$_];

                    s/xão$/xón/i  for @$one;
                    s/xão$/xión/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                AM => sub {
                    my $one = [@$_];
                    my $two = [@$_];

                    s/rv/rb/i for @$two;

                    my %x;
                    $x{$_}++ for (@$one, @$two);
                    $_ = [ keys %x ]
                },
                AN => sub { s/iver$/ivir/i for @$_ },
               };

    local $_ = [$pt];
    for my $s (@subs) {
      $subs->{$s}->();
    }
    return @$_;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::FuzzyTrans::PT2GL - Translates Portuguese words to Galician using fuzzy replacements

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use utf8;
    use Lingua::FuzzyTrans::PT2GL;
    my @trans = Lingua::FuzzyTrans::PT2GL::translate("coração");

=head1 DESCRIPTION

A simple rule-substitution-based fuzzy translator from Portuguese
words to Galician words, as despicted on L<Dictionary Alignment based
on Rewrite-based Entry
Translation|http://drops.dagstuhl.de/opus/volltexte/2013/4041/pdf/16.pdf>.

=head2 translate

This is the only method available and that is not exportable. To use it you
should qualify the full method call with the package name as shown in the
synopsys.

It receives a portuguese word, returns a list of possible orthographies for
that same word in Galician.

B<NOTE:> This is not a translator, just a fuzzy-replacer, that tries to guess
Galician words by simple substitutions.

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
