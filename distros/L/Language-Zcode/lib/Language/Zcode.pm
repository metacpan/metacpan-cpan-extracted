package Language::Zcode;

use strict;
use warnings;

our $VERSION = 0.8;

# No code here, just docs.

=head1 NAME 

Language::Zcode - Play with Z-code and the Z-machine

=head1 SYNOPSIS

Translate a Z-code file into Perl. The following (if piped to a file) will
create an executable which will will execute just as if you ran zork1.z3 under
a Z-code interpreter. Note: the executable will not be standalone; it will use
Language::Zcode::Runtime::* modules. Creating a downloadable single-file
executable is a TODO.

    use Language::Zcode::Parser; # parse Z-file
    use Language::Zcode::Translator; # language-specific output routines

    my $Zfile = "zork1.z3";
    my $Parser = new Language::Zcode::Parser "Perl";
    $Parser->read_memory($Zfile);
    $Parser->parse_header();

    my $T = new Language::Zcode::Translator "Perl";
    print $T->program_start();
    for my $rtn ($Parser->find_subs($Zfile)) {
	$rtn->parse();
	print $T->routine_start($rtn->address, $rtn->locals); 
	print $T->translate_command($_) for $rtn->commands;
	print $T->routine_end();
    }
    print $T->write_memory();
    print $T->program_end();

Create a Z-machine...

    Nothing here yet.

Parse a Quetzal save file.

    Nothing here yet.

=head1 DESCRIPTION

Z-code is the machine language for the Z-machine, the virtual machine
that the Infocom text adventure games (among others) run on.
Language::Zcode provides tools to parse story files written in Z-code, and to
translate ("compile") them to executables in other languages (such as Perl).

This module does not contain a Z-machine interpreter: you can't run a
Z-machine file without translating it to some other language first.  Pick up
Michael Edmonson's Games::Rezrov if you want to B<play> Zork, rather than
translate it to Perl. (I stole almost all of Games::Rezrov to start this
module.)

=head2 Parsing

Language::Zcode should be able to handle almost any story file, except
for fancy stuff like Unicode. Parsing will let you look at a story
file's commands and strings, like the (ca. 1992) txd program.  Looking
at objects (like infodump does) is a bit harder, but doable
using the API.  Grammar/action tables are totally not supported.

=head2 Translating to Perl

The "compiled" Perl executables basically support early-to-mid-80's Infocom
technology. That is:

=over 4

=item *

All v3 opcodes are implemented, some better than others. 

=item *

Some v4 and v5 opcodes are implemented.

=item *

Only the Dumb and Win32 Console I/O systems are implemented.

=back

This means (although I haven't tested exhaustively) that you should be able to
play most Infocom games, if you're lucky enough to have the story files.
Most modern (late Infocom, Inform) games won't work. I hope to have 
support for those in the next version.

=head2 Translating to PIR 

PIR is also known as Parrot Intermediate Representation or IMCC.
Language::Zcode is only doing this as a proof of concept. A few v3 opcodes
are implemented, badly. See L</HISTORY>.

=head2 Translating to XML

Barely even a proof of concept. A static file, rather than an executable.
But with some good XSL work (by someone who actually knows XSL), you could have
a very pretty display of the game's commands and strings. Further XML
TODOs left to the imagination.

=head1 TODO

(Only includes TODOs within the current set of supported commands.)

=over 4

=item *

print_char should do ZSCII, not ASCII.

=item *

output stream 3

=back

See Todo for far more information.

=head1 BUGS

=over 4

=item *

Stream 2 isn't buffered (word-wrapped) correctly.

=item *

Language::Zcode can't read a Windows command input file (input stream
1) when it's running on Unix. It gets a \r\n instead of a \n.

=item *

 sending "y\n" to get_key in dumb-terminal mode leaves a \n on STDIN,
so the next get_key (which just does read(STDIN, $z, 1) reads the \n even
if you don't type anything!

=item *

$SIG{INT} should call cleanup. See rezrov.

=item *

It's legal (but "bad practice" and confuses txd) to jump into a subroutine. 
I don't care for now. I might in later versions. But, for example, if you
do allow jumping into subroutines, then you can't (easily) translate
Z-machine routines into Perl subs; the latter tend to get fussy about
goto's breaking scope.

=item *

All pops & pulls ought to crash on stack underflow. We'll just return
an undef, which will probably turn into 0. Problem is that fixing this
while still using a normal Perl array for the stack is Hard, because
pop @stack happens in so many places where we don't want to have a big
     do {die unless @stack; pop @stack}

=item *

For safety, Z_machine() should take
first_instruction_address - 2*num_locals - 1, or it might break on
Infocom z3's whose Mains have local variables.

=item * 

PlotzMemory::set_word_at doesn't & 0xff the high byte. (storew DOES do it)
Also need to "unsigned_word-ify" some more constructs to make sure
we're safe.

=item *

split_window in v3 (only) should erase the screen, and
restart/restore shouldn't clear screen

=back

=head1 HISTORY

It all started with Dan Sugalski's suggestion that Parrot could
run Z-code natively. He subtly hinted at this idea as early as 12/2001
(http://www.nntp.perl.org/group/perl.perl6.internals/6875) and dedicated
a whole slide to it in a 2002 RubyConf presentation. 

Dan's idea was to make the Parrot VM think it's a Z-machine, running
the Z-code opcodes instead of the regular Parrot ones. Or,
as he put it, "parrot -b:zmachine zork.dat". Whoa! Why do it? Because
it proves how powerful Parrot is.  "Plus, it's really cool."

Given that I had no clue at all how to do this, I got some advice from
the Parrot mailing list, and it was suggested that I:

=over 4

=item 1 

Write a program that translates ("compiles") Z-code to Perl.

=item 2 

Compile Z-code to PIR, writing new Parrot opcodes for Z-machine opcodes.
The PIR and C could just be translations of the Perl code from step 1.

=item 3 

Convince Parrot to read Z-code directly, and then execute the Z Parrot opcodes
that I'd written in step 2.

=item 4

...

=item 5

Profit!

=back

Language::Zcode v0.8 is step 1, and later versions will do part of step 2.
Given how long it took to get this far, I'm not all that confident about step
5, but we'll see.

See Changes for version information.

=head1 AUTHOR

Amir Karger <akarger@cpan.org>

=head1 LICENSE

Copyright (c) 2004 Amir Karger.  All rights reserved.  

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item *

L<Games::Rezrov> - A Perl Z-code interpreter by Michael Edmonson (which I
stole from. A lot.  As in, pretty much all of the I/O, and many of the opcode
translations.  But I keep trying to convince myself that Language::Zcode has
some independent value.)

=item *

www.ifarchive.org - everything Interactive Fiction-y

=item *

www.inform-fiction.org - Inform, a coding language that compiles to Z-code.  
Get the Z-code spec here (or at ifarchive.org).

=back

=cut

1;
