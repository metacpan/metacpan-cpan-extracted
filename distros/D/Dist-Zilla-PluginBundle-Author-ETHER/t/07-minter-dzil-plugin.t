use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Moose::Util 'find_meta';

use lib 't/lib';
use NoNetworkHits;
use NoPrereqChecks;
use Helper;

# we need the profiles dir to have gone through file munging first (for
# profile.ini), as well as get installed into a sharedir
plan skip_all => 'this test requires a built distribution'
    unless -d 'blib/lib/auto/share/dist/Dist-Zilla-PluginBundle-Author-ETHER/profiles';

plan skip_all => 'minting requires perl 5.014' unless "$]" >= 5.013002;

my $tzil = Minter->_new_from_profile(
    [ 'Author::ETHER' => 'default' ],
    { name => 'Dist-Zilla-Plugin-Foo-Bar', },
    { global_config_root => path('corpus/global')->absolute },
);

# we need to stop the git plugins from doing their thing
foreach my $plugin (grep ref =~ /Git/, @{$tzil->plugins}) {
    next unless $plugin->can('after_mint');
    my $meta = find_meta($plugin);
    $meta->make_mutable;
    $meta->add_around_method_modifier(after_mint => sub { Test::More::note("in $plugin after_mint...") });
}

$tzil->chrome->logger->set_debug(1);
$tzil->mint_dist;
my $mint_dir = path($tzil->tempdir)->child('mint');

my $dist_ini = path($mint_dir, 'dist.ini')->slurp_utf8;
like(
    $dist_ini,
    qr/\[Bootstrap::lib\]
\[Foo::Bar\]

\[\@Author::ETHER\]
:version = [\d.]+
Test::MinimumVersion.max_target_perl = 5.008003

\[MetaResources\]
x_IRC/,
    'found dist.ini content',
);

unlike($dist_ini, qr/^\s/, 'no leading whitespace in dist.ini');
unlike($dist_ini, qr/[^\S\n]\n/, 'no trailing whitespace in dist.ini');
unlike($dist_ini, qr/\n\n\n/, 'no double blank links in dist.ini');
unlike($dist_ini, qr/\n\n\z/, 'file does not end with a blank line');

my $travis = path($mint_dir, '.travis.yml')->slurp_utf8;
like(
    $travis,
    qr{^install:\n  - perl -M5\.014 -e1 2>/dev/null || cpan-install Dist::Zilla\@5.047$}m,
    'extra line for older Dist::Zilla inserted into .travis.yml',
);

my $module = path($mint_dir, 'lib/Dist/Zilla/Plugin/Foo/Bar.pm')->slurp_utf8;

like(
    $module,
    qr/^use strict;\nuse warnings;\npackage Dist::Zilla::Plugin::Foo::Bar;/m,
    'our new module has a valid package declaration',
);

like(
    $module,
    do {
        my $pattern = <<PLUGIN;
use Moose;
with 'Dist::Zilla::Role::...';

use namespace::autoclean;

PLUGIN
        qr/\Q$pattern\E/
    },
    'our new module declares itself as a consumer of a Dist::Zilla role',
);

like(
    $module,
    qr/\n\n\n__PACKAGE__->meta->make_immutable;\n__END__$/m,
    'the package code ends as appropriate for Moose classes',
);

like(
    $module,
    do {
        my $pattern = <<SYNOPSIS;
=head1 SYNOPSIS

In your F<dist.ini>:

  [Foo::Bar]

=head1 DESCRIPTION

SYNOPSIS
my $cut = <<CUT;

=cut
CUT
        qr/\Q$pattern\E/
    },
    'our new module has a brief synopsis tailored to dzil plugins',
);

like(
    $module,
    qr/^=head1 DESCRIPTION\n\nThis is a L<Dist::Zilla> plugin that\.\.\.$/m,
    'our new module has a description tailored to dzil plugins',
);

like(
    $module,
    qr{^=head1 CONFIGURATION OPTIONS$}m,
    'our new module has a pod section for configuration options',
);

like(
    path($mint_dir, 't', '01-basic.t')->slurp_utf8,
    do {
        my $pattern = <<'TEST';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

my $tzil = Builder->from_config(
  { dist_root => 'does-not-exist' },
  {
    add_files => {
      path(qw(source dist.ini)) => simple_ini(
        [ GatherDir => ],
        [ MetaConfig => ],
        [ 'Foo::Bar' => ... ],
      ),
      path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
    },
  },
);

$tzil->chrome->logger->set_debug(1);
is(
  exception { $tzil->build },
  undef,
  'build proceeds normally',
);

cmp_deeply(
  $tzil->distmeta,
  superhashof({
    x_Dist_Zilla => superhashof({
      plugins => supersetof(
        {
          class => 'Dist::Zilla::Plugin::Foo::Bar',
          config => {
            'Dist::Zilla::Plugin::Foo::Bar' => {
              ...
            },
          },
          name => 'Foo::Bar',
          version => Dist::Zilla::Plugin::Foo::Bar->VERSION,
        },
      ),
    }),
  }),
  'plugin metadata, including dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
  if not Test::Builder->new->is_passing;

done_testing;
TEST
        qr/\Q$pattern\E/,
    },
    'test gets custom content for testing dzil plugins',
);

is(
    path($mint_dir, 'README.pod')->slurp_utf8,
    <<'README',
=pod

=head1 SYNOPSIS

In your F<dist.ini>:

  [Foo::Bar]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that...

=head1 CONFIGURATION OPTIONS

=head2 foo

...

=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

=for :list
* L<foo>

=cut
README
    'README.pod is generated and contains pod',
);

done_testing;
