package Math::Symbolic::Custom::Transformation;

use 5.006;
use strict;
use warnings;

use Carp qw/croak carp/;
use Math::Symbolic qw/:all/;
use Math::Symbolic::Custom::Pattern;
require Math::Symbolic::Custom::Transformation::Group;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '2.02';

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Transformation - Transform Math::Symbolic trees

=head1 SYNOPSIS

  use Math::Symbolic::Custom::Transformation;
  my $trafo = Math::Symbolic::Custom::Transformation->new(
    'TREE_x + TREE_x' => '2 * TREE_x'
  );
  
  my $modified = $trafo->apply($math_symbolic_tree);
  if (defined $modified) {
    print "Outermost operator is a sum of two identical trees.\n";
    print "Transformed it into a product. ($modified)\n";
  }
  else {
    print "Transformation could not be applied.\n";
  }
  
  # shortcut: new_trafo
  use Math::Symbolic::Custom::Transformation qw/new_trafo/;

  # use the value() function to have the transformation compute the value
  # of the expression after the replacements. simplify{} works similar.
  my $another_trafo = new_trafo(
    'TREE_foo / CONST_bar' => 'value{1/CONST_bar} * TREE_foo'
  );
  
  # If you'll need the same transformation but don't want to keep it around in
  # an object, just do this:
  use Memoize;
  memoize('new_trafo');
  # Then, passing the same transformation strings will result in a speedup of
  # about a factor 130 (on my machine) as compared to complete recreation
  # from strings. This is only 20% slower than using an existing
  # transformation.

=head1 DESCRIPTION

Math::Symbolic::Custom::Transformation is an extension to the Math::Symbolic
module. You're assumed to be remotely familiar with that module throughout
the documentation.

This package implements transformations of Math::Symbolic trees using
Math::Symbolic trees. I'll try to explain what this means in the following
paragraphs.

Until now, in order to be able to inspect a Math::Symbolic tree, one had to
use the low-level Math::Symbolic interface like comparing the top node's
term type with a constant (such as C<T_OPERATOR>) and then its operator type
with more constants. This has changed with the release of
Math::Symbolic::Custom::Pattern.

To modify the tree, you had to use equally low-level or even
encapsulation-breaking methods. This is meant to be changed by this
distribution.

=head2 EXAMPLE

Say you want to change any tree that is a sum of two identical
trees into two times one such tree. Let's assume the original object is in
the variable C<$tree>. The old way was: (strictures and warnings assumed)

  use Math::Symbolic qw/:all/;
  
  sub sum_to_product {
    if ( $tree->term_type() == T_OPERATOR
         and $tree->type() == B_SUM
         and $tree->op1()->is_identical($tree->op2()) )
    {
      $tree = Math::Symbolic::Operator->new(
        '*', Math::Symbolic::Constant->new(2), $tree->op1()->new()
      );
    }
    return $tree;
  }

What you'd do with this package is significantly more readable:

  use Math::Symbolic::Custom::Transformation qw/new_trafo/;
  
  my $Sum_To_Product_Rule = new_trafo('TREE_a + TREE_a' => '2 * TREE_a');
  
  sub sum_to_product {
    my $tree = shift;
    return( $Sum_To_Product_Rule->apply($tree) || $tree );
  }

Either version could be shortened, of course. The significant improvement,
however, isn't shown by this example. If you're doing introspection beyond
the outermost operator, you will end up with giant, hardly readable
if-else blocks when using the old style transformations. With this package,
however, such introspection scales well:

  use Math::Symbolic::Custom::Transformation qw/new_trafo/;
  
  my $Sum_Of_Const_Products_Rule = new_trafo(
    'CONST_a * TREE_b + CONST_c * TREE_b'
    => 'value{CONST_a + CONST_c} * TREE_b'
  );
  
  sub sum_to_product {
    my $tree = shift;
    return( $Sum_Of_Const_Products_Rule->apply($tree) || $tree );
  }

For details on the C<value{}> construct in the transformation string, see
the L<SYNTAX EXTENSIONS> section.

=head2 EXPORT

None by default, but you may choose to import the C<new_trafo> subroutine
as an alternative constructor for Math::Symbolic::Custom::Transformation
objects.

=head2 PERFORMANCE

