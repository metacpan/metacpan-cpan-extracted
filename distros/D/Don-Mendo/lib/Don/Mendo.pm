use lib qw( ../../lib ); # for syntax checking -*-CPerl-*-

package Don::Mendo;

use warnings;
use strict;
use Carp;

our $VERSION = "0.0.7";

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;

use Don::Mendo::Jornada;

# Module implementation here
sub new {
    my $class = shift;
    my $text = join("",<DATA>);
    $text =~ s/(\s+\d+\s+)//gs;
    my $self = { _text => $text };
    bless $self, $class;
    my @jornadas = split(/\s{39}\s+JORNADA/, $text );
    $self->{'_intro'} = $jornadas[0];

    for my $j( @jornadas[1..4] ) { #4 journeys only, first is intro
	my $esta_jornada = new Don::Mendo::Jornada ($j );
	push  @{$self->{'_jornadas'}}, $esta_jornada;
    }
    return $self;
	
}

sub text {
    my $self = shift;
    return $self->{'text'};
}

sub jornadas {
    my $self = shift;
    return $self->{'_jornadas'};
}

1; # Magic true value required at end of module


=encoding utf8

=head1 NAME


Don::Mendo - Modules for "La venganza de Don Mendo", Sir Mendo's revenge.

=head1 VERSION

This document describes Don::Mendo version 0.0.3. 

=head1 SYNOPSIS

    use Don::Mendo;
    my $don_mendo = new Don::Mendo;
    my $first_act = $don_mendo->jornadas->[0]; #Acts in the play are
				#"jornadas"
    $first_act->tell(); #Print the whole act
    my $lines_for_mendo = $first_act->lines_for_character('Mendo');
    #Just the lines for the main character
  
=head1 DESCRIPTION

A structured module for "La venganza de Don Mendo", by D. Pedro Muñoz
    Seca, a play written in 1918 and widely known and represented in
    Spain. The text was converted from a PDF found in
    L<www.juntadeandalucia.es/averroes/~04700442a/Mendo.pdf|Averroes
    Plan>.
It's old enough to be in the public domain, so I guess there's no
    problem here. 
 

=head1 INTERFACE 

=head2 new()

Parses the text and sets up journeys, characters, lines and
    everything. 

=head2 text()

Returns the whole text, in the original version

=head2 jornadas()

Returns an arrayref with the 4 journeys that constitute the play

=head1 DEPENDENCIES

Just the basic test and Carp modules

=head1 INCOMPATIBILITIES

This should be compatible with everything, up to and including
    Shakespeare, dada theater, and improv.


=head1 BUGS AND LIMITATIONS

It's not clear from the book if Don Mendo is beautiful or ugly as
    monkey's ass. You can wait for the next version of Don Mendo to
    fix this, but I wouldn't hold my breath.

Please report any bugs or feature requests to
C<bug-don-mendo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 Acknowledgements

	The author is grateful to the Madrid Perl Mongers, for having a
	look at the code and using it in their talks, specially Diego
	Kuperman and Joaquin Ferrero. 
	
=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut 

__DATA__
             Pedro MUÑOZ SECA


LA VENGANZA DE DON MENDO
           caricatura de tragedia

     en cuatro jornadas, original, escrita
          en verso, con algún ripio

            –––––––––––––––––––

    Estrenada en el Teatro de la Comedia, de Madrid,
          la noche del 20 de diciembre de 1918
                    PERSONAJES


                       Magdalena
                        Azofaifa
                     Doña Ramírez
                    Doña Berenguela
                        Marquesa
                        Duquesa
                         Raquel
                          Ester
                         Rezaida
                        Aljalamita
                          Ninón
                         Mencías
                       Don Mendo
                        Don Nuño
                        Moncada
                          Abad
                    Don Alfonso VII
                       Bertoldino
                         Froilán
                        Clodulfo
                         Girona
                        Don Lupo
                          León
                        Sigüenza
                        Manfredo
                         Marcial
                        Ali-Faféz
                        Don Juan
                        Don Lope
                         Don Gil
                        Lorenzana
                       Don Suero
                         Aldana
                        Don Cleto
                          Oliva
                        Don Tirso
Damas, pajes 1 y 2, heraldos 1 y 2, tamborilero, pifanero,
       frailes, escuderos, ballesteros y halconeros.




                            2
                                        JORNADA PRIMERA


         Sala de armas del castillo de don Nuño Manso de Jarama, Conde de Olmo. En el lateral derecha, primer
término, una puerta. En segundo término y en ochava, una enorme chimenea. En el foro, puertas y ventanales que
comunican con una terraza. En el lateral izquierda, primer término, el arranque de una galería abovedada. En último
término, otra puerta. Tapices, muebles riquísimos, armaduras, etc. Es de noche. Hermosos candelabros dan luz a la
estancia. En la chimenea, viva lumbre. La acción en las cercanías de León, allá en el siglo XII, durante el reinado de
Alfonso VII.


                                                                     Al levantarse el telón, están en escena el
                                                              CONDE NUÑO, MAGDALENA, su hija; DOÑA
                                                              RAMÍREZ, su dueña; DOÑA NINÓN, BERTOLDINO,
                                                              un joven juglar, LORENZANA, ALDANA, OLIVA,
                                                              varios escuderos y todas las mujeres que componen la
                                                              servidumbre del castillo, dos FRAILES y dos PAJES.
                                                              EL CONDE, en un gran sillón, cerca de la lumbre,
                                                              presidiendo el cotarro, y los demás formando artístico
                                                              grupo y escuchando a BERTOLDINO, que en el centro
                                                              de la escena está recitando una trova.


     NUÑO.– (A Bertoldino muy campanudamente.)
Ese canto, juglar, es un encanto.
Hame gustado desde su principio,
y es prodigioso que entre tanto canto
no exista ningún ripio


     MAGDALENA.– Verdad.


     NUÑO.– (A Bertoldino.) Seguid.


     BERTOLDINO.– (Inclinándose respetuoso.) Mandad.


     NUÑO.– (Enérgico a varios que cuchichean.) ¡Callad!


     BERTOLDINO.– Oid. (Se hace un gran silencio y recita enfáticamente.)
Los cuatro hermanos Quiñones
a la lucha se aprestaron,
y al correr de sus bridones,
como a cuatro exhalaciones,
hasta el castillo llegaron.


                                                          3
¡Ah del castillo! -Dijeron-.
¡Bajad presto ese rastrillo!
Callaron y nada oyeron,
sordos sin duda se hicieron
los infantes del castillo.
¡Tended el puente!... ¡Tendedlo!
Pues de no hacello, ¡pardiez!,
antes del primer destello
domaremos la altivez
de esa torre, habéis de vello...
Entonces los infanzones
contestaron: ¡Pobres locos!...
Para asaltar torreones,
cuatro Quiñones son pocos.
¡Hacen falta más Quiñones!
Cesad en vuestra aventura,
porque aventura es aquesta
que dura, porque perdura
el bodoque en mi ballesta...
Y a una señal, dispararon
los certeros ballesteros,
y de tal guisa atinaron,
que por el suelo rodaron
corceles y caballeros. (Murmullos de aprobación.)
Y según los cronicones
aquí termina la historia
de doña Aldonza Briones,
cuñada de los Quiñones
y prima de los Hontoria. (Nuevos murmullos.)


     NUÑO.– Esas estrofas magnánimas
son dignas del estro vuestro (Suena una campana.)


     BERTOLDINO.– Gracias, gran señor.


     NUÑO.– (Levantándose solemne.) ¡Las ánimas! (Todos se ponen en pie.)
Padre nuestro... (Se arrodilla y reza.)


     TODOS.– (Imitándole.) Padre nuestro... (Pausa. La campana, dentro, continúa un breve instante sonando
lastimosamente.)




                                                        4
     NUÑO.– Y ahora, deudos, retiraos,
que es tarde y no es ocasión
de veladas ni saraos.


Recibid mi bendición.
(Los bendice.)
Magdalena y vos, quedaos.
(Magdalena y doña Ramírez se inclinan y se colocan tras él, en tanto desfila ante el Conde toda la servidumbre.)
Adiós, mi fiel Lorenzana
y Guillena de Aragón...
Buenas noches, Pedro Aldana.
Descansad... Hasta mañana,
Luis de Oliva... Adiós, Ninón...
(Quedan en escena el Conde, Magdalena y doña Ramírez. Bueno, el Conde, que ya es anciano, es un tío capaz de
quitar, no digo el hipo, sino la hipocondria; Magdalena es una muchacha como de veinte años, de trenzas rubias, y
doña Ramírez una mujer como de cincuenta, algo bigotuda y tal.)
Ahora que estamos solos, oidme atentas.
Necesito que hablemos un instante
de algo para los dos muy importante.
(Magdalena toma asiento y el Conde la imita, diciéndola sin reproche.)
Me sentaré, puesto que tú te sientas.


     MAGDALENA.– Dime, padre y señor.


     NUÑO.– Digo, hija mía,
y al decirlo Dios sabe que lo siento,
que he concertado al fin tu casamiento,
cosa que no es ninguna tontería.
(Magdalena se estremece, casi pierde el sentido.)
¿Te inmutas?


     MAGDALENA.– (Reponiéndose y procurando sonreír.)
¡No, por Dios!


     NUÑO.– (Trágicamente escamado.) Pues parecióme.


     MAGDALENA.– No te extrañe que el rubor mi rostro queme;
de improviso cogióme
la noticia feliz... e impresionéme.


     NUÑO.– Has cumplido, si yo mal no recuerdo,
veinte abriles.


                                                          5
     MAGDALENA.– Exacto.


     NUÑO.– No eres lerda.
Pues toda la familia está de acuerdo
en que eres mi trasunto, y si yo soy cuerdo,
siendo tú mi trasunto, serás cuerda.
Eres bella... ¿Qué dije? Eres divina,
como lo fue tu madre doña Evina.


     MAGDALENA.– Gracias, padre y señor.


     NUÑO.– Modestia aparte.
Sabes latín, un poco de cocina,
e igual puedes dorar una lubina
que discutir de ciencias y aún de arte.
Tu dote es colosal, cual mi fortuna,
y es tan alta tu cuna,
es nuestra estirpe de tan alta rama,
que esto grabé en mi torre de Porcuna:
«La cuna de los Manso de Jarama,
a fuerza de ser alta cual ninguna,
más que una cuna dijérase que es cama.»


     MAGDALENA.– (Atajándole nerviosamente.)
¿Y con quién mi boda, padre, has concertado?


     NUÑO.– Con un caballero gentil y educado
que es Duque y privado del Rey mi señor.


     MAGDALENA.– ¿El Duque de Toro?...


     NUÑO.– Lo has adivinado,
El Duque de Toro, don Pero Collado,
que ha querido hacernos con su amor, honor.


     MAGDALENA.– ¿Y te habló con Pero?...


     NUÑO.– Y don Pero hablóme
y afable y rendido tu mano pidióme,
y yo que era suya al fin contestelle;
y é agradecido besóme, abrazome,


                                                6
y al ver el agrado con que yo mirelle
en la mano diestra cuatro besos dióme;
y luego me dijo con voz embargada:
Dígale, don Nuño, que presto mi espada
rendiré ante ella, que presto iré a vella,
que presto la boda será celebrada
para que termine presto mi querella... (Levantándose.)
Conque, Magdalena, tu suerte está echada,
mi palabra dada y mi honor en ella;
serás muy en breve duquesa y privada;
no puedes quejarte de tu buena estrella.


     MAGDALENA.– Gracias, padre, gracias.


     NUÑO.– Noto tu alegría.


     MAGDALENA.– Haré lo que ordenas.


     NUÑO.– De tu amor lo espero.


     MAGDALENA.– Puesto que lo quieres, seré de don Pero.


     NUÑO.– Serás de don Pero. (La besa.)
Adiós, hija mía. (Se va por la puerta de la derecha.)


     MAGDALENA.– (Aterrada, dejándose caer sin fuerzas en una silla, digo sin fuerzas, porque si se deja caer con
fuerza puede hacerse daño.) ¡Ya escuchaste lo que dijo;...


     RAMÍREZ.– Claro está que escuché,
y sólo a fuerza de fuerzas
me he podido contener,
que tal temblor dio a mi cuerpo,
tal hormiguillo a mis pies,
que no sé cómo don Nuño
no lo advirtió, no lo sé.
¡Casarte tú con el Duque
siendo amante del Marqués!...
¡Ser esposa de don Pero
la que de don Mendo es!...
¡Si el marqués lo sabe!...


     MAGDALENA.– ¡Calla!


                                                             7
     RAMÍREZ.– ¡Si el Duque se entera!...


     MAGDALENA.– ¡Bien!


     RAMÍREZ.– ¡Si al conde le dicen!...


     MAGDALENA.– ¡Cielos!


     RAMÍREZ.– ¡Y si tú lo ocultas!...


     MAGDALENA.– (Nerviosa, cargada.) ¡Eh!
¡Basta ya, doña Ramírez!
¿No ves cómo sufro? ¡Rediez!


     RAMÍREZ.– Muda seré si lo ordenas.
Si lo mandas, callaré;
pero ante Dios sólo puedes
casarte con el Marqués,
porque al Marqués entregaste
tu voluntad y tu fe;
porque te pasas las noches
en tierno idilio con él;
porque esa escala maldita
le arrojastes una vez
sólo por darle una mano
y él se ha tomado los pies. (A un gesto de Magdalena.)
No te ofendas, Magdalena,
mas yo sé, porque lo sé,
que la mujer que recibe
en su castillo a un doncel,
con él se casa, o no tiene
todo lo que hay que tener.


     MAGDALENA.– Me insultas, doña Ramírez.
No sé cómo en mi altivez
me contengo.


     RAMÍREZ.– Reflexiona
que lo digo por tu bien.




                                                         8
     MAGDALENA.– ¡Pero si ya no le amo;
si ya no tengo en él fe;
si es de mi padre enemigo!
¡Si no sé por qué le amé!


     RAMÍREZ.– Él te idolatra.


     MAGDALENA.– ¿Qué importa?
¿Qué puedo esperar de él,
si carece de fortuna
y no es amigo del Rey?
No, doña Ramírez, nunca:
no me conviene el Marqués.
Quiero triunfar en la corte,
quiero brillar, quiero ser
algo que mucho ambiciono.
¡Quiero serlo y lo seré!


     RAMÍREZ.– ¿Pero y don Mendo, señora?


     MAGDALENA.– Yo sabré librarme de él.


     RAMÍREZ.– ¿Y si don Pero se entera
de aqueste engaño?


     MAGDALENA.– ¿Por quién?


     RAMÍREZ.– ¿Y si don Nuño?...


     MAGDALENA.– Mi padre
dio su palabra anteayer
al de Toro, y yo por fuerza
le tengo que obedecer. (Suena dentro un laúd que toca el conocido cuplé de El Relicario.)


     RAMÍREZ.– Entonces...


     MAGDALENA.– ¡Calla! (Escucha.)


     RAMÍREZ.– ¡Dios mío!
¡Esa música!...




                                                          9
     MAGDALENA.– ¡El marqués!
Arroja presto la escala.
Déjame a solas con él. (Se sienta pensativa. Doña Ramírez abre una de las puertas del foro, se asoma a la terraza y
arroja una escala.)
Quisiera amarle y no puedo.
Fue mi amor una mentira,
porque no es amor, es miedo
lo que don Mendo me inspira.


     RAMÍREZ.– (Haciendo mutis por la galería de la izquierda.)
Pues lo mandan, es razón
que sea muda, ciega y sorda,
pero me da el corazón
que aquí se va a armar la gorda. (Vase. Por la puerta del foro que deja abierta doña Ramírez, entra en escena don
Mendo, apuesto caballero como de treinta años, bien vestido y mejor armado.)


     MAGDALENA.– (Yendo hacia él y cayendo en sus brazos.) ¡Don Mendo!


     MENDO.– (Declamando tristemente.) ¡Magdalena!
Hoy no vengo a tu lado
cual otras noches, loco, apasionado...
porque hoy traigo una pena
que a mi pecho destroza, Magdalena.


     MAGDALENA.– ¿Tú triste? ¿Tú apenado? ¿Tú sufriendo?
¿Pero qué estoy oyendo?
Relátame tus cuitas, ¡oh, don Mendo! (Ofreciéndole una dura banqueta, bastante incómoda.)
Acomódate aquí.


     MENDO.– Preferiría
aquél, de cuero, blando catrecillo,
pues del arzón, sin duda, vida mía,
tengo no sé si un grano o un barrillo.


     MAGDALENA.– ¡Y has venido sufriendo!


     MENDO.– ¡Mucho!... ¡Mucho!


     MAGDALENA.– ¿Cómo no quieres, di, que te idolatre?
Apóyate en mi brazo, ocupa el catre
y cuéntame tu mal, que ya te escucho. (Ocupa don Mendo un catrecillo de cuero y Magdalena se arrodilla a su lado.
Pausa.)


                                                          10
Ha un rato que te espero, Mendo amado,
¿por qué restas callado?


      MENDO.– No resto, no; es que lucho,
