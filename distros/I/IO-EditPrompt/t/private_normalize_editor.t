#!/usr/bin/env perl

use Test::More tests => 16;

use strict;
use warnings;

use IO::EditPrompt;

# This test covers a private method. There is no guarantee that this method will remain
# the same or even exist in a later version.

{
    local $ENV{EDITOR};
    editor_is_default( undef, 'vim', [ '-i', 'NONE' ], 'no editor, env, or default' );
}

{
    local $ENV{EDITOR};
    editor_is_default( 'emacs', 'emacs', [], 'default editor supplied' );
}

{
    local $ENV{EDITOR} = 'nano';
    editor_is_default( 'emacs', 'nano', [], 'default editor supplied + env' );
}

{
    local $ENV{EDITOR} = 'nano';
    editor_is_default( undef, 'nano', [], 'no default editor supplied + env' );
}

{
    local $ENV{EDITOR};
    editor_is_supplied( undef, 'vim', [ '-i', 'NONE' ], 'editor, no defaults' );
}

{
    local $ENV{EDITOR};
    editor_is_supplied( 'nano', 'emacs', [], 'editor, default editor supplied' );
}

{
    local $ENV{EDITOR} = 'vim';
    editor_is_supplied( 'emacs', 'nano', [], 'editor, default editor supplied + env' );
}

{
    local $ENV{EDITOR} = 'vim';
    editor_is_supplied( undef, 'nano', [], 'editor, no default editor supplied + env' );
}

sub editor_is_default {
    my ($def, $editor, $args, $label) = @_;
    my $fake = { editor => undef, editor_args => [] }; # Initialized like in new
    IO::EditPrompt::_normalize_editor( $fake, $def );
    is( $fake->{editor}, $editor, "$label: editor set" );
    is_deeply( $fake->{editor_args}, $args, "$label: args set" );
    return;
}

sub editor_is_supplied {
    my ($def, $editor, $args, $label) = @_;
    my $fake = { editor => $editor, editor_args => [] }; # Initialized like in new
    IO::EditPrompt::_normalize_editor( $fake, $def );
    is( $fake->{editor}, $editor, "$label: editor set" );
    is_deeply( $fake->{editor_args}, $args, "$label: args set" );
    return;
}
