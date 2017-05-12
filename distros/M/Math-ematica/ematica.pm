#                              -*- Mode: Perl -*-
# $Basename: ematica.pm $
# $Revision: 1.16.1.10 $
# Author          : Ulrich Pfeifer
# Created On      : Sat Dec 20 17:05:18 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Wed Apr 27 18:11:36 2005
# Language        : CPerl
# Update Count    : 248
# Status          : Unknown, Use with caution!
#
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
#
#

package Math::ematica;

use strict;
use Carp;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK $AUTOLOAD @FTABLE);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

%EXPORT_TAGS =
  (
   PACKET => [qw(
                 BEGINDLGPKT CALLPKT DISPLAYENDPKT DISPLAYPKT ENDDLGPKT
                 ENTEREXPRPKT ENTERTEXTPKT EVALUATEPKT FIRSTUSERPKT ILLEGALPKT
                 INPUTNAMEPKT INPUTPKT INPUTSTRPKT LASTUSERPKT MENUPKT MESSAGEPKT
                 OUTPUTNAMEPKT RESUMEPKT RETURNEXPRPKT RETURNPKT RETURNTEXTPKT
                 SUSPENDPKT SYNTAXPKT TEXTPKT BEGINDLGPKT CALLPKT DISPLAYENDPKT
                 DISPLAYPKT ENDDLGPKT ENTEREXPRPKT ENTERTEXTPKT EVALUATEPKT
                 FIRSTUSERPKT ILLEGALPKT INPUTNAMEPKT INPUTPKT INPUTSTRPKT LASTUSERPKT
                 MENUPKT MESSAGEPKT OUTPUTNAMEPKT RESUMEPKT RETURNEXPRPKT RETURNPKT
                 RETURNTEXTPKT SUSPENDPKT SYNTAXPKT TEXTPKT
                )],
   TYPE   => [qw(
                 MLTKAEND MLTKAPCTEND MLTKARRAY MLTKCONT MLTKDIM MLTKELEN MLTKEND
                 MLTKERR MLTKERROR MLTKFUNC MLTKINT MLTKNULL MLTKOLDINT MLTKOLDREAL
                 MLTKOLDSTR MLTKOLDSYM MLTKPACKED MLTKPCTEND MLTKREAL MLTKSEND MLTKSTR
                 MLTKSYM
                )],
   FUNC   => [qw(symbol)],
  );

@EXPORT_OK = map @{$EXPORT_TAGS{$_}}, keys %EXPORT_TAGS;

$VERSION = '1.201';

sub AUTOLOAD {
  # This AUTOLOAD is used to 'autoload' constants from the constant()
  # XS function.  If a constant is not found then control is passed
  # to the AUTOLOAD in AutoLoader.

  my $constname;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  my $val = constant($constname, @_ ? $_[0] : 0);
  if ($! != 0) {
    if ($! =~ /Invalid/) {
      $AutoLoader::AUTOLOAD = $AUTOLOAD;
      goto &AutoLoader::AUTOLOAD;
    }
    else {
      croak "Your vendor has not defined Math::ematica macro $constname";
    }
  }
  eval "sub $AUTOLOAD { $val }";
  goto &$AUTOLOAD;
}

bootstrap Math::ematica $VERSION;

1;


__END__

=head1 NAME

Math::ematica - Perl extension for connecting Mathematica(TM)

=head1 SYNOPSIS

  use Math::ematica qw(:PACKET :TYPE :FUNC);

=head1 WARNING

This is B<alpha> software. User visible changes can happen any time.

The module is completely rewritten. Literally no line of the old stuff
is used (don't ask - I've learned a few things since these days
;-). If you are using the old 1.006 version, note that the interface
has changed. If there is an overwhelming outcry, I will provide some
backward compatibility stuff.

Feel free to suggest modifications and/or extensions. I don not use
Mathematica for real work right now and may fail to foresee the most
urgent needs. Even if you think that the interface is great, you are
invited to complete the documentation (and fix grammos and
typos). Since I am no native English speaker, I will delay the writing
of real documentation until the API has stabilized.

I developed this module using Mathematica 3.0.1 on a Linux 2.0.30 box.
I verified that it still works with Mathematica 4.0 for Solaris.  Let
me know, if it B<does> work with other versions of Mathematica or does
B<not> work on other *nix flavors.

