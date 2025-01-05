package Eliza::Chatbot;

use strict;
use warnings;

use Moo;
use MooX::LazierAttributes;
use Eliza::Chatbot::Option;
use Eliza::Chatbot::Brain;

our $VERSION = '0.10';

our @user_options = qw(name script_file debug prompts_on memory_on);

attributes (
    [@user_options] => [rw],
    brain => [rw, nan, { lzy, bld }],
);

sub _build_brain {
    my $self = shift;
    my $options = Eliza::Chatbot::Option->new();
    foreach my $field (@user_options) {
        if (my $val = $self->$field) {
            $options->$field($val);
        }
    }
    return Eliza::Chatbot::Brain->new(options => $options);
}

sub command_interface {
    my $self = shift;
    my ($reply, $previous_user_input, $user_input) = "";
    
    my $options = $self->brain->options;
    $options->botprompt($options->name . ":\t");
    $options->userprompt("you:\t");

    # Seed the rand number generator.
    srand( time() ^ ($$ + ($$ << 15)) );

    # print the Eliza prompt
    print $options->botprompt if $options->prompts_on;

    # print an initial greeting
    print $options->welcome_message . "\n";

    while (1) {
        print $options->userprompt if $options->prompts_on;
    
        $previous_user_input = $user_input;
        chomp( $user_input = <STDIN> );

        # If the user enters the work "debug",
        # the toggle on/off Eliza's debug output.
        if ($user_input eq "debug") {
            $options->debug( ! $options->debug );
            $user_input = $previous_user_input;
        }

        # If the user enters the word "memory"
        # then use the _debug_memory method to dump out
        # the current contents of Eliza's memory
        if ($user_input =~ m{memory|debug memory}xms) {
            print $self->brain->_debug_memory();
            redo;
        }

        # If the user enters the word "debug that" 
        # the dump out the debugging of the most recent 
        # call to transform
        if ($user_input eq "debug that") {
            print $options->debug_text;
            redo;
        }

        # Invoke the transform method to generate a reply
        $reply = $self->brain->transform($user_input, '');

        # Print out the debugging text if debugging is set to on.
        # This variable should have been set by the transform method
        print $options->debug_text if $self->debug;

        # print the actual reply
        print $options->botprompt if $options->prompts_on;
        print sprintf("%s\n", $reply);

        last if $self->brain->last;
   }
}

sub instance {
    my ($self, $user_input) = @_;
    return $self->brain->transform($user_input, '');
}

1; 

__END__

=head1 NAME

Eliza::Chatbot - Eliza chatbot

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

    use Eliza::Chatbot

    my $bot = Eliza::Chatbot->new();
    
    $bot->command_interface;

=head1 DESCRIPTION

This module implements the classic Eliza algorithm. The original Eliza program was 
written by Joseph Weizenbaum and described in the Communications of the ACM in 1966.  
Eliza is a mock Rogerian psychotherapist.  It prompts for user input, and uses a simple 
transformation algorithm to change user input into a follow-up question.  The program 
is designed to give the appearance of understanding.

=head1 OPTIONS

    my $bot = Eliza::Chatbot->new(name => 'WoW');

You can pass the following options into the Chatbot

=over 

=item name 

Rename Eliza

=item script_file

Pass in your own script file

=item debug

Turn debug mode on - 1.

=item prompts_on

Turn prompts on - 1.

=item memory_on

Turn memory off - 0.

=back

=head1 SUBROUTINES/METHODS

=head2 command_interface

    $chatterbot->command_interface;

command_interface() opens an interactive session with the Eliza object, 
just like the original Eliza program. 

During an interactive session invoked using command_interface(),
you can enter the word "debug" to toggle debug mode on and off.
You can also enter the keyword "memory" to invoke the _debug_memory()
method and print out the contents of the Eliza instance's memory.

This module is written in Moo which means it should be relatively easy
for you to design your own session format. All you need to do is extend 
L<Eliza::Chatbot> and maybe L<Eliza::Chatbot::Brain> if you're feeling ambitious.
Then you can write your own while loop and your own methods.

=head2 instance

    $chatterbot->instace;

Return a single instance of the Eliza Object

=head1 AUTHOR

LNATION email@lnation.org

=head1 ACKNOWLEDGEMENTS

I started here L<Chatbot::Eliza> and then got a little carried away.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

