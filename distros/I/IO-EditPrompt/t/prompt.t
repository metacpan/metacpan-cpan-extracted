#!/usr/bin/env perl

use Test::More tests => 2;

use strict;
use warnings;

use IO::Prompter;
use IO::EditPrompt;

my $input = '';

# Mock interfaces that would be too hard to test.
{
    no warnings 'redefine';
    *IO::EditPrompt::_run_editor = sub {
        my ($self, $file) = @_;
        open my $fh, '+<', $file or die "Unable to change '$file': $!\n";
        seek( $fh, 0, 2 );
        print {$fh} $input;
        close( $fh );
        return;
    };
    *IO::Prompter::prompt = sub { return; };
}

{
    $input = '';
    my $p = IO::EditPrompt->new();
    is( $p->prompt( 'Enter something:' ), '', 'Handles empty input fine.' );
}

{
    $input = 'This is it.';
    my $p = IO::EditPrompt->new();
    is( $p->prompt( 'Enter something:' ), 'This is it.', 'Handles actual input fine.' );
}
