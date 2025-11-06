#!/usr/bin/env perl
# Test that we can cope with all of the ways of specifying a text domain.

use warnings;
use strict;

use Cwd;
use File::Temp qw/tempdir/;
use Test::More;

BEGIN
{   eval "require PPI";
    $@ and plan skip_all => 'PPI not installed';

    use_ok 'Log::Report::Extract::PerlPPI';
}

_test_import(
    subtest_name => 'Preceded by a version number',
    source       => 'use Log::Report 1.00 "not-a-version-number";',
    text_domain  => 'not-a-version-number',
);

_test_import(
    subtest_name => 'Using a quotelike operator',
    source       => 'use Log::Report qw(wossname)',
    text_domain  => 'wossname',
);

_test_import(
    subtest_name => 'The Dancer plugin works as well',
    source       => q{use Dancer2::Plugin::LogReport 'dance-monkey-dance';},
    text_domain  => 'dance-monkey-dance',
);

_test_import(
    subtest_name => 'With no arguments at all',
    source       => 'use Log::Report',
    text_domain  => undef,
);

done_testing();

sub _test_import {
    my (%args) = @_;

    subtest $args{subtest_name} => sub {
        my $source_dir   = tempdir CLEANUP => 1;
        my $lexicon      = tempdir CLEANUP => 1;
        my $ppi          = Log::Report::Extract::PerlPPI->new(lexicon => $lexicon);
        my $previous_cwd = Cwd::cwd();
        chdir($source_dir);

        open (my $fh, '>', 'perl-source.pl');
        print $fh $args{source};
        close $fh;

        $ppi->process('perl-source.pl');
        $ppi->write;

        my @leafnames = keys %{ $ppi->index->index };
        if (defined $args{text_domain}) {
            is @leafnames, 1, 'We added a file';
            like $leafnames[0], qr/^$args{text_domain}/, '...matching the expected text domain';
        } else {
            is @leafnames, 0, 'No text domain = no files added';
        }

        chdir($previous_cwd);
    };
}
