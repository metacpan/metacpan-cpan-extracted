use 5.022;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use List::Util qw( first );
use experimental qw( signatures );

my $pm = <<'EOF';
package DZT;

use strict;
use warnings;

1;

=head1 NAME

DZT - The DZT module

=head1 VERSION

version 1.23

=head1 DESCRIPTION

this is the description.  See L<Foo::Bar>.

=cut
EOF

sub build (@config)
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/lib/DZT.pm' => $pm,
        'source/dist.ini' => simple_ini(
          {},
          'GatherDir',
          [ 'Author::Plicease::ReadmeAnyFromPod' => { default_branch => 'main', @config } ],
        ),
      },
    },
  );

  $tzil->build;

  return $tzil;
}

subtest 'gfm' => sub {

  my $tzil = build(
    type        => 'gfm',
    filename    => 'README.md',
    location    => 'build',
    github_user => 'uperl',
    workflow    => [ 'static', 'linux' ],
  );

  my $plugin = $tzil->plugin_named('Author::Plicease::ReadmeAnyFromPod');
  is $plugin->github_repo, 'DZT-Sample', 'github_repo defaults to dist name';

  my $file = first { $_->name eq 'README.md' } $tzil->files->@*;
  ok $file, 'has README.md';

  my $content = $file->content;
  note $content;

  like $content, qr{^# DZT !\[static\]\(https://github\.com/uperl/DZT-Sample/workflows/static/badge\.svg\) !\[linux\]\(https://github\.com/uperl/DZT-Sample/workflows/linux/badge\.svg\)$}m, 'title with badges';
  like $content, qr{^The DZT module$}m, 'abstract follows title';
  unlike $content, qr{# NAME}, 'NAME header removed';
  unlike $content, qr{# VERSION}, 'VERSION section removed';
  unlike $content, qr{version 1\.23}, 'version removed';
  like $content, qr{Foo::Bar}, 'links with :: are not uri escaped';
  unlike $content, qr{Foo%3A%3ABar}, 'no escaped ::';

};

subtest 'gfm no workflow' => sub {

  my $tzil = build(
    type     => 'gfm',
    filename => 'README.md',
    location => 'build',
  );

  my $content = (first { $_->name eq 'README.md' } $tzil->files->@*)->content;
  note $content;

  like $content, qr{^# DZT$}m, 'title without badges';
  unlike $content, qr{badge\.svg}, 'no badges';

};

subtest 'text' => sub {

  my $tzil = build(
    type     => 'text',
    filename => 'README',
    location => 'build',
    workflow => [ 'static' ],
  );

  my $content = (first { $_->name eq 'README' } $tzil->files->@*)->content;
  note $content;

  like $content, qr{NAME}, 'NAME is left alone';
  like $content, qr{version 1\.23}, 'VERSION is left alone';
  unlike $content, qr{badge\.svg}, 'no badges for non-gfm';

};

subtest 'removed keys' => sub {

  foreach my $key (qw( travis_user travis_com appveyor_user appveyor ))
  {
    like
      dies { build(type => 'gfm', $key => 'foo') },
      qr/removed key: $key/,
      "$key is rejected";
  }

};

done_testing;
