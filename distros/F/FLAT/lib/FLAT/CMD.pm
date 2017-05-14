package FLAT::CMD;
use FLAT;
use FLAT::Regex;
use FLAT::NFA;
use FLAT::DFA;
use Carp;

=head1 NAME

CMD - Commandline interface for the Formal Language & Automata Toolkit

=head1 SYNOPSIS

CMD.pm is provides an interface to the C<fash> commandline utility that offers
certain features implemented in FLAT.  Consequently, this interface is also
available using the C<perl -MFLAT::CMD -e func> paradigm, but C<fash> makes
things a lot more convenient.

=head1 USAGE

All regular language objects in FLAT implement the following methods.
Specific regular language representations (regex, NFA, DFA) may implement
additional methods that are outlined in the repsective POD pages.

=cut

# Support for perl one liners - like what CPAN.pm uses #<- should move all to another file
use base 'Exporter'; #instead of: use Exporter (); @ISA = 'Exporter';
use vars qw(@EXPORT $AUTOLOAD);

@EXPORT = qw(compare dump dfa2gv nfa2gv pfa2gv dfa2undgv nfa2undgv pfa2undgv dfa2digraph
	     nfa2digraph pfa2digraph dfa2undirected nfa2undirected pfa2undirected random_pre random_re
             savedfa test help
	     );

sub AUTOLOAD {
    my($l) = $AUTOLOAD;
    $l =~ s/.*:://;
    my(%EXPORT);
    @EXPORT{@EXPORT} = '';
    if (exists $EXPORT{$l}){
	FLAT::CMD->$l(@_);
    }
}

sub help {
print <<END
__________             .__    ___________.____         ___________
\______   \ ___________|  |   \_   _____/|    |   _____\__    ___/
 |     ___// __ \_  __ \  |    |    __)  |    |   \__  \ |    |   
 |    |   \  ___/|  | \/  |__  |     \   |    |___ / __ \|    |   
 |____|    \___  >__|  |____/  \___  /   |_______ (____  /____|   
               \/                  \/            \/    \/    
	       
  Everything is wrt parallel regular expressions, i.e., 
  with the addtional shuffle operator, "&".  All this 
  means is that you can use the ambersand (&) as a symbol
  in the regular expressions you submit because it will be 
  detected as an operator.That said, if you avoid using
  the "&" operator, you can forget about all that shuffle
  business.

%perl -MFLAT::CMD -e
    "somestrings" 're1'       # creates all valid strings via acyclic path, no cycles yet
    "compare  're1','re2'"   # comares 2 regexs | see note [2] 
    "dump     're1'"         # dumps parse trees | see note[1]	   
    "dfa2gv  're1'"          # dumps graphviz digraph desc | see note[1]  
    "nfa2gv  're1'"          # dumps graphviz digraph desc | see note[1]  
    "pfa2gv  're1'"          # dumps graphviz digraph desc | see note[1]  
    "dfa2undgv  're1'"       # dumps graphviz undirected graph desc | see note[1]  
    "nfa2undgv  're1'"       # dumps graphviz undirected graph desc | see note[1]  
    "pfa2undgv  're1'"       # dumps graphviz undirected graph desc | see note[1]  
    "dfa2digraph 're1'"      # dumps directed graph without transitions
    "nfa2digraph 're1'"      # dumps directed graph without transitions
    "pfa2digraph 're1'"      # dumps directed graph without transitions
    "dfa2undirected 're1'"   # dumps undirected graph without transitions
    "nfa2undirected 're1'"   # dumps undirected graph without transitions
    "pfa2undirected 're1'"   # dumps undirected graph without transitions
     random_pre 
     random_re
    "savedfa 're1'"          # converts PRE to min dfa, then serializes to disk
    "test 'regex' 'string1'" # give a regex, reports if subsequent strings are valid
     help

NOTES:
[1] This means you could presumably do something like the following:
    %perl -MFLAT -e command < text_file_with_1_regex_per_line.txt
                    ^^^^^^^   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
[2] This command compares the minimal DFAs of each regular expression;
    if there exists a exact 1-1 mapping of symbols, states, and 
    transitions then the DFAs are considered equal.  This means that 
    "abc" will be equal to "def"  To make matters more confusing, "ab+ac" 
    would be equivalent to "xy+xz"; or worse yet, "z(x+y)". So to the 
    'compare' command, "ab+ac" == "xy+xz" == "z(x+y)". This however 
    does not translate into the situation where "ab+ac" will accept 
    the same LITERAL strings as "z(x+y)" because the symbols are obviously
    different.	    
		   
CREDITS:
Blockhead, CPAN.pm (for the example of how to implement these one liners), 
and #perl on irc.freenode.net for pointing out something I missed when 
trying to copy CPAN one liner majik.

Perl FLAT and all included modules are released under the same terms as Perl
itself.  Cheers.

SEE:
http://www.0x743.com/flat

END
}

# save to a dat file
sub savedfa {
    my $PRE = shift;
    # neat a better way to get input via stdin
    if (!$PRE) {
      while (<>) {
        chomp;
        $PRE = $_;
        last;
      }
    } 
    use FLAT::Regex::WithExtraOps;
    use FLAT::PFA;
    use FLAT::NFA;
    use FLAT::DFA;
    use Storable;
    # caches results, loads them in if detexted
    my $dfa = FLAT::Regex::WithExtraOps->new($PRE)->as_pfa->as_nfa->as_dfa->as_min_dfa->trim_sinks;
    store $dfa, "$PRE.dat";
}

# dumps directed graph using Kundu notation
# Usage:
# perl -MFLAT -e "pfa2directed('a&b&c&d*e*')"
sub test {
  use FLAT::Regex::WithExtraOps;
  use FLAT::PFA;
  use FLAT::NFA;
  use FLAT::DFA;
  # handles multiple strings; first is considered the regex
  if (@_) 
  { my $FA = FLAT::Regex::WithExtraOps->new(shift @_)->as_pfa()->as_nfa->as_dfa(); 
    foreach (@_)
    { if ($FA->is_valid_string($_)) {
        print "(+): $_\n";
      } else {
        print "(-): $_\n";
      }     
    } 
  } else {
    my $FA;
    while (<STDIN>) {
      chomp;
      if ($. == 1) { #<-- uses first line as regex!
        $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa->as_dfa();
      } else {
	if ($FA->is_valid_string($_)) {
	  print "(+): $_\n";
        } else {
	  print "(-): $_\n";
	}      
      }
    }
  }
}

# dumps parse tree
# Usage:
# perl -MFLAT -e "dump('re1','re2',...,'reN')"
# perl -MFLAT -e dump < list_of_regexes.dat
sub dump {
  use FLAT::Regex::WithExtraOps;
  use Data::Dumper;
  if (@_) 
  { foreach (@_)
    { my $PRE = FLAT::Regex::WithExtraOps->new($_);
      print Dumper($PRE); }} 
  else    
  { while (<STDIN>) 
     { chomp;
       my $PRE = FLAT::Regex::WithExtraOps->new($_);
       print Dumper($PRE); }
  }
}

# dumps graphviz notation
# Usage:
# perl -MFLAT -e "dfa2gv('a&b&c&d*e*')"
sub dfa2gv {
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa()->as_min_dfa()->trim_sinks();
      print $FA->as_graphviz;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa()->trim_sinks();
       print $FA->as_graphviz;} 
  }
}

