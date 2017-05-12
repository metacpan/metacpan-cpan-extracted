package Example;
use strict;
use warnings;
use Egg qw/ -Debug
  Dispatch::Fast
  Debugging
  Cache::UA
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

  VIEW=> [

    [ Template=> {
      .....
      ...
      } ],

    ],

  plugin_cache_ua => {
    cache_name  => 'FileCache',
    allow_hosts => [qw/ mydomain.name /],
    },

  plugin_lwp => {
    agent   => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
    },

  );

# Dispatch. ------------------------------------------------
__PACKAGE__->run_modes(
  cache=> {
    google => sub {
      my($e)= @_;
      $e->cache_ua->output('http://xxx.googlesyndication.com/pagead/show_ads.js');
      },
    },
  );
# ----------------------------------------------------------

1;
