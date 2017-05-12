[![Build Status](https://travis-ci.org/brummett/Devel-Chitin.png?branch=master)](https://travis-ci.org/brummett/Devel-Chitin)
## Devel::Chitin

Programmatic interface to the Perl debugging API

This class exposes the Perl debugging facilities as an API useful for
implementing debuggers, tracers, profilers, etc so they can all benefit from
common code.

Devel::Chitin is not a usable debugger per se.  It has no mechanism for interacting
with a user such as reading command input or printing retults.  Instead,
clients of this API may call methods to inspect the debugged program state.
The debugger core calls methods on clients when certain events occur, such
as when the program is stopped by breakpoint or when the program exits.
Multiple clients can attach themselves to Devel::Chitin simultaneously within
the same debugged program.
