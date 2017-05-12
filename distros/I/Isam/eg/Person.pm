package Person;

use strict;
use vars qw(@ISA $kd_nom_prenom $kd_prenom_nom);

use IsamData;
@ISA = qw(IsamData);

my $FIELDS = { 
	nom 		=> [ 'TXTz',	0,  21 ],
	prenom		=> [ 'TXTz',	21, 21 ],
	tel		=> [ 'TXTz',	42, 21 ]
};

sub LENGTH { 63 }; 
sub FIELDS { $FIELDS };

$kd_nom_prenom = new Keydesc;
$kd_nom_prenom->k_flags( &ISNODUPS );
$kd_nom_prenom->k_nparts(  2 );
$kd_nom_prenom->k_part( 0, [  0, 21, &CHARTYPE ] );
$kd_nom_prenom->k_part( 1, [ 21, 21, &CHARTYPE ] ); 

$kd_prenom_nom = new Keydesc;
$kd_prenom_nom->k_flags( &ISNODUPS );
$kd_prenom_nom->k_nparts(  2 );
$kd_prenom_nom->k_part( 0, [ 21, 21, &CHARTYPE ] );
$kd_prenom_nom->k_part( 1, [  0, 21, &CHARTYPE ] ); 


