package GOBO::Bridges::Bridge;
use Moose;
use strict;
use GOBO::Graph;
use FileHandle;
use Carp;

has graph => (is=>'rw', isa=>'GOBO::Graph', default=>sub{new GOBO::Graph});



1;


=head1 NAME

GOBO::Bridges::Bridge

=head1 SYNOPSIS

=head1 DESCRIPTION

Base class for all bridges. A bridge maps between object models


=cut
