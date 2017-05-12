package Devel::GDB::Parser::Breakpoint;

BEGIN {
	$Devel::GDB::Parser::Breakpoint::VERSION = '0.02';
}

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(parser_breakpoint);

use Devel::GDB::Breakpoint;
use Parse::Keyword { parser_breakpoint => \&parser_breakpoint_parser };

sub parser_breakpoint { 1 };

sub parser_breakpoint_parser {
    lex_read_space;

    my $num;
    while (my $c = lex_peek) {
        if ($c =~ /^[0-9]$/) {
            $num .= $c;
            lex_read(1); # consume
        } else {
            last;
        }
    }

    unless ($num) {
        die "syntax error. Usage: parser_breakpoint { <integer> }";
    }

    # Trigger bp(...)
    breakpoint(0+$num);

    return (sub {}, 0);
}

1;
__END__

=head1 NAME

Devel::GDB::Parser::Breakpoint - Create easily identifiable gdb breakpoints in Perl parser code.

=head1 SYNOPSIS

In some Perl program (prog.pl):

  #!/usr/bin/perl
  
  use strict;
  use warnings;
  
  use Devel::GDB::Parser::Breakpoint;
  
  print "before\n";
  
  # Call bp(42) during parsing of this line
  parser_breakpoint 42;
  
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

  Breakpoint 1, bp (val=42) at Breakpoint.xs:7
  7       void bp(int val) {}
  (gdb)

=head1 DESCRIPTION

This module allows you to inject breakpoints into the parsing of your Perl
code by the perl binary that you can easily identify with gdb.

It exports the C<parser_breakpoint> sub at runtime which can be called from any 
Perl code with an integer value as its argument. When the perl lexer/parser 
reaches the line, the module calls a C function called C<bp> with the argument 
you gave as its only parameter, which is named C<val>.

IE, in Perl:

  parser_breakpoint 3;

Equates to:

  void bp(int val) {};

  bp(3);

Which allows you in gdb to set breakpoints like so:

  (gdb) b bp if val == 3
  ...

Note that parser_breakpoint always returns the value 1. It can be used
in complex statements/expressions to see what's going on:

  if ($x && $y && parser_breakpoint 2 && $z) { ... }

And since it happens at lexer/parser time, it will still execute here:

  if (0 && parser_breakpoint 3) { ... }

=head1 WHY WOULD I WANT THIS?

I'm really not sure you would.

But it may be useful if you want to easily see what the perl lexer/parser is 
doing as it reads different parts of your source.

Alternatively, in Perl you can:

  BEGIN { study; }

And in gdb:

  (gdb) b Perl_pp_study

However, this doesn't allow you to break inside of if blocks like in the 
examples above.

=head1 COMPATIBILITY

This module requires at least Perl 5.11.2 because of pluggable keywords. See 
L<perlapi/"PL_keyword_plugin"> for more information.

=head1 SEE ALSO

L<Devel::GDB::Breakpoint> - Create easily identifiable runtime gdb breakpoints 
in Perl code

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Matthew Horsfall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