The module still compiles fine with Mathematica 5.0 on Linux 2.6 and
libc-2.3.2.

=head1 DESCRIPTION

The C<Math::ematica> module provides an interface to the MathLink(TM)
library. Functions are not exported and should be called as methods.
Therefore the Perl names have the 'ML' prefix stripped.  Since Perl
can handle multiple return values, methods fetching elements from the
link return the values instead of passing results in reference
parameters.

The representation of the data passed between Perl and Mathematica is
straight forward exept the symbols which are represented as blessed
scalars in Perl.

=head1 Exported constants

=over 5

=item PACKET

The C<PACKET> tag identifies constants used as packet types.

  print "Got result packet" if $link->NextPacket == RETURNPKT;

=item TYPE

The C<TYPE> tag identifies constants used as elements types.

  print "Got a symbol" if $link->GetNext == MLTKSYM;

=back

=head1 Exported functions

=over 5

=item FUNC

The C<FUNC> tag currently only contains the C<symbol> function which
returns the symbol for a given name.

  $sym = symbol 'Sin';

=back

=head1 The plain interface

This set of methods gives you direct access to the MathLink function.
Don't despair if you don't know them too much. There is a convenient
layer ontop of them ;-). Methods below are only commented if they do
behave different than the corresponding C functions. Look in your
MathLink manual for details.

=head2 C<new>

The constructor is just a wrapper around C<MLOpenArgv>.

  $ml = new Math::ematica '-linklaunch', '-linkname', 'math -mathlink';

The link is automatically activated on creation and will be closed
upon destruction.  So C<MLCloseLink> is not accessible; use C<undef>
or lexical variables to store links.  If you use a global variable and
dont force the link close, you will get an optional warning during
global destruction.

=head2 C<ErrorMessage>

  print $link->ErrorMessage;

=head2 C<EndPacket>

=head2 C<Flush>

=head2 C<NewPacket>

=head2 C<NextPacket>

=head2 C<Ready>

=head2 C<PutSymbol>

=head2 C<PutString>

=head2 C<PutInteger>

=head2 C<PutDouble>

=head2 C<PutFunction>

=head2 C<GetNext>

=head2 C<GetInteger>

=head2 C<GetDouble>

=head2 C<GetString>

The method does the appropriate C<MLDisownString> call for you.

=head2 C<GetByteString>

The method does the appropriate C<MLDisownByteString> call for you.

=head2 C<GetSymbol>

The module does the appropriate C<MLDisownSymbol> call for you.  It
also blesses the result string into the package
C<Math::ematica::symbol>.

=head2 C<Function>

Returns the function name and argument count in list context. In
scalar contex only the function name is returned.

=head2 C<GetRealList>

Returns the array of reals.

=head1 The convenience interface

=head2 C<PutToken>

Puts a single token according to the passed data type.

  $link->PutToken(1);               # MLPutInteger

Symbols are translated to C<MLPutFunction> if the arity is provided as
aditional parameter.

  $link->PutToken(symbol 'Pi');     # MLPutSymbol
  $link->PutToken(symbol 'Sin', 1); # MLPutFunction

=head2 C<read_packet>

Reads the current packet and returns it as nested data structure.  The
implementaion is not complete. But any packet made up of C<MLTKREAL>,
C<MLTKINT>, C<MLTKSTR>, C<MLTKSYM>, and C<MLTKFUNC> should translate
correctely. A function symbol C<List> is dropped automatically. So the
Mathematica expression C<List[1,2,3]> translates to the Perl
expression C<[1,2,3]>.

I<Mabybe this is >B<too>I< convenient?>.

=head2 C<call>

Call is the main convenience interface. You will be able to do most if
not all using this call.

Note that the syntax is nearly the same as you are used to as
I<FullForm> in Mathematica.  Only the function names are moved inside
the brackets and separated with ',' from the arguments. The method
returns the nested data structures read by C<read_packet>.

  $link->call([symbol 'Sin', 3.14159265358979/2]); # returns something near 1

To get a table of values use:

  $link->call([symbol 'Table',
               [symbol 'Sin', symbol 'x'],
               [symbol 'List', symbol 'x',  0, 1, 0.1]]);

This returns a reference to an array of doubles.

You may omit the first C<symbol>. I<Maybe we should choose the default
mapping to >B<Symbol>I< an require >B<Strings>I<s to be marked?>

=head2 C<install>

