package Foo::bar;
use base 'Foo';
use strict;
use warnings;

sub index :Index { shift->print("Foo::bar's index") }

sub moo :Action { shift->print('cows go moo') }
sub mood :ActionMatch { shift->print('cows go moo') }

1;
