use strict;
use warnings;

use Test::More tests => 1;
use Test::DZil qw( simple_ini Builder );

# ABSTRACT: Make sure plugins do what they say they'll do

require Moose;
require Dist::Zilla::Role::Plugin;
require Dist::Zilla::Plugin::Bootstrap::lib;
require Dist::Zilla::Plugin::GatherDir;
require Dist::Zilla::Plugin::MetaConfig;

my $pn  = 'TestPlugin';
my $fpn = 'Dist::Zilla::Plugin::' . $pn;

my $files = {};
$files->{"source/dist.ini"} = simple_ini( ['Bootstrap::lib'], ['GatherDir'], ['MetaConfig'], [$pn], );
$files->{"source/lib/Dist/Zilla/Plugin/${pn}.pm"} = <<"EOF";
package $fpn;

use Moose qw( has around with );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );
with 'Dist::Zilla::Role::Plugin';

has 'attr' => ( is => 'ro', 'lazy' => 1, default => sub { 'I have value, my life has meaning' } );

around dump_config => config_dumper({});

__PACKAGE__->meta->make_immutable;
no Moose;

1;
EOF

my ( $t, $error );
{
  local $@;
  eval {
    $t = Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } );
    $t->chrome->logger->set_debug(1);
    $t->build;
    1;
  } or $error = $@;
}
isnt( $error, undef, 'Ref == bang' );
