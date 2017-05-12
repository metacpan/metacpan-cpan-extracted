#!/usr/bin/env perl

use strict;
use warnings;

use Marpa::R2;

# ------------------------------------------------

# AUTHOR: Lukas Atkinson (amon@cpan.org) aka lwa on #marpa.
# LICENSE: WTFPL <http://www.wtfpl.net/about/>

# USAGE:
#   filter.pl <filter-expression> [<filename>]
#
# <filter-expression>: A filter expression such as 'a b (c || d) !e'
#
# If no file name is provided, input is read from STDIN

my $source = <<'END_GRAMMAR';
  lexeme default = latm => 1; :discard ~ SPACE;
  inaccessible is fatal by default;
  Filter ::= NAME             action => do_simple
    || ('(') Filter (')')     action => ::first
    || (OP_NEGATE) Filter     action => do_not
    || Filter (OP_AND) Filter action => do_and assoc => left
    || Filter (OP_OR ) Filter action => do_or  assoc => left;
  OP_OR ~ '|' | '||' | 'or':i; OP_AND ::=; OP_AND ::= op_and; op_and ~ '&' | '&&' | 'and':i;
  OP_NEGATE ~ '!';
  NAME ~ [\w]+; SPACE ~ [\s]+;
END_GRAMMAR

my $g = Marpa::R2::Scanless::G->new({ source => \$source });
my $r = Marpa::R2::Scanless::R->new({ grammar => $g, semantics_package => 'Actions' });

my $filter_expression = shift @ARGV; # take from command line
$r->read(\shift @ARGV);
my $tester = ${ $r->value };
while (<>) {
  print if $tester->(split);  # only match against space-separated words
}

# we don't build an AST, but a couple of nested closures that perform the filtering
sub Actions::do_and    { my (undef, $x, $y ) = @_; return sub { $x->(@_) && $y->(@_) } }
sub Actions::do_or     { my (undef, $x, $y ) = @_; return sub { $x->(@_) || $y->(@_) } }
sub Actions::do_not    { my (undef, $x     ) = @_; return sub { !$x->(@_) } }
sub Actions::do_simple { my (undef, $string) = @_; return sub { scalar grep { $_ eq $string } @_ } }
