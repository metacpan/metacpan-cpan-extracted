use warnings;
use strict;
use Cwd;
use Test::More tests => 1;
use Linux::NFS::BigDir qw(getdents getdents_safe);
use Capture::Tiny 0.36 'capture';
use File::Temp 'tmpnam';
use Dumbbench 0.10;

my $bench = Dumbbench->new(
    target_rel_precision => 0.005,    # seek ~0.5%
    initial_runs         => 10,
);

my $tmp_dir = 'tmp';
mkdir $tmp_dir;
print "Temporary directory is $tmp_dir\n";
my $num_of_files = 100_000;
gen_files( $tmp_dir, $num_of_files );

$bench->add_instances(
    Dumbbench::Instance::PerlSub->new(
        name => 'getdents',
        code => sub { scalar( getdents($tmp_dir) ) }
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'readdir',
        code => sub { using_readdir($tmp_dir) }
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'getdents_safe',
        code => sub {
            my $report = tmpnam();
            my $total = getdents_safe( $tmp_dir, $report );
            unlink $report;
            return $total;
        }
    )
);

$bench->run;
my %results;
report( $bench, \%results );

TODO: {
    local $TODO = 'getdents() is slower than readdir() in local file systems';
    cmp_ok( $results{getdents}, '<', $results{readdir},
        'getdents is faster than readdir' );

}

END {
    my $list_ref = getdents($tmp_dir);
    foreach my $file ( @{$list_ref} ) {
        unlink "$tmp_dir\$file";
    }
    rmdir $tmp_dir;
}

sub report {
    my ( $bench, $results_ref ) = @_;

    foreach my $instance ( $bench->instances ) {
        my $result = $instance->result;
        my $mean   = $result->raw_number;
        my $sigma  = $result->raw_error->[0];
        my $name   = $instance->_name_prefix;
        diag(
            sprintf(
                "%sRan %u iterations (%u outliers).\n",
                $name,
                scalar( @{ $instance->timings } ),
                scalar( @{ $instance->timings } ) - $result->nsamples
            )
        );
        $results_ref->{ $instance->name } = $mean;
        diag(
            sprintf(
                "%s Rounded run time per iteration: %s (%.1f%%)\n",
                $name, "$result", $sigma / $mean * 100
            )
        );
    }

    return \%results;
}

sub using_readdir {
    my $tmp_dir = shift;
    opendir( my $dh, $tmp_dir ) or die "Cannot read $tmp_dir: $!";
    my @list;

    while ( readdir($dh) ) {
        push( @list, $_ );
    }

    close($dh);
    shift(@list);
    shift(@list);
    return scalar(@list);
}

sub gen_files {
    my ( $tmp_dir, $num_of_files ) = @_;
    print
      "Generating $num_of_files files for testing, this can take a while...\n";
    my $old = getcwd;
    chdir($tmp_dir) or die "Can't cd to $tmp_dir: $!";
    my $masterfile = 'masterfile';
    my ( $out, $err, $exit ) = capture {
        system(
            'dd',   'if=/dev/zero', "of=$masterfile",
            'bs=1', "count=$num_of_files"
        );
    };
    check_system($exit);
    system( 'split', '-b', '1', '-a', '10', $masterfile );
    check_system();
    unlink $masterfile or die "Cannot remove $masterfile: $!";
    chdir($old) or die "Cannot go back to $old: $!";
}

sub check_system {
    my $error_code = shift || $?;

    if ( $error_code == -1 ) {
        warn("failed to execute: $!\n");
    }
    elsif ( $error_code & 127 ) {
        warn( sprintf("child died with signal %d, %s coredump\n") ),
          ( $error_code & 127 ), ( $error_code & 128 ) ? 'with' : 'without';
    }
    else {
        print( sprintf( "child exited with value %d\n", $error_code >> 8 ) );
    }
}

# vim: filetype=perl
