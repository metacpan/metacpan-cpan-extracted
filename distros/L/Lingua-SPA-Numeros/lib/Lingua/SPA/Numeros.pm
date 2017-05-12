# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-
#
# Jose Luis Rey Barreira (C) 2001-2009
#

package Lingua::SPA::Numeros;
# ABSTRACT: Number 2 word conversion in SPA.

# {{{ use block

use 5.10.1;
use utf8;
use strict;
use warnings;

use Carp;

# }}}
# {{{ variables declarations

our $VERSION = 0.0682;


our @EXPORT_OK = qw( $MALE $FEMALE $NEUTRAL $MALE $FEMALE $NEUTRAL);

no warnings; ## no critic
our $MALE    => 'o';
our $FEMALE  => 'a';
our $NEUTRAL => '';
use warnings;

use fields qw/ ACENTOS MAYUSCULAS UNMIL HTML DECIMAL SEPARADORES GENERO
    POSITIVO NEGATIVO FORMATO /;

my %opt_alias = qw(
    ACCENTS     ACENTOS
    UPPERCASE   MAYUSCULAS
    SEPARATORS  SEPARADORES
    GENDER      GENERO
    POSITIVE    POSITIVO
    NEGATIVE    NEGATIVO
    FORMAT      FORMATO );

my %new_defaults = (
    ACENTOS     => 1,
    MAYUSCULAS  => 0,
    UNMIL       => 1,
    HTML        => 0,
    DECIMAL     => '.',
    SEPARADORES => '_',
    GENERO      => $MALE,
    POSITIVO    => '',
    NEGATIVO    => 'menos',
    FORMATO     => 'con %02d ctms.',
);

# }}}
# {{{ new

sub new {
    my $self = shift;
    unless ( ref $self ) {
        $self = fields::new($self);
    }

    #%$self = (%new_defaults, @_);
    {    # Compatibility conversion of SEXO into GENERO
        my %opts = ( %new_defaults, @_ );
        if ( $opts{'SEXO'} ) {
            $opts{'GENERO'} = $opts{'SEXO'};
            delete $opts{'SEXO'};
        }
        %$self = %opts
    }
    return $self;
}

# }}}
# {{{ cardinal

sub cardinal {
    my $self = shift;
    my $num  = shift;
    my ( $sgn, $ent, $frc, $exp ) = parse_num( $num, $self->{'DECIMAL'}, $self->{'SEPARADORES'} );
    my @words = cardinal_simple( $ent, $exp, $self->{'UNMIL'}, $self->{'GENERO'} );
    if (@words) {
        unshift @words, $self->{'NEGATIVO'} if $sgn < 0 and $self->{'NEGATIVO'};
        unshift @words, $self->{'POSITIVO'} if $sgn > 0 and $self->{'POSITIVO'};
        return $self->retval( join( " ", @words ) );
    }
    else {
        return $self->retval('cero');
    }
}

# }}}
# {{{ real

sub real {
    my $self = shift;
    my ( $num, $genf, $genm ) = @_;
    my ( $sgn, $ent, $frc, $exp ) = parse_num( $num, $self->{'DECIMAL'}, $self->{'SEPARADORES'} );

    my $gen = $self->{'GENERO'};
    $genf = $gen  unless defined $genf;
    $genm = $genf unless defined $genm;

    # Convertir la parte entera ajustando el sexo
    #my @words = cardinal_simple($ent, $exp, $self->{'UNMIL'}, $gen);

    # Traducir la parte decimal de acuerdo al formato
    for ( $self->{'FORMATO'} ) {
        /%([0-9]*)s/ && do {

            # Textual, se traduce según el genero
            $frc = substr( '0' x $exp . $frc, 0, $1 ) if $1;
            $frc = join( " ", fraccion_simple( $frc, $exp, $self->{'UNMIL'}, $genf, $genm ) );
            $frc = $frc ? sprintf( $self->{'FORMATO'}, $frc ) : '';
            last;
        };
        /%([0-9]*)d/ && do {

            # Numérico, se da formato a los dígitos
            $frc = substr( '0' x $exp . $frc, 0, $1 );
            $frc = sprintf( $self->{'FORMATO'}, $frc );
            last;
        };
        do {

            # Sin formato, se ignoran los decimales
            $frc = '';
            last;
        };
    }
    if ($ent) {
        $ent = $self->cardinal( ( $sgn < 0 ? '-' : '+' ) . $ent );
    }
    else {
        $ent = 'cero';
    }
    $ent .= ' ' . $frc if $ent and $frc;
    return $self->retval($ent);
}

