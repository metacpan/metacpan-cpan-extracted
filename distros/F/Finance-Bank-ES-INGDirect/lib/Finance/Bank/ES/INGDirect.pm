package Finance::Bank::ES::INGDirect;

use WWW::Mechanize;
use HTML::Tree;
use Digest::MD5 qw (md5_base64);
use warnings;
use Carp;
our $VERSION='0.04';


my $inicio='https://www.ingdirect.es/WebTransactional/Transactional/AccesoClientes.asp';
my $cpin='https://www.ingdirect.es/WebTransactional/Transactional/clientes/access/Cappin.asp';
my $imagenes="https://www.ingdirect.es/WebTransactional/Transactional/clientes/images/acceso/";
my $todosdatos="https://www.ingdirect.es/WebTransactional/Transactional/clientes/position/globalinf_all_products.asp?opcion1=1&opcion2=1";

sub entra {
 my($self,$clave,$documento,$tipo,$fechan)=(@_);
 $self = {};
 bless $self;
 my ($birthDay,$birthMonth,$birthYear)=split("/",$fechan);
 my @aclave=split "",$clave;
 my %numeros;
 my %posicion;
 $numeros{2}="kGZIA+MhSDZwAJNbKPVQuw";
 $numeros{0}="/G8ZknsmSdWsGKieoJPTAQ";
 $numeros{1}="gzlcyXsBJ39n4/zwAxXcuQ";
 $numeros{6}="gbuU5oA87kDZVI/6iFHwqQ";
 $numeros{5}="oYkWYg/mzWdTQ5/tWKIbiw";
 $numeros{4}="JZvMzVSO6KoUA/F79ietTA";
 $numeros{7}="2X4WjJJmFRbvvhr/tW/n0Q";
 $numeros{3}="IgHJh1ghY+ibtkZobrCM/w";
 $numeros{8}="jTch8Vwv19eh0YgpirETiA";
 $numeros{9}="+EFFvwg3jNmSxVxk/GJt+g";
 %hashes=reverse %numeros;
 # Thanks to Dev Holland for the proxy trick
 my $https_proxy=$ENV{https_proxy};
 delete $ENV{https_proxy} if($https_proxy);
 $mech = WWW::Mechanize->new(env_proxy=>1);
 $mech->env_proxy;     # Load proxy settings (but not the https proxy)
 $mech2 = WWW::Mechanize->new(env_proxy=>1);
 $mech2->env_proxy;     # Load proxy settings (but not the https proxy)
 $ENV{https_proxy}=$https_proxy if($https_proxy);
 $mech->agent_alias('Windows IE 6');
 $mech2->agent_alias('Windows IE 6');
 $self{m1}=$mech;
 $self{m2}=$mech2;
 my $resultado=$mech->get($inicio);
 #print $resultado->content();
 $resultado=$mech->follow_link( url_regex => qr/entrada.asp/i );
 #print $resultado->content();
 my $f1=$mech->form_name('form1');
 $f1->method('POST');
 $f1->action($cpin);
 $f1->value('cbodocument',$tipo);
 $f1->value('id',$documento);
 $f1->value('birthDay',$birthDay);
 $f1->value('birthMonth',$birthMonth);
 $f1->value('birthYear',$birthYear);
 $resultado=$mech->submit_form(form_name=>'form1');
 my $texto=$resultado->content();
 #print $texto;
 my $pos=0;
 while ( $texto=~/src=....images.acceso.([^\s]*?gif). onclick/mgs) {
  my $i=$1;
  my $imagen=$mech2->get($imagenes.$i);
  my $digest=md5_base64($imagen->content());
  #print $hashes{$digest}.":".$imagenes.$i."->".$digest."\n";
  $posicion{$hashes{$digest}}=$pos;
  $pos++;
 }
 $f1=$mech->form_name('LoginForm');
 while ( $texto=~/name="txt_Pin(\d)"/mgs) {
  my $cual=$1;
  $f1->value("txt_Pin".$cual,$posicion{$aclave[$cual-1]});
 }
 $resultado=$mech->submit_form(form_name=>'LoginForm');
 $texto=$resultado->content();
 return $self;
}

