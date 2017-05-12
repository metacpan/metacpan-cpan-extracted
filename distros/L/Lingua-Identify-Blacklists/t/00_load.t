#!/usr/bin/env perl
#-*-perl-*-

use Test::More;

BEGIN { use_ok('Lingua::Identify::Blacklists', ':all') };

can_ok(__PACKAGE__,'identify');
can_ok(__PACKAGE__,'identify_file');
can_ok(__PACKAGE__,'identify_stdin');
can_ok(__PACKAGE__,'train');
can_ok(__PACKAGE__,'train_blacklist');
can_ok(__PACKAGE__,'run_experiment');

done_testing;
