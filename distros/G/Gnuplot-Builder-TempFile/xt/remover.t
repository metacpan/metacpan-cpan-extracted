use strict;
use warnings;
use Test::More;
use Test::Builder;
use Time::HiRes qw(time);

my $FILENAME = "temp_file.gp";
my $REMOVER = "gnuplot_builder_tempfile_remover";

sub run_remover {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $before = time;
    my $code = system($REMOVER, $FILENAME);
    my $elapsed = time - $before;
    is(($code >> 8), 0, "remover exits ok");
    return $elapsed;
}

sub touch {
    my ($filename) = @_;
    open my $file, ">", $filename or die "Cannot open $filename: $!";
    close $file;
}

if(-e $FILENAME) {
    plan skip_all => "$FILENAME already exists. SKIP.";
    exit 0;
}

cmp_ok run_remover(), "<", 1, "remover exits immediately if the file does not exists.";
touch($FILENAME);
ok((-e $FILENAME), "$FILENAME created");
cmp_ok run_remover(), ">", 2, "remover waits for a while and exits.";
ok((! -e $FILENAME), "$FILENAME is removed");

done_testing;