# }}}
# {{{ ordinal

sub ordinal {
    my $self = shift;
    my $num  = shift;
    my ( $sgn, $ent, $frc, $exp ) = parse_num( $num, $self->{'DECIMAL'}, $self->{'SEPARADORES'} );

    croak "Ordinal negativo"     if $sgn < 0;
    carp "Ordinal con decimales" if $frc;

    if ( $ent =~ /^0*$/ ) {
        carp "Ordinal cero";
        return '';
    }

    my $text = join( " ", ordinal_simple( $ent, $exp, $self->{'GENERO'} ) );

    return $self->retval($text);
}

# }}}

{    # Build the accessors
    my @a = @_;
    my %names = ( ( map { $_ => $_ } keys %new_defaults ), %opt_alias );
    while ( my ( $opt, $alias ) = each %names ) {
        $opt = lc $opt;
        no strict 'refs'; ## no critic
        *$opt = sub {
            my $self = shift;
            return $self->{$alias} unless @a;
            $self->{$alias} = shift @a;
            return $self;
            }
    }
}

# }}}

#####################################################################
#
# Soporte para números CARDINALES
#
####################################################################
# {{{ variable declarations II

my @cardinal_30 = qw/ cero un dos tres cuatro cinco seis siete ocho nueve diez
    once doce trece catorce quince dieciséis diecisiete dieciocho diecinueve
    veinte veintiun veintidós veintitrés veinticuatro veinticinco veintiséis
    veintisiete veintiocho veintinueve /;

my @cardinal_dec = qw/
    0 1 2 treinta cuarenta cincuenta sesenta setenta ochenta noventa /;

my @cardinal_centenas = (
    "", qw/
        ciento doscientos trescientos cuatrocientos quinientos
        seiscientos setecientos ochocientos novecientos /
);

my @cardinal_megas = (
    "", qw/ m b tr cuatr quint sext sept oct non dec undec
        dudec tredec cuatordec quindec sexdec sepdec octodec novendec vigint /
);

my $MAX_DIGITS = 6 * @cardinal_megas;

# }}}
# {{{ cardinal_e2

sub cardinal_e2 {
    my ( $n, $nn ) = @_;

    return if $n == 0;
    do { push @$nn, $cardinal_30[$n]; return } if $n < 30;
    $n =~ /^(.)(.)$/;
    push @$nn, $cardinal_30[$2], "y" if $2;
    push @$nn, $cardinal_dec[$1];

    return;
}

# }}}
# {{{ cardinal_e3

sub cardinal_e3 {
    my ( $n, $nn ) = @_;

    return if $n == 0;
    $n == 100 and do { push @$nn, "cien"; return };
    cardinal_e2( $n % 100, $nn );
    $n >= 100 and push @$nn, $cardinal_centenas[ int( $n / 100 ) ];

    return;
}

# }}}
# {{{ cardinal_e6

sub cardinal_e6 {
    my ( $n, $nn, $mag, $un_mil, $postfix ) = @_;

    return if $n == 0;
    push @$nn, $cardinal_megas[$mag] . $postfix->[ $n == 1 ] if $mag;
    cardinal_e3( $n % 1000, $nn );
    my $n3 = int( $n / 1000 );
    if ($n3) {
        push @$nn, "mil";
        cardinal_e3( $n3, $nn ) if $n3 != 1 or $un_mil;
    }

    return;
}

# }}}
# {{{ cardinal_generic

