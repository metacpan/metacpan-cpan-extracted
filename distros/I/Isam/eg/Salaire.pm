package Salaire;

use strict;
use vars qw(@ISA);

use IsamData;
@ISA = qw(IsamData);

my $FIELDS = { 
	matricule	=> [ 'txt',	0,  10 ],
	salaire		=> [ 'txt',	10, 10 ],
};
sub LENGTH { 63 };
sub FIELDS { $FIELDS };

