package Decl::Template;

use warnings;
use strict;
use Data::Dumper;

=head1 NAME

Decl::Template - implements a template in the Decl system.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

A I<template> is a textual representation of a class of data structures.  A template has named slots and other value specifications that
permit an arbitary set of data to be extracted from the environment of its invocation and formatted into a text block that can be used
to do something else.  In Decl, that "something else" is often the creation of a new set of nodes, but the typical use of templates
is to express data in display text.

Decl templates are based pretty closely on JSON::Templates (a system used in Python and Javascript that I rather like).

This class, instead of implementing a template itself, actually implements a template environment.  A template, after all, is just a
piece of text - and its output is also a piece of text.  All the interesting stuff falls into the environment - it is in the environment
that we determine the values of all our slots, after all.  And in the Decl context, that is no trivial task.

=head2 new()

The C<new> function, of course, doesn't do much except set up the engine according to the parameters.

=cut

sub new {
   my ($class, %values) = @_;
   my $self = bless \%values, $class;
   #TODO: 'brackets' split
   $self->{left} = '\[\[' unless $self->{left};
   $self->{right} = '\]\]' unless $self->{right};
   $self->{leftp} = $self->{left};
   $self->{leftp} =~ s/\\//g;
   $self->{rightp} = $self->{right};
   $self->{rightp} =~ s/\\//g;
   $self->{valuator} = \&default_valuator unless $self->{valuator};
   $self->{leave_misses} = 1 unless defined $self->{leave_misses};
   
   $self->{spanners} = {} unless $self->{spanners};
   $self->{spanners}->{with}   = \&do_with   unless defined $self->{spanners}->{with};
   $self->{spanners}->{if}     = \&do_if     unless defined $self->{spanners}->{if};
   $self->{spanners}->{repeat} = \&do_repeat unless defined $self->{spanners}->{repeat};
   
   $self;
}

=head2 default_valuator

Given a value environment (by default, a hashref) and the name of a value, a valuator finds the value.

If nothing else is specified, the hashref valuator is used.  In the Decl context, a node will generally
be used and the node's own valuation function is used as the valuator.

=cut

sub default_valuator {
   my ($name, $env) = @_;
   $$env{$name};
}

=head2 prepare_varname

Given a variable specification, prepare it for use as a lookup key.

=cut

sub prepare_varname {
   my ($name) = @_;
   $name =~ s/\n */ /sg;
   $name =~ s/^ *//g;
   $name =~ s/ *$//g;
   $name;
}

=head2 parse_spanning_command

Given a spanning command string, parse out the initial word (the command) and leave the arguments (the rest).  Drop the . or +.

=cut

sub parse_spanning_command {
   my $piece = shift;
   
   $piece =~ s/^[+\.] *//;
   split m[ +], $piece, 2;
}

=head2 handle_spanning_command

Given a parsed spanning command and the value object and valuator function to be used, express the command.  This is really just
a dispatcher for a command table.

=cut

sub handle_spanning_command {
   my ($self, $command, $values, $valuator) = @_;
   
   my $c = $self->{spanners}->{$$command[0]};
   return $c->($self, $command, $values, $valuator) if $c;
   return '';   # TODO: consider better error handling.  As always.
}

=head2 register_spanning_command ($name, $closure)

Here's how you register a spanning command.  Just name it and provide a closure for it, and you're good to go.

=cut

sub register_spanning_command {
   my ($self, $name, $sub) = @_;
   
   $self->{spanners}->{$name} = $sub;
}

=head2 do_with, do_if, do_repeat, express_repeat

These are our three default spanning commands.  More can be added to the table.

The C<express_repeat> does the heavy lifting in expressing the list template and can be recycled in other forms of list template.

=cut

sub do_with {
   my ($self, $command, $values, $valuator) = @_;
   
   my $with = do_lookup($$command[1], $values, $valuator);
   $self->express_parsed ($$command[2], $with, \&default_valuator);
}

sub do_if {
   my ($self, $command, $values, $valuator) = @_;

   my $test = do_lookup ($$command[1], $values, $valuator);
   if ($test) {
      return $self->express_parsed ($$command[2], $values, $valuator);
   }
   my @alternatives = @{$$command[3]};
   foreach my $check (@alternatives) {
      if ($$check[0] eq 'elif') {
         $test = do_lookup ($$check[1], $values, $valuator);
         if ($test) {
            return $self->express_parsed ($$check[2], $values, $valuator);
         }
      }
      if ($$check[0] eq 'else') {
         return $self->express_parsed ($$check[2], $values, $valuator);
      }
   }
   return '';            
}