The performance of transformations isn't astonishing by itself, but if you
take into account that they leave the original tree intact, we end up with
a speed hit of only 16% as compared to the literal code. (That's the
huge if-else block I was talking about.)

You may be tempted to recreate the transformation objects from strings
whenever you need them. There's one thing to say about that: Don't!
The construction of transformations is really slow because they have
been optimised for performance on application, not creation.
(Application should be around 40 times faster than creation from strings!)

I<Note:> Starting with version 2.00, this module also supports the new-ish
Math::Symbolic::Parser::Yapp parser implementation which is significantly
faster than the old Parse::RecDescent based implementation. Replacement
strings are parsed using Yapp by default now, which means a performance
increase of about 20%. The search patterns are still parsed using the default
Math::Symbolic parser which will be switched to Yapp at some point in the
future. If you force the use of the Yapp parser globally, the parser
performance will improve by about an order of magnitude! You can do so by
adding the following before using Math::Symbolic::Custom::Transformation:

  use Math::Symbolic;
  BEGIN {
    $Math::Symbolic::Parser = Math::Symbolic::Parser->new(
      implementation => 'Yapp'
    );
  }
  use Math::Symbolic::Custom::Transformation;
  #...

If you absolutely must include the source strings where the transformation
is used, consider using the L<Memoize> module which is part of the standard
Perl distribution these days.

  use Memoize;
  use Math::Symbolic::Custom::Transformation qw/new_trafo/;
  memoize('new_trafo');

  sub apply_some_trafo {
    my $source = shift;
    my $trafo = new_trafo(...some pattern... => ...some transformation...);
    return $trafo->apply($source);
  }

This usage has the advantage of putting the transformation source strings
right where they make the most sense in terms of readability. The
memoized subroutine C<new_trafo> only constructs the transformation the first
time it is called and returns the cached object every time thereafter.

=head2 SYNTAX EXTENSIONS

The strings from which you can create transformations are basically those that
can be parsed as Math::Symbolic trees. The first argument to the transformation
constructor will, in fact, be parsed as a Math::Symbolic::Custom::Pattern
object. The second, however, may include some extensions to the default
Math::Symbolic syntax. These extensions are the two functions C<value{...}>
and C<simplify{...}>. The curly braces serve the purpose to show the
distinction from algebraic parenthesis. When finding a C<value{EXPR}>
directive, the module will calculate the value of C<EXPR> when the
transformation is applied. (That is, after the C<TREE_foo>, C<CONST_bar> and
C<VAR_baz> placeholders have been inserted!) The result is then inserted
into the transformed tree.

