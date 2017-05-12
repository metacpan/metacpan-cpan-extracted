use strict;
use warnings;

use Dumbbench;
use Getopt::Long qw<:config no_ignore_case>;

my %cases = (
    cover_01 => {
        filename => 'cover-01.pl',
    },
    cover_02 => {
        filename => 'cover-02.pl',
    },
    cover_03 => {
        filename => 'cover-03.pl',
    },
    cover_04 => {
        filename => 'cover-04.pl',
    }
);

my ($verbose);
GetOptions( 'verbose|v' => \$verbose );

sub benchmark_file {
    my $file = shift;

    $verbose and print "* $file... ";

    my $bench = Dumbbench->new(
        target_rel_precision => 0.005,
        initial_runs         => 100,
    );

    my $normal = [
        $^X,
        "./fixtures/$file",
    ];
    $bench->add_instances(
        Dumbbench::Instance::Cmd->new(
            name    => $file,
            command => $normal,
        )
    );

    my $with_devel_cover = [
        $^X,
        '-I./blib/lib',
        '-I./blib/arch/',
        '-MDevel::QuickCover',
        "./fixtures/$file",
    ];
    $bench->add_instances(
        Dumbbench::Instance::Cmd->new(
            name    => "${file}_devel_quickcover",
            command => $with_devel_cover,
        )
    );

    $bench->run;
    $verbose and $bench->report;

    my @instances        = $bench->instances;
    my $devel_quickcover = $instances[1]->result()->{num};
    my $original         = $instances[0]->result()->{num};

    printf "For $file, Devel::QuickCover is %e times slower\n", ($devel_quickcover / $original);
}


foreach my $name ( sort keys %cases ) {
    my $value = $cases{$name};
    benchmark_file( $value->{filename} );
}
