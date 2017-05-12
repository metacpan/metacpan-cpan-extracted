use warnings;
use strict;
use Test::More tests => 5;
use Test::TempDir::Tiny 0.016;
use File::Spec;
use Cwd;
use Linux::NFS::BigDir qw(getdents getdents_safe);
use Capture::Tiny 0.36 'capture';
use File::Temp 'tmpnam';
use File::Which 1.21 'which';

my $report;

SKIP: {

    my $dd    = which('dd');
    my $split = which('split');

    skip "Don't have the tools to create the files for testing", 5
      unless ( defined($dd) and defined($split) );

    my $tmp_dir      = tempdir();
    note("Temporary directory is $tmp_dir");
    my $num_of_files = 100_000;
    gen_files( $tmp_dir, $num_of_files );
    my $entries_ref = getdents($tmp_dir);
    is( ref($entries_ref), 'ARRAY', 'getdents returns an array reference' );
    is( scalar( @{$entries_ref} ),
        $num_of_files,
        'getdents array reference has the expected number of entries' );
    opendir( my $dh, $tmp_dir ) or die "Cannot read $tmp_dir: $!";
    my $counter = 0;

    while ( readdir($dh) ) {
        $counter++;
    }

    close($dh);
    is(
        scalar( @{$entries_ref} ),
        ( $counter - 2 ),
        'getdents returns the same number of entries as readdir()'
    );

    $report = tmpnam();
    my $total = getdents_safe( $tmp_dir, $report );
    is( $total, $num_of_files,
        'getdents_safe returns the expected number of entries' );
    open( my $in, '<', $report ) or die "Cannot read $report: $!";
    $counter = 0;

    while (<$in>) {
        $counter++;
    }

    close($in);
    is( $total, $counter,
'getdents_safe returns the same number of entries as are in the output file'
    );

}

END {
    unlink $report if ( ( defined($report) ) and ( -f $report ) );
}

sub gen_files {
    my ( $tmp_dir, $num_of_files ) = @_;
    diag(
        "Generating $num_of_files files for testing, this can take a while...");
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
        diag("failed to execute: $!\n");
    }
    elsif ( $error_code & 127 ) {
        diag( sprintf("child died with signal %d, %s coredump\n") ),
          ( $error_code & 127 ), ( $error_code & 128 ) ? 'with' : 'without';
    }
    else {
        note( sprintf( "child exited with value %d\n", $error_code >> 8 ) );
    }
}

# vim: filetype=perl
