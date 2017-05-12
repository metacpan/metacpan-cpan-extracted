package Devel::GDB::Breakpoint;
use 5.006000;

BEGIN {
	$Devel::GDB::Breakpoint::VERSION = '0.02';
}

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(breakpoint);

require XSLoader;
XSLoader::load('Devel::GDB::Breakpoint', $Devel::GDB::Breakpoint::VERSION);

1;
__END__

=head1 NAME

Devel::GDB::Breakpoint - Create easily identifiable gdb breakpoints in Perl code.

=head1 SYNOPSIS

In some Perl program (prog.pl):

  #!/usr/bin/perl
  
  use strict;
  use warnings;
  
  use Devel::GDB::Breakpoint;
  
  print "before\n";
  
  breakpoint 42;
  
  print "after\n";

Then:

  $ gdb --args perl ./prog.pl
  ...

  (gdb) b bp if val == 42
  Function "bp" not defined.
  Make breakpoint pending on future shared library load? (y or [n]) y
  
  Breakpoint 1 (bp if val == 42) pending.
  (gdb) run
  Starting program: /usr/bin/perl prog.pl
  [Thread debugging using libthread_db enabled]
  before

  Breakpoint 1, bp (val=42) at Breakpoint.xs:7
  7       void bp(int val) {}
  (gdb)

=head1 DESCRIPTION

This module allows you to inject breakpoints into your Perl code that you can 
easily identify with gdb.

It exports the C<breakpoint> sub at runtime which can be called from any Perl 
code with an integer value as its argument. When the Perl codepoint is reached, 
the module calls a C function called C<bp> with the argument you gave as its 
only parameter, which is named C<val>.

IE, in Perl:

  breakpoint 3;

Equates to:

  void bp(int val) {};

  bp(3);

Which allows you in gdb to set breakpoints like so:

  (gdb) b bp if val == 3
  ...

=head1 WHY WOULD I WANT THIS?

I'm really not sure you would.

But it may be useful if you want to break at different points in a large 
program and don't want to maintain a list of Perl_pp_* methods you haven't used 
yet to create unique breakpoints.

Alternatively, in Perl you can:

  study;

And then in gdb:

  (gdb) b Perl_pp_study

If you want to break during parsing, you can:

  BEGIN { breakpoint 5; }

Or

  BEGIN { study; }

If you want to break during parsing inside of if blocks and other places 
however, see L<Devel::GDB::Parser::Breakpoint>.

=head1 SEE ALSO

L<Devel::GDB::Parser::Breakpoint> - Create easily identifiable gdb breakpoints in Perl parser code.

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Matthew Horsfall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
