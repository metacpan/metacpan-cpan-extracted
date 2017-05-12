# \author: Armand Leclercq
# \file: t/01_basic.t
# \date: Wed 17 Dec 2014 02:51:21 PM CET

use strict;
use warnings;

use Test::DZil;
use Test::More;

subtest 'Dummy' => sub {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT_SQL' },
    {
      add_files => {
        'source/dist.ini' => simple_ini('@Classic', 'Documentation::SQL'),
      },
    },
  );

  $tzil->build;

  # This dir location is defined by default values from simple_ini call
  my $content = $tzil->slurp_file('build/lib/DZT/Sample/Documentation/SQL.pod');
  my $expected = <<"END_EXP";
=pod

=head1 lib/DZT/Sample.pm

L<DZT::Sample>

B<SELECT> * B<FROM> sample_table

=cut
END_EXP

  is $content, $expected, "Test content correctly printed";
};

done_testing;