If you find this too ugly, you may C<install> Mathematica functions as
Perl functions using the C<install> method.

  $link->install('Sin',1);
  $link->install('Pi');
  $link->install('N',1);
  $link->install('Divide',2);

  Sin(Divide(Pi(),2.0)) # should return 1 (on machines which can
                        # represent '2.0' *exactely* in a double ;-)

The C<install> method takes the name of the mathematica function, the
number of arguments and optional the name of the Perl function as
argument.

  $link->install('Sin',1,'sin_by_mathematica');

Make shure that you do not call any I<installed> function after the
C<$link> has gone. Wild things will happen!

=head2 C<send_packet>

Is the sending part of C<call>. It translates the expressions passed
to a Mathematica package and puts it on the link.

=head2 C<register>

This method allows to register your Perl functions to Mathematica.
I<Registered> functions may be called during calculations.

  sub addtwo {
    $_[0]+$_[1];
  }

  $link->register('AddTwo', \&addtwo, 'Integer', 'Integer');
  $link->call([symbol 'AddTwo',12, 3]) # returns 15

You may register functions with unspecified argument types using undef:

  sub do_print {
    print @_;
  }
  $link->register('DoPrint', undef);
  $link->call(['DoPrint',12]);
  $link->call(['DoPrint',"Hello"]);

=head2 C<main>

This method allows to have Perl scripts installed in a running
Mathematica session.  The Perl script F<try.pl> might look like this:

  use Math::ematica;
  sub addtwo {
    my ($x, $y) = @_;
  
    $x + $y;
  }
  $ml->register('AddTwo', \&addtwo, 'Integer', 'Integer');
  $ml->main;
  
Inside the Mathematica do:

  Install["try.pl"]
  AddTwo[3,5];

Admittedly, adding two numbers would be easier inside Mathematica. But
how about DNS lookups or SQL Databases?

=head1 AUTHOR

Ulrich Pfeifer E<lt>F<pfeifer@wait.de>E<gt>

=head1 SEE ALSO

