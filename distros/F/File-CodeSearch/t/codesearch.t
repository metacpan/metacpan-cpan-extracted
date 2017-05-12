#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings qw/warning/;
use Term::ANSIColor qw/:constants/;
use FindBin qw/$Bin/;
use File::CodeSearch::Highlighter;
use File::CodeSearch;
use Data::Dumper qw/Dumper/;

simple();
message();
done_testing();

sub simple {
    my $re = File::CodeSearch::RegexBuilder->new(
        re => ['.'],
    );
    my $cs = File::CodeSearch->new(
        regex  => $re,
    );

    my %files;
    $cs->search(sub{
        $files{$_[1]} = 1;
    }, $Bin);
    is +(scalar keys %files), 11, 'Find all files';

    %files = ();
    $cs->search(sub{
        $files{$_[1]} = 1;
    }, 'missing-dir');
    is +(scalar keys %files), 0, 'Find no files';

    my @files;
    $cs->search(sub{
        push @files, $_[1] if !@files || $files[-1] ne $_[1];
    }, 'lib');
    is_deeply \@files, [
        'lib/File/CodeSearch/Highlighter.pm',
        'lib/File/CodeSearch/RegexBuilder.pm',
        'lib/File/CodeSearch/Replacer.pm',
        'lib/File/CodeSearch.pm',
    ], 'Default search'
        or diag explain \@files;

    @files = ();
    $cs->depth(1);
    $cs->search(sub{
        push @files, $_[1] if !@files || $files[-1] ne $_[1];
    }, 'lib');
    is_deeply \@files, [
        'lib/File/CodeSearch.pm',
        'lib/File/CodeSearch/Highlighter.pm',
        'lib/File/CodeSearch/RegexBuilder.pm',
        'lib/File/CodeSearch/Replacer.pm',
    ], 'Depth firs search'
        or diag explain \@files;

    @files = ();
    $cs->breadth(1);
    $cs->search(sub{
        push @files, $_[1] if !@files || $files[-1] ne $_[1];
    }, 'lib');
    is_deeply \@files, [
        'lib/File/CodeSearch/Highlighter.pm',
        'lib/File/CodeSearch/RegexBuilder.pm',
        'lib/File/CodeSearch/Replacer.pm',
        'lib/File/CodeSearch.pm',
    ], 'Bredth first search'
        or diag explain \@files;
}

sub message {
    my $re = File::CodeSearch::RegexBuilder->new(
        re             => ['test'],
    );
    my $cs = File::CodeSearch->new(
        regex  => $re,
    );

    is warning { $cs->_message(qw/type name error/) }, "Could not open the type 'name': error\n";
    $cs->quiet(1);

    # the test warnings will pick this up if it warns
    $cs->_message(qw/type name error/);
}
