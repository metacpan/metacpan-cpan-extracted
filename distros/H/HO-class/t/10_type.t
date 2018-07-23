
use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

package Host;

sub name { '127.0.0.1' }

BEGIN  {
  require HO::accessor;
  require HO::abstract;

  $HO::accessor::type{'hostname'} = sub () { Host::name };

  $HO::accessor::ro_accessor{'hostname'} = $HO::accessor::ro_accessor{'$'};
  $HO::accessor::rw_accessor{'hostname'} = sub { 
      die('Type hostname has no rw accessor.')
  }; 
};

package Network::Node;

use HO::class
  _ro => name => 'hostname',
  _index => ln => 'hostname';

package main;

my $node = Network::Node->new;
is($node->name,'127.0.0.1','dummy type - ro accessor');
is($node->[$node->ln],'127.0.0.1','dummy type - index');

eval <<__PERL__;
        package Host::RW;
        use HO::class
            _rw => 'name' => 'hostname';
__PERL__

like($@,qr/Type hostname has no rw accessor\. .*/,'rw accessor dies during class creation');

