package Math::SymbolicX::Calculator::Interface;

use 5.006;
use strict;
use warnings;

use Math::SymbolicX::Calculator;
use Params::Util qw/_INSTANCE/;

our $VERSION = '0.02';

=encoding utf8

=head1 NAME

Math::SymbolicX::Calculator::Interface - Miscallaneous routines for interfaces

=head1 SYNOPSIS

Do not use this in your scripts. Use one of the C<::Interface::Foo> classes.

=head1 DESCRIPTION

I<This is very much an internal class.>

This module is a base class for interfaces to L<Math::SymbolicX::Calculator>.
It is not an interface by itself. It doesn't even define stubs for all
methods of an interface and as such isn't an interface definition for
Calculator::Interfaces. Instead, it contains various miscellaneous methods
which may be of use to classes which actually implement interfaces.

=head1 METHODS RELATED TO PARSING

These methods parse commands of a somewhat generic syntax.

When defining the form of the accepted input strings below,
I'll be using certain variables:

  $SYMBOL         => An identifier matching /[A-Za-z][A-Za-z0-9_]*/
  $FORMULA        => String that can be parsed as a Math::Symbolic tree
  $PATTERN        => String that can be parsed as a
                     Math::Symbolic::Custom::Transformation. (*)
  $REPLACEMENT    => String that can be parsed as the replacement part
                     of a Math::Symbolic::Custom::Transformation (*).
  $TRANSFORMATION => String that can be parsed as a transformation in
                     the calculator context. (*) This means it has the
                     following form: $PATTERN -> $REPLACEMENT
  $GROUP          => A group of transformations. Grouping is done in
                     []-braces and the group elements are chained with
                     one of &, |, or ",". Form: [ $x & $x & .... ]
                     (Same for | or , but not mixed!)
                     $x is either another $GROUP, a $TRANSFORMATION
                     or a $SYMBOL in case of the latter, the symbol
                     table of the calculator is accessed to map the
                     $SYMBOL to a $TRANSFORMATION.
                     The ultimate result of parsing such a thing is a
                     Math::Symbolic::Custom::Transformation::Group
                     object (**).

(*) C<$PATTERN>s, C<$REPLACEMENT>s and C<$TRANSFORMATION>s
may contain some special syntax.
Instead of the C<TREE_foo>, C<VAR_foo>, and C<CONST_foo> special variables:
You can write C<?foo>, C<$foo> and C<!foo> respectively.

(**) L<Math::Symbolic::Custom::Transformation::Group> objects are also
L<Math::Symbolic::Custom::Transformation>s.

If errors occurr, these methods call the C<error()> method with
a description and then return the empty list.

If these methods require access to certain attributes of the interface
objects, this is mentioned in the docs.

=cut


# Matches identifiers
my $Ident = $Math::SymbolicX::Calculator::Identifier_Regex;


=head2 _parse_assignment

Parses an expression of one of the forms

  $SYMBOL = $FORMULA
  $SYMBOL = $TRANSFORMATION
  $SYMBOL = $GROUP

Returns an instance of L<Math::SymbolicX::Calculator::Command::Assignment>
which assigns either a formula or a transformation(-group) when executed.

Uses C<$self->calc()> and expects it to return the Calculator object.
Uses the C<_parse_trafo_group> method.

=cut

