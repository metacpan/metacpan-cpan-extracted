#!/usr/bin/perl

use strict;
use warnings;
use constant true  => 1;
use constant false => 0;

use File::Spec;
use FindBin qw($Bin);
use LaTeX::TOM;
use Test::More tests => 6;

my $set_input = sub { ${$_[0]} =~ s/\$INPUT/\\input{$_[1]}/ };

my $abs_path = File::Spec->catfile($Bin, 'data', 'input.t');
my $rel_path = File::Spec->abs2rel($abs_path);

my $parser = LaTeX::TOM->new(0,1,0);

my $data = do { local $/; <DATA> };

my @tests = (
    #  input file             # tex file     # message      # input file must exist
    [ '00-image_skip.pstex_t',  undef,        'skip pstex'  , true  ],
    [ '01-basic.tex',          '01-basic.in', 'basic'       , true  ],
    [ '02-guess',              '02-guess.in', 'guess'       , false ], # file extension for '02-guess' missing on purpose
    [ '03-empty.tex',          '03-empty.in', 'empty',        true  ],
    [ '04-psfig_ignore.tex',    undef,        'ignore Psfig', true  ],
);

SKIP:
{
    skip 'test for release testing', 1 unless $ENV{RELEASE_TESTING};

    # Check that all input files exist or bogus results may ensue.
    my $exist = true;
    foreach my $test (@tests) {
        my ($input_file, $must_exist) = @$test[0,3];
        if ($must_exist) {
            $exist &= -e File::Spec->catfile($abs_path, $input_file) ? true : false;
        }
    }
    ok($exist, '\input test files exist');
}

sub check_unaltered_tex
{
    my $input_file = $_[0]->[0];

    $input_file = File::Spec->catfile($rel_path, $input_file);

    my $tex = $data;
    $set_input->(\$tex, $input_file);

    my $tree = $parser->parse($tex);

    return scalar grep /\\input\{\Q$input_file\E\}/, split /\n/, $tree->toLaTeX;
}

{
    my $skipped = check_unaltered_tex($tests[0]);
    my $message = $tests[0]->[2];

    ok($skipped, $message);
}

{
    foreach my $test (@tests[1..3]) {
        my ($input_file, $tex_file, $message) = @$test;

        $input_file = File::Spec->catfile($rel_path, $input_file);
        $tex_file   = File::Spec->catfile($abs_path, $tex_file);

        my $tex = $data;
        $set_input->(\$tex, $input_file);

        my $tree_string = $parser->parse($tex);
        my $tree_file   = $parser->parseFile($tex_file);

        is_deeply(
            [ grep /\S/, split /\n/, $tree_string->toLaTeX ],
            [ grep /\S/, split /\n/, $tree_file->toLaTeX   ],
        $message);
    }
}

{
    my $seen_warning = false;

    local $SIG{__WARN__} = sub
    {
        warn $_[0] and return unless $_[0] =~ /^ignoring Psfig/;
        $seen_warning = true;
    };

    my $ignored = check_unaltered_tex($tests[4]);
    my $message = $tests[4]->[2];

    ok($ignored && $seen_warning, $message);
}

__DATA__
\documentclass[10pt]{article}
\begin{document}
$INPUT
\end{document}