pero ya ya mi mutismo ha terminado;
vine a desembuchar y desembucho.
Voy a contarte, amor mío,
la historia de una velada
en el castillo sombrío
del Marqués de Moncada.
Ayer... ¡triste día el de ayer!...
Antes del anochecer
y en mi alazán caballero
iba yo con mi escudero
por el parque de Alcover,
cuando cerca de la cerca
que pone fin a la aberca
de los predios de Albornoz,
me llamó en alto una voz,
una voz que insistió terca.
Hice en seco una parada,
volví el rostro, y la voz era
del Marqués de Moncada,
que con otro camarada
estaba al pie de una higuera.


      MAGDALENA.– ¿Quién era el otro?


      MENDO.– El Barón
de Vedia, un aragonés
antipático y zumbón
que está en casa del Marqués
de huésped o de gorrón.
Hablamos... ¿Y vos qué haceis?
Aburrirme... Y el de Vedia
dijo: No os aburriréis;
os propongo, si queréis,
jugar a las siete y media.


      MAGDALENA.– ¿Y por qué marcó esa hora
tan rara? Pudo ser luego...



                                              11
     MENDO.– Es que tu inocencia ignora
que a más de una hora, señora,
las siete media es un juego.


     MAGDALENA.– ¿Un juego?


     MENDO.– Y un juego vil
que no hay que jugarlo a ciegas,
pues juegas cien veces, mil,
y de las mil, ves febril
que o te pasas o no llegas.
Y el no llegar da dolor,
pues indica que mal tasas
y eres del otro deudor.
Mas ¡ay de ti si te pasas!
¡Si te pasas es peor!


     MAGDALENA.– ¿Y tú... don Mendo?


     MENDO.– ¡Serena
escúchame, Magdalena,
porque no fui yo... no fui!
Fue el maldito cariñena
que se apoderó de mí.
Entre un vaso y otro vaso
el Barón las cartas dio;
yo vi un cinco, y dije «paso»,
el Marqués creyó otro el caso,
pidió carta... y se pasó.
El Barón dijo «plantado»;
el corazón me dio un brinco;
descubrió el naipe tapado
y era un seis, el mío era un cinco;
el Barón había ganado.
Otra y otra vez jugué,
pero nada conseguí,
quince veces me pasé,
y una vez que me planté
volví mi naipe... y perdí.
Ya mi peculio en un brete
al fin me da Vedia un siete;
le pido naipe al de Vedia,


                                          12
y Vedia me pone una media
sobre el mugriento tapete.
Mas otro siete él tenía
y también naipe pidió...
y negra suerte la mía,
que siete y media cantó
y me ganó en la porfía...
Mil dineros se llevó,
¡por vida de Satanás!
Y más tarde... ¡qué sé yo!
de boquilla se jugó,
y se ganó diez mil más.
¿Te haces cargo, di, amor mío?
¿Te haces cargo de mis males?
¿Ves ya por qué no sonrío?
¿Comprendes por qué este río
brota de mis lagrimales? (Se seca una lágrima de cada ojo.)
Yo mal no quedo, ¡no quedo!
¡Quién diga que yo un borrón
eché a mi grey que alce el dedo!...
Y como pagar no puedo
los dineros al Barón,
para acabar de sufrir
he decidido... partir
a otras tierras, a otro abrigo.


     MAGDALENA.– (Ocultando su alegría.)
¿Qué me dices?... ¿Vas a huir?


     MENDO.– Voy a huir, pero contigo.


     MAGDALENA.– ¿Perdiste el juicio?


     MENDO.– No tal.
Resuelto está, vive Dios.
Y si te parece mal,
aquí mesmo, este puñal (Saca un puñal enorme.)
nos dará muerte a los dos.
Primero lo hundiré en ti,
y te daré muerte, sí,
¡lo juro por Belcebú!



                                                         13
y luego tú misma, tú,
hundes el acero en mí.


        MAGDALENA.– (Ocultando su miedo.)
Es que tú puedes pagar
con algo... que alguien te preste...
y luego para medrar
puedes partir con la hueste
que organiza el del Melgar.
Y yo aquí te aguardaría
y al Conde prepararía,
y al volver de tu cruzada
nuestra unión sancionaría.


        MENDO.– ¡Calla!


        MAGDALENA.– ¡Sí!... ¿Qué piensas?


        MENDO.– ¡Nada!


        MAGDALENA.– ¡Salvado, don Mendo, estás!
Pagas las deudas, te vas,
luchas, vences y al regreso
loca de amor me hallarás
aquí.


        MENDO.– ¡Nunca!... ¡Nunca!...


        MAGDALENA.– ¿Y eso?


        MENDO.– Porque... ¿cómo a pagar voy?


        MAGDALENA.– ¿Cómo? (Se dirige a un mueble y saca un estuche de orfebrería.)
Si ya tuya soy
y lo mío tuyo es... (Le da el estuche.)
este collar que te doy
has de aceptarlo, Marqués.


        MENDO.– ¡Dios santo!


        MAGDALENA.– Ve mi intención,
de rodillas te lo ruego,


                                                        14
véndelo, paga al Barón,
tu honor salva, y parte luego
a unirte al rey de Aragón.


     MENDO.– (Dudando.) Es que...


     MAGDALENA.– Todo está arreglado.


     MENDO.– Pero mi honor...


     MAGDALENA.– No comprendo...


     MENDO.– Temo que algún deslenguado
lo sepa, y diga: don Mendo
es un vil y un deshaogado,
que se pizca de aprensión
aprovechó la ocasión
que él creyó propcia y obvia
y pagó a cierto Barón
con alhajas de su novia.
Y me anulo y me atribulo
y mi horror no dismulo,
pues aunque el nombre te asombre
quien obra así tiene un nombre,
y ese nombre es el de... chulo.


     MAGDALENA.– ¡Basta, don Mendo!


     MENDO.– ¡No!... ¡No!


     MAGDALENA.– (Trágica.) ¡O aceptas ese collar
que mi mano te donó,
o tú no me has de matar,
pues he de matarme yo! (Ruido de espadas que chocan entre sí.)


     MENDO.– ¡Calla!


     MAGDALENA.– ¿Qué es eso?... ¡Dios santo!...


     MENDO.– Al pie de este torreón
alguien riñe con tesón...



                                                        15
     RAMÍREZ.– (Entrando en escena asustadísima.)
¡Ay, Magdalena! ¡Qué espanto!...


     MENDO.– ¿Qué ocurre?


     RAMÍREZ.– (A Magdalena.) ¡Salva tu honor!
Un rufián o un caballero
a vuestro fiel escudero
ha puesto en fuga.


     MAGDALENA.– ¡Qué horror!


     RAMÍREZ.– ¡Y diciendo no se qué,
por la escala está subiendo!


     MAGDALENA.– ¡Tú tienes mi honor, don Mendo!


     MENDO.– Pues ten en mi espada fe.
Y de ese honor al conjuro,
juro que morir prefiero
a delatarte, lo juro
por mi fe de caballero (Se van por la izquierda doña Ramírez y Magdalena. Pausa. Don Mendo desenvaina su espada y
se emboza.)
¡Por vida!... Si hay que luchar
y luchar habrá, si hay quien luche
puede estorbarme el estuche...
el estuche del collar. (Arroja el estuche al suelo y se cuelga el collar del brazo.) (Por el fondo, y también embozado,
entra don Pero, por una de las ventanas, y se detiene al ver a don Mendo.)
¿Quién se acerca inoportuno?


     PERO.– ¡Uno!


     MENDO.– ¿Sabe qué suerte le cabe?


     PERO.– ¡Qué sabe! (Saca la espada.)


     MENDO.– ¿Y qué le impulsó a subir?


     PERO.– ¡Reñir!


     MENDO.– ¿Dijo reñir o morir?



                                                            16
     PERO.– Reñir y matar si cabe,
que entró por ese arquitrabe
uno que sabe reñir.


     MENDO.–Morirás, ¡rayos y truenos!


     PERO.– ¡Menos!


     MENDO.– Que mi espada vidas roba.


     PERO.– ¡Coba!


     MENDO.– ¿Eres juglar o escudero?


     PERO.– ¡Caballero!


     MENDO.– Entonces con más esmero.


     PERO.– Pues entonces presto a reñir,
que no os tenga que decir
menos coba, caballero.


     MENDO.– decid cuál es vuestro nombre.


     PERO.– ¿Mi nombre queréis? ¡Pardiez!
Pues... un hombre.




     MENDO.– ¿Solo un hombre?


     PERO.– Uno que vale por diez.


     MENDO.– ¡Vive el cielo!... ¡Venga el duelo!...


     PERO.– ¡Vive Dios!... ¡Aunque sean dos!...


     MENDO.– Habéis de medir el suelo.


     PERO.– Habéis de medirlo vos.


     MENDO.– ¡Por mi dama! ¡Vive el cielo!...



                                                      17
     PERO.– ¡Por mi dama! ¡Vive Dios!... (Cruzan las espadas y se acometen fieramente. Dentro gritan pidiendo
socorro Magdalena y doña Ramírez.)


     MENDO.– (Haciendo alto y mirando hacia ambos laterales temerosamente.)
(Voces, ayes, luces, ruido...
si me ven, está perdida
y yo con ella perdido...
Hay que buscar la salida...)
¡Paso franco!


     PERO.– (Gritando.) ¡Ah de la casa!


     MENDO.– ¡Paso!


     PERO.– Lo impide mi acero.


     MENDO.– ¡Paso digo, caballero!


     PERO.– Yo digo que no se pasa.


     MENDO.– ¡Por favor!...


     PERO.– ¡No hay compasión!
No salís, lo he decidido.


     MENDO.– (Desesperado.) (¡Y si vienen!... ¡Sí! ¡Estoy perdido!)
¡Paso!


     PERO.– ¡Nunca!


     MENDO.– ¡Maldición! (Se emboza y queda con la espada desnuda en el centro de la escena. En el foro, también
embozado y espadi-desnudo, queda don Pero. Preo las distintas puertas y galerías entran todos los personajes que
había en escena al comenzar el acto. Vienen muchos de ellos con armas y otros con hachones encendidos. Magdalena
se presenta con el pelo suelto, como si se acabara de levantar, y sostenida por doña Ramírez.)


     LORENZANA.– ¿Quién llama?


     ALDANA.– ¿Quién grita?


     OLIVA.– ¿Qué ocurre?


     NINÓN.– ¡Dios Santo!


                                                          18
     BERTOLDINO.– ¿Qué es esto?
¡Dos hombres
espadas en mano!...


     LORENZANA.– ¡Dos hombres!...


     RAMÍREZ.– ¡Qué espanto!


     NINÓN.– ¡Qué miedo!


     MAGDALENA.– ¡Qué horror!


     BERTOLDINO.– (Por don Nuño.) ¡El Conde!


     NUÑO.– (Entrando en escena on la espada desnuda.)
¡Silencio!
¡Atrás todo el mundo!
Qué sólo a mí me toca
defender mi honor. (Avanzando sublime.)
Aunque anciano, matar a los dos puedo,
que cuando empuño la tajante espada,
ni nadie supo resistir, ni nada
logró borrar la máxima sagrada
que hice grabar en su hoja de Toledo.
«Viva mi dueño», dice como un grito.
«Viva su madre», añádase en el puño;
y yo ambos gritos con valor repito,
que está para cumplir lo en ella escrito
el brazo de granito de don Nuño.
¡Presto!... ¡Fuera el embozo!... ¡Presto fuera!
¡Explicar por qué estáis en mi castillo!...
¿Quién sois? ¿A qué venís?


     PERO.– (Desembozándose y avanzando un paso altaneramente.) Es muy sencillo.


     TODOS.– ¡El de Toro!


     NUÑO.– ¡Gran Dios!


     MAGDALENA.– (A doña Ramírez.) ¡El Duque era!



                                                     19
     NUÑO.– Un rayo que a mis plantas cayese de la altura...
un sol que a media noche luciera en la negrura...
un cuervo que trocase su negror en albura...
extrañáranme menos que esta loca aventura.
¡El de Toro en mi casa de tan rara manera!...
Ocultas por el manto de faz y la cimera...
con la espada desnuda y la voz altanera...
violando mi castillo, mi honor y mi bandera.


     PERO.– Tu honor, nunca, don Nuño, porque tu honor es mío,
y por serlo, don Nuño, vine a tu señorío,
y te juro, don Nuño, que no vine en baldío.


     NUÑO.– No entiendo.


     PERO.– Pues yo mesmo te explicaré este lío.
Al despuntar el día,
y en unión de mi paje Ginesillo,
dejé la Corte y vine a tu castillo,
para ver a su dueña, y dueña mía,
cuya regia hermosura me enamora.
Llegué de noche, más llegué en buena hora,
porque cuando a llamar me disponía
vi una escala de cuerda que pendía
de esa terraza, y que a sus pies estaba
un hombre que a la escala defendía.
Quise saber lo que aquel hombre hacía
y quién era el doncel que aquí se hallaba,
y a quién la escala, ¡vive Dios!, servía
y qué mano la echaba
y qué mano la recogía.
Que ya que aquí moraba
la dama que el amor me destinaba,
era muy justo hacer lo que pensaba
y muy justo saber lo que quería.
Puse en fuga al follón que me estorbaba,
subí y entré, y en esta estancia había
un hombre, y cuando yo con él reñía
llegasteis... y eso es todo. Agora espero
que e digáis con claridad del día
qué aguarda y qué hace aquí tal caballero.



                                                         20
     NUÑO.– (A don Mendo.) ¡Hablad! (Don Mendo ni le mira.) ¿Calla?... (Terriblemente.) ¡¡Magdalena!!


     MAGDALENA.– ¡Padre! ¿Qué piensas de mí?


     NUÑO.– ¿Eres inocente?


     MAGDALENA.– (Con grandísima energía.) ¡¡Sí!!
¡Pura como la azucena!...
Tú mesmo has de verlo aquí,
en mis ojos, clara luna,
de donde tú siempre lees.


     NUÑO.– (Amenazador.) Entonces... voy a armar una
de las que no te menees. (Muy enérgico.)
¡A ver, pronto! ¿Quién la escala
a ese embozado arrojó?


     MENDO.- Yo mesmo.


     NUÑO.- ¿Qué dices?


     MENDO.– ¡Yo!


     NUÑO.– No es posible.


     MENDO.– Nadie iguala
mi destreza en el trepar
para una torre invadir.
Excusaos de preguntar:
yo la eché para bajar,
no la usé para subir.
Por las grietas del torreón
trepé cual raposa,
que eso en mí, Conde, no es cosa
que llame ya la atención;
pero como en el descenso
suele más peligro haber,
y yo cuando subo, pienso
que tengo que descender,
llevo siempre a previsión
una escala de garduño,



                                                        21
y esa es la escala, don Nuño,
que pende del torreón.


     NUÑO.– ¿Y a qué subisteis?


     MENDO.– Señor...


     NUÑO.– No acabo de imaginar.
¿Fue el amor?


     MENDO.– No fue el amor.


     NUÑO.– Entonces...


     MENDO.– Subí a robar. (Asombro en todos.)


     NUÑO.– ¡Miserable!... ¡Presto, a él!...


     MENDO.– ¡Quietos!... ¡Infeliz de aquel
que intentare, ay Dios, llegar
a don Mendo Salazar
y Bernáldez de Montiel! (Se desemboza.)


     NUÑO.– ¿Ladrón vos, don Mendo? ¿Vos?


     RAMÍREZ.– (Aparte a Magdalena.) Por salvarnos a las dos
ya ves, su infortunio labra.


     MENDO.– (De salvarla di palabra,
y la cumplo, vive Dios.)


     NUÑO.– Un Marqués cual vos, ¡qué afrenta!
¿Cuándo vióse acción tan doble?


     MENDO.– Nunca ha de faltar un noble
que robe más de la cuenta.


     NUÑO.– ¿Pero vos?...


     MENDO.– Y a fuer de honrado,
antes de rendir la espada
que mi delito ha manchado


                                                      22
quiero confesar, que nada
de amora hame aquí arrastrado.


     PERO.– ¡No! ¡No!... ¡Nunca lo creeré!


     LORENZANA.– Ni yo.


     MAGDALENA.– ¿Qué decís?


     PERO.– ¡No sé!
Permitid que en creerlo luche.


     MAGDALENA.– (Recogiendo del suelo el estuche que tiró don Mendo.) Mirad... hay aquí un estuche.


     NUÑO.– El de tu collar.


     MAGDALENA.– ¡Sí!


     PERO.- ¿Eh?


     MENDO.– Como tan poco valía
no lo quise para mí.


     PERO.– ¿Pero y el collar?


     MENDO.– (Enseñándolo.) ¡Aquí!


     PERO.– ¡Es verdad!


     NUÑO.– Lo tenía.


     MENDO.– Tomadlo, y perdón, señora,
si os lo quise arrebatar. (Le da el collar.)


     MAGDALENA.– (A Pero.) ¿Estáis convencido ahora
de quee vino aquí a robar?


     PERO.– Convencido y dolorido
de haber dudado de vos,
y os pido en nombre de Dios
para mi crimen olvido.
Pronto mi esposa os haré


                                                      23
