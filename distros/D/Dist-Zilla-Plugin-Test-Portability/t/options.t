use strict;
use warnings;
use Test::More;

use Test::DZil;

my $config = simple_ini();

my $end = 'run_tests\(\);';

my @tests = (
    [ {             }, qr/  if \$@;\n+$end$/m ],
    [ {options => ''}, qr/  if \$@;\n+$end$/m ],
    [ {options => 'test_case => 0'}, qr/\n\Qoptions(test_case => 0);\E\n$end$/m ],
    [ {options => 'test_space=0,test_dos_length=1'}, qr/\n\Qoptions(test_dos_length => 1, test_space => 0);\E\n$end/m ],
);

plan tests => scalar @tests;

foreach my $test ( @tests ) {
    my ($opts, $qr) = @$test;

    my $dzil = new_dzil(port_test_plug($opts));
    $dzil->build;

    my $t = (grep { $_->name eq 'xt/author/portability.t' } @{ $dzil->files })[0];
    like($t->content, $qr, 'options merged successfully');
}

sub port_test_plug {
           # class           => name             => {}
    return ['Test::Portability', 'Test::Portability' => @_];
}

sub new_dzil {
    return Builder->from_config(
        { dist_root => 'corpus' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(@_),
            },
        }
    );
}
