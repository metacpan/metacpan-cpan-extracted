package Catalyst::TraitFor::Controller::Harbinger;
$Catalyst::TraitFor::Controller::Harbinger::VERSION = '0.001002';
use Moo::Role;
use warnings NONFATAL => 'all';

around auto => sub {
   my ($orig, $self, $c, @rest) = @_;

   my $env = $c->engine->env;
   my $req = $c->request;
   $env->{'harbinger.ident'} = $req->action;
   $env->{'harbinger.server'} = $c->config->{server};
   $c->model('DB')->storage->debugobj->replace_logger(
      harbinger => $env->{'harbinger.querylog'},
   );

   $self->$orig($c, @rest);
};

1;