como ya está concertado.
¿Me perdonáis?


     MAGDALENA.– ¡Perdondado!


     MENDO.– (¡Santo cielo! ¿Qué escuché?
Ella su esposa. ¡Su esposa!...
si tal es verdad, estimo
que salvándola hice el primo
de una manera espantosa.
Pronto he de saberlo, sí,
que he de preguntarle yo
y he de arrancarle... (Conteniéndose.)
Mas, ¡oh!
¿Y la palabra que di?)


     NUÑO.– Presto, tomadle la espada
y a un calabozo sombrío
llevadle.


     PERO.– (Rendidamente a Magdalena.) ¡Prenda adorada!


     MAGDALENA.– (Idem.) ¡Don Pero!... ¡Don Pero mío!...


     MENDO.– (Enloquecido.) (¡Ah! ¡No! ¡Mi venda cayó!
¡He de confesarlo aquí! (Conteniéndose de nuevo.)
¡Pero no es posible, no!
¡Dios santo! ¿Qué iba a hacer yo?
¿Y la palabra que di?


     NUÑO.– Sujetadle.


     MENDO.– ¡Atrás, follones!
Que sólo así un caballero
puede entregar el acero
que combatió en cien acciones. (Rompe la espada y arroja los pedazos en el suelo.)


     NUÑO.– ¡Vive Dios, que tal pujanza
ni tal orgullo comprendo!


     MENDO.– (Sujeto ya fuertemente por Lorenzana, Aldana y Oliva.) ¡Venganza, cielos, venganza! (Mirando al
cielo.)


                                                         24
Juro, y al jurar te ofrendo,
que los siglos en su atruendo
habrán de mí una enseñanz
pues dejará perduranza
la venganza de don Mendo. (Cae desmayada Magdalena. Inician el mutis los que conducen a don Mendo, y cae el
telón.)


                                                FIN DE LA JORNADA PRIMERA




                                          JORNADA SEGUNDA


          Interior de la torre abovedada que sirve de prisión a don Mendo. Una claraboya en el foro, cerca del techo, y
una puerta en el lateral izquierda. Al levantarse el telón amanece.


                                                                        Está en escena DON MENDO, recostado sobre
                                                                 un mal camastro. No hay en escena más muebles que el
                                                                 susodicho camastro y un par de taburetes toscos.


     MENDO.– (Incorporándose, restregándose los ojos y mirando a la claraboya.) Ya amanece. Por esa claraboya
las luces del crepúsculo atalayo:
pronto entrará del sol el puro rayo
que a las sombras arrolla
y en bienestar convierte mi desmayo... (Por la claraboya entra triunfante un rayo de sol.)
¡Ya el rayo destella!...
¡Ya mi prisión se enjoya de luz bella!...
¡Ya soy dueño de mí!... ¡Ya bien me hallo!... (Canta un gallo dentro, lejos.)
¡Ya trina el ruiseñor!... ¡Ya canta el gallo!... (Pausa.)
¡Trece de mayo ya!... ¡Quién lo diría!
Llevo en esta prisión un mes y un día,
sin por nadie saber lo que acontece... (Estremeciéndose.)
¡Y hoy martes, gran Dios!... ¡Martes y trece!...
¿Por qué el terror invade el alma mía?
¿Por qué me inspira un miedo extraordinario
esa cifra, ¡ay de mí!, del calendario? (Como loco.)
¡Ah, no, cifra fatal!... No humillaréis
el valor de don Mendo; no podréis;
todos iguales para mí seréis,,,


                                                            25
¡Trece, catorce, quince y dieciséis! (Pausa.)
¿Moriré sin venganza? ¡Cielos! ¡Nunca!
Ha de morir la que mi vida trunca
y morirá a mis manos... Mas, ¿qué exclamo?
¿Cómo podré matalla si aún la amo?
Acaso por salvarse aquella noche
aceptó del de Toro sin reproche
el amor y la fe y el galanteo...
Mas aquel «Pero mío», aquel sobeo
delante de mi faz, estuvo feo;
porque él llegó a palpalla,
que yo lo vi con estos ojos, ¡ay!
y ella debió oponerse, ¡qué caray!,
al ver lo que yo hacía por salvalla. (Escuchando hacia la derecha.)
Oigo pasos. Acaso
es Magdalena que en amor e abrasa
o el carcelero vil, que con retraso
tráeme el bollo de pan que él mismo amasa... (Viendo que la puerta se abre y que aparece en el umbra Clodulfo, viejo
mal encarado y cetrino, que trae un gran pan y un cántaro.)


     CLODULFO.– ¿Paso?


     MENDO.– (Desalentado.) Pasa. (Clodulfo deja en escena el pan y el cántaro y se dispone a hacer el mutis.)
¿Hoy también, viejo Clodulfo,
habrás de guardar silencio?
¿Hoy tampoco mis preguntas
habrán en tus labios secos?
¿Cuándo saldré de esta torre?
¿Pronto o tarde? ¿Vivo o muerto?
¿No sabré tampoco hoy
lo que con ansias espero?


     CLODULFO.– Hoy lo sabrás.


     MENDO.– ¿Por fin hablas?


     CLODULFO.– Hablo ya, porque hablar puedo,
que hoy de gala está el castillo
y hoy es día grande, don Mendo.


     MENDO.– ¿Día grande?



                                                           26
     CLODULFO.– Más brilla el sol
hoy que ayer, aun siendo el mesmo.


     MENDO.– ¿Pues qué ocurre?


     CLODULFO.– Que el privado
del Rey don Alfonso séptimo,
el noble duque de Toro
y conde de Recovedo,
señor de catorce villas,
seis castillos y un convento,
a las nueve ha de casarse
con Magdalena... (Al ver que don Mendo medio se desvanece.)
¡Don Mendo! (Acude a él y le sujeta.)
¿Qué mal os dio que os pusisteis
pálido, convulso y trémulo?...


     MENDO.– (Reponiéndose y después de una breve pausa.)
Nada, Clodulfo, un vahído,
un malestar, un mareo,
una locura, un repente,
una turbación, un vértigo...
Mas ya pasó, por ventura.


     CLODULFO.– Yo creo que estáis neurasténico.


     MENDO.– Tal vez; ¡ay de mí! Mas sigue,
viejo Clodulfo. Ha un momento
decías...


     CLODULFO.– Que Magdalena
hoy se casa con don Pero
y está don Nuño gozoso
y las galas del gozo haciendo
ha mandado que las puertas
queden franccas a sus deudos;
y que la despensa se abra
y que corra el vino añejo,
y que en la más alta torre
luzca el pendón de su abuelo,
que no hay un pendón más grande,
ni más noble, ni más viejo.


                                                       27
Colmada está ya le iglesia;
en fiesta arde ya el pueblo;
y los tres primos del Conde,
don Juan, don Tirso y don Crespo,
llegaron esta mañana
desde Pravia, con su séquito.


     MENDO.– (Dejándose caer, abatido, en el camastro.)
¡Que ella se casa!... ¡¡Se casa!!...
¡Y yo en esta torre preso,
haciendo el primo!... ¿Qué dije?
El primo es poco... ¡el canelo!...
¡Martes y trece, por algo
os tomé en aborrecimiento!...


     CLODULFO.– ¿Qué os sucede?


     MENDO.– Nada, nada...


     CLODULFO.– ¿Es que teméis?


     MENDO.– ¡Nada temo!


     CLODULFO.– Pensé que...


     MENDO.– (Altivo.) Pensaste mal.


     CLODULFO.– Os vi temblar...


     MENDO.– ¡Yo no tiemblo!
Nada en la vida, Clodulfo,
hizo temblar a don Mendo.


     CLODULFO.– Perdonad, marqués de Cabra,
si mis frases os hirieron...


     MENDO.– Perdonado estás, Clodulfo;
y agora, si no es secreto,
dime qué suerte me espera
y dilo sin titubeos,
bueno o malo, lo que fuera.
¡Qué me importa, vive el cielo!


                                                      28
Cuando hace un rato, ¡ay de mí!,
no rodé a tus plantas mureto,
es que un rayo no me mata.
Habla, por Dios, habla presto.


     CLODULFO.– ¿Tendréis valor?...


     MENDO.– (Altivísimo.) ¿Olvidaste
que te escucha un caballero?


     CLODULFO.– Pues bien, el conde don Nuño,
vuestra prosapia atendiendo,
pensó sacaros los ojos
y daros libertad luego;
pero terció Magdalena...


     MENDO.– ¡Magdalena!... ¡Blando pecho
que envidia diera a las aves!...
¡Corazón de suaves pétalos!...
¡Alma pura, cual la linfa
del transparente arroyuelo!...
¡Magdalena!... ¡Magdalena!...
¡Ave, rosa, luz, espejo,
rayo, linfa, luna, fuente,
ángel, joya, vida, cielo!...
¿Y dices que ella terció?


     CLODULFO.– Terció y os hizo mal tercio,
porque pidió que la lengua
os arrancasen primero
y que os cortasen las manos
y que mudo, manco y ciego
en esta torre quedaseis
para siempre prisionero.


     MENDO.– ¡¡Mientes!!


     CLODULFO.– ¡No!


     MENDO.- ¡Mientes te digo!
¡Infame sayón!



                                                29
     CLODULFO.– (Amenazador.) ¡Don Mendo!...


     MONCADA.– (Entrando en escena.)
¡Vive Dios, que hasta en prisiones
y con vuestro carcelero
habéis de reñir!


     MENDO.– (Asombrado.) ¡Moncada!
¿Pero sois vos?


     MONCADA.– En efeto.


     CLODULFO.– (¡El de Moncada en la torre!...)


     MONCADA.– (A Clodulfo.) Dejadnos, buen hombre.


     CLODULFO.– (Sin moverse.) Eso...


     MONCADA.– (Imperioso.) ¡Dejadnos digo!


     CLODULFO.– (Resistiéndose.) Es que yo...


     MONCADA.– Si desenvaino el acero,
vasi a quedar en la torre;
pero vive Dios, que muerto.


     CLODULFO.– (Temeroso.) Pues que así lo suplicáis,
señor marqués... obedezco. (Se va, cerrando la puerta.)


     MONCADA.– Aunque cierre no me importa:
me abrirán mis escuderos. (Este Marqués de Moncada es joven y apuestísimo.)


     MENDO.– (Que aún no ha vuelto de su asombro.)
En vano pretendo, Marqués de Moncada,
hallar las razones que aquí os han traído.


     MONCADA.– ¿No sois por ventura, mi buen camarada?


     MENDO.– ¿Camarada vuestro quien ha delinquido?
Perpetrando un robo me vi sorprendido,
así plugo al cielo o al Hado... o al Hada,
y no creo Moncada, que ganéis vos nada,


                                                          30
siendo camarada de quien a su espada
ha infido, escupido, torcido y rompido.


     MONCADA.– (Sonriente.) Mentís.


     MENDO.– ¿Qué decís?


     MONCADA.– Mentís.
Y vos de vos os reís,
como yo me rio de vos.


     MENDO.– No comprendo qué decís.


     MONCADA.– Será porque no querís,
que está claro, ¡vive Dios!


     MENDO.– Siempre fuisteis enigmático
y epigramático y ático
y gramático y simbólico,
y aunque os escucho flemático
sabed que a mí lo hiperbólico
no me resulta simpático.
Habladme claro, Marqués,
que en esta cárcel sombría
cualquier claridad de día
consuelo y alivio es.


     MONCADA.– claro he de hablar, a fe mía.
Si vos fueseis un ladrón,
o por ladrón yo os tuviera,
juro a Dios, que os escupiera
a la frente, con razón;
y en vez de en esta prisión
hallarme, cual ahora ve,
sin fe en vos ni en nadie fe,
a vuestra amistad y afeto
puesto hubiera con respeto
el consabido R.I.P.
Mas sé, Marqués... ¡lo sé yo!,
que en esta torre cautivo
está un caballero altivo
que nunca en robar soñó;


                                               31
que si en un castillo entró,
no entró en él para robar
el aljófar de un collar
que aun valiendo es baladí,
sino que entró en él...


     MENDO.– (Imperioso.) ¡¡No!!


     MONCADA.– (Idem y achicándole.) ¡¡¡Sí!!!
Yo lo juro... ¡para amar!


     MENDO.– ¡Miente quien tal cosa diga!


     MONCADA.– El que confeséis no espero,
pues sé que sois caballero
y a enmudecer os obliga
algo que os ata y que os liga.
Pero, por casualidad,
que tal cosa en mí no cabe,
como todo al fin se sabe,
yo he sabido la verdad.


     MENDO.– (Irónico.) ¿Con la verdad disteis?


     MONCADA.– Di.


      MENDO.– ¡Pues suerte tuvisteis!


     MONCADA.– ¡Oh!


     MENDO.– ¿Y si os engañasteis?


     MONCADA.– ¡No!


     MENDO.– ¿Estais bien seguro?


     MONCADA.– ¡Sí!


     MENDO.– ¿Acaso visteis?...


     MONCADA.– ¡Lo vi!



                                                  32
     MENDO.– ¿Y sabéis que yo?...


     MONCADA.– ¡Lo sé!


     MENDO.– ¿Pero cómo?...


     MONCADA.– Os lo diré:
mas por Dios tranquilizaos.


     MENDO.– Estoy tranquilo. Sentaos.


     MONCADA.– Muchas gracias.


     MENDO.– No hay de qué. (Se sientan los dos. Pausa )


     MONCADA.– Ha de antiguo la costumbre
mi padre, el barón de Mies,
de descender de su cumbre
y cazar aves con lumbre:
ya sabéis vos cómo es.
En la noche más cerrada
se toma un farol de hierro
que tenga la luz tapada,
se coge una espada
y una esquila o un cencerro,
a fin de que al avanzar
el cazador importuno
las aves oigan sonar
la esquila y puedan pensar
que es un animal vacuno;
y en medio de la penumbra
cuando al cabo se columbra
que está cerca el verderol,
se alumbra, se le deslumbra
con la lumbre del farol,
queda el ave temblorosa,
cautelosa, recelosa,
y entonces, sin embarazo,
se le atiza un estacazo,
se le mata y a otra cosa.




                                                      33
     MENDO.– No es torpe, no, la invención;
mas un cazador de ley
no debe hacer tal acción,
pues oyendo el esquilón
toman las avez por buey
a vuestro padre el Barón.


     MONCADA.– Es verdad. No había caído...
Vuestra advertencia es muy justa
y os agradezco el cumplido.
¡El Barón, por buey tenido!...
No me gusta; no me gusta.


     MENDO.– ¿Y a qué viene, ¡vive el cielo!,
cuando tan grande es mi duelo,
esa conseja endiablada
del cencerro y de la espada
y del farol y del celo?


     MONCADA.– Viene, amigo, a que el Barón,
cierta noche que cazaba
con la luz y el esquilón,
vio una escala que colgaba
de no sé qué torreón.


     MENDO.– Acaso el Barón soñaba...


     MONCADA.– Y otra noche, vio algo más.


     MENDO.– ¿Qué me decís, vive Dios?...


     MONCADA.– Que vio... soñando quizás,
que echaron la escala... y zas,
por ella bajasteis vos. (Don Mendo baja los ojos y se deja caer abatidísimo en su camastro.)
Y esto, don Mendo, tal vez
por alguien se ha comentado,
y al de Collado ha llegado,
y don Pero, que es un pez,
está por vos escamado.
Y como al cabo no es bobo,
de Magdalena abomina
y, lógicamente, opina


                                                          34
que la comedia del robo
sólo fue una pantomima.
Y ella, que anhela el sosiego
o que ve perder su juego
y en casarse tiene prisa,
quiere que quedéis, ¡qué risa!,
preso, mudo, manco y ciego.
Pero no será, ¡no! ¡No!
Que aunque vos, Marqués de Cabra,
a ella le disteis palabra
de salvalle, hablaré yo.
Mas para hablar, sólo espero
vuestra indicación somera.


     MENDO.– ¿Y es caballero el que espera
que no sea yo caballero?


     MONCADA.– ¿Y es caballero, Marqués,
el que por una perjura
muere vilmente?


     MENDO.– Lo es:
mi palabra os lo asegura,
y soy leonés.


     MONCADA.– Basta, pues.
Y en premio de esa hidalguía
que en vos es norte y guía;
en premio de ese valor,
tomad esta daga mía. (Le da una daga.)
Os la da un hombre de honor.
Ponedla oculta y salvaos
si ocasión para ello habéis;
y si la afrenta teméis
de una muerte vil, mataos;
porque es tan grande la insidia,
la perfidia y la falsidia
del mundo, que casi envidio
al que apelando al suicidio
toma un arma y se suicidia.




                                             35
     MENDO.– (Abrazándole conmovido.)
¡Marqués de Moncada! ¡Hermano!
¡Permitid que os dé ese nombre!...


     MONCADA.– ¿Os afectáis?


     MENDO.– No os asombre,
que este dolor sobrehumano
en niño convierto a un hombre.
Gracias mil por el puñal;
gracias mil, porque mi mal
será por él menos cruel,
pues muy pronto, amigo fiel,
habré de hundírmelo en el
quinto espacio intercostal.
Y cuando os hablen de mí,
decid, Marqués, decid vos
que caballero morí,
pues una palabra di
y la cumplí, vive Dios. (Le abraza de nuevo.)


     CLODULFO.– (Entrando muy azorado y muy nervioso, a Moncada.) Salid, caballero,
salid a seguida
porque de no hacello
mi vida peligra.


     MENDO.– ¿Qué ocurre?


     MONCADA.– ¿Qué pasa?


     CLODULFO.– Nadie se lo explica.


     MENDO.– Hablad.


     CLODULFO.– Que la novia
ya estaba vestida
aguardando al Duque
y a su comitiva
y el Abad mitrado
calada la mitra
aguardaba a entrambos
en la sacristía,


                                                     36
cuando de repente
las tropas avisan
y el de Toro arriba,
sin pajes, ni escoltas,
ni bandas, ni insignias.
Llega tembloroso;
pálido de ira;
echando venablos
y tacos y ristras,
y dice a la novia:
«¡Perjura!... ¡Maldita!...
¡Fuiste de don Mendo
la amante y la amiga;
y tú le idolatras
y por él suspiras;
lo sé, miserable,
de muy buena tinta!»...
¡Mientes! - grita ella.
¡Falso! - el conde grita,
y los tres Pravianos,
rugiendo de ira,
al de Toro quieren
sesgarle la vida.
¡Callen todos!... dice
ella enfurecida.
¿Quieres que te pruebe
que aquesto es mentira?
- Si me lo probaras
yo me casaría.
- Pues ven a la torre
que el cautivo habita,
ven a la cárcel
y en su cárcel misma
yo sabré librarte
de tanta falsía.
Y ya suben todos escaleras arriba...


     MONCADA.– ¡Valor, pobre amigo! (Se abrazan.)


     CLODULFO.– Salid enseguida.


     MENDO.– ¡Adiós! ¡Hasta nunca!


                                                    37
     CLODULFO.– ¡Que ya se avecinan!


     MONCADA.– ¿Hablaréis?


     MENDO.– Primero me arranco la vida. (Se van Moncada y Clodulfo. Don Mendo queda alicaidísimo.)
¡Voy a verla! Sí. ¿Qué incoa
mi espíritu? Lo que incoe
ya mi cerebro corroe.
¿Mas qué importa que corroa?
¡Aspid que en mi pecho roe,
prosigue tu insana roa
que aunque soy digno de loa
no he deser yo quien se loe!
¡Fuerzas, cielos, porque al vella
querré matalla y mordella
y eso sería delatalla!
¡Juro a Dios que he de miralla
y escuchalla sin vendella!
Mas si juré no perdella
también vengarme juré
en la infausta noche aquella.
Y he de vengarme; sí, a fe.
¿Mas qué haré, qué intentaré?
¿Cómo vengarme podré
si lo que juré, sé que
lacra mi boca y la sella?
¡Cómo, ¡ay Dios!, compaginallo
si este desengaño, ¡ah!,
no puede dejarme ya
ni tiempo para pensallo?... (Saca el puñal, lo besa y lo contempla con arrobo.)
¡Puñal de puño de aluño!...
¡Puñal de bruñido acero,
orgullo del puñalero
que te forjó y te dio bruño!...
Puñal que en mi mano empuño,
en cuyos finos estríes
hay escritas con rubíes
dos frases a cual más bella:
«Si hay que luchar, no te enfríes.
Si hay que matar... descabella.»
Tú con tu lengua me llamas


                                                           38
y deshaces mi congoja,
pues teniendo yo tu hoja
no he de andarme por las ramas.
Penetra, puñal, en mí,
llega pronto al corazón
y a quien pregunte, di
que a pesar de su traición
adorándola morí. (Ocultando el puñal al ver que se abre la puerta.)
¡Mas ya llegan: maldición!
¡Qué lindo tiempo perdí! (Entran en escena, primero dos frailes cistercianos, caladas las capuchas, luego don Nuño,
don Pero, doña Ramírez, el Abad con su gran mitra, don Juan, don Tirso y don Crespo, tres nobles de Pravia, frailes,
soldados, etc. Por último entra Magdalena, con el traje de boda, apoyada en doña Ninón.)
Un fraile... dos frailes... Mi mente no sueña.
El conde don Nuño... Don Pero, la dueña...
El Abad mitrado, los nobles pravianos,
que son los tres primos porque son hermanos...
¿Pero y ella?... ¿Y ella?... ¿Do está, vive Cristo?... (Entra Magdalena, don Mendo se estremece.)
¡Ah! ¡Por fin la he visto! ¡La he visto!... ¡La he visto! (Pausa. Todos miran a Magdalena.)


     MAGDALENA.– ¿Dónde está quien mi paz turba?
¿Dónde está, que quiero vello?
¿Dónde está el que fue motivo
de los celos de don Pero?
¿Es éste?


     PERO.– ¡Sí!...


     MENDO.– (¡Cuán hermosa
está con su traje nuevo!...)


     MAGDALENA.– Pues escuchad: ante todos
digo que su muerte quiero,
que si importunóme vivo
no ha de importunarme muerto.
Yo juro que nada mío
ha sido nunca de don Mendo;
que él, que me escucha, responda
si digo verdad o miento.


     MENDO.– Dice verdad. (Rumores.)


     RAMÍREZ.– (Es un primo.)


                                                           39
     PERO.– (Humildemente.) ¡Magdalena!


     MAGDALENA.– (Altivísima deteniéndose con el gesto.) ¡Caballero!


     RAMÍREZ.– (Don Pero se lo ha creído.
Este Pero es un camueso.)


     MAGDALENA.– Padre y señor, ya lo oíste.
Ya lo escuchaste, don Pero.
Jamás mis labios le hablaron:
jamás mis ojos le vieron:
para robar, escaló
la torre de mi aposento.
Ladrón, ladrón, no mereces
otro nombre y a él apeli.


     PERO.– ¡Perdóname, Magdalena!...


     MAGDALENA.– No he terminado. Un momento.
Por los males que me fizo
pido a todos que ahora mesmo
y aquí mesmo le empareden;
y para escarnio y ejemplo,
le dejen una mano,
la mano del brazo diestro. (Rumores.)


     MENDO.– (¡Caray, qué bruta!)


     PERO.– (Cayendo de rodillas a los pies de Magdalena, y tomándole una mano.) Amor mío,
¡perdón mil veces!


     MAGDALENA.– ¡Don Pero!...


     PERO.– Con señales tan prolijas
la vil calumnia tejieron,
que yo, encelado, caí
como a zorra en el cepo.
¡Perdóname!


     MAGDALENA.– Perdonado.



                                                      40
     NUÑO.– (Desenvainando la espada.)
¿Que lo perdonas? ¿Qué es esto? (Sensación. Pausa. Don Pero se levanta y le mira con altivez.)
Poco a poco, Magdalena;
tú eres mujer y eres buena
y perdonas; pero yo,
a quien la calumnia oyó
como canto de sirena,
y la creyó y difundió
y me ofendió y ultrajó
y mi honor pisoteó,
no he de perdonarle. ¡Oh!


     MAGDALENA.– ¡Padre! ¡Padre!


     NUÑO.– ¡No, no, no!
Aunque cumplí los setent
aún mi brazo tiene brío
para saldar esa cuenta
con Pero.


     MAGDALENA.– ¡Pero Dios mío!...


     RAMÍREZ.– ¿Lavar vos, Conde, la afrenta
a vuestra edad? Es salirse
de lo que por justo estimo.
Vuestro valor, no escatimo,
mas por vos, debe batirse... (Por don Juan y don Crespo.)
este primo... o aquel primo.


     CRESPO.– Dice bien.


     JUAN.– Tiene razón.
Para lavar el baldón,
la mancha que nos agravia
Conde Nuño, henos de Pravia.


     ABAD.– (Mediando con voz hueca campanuda.)
Un solo instante...


     NUÑO.– Atención.


     ABAD.– Caballeros, escuchad.


                                                            41
     RAMÍREZ.– Escuchad, que habla el Abad.


     ABAD.– Un consejo permitid,
en nombre de la piedad
de la que soy adalid
como Abad y por edad.


     PERO.– Decid, don David, decid.


     NUÑO.– Hablad, buena Abad, hablad.


     ABAD.– El gran Duque, como yo,
cree que su esposa futura
es pura, cual aura pura.
¿Opino bien?


     PERO.– ¿Cómo no?


     ABAD.– Pues si todos, según veo,
creen lo mismo que yo creo
¿a qué más sangre verter?
¿A qué este asunto mover
si ha de haber luego himeneo?
¿Que él al dudar la ofendió?
Pues al casarse, coliga
que su pecado purgó,
que el casamiento, creo yo
que es suficiente castigo.
¿A qué batirse? ¿Qué alcance
tiene ese duelo que infama?
¿Que un ilustre nombre dance?
¿Que alguien diga que esta dama
es una dama de lance?
Esa idea del averno
dad, Conde, por no pensada.
Turpiter atrum, fraterno!
Abrazad a vuestro yerno
y aquí no ha pasado nada.


     NUÑO.– (Humilde.) Del Evangelio la voz,
siempre sabia y eficaz,


                                               42
vibró en mi pecho y veloz
quiero brindaros la paz.


     PERO.– Y yo la acepto veraz,
porque hubiera sido atroz
ese duelo contumaz. (Se abrazan.)
En cuanto a don Mendo, apruebe
lo por mi dama indicado.


     NUÑO.– Aprobado, sí, aprobado.
En esta boda no debe
faltar ese emparedado. (Gritando hacia el lateral.)
A ver, Mendingundinchía...
Otalaorreta... Sarmiento...
Acudan, por mi vida...


     MENDO.– (¡Qué momento!... ¡Qué momento!) (Entran en escena Marcial y León, hombres de armas con
capuchas rojas. No se les verá la cara.)


     NUÑO.– Que aqueste muro vacíen,
que en él fabriquen su nicho,
y en la forma que se ha dicho
le sepulten.


     MENDO.– ¿Es capricho
eso de la mano?


     NUÑO.– Sí;
fuera y de aquesta manera,
en actitud pordiosera,
para que al salir de aquí
todo el que a veros viniera
diga a la ciudad entera:
«Allí está don Mendo, allí,
en la torre, yo le vi;
tenía una mano fuera,
por eso le conocí.»


     ABAD.– Don Pero, ya el ara espera.




                                                      43
     PERO.– Vamos al ara preclara,
pues sólo el ara remedia
la inquietud que me acibara.


     MENDO.– (¡Esto, ay Dios, cuán me apesara,
quedar yo con mi tragedia
mientras ellos van al ara
para ver una comedia!...)


     NUÑO.– (A uno de los frailes, el que oculta más el rostro.)
Quedad con él y exhortalle,
fray Luis de Jerusalén;
confesalle y preparalle
para bien morir, amén.
¿Vamos todos?


     ABAD.– Vamos, sí. (Van haciendo mutis.)


     MENDO.– (Lo que prometí, cumplí.)


     MAGDALENA.– (¡Lo que prometió, cumplió!)


     RAMÍREZ.– (¡Jamás tal lealtad se vio!)


     MENDO.– (¡Jamás tal perjurio vi!
¡No sé si oí lo que oí
o si mi mente lo urdió!)


     MAGDALENA.– (Con tal de ser feliz yo,
¿qué puede importarme a mí
que lo empareden o no?) (Vase.)


     MENDO.– (Monstruo de maldad, quimera
con forma de ángel divino...)


     RAMÍREZ.– (Y el pobre duque en la higuera...
¡Los hay que tienen un sino!... (Vase. Quedan en escena don Mendo y los dos frailes, es decir, Moncada y Sigüenza y
los dos verdugos.)


     MENDO.– Basta ya de sufrimientos;
acabemos de una vez
y con altivez, ¡pardiez!


                                                          44
Esta vida de tormentos. (A los frailes, sacando el puñal.)
Se empareda a los villanos,
no a los hombres de raigambre.
Sed testigos, cisterianos,
de que muero por mis manos
y emparedan a un fiambre. (Intenta clavarse el puñal; pero Moncada y Sigüenza echan atrás sus capuchas respectivas y
le sujetan.)


     MONCADA.– ¡Quieto!


     MENDO.– ¡Moncada!... ¡Sigüenza!...


     SIGÜENZA.– ¿Qué es esto? ¿Qué vais a hacer?


     MENDO.– ¡Matarme!


     MONCADA.– ¿Cuando comienza
vuestra vida a renacer?


     MENDO.– No comprendo.


     MONCADA.– (Llamando.) ¡Pronto! ¡Alenza...
Gorostiza... León!...
El cadáver y el avío. (Se quitan Marcial y León las caperuzas rojas.)


     MENDO.– (Boquiabierto.) ¿Pero qué es esto, Dios mío?
¡El Vizconde y el Barón!...
¡Oh, virtud de la amistad!


     MONCADA.– ¡Presto, Vizconde, avisad;
no hay que perder un instante!


     MARCIAL.– (Asomándose al lateral izquierda.)
Vamos, señores, pasad,
con vuestra carga y adelante. (Entran cuatro gachós con unas parihuelas en las que traen un cadáver tapado con una
manta.)


     MENDO.– ¿Ese cadáver?... No acierto...


     MONCADA.– En ocasión a que está
don Mendo, el castillo abierto,
hemos embriagado a


                                                             45
vuestros verdugos.


     MENDO.– ¿Es cierto?


     MONCADA.– Y en lugar de vos se hará
emparedar a este muerto.
Ponga el anillo en su mano,
y aprovechando la fiesta
y el bullicio cortesano,
huya de la torre aquesta
vestido de cisterciano. (Se quita el hábito.)


     MENDO.- Huiré, sí; pero yo juro
que nadie sabrá de mí;
que don Mendo queda aquí
sepultado en este muro.
Yo ya no soy el que era;
he muerto, y el que ha nacido
ni es don Mendo ni lo ha sido,
ni volverlo a ser quisiera.
Soy un ente, una quimera;
soy un jirón, una sombra;
alguien sin patria y sin nombre
que de ser hombre se asombra.
Cual una nota perdida
con la ceniza en la frente,
naufragaré en el torrente
proceloso de la vida.
¿De qué viviré?... ¿Qué haré?
¿Dónde al cabo moriré?...
¿Aquí o allá?... ¿Qué más da?
¿Seré malo?... ¡Qui lo sa!
Malo o bueno, par vos
será mi postrimer hálito.
Acabemos. Venga el hábito. (Lo toma.)
Ahí va mi anillo, y adiós.


     MONCADA.– (Conmovido.) ¡Don Mendo!


     MENDO.- ¿Qué estáis diciendo?
¿Don Mendo yo? ¿Estáis seguro? (Por el cadáver.)
Ese, Moncada, es don Mendo,


                                                   46
el que sin pompas ni estruendo
vais a enterrar en el muro.
Despedidme de otra suerte,
porque yo no tengo nombre.


     MONCADA.- ¿Y cómo os diré que acierte?


     MENDO.– Decidme sólo: ¡Adiós, hombre!


     MONCADA.– ¡Adiós, hombre!... ¡Buena suerte! (Telón.)


                                             FIN DE LA JORNADA SEGUNDA




                                       JORNADA TERCERA


         Perspectiva de un campamento en el siglo XII. En el telón de fondo habrá pintadas aquí y allá, entre macizos
de árboles y sorteando los accidentes del terreno, varias tiendas de campaña. Lejos se verá una ciudad circundada por
espesas murallas y enhiestos torreones. En el lateral derecha frondoso arbolado. En el lateral izquierda una lujosa tienda
de campaña que se pierde en el lateral. Es de día.


                                                                       Al levantarse el telón están en escena FROILÁN
                                                                y MANFREDO, nobles y apuestos guerreros. Dentro
                                                                suena, cerca, un redoble de tambor, luego otro redoble
                                                                más lejano, y así un rato hasta perderse el sonido
                                                                lejísimos.


     FROILÁN.– Ya los roncos atambores
dan al aire las noticias. (A Girona, que entra por la derecha primer término.)
¡Albricias, Girona!


     MANFREDO.– ¡Albricias!


     GIRONA.– Muy buenas tardes, señores.
¿Es cierto lo que pregona
ese parche que resuena?




                                                           47
     MANFREDO.– Es cierto; de enhorabuena
estamos todos, Girona.


     FROILÁN.– (Mirando hacia la derecha último término.)
Pero, ¡vive Dios! ¿Qué vedo?
¡Aquel aire, aquella espada!...
¿Es que deliro, Manfredo,
o es el Marqués de Moncada?


     MANFREDO.– El Marqués es, en efecto,
que ni en Burgos ni en León
hay jubón cual su jubón
ni peto como su peto.


     MONCADA.– (Entrando en escena por el término indicado.)
¿Redoblan? ¡Por San Dionís!
¿A quién tal ruido precede?


     FROILÁN.– Capitán, ¿de do salís
que ignoráis lo que sucede?


     MONCADA.– Pues, ¿qué sucede, Froilán?
¿Anuncian alguna ley?


     FROILÁN.– Anuncian al Rey.




     MONCADA.– ¿Al Rey?
¿No me engañáis?


     FROILÁN.– ¡Capitán!




     MONCADA.– Perdonad. Herido fui
cuando Baños fue asaltado,
y de Burgos he llegado
recientemente.


     FROILÁN.– Pues sí;
don Alfonso hace un momento
salió de la ciudadela,
y con doña Berenguela


                                                     48
va a llegar al campamento.
Viene a ver a su privado,
y no es extraño el honor,
que muerto el Cid Campeador
no hay otro más esforzado;
pues con su arresto y su hueste,
es sabido que el de Toro
supo contener al moro
al Este, al Sur y al Oeste.
El fuerte de Olivo fue
su principal objetivo,
y sabéis, Moncad, que
don Pero tomó el Olivo.
En la villa de Al-coló
bien demostró sus redaños;
y después, al tomar Baños,
su mayor triunfo alcanzó.
Ayer juró ante la tropa
y ante toda la nobleza
que hasta no entrar en Baeza
no ha de mudarse de ropa;
y siendo ayer once, infiero
que en entrar tendrá interés,
pues él se muda el primero
y el quince de cada mes.
¿No valen estos trabajos
que el propio Rey le visite
y le abrace y felicite
y le colme de agasajos?


     MONCADA.– ¿Y no será otro el motivo
que obliga al Rey a venir?


     FROILÁN.– No sé, Marqués, qué decir.
Aquí no hay otro atractivo...


     MONCADA.– Hailo.


     FROILÁN.– ¡Cielo! ¿Hailo? ¿Y eso?


     MONCADA.– Yo no soy ningún Licurgo,
mas aquí, Froilán, ni en Burgo


                                            49
me la da nadie con queso.
No hay que emular a la ardilla
para saber, ¡vive Dios!,
cómo es el Rey de Castilla.


     FROILÁN.– ¿Sabéis vos...?


     MONCADA.– ¡Mejor que vos!
Que en mi infancia, allá en Sagley,
y en Pozal, y hasta en Bordallo,
hemos corrido el caballo
juntamente yo y el Rey.
Más de cien noches de oculto,
él portando un anafil
y yo llevando el candil,
hemos escurrido el bulto
en busca de galanteos
con damas de baja estofa,
y hasta con la vil gallofa
hubo lances y escarceos.
Él es, Froilán, muy osado
al par que afable y cortés,
¡si sabré yo cómo es
después de haberle alumbrado!


     MANFREDO.– ¿Y opináis vos?...


     MONCADA.– ¡Claro está!


     GIRONA.– ¿Qué aquí viene?...


     MONCADA.– Es muy creíble.


     MANFREDO.– ¿Alguna mujer?


     MONCADA.– ¡Quizá!


     GIRONA.– ¿Algún amor?


     MONCADA.– Es posible.




                                      50
     MANFREDO.– Entonces, ¿vos suponéis
que viene por la...? (Señala la tienda de la izquierda.)


     MONCADA.– ¡Manfredo,
en la llaga vuestro dedo
con gran tino puesto habéis! (Confidencial.)
El privado se casó
con la Manso de Jarama,
al propio Rey, que exclamó
al conocella: ¡Por Cristo,
que en mi vida logré ver
una tan linda mujer
como la que agora he visto!
A su conquista me lanzo,
que esa Manso es un tesoro;
y sabiendo que el de Toro
al par que Toro era Manso,
rápido como un cohete
puso cerco a la señora,
y al cabo de media hora
era ya de Alfonso siete.
Y pues que agora la bella
mora en aqueste vergel,
viene el Rey, no a verle a él,
el Rey viene a verla a ella.


     FROILÁN.– (Enfáticamente, dando un paso atrás.)
Pues pierde su tiempo el Rey,
señor Marqués de Moncada,
que la esposa de don Pero
no está ya del Rey prendada,
sino de un bardo errabundo
que la dejó fascinada
una mañana en Fuenfría
al pie de Navacerrada.


     MONCADA.– ¿De un bardo? ¿De un trovador
la Duquesa enamorada?
¿Estáis seguro?


     FROILÁN.– Lo estoy,
señor Marqués de Moncada;


                                                           51
de un trovador, que no lleva
ni crestón, ni barberada,
ni casco, ni cruz, ni peto
ni porta en el cinto espada,
sino un puñal toledano
de hoja fina y bien templada
con rubíes que parecen
robados a la alborada
y en su puño, vuestro cuño,
señor Marqués de Moncada.


     MONCADA.– ¿Mi cuño?... (¡Cielos! ¿Acaso
es la joya regalada
por mí a don Mendo, o la otra
que en Burgos dejé empeñada
en el Mesón de Paredes?)
Vive el cielo que me agrada
lo que me contáis del bardo
que hizo empresa tan osada.
¿Podréis, Froilán, describilla?


     FROILÁN.– Puedo, que su faz grabada
quedó en mis ojos al vello,
al pie de Navacerrada.
Tiene la color oscura,
tiene la su voz velada,
la su cabeza es pequeña
y algo braquicefalada.
Tiene rubios los cabellos,
tiene la barba afeitada,
breve el naso, noble el belfo,
la su frente despejada,
y una mirada tan dulce,
tan triste, tan apenada,
que hay que preguntarle al vella:
¿qué tienes en la mirada?


     MONCADA.– ¿Sabéis su nombre?


     FROILÁN.– Renato.


     MONCADA.– Le va bien.


                                               52
     FROILÁN.– ¿Cómo?


     MONCADA.– No, nada.
¿Y se apellida?


     FROILÁN.– Lo ignoro,
señor Marqués de Moncada.


     MONCADA.– (Es él; don Mendo,
sin duda.)


     FROILÁN.– Va de mesnada en mesnada
en unión de tres judías
y dos moras de Granada;
que bailan, mientras que él
recita alguna balada.
Y diz, que una de las moras,
la que Azofaifa es llamada,
sabe de augurios y hechizos
y fabrica una pomada
que aunque al verla se os antoja
vaselina boricada,
es pomada milagrosa,
pues con una pincelada
torna al anciando en adulto
y a la nieve en llamarada.


     MANFREDO.– (Mirando hacia la derecha.)
Ved, Froilán, ya se columbra
el tropel por la cañada.


     MONCADA.– Es verdad. El Rey se acerca,
se ve su enseña morada
junto a los verdes pendones
del Privado y la Privada.
¿Vamos, señores?


     FROILÁN.– Sí, vamos,
señor Marqués de Moncada. (Se van por la derecha último término.) (Por el primer término de la izquierda entran en
escena don Mendo, Azofaifa, Rezaida, Aljalamita, Raquel, y Ester. Las dos primeras son moras; las tres últimas judías;
don Mendo viene afeitado y disfrazado de juglar.)


                                                          53
     MENDO.– (Por la tienda de la izquierda.)
Aquí ha de hospedarse el Rey.
Hagamos alto aquí mesmo,
que si en su honor se hacen fiestas
como dicen, y yo espero,
vamos a sacar tajada
y bien gorda, vive el cielo.
Ester y tú, Aljalamita,
por ese camino estrecho
avanzad, y dadme aviso
de cuando el Rey y su séquito
se avecine. (Hacen mutis por la derecha Ester y Aljalamita.)
Tú, Rezaida
acércate al arroyuelo
y lávate barba y boca,
porque después del almuerzo
no lo hiciste y tienes manchas
de chorizamen y huevo. (Vase Rezaida por la izquierda.)
Raquel, haz tú otra tomita
y remienda el roto velo,
que para danzar la rumba
puede hacer falta.


     RAQUEL.– Al momento. (Mutis por la derecha.)


     MENDO.– Y tú, Azofaifa, averigua
si al Barón de Vasconcello
plació la silva que ayer
dediqué a sus mesnaderos. (Azofaifa no se mueve.)
¿No me escuchaste, Azofaifa?
¿No obedeces?


     AZOFAIFA.– (Resuelta.) ¡No obedezco!


     MENDO.– ¡Cielos, qué fue lo que oí!
¡Azofaifa!... ¿Qué es aquesto!


     AZOFAIFA.– Aquesto es, Renato, que muero de amores;
aquesto es, Renato, que muero de celos.
Aquesto es que anhelas restar aquí olo
para hablar con ella... ¡No niegues aquesto!


                                                          54
Que yo sé, Renato, que aquesta es la tienda
del noble Privado, del Duque don Pero,
y sé que a su esposa tú adoras, Renato.


     MENDO.– ¡Mientes, Azofaifa!... ¡Mientes, sí!...


     AZOFAIFA.– No miento.
La quieres, la adoras, suspiras por ella,
la nombras dormido, la buscas despierto.
Magdalena, dices, al abrir los ojos,
Magdalena, dices, al rendirte al sueño.
Y hasta hace unas horas, cuando en la hostería
te desayunabas, pediste al hostero
en vez de ensaimada, una magdalena,
y eso fue una daga que horadó mi pecho.


     MENDO.– (Mirándola con profundísima pena.)
¡Pobre morabita, nieta de Mahoma,
fuego de mi nieve, nieve de mi fuego,
luminar lejano de mi eterna noche,
rosa que perfumas en mi campo yermo!...
¿Qué traidora mano vertió en tus entrañas
la negra semilla de los tristes celos?


     AZOFAIFA.– Mis ojos, Renato, que vieron los tuyos
y vieron los suyos y en ambos leyeron.
¡Ella te idolatra!


     MENDO.– ¿Qué dices?


     AZOFAIFA. ¡Te adora!
¡Lo he visto en sus ojos!


     MENDO.– (Si tal fuera cierto,
qué hermosa venganza matalla de amores.)


     AZOFAIFA.– Y tú...


     MENDO.– Calla, calla, ¿qué sabes de eso?


     AZOFAIFA.– ¿Por qué me engañaste? ¿Por qué me dijiste
que en ti los amores y la fe habían muerto?


                                                         55
¿Por qué me dijiste que esos labios rojos
que me vuelven loca, no darían más besos?
¿Por qué me dijiste que tus ojos claros
nunca mirarían con loco deseo?
¿Por qué me dijiste que no me abrazabas
porque las traiciones tanto mal te hicieron,
que en huelga tranquila de brazos caídos
tus brazos nervudos por siempre cayeron?
¿Por qué me engañaste, Renato? Responde.
Ya ves que, llorando, mis penas te cuento. (Cae de rodillas, llorando.)


      MENDO.– (Conmovido, poniéndole una mano sobre la cabeza.) ¡Mora de la morería!...
¡Mora que a mi lado moras!....
¡Mora que ligó sus horas
a la triste suerte mía!...
¡Mora que a mis plantas lloras
porque a tu pecho desgarro!...
¡Alma de temple bizarro!
¡Corazón de cimitarra!
¡Flor la más bella del Darro
y orgullo de la Alpujarra!...
¡Mora en otro tiempo atlética
y hoy enfermiza y escuálida,
a quien la pasión frenética
trocó de hermosa crisálida
en mariposa sintética!...
¡Mora digna de mi amor,
pero a quien no puedo amar
porque a un hálito traidor
heló en mi pecho la flor
aun antes de perfumar!... (Levantándola.)
Deja de estar en hinojos.
Cese tu amargura congoja,
seca tus rasgados ojos
y déjame que te acoja
en mis brazos, sin enojos. (Le abraza.)
No celes, que no es razón
celar, del que por su suerte
en una triste ocasión
por escapar de la muerte
dejó en prenda el corazón.
No cele del desgraciado


                                                           56
que sin merecer reproche
fue vilmente traicionado
y cambióse en media noche
por no ser emparedado.
Ni a ti ni a nadie ha de amar.
Déjame a solas pensar
sentado en aqueste ripio,
sin querer participar
del dolor que participio.
Déjame con mi revés:
si quieres besarme, bésame,
consiento por esta vez,
pero déjame después.
Déjame, Azofaifa, déjame.


     AZOFAIFA.– (Arrodillándose ante él y besándole la mano.)
Adiós, mi amor, mi destino, asesino peregrino
de mi paz y mi sosiego.
Adiós, Renato divino.


     MENDO.– Adiós, adiós. Hasta luego.


     AZOFAIFA.– (Haciendo mutis por la izquierda primer término.) (De quien causó su quebranto
y le fizo llorar tanto,
he de vengarme colérica.) (Vase.)


     MENDO.– (Viéndola ir, con cierta lástima.)
(La infeliz es una histérica
que no sé cómo la aguanto.) (Sentándose.)
¿Pero lo que me indicó
de Magdalena, será
una ilusión suya o no?
Si eso fuera cierto... ¡oh!
Si se confirmara... ¡ah!
Que de estar enamorada
mi venganza tendría efeto,
pues que podría, discreto,
herirla de una balada
y matalla de un soneto.
Y debe ser cierto, sí,
porque siempre que me ve
me mira de un modo que


                                                      57
parece como que se
face pedazos por mí.
¡Ironías de la suerte:
la que condenóme a muerte
y te arrojó de sus brazos,
agora sin conocerte
se muere por tus pedazos! (Queda pensativo, con la frente apoyada en el índice de la mano diestra.) (Por la derecha
último término, entran en escena Magdalena y doña Ramírez.)


     MAGDALENA.– ¿Es él?


     RAMÍREZ.– El es.


     MAGDALENA.– ¡Ya era hora!


     RAMÍREZ.– Sin duda alguna os acecha...


     MAGDALENA.– Doña Ramírez.


     RAMÍREZ.– Señora.


     MAGDALENA.– Dejadme con él agora.


     RAMÍREZ.– Pues buena mano derecha. (Haciendo el mutis.)
(Hoy quien priva es el poeta
de las baladas divinas,
y ayer privaba un atleta...
¡Infeliz! Es más coqueta
que las clásicas gallinas.) (Entran en la tienda.)


     MAGDALENA.– (A don Mendo.) Trovador, soñador,
un favor.


     MENDO.– ¿Es a mí?


     MAGDALENA.– Sí, señor.
Al pasar por aquí
a la luz del albor
he perdido una flor.


     MENDO.– ¿Una flor de rubí?



                                                          58
     MAGDALENA.– Aun mejor:
un clavel carmesí.
Trovador.
¿No lo vio?


     MENDO.– No le vi.


     MAGDALENA.– ¡Qué dolor!
No hay desdicha mayor
para mí,
que la flor que perdí,
era signo de amor.
Búsquela,
y si al cabo la ve,
démela.


     MENDO.– Buscaré,
mas no sé si sabré
cuál será.


     MAGDALENA.– Lo sabrá,
porque al ver la color
de la flor
pensará
¿seré yo
el claverl carmesí
que la dama perdió?


     MENDO.– ¿Yo decís?


     MAGDALENA.– Lo que oís,
que en aqueste vergel
cual no hay dos,
no hay joyel ni clavel
como vos.


     MENDO.– Quedad, señora, con Dios.


     MAGDALENA.– ¿Por mi desdicha os molesto,
os importuno y agravo?




                                                59
     MENDO.– No, señora, no es aquesto:
es que cual flor, soy modesto
y me estáis subiendo el pavo.


     MAGDALENA.– ¿Es que tal mal expreséme,
doncel, que no comprendióme?
¿No miróme? ¿No escuchóme?
¿Tan poco afable mostréme
que apenas vióme ya odióme?


     MENDO.– Escuchéla y contempléla,
vila, señora, y oíla;
pero cuando más miréla
y cuanto más escuchéla,
menos, señora, entendila.
¿Quién sois que venís a mí,
a un errante trovador,
y me comparáis así
con un clavel carmesí
que es signo de vuestro amor?


     MAGDALENA.– Trovador a quien adoro:
soy la Duquesa de Toro,
la más rica de Alcover.
Tengo en mi casa un tesoro:
para amarme, ¿queréis oro?


     MENDO.– ¿Para qué lo he de querer
si el oro no da placer?


     MAGDALENA.– Trovador de baja grey,
soy yo la amante del Rey,
la que reina por amor.
Mi capricho es siempre ley.
¿Quieres ser Duque o Virrey?


     MENDO.– Honor que otorga el favor,
¿para qué si no es honor?


     MAGDALENA.– (Cada vez más loca.)
Trovador, soy muy hermosa,
mi piel es pulida rosa


                                              60
que goce y perfume da.
Soy volcánica y mimosa,
tómame y hazme dichosa.


     MENDO.– ¿Quién habla de goces ya
si el goce la muerte da?


     MAGDALENA.– Hombre de hielo, que así
responde a mi frenesí,
¿dónde tu acento escuché?
¿En dónde tus ojos vi?
¿Dónde la tu voz oí?


     MENDO.– No sé, señora, no sé,
ni do os vi, ni do os hablé. (Adoptando una postura gallarda.)
Algún fantasma está viendo
vuestro cerebro exaltado.


     MAGDALENA.– (Retrocediéndose horrorizada.)
¡No, sí, no, sí, no!... ¡¡Don Mendo!! (Reponiéndose.)
(¡Pero qué estoy yo diciendo?
¡Don Mendo está emparedado!)
Perdonad. Tuve un repente,
mas ya pasó, por ventura.
Sin duda la calentura
trajo de pronto a mi mente
el recuerdo, la figura
de un ladrón, de un perdulario,
de un Marqués estrafalario,
que, aunque noble y de Sigüenza,
por robar como un corsario,
murió como un sinvergüenza.


     MENDO.– Si me quisierais contar
esa historia, gran señora,
pudiérola yo glosar.


     MAGDALENA.– Luego, que no hay tiempo ahora.
Si la queréis escuchar,
¡bellísimo trovador!...
en la cueva de Algodor
aguardadme al dar la una;


                                                          61
que hay allí sombra y frescor
y una fuente que oportuna
saciará, sin duda alguna,
mi sed ardiente de amor.
¿Faltarás?


     MENDO.– No faltaré.


     MAGDALENA.– Gracias, mi tesoro, adiós.
Con mi dueña acudiré,
y tan en punto estaré,
que, al sentirnos, diréis vos:
«Es la una, y son las dos.»
¡Adiós, mi vida, mi fe!...
¡Adiós, mi tesoro, adiós!... (Le tira un beso y entra en la tienda de la izquierda.)


     MENDO.– (Horrorizado.) ¿Qué es eso? ¿Tiróme un beso?
(Limpiándose.)
¿Dónde, ¡ay, Dios!, el beso dióme,
y dónde quedóme impreso?
¡Pardiez! ¿Por qué fizo aquesto
y por qué me lo tiróme?
¡Trapalona! ¡Lagartona!
¡Furia, catapulta, aborto...
que de perjurio blasona,
has de ver cómo me porto;
pues esta tarde en la cueva
adonde el hado te lleva,
juro por quien fui y no soy
que he de vengarme y que voy
a dejarte como nueva.
Porque al hacer explosión
todo el odio que hay en mí,
seré para tu expiación,
no ya un clavel carmesí,
sino un clavel reventón. (Jura y se va por la derecha último término.)


     AZOFAIFA.– (Surgiendo por la izquierda.)
¡Ah! ¡No, miserable, no!...
A esa cita que te dio
no irás solo con la bella.
Habrá otra mujer en ella,


                                                             62
y esa mujer seré yo. (Se va tras de don Mendo. Por la derecha, primer término, entran en escena sigilosamente don
Lope y don Lupo.)


     LUPO.– ¡Válame el cielo, don Lope!
¡Válanme todos los santos!


     LOPE.– ¿Qué ha sucedido, don Lupo?


     LUPO.– Que don Nuño y el privado
hacia la tiendan venían
a fin de tomar descanso,
cuando al llegar a la orilla
de ese chaparral cercano
vio don Pero que su esposa
con un hombre estaba hablando.
Celoso, pretendió oilla:
detuvo a don Nuño el paso
y hoy han sabido los dos
lo que nunca sospecharon:
que la privada es capaz
de pegársela al privado
no ya con el propio Rey,
que tal pegamento, es caso
de honor para la familia,
sino con cualquier bellaco
que le recite una trova
junto a la trompa de eustaquio.


     LOPE.– ¡Pobre Toro! Tan boyante
que venía, tan ufano
con los honores que el Rey
ha un instante le ha otorgado.


     LUPO.– ¿Honores?


     LOPE.– ¿No lo sabíais?


     LUPO.– No por cierto.


     LOPE.– ¡Qué milagro!
Pues sí; por su loca audacia
y su arrojo al tomar Baños,


                                                         63
hale otorgado el honor
de poner en lo más alto
de su escudo, donde ostenta
una cruz de luengos brazos,
cinco banderillas blancas
con ribetes encarnados.


     LUPO.– ¡Cinco banderillas!


     LOPE.– Cinco:
a bandera por asalto.
Y por tomar Al-coló
y el Olivo, le ha donado
para su escudo también
aqueste lema preclaro:
«No hay barreraas para mí,
pues si hay barreras, las salto.»


     LUPO.– Aquí llegan. Reparad
cuán tristes y cabizbajos
se acercan ambos, don Lope.


     LOPE.– Y con razón, qué diablos.
Yo en el pellejo de Toro
embistiera sin reparo
desde el rey al trovador.


     NUÑO.– (A don Pero por la derecha primer término.)
¡Valor, don Pero!...


     PERO.– (A don Lupo y Lope.) ¡Dejadnos! (Se deja caer en una piedra y oculta el rostro entre las manos.)


     LUPO.– (Haciendo mutis con don Lope por la derecha, último término.) Parte el alma ver a un Toro
tan noble y tan castigado. (Vase.)


     PERO.– (Incorporándose, desalentado, tras una pausa.)
¡Qué fue, don Nuño amigo,
lo que escuché desde la vil maleza!...
¡Qué horóscopo infernal nació conmigo!
¿Por qué cayó este peso, este castigo
sobre mi corazón y mi cabeza?...
¡Ella; la blanca flor que yo estimaba


                                                         64
pura como el albor de primavera,
aprovechando mi fatal ceguera,
con éste y con el otro enredaba,
y más que blanca flor que perfumaba,
era torpe y maldita enredadera!...
¡Con lo que yo la amaba, que ella era
mi norte, mi pendón y mi bandera!...
¡Triste suerte la mía!
¿A quién sale con tal coquetería?
¿Lo imagináis tal vez?


     NUÑO.– (Tristemente.) Sale a una tía:
a mi hermana menor doña Mencia,
que dos veces casóse
y von los dos esposos divirtióse.


     PERO.– Yo fi siempre un marido comedido,
que en tal comedimiento está mi flaco.
Jamás se oyó de mí nada atrevido,
que cuando exasperaba y distraído
soltaba en su presencia cualquier taco,
procuraba al instante
disimular la frase malsonante
y saba de vocables
que eran sustitutivos de venablos.
¡Cuántas veces he dicho centellante:
«Córcholi», que es un taco italiano,
en lugar del venablo castellano!




     NUÑO.– ¿Y qué piensas hacer?


     PERO.– ¡Matalla!


     NUÑO.– ¡Calla!
Al ladrón que en su amor te sustituya
mátale, sí, porque su vida es tuya;
pero a la vil canalla
que el honor de los Mansos avasalla,
yo solo he de matar. ¡Nadie me arguya!
Mi sangre lleva, que mi sngre es suya,
y yo mesmo, su padre, he de matalla.


                                                65
     PERO.– ¡Pero si el golpe os falla...
dejaréis que a mi vez contribuya!...


     NUÑO.– Debes en caso tal, apuñalalla
y con furia de tigre rematalla
hasta que el deshonor en ti concluya.


     PERO.– (Abrazándose conmovido.)
Esa respuesta noble y bondadosa
aguardaba yo de vos y no otra cosa.
Si no escuchamos mal, es a la una
la cita de mi cónyuge.


     NUÑO.– En efeto.
Y en la cueva moruna,
lugar que por su aspeto,
se presta, ¡vive Dios!, a mi proyeto.


     PERO.– Pues la comedia acabará en tragedia.
Nos reuniremos a las doce y media
y sereno... ¡Sereno, sí, sereno,
mi honor he de librar de tanto cieno! (Trompetazos y musiquilla dentro.)


     NUÑO. (Mirando hacia la derecha.) ¡El Rey se acerca!


     PERO.– ¡El Rey!... ¡Qué desengaños!
¡Después de una amistad de tantos años
resulta que era él, mi condiscípulo,
el que en la corte me ponía en ridículo!...
Y debe amarla aún, que aunque sostiene
que viene aquí por mí, por mí no viene.
Esas son ocurrencias de retórico.
¡Viene por mi mujer!


     NUÑO.– Eso es histórico...


     PERO.– De haberlo yo sabido
no hubiera, no, don Nuño, consentido
que por premiar mi táctica certera
al tomar esos fuertes por asalto,
en el escudo de mi padre hiciera


                                                          66
insertar la inscripción de la barrera,
y luego, esto es peor, ¡ay!, me pusiera
las cinco banderillas en lo alto;
que agora me avergüenza y me mancilla
al llevar en la cruz las banderillas.


     NUÑO.– ¡Disimulo, don Pero!


     PERO.– Soy valido
y sé disimular como es debido. (La musiquilla suena ya en el último rompimiento de la izquierda y al mismo tiempo que
Magdalena y doña Ramírez salen de la tienda, entran en escena por la derecha último término los siguientes
personajes y en este mismo orden: dos heraldos, seis soldados, dos pajes, don Alfonso, doña Berenguela, Marquesa,
Duquesa, don Gil, don Suero, Moncada, Froilán, Manfredo, Girona, don Lupo, don Lope, don Mendo, Azofaifa,
Raquel, Ester, Aljalamita, Rezaida, Mori 1, Moro 2 y cuantos guerreros sean posibles. Magdalena saluda cortésmente
a los Reyes en tanto que los pajes entran en la tienda y sacan dos sillones, que ocupan doña Berenguela y don Alfonso.)


     ALFONSO.– Cese ya el atambor, que están mis nobles
canados de redobles
y yo ahito
de tanto parchear y tanto pito. (Cesa la música.) (Dirigiéndose a la Duquesa.)
Ha un momento, señora, que a tu esposo
por su mando glorioso
en esta magna empresa
le demostré gustoso
el amor que mi pecho le profesa.
A ti, noble Duquesa,
que por valles, y cúspides y oteros,
vas tras él animando a los guerreros
que te llaman « la bélica leonesa»,
cumpliendo una promesa
que hice a la Reina ayer, de sobremesa,
te nombro capitán de coraceros. (Murmullos.)
Y a tu cintura breve y torneada
yo mesmo he de ceñir mi regia espada.


     MAGDALENA.– No me estimo acreedora
a gracia tan loadora y valedora.


     BERENGUELA.– Tal merced nuestro afeto conmemora.


     MAGDALENA.– ¡Gracias, Rey y señor!... ¡Gracias, señora!...



                                                           67
     ALFONSO.– (Ciñéndole su espada.)
¿Por qué no me has escrito, vida mía?


     MAGDALENA.– (También en voz baja.)
Porque Pero me acecha noche y día.


     ALFONSO.– Luego te buscaré.


     MAGDALENA.– ¿Pero esta gente?


     ALFONSO.– Yo les daré esquinazo fácilmente. (Se separa. Don Alfonso vuelve a ocupar su sitio.)


     PERO.– (A don Alfonso.) Señor, de veras lamento
y me duele y me molesta
no poder haceros fiesta
en mi pobre campamento;
pero aunque a todos convoque
no he de hallar, porque no haile,
nadie que cante, ni toque,
ni que recite, ni baile;
que son mis garridas huestes,
huestes de recios soldados
a quienes han sin cuidados
los romances y los «tuestes».


     BERENGUELA.– ¿Pero es posible, don Pero,
que quien distraiga no haiga?


     PERO.– Señora, no hay quien distraiga.


     MENDO.– (Avanzando.) Perdonadme, caballero.


     PERO.– (Furioso.) ¡Cielos! ¿Quién osa?


     MENDO.– ¡Yo oso!


     ALFONSO.– ¡Un trovador!


     MONCADA.– (¿Qué estoy viendo?
Es él, don Mendo ¡Don Mendo!...)




                                                        68
     BEREBGUELA.– (Calándose los impertinentes y mirando a don Mendo con codicia.) (¡Qué trovador tan
hermoso!)


     MENDO.– Rey de Castilla y León,
si tu permiso me dieras,
yo trovara una canción
al son del mago danzón
de mis cinco bayaderas,


     ALFONSO.– ¿Cinco bayaderas? ¡Vaya!


     MENDO.– Vedlas, señor. (A las moras y judías que estarán tras él.)
¡Avanzad! (Las cinco saludan.)
Dudo que en Hispania haya
desde Cádiz a Vizcaya
nada mejor, Majestad.
Judías son estas tres,
y hacen tan raras estrías
con los brazos y los pies
al danzar, que raro es
no repitan las judías.
Estas otras dos son moras
de la Alpujarra, y compiten
con las otras danzadoras
de tal modo, que repiten
aunque son moras, señoras.
Si ver sus gracias quieredes
y permiso me concedes
para una trova entonar,
yo sabré, señor, pagar
con un canto tus mercedes.


     ALFONSO.– Trove, trove el trovador,
que no ha de causarme enojos.


     MAGDALENA.– (¡Es bello como una flor!)


     BERENGUELA.– (¿Qué fuego tiene en sus ojos
que ha despertado en mí amor?)




                                                        69
     MAGDALENA.– (Que no quita ojo a don Mendo.)
Doña Ramírez, le quiero;
muero por ese doncel.


     BERENGUELA.– (A don Suero, que está tras ella.)
Ese trovador, don Suero,
ha de ser mío, o me muero. (Siguen hablando.)


     AZOFAIFA.– (¡Todas se fijan en él!)


     ALFONSO.– (A don Gil, que está tras él.)
Haced que yo y Magdalena
tengamos alguna escena
antes de sonar las cuatro. (Siguen hablando.)


     BERENGUELA.– (A don Suero.) Decidle que me enajena,
decidle que le idolatro,
que a su voz me suena a trinos,
que su boca es un edén,
y que quiero, por mi bien,
verme en sus ojos divinos
antes que las cuatro den.


     GIL.– (A don Alfonso.) Yo habaré luego a la bella.


     SUERO.– (A doña Berenguela.) Satisfarás tu quillotro.


     PERO.– (A don Nuño, rugiendo de ira.)
¡Qué estrella tengo! ¡Qué estrella!
¡Cómo mira el Rey a ella!...
¡Y ella cómo mira al otro!...


     MENDO.– (Que ha estado templando su laúd.)
Templado está ya el laúd.


     ALFONSO.– Pues vuestra trova cantad.


     MENDO.– ¡Reyes, y nobles, salud!... (Al Rey.)
Para ti mi gratitud
por tu indulgencia.


     ALFONSO.– Empezad. (Música.)


                                                          70
     MENDO.– (Mientras las tres judías y las dos moras bailan, recita a compás de la música.)
Era don Lindo García
el Marqués de Fuente-Amor,
el más noble caballero
de Castilla y de León.
Sangre de reyes tenía
y sangre de rey vertió,
que fue don Lindo el que en Clunia
dio muerte al rey Almanzor.
Oro don Lindo, no había,
ni jamás en él pensó,
que el oro con valer tanto,
nunca fue el triunfo mejor
para quien pone en el puño
de su espada el corazón.


     AZOFAIFA, REZAIDA, RAQUEL, ESTER Y ALJALAMITA.– (Todas a una.)
Era don Lindo García,
el Marqués de Fuente-Amor,
el más noble caballero
de Castilla y de León.


     MENDO.– En doña Sancha Mendoza,
hija del Conde de Aldoz,
puso don Lindo los ojos,
y con los ojos su amor;
y doña Sancha una noche
a don Lindo se entregó,
porque cantóla una trova
al pie de su torreón,
y era la trova tan linda
y tan lindo el trovador,
que doña Sancha rindióse
con el do re mi fa sol.
El Conde, que no sabía
d’este enredo, concertó
la boda de doña Sancha
con Suero de Waldeflor,
qu’era valido del Rey
de Castilla y de León.
Y doña Sancha, ambicioesa


                                                        71
de riquezas y de honor,
quiso alejar a don Lindo
de su castillo de Aldoz
para casar con don Suero
con pompa y con esplendor,
que en aquel Suero veía
un remedio a su ambición.


     AZOFAIFA, REZAIDA, RAQUEL, ESTER Y ALJALAMITA.– (Todas a una.)
En doña Sancha Mendoza,
hija del Conde de Aldoz,
puso don Lindo los ojos,
y con los ojos su amor.


     MENDO.– Un collar Sancha tenía
y a don Lindo le entregó
para perdelle, y aluego
matalle sin compasión.
Que la noche que donóle
el collar, don Suero entró
por la escala que pendía
del macizo torreón
y halló a don Lindo en la estancia,
y con don Lindo luchó;
y cuando el furioso Conde,
para defender su honor,
a don Lindo y a don Suero
pidió franca explicación,
doña Sancha, la perjura,
con serena y firme voz,
confesó que por roballa
don Lindo en la estancia entró;
y como el collar tenía
de su brazo en derredor
y delatalla no pudo
porque salvalla juró,
como ladrón fue tenido
el Marqués de Fuente-Amor,
y como ladrón juzgado,
y muerto como ladrón. (Magdalena, que ha estado escuchándole nerviosísima, da un grito y cae desmayada en brazos
de doña Ramírez. Cesa la música.)



                                                       72
     PERO.– ¡Cielos! ¿Qué es esto?


     RAMÍREZ.– ¡Venid! (Acuden los pajes.)


     NUÑO.– (Acercándose.) ¿Qué sucede?


     MONCADA.– (A don Mendo, con intención.) ¡Por Satán!
Que el valiente capitán
se ha desmayado. (Don Mendo le mira, se estremece, y muy azorado le vuelve la espalda.)


     ALFONSO.– (A doña Ramírez y los pajes.) Partid.
En su tienda la dejad
con gran mesura y cuido.


     RAMÍREZ.– (Al ver que Magdalena se agita convulsa.)
(¡Hija, qué barbaridad,
y qué histérico has cogido! (Entran en la tienda, transportando a Magdalena, los dos pajes y doña Ramírez.)


     PERO.– (Severamente a don Nuño.)
El trovador ha trovado
mi casorio, caballero.
Ella es Sancha, yo don Suero
y vos el Conde menguado.
Y si es cierto, ¡vive Dios!,
que desde que me casé
hice el burro, juro que
habréis de llorar los dos.


     NUÑO.– ¿Hacéis caso de un poeta? (Siguen hablando.)


     AZOFAIFA.– (¿Qué colijo de este trance?
¿Por qué escuchando el romance
cayó con la pataleta?
¿Será acaso esa mujer
la que mató su ilusión?
Si es ella, le he de morder
la lengua y el corazón.) (Se desliza y entra en la tienda de Magdalena.)


     BERENGUELA.– (Que le anda dando vueltas a don Mendo,
comiéndosele con los ojos.)
(Yo mesma decirle quiero
que por su boca estoy loca,


                                                           73
y que el coral de su boca
ha de besarme o me muero.)


     MONCADA.– Detrás de don Mendo, que continúa en el centro de la escena con los brazos cruzados y la vista en
las nubes.)
¡Don Mendo!


     MENDO.– (Estremeciéndose.) Así no me llamo.


     MONCADA.– Vos sois don Mendo.


     MENDO.– ¡Jamás!


     BERENGUELA.– (A don Mendo, a media voz y comiéndoselo.)
¡Te amo, trovador! ¡¡Te amo!! (Se separa de él.)


     MONCADA.– Pero Mendo, ¿qué les das?


     MENDO.– (¡La Reina!... Lo estaba viendo.)


     ALFONSO.– ¡Señores, siga la danza!...


     MENDO.– (¡Qué cerca está la venganza,
la venganza de don Mendo!... (Telón.)


                                            FIN DE LA JORNADA TERCERA




                                        JORNADA CUARTA


        La escena es una gran oquedad abovedada, perteneciente a una cantera o mina abandonada. En el fondo gran
arco irregular que sirve de entrada. El telón de foro será una alegre y luminosa perspectiva de campo andaluz, con algún
que otro pino frondoso en primer término.
        Dentro ya de esta gran cueva habrá, a la derecha y en ochava, una cascada cuyas aguas corren hacia el foro.
Sobre la cascada y como a dos metros de altura un agujero sobre las rocas por el que puedan asomarse dos personas. En
primero y segundo términos del lateral derecha al arranque de dos galerías que se pierden en el lateral. Entre uno y otro
algún macizo de zarzas donde pueda ocultarse una persona. En el lateral izquierda se inician tres de estas galerías,




                                                           74
también practicables. Dichas galerías serán de altura y anchura distintas y alguna de ellas estará semioculta por los
arbustos y malezas que crecen entre los riscos. Es de día. Luz intensa en el campo.


                                                                       Al levantarse el telón entran en escena por el
                                                                foro y guardando todo género de precauciones
                                                                AZOFAIFA y ALÍ-FAFÉZ, un morazo muy mal
                                                                encarado.


     ALÍ.– ¿Qué me quieres, Azofaifa,
que a tan lejano lugar
de mi tienda me conduces?


     AZOFAIFA.– Alí-Faféz, por Alá
te suplico que me ayudes.


     ALÍ.– ¿Qué intentas, di?


     AZOFAIFA.– Castigar
a una cristiana maldita
a quien tengo por rival.


     ALÍ.– Si es cristiana, con mi brazo
puedes al punto contar;
que tanto mi pecho odia
a la infame cristiandad,
que si sangre de cristianos
corriera por el pinar
como corre por la rocas
ese puro manantial;
tal vez por lavarme en sangre
me llegaría a lavar.


     AZOFAIFA.– Mucho les odias, Alí.


     ALÍ.– Y quisiera odiarles más,
que aunque fabrico babuchas
sé de memoria que el Korán.
Dispón de mí.


     AZOFAIFA.– Sólo quiero
que oculto en el olivar
que ese camino bordea,


                                                           75
mediante alguna señal
me avises cuando se acerque
mi amor y señor el juglar
a quien sirvo.


     ALÍ.– ¿Sólo eso?


     AZOFAIFA.– ¿Sólo eso?


     AZOFAIFA.– Eso, Alí-Faféz, no más.


     ALÍ.– ¿Y la señal?


     AZOFAIFA.– Un silbido.


     ALÍ.– ¿Un silbido? ¿No creerá
que le silbo, recordando
lo mal que suele trovar?


     AZOFAIFA.– No lo creerá. Ve tranquilo.


     ALÍ.– ¿Y tú, entretando, qué harás?


     AZOFAIFA.– Entre esas piedras oculta,
afilaré mi puñal.
Marchóme, pues por aquí,
y vete, Alí, ¡por Alá! (Azofaifa hace mutis por la derecha primer término.)


     ALÍ.– ¡Cristianos!... ¡Raza maldita!...
Aunque yo os finja amistad
y os venda rojas babuchas
de orillo y de cordobán,
os desprecio y abomino!... (Viendo entrar por el foro a doña Berenguela, seguida de la Duquesa y la Marquesa.)
¡Oh, señora!... ¡Majestad!... (Se inclina hasta partirse el esternón y se va por el foro haciendo zalemas.)


     BERENGUELA.– Esta es la bella cueva que indiquéle
al lindo trovador que enloquecióme.
A recedal y yerbaluisa huele,
como su puro aliento cuando hablóme.
Quiero que aquí mi boca le revele
todo lo que su amor me reconcome,



                                                            76
y le he de conceder, ¡tanto me embarga!
No ya un cuarto de hora, una hora larga.


     DUQUESA.– Ved, señora, que acaso sea imprudente
lo que hacéis al venir a aquesta cueva.
Esa pasión satánica y vehemente
que, justo es confesallo, en vos no es nueva,
paréceme importuna.


     MARQUESA.– (Con marcado acento catalán.) Ciertamente.
Mi criterio también te lo reprueba,
que con nobles, tal vez, mas con pigmeos
no se deben tener tales flirteos.
Si el Conde de Provenza y Barcelona,
tu buen padre, a quien tanto te pareces,
viera cómo Cupido te aprisiona,
de ti renegaría cual mereces.
Repara que te juegas la corona;
que estás buscando al gato los tres pieces
y que es, ¡oh, reina!, torpe e insensato
el pretender buscar tres pies al gato.


     BERENGUELA.– No me enojes, marquesa de Tarrasa;
ya sé que no hago bien; pero el cuitado
es tan gentis, que su mirar abrasa.
¿Dónde vsite doncel más bien formado?
Mi virtud ante él muere y fracasa.
¡Pecado quiero ser si él es pecado!...
que por un beso de su boca diera
cien coronas, cien vidas que tuviera.


     MARQUESA.– Loca estás a la fe.


     BERENGUELA.– (Malhumorada.) ¡Dejadme digo!
Por estas galerías discurramos
hasta oír la señal. Venid conmigo.


     MARQUESA.– A tu servicio, Majestad, estamos.


     DUQUESA.– Despacio caminad, que me fatigo.




                                                       77
     BERENGUELA.– (Por la primera galería de la izquierda.)
Entremos por aquí. Seguidme.


     MARQUESA.– Vamos.
(En cuanto ve un doncel como una rosa
lo escoge para sí; es una ansiosa.) (Se van los tres por el sitio indicado. Por el foro entran en escena don Alfonso y
Moncada.)


     ALFONSO.– Este es el sitio, Moncada.


     MONCADA.– Bravo lugar, a fe mía;
hay en él frescor, poesía,
poca luz... y asaz velada.
Siempre te plació buscar
para tus hechos corruptos,
lugares un poco abruptos,
y no me debe extrañar;
que para amar, lo mejor
es lo más concupiscente:
al remanso de una fuente
el amor es más amor.
Y entre esto peñascos romos,
en este lugar perdido,
que semeja un bello nido
de ninfas, hadas y gnomos;
en esta penumbra grata,
bajo esta bóveda oscura,
y oyendo cómo murmura
la limpia fuente de plata,
cualquier dicho gallofero
parecerá un verso adonio;
cualquier corcova, un Petronio,
y cualquier besugo, Homero.


     ALFONSO.– Hablas, Marqués, sabiamente,
cosa nada nueva en ti.
A la que yo aguardo aquí
ha de placerle este ambiente;
que es alma de dulce albura,
rosicler de Alejandría,
toda luz, gracia y poesía,
exquisitez y ternura.


                                                            78
Un bello ser delicado
que ignora lo que es maldad.


     MONCADA.– Es... Magdalena, ¿verdad?


     ALFONSO.– La misma.


     MONCADA.– (Estás apañado.)


     ALFONSO.– Y me remuerde este exceso.
Temo que piense el marido
que por ser él mi valido
yo me he valido de eso.
Y aún más confuso me hallo,
por traicionar a mi esposa
que es dama tan virtuosa.


     MONCADA.– (Este rey es un caballo.)


     ALFONSO.– Pero cuando amor azota
y clava su dardo cruel,
lo mismo el Rey que la Sota.
Y el dardo en esta ocasión
llegó al alma tan derecho,
que no sé ya si en el pecho
tengo dardo o corazón.


     MONCADA.– Creo, señor, que viene gente.


     ALFONSO.– Aún es temprano, aguardemos,
entremos y paseemos.


     MONCADA.– Lo estimo azaz pertinente.


     ALFONSO.– Ve delante.


     MONCADA.– ¡Nunca!


     ALFONSO.– Sí.
Que si peligro o tropiezo
debes cargar con eso
antes de que me toque a mí.


                                               79
     MONCADA.– Razón tienes en verdad
pues que tu vida es sagrada.


     ALFONSO.– Pues vamos presto, Moncada.


     MONCADA.– Vamos presto, Majestad. (Hacen mutis por la izquierda último término.) (Por el foro entran en
escena, primero don Nuño y luego don Pero. Este último con la espada desenvainada.)


     NUÑO.– Pasad, don Pero, en buena hora,
y ese acero vengador
enfundad, que aún no ha llegado
al lugar de la traición
la que manchó vuestro nombre
y mi vida ensombreció.


     PERO.– (Enfundando la espada.)
¡Plegue al cielo que no tarde,
y plegue al santo patrón
San Ildefonso, que al vella
mis iras contenga yo;
que es mi cólera tan sorda
y es tan grande mi furor
que plegue a Dios, no le plegue
un golpe en el corazón
que se le rompa en pedazos!


     NUÑO.– ¡Don Pero, teneos, por Dios,
y habed calma!


     PERO.– (Despectivo.) Un padre puede,
cuando se falta a su honor,
hablar de calma; un marido
vilmente ultrajado, no
La sangre de veinte Toros
presta a mi pecho calor;
y la sangre de los veinte
pídeme con recia voz
que lave, también con sangre,
la mancha de mi blasón.




                                                        80
     NUÑO.– (Con rabia.) Si veinte fueron los Toros,
fueron pocos, vive Dios,
que para veinte, hay cien Mansos
cuya sangre llevo yo,
y los cien también me piden
que castigue ese baldón.
Comparad, Duque, quién puede
hablar más alto y mejor;
si los Toros o los Mansos:
si yo como padre o vos.


     PERO.– Me place escucharos.


     NUÑO.– ¡Basta!
Venid. Este corredor (Por la primera galería de la derecha.)
después de mil vueltas, lleva
a aquel hueco. En él los dos
podremos ver sin ser vistos,
y cuando llegue el traidor
y con la traidora hable
de trovas y de pasión
saldremos y... ¡Dios les valga!
Vamos, noble Duque.


     PERO.– ¡Allón! (Se van por la primera galería de la derecha.)


     RAMÍREZ.– (Con Magdalena por la segunda galería de la izquierda.) Gracias a Dios que se ve,
Señora, que este antro está
tan oscuro, que no sé
cómo con vos no quedé
perdida por siempre allá.


     MAGDALENA.– ¿Oscuro dices? ¡Por Dios!


     RAMÍREZ.– Permitid que en ello insista.
¿No era oscuro para vos?


     MAGDALENA.– No tal.


     RAMÍREZ.– Entonces, las dos
no tenemos igual vista.
Porque aunque anduve con flema


                                                          81
tropecé, cosa en mí rara,
y ved, señora, qué exema. (Le enseña un dedo.)


     MAGDALENA.– ¡Jesús!...


     RAMÍREZ.– No estaría tan clara
cuando me he roto una yema.
Sin duda en vos el amor
es fuego que tanto alumbra,
que ha trocado a su sabor
en albores la penumbra,
y la sombra en resplandor.
Mas yo que nunca he sabido
lo que es la dicha de amar,
porque así plugo a Cupido,
y por tanto no he tenido
ocasiones de alumbrar,
cuando a sitio oscuro voy
mi pobre infortunio labro,
pues me ocurre lo que hoy
que voy, mas segura estoy
de que al ir me descalabro. (Silbido dentro.)


     MAGDALENA.– ¡Cielos!...


     RAMÍREZ.– ¡Silbaron!...


     MAGDALENA.– ¡Qué horror!


     RAMÍREZ.– Temblor entróme al oírlo.


     MAGDALENA.– Asomaos, por favor. (Se asoma al foro doña Ramírez.)
¡Dios santo! ¿Será algún mirlo
o será un reventador?
¿Veis algo?


     RAMÍREZ.– ¡Por más que ojeo!...


     MAGDALENA.– Heme quedado de estuco,
doña Ramírez.


     RAMÍREZ.– ¡Ya veo!


                                                   82
        MAGDALENA.– ¿Y es un mirlo como creo?


        RAMÍREZ.– No señora, que es un cuco.
¡El trovado!


        MAGDALENA.– ¡Ah! ¡Por fin!
Idos.


        RAMÍREZ.– Claro está señora.
¿Qué hago yo en este trajín?


        MAGDALENA.– Aguardad sólo una hora.


        RAMÍREZ.– Aunque sean dos. A mí... plin. (Al hacer mutis por el foro, se encuentra con don Mendo y le saluda
ceremoniosamente. Vase.)


        MENDO.– Guárdeos Dios, pulida dama.


        MAGDALENA.– Y a vos, flor de la poesía,
que venís por dicha mía
adonde mi amor os llama.


        MENDO.– (Señores, valiente arpía.)


        MAGDALENA.– Gracias os doy, trovador,
por atender mi cuidado,
que es un cuidado de amor.


        MENDO.– ¿Quién pudo haberos negado,
gran señora, tal honor?


        MAGDALENA.– Pues eres asaz cortés
ven aquí, pulcro trovero;
que voy, postrada a tus pies,
a explicarte cómo es
el amor con que te quiero. (Sienta a don Mendo sobre una piedra y se arrodilla a sus pies.)
¿Has visto cómo la flor
cuando despunta la aurora
abre sus pétalos tiernos
buscando luz en las sombras?



                                                           83
Pues así mi boca busca
el aliento de tu boca.


     AZOFAIFA.– (Oculta entre los riscos y arbustos del primer término derecha.)
(Yo haré que tu boca infame
bese el polvo de tu fosa.)


     MAGDALENA.– ¿Has visto cómo los ríos
buscan el mar con anhelo
para darle cuanto llevan
porque es el mar su deseo?
Pues así mis labios buscan
los suspiros de tu pecho.


     AZOFAIFA.– (Yo arrancaré de tus labios
los suspiros con mi acero.) (Por el agujero del foro derecha, asoman don Nuño y don Pero.)


     MAGDALENA.– ¿Has visto cómo la luna
busca en el bosque frondoso
un lago de linfa clara
donde mirarse a su antojo?
Pues así mis ojos buscan
el espejo de tus ojos.


     PERO.– Este puñal, ¡vive Cristo!,
será quien tu fuego venza.
Vamos, que más no resisto.


     NUÑO.– ¿Has visto qué sinvergüenza?


     PERO.– ¡Vive Cristo, que lo he visto! (Desaparecen.)


     MENDO.– (Levantándose.) O yo mucho desvarío
o alguien en la cueva habló.


     MAGDALENA.– Dices bien. Saber ansío...


     MENDO.– Aguardadme.


     MAGDALENA.– No, bien mío.
Soy capitán; iré yo. (Hace mutis por la derecha primer término. Azofaifa se oculta.)



                                                          84
     MENDO.– (Viendo marchar a Magdalena.)
¡Aborto de Satanás!...
Dentro de poco sabrás
quién es el Marqués de Cabra,
que ahora me he dado palabra
de matarte y morirás. (Mirando hacia la izquierda primer término.)
¡Mas qué es esto! ¿Es ilusión? (Viendo entrar a la Reina.)
¡La Reina! ¡Qué situación!


     BERENGUELA.– (Cayendo a sus pies y tomándole una mano.)
¡Doncel, que eres ya mi vida,
mira a tus plantas rendida
a la Reina de León!


     MENDO.– (¡Malhaya sea la hora!...)
Alzad del suelo, señora.


     BERENGUELA.– Ante tan grande hermosura
esta ha de ser la postura
que yo adopte desde ahora.


     MENDO.– (Estaba por darla un lapo...
Todas por mí como un trapo,
y con igual pretensión...
¡Ay, infeliz del varón
que nace cual yo tan guapo!)
Alzad, porque el suelo os mancha. (La levanta.)


     PERO.– (Entrando con don Nuño, sigilosamente, por la derecha segundo término.) ¡Dejadme!


     NUÑO.– ¡No!


     PERO.– ¡Es mi revancha!


     NUÑO.– ¡A mí toca!


     PERO.– ¡Toca a mí!


     NUÑO.– ¡Quieto, que es la Reina!


     PERO.– ¡Sí!
¡La Reina! ¡Cielos, qué plancha!


                                                             85
     NUÑO.– El hierro con furia empuño.


     PERO.– Volvamos al agujero.


     NUÑO.– ¡Qué cosas se ven, don Pero!


     PERO.– ¡Qué cosas se ven, don Nuño! (Se van sigilosamente por la derecha segundo término.)


     BERENGUELA.– ¡Trovador, ámame o muero!


     AZOFAIFA.– (¡Pues agora has de morir!) (Se dispone a salir, pero al ver a la Marquesa, que entra en escena por
la izquierda primer término, se contiene.)


     MARQUESA.– (Muy asustada.) ¡Señora, acabo de oír
por aquesta galería
la voz del Rey, que decía
algo de vos! ¡Hay que huir enseguida, Majestad!


     BERENGUELA.– ¡El Rey! ¡Qué contrariedad!


     MARQUESA.– Venid, por Dios.


     BERENGUELA.– (A don Mendo.) Ya sabéis en dónde estoy.


     MENDO.– Iré a buscaros.


     MARQUESA.– ¡Pasad! (Se va por la izquierda primer término doña Berenguela. La Marquesa, mirando
rendidamente a don Mendo, dice más catalanamente que nunca.)
¡Qué preciós, Mare de Deu!
No vi duncel más hermós
ni en Sitges ni en Palamós,
ni en San Feliú... ni en Manlleu. (Vase.)


     AZOFAIFA.– (Ella vuelve: escucharé.)


     MAGDALENA.– (Entrando en escena nuevamente.)
Nada vi. Nada encontré.
Sin duda el viento zumbó
y eso fue lo que se oyó.


     MENDO.– El viento sin duda fue.


                                                        86
     MAGDALENA.– (Intentando abrazar a don Mendo.)
¡Amor de mi vida!


     MENDO.– (Sujetándola colérico.) ¡¡Basta!!
¡Que ya el furor me domina!


     MAGDALENA.– ¡Cielos!


     MENDO.– ¡Mujer asesina,
baldón de tu infame casta,
a quien mi pecho abomina!...
¡Mírame bien!...


     MAGDALENA.– (Asustada.) ¡No comprendo!


     MENDO.– ¡Pálpame aquí, es bien sencillo!... (Le lleva una mano a su coronilla.)


     MAGDALENA.– (Horrorizada.)
¿Qué toco, Dios? ¿Qué estoy viendo?
¿Tú tienes un lobanillo
como el que tenía don Mendo?...


     MENDO.– (Remangándose y enseñándole el brazo izquierdo.)
¡Mira el recuerdo sagrado
vestigios de diez combates!...


     MAGDALENA.– ¡La cicatriz! ¡Mi bocado!... (Como loca.)
¡Don Mendo! ¡Tú!... ¡No me mates!
¡No me mates!... (Cae desmayada en sus brazos.)


     MENDO.– ¡Se ha privado!


     AZOFAIFA.– (Hice bien al suponer
que era esa infame mujer
la causa de su aflicción.
¡Oh! ¡Con qué gusto he de hacer
pedazos su corazón!)


     MENDO.– Largo ya el desmayo va siendo.




                                                         87
     PERO.– (En el agujero.) ¡Ahora es ella! De ira enciendo
y a vengar mi afrenta voy.


     NUÑO.– Y yo también. (Desaparecen.)


     MAGDALENA.– (Abriendo los ojos.) ¿Dónde estoy?


     MENDO.– En brazos de don Mendo.


     MAGDALENA.– (Horrorizada.) ¡Cielos! ¡El emparedado
con vida!...


     MENDO.– ¡Al cielo le plugo!...
¡Tiemble tu pecho menguado
que don Mendo se ha tornado
de emparedado en verdugo!
¡Y vas a morir, arpía!
¡Vas a morir sin tardanza!...


     MONCADA.– (Precipitadamente, por la última galería de la izquierda.) Hiud, Marqués, por vida mía,
que el Rey llega. Tu venganza
aplaza para otro día.


     MAGDALENA.– (¡Me he salvado!) (Se parapeta tras de Moncada.)


     MENDO.– (Puñal en mano amenazando a Magdalena.) ¡Muere!


     MONCADA.– ¡Atrás!


     MENDO.– ¡Marqués!


     MONCADA.– ¡La defiendo yo!


     MENDO.– ¡Te juro que morirás!


     MONCADA.– Más tarde la matarás,
pero con mi daga, no. (Le arrebata el puñal y le señala imperiosamente la primera galería de la izquierda. Don Mendo
hace mutis por ella mordiéndose las manos.)


     MAGDALENA.– ¡Gracias, Moncada!


     MONCADA.– (Con la mayor naturalidad.) De nada.


                                                         88
     MAGDALENA.– Vuestro favor.


     MONCADA.– No es favor.


     AZOFAIFA.– (¡Un Marqués el trovador!
Azofaifa desgraciada...
¿En quién pusiste tu amor?) (Entra don Alfonso por la izquierda último término. Moncada se inclina ante él
reverenciosamente y hace mutis por el foro.)


     ALFONSO.– ¡Oh, mi gentil Magdalena!


     MAGDALENA.– ¡Oh, Rey a quien tanto amo! (Se abrazan.)


     ALFONSO.– Siervo llámame y no rey,
que de ti soy tan esclavo
que morir quisiera agora
en la cárcel de tus brazos. (Por último término de la derecha entran en escena, espada en mano, don Nuño y don Pero.)


     PERO.– ¡Pues morirás, miserable,
en sus brazos y a mis manos! (Magdalena da un grito y se separa del Rey. Éste vuelve y mira altivo a don Nuño y don
Pero, que sofocan al verle una exclamación.)


     ALFONSO.– ¡Hiéreme, Duque de Toro,
si tu valor llega a tanto! (A don Pero se le cae la espada de la mano.)


     PERO.– ¡Por el alma bendita
de mi abuelo el conde Alarco!
¡Por lo huesos de mis padres,
que fueron huesos de santo!...
¡Por los dioses de los cielos
y el satanás de los Antros!...
¡Por las parcas guadañudas
y los monstruos y los trasgos,
que no sé cómo mis ojos
para siempre se cegaron
antes que ver lo que han visto
para su vergüenza y daño!...
¡Vos dando coba a mi esposa!
¡Vos mi escudo baldonando!
¡Vos, don Alfonso, mi Rey,
haciendo a mi honor agravio!...


                                                            89
¡Vos, a quien di en cuatro meses
cien pueblos, cuatro condados
y la sangre de mis venas
que derramé al tomar Baños!...
¡Ah, no! No es de rey tal hecho,
ni aun es siquiera de hidalgo;
el que como vos procede,
Majestad, es un villano.


     ALFONSO.– ¡Detén, don Pero, la lengua
y detenga yo mi brazo,
porque de no detenello,
vive Dios, que te la arranco!


     PERO.– Nada puedo contra vos,
que estáis, Alfonso, muy alto:
pero no quiero tampoco
vivir por vos deshonrado,
y antes que servir de burla,
de befa, mofa y escarnio,
ya que no puedo vengarme
de tal perfidia me mato. (Saca una daga.)
¡Mirad cómo muere un Toro
por vos mismo apuntillado! (Se clava la daga cae en brazos de don Nuño. Todos lanzan un grito de horror.)


     NUÑO.– ¡¡Cielos!!


     MAGDALENA.– ¡¡Qué horror!!


     PERO.– (Agonizando.) ¡¡Magdalena!!
¡¡Yo te maldigo!!


     ALFONSO.– ¡¡Qué espanto!!


     MAGDALENA.– ¡¡Don Pero!!


     NUÑO.– ¡¡Atrás, miserable!! (Don Pero hipa, ronca, se retuerce, se estremece y la diña.)
¡¡Muerto!!


     MAGDALENA.– ¡¡Muerto!!


     ALFONSO.– ¡Desgraciado!


                                                         90
     NUÑO.– Feneció como un valiente.


     ALFONSO.– ¿Mas con un solo pinchazo?...


     NUÑO.– El pinchazo, Majestad,
estaba en todo lo alto.


     ALFONSO.– ¿Pero quién pudo decirle?...
¿Quién pudo, di, traicionarnos?
¿Lo sabes tú?


     MAGDALENA.– ¡Sí lo sé!


     ALFONSO.– ¿Quién fue? Responde...


     MAGDALENA.– Renato;
ese trovador maldito
que de mí está enamorado,
y como yo despreciéle
llevó tal venganza a cabo.
¡Por el amor que me tienes,
oh, Rey don Alfonso, mátalo!


     NUÑO.– ¡Calla, hija maldita!


     MAGDALENA.– ¡Padre!


     NUÑO.– ¡Maldita, sí!


     ALFONSO.– ¡Reportaos!


     NUÑO.– Como padre, Rey Alfonso,
puedo, por mi honor velando,
castigar a la perjura
que mi nombre ha deshonrado.
Esa pérfida, sabello,
hora es ya de confesallo,
burló a su esposo con vos,
os burló a vos con Mendaro,
a Mendaro con el Conde
de Velilla de Montarco.


                                               91
Ella citó al trovador
aquí mesmo, y en sus brazos
cayó rendida ha un instante.
Ved, señor, si bien no hago
castigando sus traiciones
y su infamia castigando.


     MAGDALENA.– ¡Miente, Alfonso!


     AZOFAIFA.– ¡Que es tu padre!


     MAGDALENA.– ¡Miente mi padre cuitado!
¡Por nuestro amor te lo juro!


     NUÑO.- (Espada en mano queriendo matarla.) ¡Ah, miserable! ¡Quitaos!


     ALFONSO.– (Cubriendo con su cuerpo el de Magdalena.) ¡¡Quieto!! (Saca su espada.)


     NUÑO.– (Furioso.) ¡Rey, que no respondo!


     AZOFAIFA.– ¡Basta!


     NUÑO.– ¡No!


     ALFONSO.– ¡Don Nuño!


     NUÑO.– ¡Paso!


     ALFONSO.– ¡Es la mi dama!


     NUÑO.– ¡Pues muere!


     ALFONSO.– ¡Muere tú, desventurado! (Luchan.)


     MAGDALENA.– (Gritando hacia el foro.)
¡Socorro! ¡Doña Ramírez!... (Don Alfonso hiere a Nuño.)


     NUÑO.– ¡¡Ah!! (Se lleva una mano al pecho y deja caer la espada.)
¡¡Muero!! (Cae moribundo.)


     MAGDALENA.– (Acudiendo a él como loca.) ¡¡Padre!!



                                                          92
     ALFONSO.– (Horrorizado.) ¡Dejadlo!


     NUÑO.– (Agonizando.) ¡Maldita!... ¡¡Maldita seas!! (Muere.)


     MAGDALENA.– ¡¡Me maldijo!!... ¡¡Cielo santo!! (Queda arrodillada junto al cadáver de don Numo.) (Por el
foro entran precipitadamente doña Ramírez, Moncada y Alí-Faféz.)


     MONCADA.– ¿Qué sucede?


     RAMÍREZ.– ¡Magdalena!...
¡Cielos! ¿Privado el Privado?


     MONCADA.– ¡Majestad!


     ALFONSO.– ¡Moncada amigo!


     RAMÍREZ.– (Cayendo de rodillas al lado de Magdalena.)
¡Conde!... ¡Don Nuño!... ¡¡Mi amo!!


     ALÍ.– ¡Muertos lo dos!!


     MONCADA.– ¡Ambos muertos!


     ALFONSO.– ¡Dios lo quiso!


     MONCADA.– ¡Sea loado!


     AZOFAIFA.– (Surgiendo de repente puñal en mano.)
¡Rey de Castilla y León,
Rey asesino y tirano
que con espada o sin ella
das muerte a Toros y Mansos!...
¡Por Alá que es el Dios mío,
por el Dios de los cristianos,
por doña Urraca, tu madre,
que fue de virtud dechado,
y por Raimundo Borgoña,
tu padre, juro y declaro,
que es verdad cuanto te dijo
ese viejo infortunado,
espejo de nobles frentes
y de pechos fijosdalgos!


                                                        93
Esa mujer, mal nacida,
es la pérfida que antaño
para casar con don Pero
engañó a don Mendo.


     MAGDALENA.– (Levantándose.) ¡Falso!


     AZOFAIFA.– Don Mendo es el trovador
a quien ella ha denunciado
vilmente, porque le teme.


     MAGDALENA.– ¡Calla, víbora!


     AZOFAIFA.– ¡No callo!


     MAGDALENA.– ¿Sales de la zarza, mora,
para cebarte en mi daño?


     AZOFAIFA.– Salgo para hacer justicia,
y he de hacella por mi mano.


     ALFONSO.– Prueba, mora, lo que dices,
y si no logras probarlo,
el verdugo tu cabeza
cortará de un solo tajo.


     AZOFAIFA.– ¡Yo lo probaré!


     ALFONSO.– ¡Aquí mesmo!


     AZOFAIFA.– Aquí mesmo, Rey menguado,
que al calor de mi conjuro
hará la Parca un milagro. (Revolviéndose y trazando en el aire con su puñal líneas y signos.)
¡¡Alcalajá, salujó!!
¡Belimajé, tajalí!!
¿Es ella culpable?


     NUÑO y PERO.– (Incorporándose como movidos por un resorte y diciendo lúgubremente, sin abrir los ojos.)
¡¡Sí!!


     AZOFAIFA.– ¿Debo perdonalla?



                                                           94
     NUÑO y PERO.– (Como antes.) ¡¡No!! (Vuelven a tumbarse. Todos retroceden horrorizados.)


     AZOFAIFA.– (Clavando su puñal en el pecho de Magdalena.) ¡Baldón de mujeres, muere!


     MAGDALENA.– ¡Ay, mi madre; muerta soy! (Cae en brazos de don Alfonso, que cuidadosamente la deposita en
el suelo. Doña Ramírez sofoca también un grito y cae en brazos de Alí-Faféz, que también la deja en el suelo como sin
vida.)


     MONCADA.– (A Azofaifa.) ¡A segar tu cuello voy!


     AZOFAIFA.– ¡Hiere, castellano, hiere!


     ALFONSO.– ¡¡Mi Magdalena!!.. ¡¡Qué horror!!
¡Muerta!... ¡Magdalena mía!


     MONCADA.– (A don Alfonso.) Oigo en esa galería
de unas voces el rumor.
¡Ocultaos!


     ALFONSO.– ¡Ay de mí!
¡Qué horrible trance, Marqués!


     MONCADA.– Cierta mi sospecha es;
el ruido viene hacia aquí...
¡Pronto!


     ALFONSO.– ¡Vamos!


     MONCADA.– ¿Quién será? (Medio se ocultan en el momento en que entran en escena, por la primera galería de
la izquierda, doña Berenguela con don Mendo, seguidos de la Marquesa y la Duquesa. Doña Berenguela y don Mendo
vienen del brazo, y derretidísimos.)


     MENDO.– Berenguelilla, tutéame,
y si te place, osculéame,
en las dos mejillas.


     ALFONSO.– (Surgiendo lívido.) ¡¡Ah!!
¡¡Miserable!!


     MENDO.– ¡¡Cielos!!


     BERENGUELA.– ¡¡Oh!! (Cae desmayada y acude a sostenerla la Marquesa y la Duquesa.)


                                                          95
     MENDO.– (¡El Rey don Alfonso, sí!)


     ALFONSO.– ¡Mátalo, Moncada!...


     AZOFAIFA.– (Resguardándolo con su cuerpo.) ¡No!
¡Primero, Marqués, a mí!


     MENDO.– ¡Azofaifa!...


     AZOFAIFA.– ¡Mendo amado!
¡Mira!


     MENDO.– ¡Sangre! ¡Dios clemente!...


     AZOFAIFA.– A la que nubló tu frente
con esta daga he matado.


     MENDO.– (Como loco.) ¡Magdalena!... ¡Nuño!... ¡Pero!...
¿Qué has hecho, maldita mora!
¿En quién me vengo yo ahora?


     AZOFAIFA.– ¡Clava en mis carnes tu acero!...
¡Sacia tu venganza en mí
si nos has de quererme ya!
¡Hiere, Mendo, por Alá!


     MENDO.– ¡Qué por Alá; por aquí! (Le clava el puñal. Cae Azofaifa muerta.)


     MONCADA.– ¡Otra muerte! ¡Cielo santo!


     MENDO.– (Riendo locamente.) ¡Ja, ja, ja, ja, ja, ja, ja!...


     MONCADA.– ¡La razón perdido ha!


     ALFONSO.– ¡Qué espanto, Marqués, qué espanto!


     FROILÁN.– (Dentro.) Majestad.


     ALFONSO.– Aquí, Velloso.


     FROILÁN.– (Entrando por el foro con don Lope, don Lupo, Manfredo, don Gil, etc.) ¿Qué es aquesto?


                                                             96
     MONCADA.– ¡Un panteón!


     ALFONSO.– (Por don Mendo.) ¡Sujetadle!


     MENDO.– ¡Fuera ocioso!
¡Ved cómo muere un león
cansado de hacer el oso! (Se clava el puñal y cae en brazos de Moncada y de Froilán.)


     MANFREDO.– ¡Qué puñalada!


     MONCADA.– ¡Tremenda!
¡Infeliz, se está muriendo!


     MENDO.– (Agonizando.) Sabed que menda... es don Mendo,
y don Mendo... mató a menda. (Muere.) (Telón)


                                                FIN DE LA CARICATURA




                                                         97

