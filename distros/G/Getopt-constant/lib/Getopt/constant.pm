
require 5.003_96; # Time-stamp: "2004-12-29 19:27:33 AST"
 # same minimal version required as constant.pm

package Getopt::constant;
$VERSION = '1.03';
use strict;

sub import {
  shift(@_); # We don't care about our own package name

  my(%h) = (@_); # Get default values from there.
  my $pkg    = caller;
  my $pref   = delete( $h{':prefix'} ) || '';
  my $usage  = delete( $h{':usage' } ); # a usage message to throw at people
  my $retain = delete( $h{':retain'} ); # if we should not change @ARGV
  my $permissive = delete( $h{':permissive'} );
    # if we should just skip weird things
  my($x, @unknowns, @orig_ARGV);
  @orig_ARGV = @ARGV if $retain;

  while(@ARGV) {
    $x = $ARGV[0];
    #print "Considering \"$x\"\n";
    if($x eq '-') {
      # Deceptively not part of the options list, so bail.
      last;
    } elsif($x eq '--') {
      # End of options list.
      shift @ARGV;
      last;
    } elsif($x =~ m<--?([^=]+)=([^=]*)>s ) {  # like -foo=123 or --foo=123
      if(!exists $h{$1}) {
	push @unknowns, $1 unless $permissive;
      } elsif(ref($h{$1} || '') eq 'ARRAY') {
	my($name) = $1;
	@{$h{$name}} = split(",", $2, -1);
      } else {
	$h{$1} = $2;
      }
      shift @ARGV;

    } elsif($x =~ m<--?([^=]+)>s ) {  # like -foo or --foo
      if(!exists $h{$1}) {
	push @unknowns, $1 unless $permissive;
      } elsif(ref($h{$1} || '') eq 'ARRAY') {
	@{$h{$1}} = (1); # guh, I guess that's right.
      } else {
	$h{$1} = 1;
      }
      shift @ARGV;

    } elsif(length $x and substr($x,0,1) eq '-') {
      push @unknowns, "\"$x\"" unless $permissive;

    } else {
      last;  # First non-option in @ARGV
    }
  }

  @ARGV = @orig_ARGV if $retain;

  if(@unknowns) {
    if(ref($usage || '') eq 'CODE') {
      $usage->(\@unknowns, [sort grep !m/^:/s, keys %h], \%h);
    } else {
      printf STDERR "Unknown option%s: %s\n",
	(@unknowns == 1) ? '' : 's', join(' ', @unknowns);
      if(defined $usage) {
	print  STDERR $usage
      } else {
	my(@x) = sort grep !m/^:/s, keys %h;
	print STDERR
	   (@x == 1) ?
	   '(The only known option is: ' : '(The known options are: ',
           join(', ', @x), ")\n";
      }
    }
    
    if($] <= 5.00599) {
      exit;
       # Because if we put a 1 there, those versions of Perl will emit
       #  a nasty "Callback called exit" message.  Ah well.
    } else {
      exit 1;
    }
  }

  while( my($name,$value) = each %h) {
    next unless length($name) and substr($name,0,1) ne ':';
    no strict 'refs';
    if(ref($value || '') eq 'ARRAY') {
      #print "Setting ${pkg}::$pref$name to the list (@$value)\n";
      *{"${pkg}::$pref$name"} = sub () { @$value };
    } else {
      #print "Setting ${pkg}::$pref$name to $value\n";
      *{"${pkg}::$pref$name"} = sub () {  $value };
    }
  }

  return;
}
# Yup, that's it.
###########################################################################
1;

__END__

=head1 NAME

Getopt::constant -- set constants from command line options

=head1 SYNOPSIS

  # Assuming @ARGV is: ('-foo=9,8,7', '-bar', 'wakawaka.txt')
  use Getopt::constant (
    ':prefix' => 'C_',
    'foo' => [3,5],
    'bar' => 0,
    ':usage' =>
  "Usage:
  thingamabob
    -foo=one,two,three  :  fooey on these items
    -bar                :  enable barriness
  ",
  );
  # @ARGV is now 'wakawaka.txt', and you've now got
  #  a constant C_foo with value (9,8,7)
  #  and a constant C_bar with value 1

=head1 DESCRIPTION

Other command-line options processing modules (like Getopt::Std)
parse command-line arguments (from @ARGV) and set either variables or
hash entries based on them.  This module, however, parses command-line
arguments into constants which are put into the current package.

