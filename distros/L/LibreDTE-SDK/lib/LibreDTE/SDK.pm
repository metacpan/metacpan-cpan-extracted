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
# SDK para conectar una aplicación en Perl con LibreDTE
# @author Esteban De La Fuente Rubio, DeLaF (esteban[at]sasco.cl)
# @version 2017-02-20
#

package LibreDTE::SDK;

use 5.024001;
use strict;
use warnings;
use REST::Client;
use JSON;
use MIME::Base64;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use LibreDTE::SDK ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

# Constructor de la clase principal del SDK
# @param hash Hash de autenticación del usuario
# @param host Host con la dirección web base de LibreDTE
sub new {
    my $class = shift;
    my $hash = shift;
    my $host = shift;
    my $self = {};
    bless($self, $class);
    $self->{hash} = $hash;
    $self->{host} = $host;
    $self->{rest} = REST::Client->new();
    $self->{rest}->setFollow(1);
    $self->{rest}->addHeader('Authorization', 'Basic '.encode_base64($hash.':X'));
    return $self;
}

# Método que consume un servicio web de LibreDTE a través de POST
# @param api Recurso de la API
# @param data Datos que se enviarán por POST
sub post {
    my $self = shift;
    my $api = shift;
    my $data = shift;
    my $data_json;
    if (ref($data) eq 'HASH') {
        $data_json = encode_json($data);
    } else {
        $data_json = $data;
    }
    $self->{rest}->POST($self->{host}.'/api'.$api, $data_json);
    my %response = (
        code => $self->{rest}->responseCode(),
        body => $self->{rest}->responseContent()
    );
    return \%response;
}

# Método que consume un servicio web de LibreDTE a través de GET
# @param api Recurso de la API
# @todo Armar query por GET con parámetro 'data'
sub get {
    my $self = shift;
    my $api = shift;
    $self->{rest}->GET($self->{host}.'/api'.$api);
    my %response = (
        code => $self->{rest}->responseCode(),
        body => $self->{rest}->responseContent()
    );
    return \%response;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!
=encoding UTF-8

=head1 NAME

LibreDTE::SDK - SDK para conectar una aplicación en Perl con LibreDTE

=head1 SYNOPSIS

  use LibreDTE::SDK;  
  my %dte = ( ... ); # datos del DTE en formato estándar SII
  my $LibreDTE = LibreDTE::SDK->new($hash, $url);
  my $emitir = $LibreDTE->post('/dte/documentos/emitir', \%dte);
  my $generar = $LibreDTE->post('/dte/documentos/generar', $emitir->{body});

=head1 DESCRIPTION

Este SDK facilita la conexión entre una aplicación escrita en Perl y los
servicios web de LibreDTE. Además provee ejemplos básicos para empezar a
realizar la integración entre tu aplicación y el software de facturación.

Aplicación web oficial de LibreDTE en https://libredte.cl

=head1 SEE ALSO

Encuentras más información sobre el proceso de integración en:

  - https://wiki.libredte.cl/doku.php/sowerphp/api
  - https://doc.libredte.cl/api

Si tienes consultas puedes realizarlas en nuestra lista de correo en
https://groups.google.com/forum/#!forum/libredte o si tienes contratado
soporte personalizado directamente en https://libredte.cl/contacto/tecnico

=head1 AUTHOR

Esteban De La Fuente Rubio, DeLaF E<lt>esteban[at]sasco.clE<gt>

=head1 COPYRIGHT AND LICENSE

LibreDTE
Copyright (C) SASCO SpA (https://sasco.cl)

Este programa es software libre: usted puede redistribuirlo y/o modificarlo
bajo los términos de la GNU Lesser General Public License (LGPL) publicada
por la Fundación para el Software Libre, ya sea la versión 3 de la Licencia,
o (a su elección) cualquier versión posterior de la misma.

Este programa se distribuye con la esperanza de que sea útil, pero SIN
GARANTÍA ALGUNA; ni siquiera la garantía implícita MERCANTIL o de APTITUD
PARA UN PROPÓSITO DETERMINADO. Consulte los detalles de la GNU Lesser General
Public License (LGPL) para obtener una información más detallada.

Debería haber recibido una copia de la GNU Lesser General Public License
(LGPL) junto a este programa. En caso contrario, consulte
<http://www.gnu.org/licenses/lgpl.html>.

=cut
