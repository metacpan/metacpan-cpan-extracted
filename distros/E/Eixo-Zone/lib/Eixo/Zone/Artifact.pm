package Eixo::Zone::Artifact;

use strict;

sub new{

	return bless({}, $_[0]);
}

sub clean{

	die(ref($_[0]) . '::clean:  ABSTRACT!!!');

}

1;