Similarily, the C<simplify{EXPR}> directive will use the Math::Symbolic
simplification routines on C<EXPR> when the transformation is being applied
(and again, after replacing the placeholders with the matched sub-trees.

=cut

our %EXPORT_TAGS = ( 'all' => [ qw(
    new_trafo new_trafo_group
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $Predicates = [
    qw/simplify value/
];

# We have some class data. Namely, the parser for the transformation strings
# which aren't quite ordinary Math::Symbolic strings.
our $Parser;
{
    my $pred = join '|', @$Predicates;
    $Parser = Math::Symbolic::Parser->new(
        implementation => 'Yapp',
        yapp_predicates => qr/$pred/o,
    );
}

if ($Parser->isa('Parse::RecDescent')) {
    # This is left in for reference.
    my $pred = join '|', @$Predicates;
    $Parser->Extend(<<"HERE");
function: /(?:$pred)\{/ expr '}'
    {
                my \$function_name = \$item[1];
                \$function_name =~ s/\{\$//;

                my \$inner = \$item[2];

                my \$name = 'TRANSFORMATION_HOOK';

                # Since we need to evaluate both 'simplify' and 'value'
                # at the time we apply the transformation, we just replace
                # the function occurrance with a special variable that is
                # recognized later. The function name and argument is stored
                # in an array as the value of the special variable.
                Math::Symbolic::Variable->new(
                    \$name, [\$function_name, \$inner]
                );
    }
HERE
}
elsif ($Parser->isa('Math::Symbolic::Parser::Yapp')) {
    # This is a no-op since the logic had to be built into
    # the Yapp parser. *sigh*
}
else {
    die "Unsupported Math::Symbolic::Parser implementation.";
}

=head2 METHODS

This is a list of public methods.

=over 2

=cut

=item new

This is the constructor for Math::Symbolic::Custom::Transformation objects.
It takes two arguments: A pattern to look for and a replacement.

The pattern may either be a Math::Symbolic::Custom::Pattern object (fastest),
or a Math::Symbolic tree which will internally be transformed into a pattern
or even just a string which will be parsed as a pattern.

The replacement for the pattern may either be a Math::Symbolic tree or a
string to be parsed as such.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my $pattern = shift;
    my $replacement = shift;

    # parameter checking
    if (not defined $pattern or not defined $replacement) {
        croak("Arguments to ".__PACKAGE__."->new() must be a valid pattern and a replacement for matched patterns.");
    }

    if (not ref($pattern)) {
        my $copy = $pattern;
        $pattern = parse_from_string($pattern);
        if (not ref($pattern)) {
            croak("Failed to parse pattern '$copy' as a Math::Symbolic tree.");
        }
    }

    if (not $pattern->isa('Math::Symbolic::Custom::Pattern')) {
        eval {$pattern = Math::Symbolic::Custom::Pattern->new($pattern);};
        if ( $@ or not ref($pattern)
             or not $pattern->isa('Math::Symbolic::Custom::Pattern')    )
        {
            croak(
                "Could not transform pattern source into a pattern object."
                . ($@?" Error: $@":"")
            );
        }
    }

    if (not ref($replacement) =~ /^Math::Symbolic/) {
        my $copy = $replacement;
        $replacement = $Parser->parse($replacement);
        if (not ref($replacement) =~ /^Math::Symbolic/) {
            croak(
                "Failed to parse replacement '$copy' as a Math::Symbolic tree."
            );
        }
    }

    my $self = {
        pattern => $pattern,
        replacement => $replacement,
    };

    bless $self => $class;

    return $self;
}


=item apply

Applies the transformation to a Math::Symbolic tree. First argument must be
a Math::Symbolic tree to transform. The tree is not transformed in-place,
but its matched subtrees are contained in the transformed tree, so if you plan
to use the original tree as well as the transformed tree, take
care to clone one of the trees.

C<apply()> returns the transformed tree if the transformation pattern matched
and a false value otherwise.

On errors, it throws a fatal error.

=cut

sub apply {
    my $self = shift;
    my $tree = shift;

    if (not ref($tree) =~ /^Math::Symbolic/) {
        croak("First argument to apply() must be a Math::Symbolic tree.");
    }

    my $pattern = $self->{pattern};
    my $repl = $self->{replacement};

    my $matched = $pattern->match($tree);

    return undef if not $matched;

    my $match_vars = $matched->{vars};
    my $match_trees = $matched->{trees};
    my $match_consts = $matched->{constants};

    my $new = $repl->new();

    no warnings 'recursion';
    
    my $subroutine;
    my @descend_options;

    $subroutine = sub {
        my $tree = shift;
        if ($tree->term_type() == T_VARIABLE) {
            my $name = $tree->{name};
            if ($name eq 'TRANSFORMATION_HOOK') {

        my $hook = $tree->value();
                if (not ref($hook) eq 'ARRAY' and @$hook == 2) {
                    croak("Found invalid transformation hook in replacement tree. Did you use a variable named 'TRANSFORMATION_HOOK'? If so, please change its name since that name is used internally.");
                }
                else {
                    my $type = $hook->[0];
                    my $operand = $hook->[1]->new();
                    $operand->descend(
                        @descend_options
                    );

                    if ($type eq 'simplify') {
                        my $simplified = $operand->simplify();
                        $tree->replace($simplified);
                        return undef;
                    }
                    elsif ($type eq 'value') {
                        my $value = $operand->value();
                        if (not defined $value) {
                            croak("Tried to evaluate transformation subroutine value() but it evaluated to an undefined value.");
                        }
                        $value = Math::Symbolic::Constant->new($value);
                        $tree->replace($value);
                        return undef;
                    }
                    else {
                        die("Invalid TRANSFORMATION_HOOK type '$type'.");
                    }
                }
            }
            elsif ($name =~ /^(VAR|CONST|TREE)_(\w+)/) {
                my $type = $1;
                my $name = $2;
                if ($type eq 'VAR') {
                    if (exists $match_vars->{$name}) {
                        $tree->replace(
                            Math::Symbolic::Variable->new(
                                $match_vars->{$name}
                            )
                        );
                    }
                }
                elsif ($type eq 'TREE') {
                    if (exists $match_trees->{$name}) {
                        $tree->replace($match_trees->{$name});
                    }
                }
                else {
                    if (exists $match_consts->{$name}) {
                        $tree->replace(
                            Math::Symbolic::Constant->new(
                                $match_consts->{$name}
                            )
                        );
                    }
                }
                
                return undef;
            }
            return();
        }
        else {
            return();
        }
    };
    @descend_options = (
        in_place => 1,
        operand_finder => sub {
            if ($_[0]->term_type == T_OPERATOR) {
                return @{$_[0]->{operands}};
            }
            else {
                return();
            }
        },
        before => $subroutine,
    );
    $new->descend(@descend_options);
    return $new;
}

=item apply_recursive

"Recursively" applies the transformation. The Math::Symbolic tree
passed in as argument B<will be modified in-place>.

Hold on: This does not mean
that the transformation is applied again and again, but that the
Math::Symbolic tree you are applying to is descended into and while walking
back up the tree, the transformation is tried for every node.

Basically, it's applied bottom-up. Top-down would not usually make much sense.
If the application to any sub-tree throws a fatal error, this error is silently
caught and the application to other sub-trees is continued.

Usage is the same as with the "shallow" C<apply()> method.

=cut

sub apply_recursive {
    my $self = shift;
    my $tree = shift;

    my $matched = 0;
    $tree->descend(
        after => sub {
            my $node = shift;
            my $res;
            eval { $res = $self->apply($node); };
            if (defined $res and not $@) {
                $matched = 1;
                $node->replace($res);
            }
            return();
        },
        in_place => 1
    );

    return $tree if $matched;
    return();
}

=item to_string

Returns a string representation of the transformation.
In presence of the C<simplify> or C<value> hooks, this may
fail to return the correct represenation. It does not round-trip!

(Generally, it should work if only one hook is present, but fails if
more than one hook is found.)

=cut

sub to_string {
    my $self = shift;
    my $pattern_str = $self->{pattern}->to_string();
    my $repl = $self->{replacement};

    my $repl_str = _repl_to_string($repl);
    
    return $pattern_str . ' -> ' . $repl_str;
}

sub _repl_to_string {
    my $repl = shift;
    my $repl_str = $repl->to_string();
    if ($repl_str =~ /TRANSFORMATION_HOOK/) {
        my @hooks;
        $repl->descend(
            before => sub {
                my $node = shift;
                if (
                    ref($node) =~ /^Math::Symbolic::Variable$/
                    and $node->name() eq 'TRANSFORMATION_HOOK'
                   )
                {
                   push @hooks, $node;
                }
                return();
            },
            in_place => 1, # won't change anything
        );

        $repl_str =~ s{TRANSFORMATION_HOOK}!
            my $node = shift @hooks;
            my $value = $node->value();
            my $operand = _repl_to_string($value->[1]);
            my $name = $value->[0];
            "$name\{ $operand }"
        !ge;
    }

    return $repl_str;
}

=back

=head2 SUBROUTINES

This is a list of public subroutines.

=over 2

=cut

=item new_trafo

This subroutine is an alternative to the C<new()> constructor for
Math::Symbolic::Custom::Transformation objects that uses a hard coded
package name. (So if you want to subclass this module, you should be aware
of that!)

=cut

=item new_trafo_group

This subroutine is the equivalent of C<new_trafo>, but for creation
of new transformation groups. See L<Math::Symbolic::Custom::Transformation::Group>.

=cut

*new_trafo_group = *Math::Symbolic::Custom::Transformation::Group::new_trafo_group;

sub new_trafo {
    unshift @_, __PACKAGE__;
    goto &new;
}

1;
__END__

=back

=head1 SEE ALSO

New versions of this module can be found on http://steffen-mueller.net or CPAN.

This module uses the L<Math::Symbolic> framework for symbolic computations.

L<Math::Symbolic::Custom::Pattern> implements the pattern matching routines.

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006, 2007, 2008, 2009, 2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
