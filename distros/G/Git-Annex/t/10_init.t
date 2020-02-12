#!/usr/bin/perl

use 5.028;
use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Git::Annex;
use File::chdir;
use File::Temp qw(tempdir);
use t::Setup;
use t::Util;
use File::Spec::Functions qw(catfile file_name_is_absolute);

{
    my $temp = tempdir CLEANUP => 1;
    my $annex = Git::Annex->new($temp);
    is $annex->toplevel, $temp, "constructor sets toplevel to provided dir";
    local $CWD = $temp;
    $annex = Git::Annex->new;
    is $annex->toplevel, $temp, "constructor sets toplevel to pwd";
    $annex = Git::Annex->new("foo");
    ok file_name_is_absolute($annex->toplevel),
      "it converts a relative path to absolute";
    ok !-d $annex->toplevel, "it permits initialisation in a nonexistent dir";
}

{
    my $temp = tempdir CLEANUP => 1;
    my $annex = Git::Annex->new($temp);
    is $annex->{git}, undef, "Git::Wrapper instance lazily instantiated";
    ok $annex->git->isa("Git::Wrapper") && defined $annex->{git},
      "Git::Wrapper instance available";
    is $annex->git->dir, $temp, "Git::Wrapper has correct toplevel";
}

# # lazy init of Git::Repository object requires an actual git repo, not
# # just an empty tempdir
# with_temp_annexes {
#     my $annex = Git::Annex->new("source1");
#     is $annex->{repo}, undef, "Git::Repository instance lazily instantiated";
#     ok $annex->repo->isa("Git::Repository") && defined $annex->{repo},
#       "Git::Repository instance available";
#     is $annex->repo->work_tree, catfile(shift, "source1"),
#       "Git::Repository has correct toplevel";
# };

SKIP: {
    skip "git-annex not available", 1 unless git_annex_available;
    with_temp_annexes {
        my $source1_dir = catfile shift, "source1";
        my $annex = Git::Annex->new(catfile $source1_dir, "foo");
        is $annex->toplevel, $source1_dir, "it rises to top of working tree";
    };
}

done_testing;