# dumps graphviz notation
# Usage:
# perl -MFLAT -e "nfa2gv('a&b&c&d*e*')"
sub nfa2gv {
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
      print $FA->as_graphviz;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
       print $FA->as_graphviz;} 
  }
}

# dumps graphviz notation
# Usage:
# perl -MFLAT -e "pfa2gv('a&b&c&d*e*')"
sub pfa2gv {
  use FLAT::Regex::WithExtraOps;
  use FLAT::PFA;
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
      print $FA->as_graphviz;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
       print $FA->as_graphviz;} 
  }
}

#as_undirected_graphviz

# dumps graphviz notation
# Usage:
# perl -MFLAT -e "dfa2undgv('a&b&c&d*e*')"
sub dfa2undgv {
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa()->as_min_dfa()->trim_sinks();
      print $FA->as_undirected_graphviz;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa()->trim_sinks();
       print $FA->as_undirected_graphviz;} 
  }
}

# dumps graphviz notation
# Usage:
# perl -MFLAT -e "nfa2undgv('a&b&c&d*e*')"
sub nfa2undgv {
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
      print $FA->as_undirected_graphviz;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
       print $FA->as_undirected_graphviz;} 
  }
}

# dumps graphviz notation
# Usage:
# perl -MFLAT -e "pfa2undgv('a&b&c&d*e*')"
sub pfa2undgv {
  use FLAT::Regex::WithExtraOps;
  use FLAT::PFA;
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
      print $FA->as_undirected_graphviz;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
       print $FA->as_undirected_graphviz;} 
  }
}

# dumps directed graph using Kundu notation
# Usage:
# perl -MFLAT -e "dfa2directed('a&b&c&d*e*')"
sub dfa2digraph {
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  # trims sink states from min-dfa since transitions are gone 
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa->trim_sinks(); 
       print $FA->as_digraph;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa->trim_sinks();
       print $FA->as_digraph;} 
  }
  print "\n";
}

# dumps directed graph using Kundu notation
# Usage:
# perl -MFLAT -e "nfa2directed('a&b&c&d*e*')"
sub nfa2digraph {
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa(); 
       print $FA->as_digraph;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
       print $FA->as_digraph;} 
  }
  print "\n";
}

# dumps directed graph using Kundu notation
# Usage:
# perl -MFLAT -e "pfa2directed('a&b&c&d*e*')"
sub pfa2digraph {
  use FLAT::Regex::WithExtraOps;
  use FLAT::PFA;
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa(); 
       print $FA->as_digraph;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
       print $FA->as_digraph;} 
  }
  print "\n";
}

