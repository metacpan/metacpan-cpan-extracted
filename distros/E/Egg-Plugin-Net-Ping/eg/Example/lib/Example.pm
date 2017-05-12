package Example;
use strict;
use warnings;
use Egg qw/ -Debug
  Net::Ping
  Dispatch::Fast
  Debugging
  Log
  /;

our $VERSION= '0.01';

__PACKAGE__->egg_startup(

  title      => 'Example',
  root       => '/path/to/Example',
  static_uri => '/',
  dir => {
    lib      => '< $e.root >/lib',
    static   => '< $e.root >/htdocs',
    etc      => '< $e.root >/etc',
    cache    => '< $e.root >/cache',
    tmp      => '< $e.root >/tmp',
    template => '< $e.root >/root',
    comp     => '< $e.root >/comp',
    },
  template_path=> ['< $e.dir.template >', '< $e.dir.comp >'],

  plugin_net_ping => {
    protcol => 'tcp',
    timeout => 3,
    retry   => 1,
    wait    => 0.5,
    },

  );

# Dispatch. ------------------------------------------------
__PACKAGE__->run_modes(
  _default => sub {
    my($dispatch, $e)= @_;
    require Egg::Helper::BlankPage;
    $e->response->body( Egg::Helper::BlankPage->out($e) );
    },
  );
# ----------------------------------------------------------

1;
