package testcover;
use Config;
use Devel::Cover::DB;
use Devel::Cover::Inc;
use File::Glob qw(bsd_glob);
use File::Path qw(remove_tree);
use FindBin;
use List::Util qw(first);
use TAP::Harness;
use File::Which qw(which);

sub run {
    my $name = shift;

    my $path     = test_path($name);
    my $cover_db = cover_db_path($name);

    # Not all @INC paths were set in  Devel::Cover::Inc::Inc
    # when CPAN was used to install Devel::Cover on OSX Lion.
    # ...try and fake this
    my @additional_inc_ignores;
    foreach my $i (@INC) {
        if( ! grep /^$i$/, @Devel::Cover::Inc::Inc ) {
            push @additional_inc_ignores, $i;
        }
    }
    my $incs = join ',', map { '+inc,'.$_ } @additional_inc_ignores;

    if( -d "$cover_db" ) {
        remove_tree($cover_db);
    }

    my $harness = TAP::Harness->new(
        {   verbosity => -3,
            lib       => [$path],
            switches  => "-MDevel::Cover=-db,$cover_db,$incs"
        }
    );
    my @tests = bsd_glob("$path/*.t");
    $harness->runtests(@tests);

    my $cover_cmd = cover_cmd();
    my $perl_cmd  = perl_cmd();
    run_cmd( $perl_cmd, $cover_cmd, $cover_db );

    my $db = Devel::Cover::DB->new( db => $cover_db );
    return $db;

}

sub run_cmd {
    my @parts = @_;
    my $str = sprintf( "'%s'", join "','", @parts );
    {
        local *STDOUT = STDOUT;
        open( STDOUT, '>', '/dev/null' );
        system(@parts) == 0 or die "system($str) failed: $? \n";
    }
    return;
}

sub cover_cmd {
    my $p_which = which('cover');
    my $found
        = first { defined $_ && $_ && -f $_ } ( $p_which, $Devel::Cover::Inc::Base . "/cover" );
    return $found || 'cover';
}

sub perl_cmd {
    my $found = first { defined $_ && $_ && -f $_ } ( $Config{perlpath}, $^W );
    return $found || 'perl';
}

sub cover_db_path {
    my $name = shift;
    my $path = test_path($name) . "/cover_db";
}

sub test_path {
    my $name = shift;
    return "$FindBin::Bin/../cover_db_test/$name";
}

sub test_file {
    my $name = shift;
    return test_path($name) . "/{$name}.pm";
}

1;
