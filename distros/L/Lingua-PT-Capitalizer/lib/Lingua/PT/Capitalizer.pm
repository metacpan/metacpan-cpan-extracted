package Lingua::PT::Capitalizer;

use common::sense;
use English qw[-no_match_vars];

use base qw[ Exporter ];
our @EXPORT = q(capitalize);

our $VERSION = '0.001'; # VERSION

our %lc_always = (
    q(a)   => 1,
    q(á)   => 1,
    q(à)   => 1,
    q(aos) => 1,
    q(às)  => 1,
    q(d')  => 1,    # elisão
    q(da)  => 1,
    q(das) => 1,
    q(de)  => 1,
    q(di)  => 1,
    q(do)  => 1,
    q(dos) => 1,
    q(e)   => 1,
    q(na)  => 1,
    q(nas) => 1,
    q(no)  => 1,
    q(nos) => 1,
    q(o)   => 1,
    q(os)  => 1,
);

sub capitalize {
    my ( $self, $text, $preserve_caps )
        = ref $_[0] eq __PACKAGE__
        ? @_
        : ( undef, @_ );

    $text //= $_;

    return unless defined $text;

    my @token = _pt_word_tokenizer($text);

    foreach ( my $i = 0; $i <= $#token; $i++ ) {
        foreach ( $token[$i] ) {
            if ( $preserve_caps ~~ q(1)
                && m{^\p{Lu}+(?:\N{APOSTROPHE})?$}msx )
            {
                next;
            }

            my $lc = lc;
            when ( $i == 0 ) { $_ = ucfirst $lc; }
            when ( substr( $_, -1 ) eq q(.) ) { $_ = ucfirst $lc; }
            when ( exists $lc_always{$lc} ) { $_ = $lc; }
            default {
                $_ = ucfirst $lc;
            }
        } ## end foreach ( $token[$i] )
    } ## end foreach ( my $i = 0; $i <= ...)

    $text = join q(), @token;

    return $text;
} ## end sub capitalize

sub _pt_word_tokenizer {
    my $text = shift;

    my $re = qr{(\p{L}+(?:\N{APOSTROPHE}|\p{L}{0,2}))}msx;

    my @token = split $re, $text;
    @token = grep { defined && $_ ne q() } @token;

    return @token;
}

sub new {
    my $class = shift;
    my $self  = {
        capitalize => \&capitalize,
        lc_always  => \%lc_always,
    };
    return bless $self, $class;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Lingua::PT::Capitalizer - Simple text capitalize.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head2 Procedural Interface

   use Lingua::PT::Capitalizer;
   my $text = q(ESCRITOR, JORNALISTA, CONTISTA E POETA JOAQUIM MARIA MACHADO DE ASSIS);
   say capitalize($text);
   # Output:
   # Escritor, Jornalista, Contista e Poeta Joaquim Maria Machado de Assis

   $text = q(comprehensive perl archive network (CPAN));
   say capitalize($text, 1);
   # Output:
   # Comprehensive Perl Archive Network (CPAN)

=head2 OO Interface

    use Lingua::PT::Capitalizer ();

    my $capitalizer = Lingua::PT::Capitalizer->new();
    my $text = q(ESCRITOR, JORNALISTA, CONTISTA E POETA JOAQUIM MARIA MACHADO DE ASSIS);
    say $capitalizer->capitalize($text);
    # Output:
    # Escritor, Jornalista, Contista e Poeta Joaquim Maria Machado de Assis

    $text = q(comprehensive perl archive network (CPAN));
    say $capitalizer->capitalize($text, 1);
    # Output:
    # Comprehensive Perl Archive Network (CPAN)

=head1 DESCRIPTION

This  module  format   strings  in  title-case mode   using  common typographic
rules for proper names in S<B<Portuguese Language>>.

=head1 SUBROUTINES/METHODS

=head2 capitalize

Receive  one  or  two  arguments  and   return  a  capitalized  string.  If the
second  argument is C<1>, the upper  case words won't be affected.

=head2 lc_always

A  data  structure  with  some  articles  and  prepositions  that  normaly stay
in lower case.

=head1 EXAMPLES

=head2 Using files as input

If F<text.txt>  is a file with  names/titles to capitalize, the  easiest way to
capitalize all is:

    perl -MLingua::PT::Capitalizer -wpE'$_=capitalize' text.txt

=head2 Getting lc_always hash

   # Procedural Interface
   my %lc_always = %{Lingua::PT::Capitalizer::lc_always}

   # OO Interface
   my %lc_always = $capitalizer->{lc_always}

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=head1 SEE ALSO

Text::Capitalize.

=cut
