package t::Setup;

use 5.028;
use strict;
use warnings;
use parent 'Exporter';

use File::Slurp;
use File::Temp qw(tempdir);
use Git::Wrapper;
use File::Spec::Functions qw(catfile rel2abs);
use File::chdir;
use File::Path qw(rmtree);

our @EXPORT = qw( with_temp_annexes );

sub with_temp_annexes (&) {
    my $temp = tempdir CLEANUP => 1;
    {
        local $CWD = $temp;
        my ($source1, $source2, $dest)
          = map { Git::Wrapper->new(rel2abs $_) } qw(source1 source2 dest);
        mkdir for qw(source1 source2 dest);
        for ($source1, $source2, $dest) {
            $_->init;
            $_->annex("init");
            $_->config(qw(annex.thin false));
        }

        # source1 setup
        mkdir catfile qw(source1 foo);
        write_file catfile(qw(source1 foo bar)), "bar\n";
        mkdir catfile qw(source1 foo foo2);
        write_file catfile(qw(source1 foo foo2 baz)), "baz\n";
        $source1->RUN(qw(-c annex.gitaddtoannex=false add foo/bar));
        $source1->RUN(qw(-c annex.addunlocked=true annex add foo/foo2/baz));
        $source1->commit({ message => "add" });

        # source2 setup
        write_file catfile(qw(source2 other)), "other\n";
        $source2->RUN(qw(-c annex.addunlocked=false annex add other));
        $source2->commit({ message => "add" });

        &{ $_[0] }($temp, $source1, $source2, $dest);
    }
    rmtree $temp;
}

1;
