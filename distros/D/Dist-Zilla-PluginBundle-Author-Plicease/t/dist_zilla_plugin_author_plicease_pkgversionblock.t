use 5.022;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use experimental qw( signatures );

my $pm = <<'PERL';
package Foo {

  use strict;
  use warnings;

  # ABSTRACT: The Foo module

}

1;
PERL

sub build ($version)
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      tempdir_root => undef,
      add_files => {
        'source/lib/DZT.pm' => $pm,
        'source/dist.ini'   => simple_ini(
          { version => $version },
          # [GatherDir]
          'GatherDir',
          [ 'Author::Plicease::PkgVersionBlock' => {} ],
        ),
      },
    },
  );

  $tzil->build;

  my($file) = grep { $_->name eq 'lib/DZT.pm' } @{ $tzil->files };
  note $file->content;

  return ($tzil, $file->content);
}

subtest 'normal version' => sub {
  my($tzil, $content) = build('1.23');
  like $content, qr/^package Foo 1\.23 \{/m, 'version in package block';
  is $tzil->version, '1.23', 'dist version';
  ok !(grep { /instead of/ } @{ $tzil->log_messages }), 'no rewrite message';
};

subtest 'underscore version' => sub {
  my($tzil, $content) = build('1.23_01');
  like $content, qr/^package Foo 1\.2301 \{/m, 'underscore removed in package block';
  is $tzil->version, '1.23_01', 'dist version restored';
  ok((grep { /Using 1\.2301 instead of 1\.23_01/ } @{ $tzil->log_messages }), 'logged rewrite');
};

done_testing;