You provide default values for each constant in the list that you pass
in the "use Getopt::constant (...);" statement.  Values can be a scalar
(in which case you will get a scalar constant) or an arrayref (in
which case you will get a list constant).

=head1 OPTIONS

=over

=item ":prefix" => STRING,

Constants are named by putting the value
of the ":prefix" option
(which can be empty-string) before the option name.  For
an example, read the SYNOPSIS section above.

Default is empty-string, C<"">.  A common useful value you
should consider is C<"C_">.

You should not use a value, like "*" or "-" or "1" that can't begin a
legal Perl symbol name.

=item ":permissive" => BOOL,

Normally, if Getopt::constant is parsing the options in @ARGV and
finds an unknown item, this causes a fatal error.  For example, if
your call to C<use Getopt::constant (...)> didn't mention a

    'foo' => some_value,

then when Getopt::constant gets to parsing "-foo=1", it would
exit with a message to STDERR, as determined by the value of the
":usage" parameter.

However, if the ":permissive" parameter is set to a true value,
then unknown items are simply ignored.

The default value is 0.

=item ":usage" => VALUE,

When Getopt::constant hits a command-line switch that attempts to set
an option that's not in its list of known options, this is considered
a fatal error, unless the ":permissive" option has been set to true
(in which case it is simply ignored).

What happens in the case of a fatal error is controlled by the
":usage" parameter's value:

If it's a string, then on STDERR we print "Unknown options: ", and the
list of the unknown options, and a newline and then the string value
of the ":usage" parameter (which should presumably be something
explaining what the valid parameters are, and what they mean); and
then the program exits.

If it's undef (which is the default value), then on STDERR we print
"Unknown options: ", and the list of the unknown options and a
newline, and then on the next line, the list of all permitted options;
and then the program exits.

If it's a code ref, then the code ref is called with three options: a
reference to the array of unknown options found, a reference to the
array of options allowed, and a reference to the hash consisting of
the elements passed in the 'C<use Getopt::constant (...)>;' statement.
For example, if you said:

    use Getopt::constant (
      ':prefix' => 'C_',
      'foo' => [3,5],
      'bar' => 0,
      ':usage' => sub {...},
    );

and there's a "-baz" in @ARGV, then the specified sub will be called as

    $thatsub->(
      ['baz'],
      ['foo','bar'],
      { ':prefix' => 'C_',
        'foo' => [3,5],
        'bar' => 0,
        ':usage' => sub {...},
      }
    );

and then once that sub returns, the program exits.

=item ":retain" => BOOL,

This controls whether (1) or not (0) parsed options are removed
from @ARGV.

Default is 0 -- to remove parsed items from @ARGV.

If you want to parse the options in @ARGV first with Getopt::constant
and then with something like Getopt::Std, you should consider:

    ":retain" => 1,  ":retain" => 1,

(Although note that this is only a partial solution: consider an
argument list of C<qw(-foo 13 -bar)> which you want to be parsed by
Getopt::constant and then by Getopt::Long.  Getopt::Long will parse it
as you expect, but Getopt::constant has a more restricted view of
switch parsing and will stop parsing at "13".)

=item ":I<whatever>" => any_value,

Assignments to parameters beginning with ":", other than the ones mentioned
above, have no effect.

=item "option_name" => [ ...list elements... ]

Specifies a default list value for that option.  The option name
should be a legal Perl symbol name (e.g., "thing_1", "Thing_1", and
"THING_1" are all okay -- "thing 1", "thing-1", "1thing" are not.)

=item "option_name" => value

Specifies a default scalar value for that option.
The option name should be a legal Perl symbol name.

=back

=head1 SWITCH PARSING

As Getopt::constant parses thru the items in @ARGV, it expects @ARGV to
start with some number of switches; it stops parsing when it hits the
first non-switch item.

A switch consists of one of the following syntaxes:

=over

=item -foo or --foo

