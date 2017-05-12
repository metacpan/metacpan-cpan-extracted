use strict;
use warnings;

BEGIN {
    my $out =  `notify-send --version`;
    if($? == 0) {
        print $out;
    }
    else {
        warn "notify-send(1) is not available.\n";
        warn "Please install it by the following command:\n";
        warn "    sudo apt-get install libnotify-bin\n";
        exit;
    }
}

BEGIN {
    unshift @INC, 'inc';

    # author requires, or bundled modules
    my @devmods = qw(
        inc::Module::Install             1.00
        Module::Install::AuthorTests     0.002
        Module::Install::Repository      0.06
    );
    my @not_available;
    while(my($mod, $ver) = splice @devmods, 0, 2) {
        eval qq{use $mod $ver (); 1} or push @not_available, $mod;
    }
    if(@not_available) {
        print qq{# The following modules are not available.\n};
        print qq{# `perl $0 | cpanm` will install them:\n};
        print $_, "\n" for @not_available;
        exit 1;
    }
}
use inc::Module::Install;

all_from 'lib/Growl/NotifySend.pm';

requires 'File::Which';

test_requires 'Test::More' => '0.88';

auto_set_repository;

tests_recursive;
author_tests 'xt';

clean_files qw(
    Growl-NotifySend-*
    *.stackdump
    cover_db *.gcov *.gcda *.gcno
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
