=head1 NAME

GOBO::Synonym

=head1 SYNOPSIS

=head1 DESCRIPTION

An alternate label for an GOBO::Labeled object

=cut

package GOBO::Synonym;
use Moose;
use strict;
use GOBO::Node;
with 'GOBO::Attributed';

use Moose::Util::TypeConstraints;

coerce 'GOBO::Synonym'
      => from 'Str'
      => via { new GOBO::Synonym(label=>$_) };

has label => (is=>'rw',isa=>'Str');
has scope => (is=>'rw',isa=>'Str');
has type => (is=>'rw',isa=>'GOBO::Node', coerce=>1);
has lang => (is=>'rw',isa=>'Str');

1;