This sets option "foo" to 1 if it's to be a scalar constant
(as it usually is), or sets "foo" to [1] if it's to be a list constant.
(Which it is, is determined by whether you said "foo => VALUE" or "foo
=> [...]" in your parameters to "use Getopt::constant (...)").

=item -foo=VALUE or --foo=VALUE

This sets option "foo" to VALUE if it's to be a scalar constant
(as it usually is); or if it's to be a list constant, then
it's set to:

      split(",", VALUE, -1)

Note that VALUE may be empty-string.  I.e., "-foo=", is a legal
switch which sets foo to empty-string, or empty-list if foo is
to be a list constant.

=item --

(That's two hyphens in a row, not one.)  This signals the end
of the parameter list.

=back

Note that switches of the form:

      % progname.pl -foo VALUE

are not recognized; you need to express that as one of:

      % progname.pl -foo=VALUE
      % progname.pl --foo=VALUE

=head1 SEE ALSO

L<constant>, L<Getopt::Long>, L<Getopt::Std>

=head1 WHY?

Consider this:

    use Getopt::constant ('DEBUG' => 0);
  ...
    print "Starting doing things...\n" if DEBUG;
  ...
    foreach $thing (@many_things) {
      print " About to do things with $thing\n" if DEBUG > 1;
      ...
    }
  ...
    DEBUG and printf "Done doing things at %s after %s sec.\n",
      scalar(localtime), time - $^T;

What's the point of doing this, as opposed to using Getopt::Std to set
a C<$DEBUG> that we'd use everywhere where we have a C<DEBUG> above?
Well, every time an expression consisting of a variable, or involving
a variable (like "C<$DEBUG E<gt> 1>") is encountered, it has to be
evaluated.  That means that in every iteration of the loop, the
expression "C<$DEBUG E<gt> 1>" would have to be evaluated anew, since
Perl has no assurance that C<$DEBUG>'s value can't have changed since
the last iteration.  But, with constants, or expressions involving
constants, Perl evaluates them only once, at compile time.  So if Perl
knows that the constant DEBUG has the value 2, then the expression

      print " About to do things with $thing\n" if DEBUG > 1;

turns into:

      print " About to do things with $thing\n";

as Perl compiles it.

But more importantly, if Perl knows DEBUG is 0 (or anything such that
"DEBUG > 1" is false) then the above statement is actually removed
from the in-memory compiled version of the program, before it is
actually run.

Incidentally, you can, with some doing, use any other Getopt library
to make constants, using something like:

  #...Assuming an @ARGV of qw( -D4 -x9 stuff )...
  
  use strict;
  my %opts;
  BEGIN { # constants need to be made at compile time!
    %opts = ( 'D' => 0, 'y' => 'nope', 'x' => 3 ); # default values
    
    use Getopt::Std ();
    Getopt::Std::getopt('Dxy', \%opts);
    
    require constant;
    # Now make constants from whatever we want:
    constant->import('D',   $opts{'D'});
    constant->import('C_y', $opts{'y'});
  }
  print "ARGV is @ARGV\n";
  printf "D is %s, C_y is %s, and opts-x is %s\n", D, C_y, $opts{'x'};

That prints:

  ARGV is stuff
  D is 4, C_y is nope, opts-x is 9

That's obviously a bit circuitous, but it's quite doable.

=head1 COPYRIGHT AND DISCLAIMER

Copyright (c) 2001 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke, sburke@cpan.org

=cut

# Test code:

BEGIN { @ARGV = qw(-fooz -bar=4,5,6) }
  # Assuming @ARGV is: ('-foo=9,8,7', '-bar', 'wakawaka.txt')
  use Getopt::constant (
    ':prefix' => 'C_',
    'foo' => [3,5],
    'bar' => 0,
    ':usage' =>
  "Usage:
  thingamabob
    -foo=one,two,three  :  fooey on these items
    -bar                :  enable barriness
  \n",
  );
  # @ARGV is now 'wakawaka.txt', and you've now got
  #  a constant C_foo with value (9,8,7)
  #  and a constant C_bar with value 1
print C_bar;

  BEGIN{    @ARGV = qw( -D4 -x9 stuff ); }
  #...Assuming an @ARGV of qw( -D4 -x9 stuff )...

  use strict;
  my %opts;
  BEGIN {
    %opts = ( 'D' => 0, 'y' => 'nope', 'x' => 3 ); # default values

    use Getopt::Std ();
    Getopt::Std::getopt('Dxy', \%opts);

    require constant;
    # Now make constants from whatever we want:
    constant->import('D',   $opts{'D'});
    constant->import('C_y', $opts{'y'});
  }
  print "ARGV is @ARGV\n";
  printf "D is %s, C_y is %s, and opts-x is %s\n", D, C_y, $opts{'x'};

Prints:

  ARGV is stuff
  D is 4, C_y is nope, opts-x is 9
