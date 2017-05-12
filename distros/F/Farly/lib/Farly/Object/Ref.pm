package Farly::Object::Ref;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.26';

require Farly::Object;
our @ISA = qw(Farly::Object);

1;
__END__

=head1 NAME

Farly::Object::Ref - Reference object

=head1 SYNOPSIS

  use Farly::Object::Ref;
  use Farly::Value::String;
  
  my $object1 = Farly::Object::Ref->new();
  
  $object1->set( 'type', Farly::Value::String->new('GROUP') );
  $object1->set( 'id',   Farly::Value::String->new('id1234') );

=head1 DESCRIPTION

A Farly::Object::Ref is a reference object which refers to the identity
of one or more Farly::Objects in the same Farly::Object::List.

Farly::Object::Ref is a Farly::Object. 

=head1 COPYRIGHT AND LICENCE

Farly::Object::Ref
Copyright (C) 2013  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
