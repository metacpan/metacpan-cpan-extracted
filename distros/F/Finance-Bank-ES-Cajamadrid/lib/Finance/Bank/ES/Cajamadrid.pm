package Finance::Bank::ES::Cajamadrid;

use strict;
use warnings;
use Carp;
use WWW::Mechanize;
our $VERSION='0.04';


# hackery for https proxy support, inspired by Finance::Bank::Barclays
# thanks Dave Holland!
my $https_proxy=$ENV{https_proxy};
delete $ENV{https_proxy} if($https_proxy);
our $browser = WWW::Mechanize->new(env_proxy=>1);
$browser->env_proxy;     # Load proxy settings (but not the https proxy)
$ENV{https_proxy}=$https_proxy if($https_proxy);

sub check_balances {
	my ($class,%opts)=@_;
	croak "Must provide a DNI number" unless exists $opts{dni};	
	croak "Must provide a PIN" unless exists $opts{pin};
	my $base="https://oi.cajamadrid.es";
	my $re='<tr><td class=oiparialgrissin><a class=enlaceverdeabajo .*?;">(\d+)&nbsp;.*?<td class=oiparialgrissin align=right>(.*?)&nbsp;Euros</td>.*?</tr>';
	my $self=bless { %opts }, $class;
	$browser->quiet(1);
	$browser->agent_alias("Windows IE 6");
	$browser->get("$base/CajaMadrid/oi/pt_oi/Login/login");
	$browser->form('f1');
	$browser->field("Documento_s", $opts{dni});
	$browser->field("ClaveAcceso_s", $opts{pin});
	my $r=$browser->submit();
	$browser->form('f_lanzar')
	        ->action("$base/CajaMadrid/oi/puente_oi?pagina=5950&tran=0");
	$r=$browser->submit();
	my $datos=$r->content;
	my @cuentas=();
	while ($datos=~m{$re}gs){
		push @cuentas,( { numero => $1,
				  saldo => $2 } );
	}
	return @cuentas;
}	
sub ver_saldos {
	my ($class,%opts)=@_;
	croak "Debe proporcionar un DNI" unless exists $opts{dni};	
	croak "Debe proporcionar un PIN" unless exists $opts{pin};	
	return &check_balances($class,%opts);
}
1;
__END__
# Documentation

=head1 NAME

Finance::Bank::ES::Cajamadrid - Check your Cajamadrid bank accounts from Perl 

=head1 SYNOPSIS

  use Finance::Bank::ES::Cajamadrid;
  my @cuentas = Finance::Bank::ES::Cajamadrid->ver_saldos(
	  dni => "xxxxxxxx",
	  pin => "****"
  );
  foreach (@cuentas) {
	  print "Cuenta: ".$_->{numero}." Saldo: ".$_->{saldo}."\n";
  }

=head1 DESCRIPTION

Check your Cajamadrid bank accounts from Perl.
It only checks balances, but future versions will allow you to do more things.
Chequea el saldo de tus cuentas en Cajamadrid con Perl.
Ahora solamente chequea saldos, pero en futuras versiones se permitiran mas cosas.
Me encantaria saber que usas el modulo! Enviame un mail!

=head2 EXPORT

None by default.

=head2 REQUIRE

WWW::Mechanize

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

=head1 SEE ALSO

Finance::Bank::*

=head1 AUTHOR

Bruno Diaz Briere C<bruno.diaz@gmx.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Bruno Diaz Briere

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
