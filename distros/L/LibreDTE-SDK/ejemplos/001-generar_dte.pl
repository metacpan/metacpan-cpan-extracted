#
# LibreDTE
# Copyright (C) SASCO SpA (https://sasco.cl)
#
# Este programa es software libre: usted puede redistribuirlo y/o modificarlo
# bajo los términos de la GNU Lesser General Public License (LGPL) publicada
# por la Fundación para el Software Libre, ya sea la versión 3 de la Licencia,
# o (a su elección) cualquier versión posterior de la misma.
#
# Este programa se distribuye con la esperanza de que sea útil, pero SIN
# GARANTÍA ALGUNA; ni siquiera la garantía implícita MERCANTIL o de APTITUD
# PARA UN PROPÓSITO DETERMINADO. Consulte los detalles de la GNU Lesser General
# Public License (LGPL) para obtener una información más detallada.
#
# Debería haber recibido una copia de la GNU Lesser General Public License
# (LGPL) junto a este programa. En caso contrario, consulte
# <http://www.gnu.org/licenses/lgpl.html>.
#

#
# Ejemplo que muestra los pasos para:
#   - Emitir DTE temporal
#   - Generar DTE real a partir del temporal
#   - Obtener PDF a partir del DTE real
# @author Esteban De La Fuente Rubio, DeLaF (esteban[at]sasco.cl)
# @version 2017-02-20
#

use strict;
use warnings;
use LibreDTE::SDK;
use JSON;

# datos a utilizar en el cliente
my $url = 'https://libredte.cl';
my $hash = '';

# documento que se desea emitir
my %IdDoc = (
    TipoDTE => 33
);
my %Emisor = (
    RUTEmisor => '76192083-9'
);
my %Receptor = (
    RUTRecep => '66666666-6',
    RznSocRecep => 'Persona sin RUT',
    GiroRecep => 'Particular',
    DirRecep => 'Santiago',
    CmnaRecep => 'Santiago',
);
my %Encabezado = (
    IdDoc => \%IdDoc,
    Emisor => \%Emisor,
    Receptor => \%Receptor
);
my %Item = (
    NmbItem => 'Producto 1',
    QtyItem => 2,
    PrcItem => 1000,
);
my @Detalle = [\%Item];
my %dte = (
    Encabezado => \%Encabezado,
    Detalle => @Detalle
);

# crear cliente
my $LibreDTE = LibreDTE::SDK->new($hash, $url);

# crear DTE temporal
my $emitir = $LibreDTE->post('/dte/documentos/emitir', \%dte);
die('Error al emitir DTE temporal: '.$emitir->{body}) if $emitir->{code} != 200;

# crear DTE real
my $generar = $LibreDTE->post('/dte/documentos/generar', $emitir->{body});
die('Error al generar DTE real: '.$generar->{body}) if $generar->{code} != 200;

# obtener el PDF del DTE
my $dte_real = decode_json($generar->{body});
my $generar_pdf = $LibreDTE->get('/dte/dte_emitidos/pdf/'.$dte_real->{dte}.'/'.$dte_real->{folio}.'/'.$dte_real->{emisor});
die('Error al generar PDF del DTE: '.$generar_pdf->{body}) if $generar_pdf->{code} != 200;

# guardar PDF en el disco
open(my $out, '>:raw', 'documento.pdf') or die "No fue posible crear el PDF: $!";
print $out $generar_pdf->{body};
close($out);
