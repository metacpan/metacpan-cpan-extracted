use strict;
use warnings;

use Test::More 0.96;

use Dist::Zilla::MetaProvides::Types qw( :all );

{

  package Dist::Zilla::Role::MetaProvider::Provider;
  use Moose::Role;
}
{

  package Test;
  use Moose;
  with 'Dist::Zilla::Role::MetaProvider::Provider';
  __PACKAGE__->meta->make_immutable;
}

isa_ok( \&ModVersion,       'CODE' );
isa_ok( \&ProviderObject,   'CODE' );
isa_ok( \&is_ModVersion,    'CODE' );
isa_ok( \&is_ProviderObect, 'CODE' );
ok( is_ModVersion('1.0'),             '1.0 is a valid module version' );
ok( is_ModVersion(undef),             'undef is a valid module version' );
ok( is_ModVersion('9999'),            '9999 is a valid module version' );
ok( is_ProviderObject( Test->new() ), 'Given obeject is a ProviderObject' );

done_testing;
