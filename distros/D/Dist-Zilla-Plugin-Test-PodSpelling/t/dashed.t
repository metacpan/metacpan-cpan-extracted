use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;
use Path::Tiny;

# test the file content generated when various attributes are set

my $fname  = 'Fo';
my $mi     = 'G';
my $lname1 = 'oer';
my $lname2 = 'bar';
my $author = "$fname $mi $lname1 - $lname2";

sub get_content {
  my ($args) = @_;

  my $name = 'Test::PodSpelling';
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/foo' },
    {
      add_files => {
        'source/lib/Spell/Checked.pm' => "package Spell::Checked;\n1;\n",
        'source/dist.ini' => dist_ini(
          {
            name => 'Spell-Checked',
            version => 1,
            abstract => 'spelled wrong',
            license => 'Perl_5',
            author => $author,
            copyright_holder => $author,
          },
          [GatherDir =>],
          [$name => $args],
        )
      }
    }
  );

  $tzil->build;
  my $build_dir = path($tzil->tempdir)->child('build');
  my $file = $build_dir->child('xt', 'author', 'pod-spell.t');
  return $file->slurp_utf8;
}

my $content = get_content({});

like   $content, qr/$fname /xms, 'includes first name';
like   $content, qr/$lname1/xms, 'includes last name 1';
like   $content, qr/$lname2/xms, 'includes last name 2';
unlike $content, qr/$mi    /xms, 'does not include the midddle initial';

SKIP: {
    skip 'qr//m does not work properly in 5.8.8', 4,
        unless "$]" > '5.010';

    like   $content, qr/^$fname $/xms, q[includes first name];
    like   $content, qr/^$lname1$/xms, q[includes last name 1];
    like   $content, qr/^$lname2$/xms, q[includes last name 2];
    unlike $content, qr/^$mi    $/xms, q[does not include the midddle initial];
}

done_testing;