sub _parse_assignment {
    my $self = shift;

    my $expr = shift;
    my ($sym, $func) = split /\s*=\s*/, $expr, 2;

    # get symbol name
    $sym =~ s/^\s*//;
    $sym =~ s/\s*$//;
    $sym =~ /^$Ident$/ or $self->error("Invalid symbol name"), return();

    my $cmd;
    if ($func =~ /->/ or $func =~ /\[/) {
        # Transformation

        # If this fails, it should call ->error(...) itself.
        my $trafo = $self->_parse_trafo_group($func);
        return() if not defined $trafo;

        # Assigns the transformation to the symbol in the stash
        $cmd = $self->calc->new_command(
            type => 'Assignment', symbol => $sym, object => $trafo
        );
    }
    else {
        # Function
        eval { $func = Math::Symbolic->parse_from_string($func); };
        if ($@ or not defined $func) {
            $self->error("Could not parse function." . ($@?" Error: $@":""));
            return();
        }
    
        $cmd = $self->calc->new_command(
            type => 'Assignment', symbol => $sym, object => $func
        );
    }

    return $cmd;
}

=head2 _parse_transformation

This method parses expressions of the form

  $SYMBOL =~ $SYMBOL2
  $SYMBOL =~ $TRANSFORMATION
  $SYMBOL =~ $GROUP

or

  $SYMBOL =~~ $SYMBOL2 (*)
  ... and so on ...

(*) The C<=~> operator stands for recursive application of the transformation
whereas the C<=~~> operator stands for shallow application.

These expressions generally stand for the application of the
transformation given on the right to the function C<$SYMBOL>
stands for. This method returns a
C<Math::SymbolicX::Calculator::Command::Transformation> object on success
or calls the C<error()> method and returns an empty list on failure.

This methods expects C<$self->calc()> to return the Calculator object.
It also uses the C<_parse_trafo_group> method.

=cut

sub _parse_transformation {
    my $self = shift;
    my $expr = shift;

    my $shallow = 0;
    $shallow = 1 if $expr =~ /=~~/;

    my ($sym, $right) = split /\s*=~~?\s*/, $expr, 2;

    # get symbol name
    $sym =~ s/^\s*//;
    $sym =~ s/\s*$//;
    if (not $sym =~ /^$Ident$/) {
        $self->error("Invalid symbol name");
        return();
    }

    my $trafo = $self->_parse_trafo_group($right);
    if (not defined $trafo) {
        $self->error(
            "Invalid transformation application: "
            ."'$right' is not a transformation."
        );
        return();
    }

    my $cmd = $self->calc->new_command(
        type => 'Transformation', symbol => $sym, object => $trafo,
        shallow => $shallow,
    );
    return $cmd;
}


=head2 _parse_trafo_group

Parses a string of the form:

    $SYMBOL
    $GROUP
    $TRANSFORMATION

In case of C<$SYMBOL>, it accesses the Calculator symbol table to fetch
the referenced Transformation. (And throws an error if it's not one.)

Returns a L<Math::Symbolic::Custom::Transformation> object or calls
the C<error()> method and returns the empty list on failure.

This method uses L<Parse::RecDescent>.
Expects the C<calc()> method to return the Calculator object.
Uses the method C<_parse_simple_transformation>.

=cut

{ # {{{ block around _parse_trafo_group
    my $group_grammar = <<'GROUP_GRAMMAR';
      parse: group /^\Z/
             {
               $return = $item[1]
             }
           | // {undef}
    
      group: /[^,\[\]&|]+/
             { $return = $item[1] }
       | '[' /[^,\[\]&|]+/ ']'
         { $return = $item[2] }
       | '[' <leftop:group '&' group> ']'
         { $return = ['&', $item[2]] }
       | '[' <leftop:group '|' group> ']'
         { $return = ['|', $item[2]] }
       | '[' <leftop:group ',' group> ']'
         { $return = [',', $item[2]] }
GROUP_GRAMMAR

    my $group_parser;

    sub _parse_trafo_group {
        my $self = shift;
        my $string = shift;

        # Initialize parser
        if (not defined $group_parser) {
            require Parse::RecDescent;
            $group_parser = Parse::RecDescent->new($group_grammar);
        }

        # If it's a symbol, access the stash
        if ($string =~ /^\s*($Ident)\s*$/) {
            my $trafo_sym = $1;
    
            my $trafo = $self->calc->get_transformation($trafo_sym);
            if (not ref($trafo)) {
                $self->error($trafo);
                return();
            }
            else {
                return $trafo;
            }
        }
        # It's a group
        elsif ($string =~ /^\s*\[.*\]\s*$/) {
            $string =~ s/\s+//g;
            my $struct = $group_parser->parse($string);
            if (not defined $struct) {
                $self->error("There was an error in your previous line of input. Please check your syntax.");
                return();
            }

            if (not ref $struct) {
                return $self->_parse_simple_transformation($struct);
            }

            my $group = $self->_struct_to_group($struct);
    
            return($group);
        }
        # It must be an ordinary transformation
        else {
            return $self->_parse_simple_transformation($string);
        }
    }

    no warnings 'recursion';

    # Helper method for _parse_trafo_group (recursive)
    sub _struct_to_group {
        my $self = shift;
        my $struct = shift;

        my $op = $struct->[0];
        my $inside = $struct->[1];

        my @expr;
        foreach my $expr (@$inside) {
            if (ref($expr)) {
                # nested groups
                push @expr, $self->_struct_to_group($expr);
            }
            else {
                my $trafo = $self->_parse_trafo_group($expr);
                if (not defined $trafo) {
                    $self->error(
                        "Error creating transformation from expression '$expr'."
                    );
                    return();
                }
                push @expr, $trafo;
            }
        }
        return Math::Symbolic::Custom::Transformation::Group->new(
            $op, @expr
        );
    }

} # }}} block around _parse_trafo_group



=head2 _parse_simple_transformation

Parses a string of the form "pattern -> replacement", i.e. a
simple C<$TRANSFORMATION>.

Returns a C<Math::Symbolic::Custom::Transformation> object or the
empty list on failure.

=cut

sub _parse_simple_transformation {
    my $self = shift;
    my $string = shift;
    my ($pattern, $replacement) = split /\s*->\s*/, $string, 2;

    # Special syntax for our transformations
    for ($pattern, $replacement) {
        s/(!|\$|\?)($Ident)/
          if    ($1 eq '!') { "CONST_$2" }
          elsif ($1 eq '$') { "VAR_$2"   }
          else              { "TREE_$2"  }
        /ge;
    }

    my $trafo;
    eval {
        $trafo = Math::Symbolic::Custom::Transformation->new(
            $pattern, $replacement
        );
    };
    if ($@ or not defined $trafo) {
        $self->error(
            "Could not parse transformation '$pattern -> $replacement'."
            . ($@?" Error: $@":"")
        );
        return();
    }

    return $trafo;
}





1;
__END__


=head1 SEE ALSO

L<Math::SymbolicX::Calculator>,
L<Math::SymbolicX::Calculator::Interface::Shell>

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