sub cardinal_generic {
    my ( $n, $exp, $fmag, $gen ) = @_;
    $gen //= '';

    $n =~ s/^0*//;    # eliminar ceros a la izquierda
    return () unless $n;
    croak("Fuera de rango") if length($n) + $exp > $MAX_DIGITS;
    $n .= "0" x ( $exp % 6 );    # agregar ceros a la derecha
    my $mag   = int( $exp / 6 );
    my @group = ();
    $fmag->( $1, \@group, $mag++ ) while $n =~ s/(.{1,6})$//x;
    $group[0] .= $gen if $group[0] =~ /un$/;
    return reverse @group;
}

# }}}
# {{{ cardinal_simple

sub cardinal_simple {
    my ( $n, $exp, $un_mil, $gen ) = @_;

    $un_mil = $un_mil ? 1 : 0;
    $gen = $NEUTRAL unless $gen;
    my $format = sub {
        cardinal_e6( $_[0], $_[1], $_[2], $un_mil, [ 'illones', 'illón' ] );
    };
    return cardinal_generic( $n, $exp, $format, $gen );
}


# }}}
# {{{ fraccion_mag_prefix

sub fraccion_mag_prefix {
    my ( $mag, $gp ) = @_;

    return "" unless $mag;
    return "décim" . $gp    if $mag == 1;
    return "centésim" . $gp if $mag == 2;
    my $format = sub {
        cardinal_e6( $_[0], $_[1], $_[2], 0, [ 'illon', 'illon' ] );
    };
    my @name = cardinal_generic( 1, $mag, $format, "" );
    shift @name unless $mag % 6;
    return join( "", @name, "ésim", $gp );
}

# }}}
# {{{ fraccion_simple

sub fraccion_simple {
    my ( $n, $exp, $un_mil, $gen, $ngen ) = @_;

    $n =~ s/0*$//;    # eliminar 0 a la derecha
    return () if $n == 0;
    $ngen = $gen unless defined $ngen;
    $exp = -$exp + length $n;    # adjust exponent
    croak("Fuera de rango") if $exp > $MAX_DIGITS;
    $gen .= "s" unless $n =~ /^0*1$/;
    return ( cardinal_simple( $n, 0, $un_mil, $ngen ), fraccion_mag_prefix( $exp, $gen ) );
}

#####################################################################
#
# Soporte para números ORDINALES
#
####################################################################
# {{{ variable declarations III

my @ordinal_13 = (
    '', qw/ primer_ segund_ tercer_ cuart_ quint_ sext_
        séptim_ octav_ noven_ décim_ undécim_ duodécim_ /
);

my @ordinal_dec = qw/ 0 1 vi tri cuadra quicua sexa septua octo nona /;

my @ordinal_cen = qw/ 0 c duoc tric cuadring quing sexc septig octing noning /;

# }}}
# {{{ ordinal_e2

sub ordinal_e2 {
    my ( $n, $nn ) = @_;

    return if $n == 0;
    if ( $n < 13 ) {
        push @$nn, $ordinal_13[$n];
        return;
    }
    $n =~ /^(.)(.)$/;
    my $lo = $ordinal_13[$2];
    if ( $1 <= 2 ) {
        my $name = $2
            ? ( $1 == 1 ? 'decimo' : 'vigesimo' )
            : ( $1 == 1 ? 'décim_' : 'vigésim_' );
        $name =~ s/o$// if $2 == 8;    # special case vowels colapsed
        push @$nn, $name . $lo;
        return;
    }
    push @$nn, $lo if $2;
    push @$nn, $ordinal_dec[$1] . 'gésim_';
    return;
}

# }}}
# {{{ ordinal_e3

sub ordinal_e3 {
    my ( $n, $nn ) = @_;

    return if $n == 0;
    ordinal_e2( $n % 100, $nn );
    push @$nn, $ordinal_cen[ int( $n / 100 ) ] . 'entésim_' if $n > 99;

    return;
}

# }}}
# {{{ ordinal_e6