# dumps undirected graph using Kundu notation
# Usage:
# perl -MFLAT -e "dfa2undirected('a&b&c&d*e*')"
sub dfa2undirected {
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  # trims sink states from min-dfa since transitions are gone 
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa->trim_sinks(); 
       print $FA->as_undirected;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa()->as_dfa->as_min_dfa->trim_sinks();
       print $FA->as_undirected;} 
  }
  print "\n";
}

# dumps undirected graph using Kundu notation
# Usage:
# perl -MFLAT -e "nfa2undirected('a&b&c&d*e*')"
sub nfa2undirected {
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::NFA;
  use FLAT::PFA;  
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa(); 
       print $FA->as_undirected;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa()->as_nfa();
       print $FA->as_undirected;} 
  }
  print "\n";
}

# dumps undirected graph using Kundu notation
# Usage:
# perl -MFLAT -e "pfa2undirected('a&b&c&d*e*')"
sub pfa2undirected {
  use FLAT::Regex::WithExtraOps;
  use FLAT::PFA;
  if (@_) 
  { foreach (@_)
    { my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa(); 
       print $FA->as_undirected;} }
  else    
  { while (<STDIN>) 
     { chomp;
       my $FA = FLAT::Regex::WithExtraOps->new($_)->as_pfa();
       print $FA->as_undirected;} 
  }
  print "\n";
}

# compares 2 give PREs
# Usage:
# perl -MFLAT -e "compare('a','a&b&c&d*e*')" #<-- no match, btw
sub compare {
  use FLAT::Regex::WithExtraOps;
  use FLAT::DFA;
  use FLAT::PFA;
  my $PFA1 = FLAT::Regex::WithExtraOps->new(shift)->as_pfa();
  my $PFA2 = FLAT::Regex::WithExtraOps->new(shift)->as_pfa();
  my $DFA1 = $PFA1->as_nfa->as_min_dfa;
  my $DFA2 = $PFA2->as_nfa->as_min_dfa;
  if ($DFA1->equals($DFA2)) {
    print "Yes\n";
  } else {
    print "No\n";
  }
}

# prints random PRE
# Usage:
# perl -MFLAT -e random_pre
sub random_pre {
  my $and_chance = shift;
  # skirt around deep recursion warning annoyance
  local $SIG{__WARN__} = sub { $_[0] =~ /^Deep recursion/ or warn $_[0] };
  srand $$;
  my %CMDLINEOPTS = ();
  # Percent chance of each operator occuring
  $CMDLINEOPTS{LENGTH} = 32;
  $CMDLINEOPTS{OR} = 6;
  $CMDLINEOPTS{STAR} = 10;
  $CMDLINEOPTS{OPEN} = 5;
  $CMDLINEOPTS{CLOSE} = 0;
  $CMDLINEOPTS{n} = 1;
  $CMDLINEOPTS{AND} = 10; #<-- default    
  $CMDLINEOPTS{AND} = $and_chance if ($and_chance == 0); #<-- to make it just an re (no shuffle)
  

  my $getRandomChar = sub {
    my $ch = '';
    # Get a random character between 0 and 127.
    do {
      $ch = int(rand 2);
    } while ($ch !~ m/[a-zA-Z0-9]/);  
    return $ch;
  };

  my $getRandomRE = sub {
    my $str = '';
    my @closeparens = ();
    for (1..$CMDLINEOPTS{LENGTH}) {
      $str .= $getRandomChar->();  
      # % chance of an "or"
      if (int(rand 100) < $CMDLINEOPTS{OR}) {
	$str .= "|1";
      } elsif (int(rand 100) < $CMDLINEOPTS{AND}) {
	$str .= "&0";
      } elsif (int(rand 100) < $CMDLINEOPTS{STAR}) {
	$str .= "*1";     
      } elsif (int(rand 100) < $CMDLINEOPTS{OPEN}) {
	$str .= "(";
	push(@closeparens,'0101)');
      } elsif (int(rand 100) < $CMDLINEOPTS{CLOSE} && @closeparens) {
	$str .= pop(@closeparens);
      }
    }
    # empty out @closeparens if there are still some left
    if (@closeparens) {
      $str .= join('',@closeparens);  
    }
    return $str;
  };

  for (1..$CMDLINEOPTS{n}) {
    print $getRandomRE->(),"\n";  
  } 
}

# prints random RE (no & operator)
# Usage:
# perl -MFLAT -e random_re
sub random_re {
  shift->random_pre(0);
}

1;

__END__

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and 
Brett Estrade E<lt>estradb at gmail dot comE<gt>.

The initial version (FLAT::Legacy) by Brett Estrade was work towards an 
MS thesis at the University of Southern Mississippi.

Please visit the Wiki at http://www.0x743.com/flat

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

