#!/usr/bin/env perl

use Test::More tests => 6;

use File::Temp;
use strict;
use warnings;

use IO::EditPrompt;

my $p = IO::EditPrompt->new();

has_text( 'Short prompt, no text', "# Enter text below:\n", '', '' );
has_text( 'Short prompt, some text', "# Enter text below:\n", "Here's my text", '' );
has_text( 'Short prompt, some text, post', "# Enter text below:\n", "Here's my text\n", "# Some other text" );
has_text( 'Long prompt, no text', "# This is info\n# This is info\n# Enter text below:\n", '', '' );
has_text( 'Long prompt, some text', "# This is info\n# This is info\n# Enter text below:\n", "Here's my text", '' );
has_text( 'Long prompt, some text, post', "# This is info\n# This is info\n# Enter text below:\n", "Here's my text\n", "# Some other text\n" );

sub has_text
{
    my ($label, $prompt, $text, $post) = @_;
    my $tmp = File::Temp->new;
    my $filename = $tmp->filename;
    print {$tmp} $prompt, $text, $post;
    close( $tmp );
    return is( $p->_get_output( $filename, $prompt ), $text, "$label: Correct output" );
}