sub do_repeat {
   my ($self, $command, $values, $valuator) = @_;
   
   my $loop = do_lookup ($$command[1], $values, $valuator);
   my @list;
   if (ref $loop eq 'ARRAY') {
      @list = @$loop;
   } elsif (not defined $loop) {
      @list = ();
   } else {
      @list = ($loop);
   }
   
   $self->express_repeat ($command, $values, $valuator, @list);
}

sub express_repeat {
   my $self = shift;
   my $command = shift;
   my $values = shift;
   my $valuator = shift;
   
   if (not @_) {
      foreach my $else (@{$$command[3]}) {
         if ($$else[0] eq 'else') {
            return $self->express_parsed ($$else[2], $values, $valuator);
         }
      }
      return '';
   }
   
   my $body = $$command[2];
   my $before = '';
   my $alternate = '';
   my $after = '';
   foreach (@{$$command[3]}) {
      if ($$_[0] eq 'before') {
         $before = $self->express_parsed ($$_[2], $values, $valuator);
         next;
      }
      if ($$_[0] eq 'alt') {
         $alternate = $self->express_parsed ($$_[2], $values, $valuator);
         next;
      }
      if ($$_[0] eq 'after') {
         $after = $self->express_parsed ($$_[2], $values, $valuator);
         next;
      }
      if ($$_[0] eq 'body') {
         $body = $$_[2];
         next;
      }
   }
   
   my $return = $before;
   while (@_) {
      my $this = shift;
      $return .= $self->express_parsed ($body, $this, \&default_valuator);
      $return .= $alternate if (@_);
   }
   $return .= $after;
   
   $return;
}

=head2 do_lookup ($name, $values, $valuator)

Takes a value specification, cleans up the name, applies filters, and returns the final value.  TODO: filters.

=cut

sub do_lookup {
   my ($name, $values, $valuator) = @_;
   
   $valuator->(prepare_varname($name), $values);
}

=head2 parse_template ($template)

This parses our template language into a kind of interlanguage consisting of interleaved plain text and commands to be carried out to generate
text.  Then we can either express the command structure, or alternatively translate it into some other template language.

So.  Our template language is text interspersed with fields delimited by default delimiters of [[ and ]].  (These can be overridden.)
Its output is a list (or arrayref) of commands.  Plain text between fields is output exactly as-is, and so the output "command" is simply a
string containing that text.

Most fields are variable lookups, and these turn into ['lookup', '<variable>'] - where "variable" can be an extended command if our valuation
function knows how to handle them.  The basic template engine, however, simply looks up names in a hashref.

Any field of the form [[.<command> <args>]] is a "dotted command" or "spanning command".
The default ones defined are .repeat, .with, and .if; you can write
your own, though.  (TODO: provide a way to hook them in.)  A dotted command extends until it hits [[.end]], and they can of course be
nested.

The Decl node framework will also provide a .select command, which will do exactly what you think it will.  I think, based on this
alone, you could probably build a believable report generator.

Within a spanning command, you can define subranges with [[+<range> <args]].  This is used for C<elif> and C<else> in the C<.if>
command, and for C<alt> and C<else> in the C<.repeat> command.  What you get back is then a hashref with any subranges stored
by name for your viewing pleasure.

The parser outputs a spanning command like this:

  ['<command with string arguments>',
   [<list of contained template items>],
   [ [<subcommand>, <subcommand arguments>, <list of contained items>],
     ...  (this part is optional and repeated for as many subcommands as appear)
   ]
  ]
  
The hashref of named subspans likewise has arrayrefs for values.  Each of the arrayrefs in this structure has already been parsed by the
time all is said and done.

=cut