sub balances {
 my ($self)=(@_);
 my $mech=$self{m1};
 my $resultado=$mech->get($todosdatos);
 #print $resultado->content();
 my $tree = HTML::TreeBuilder->new();
 $tree->parse($resultado->content());
 $tree->eof();
 $tree->elementify();
 my $datos="";
 my @elementos=$tree->look_down("_tag","td","class","negro10tablewithoutline");
 foreach my $el (@elementos) {
  if($el->as_text()=~/pciones/) {
   $datos=$datos."\n";
  }
  else {
   $datos=$datos.$el->as_text()."\t";
  }
 }
 @elementos=$tree->look_down("_tag","td","class","negro10tableline");
 foreach my $el (@elementos) {
  if($el->as_text()=~/pciones/) {
   $datos=$datos."\n";
  }
  else {
   $datos=$datos.$el->as_text()."\t";
  }
 }
 my @cuentas;
 foreach my $lin (split "\n",$datos) {
  my @t=split "\t",$lin;
  $t[2]=~s/[^\d|^,]//g;
  #print $t[2];
  push @cuentas,( { descripcion =>$t[0],
        	    numero => $t[1],
	            saldo => $t[2] } ) if defined ($t[2]) and length($t[2])>0;
 }
 return @cuentas;
}

sub ver_saldos {
 my ($class,%opts)=@_;
 croak "Debe proporcionar un Documento" unless exists $opts{documento};
 croak "Debe proporcionar una fecha de nacimiento DD/MM/AAAA" unless exists $opts{fecha_nacimiento};
 croak "Debe proporcionar un PIN" unless exists $opts{pin};
 $opts{tipo_documento}="NIF" unless exists $opts{tipo_documento};
 my %tipodoc=(NIF => 0,
              Pasaporte=> 1,
              TarjetaResidencia=> 2);
 my $cbodocument=$tipodoc{NIF};
 my $temporal=$class->entra($opts{pin},$opts{documento},$cbodocument,$opts{fecha_nacimiento});
 return $temporal->balances();
}


1;
__END__
# Documentation

=head1 NAME

Finance::Bank::ES::INGDirect - Check your INGDirect bank accounts from Perl 

=head1 SYNOPSIS

  my $nif="11111111B";
  my $fenac="12/12/1212";
  my $pin="929999";
  my @cuentas=Finance::Bank::ES::INGDirect->ver_saldos(	documento=>$nif,
  							fecha_nacimiento=>$fenac  ,
  							pin=> $pin);
  foreach (@cuentas) {
  	print "Desc: ".$_->{descripcion}." Num: ".$_->{numero}." Saldo: ".$_->{saldo}."\n";
  }

=head1 DESCRIPTION

Check your INGDirect bank accounts from Perl.
It only checks balances, but future versions will allow you to do more things.
Chequea el saldo de tus cuentas en INGDirect con Perl.
Ahora solamente chequea saldos, pero en futuras versiones se permitiran mas cosas.
Me encantaria saber que usas el modulo! Enviame un mail!

=head2 EXPORT

None by default.

=head2 REQUIRE

WWW::Mechanize
HTML::Tree
Digest::MD5

=head1 WARNING

This warning is from Simon Cozens' C<Finance::Bank::LloydsTSB>, and seems
just as apt here.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

Ten cuidado con el modulo. Examina el fuente para que veas que no hago 
cosas raras.
Pasalo a traves de un proxy para que veas que no me conecto a sitios raros.

=head1 EXAMPLES

  use Finance::Bank::ES::INGDirect;
  use Tk;
  use strict;
  
  my $main = MainWindow->new;
  $main->Label(-text => 'NIF')->pack;
  my $nif = $main->Entry(-width => 10);
  $nif->pack;
  $main->Label(-text => 'Fecha Nacimiento(DD/MM/AAAA)')->pack;
  my $fenac = $main->Entry(-width => 10);
  $fenac->pack;
  $main->Label(-text => 'PIN')->pack;
  my $pin = $main->Entry(-width => 7, -show => '*' );
  $pin->pack;
  $main->Label(-text => 'Datos')->pack;
  my $d = $main->MListbox(  -columns =>     [[-text=>'Descripcion']  ,
  					   [-text=>'Numero'],
  					   [-text=>'Saldo']]);
  $d->pack;
  $main->Button(-text => 'Conectar!',
                -command => sub{ver_saldos($nif->get, $fenac->get, $pin->get)}
                )->pack;
  MainLoop;

  sub ver_saldos {
  	my ($nif, $fenac, $pin) = @_;
  	my @cuentas=Finance::Bank::ES::INGDirect->ver_saldos(	documento=>$nif,
  								fecha_nacimiento=>$fenac,
  								pin=> $pin);
  	foreach (@cuentas) {
  		$d->insert(0,[$_->{descripcion},$_->{numero},$_->{saldo}]);
  	}
  }


=head1 SEE ALSO

Finance::Bank::*

=head1 AUTHOR

Bruno Diaz Briere C<brunodiaz@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Bruno Diaz Briere

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