sub ordinal_e6 {
    my ( $n, $nn, $mag ) = @_;

    return if $n == 0;
    push @$nn, $cardinal_megas[$mag] . 'illonésim_' if $mag;
    ordinal_e3( $n % 1000, $nn );
    my $n3 = int( $n / 1000 );
    if ($n3) {
        if ( $n3 > 1 ) {
            my $pos = @$nn;    # keep pos to adjust number
            cardinal_e3( $n3, $nn );    # this is not a typo, its cardinal
            $nn->[$pos] .= 'milésim_';
        }
        else {
            push @$nn, "milésim_";
        }
    }

    return;
}

# }}}
# {{{ ordinal_simple

sub ordinal_simple {
    my ( $n, $exp, $gen ) = @_;

    $n =~ s/^0*//;    # eliminar ceros a la izquierda
    return () unless $n;
    croak("Fuera de rango") if length($n) + $exp > $MAX_DIGITS;
    $n .= "0" x ( $exp % 6 );    # agregar ceros a la derecha
    my $mag = int( $exp / 6 );

    my @group = ();
    if ( $mag == 0 ) {
        $n =~ s/(.{1,6})$//x;
        ordinal_e6( $1, \@group, $mag++ );
    }

    while ( $n =~ s/(.{1,6})$//x ) {
        if ( $1 == 0 ) {
            $mag++;
            next;
        }
        my $words = [];
        if ( $1 == 1 ) {
            push @$words, '';
        }
        else {
            cardinal_e6( $1, $words, 0, 0, [] );
        }
        $words->[0] .= $cardinal_megas[ $mag++ ] . 'illonésim_';
        push @group, @$words;
    }

    unless ($gen) {
        $group[0] =~ s/r_$/r/;    # Ajustar neutros en 1er, 3er, etc.
        $gen = $MALE;
    }
    s/_/$gen/g for @group;
    return reverse @group;
}

# }}}
# {{{ parse_num

sub parse_num {
    my ( $num, $dec, $sep ) = @_;

    # Eliminar blancos y separadores
    $num =~ s/[\s\Q$sep\E]//g;
    $dec = '\\' . $dec if $dec eq '.';
    my ( $sgn, $int, $frc, $exp ) = $num =~ /^
        ([+-]?) (?= \d | $dec\d )   # signo
        (\d*)                       # parte entera
        (?: $dec (\d*) )?           # parte decimal
        (?: [Ee] ([+-]?\d+) )?      # exponente
        $/x or croak("Error de sintaxis");

    $sgn = $sgn eq '-' ? -1 : 1;    # ajustar signo
    return ( $sgn, $int || 0, $frc || 0, $exp ) unless $exp ||= 0;

    $int ||= '';
    $frc ||= '';

    # reducir la magnitud del exponente
    if ( $exp > 0 ) {
        if ( $exp > length $frc ) {
            $exp -= length $frc;
            $int .= $frc;
            $frc = '';
        }
        else {
            $int .= substr( $frc, 0, $exp );
            $frc = substr( $frc, $exp );
            $exp = 0;
        }
    }
    else {
        if ( -$exp > length $int ) {
            $exp += length $int;
            $frc = $int . $frc;
            $int = '';
        }
        else {
            $frc = substr( $int, $exp + length $int ) . $frc;
            $int = substr( $int, 0, $exp + length $int );
            $exp = 0;
        }
    }
    return ( $sgn, $int || 0, $frc || 0, $exp );
}

# }}}
# {{{ retval

sub retval {
    my $self = shift;
    my $rv   = shift;
    if ( $self->{ACENTOS} ) {
        if ( $self->{HTML} ) {
            $rv =~ s/([áéíóú])/&$1acute;/g;
            $rv =~ tr/áéíóú/aeiou/;
        }
    }
    else {
        $rv =~ tr/áéíóú/aeiou/;
    }
    return $self->{MAYUSCULAS} ? uc $rv : $rv;
}

# }}}

1;
__END__

# {{{ module documentation

=head1 NAME

Lingua::SPA::Numeros - Translates numbers to spanish text

=head1 VERSION

version 0.0682

