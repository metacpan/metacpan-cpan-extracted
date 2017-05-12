=head1 NAME

IO::Async::Loop::AnyEvent2::ElectricBoogaloo - load IO::Async::Loop::AnyEvent

=head1 SYNOPSIS

 use IO::Async::Loop::AnyEvent2::ElectricBoogaloo;

 my $loop = IO::Async::Loop::AnyEvent->new();
 ...

=head1 DESCRIPTION

This module lets you load L<IO::Async::Loop::AnyEvent> with L<AnyEvent> 6.1/7.

Unfortunately, IO::Async::Loop::AnyEvent currently fails its tests because it's
being sabotaged by AnyEvent, so you have to force the install (e.g. using
C<cpan -T IO::Async::Loop::AnyEvent> or C<cpanm --notest IO::Async::Loop::AnyEvent>).

After that, IO::Async::Loop::AnyEvent2::ElectricBoogaloo should install normally.

=head1 NOTES

The code to sabotage IO::Async::Loop::AnyEvent first appeared in AnyEvent 6.1
(it was not present in AnyEvent 6.02). It was later modified in 6.11, and again
in AnyEvent 7.0. As of 2016, the code is still there.

=head1 SEE ALSO

L<IO::Async::Loop::AnyEvent>, L<IO::Async>, L<AnyEvent>

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011, 2016 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

package IO::Async::Loop::AnyEvent2::ElectricBoogaloo;

; use warnings
; use strict

; *VERSION = \'0.003'

; use AnyEvent
    (
    )
; BEGIN
    { my $AE_log = \&AnyEvent::log
    ; no warnings qw
        ( redefine
        )
    ; *AnyEvent::log = sub
        ( $$
        ; @
        )
        { if
            ( $_[0] eq 'fatal'
           && ( $_[1] eq "AnyEvent: IO::Async::Loop::AnyEvent detected - this module is broken by design,\nabuses internals and breaks AnyEvent, will not continue."
             || $_[1] eq "AnyEvent: IO::Async::Loop::AnyEvent detected - that module is broken by\ndesign, abuses internals and breaks AnyEvent - will not continue."
             || $_[1] eq "IO::Async::Loop::AnyEvent detected - that module is broken by\ndesign, abuses internals and breaks AnyEvent - will not continue."
              )
            )
            { return "no :)"
            }
            ; goto
            & $AE_log
        }
    }

; use parent qw
    ( IO::Async::Loop::AnyEvent
    )

; <<''
HAHAHAHA
YOU THINK YOURE THOUGH UH ?
I HAVE ONE WORD FOR YOU
  THE FORCED INDENTATION OF THE CODE
GET IT ?
I DONT THINK SO
YOU DONT KNOW ABOUT MY OTHER CAR I GUESS ?
ITS A CDR
AND IS PRONOUNCED ``CUDDER''
OK YOU FUQIN ANGERED AN EXPERT PROGRAMMER
THIS IS /prog/
YOU ARE ALLOWED TO POST HERE ONLY IF YOU HAVE ACHIEVED SATORI
PROGRAMMING IS ALL ABOUT ``ABSTRACT BULLSHITE'' THAT YOU WILL NEVER COMPREHEND
I HAVE READ SICP
IF ITS NOT DONE YOU HAVE TO
TOO BAD RUBY ON RAILS IS SLOW AS FUCK
BBCODE AND ((SCHEME)) ARE THE ULTIMATE LANGUAGES
ALSO
WELCOME TO /prog/
EVERY THREAD WILL BE REPLIED TO
NO EXCEPTION

