package Example;
use strict;
use warnings;
use Egg qw/ -Debug
  LWP
  Dispatch::Fast
  Debugging
  Log::Syslog
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

  plugin_syslog => { facility=> 'local3' },

  );

# Dispatch. ------------------------------------------------
__PACKAGE__->run_modes(
  _default => sub {
    my($dispatch, $e)= @_;
    $e->slog(' 403 Forbidden. ');
    $e->finished(403);
    },
  );
# ----------------------------------------------------------

1;
