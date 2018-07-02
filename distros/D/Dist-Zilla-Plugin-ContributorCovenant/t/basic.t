use strict;
use warnings;

use Test::More;
use Test::DZil;

my $cases = [
  {
    author  => 'E. Xavier Ample <example@example.org>',
    contact => 'example@example.org',
  },
  {
    author  => 'E. Xavier Ample',
    contact => 'GitHub / RT',
  },
  # add more here
];

foreach my $case (@$cases){
  my $author  = $case->{author};
  my $contact = $case->{contact};

  my $dist_ini = dist_ini({
    name     => 'DZT-Sample',
    abstract => 'Sample DZ Dist',
    author   => $author,
    license  => 'Perl_5',
    version  => '1.0.0',
    copyright_holder => 'E. Xavier Ample',
  }, qw/
    GatherDir
    FakeRelease
  /, qw/
    ContributorCovenant
  /
  );

  my $tzil = Builder->from_config(
    { dist_root => 'corpus' },
    { add_files => { 'source/dist.ini' => $dist_ini } },
  );
  $tzil->build;

  like $tzil->slurp_file('build/CODE_OF_CONDUCT.md'),
    qr/$contact/,
    "$contact exists in code of conduct";
}

done_testing;