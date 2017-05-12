use Test::More tests=> 66;
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;

my @files= Egg::Helper->helper_yaml_load(join '', <DATA>);

my $e= Egg::Helper->run( Vtest=> {
  create_files => \@files,
  MODEL        => [qw/ Test /],
  });

# Model manager.
can_ok $e, 'model';
can_ok $e, 'model_manager';
  ok my $m= $e->model_manager, q{my $m= $e->model_manager};
  isa_ok $m, 'Egg::Manager::Model::handler';
  isa_ok $m, 'Egg::Manager';
  isa_ok $m, 'Egg::Component';
  isa_ok $m, 'Egg::Component::Base';

can_ok $m, 'myname';
  is $m->myname, 'model', q{$m->myname, 'model'};
can_ok $m, 'default';
can_ok $m, 'regists';
  isa_ok $m->regists, 'HASH';
  isa_ok tied(%{$m->regists}), 'Tie::Hash::Indexed';
can_ok $m, 'e';
  is $m->e, $e, q{$m->e, $e};
can_ok $m, 'reset';
can_ok $m, 'context';
can_ok $m, 'reset_context';
can_ok $m, 'isa_register';
can_ok $m, 'add_register';
  can_ok $m, 'register';

can_ok $m, '_import';
can_ok $m, '_startup';
can_ok $m, '_setup';
can_ok $m, '_prepare';
can_ok $m, '_dispatch';
can_ok $m, '_action_start';
can_ok $m, '_action_end';
can_ok $m, '_finalize';
can_ok $m, '_finalize_error';
can_ok $m, '_output';
can_ok $m, '_finish';
can_ok $m, '_result';

# View manager.
can_ok $e, 'view';
can_ok $e, 'view_manager';
  ok my $v= $e->view_manager, q{my $v= $e->view_manager};
  isa_ok $v, 'Egg::Manager::View::handler';
  isa_ok $v, 'Egg::Manager';
  isa_ok $v, 'Egg::Component';
  isa_ok $v, 'Egg::Component::Base';

can_ok $v, 'myname';
  is $v->myname, 'view', q{$v->myname, 'view'};
can_ok $v, 'default';
can_ok $v, 'regists';
  isa_ok $v->regists, 'HASH';
  isa_ok tied(%{$v->regists}), 'Tie::Hash::Indexed';
can_ok $v, 'e';
  is $v->e, $e, q{$v->e, $e};
can_ok $v, 'reset';
can_ok $v, 'context';
can_ok $v, 'reset_context';
can_ok $v, 'isa_register';
can_ok $v, 'add_register';
  can_ok $v, 'register';

can_ok $v, '_import';
can_ok $v, '_startup';
can_ok $v, '_setup';
can_ok $v, '_prepare';
can_ok $v, '_dispatch';
can_ok $v, '_action_start';
can_ok $v, '_action_end';
can_ok $v, '_finalize';
can_ok $v, '_finalize_error';
can_ok $v, '_output';
can_ok $v, '_finish';
can_ok $v, '_result';


__DATA__
---
filename: lib/Egg/Model/Test.pm
value: |
  package Egg::Model::Test;
  use strict;
  use warnings;
  
  package Egg::Model::Test::handler;
  use strict;
  use base qw/ Egg::Model /;
  
  1;
---
filename: lib/Egg/View/Test.pm
value: |
  package Egg::View::Test;
  use strict;
  use warnings;
  use base qw/ Egg::View /;
  
  package Egg::View::Test::handler;
  use strict;
  use base qw/ Egg::View /;
  
  1;
