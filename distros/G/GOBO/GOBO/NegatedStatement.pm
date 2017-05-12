package GOBO::NegatedStatement;
use Moose;
use strict;
use GOBO::Statement;
use Moose::Util::TypeConstraints;

coerce 'GOBO::NegatedStatement'
    => from 'GOBO::Statement'
    => via { new GOBO::NegatedStatement(statement=>$_) };

has 'statement' => (is=>'ro', isa=>'GOBO::Statement',handles=>qr/.*/);
1;
