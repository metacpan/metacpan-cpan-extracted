package GOBO::Formula;
use Moose;
use strict;
with 'GOBO::Attributed';
with 'GOBO::Identified';

has text => ( is=>'rw', isa=>'Str' );
has language => ( is=>'rw', isa=>'Str' ); # TODO - enum
has associated_with => ( is=>'rw', isa=>'GOBO::Node' );

=head1 NAME

GOBO::Formula

=head1 SYNOPSIS

=head1 DESCRIPTION

(Advanced OBO ontologies only)

Formulas have the roles GOBO::Attributed and GOBO::Identified. This
means they can have metadata attached. For example, who made the
formula and when.

=cut

1;