sub parse_template {
   my ($self, $template) = @_;
   
   my @pieces;
   my $main_body = [];
   my @arglist = ();
   my $curspan = '';
   my $curspan_args = '';
   
   if (ref($template) eq 'ARRAY') {
      # An arrayref means we've already split the template and we
      # just need to express it.
      @pieces = @$template;
   } else {
      @pieces = split /$self->{left}(.*?)$self->{right}/s, $template;
   }
   
   # First step: scan the template pieces and take care of any spanning
   # commands (.repeat, .with, or .if)
   my @current_span = ();
   my $on = 1;
   my $trailing_indent;
   while (@pieces) {
      $on = not $on;
      if (not $on) {
         my $literal = shift @pieces;
         push @current_span, $literal;
         if ($literal =~ /\n([^\n]*?)\z/s) {
            $trailing_indent = length($1);
            if ($1 =~ /^\s*$/) {
               $trailing_indent = 0;
            }
         } else {
            $trailing_indent = length($literal);
         }
         next;
      }
      
      my $piece = shift @pieces;
      if ($piece !~ /^[+\.]/) {
         push @current_span, ['lookup', $piece];
         next;
      }

      $pieces[0] =~ s/^\s*\n//s;

      my ($command, $args) = parse_spanning_command ($piece);
      
      if ($piece =~ /^\+/) {
         if ($curspan eq '') {
            $main_body = [@current_span];
         } else {
            push @arglist, [$curspan, $curspan_args, [@current_span]];
         }
         @current_span = ();
         $curspan = $command;
         $curspan_args = $args;
         
         next;
      }
      
      if ($command eq 'end') {
         if ($curspan eq '') {
            $main_body = [@current_span];
         } else {
            push @arglist, [$curspan, $curspan_args, [@current_span]];
         }
         
         # If we've encountered an .end command, return what we've got.
         return ($main_body, \@arglist, \@pieces);
      }

      my ($body, $arglist, $rest) = $self->parse_template (\@pieces);
      push @current_span, [$command, $args, $body, $arglist];
      @pieces = @$rest;
   }

   if ($curspan eq '') {
      $main_body = \@current_span;
   } else {
      push @arglist, [$curspan, $curspan_args, \@current_span];
   }
   
   
   return ($main_body, \@arglist, \@pieces) if wantarray;
   $main_body;
}

=head2 express_parsed ($template, $values, $valuator)

Given a parse tree returned from the above function, plus a value structure and a way to retrieve first-level values from it (second-level
values are presumed to be hashrefs or arrayrefs returned from the first level, and perhaps there might someday be motivation to extend
that notion to some kind of lazy evaluation, but I<today is not that day>), (breathe) returns the expressed template.  Which is just a string.

Non-default spanning commands must be defined in the engine before use.

=cut

sub express_parsed {
   my ($self, $template, $values, $valuator) = @_;

   $values = $self->{values} || {} unless defined $values;
   $valuator = $self->{valuator} unless defined $valuator;

   my $return = '';

   my $indent = 0;
   my $literal;
   my $value = undef;
   
   foreach my $piece (@$template) {
      next unless defined $piece;   # Just in case.
      if (not ref $piece) {  # Strings just pass through.
         $value = $piece;
         $literal = 1;
      } else {
         next unless ref $piece eq 'ARRAY';  # Anything but an arrayref or string will be roundly ignored.
        
         $literal = 0;
         if ($$piece[0] eq 'lookup') {
            $value = do_lookup($$piece[1], $values, $valuator);
            if (not defined $value) {  # If the value is undefined, then either leave the field in place, or don't.
               if ($self->{leave_misses}) {
                  $value = $self->{leftp} . $$piece[1] . $self->{rightp}
               } else {
                  $value = '';
               }
            }
         } else {  # We have a spanning command.
            $value = $self->handle_spanning_command($piece, $values, $valuator);
         }
      }

      # If the value is an arrayref, use its length.  This gives us a cheap way to say "search returned [[x]] rows"; just reuse the result variable.      
      if (ref $value eq 'ARRAY') {
         $value = scalar @$value;
      }
      # If the value is a hashref, run it through our JSONifier for output as a debugging value.
      # If it's an object, do .... hell, I dunno.  If it can "describe" (i.e. it's a node) then it should do that.
      # TODO: both of the above cases.  I just don't need these right now.
         
      # Now we've got a value, so we insert it into the expression,
      # taking care to keep track of indentation so we can do literate
      # programming of Python.  (No, seriously, that was my major
      # motivation here; sort of a left-over from a decade ago.)
      my $indent_incr;
      if ($value =~ /\n([^\n]*?)\z/s) {    # 2011-08-17 - learned about \z today!
         if ($literal) {
            $indent = length($1);
         } else {
            $indent_incr += length($1);
            my $spaces = ' ' x $indent;
            $value =~ s/\n/\n$spaces/g;
            $indent += $indent_incr;
         }
      } else {
         $indent += length($value);
      }
      $return .= $value;
   }
   $return;
}


=head2 express($template, $values, $valuator)

If C<$template> is omitted, the default template for the engine is used.  If C<$values> is omitted, same goes for any previously
defined values.  And the default C<$valuator> is defined above.

=cut

sub express {
   my ($self, $template, $values, $valuator) = @_;
   
   $template = $self->{template} || '' unless defined $template;

   my $pieces = $self->parse_template($template);  # Note that anything after a superfluous [[+command]] or [[.end]] will be ignored.
   
   $self->express_parsed ($pieces, $values, $valuator);
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::Template
