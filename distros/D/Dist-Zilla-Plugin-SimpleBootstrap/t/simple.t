use v5.20;
use warnings;
use experimental qw(signatures postderef);

use Test::More;
use Dist::Zilla::Dist::Builder;
use File::ShareDir ();
use Path::Tiny;

# this is a horrible hack to work around Test::DZil localizing @INC.
# In normal use, it doesn't matter because nobody will be using this plugin in
# their tests.
my @out_INC;
BEGIN {
  my $meta = Dist::Zilla::Dist::Builder->meta;
  $meta->make_mutable;
  $meta->add_around_method_modifier('from_config', sub {
    my $orig = shift;
    my $return = $orig->(@_);
    @out_INC = @INC;
    return $return;
  });
  $meta->make_immutable;
}

use Test::DZil;

subtest "Loading using SimpleBootstrap" => sub {
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        path(qw(source dist.ini)) => simple_ini(
          [ SimpleBootstrap => ],
          [ MyPlugin => ],
        ),
        path(qw(source lib Dist Zilla Plugin MyPlugin.pm)) => <<'END_CODE',
package Dist::Zilla::Plugin::MyPlugin;
use Moose;
with qw(
  Dist::Zilla::Role::Plugin
);

1;
END_CODE
      },
    },
  );

  my ($plugin) = grep $_->isa('Dist::Zilla::Plugin::MyPlugin'), $tzil->plugins->@*;
  ok $plugin, 'plugin could be loaded';
  my $lib_dir = $tzil->root->path->child('lib')->stringify;
  ok +(grep $_ eq $lib_dir, @out_INC), 'lib directory was added';
};

subtest "With Share Dir" => sub {
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        path(qw(source dist.ini)) => simple_ini(
          { name => 'Dist-Zilla-Plugin-MySharePlugin' },
          [ SimpleBootstrap => ],
          [ MySharePlugin => ],
        ),
        path(qw(source lib Dist Zilla Plugin MySharePlugin.pm)) => <<'END_CODE',
package Dist::Zilla::Plugin::MySharePlugin;
use Moose;
use File::ShareDir qw(dist_file);
with qw(
  Dist::Zilla::Role::Plugin
);

sub share_file {
  dist_file('Dist-Zilla-Plugin-MySharePlugin', 'file.txt');
}

1;
END_CODE
        path(qw(source share file.txt)) => 'file content',
      },
    },
  );

  my ($plugin) = grep $_->isa('Dist::Zilla::Plugin::MySharePlugin'), $tzil->plugins->@*;
  ok $plugin, 'plugin could be loaded';
  ok -e $plugin->share_file, 'share dir loaded successfully';
};

subtest "With Module Share Dir" => sub {
  my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
      add_files => {
        path(qw(source dist.ini)) => simple_ini(
          [ SimpleBootstrap => {
            module_share => 'Dist::Zilla::Plugin::MyModuleSharePlugin => share',
          }],
          [ MyModuleSharePlugin => ],
        ),
        path(qw(source lib Dist Zilla Plugin MyModuleSharePlugin.pm)) => <<'END_CODE',
package Dist::Zilla::Plugin::MyModuleSharePlugin;
use Moose;
use File::ShareDir qw(module_file);
with qw(
  Dist::Zilla::Role::Plugin
);

sub share_file {
  module_file(__PACKAGE__, 'file.txt');
}

1;
END_CODE
        path(qw(source share file.txt)) => 'file content',
      },
    },
  );

  my ($plugin) = grep $_->isa('Dist::Zilla::Plugin::MyModuleSharePlugin'), $tzil->plugins->@*;
  ok $plugin, 'plugin could be loaded';
  ok eval { -e $plugin->share_file }, 'share dir loaded successfully'
    or diag explain \%File::ShareDir::MODULE_SHARE;
};

done_testing;
