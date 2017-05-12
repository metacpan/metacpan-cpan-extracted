# NAME

Eliza::Chatbot - Eliza chatbot

# VERSION

Version 0.02

# SYNOPSIS

    use Eliza::Chatbot

    my $bot = Eliza::Chatbot->new();
    
    $bot->command_interface;

# DESCRIPTION

This module implements the classic Eliza algorithm. The original Eliza program was 
written by Joseph Weizenbaum and described in the Communications of the ACM in 1966.  
Eliza is a mock Rogerian psychotherapist.  It prompts for user input, and uses a simple 
transformation algorithm to change user input into a follow-up question.  The program 
is designed to give the appearance of understanding.

# OPTIONS

    my $bot = Eliza::Chatbot->new(name => 'WoW');

You can pass the following options into the Chatbot

- name 

    Rename Eliza

- script\_file

    Pass in your own script file

- debug

    Turn debug mode on - 1.

- prompts\_on

    Turn prompts on - 1.

- memory\_on

    Turn memory off - 0.

# SUBROUTINES/METHODS

## command\_interface

    $chatterbot->command_interface;

command\_interface() opens an interactive session with the Eliza object, 
just like the original Eliza program. 

During an interactive session invoked using command\_interface(),
you can enter the word "debug" to toggle debug mode on and off.
You can also enter the keyword "memory" to invoke the \_debug\_memory()
method and print out the contents of the Eliza instance's memory.

This module is written in Moo which means it should be relatively easy
for you to design your own session format. All you need to do is extend 
[Eliza::Chatbot](https://metacpan.org/pod/Eliza::Chatbot) and maybe [Eliza::Chatbot::Brain](https://metacpan.org/pod/Eliza::Chatbot::Brain) if you're feeling ambitious.
Then you can write your own while loop and your own methods.

## instance

    $chatterbot->instace;

Return a single instance of the Eliza Object

# AUTHOR

LNATION thisusedtobeanemail@gmail.com

# ACKNOWLEDGEMENTS

I started here [Chatbot::Eliza](https://metacpan.org/pod/Chatbot::Eliza) and then got a little carried away.

# LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

http://www.perlfoundation.org/artistic\_license\_2\_0

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
