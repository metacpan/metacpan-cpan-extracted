#!/usr/bin/env perl

use strict;
use warnings;

use HTML::Latemp::GenMakeHelpers;

use Cwd (qw(getcwd));

my $generator =
    HTML::Latemp::GenMakeHelpers->new(
        'hosts' =>
        [ map {
            +{ 'id' => $_, 'source_dir' => $_,
                'dest_dir' => "\$(ALL_DEST_BASE)/$_-homepage"
            }
        } (qw(common t2 vipe)) ],
    );

$generator->process_all();

use IO::All;

my $text = io("include.mak")->slurp();
$text =~ s!^(T2_DOCS = .*)humour/fortunes/index.html!$1!m;
io("include.mak")->print($text);

# This is to in order to generate the t2/humour/fortunes/arcs-list.mak
# file, which is inclduded by the makefile.
{
    my $orig_dir = getcwd();

    chdir("t2/humour/fortunes");
    system("make", "dist");

    chdir($orig_dir);
}

1;