=head1 SYNOPSIS

   use Lingua::SPA::Numeros

   $obj = new Lingua::SPA::Numeros ('MAYUSCULAS' => 1)
   print $obj->Cardinal(124856), "\n";
   print $obj->Real(124856.531), "\n";
   $obj->{GENERO} = $FEMALE;
   print $obj->Ordinal(124856), "\n";

=head1 DESCRIPTION

Number 2 word conversion in SPA.

This module supports the translation of cardinal, ordinal and, real numbers, the
module handles integer numbers up to vigintillions (that's 1e120), since Perl
does not handle such numbers natively, numbers are kept as text strings because
processing does not justify using bigint.

Currently Lingua::SPA::Numeros handles numbers up to 1e127-1 (999999 vigintillions).

=head1 METHODS

=head2 CONSTRUCTOR: new

To create a new Lingua::SPA::Numeros, use the B<new> class method. This method can
receive as parameters any of the above mentioned fields. 

Examples:

      use Lingua::SPA::Numeros;
      
      # Use the fields' default values
      $obj = new Lingua::SPA::Numeros; 
      
      # Specifies the values of some of them
      $obj = Lingua::SPA::Numeros->new( ACENTOS => 0, 
                MAYUSCULAS => 1, GENERO => $FEMALE,
                DECIMAL => ',', SEPARADORES=> '"_' );

=over 4

=item DECIMAL

Specifies the character string that will be used to separate the integer
from the fractional part of the number to convert. The default value for
DECIMAL is '.'

=item SEPARADORES

Character string including all of the format characters used when
representing a number. All of the characters in this string will be ignored
by the parser when analyzing the number. The default value for SEPARADORES
is '_'

=item ACENTOS

Affects the way in which the generated string for the translated numbers is
given; if it is false, the textual representation will not have any
accented characters. The default value for this field is true (with
accents).

=item MAYUSCULAS

If this is a true value, the textual representation of the number will be
an uppercase character string. The default value for this field is false
(lowercase).

=item HTML

If this is a true value, the textual representation of the number will be a
HTML-valid string character (accents will be represented by their
respective HTML entities). The default value is 0 (text).

=item GENERO

The gender of the numbers can be $MALE, $FEMALE or $NEUTRAL, respectively for
femenine, masculine or neutral numbers. The default value is $MALE.

The following table shows the efect of GENDER on translation of Cardinal
and Ordinal numbers:

 +---+---------------------+-----------------------------+
 | N |     CARDINAL        |          ORDINAL            |
 | u +------+------+-------+---------+---------+---------+
 | m | MALE |$FEMALE|$NEUTRAL|  $MALE   |  $FEMALE | $NEUTRAL |
 +---+------+------+-------+---------+---------+---------+
 | 1 | uno  | una  | un    | primero | primera | primer  |
 | 2 | dos  | dos  | dos   | segundo | segunda | segundo |
 | 3 | tres | tres | tres  | tercero | tercera | tercer  |
 +---+------+------+-------+---------+---------+---------+

=item SEXO

Deprecated option only for backward compatibility, use GENERO instead.

=item UNMIL

This field affects only the translation of cardinal numbers. When it is a true
value, the number 1000 is translated to 'un mil' (one thousand), otherwise it
is translated to the more colloquial 'mil' (thousand). The default value is 1.

=item NEGATIVO

Contains the character string with the text to which the negative sign (-) will
be translated with. Defaults to 'menos'.

For example: default translation of -5 will yield "menos cinco".

=item POSITIVO

Contains the character string with the text to which the positive sign will be
translated with. Defaults to ''.

For example: default translation of 5 will yield "cinco".

=item FORMATO

A character string specifying how the decimals of a real number are to be 
translated. Its default value is 'con %2d ctms.' (see the B<real> method)

=back

=head3 Aliases

By popular demand I have added the following aliases for the options:

    Alias        Natural Name
    --------------------------
    ACCENTS       ACENTOS          
    UPPERCASE     MAYUSCULAS  
    SEPARATORS    SEPARADORES 
    GENDER        GENERO      
    POSITIVE      POSITIVO    
    NEGATIVE      NEGATIVO    
    FORMAT        FORMATO

=head2 cardinal

SYNOPSIS:
  $text = $obj->cardinal($num)

=head3 Parameters

=over 4

=item $num

the number.

=back

=head3 Description

Translates a cardinal number ($num) to spanish text, translation
is performed according to the following object ($obj) settings:
DECIMAL, SEPARADORES, SEXO, ACENTOS, MAYUSCULAS, POSITIVO and
NEGATIVO.

This method ignores any fraction part of the number ($num).

=head3 Return Value

Textual representation of the number as a string

=head2 real

SYNOPSIS:
  $text = real($n; $genf, $genm)

Translates the real number ($n) to spanish text.

The optional $genf and $genm parameters are used to specify gender of the
fraction part and fraction part magnitude in that order.  If $genf is missing
it will default to the GENDER option, and $genm will default to the $genf's
value.

This translation is affected by the options: DECIMAL, SEPARADORES, GENDER, 
ACENTOS, MAYUSCULAS, POSITIVO, NEGATIVO and FORMATO.

=head3 Fraction format (FORMATO)

FORMAT option is a formatting string like printf, it is used to format the
fractional part before appending it to the integer part. It has the following
format specifiers:

=over 4

=item %Ns

Formats the fractional part as text with precisión of N digits, for example:
number '124.345' formated with string 'CON %s.' will yield the text 'ciento
veinticuatro CON trescientas cuarenta y cinco milE<eacute>simas', and
formatted with string 'CON %2s.' will yield 'ciento veinticuatro CON treinta
y cuatro centE<eacute>simas'.

=item %Nd

Formats the fractional part as a number (no translation), with precision
of N digits, veri similar to sprintf's %d format, for example: number 
'124.045' formated with 'CON %2d ctms.' will yield: 'ciento veinticuatro
CON 04 ctms.'

=back

=head2 ordinal

SYNOPSIS:
  $text = $obj->ordinal($num)

=head3 Parameters

=over 4

=item $num

the number.

=back

=head3 Description

Translates an ordinal number ($num) to spanish text, translation
is performed according to the following object ($obj) settings:
DECIMAL, SEPARADORES, GENERO, ACENTOS, MAYUSCULAS, POSITIVO and
NEGATIVO.

This method croacks if $num <= 0 and carps if $num has a fractional
part.

=head3 Return Value

Textual representation of the number as a string

=head2 Accessors

Each of the options has a setter/getter with the name of the option in
lowercase, all the accessors have the following sintax:

=head3 Getters

  $obj->name_of_option()

Returns the current value of the option.

=head3 Setters

  $obj->name_of_option( $value )

Sets the option to $value and returns $obj

=head3 List of accessors

  $obj->accents
  $obj->acentos          
  $obj->uppercase
  $obj->mayusculas  
  $obj->unmil
  $obj->html
  $obj->decimal
  $obj->separators
  $obj->separadores 
  $obj->gender
  $obj->genero      
  $obj->positive
  $obj->positivo    
  $obj->negative
  $obj->negativo    
  $obj->format
  $obj->formato

=head1 INTERNALS

Functions in this secction are generally not used, but are docummented
here for completeness.

This is not part of the module's API and is subject to change.

=head2 CARDINAL SUPPORT

Construction of cardinal numbers

=head3 cardinal_e2

=over 4

=item SYNOPSIS

  cardinal_e2($n, $nn)

=item PARAMETERS

=over 4

=item $n

the number.

=item $nn

word stack.

=back

=item DESCRIPTION

This procedure takes $n (an integer in the range [0 .. 99], not verified) and
adds the numbers text translation to $nn (a word stack), on a word by word basis.
If $n == 0 nothing is pushed into $nn.

=back

=head3 cardinal_e3

=over 4

=item SYNOPSIS

  cardinal_e3($n, $nn)

=item PARAMETERS

=over 4

=item $n

the number.

=item $nn

word stack.

=back

=item DESCRIPTION

This procedure takes $n (an integer in the range [0 .. 99], not verified) and
adds the numbers text translation to $nn (a word stack), on a word by word basis.
If $n == 0 nothing is pushed into $nn.

=back

=head3 cardinal_e6

=over 4

=item SYNOPSIS

  cardinal_e6($n, $nn, $mag, $un_mil, $postfix)

=item PARAMETERS

=over 4

=item $n

the number.

=item $nn

word stack.

=item $mag

magnitude of the number 1 for millions, 2 for billions, etc.

=item $un_mil

if true 1000 is translated as "un mil" otherwise "mil"

=item $postfix

array representing plural & singular magnitude of the number, in this
order.

=back

=item DESCRIPTION

This procedure takes $n, and pushes the numbers text translation into $nn,
on a word by word basis, with the proper translated magnitude.  If $n == 0
nothing is pushed into $nn.

=back

=head3 cardinal_generic

=over 4

=item SYNOPSIS

  cardinal_generic($n, $exp, $fmag, $gen)

=item PARAMETERS

=over 4

=item $n

the number.

=item $exp

exponent.

=item $fmag

closure to format the 6 digits groups.

=item $gen

gender of the magnitude (optional defaults to $NEUTRAL):
    $FEMALE  for female gender (1 -> una).
    $MALE    for male gender (1 -> uno).
    $NEUTRAL for neutral gender (1 -> un).

=back

=item DESCRIPTION

This function translate the natural number $n to spanish words, adding
gender where needed.

=item RETURN VALUE

Translation of $n to spanish text as a list of words.

=back

=head3 cardinal_simple

=over 4

=item SYNOPSIS

  cardinal_simple($n, $exp, $un_mil; $gen)

=item PARAMETERS

=over 4

=item $n

the number.

=item $exp

exponent.

=item $un_mil

if true 1000 is translated as "un mil" otherwise "mil"

=item $gen

gender of the magnitude (optional defaults to $NEUTRAL):
    $FEMALE  for female gender (1 -> una).
    $MALE    for male gender (1 -> uno).
    $NEUTRAL for neutral gender (1 -> un).

=back

=item DESCRIPTION

This function translate the natural number $n to spanish words, adding 
gender where needed.

This procedure just builds a closure with format information, to call
cardinal_e6, and then calls cardinal_generic to do the work.

=item RETURN VALUE

Translation of $n to spanish text as a list of words.

=back

=head3 fraccion_mag_prefix

=over 4

=item SYNOPSIS

  fraccion_mag_prefix($mag, $gp)

=item PARAMETERS

=over 4

=item $n

the number.

=item $exp

exponent.

=item $mag

magnitude of the number 1 for millionths, 2 for billionths, etc.

=item $gp

gender and plural of the number, is the concatenation of gender and plural
gender must be one of $FEMALE, $MALE or $NEUTRAL, and plural must be '' for
singular and 's' for plural.

Note that $NEUTRAL + plural is a nonsense.

=item $ngen

gender of the number (same values as $gen).

=back

=item DESCRIPTION

This function returns the name of the magnitude of a fraction, $mag 
is the number of decimal digits. For example 0.001 has $mag == 3 and 
translates to "milesimos" if $gp is ($MALE . 's').

=item RETURN VALUE

Translation of $n to spanish text as a string.

=back

=head3 fraccion_simple

=over 4

=item SYNOPSIS

  fraccion_simple($n, $exp, $un_mil, $gen; $ngen)

=item PARAMETERS

=over 4

=item $n

the number.

=item $exp

exponent.

=item $un_mil

if true 1000 is translated as "un mil" otherwise "mil"

=item $gen

gender of the magnitude (optional defaults to $NEUTRAL):
    $FEMALE  for female gender (1 -> primera).
    $MALE    for male gender (1 -> primero).
    $NEUTRAL for neutral gender (1 -> primer).

=item $ngen

gender of the number (same values as $gen).

=back

=item DESCRIPTION

This function translate the fraction $n to spanish words, adding 
gender where needed.

This procedure just builds a closure with format information, to call
cardinal_e6, and then calls cardinal_generic to do the work.

=item RETURN VALUE

Translation of $n to spanish text as a list of words.

=back

=head2 ORDINAL SUPPORT

Construction of ordinal numbers

=head3 ordinal_e2

=over 4

=item SYNOPSIS

  ordinal_e2($n, $nn)

=item PARAMETERS

=over 4

=item $n

the number.

=item $nn

word stack.

=back

=item DESCRIPTION

This procedure takes $n (an integer in the range [0 .. 99], not verified) and
adds the numbers text translation to $nn (a word stack), on a word by word basis.
If $n == 0 nothing is pushed into $nn.

=back

=head3 ordinal_e3

=over 4

=item SYNOPSIS

  ordinal_e3($n, $nn)

=item Parameters

=over 4

=item $n

the number.

=item $nn

word stack.

=back

=item DESCRIPTION

This procedure takes $n (an integer in the range [0 .. 999], not verified) and
adds the numbers text translation to $nn (a word stack), on a word by word basis.
If $n == 0 nothing is pushed into $nn.

=back

=head3 ordinal_e6

=over 4

=item SYNOPSIS

  ordinal_e6($n, $nn, $mag, $un_mil, $postfix)

=item PARAMETERS

=over 4

=item $n

the number.

=item $nn

word stack.

=item $mag

magnitude of the number 1 for millions, 2 for billions, etc.

=back

=item DESCRIPTION

This procedure takes $n, and pushes the numbers text translation into $nn,
on a word by word basis, with the proper translated magnitude.  If $n == 0
nothing is pushed into $nn.

=back

=head3 ordinal_simple

=over 4

=item SYNOPSIS

  ordinal_simple($n, $exp; $gen)

=item PARAMETERS

=over 4

=item $n

the number.

=item $exp

exponent.

=item $un_mil

if true 1000 is translated as "un mil" otherwise "mil"

=item $gen

gender of the magnitude (optional defaults to $NEUTRAL):
    $FEMALE  for female gender (1 -> primera).
    $MALE    for male gender (1 -> primero).
    $NEUTRAL for neutral gender (1 -> primer).

=back

=item DESCRIPTION

This function translate the fraction $n to spanish words, adding 
gender where needed.

This procedure just builds a closure with format information, to call
ordinal_e6, and then calls ordinal_generic to do the work.

=item RETURN VALUE

Translation of $n to spanish text as a list of words.

=back

=head2 MISCELANEOUS

Everithing not fitting elsewere


=head3 parse_num

=over 4

=item SYNOPSIS

  parse_num($num, $dec, $sep)

Decomposes the number in its constitutive parts, and returns them in a list:

   use Lingua::SPA::Numeros;
   ($sgn, $ent, $frc, $exp) = parse_num('123.45e10', '.', '",');

=item PARAMETERS

=over 4

=item $num

the number to decompose

=item $dec

decimal separator (tipically ',' or '.').

=item $sep

separator characters ignored by the parser, usually to mark thousands, millions, etc..

=back

=item RETURN VALUE

This function parses a general number and returns a list of 4 
elements:

=over 4

=item $sgn

sign of the number: -1 if negative, 1 otherwise

=item $int

integer part of the number

=item $frc

decimal (fraction) part of the number

=item $exp

exponent of the number

=back

Croaks if there is a syntax error.

=back

=head3 retval

=over 4

=item SYNOPSIS

  $obj->retval($value)

=item DESCRIPTION

Utility method to adjust return values, transforms text 
following the options: ACENTOS, MAYUSCULAS y HTML.

Returns the adjusted $value.

=back


=head1 DEPENDENCIES

Perl 5.006, Exporter, Carp

=head1 SEE ALSO

http://roble.pntic.mec.es/~msanto1/ortografia/numeros.htm

=head1 AUTHOR

Jose Rey, <jrey@cpan.org>

Maintenance
PetaMem s.r.o., <info@petamem.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2009 by Jose Rey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

# }}}