See also L<perl(1)> and your Mathematica and MathLink
documentation. Also check the F<t/*.t> files in the distribution.

=cut

sub send_packet {
  my $link = shift;

  $link->_send_packet(@_);
  $link->EndPacket;
  $link->Flush;
}

# The following is a cludge. The goal ist to make the Perl syntax the
# same as the mathematica syntax execpt that the opening '[' are move
# one token left:
# Mathematica Perl
# Sin[x]      [Sin, x]
# Pi          Pi
# Blank[]     [Blank]

sub _send_packet {
  my $link  = shift;

  while (@_) {
    my $elem = shift;
    if (ref $elem eq 'ARRAY') {
      $link->_send_call(@$elem);
    } else {
      $link->PutToken($elem);   # PutSymbol in doubt
    }
  }
}

sub _send_call {
  my ($link, $head, @tail)  = @_;

  if (ref $head eq 'ARRAY') {
    $link->_send_call(@$head);
  } else {
    $link->PutToken($head, scalar @tail) # PutFunction in doubt
  }
  while (@tail) {
    my $elem = shift @tail;
    if (ref $elem eq 'ARRAY') {
      $link->_send_call(@$elem);
    } else {
      $link->PutToken($elem); # PutSymbol in doubt
    }
  }
}

sub register {
  my ($link, $name, $code, @args) = @_;
  my $fno = @FTABLE;
  my @parm;
  my $var = 'aaaa';

  push @FTABLE, $code;
  $FTABLE[$fno] = $code;
  my @list = (symbol 'List');

  for my $type (@args) {
    if (defined $type) {
      push @parm, [symbol 'Pattern', symbol $var, [ symbol 'Blank', symbol $type ]];
    } else {
      push @parm, [symbol 'Pattern', symbol $var, [ symbol 'Blank']];
    }
    push @list, symbol $var;
    $var++;
  }
  $link->call([symbol 'SetDelayed',
               [symbol $name, @parm],
               [symbol 'ExternalCall',
                [symbol 'LinkObject', "ParentLink", 1, 1],
                [symbol 'CallPacket', $fno, \@list]]]);
}

sub do_callback {
  my $link = shift;

  my $func_no = $link->read_packet;
  my $args = $link->read_packet;
  if ($FTABLE[$func_no]) {
    my @result;
    if (ref $args eq 'ARRAY') {
      @result = $FTABLE[$func_no]->(@$args);
    } else {
      @result = $FTABLE[$func_no]->();
    }
    $link->send_packet(@result);
  }
}

sub call {
  my $link = shift;
  my $fname = shift;

  # first argument may be symbol name instead of a symbol
  $fname = symbol $fname unless ref $fname;
  $link->send_packet($fname, @_);
  $link->dispatch unless $link->{passive};
}

sub dispatch {
  my $link = shift;
  
  $link->NewPacket;
  while (my $packet = $link->NextPacket) {
    if ($packet == RETURNPKT) {
      return $link->read_packet;
    } elsif ($packet == MESSAGEPKT) {
      return $link->read_packet;
    } elsif ($packet == TEXTPKT) {
      return $link->read_packet;
    } elsif ($packet == CALLPKT) {
      $link->do_callback;
    } elsif ($packet == DISPLAYPKT) {
      $link->GetNext() == MLTKSTR  or die "Expected DISPLAYPKT to start with 'MLTKSTR'";
      $link->GetByteString() eq '' or die "Expected DISPLAYPKT to start with empty string";
      # $link->GetNext() == MLTKFUNC or die "Expected DISPLAYPKT to contain 'MLTKFUNC'";
      my $result = '';
      while ($link->GetNext() == MLTKFUNC) {
        my ($name, $nargs) = $link->GetFunction();
        $$name eq "DisplayPacket"  or
          $$name eq "DisplayEndPacket" or die "Expected 'DisplayPacket' symbol in DISPLAYPKT, not '$$name'";
        $nargs == 1                  or die "Expected 'DisplayPacket'to habe one argument only";
        $result .= $link->GetByteString();
        return $result if $$name eq "DisplayEndPacket";
      }
    } elsif ($packet == INPUTNAMEPKT) {
      next;
    } else {
      warn "Ignoring Unkown packet: $packet\n";
      return;
    }
  }
  $link->NewPacket;
}

sub main {
  my $link = shift;

  $link->PutSymbol('End');
  $link->Flush;
  delete $link->{passive};
  $link->NewPacket;
  while (my $packet = $link->NextPacket) {
    if ($packet == CALLPKT) {
      $link->do_callback;
    } else {
      warn "Ignoring Unkown packet: $packet\n";
    }
  }
}

sub install {
  my ($link, $name, $nargs, $alias) = @_;
  my $package   = caller;
  $alias ||= $name;

  # This is very bad style. We steal the C pointer from $link since
  # DESTROY will not be called for it unless the function we generate
  # is undefined. Perl would die horribly when Perl_destruct would
  # encouter a blessed reference in the padlist of the function.
  # So *never* call the installed function after dropping $link!!!

  my $ptr = $link->{'mlink'};
  my $func = sub {
    my $link = bless {mlink => $ptr}, 'Math::ematica'; # this is the *nono*!
    my $result;
    
    if (defined $nargs) {
      die "${package}::$alias must be called with $nargs arguments\n"
        if $nargs != @_;
        $result    = $link->call([symbol($name), @_]);
    } else {
      die "${package}::$alias must be called with $nargs arguments\n"
        if @_;
        $result    = $link->call(symbol($name));
    }
    $link->{mlink} = 0;         # make DESTROY less harmfull
    $result;
  };

  no strict 'refs';
  *{"${package}::$alias"} = $func;
}

=head1 ACKNOWLEDGEMENTS

I wish to thank Jon Orwant of I<The Perl Journal>, Nancy Blachman from
I<The Mathematica Journal> and Brett H. Barnhart from I<Wolfram
Research>

Jon brought the earlier versions of this module to the attention of
Nancy Blachman. She in turn did contact Brett H. Barnhart who was so
kind to provide a trial license which made this work possible.

So subscribe to I<The Perl Journal> and I<The Mathematica Journal> if
you are not subscribed already if you use this module (a Mathematica
license is needed anyway). You would be nice to nice people and may
even read something more about this module one day ;-)

Special thanks to Randal L. Schwartz for naming this module.

Thanks also to Richard Jones for providing a login on a Solaris box so
that I could check that the module still works with Mathematica 4.0.

=head1 Copyright

The B<Math:ematica> module is Copyright (c) 1996,1997,1998,2000,2005 Ulrich
Pfeifer. Germany.  All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

B<Mathematica> and B<MathLink> are registered trademarks of Wolfram
Research.

=cut

