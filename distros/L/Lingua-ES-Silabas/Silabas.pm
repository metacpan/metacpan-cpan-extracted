package Lingua::ES::Silabas;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(silabas);

our $VERSION = '0.01';

######################################################################

# grupos conson·nticos 
my @GC = qw(
               bl br
            ch cl cr
	       dl dr
	       fl fr
	       gl gr
	       ll
	       pl pr
		  rr
	       tl tr
	   );

my $VA  = '·ÈÌÛ˙¡…Õ”⁄';   # vocales acentuadas
my $VD  = '[iu¸‹]';   # vocales dÈbiles 
my $VF  = "[aeo$VA]";  # vocales fuertes
my $V   = "(?:$VD|$VF)";  # vocales
my $C   = '[b-df-hj-np-tv-zÒ—]';  # consonantes
my $CoGC = '(?:'. join('|', @GC) ."|$C)";  # consonantes y grupos conson·nticos

my $dipt = "(?:${VD}h?$VF|${VF}h?$VD|$V$V)";  # diptongos
my $tript = "(?:$V$V$V)";  # triptongos

sub silabas ($) {
    my $palabra = shift;
    my @silabas;

    while ($palabra) {

        if ($palabra =~ /^($C*?(?:$tript|$dipt|$V)$C{0,2}?)$CoGC$V/io) {
            push @silabas, $1;
            substr $palabra, 0, $+[1], '';
        } else {
            push @silabas, $palabra;
            undef $palabra;
        }

    }

    # hiatos
    @silabas = map {
                   !/(.*?$VF$VD?)(?(?=$VF$VF)($VF))($VF.*)/sio ? $_         :
		                                            $2 ? ($1,$2,$3) :
							         ($1,$3)
		   } @silabas;

    return @silabas;
}

1;

__END__

=head1 NOMBRE

Lingua::ES::Silabas - Divide una palabra en sE<iacute>labas

=head1 SINOPSIS

  use Lingua::ES::Silabas;

  $palabra = 'externocleidomastoideo'; # muchas silabas ;-)

  ## en contexto de lista,
  ## lista de silabas que componen la palabra
  @silabas = silabas($palabra);

  ## en contexto escalar,
  ## el numero de silabas que componen la palabra
  $num_silabas = silabas($palabra);

=head1 DESCRIPCION

Lingua::ES::Silabas::silabas() recibe como argumento una palabra y regresa 
una lista con las sE<iacute>labas que la forman.

=head1 BUGS

Probablemente existan errores en el cE<oacute>digo, o en las reglas que
se utilizan para separar las palabras en sE<iacute>labas, por lo que
las correcciones serE<aacute>n bienvenidas.

=head1 AUTOR

Marco Antonio Valenzuela EscE<aacute>rcega, E<lt>marcos@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2002 Marco Antonio Valenzuela EscE<aacute>rcega

Este mE<oacute>dulo es software libre; puede ser distribuido y/o modificado
bajo los mismos tE<eacute>rminos que Perl.

=cut
