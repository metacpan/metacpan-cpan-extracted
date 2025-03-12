package Math::Symbolic::Custom::Equation;

use 5.006;
use strict;
use warnings;
use Carp;

=pod

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Equation - Work with equations of Math::Symbolic expressions

=head1 VERSION

Version 0.2

=cut

our $VERSION = '0.2';

our $EQ_PH = 'EQ';

use Math::Symbolic 0.613 qw(:all);
use Math::Symbolic::Custom::Collect 0.32;
use Math::Symbolic::Custom::Factor 0.13;

=head1 DESCRIPTION

This class implements methods for equating two Math::Symbolic expressions, and performing various operations on that equation.

=head1 EXAMPLE

    use strict;
    use Math::Symbolic 0.613 qw(:all);
    use Math::Symbolic::Custom::Equation 0.2;
    use Math::Symbolic::Custom::Polynomial 0.3;
    use Math::Symbolic::Custom::CollectSimplify 0.2;
    Math::Symbolic::Custom::CollectSimplify->register();

    # Solve the simultaneous equations:-
    # x - 2*y = 7
    # x^2 + 4*y^2 = 37
    my $eq1 = Math::Symbolic::Custom::Equation->new('x - 2*y = 7');
    my $eq2 = Math::Symbolic::Custom::Equation->new('x^2 + 4*y^2 = 37');

    print "Solve the simultaneous equations:-\n\n";
    print "\t[1]\t", $eq1->to_string(), "\n";
    print "\t[2]\t", $eq2->to_string(), "\n\n";

    # Make x the subject of eq. 1
    my $eq1_x = $eq1->isolate('x');
    die "Cannot isolate 'x' in " . $eq1->to_string() . "\n" unless defined $eq1_x;
    print "Make x the subject of [1]: ", $eq1_x->to_string(), "\n\n";
    my $x_expr = $eq1_x->RHS();

    # Substitute into eq. 2, re-arrange to make RHS = 0, and simplify
    my $eq3 = $eq2->implement('x' => $x_expr)->simplify();
    print "Substitute into [2]: ", $eq3->to_string(), "\n\n";

    # Re-arrange it to equal 0
    my $eq3_2 = $eq3->to_zero()->simplify();
    print "Rearrange to equal zero: ", $eq3_2->to_string(), "\n\n";

    # we have an expression for y, solve it
    my ($var, $coeffs, $disc, $roots) = $eq3_2->LHS()->test_polynomial();
    die "Cannot solve quadratic!\n" unless defined($var) && ($var eq 'y');

    my $y_1 = $roots->[0];
    my $y_2 = $roots->[1];
    print "The solutions for y are: ($y_1, $y_2)\n\n";

    # put these solutions into the expression for x in terms of y to get x values
    my $x_1 = $eq1_x->implement('y' => $y_1)->simplify()->RHS();
    my $x_2 = $eq1_x->implement('y' => $y_2)->simplify()->RHS();
    print "The solutions for x given y are: (x = $x_1 when y = $y_1) and (x = $x_2 when y = $y_2)\n\n";

    # Check that these solutions hold for the original equations
    print "Check: ";
    if ( $eq1->holds({'x' => $x_1, 'y' => $y_1}) && $eq2->holds({'x' => $x_1, 'y' => $y_1}) ) {
        print "Solution (x = $x_1, y = $y_1) holds for [1] and [2]\n";
    }
    print "Check: ";
    if ( $eq1->holds({'x' => $x_2, 'y' => $y_2}) && $eq2->holds({'x' => $x_2, 'y' => $y_2}) ) {
        print "Solution (x = $x_2, y = $y_2) holds for [1] and [2]\n";
    }

=head1 METHODS

=head2 Constructor new

Expects the left hand side and right hand side of the desired equation as parameters. These can be Math::Symbolic expressions,
or strings which will be parsed into Math::Symbolic expressions using the parser. Another option is to pass one parameter, an
equation string, from which the left hand side and the right hand side of the equation will be extracted.

    # specify LHS and RHS separately
    my $eq1 = Math::Symbolic::Custom::Equation->new('y', '2*x + 4');
    
    # pass it an equation
    my $eq2 = Math::Symbolic::Custom::Equation->new('y = 2*x + 4');

=cut

sub new {
    my ($proto, $LHS, $RHS) = @_;
    my $class = ref($proto) || $proto;
    my $self;

    if ( ref($proto) && !defined($LHS) ) {
        # copy constructor
        $self->{LHS} = $proto->LHS()->new();
        $self->{RHS} = $proto->RHS()->new();
    }
    else {
        # might have been passed an equation in string form
        if ( !defined($RHS) && (ref($LHS) eq "") && ($LHS =~ /=/) ) {
            ($LHS, $RHS) = split(/=/, $LHS);
        }

        $LHS = Math::Symbolic::parse_from_string($LHS) if ref($LHS) !~ /^Math::Symbolic/;
        $RHS = Math::Symbolic::parse_from_string($RHS) if ref($RHS) !~ /^Math::Symbolic/;

        $self = { LHS => $LHS, RHS => $RHS };
    }

    bless $self, $class;
}

=head2 Method LHS

With no parameter, will return the left-hand side of the equation. 
With a parameter, will set the left-hand side of the equation, and return it.

=cut

sub LHS {
    my $self = shift;
    my $t = shift;
    if ( defined $t ) {
        $t = Math::Symbolic::parse_from_string($t) if ref($t) !~ /^Math::Symbolic/;
        if ( defined $t ) {
            $self->{LHS} = $t;
        }
        else {
            carp "LHS(): not setting undefined LHS";
        }
    }
    return $self->{LHS};
}

=head2 Method RHS

With no parameter, will return the right-hand side of the equation. 
With a parameter, will set the right-hand side of the equation, and return it.

=cut

sub RHS {
    my $self = shift;
    my $t = shift;
    if ( defined $t ) {
        $t = Math::Symbolic::parse_from_string($t) if ref($t) !~ /^Math::Symbolic/;
        if ( defined $t ) {
            $self->{RHS} = $t;
        }
        else {
            carp "RHS(): not setting undefined RHS";
        }
    }
    return $self->{RHS};
}

=head2 Method to_string

Takes no parameter. Will return the equation in string form, e.g. "LHS = RHS".

=cut

sub to_string {
    my $self = shift;

    my $LHS = $self->LHS();
    my $RHS = $self->RHS();

    unless ( defined($LHS) && defined($RHS) ) {
        carp "display(): equation not properly set up, needs both sides.";
        return q{};
    }

    return "$LHS = $RHS";
}

=head2 Method holds

Tests to see if the equation is true for given variable values, passed as a hash reference.
This calls L<Math::Symbolic>'s value() method with the passed values on the expressions for the left-hand side 
and right-hand side and compares the two results.

An optional second argument is a threshold used to set the accuracy of the numerical comparison (set
by default to 1e-11). 

    my $eq = Math::Symbolic::Custom::Equation->new('y', '2*x + 4');

    if ( $eq->holds({'x' => 2, 'y' => 8}) ) {
        print "'", $eq->to_string(), "' holds for x = 2 and y = 8.\n"; 
        # 'y = (2 * x) + 4' holds for x = 2 and y = 8.
    } 

=cut

sub holds {
    my $self = shift;
    my $vals = shift;
    my $epsilon = shift;
    $epsilon = 1e-11 unless defined $epsilon;

    my $LHS = $self->LHS();
    my $RHS = $self->RHS();

    unless ( defined($LHS) && defined($RHS) ) {
        carp "holds(): equation not properly set up, needs both sides.";
        return undef;
    }

    # try hard to force down to a number
    my $LHS_val = $LHS->value(%{$vals});
    if ( ref($LHS_val) =~ /Math::Symbolic::Operator/ ) {
        $LHS_val = $LHS_val->simplify();
    }
    if ( ref($LHS_val) =~ /Math::Symbolic::Constant/ ) {
        $LHS_val = $LHS_val->value();
    }

    my $RHS_val = $RHS->value(%{$vals});   
    if ( ref($RHS_val) =~ /Math::Symbolic::Operator/ ) {
        $RHS_val = $RHS_val->simplify();
    }
    if ( ref($RHS_val) =~ /Math::Symbolic::Constant/ ) {
        $RHS_val = $RHS_val->value();
    }

    unless ( defined($LHS_val) && defined($RHS_val) ) {
        carp "holds(): some problem setting values for equation. Perhaps a variable is missing or there is a typo.";
        return undef;
    }

    return abs($LHS_val - $RHS_val) < $epsilon;
}

=head2 Method simplify

Takes no parameters. Calls Math::Symbolic's simplify() (or whichever simplify() is currently 
registered) on both sides of the equation. If successful returns a new (simplifed) equation object, otherwise undef.

=cut

sub simplify {
    my $self = shift;
    
    my $LHS = $self->LHS()->new();
    my $RHS = $self->RHS()->new();

    unless ( defined($LHS) && defined($RHS) ) {
        carp "simplify(): equation not properly set up, needs both sides.";
        return undef;
    }

    my $new_LHS = $LHS->simplify();
    my $new_RHS = $RHS->simplify();

    if ( defined($new_LHS) && defined($new_RHS) ) {
        return $self->new($new_LHS, $new_RHS);
    }
    
    return undef; # simplify failed
}

=head2 Method implement

Calls Math::Symbolic's implement() on both sides of the equation. This can be used to substitute a specified variable with another 
Math::Symbolic expression (see the example above). If successful returns a new equation object, otherwise undef.

=cut

sub implement {
    my $self = shift;
    my %to_implement = @_;
    
    my $LHS = $self->LHS()->new();
    my $RHS = $self->RHS()->new();

    unless ( defined($LHS) && defined($RHS) ) {
        carp "implement(): equation not properly set up, needs both sides.";
        return undef;
    }

    my $new_LHS = $LHS->implement(%to_implement);
    my $new_RHS = $RHS->implement(%to_implement);

    if ( defined($new_LHS) && defined($new_RHS) ) {
        return $self->new($new_LHS, $new_RHS);
    }
    
    return undef;
}

sub _transform {
    my $self = shift;
    my $t1 = shift;

    my $LHS = $self->LHS()->new();
    my $RHS = $self->RHS()->new();

    unless ( defined($LHS) && defined($RHS) ) {
        carp "transform(): equation not properly set up, needs both sides.";
        return 0;
    }

    $t1 = Math::Symbolic::parse_from_string($t1) if ref($t1) !~ /^Math::Symbolic/;

    unless ( defined $t1 ) {
        carp "transform(): passed expression is not a valid Math::Symbolic expression.";
        return 0;
    }

    my @vars = $t1->explicit_signature();
    my @got_eq = grep { $_ eq $EQ_PH } @vars;
    if ( scalar(@got_eq) == 0 ) {
        carp "transform(): not found equation placeholder variable $EQ_PH in passed expression.";
    }

    my $t2 = $t1->new();

    my $new_LHS = $t1->implement($EQ_PH => $LHS);
    my $new_RHS = $t2->implement($EQ_PH => $RHS);

    if ( defined($new_LHS) && defined($new_RHS) ) {
        return $self->new($new_LHS, $new_RHS);
    }
    
    return undef;
}

=head2 Method add

Takes one parameter, which can be another equation object, or a Math::Symbolic expression (or a text string which can parse to a 
Math::Symbolic expression). If passed an equation then it will perform equation addition, or if passed an expression it will add 
the passed expression to both sides of the equation. Returns a new equation object.

=cut

sub add {
    my $self = shift;
    my $t = shift;

    if ( ref($t) eq ref($self) ) {

        my $LHS1 = $self->LHS()->new();
        my $RHS1 = $self->RHS()->new();
        my $LHS2 = $t->LHS()->new();
        my $RHS2 = $t->RHS()->new();
        my $LHS3 = Math::Symbolic::Operator->new('+', $LHS1, $LHS2);
        my $RHS3 = Math::Symbolic::Operator->new('+', $RHS1, $RHS2);
        return $self->new($LHS3, $RHS3);
    }
    else {

        $t = Math::Symbolic::parse_from_string($t) if ref($t) !~ /^Math::Symbolic/;

        my $operation = Math::Symbolic::Operator->new('+', Math::Symbolic::Variable->new($EQ_PH), $t);

        return $self->_transform($operation);
    }
}

=head2 Method subtract

Takes one parameter, which can be another equation object, or a Math::Symbolic expression (or a text string which can parse to a 
Math::Symbolic expression). If passed an equation then it will perform equation subtraction, or if passed an expression it will subtract
the passed expression to from sides of the equation. Returns a new equation object.

=cut

sub subtract {
    my $self = shift;
    my $t = shift;

    if ( ref($t) eq ref($self) ) {

        my $LHS1 = $self->LHS()->new();
        my $RHS1 = $self->RHS()->new();
        my $LHS2 = $t->LHS()->new();
        my $RHS2 = $t->RHS()->new();
        my $LHS3 = Math::Symbolic::Operator->new('-', $LHS1, $LHS2);
        my $RHS3 = Math::Symbolic::Operator->new('-', $RHS1, $RHS2);
        return $self->new($LHS3, $RHS3);
    }
    else {

        $t = Math::Symbolic::parse_from_string($t) if ref($t) !~ /^Math::Symbolic/;

        my $operation = Math::Symbolic::Operator->new('-', Math::Symbolic::Variable->new($EQ_PH), $t);

        return $self->_transform($operation);
    }
}

=head2 Method multiply

Takes one parameter, a Math::Symbolic expression or a text string which can parse to a Math::Symbolic
expression. 

Multiplies the passed expression with both sides of the equation and returns a new equation object.

=cut

sub multiply {
    my $self = shift;
    my $t = shift;

    $t = Math::Symbolic::parse_from_string($t) if ref($t) !~ /^Math::Symbolic/;

    my $operation = Math::Symbolic::Operator->new('*', $t, Math::Symbolic::Variable->new($EQ_PH));

    return $self->_transform($operation);
}

=head2 Method divide

Takes one parameter, a Math::Symbolic expression or a text string which can parse to a Math::Symbolic
expression. 

Divides both sides of the equation by the passed expression and returns a new equation object.

=cut

sub divide {
    my $self = shift;
    my $t = shift;

    $t = Math::Symbolic::parse_from_string($t) if ref($t) !~ /^Math::Symbolic/;

    my $operation = Math::Symbolic::Operator->new('/', Math::Symbolic::Variable->new($EQ_PH), $t);

    return $self->_transform($operation);
}

=head2 Method to_zero

Takes no parameters. Re-arranges the equation to equate to zero, by subracting the right-hand side from both sides.
Returns a new equation object.

    my $eq = Math::Symbolic::Custom::Equation->new('3*x^3 - 2*x^2 + 5*x - 10 = 5*x + 8');
    $eq->to_zero();
    print $eq->to_string(), "\n"; # ((3 * (x ^ 3)) - 18) - (2 * (x ^ 2)) = 0

=cut

sub to_zero {
    my $self = shift;

    my $LHS = $self->LHS()->new();
    my $RHS = $self->RHS()->new();

    unless ( defined($LHS) && defined($RHS) ) {
        carp "transform(): equation not properly set up, needs both sides.";
        return;
    }

    my $new_LHS = Math::Symbolic::Operator->new('-', $LHS, $RHS);

    return $self->new($new_LHS, '0');
}

=head2 Method explicit_signature

Takes no parameters. Calls Math::Symbolic's explicit_signature() on both sides of the 
equation and returns the de-duped results, effectively returning a list of variables used
in the equation.

    my $eq = Math::Symbolic::Custom::Equation->new('y', '2*x + 4');
    my @vars = $eq->explicit_signature();
    print "Vars: ('", join("', '", sort {$a cmp $b } @vars), "')\n";    # Vars: ('x', 'y')

=cut

sub explicit_signature {
    my $self = shift;
    
    my $LHS = $self->LHS();
    my $RHS = $self->RHS();

    unless ( defined($LHS) && defined($RHS) ) {
        carp "explicit_signature(): equation not properly set up, needs both sides.";
        return ();
    }
    
    my %vars;
    my @LHS_vars = $LHS->explicit_signature();
    my @RHS_vars = $RHS->explicit_signature();
    $vars{$_} = 1 for (@LHS_vars, @RHS_vars);
    
    return keys %vars;
}

=head2 Method isolate

Takes a Math::Symbolic::Variable, or a string which parses to a Math::Symbolic::Variable, as a 
parameter. This method attempts to re-arrange the equation to make that variable the subject of
the equation, returning new equation object(s). It will return undef if it doesn't succeed.

When called in a scalar context, it will return the first (simplest) result it can find. When called
in a list context it will return all the results it can find.

    my $eq = Math::Symbolic::Custom::Equation->new('v^2 = u^2 + 2*a*s');
    my $hit = $eq->isolate('u');
    print "Result 1: ", $hit->to_string(), "\n\n";
    # Result 1: u = ((v ^ 2) - ((2 * a) * s)) ^ (1 / 2)

    my @hits = $eq->isolate('u');
    foreach my $hit (@hits) {
        print "Result 2: ", $hit->to_string(), "\t";
    }
    # Result 2: u = ((v ^ 2) - ((2 * a) * s)) ^ (1 / 2)
    # Result 2: u = -1 * (((v ^ 2) - ((2 * a) * s)) ^ (1 / 2))
    
Warning: this is very different to how it worked in the previous version of the module, and it probably
has a way to go yet.

=cut

sub isolate {
    my ($self, $expr) = @_;

    my $autodetected = 0;

    if ( not defined $expr ) {
        # try to autodetect
        my @v = $self->explicit_signature();
        if (scalar(@v) == 1) {
            $expr = $v[0];
            $autodetected = 1;
        }
        else {
            carp "isolate: not passed a variable and cannot autodetect. (Variables in equation: ['" . 
                join("', '", @v) . "'])";
            return wantarray ? () : undef;
        }
    }

    $expr = Math::Symbolic::parse_from_string($expr) 
        if ref($expr) !~ /^Math::Symbolic/;
        
    # ensure we've been passed a variable
    if ( ref($expr) ne 'Math::Symbolic::Variable' ) {
        carp "isolate: not passed a variable.";
        return wantarray ? () : undef;
    }

    if ( not $autodetected ) {
        # ensure it's a var in the equation
        my @v = $self->explicit_signature();
        my @r = grep { $expr->{name} eq $_ } @v;
        
        if ( scalar(@r) == 0 ) {
            carp "isolate: not passed a variable that is present in the equation. (Was passed: '" . 
                    $expr->{name} . "'. Variables in equation: ['" . join("', '", @v) . "'])";
            return wantarray ? () : undef;
        }
    }
    
    my @matches;

    # is it already in the correct form? 
    if ( $expr->is_identical( $self->LHS() ) ) {
        if ( wantarray ) {
            push @matches, [$self->new($self->LHS(), $self->RHS()), 0];
        }
        else {    
            return $self->new($self->LHS(), $self->RHS());
        }
    }
    
    # init search
    my %nodes_todo;
    my %nodes_done;
    my $node_key = $self->to_string();
    $nodes_todo{$node_key} = { LHS => $self->{LHS}, RHS => $self->{RHS}, level => 0, operation => 'None', previous => 'None', plevel => 'None' };   
  
    # process the list
    # FIXME: must be a better way to limit the loop
    NODE_LOOP: foreach my $i (1..200) {  
            
        my @todo = sort { $nodes_todo{$a}{level} <=> $nodes_todo{$b}{level} } keys %nodes_todo;
        last NODE_LOOP if scalar(@todo) == 0;
        my $next = $todo[0];    # get an unexpanded entry       
        
        # "expand" the node to get other candidate nodes
        # step 1: Collect
        my %step1_nodes = _expand_collect($next, $nodes_todo{$next});

        # step 2: Factor
        my %step2_nodes = _expand_factor($next, $nodes_todo{$next});
        
        # step 3: Unwind operator
        my %step3_nodes = _expand_operator($next, $nodes_todo{$next});        
        
        foreach my $hash (\%step1_nodes, \%step2_nodes, \%step3_nodes) {
            foreach my $new_node (keys %{$hash}) {
                
                $hash->{$new_node}{level} = $i;

                if (    !exists($nodes_done{$new_node}) && 
                        !exists($nodes_todo{$new_node}) ) {

                    if ( ($hash->{$new_node}{operation} !~ /Factor/) && ($hash->{$new_node}{operation} !~ /Collect/) ) {
                        # check if we have sucessfully isolated
                        my ($subject, $object);
                        if ( $expr->is_identical($hash->{$new_node}{LHS}) ) {
                            $subject = $hash->{$new_node}{LHS};
                            $object = $hash->{$new_node}{RHS};
                        }
                        
                        if ( $expr->is_identical($hash->{$new_node}{RHS}) ) {
                            $subject = $hash->{$new_node}{RHS};
                            $object = $hash->{$new_node}{LHS};
                        }
                        
                        if ( defined $object ) {
                            my @v = $object->explicit_signature();
                            my @r = grep { $expr->{name} eq $_ } @v;
                            if ( scalar(@r) == 0 ) {
                                # succesfully isolated, add it to matches
                                push @matches, [$self->new($subject, $object), $hash->{$new_node}{level}];
                            }
                        }
                    }
                    
                    $nodes_todo{$new_node} = $hash->{$new_node};
                }
            }
        }

        unless ( wantarray ) {
            if ( scalar(@matches) ) {                
                # return least "complex"
                my @sorted = sort { $a->_complexity() <=> $b->_complexity() } map { $_->[0] } @matches;
                return $sorted[0];
            }
        }
            
        # move this node to the done pile
        $nodes_done{$next} = $nodes_todo{$next};
        delete $nodes_todo{$next};
    }    

    if ( scalar(@matches) ) {
        if ( wantarray ) {

            my @reduced = sort { $a->_complexity() <=> $b->_complexity() } map { $_->[0] } @matches;
            return @reduced;
        }
        else {           
            my @sorted = sort { $a->_complexity() <=> $b->_complexity() } map { $_->[0] } @matches;
            return $sorted[0];            
        }
    }    

    return wantarray ? () : undef;
}

sub _expand_collect {
    my ($node_name, $node) = @_;

    my %new_nodes;

    my $LHS = $node->{LHS}->to_collected();
    my $RHS = $node->{RHS}->to_collected();
    
    if ( $LHS->to_string() ne $node->{LHS}->to_string() ) {
        my $new_node = "$LHS = " . $node->{RHS};
        $new_nodes{$new_node} = { LHS => $LHS, RHS => $node->{RHS}, previous => $node_name, plevel => $node->{level}, operation => 'Collect LHS' };
    }
    
    if ( $RHS->to_string() ne $node->{RHS}->to_string() ) {
        my $new_node = $node->{LHS} . " = $RHS";
        $new_nodes{$new_node} = { LHS => $node->{LHS}, RHS => $RHS, previous => $node_name, plevel => $node->{level}, operation => 'Collect RHS' };
    }
    
    if ( ($LHS->to_string() ne $node->{LHS}->to_string()) &&
            ($RHS->to_string() ne $node->{RHS}->to_string()) ) {
        my $new_node = "$LHS = $RHS";
        $new_nodes{$new_node} = { LHS => $LHS, RHS => $RHS, previous => $node_name, plevel => $node->{level}, operation => 'Collect LHS & RHS' };
    }

    return %new_nodes;
}

sub _expand_factor {
    my ($node_name, $node) = @_;

    my %new_nodes;

    my $LHS = $node->{LHS}->to_factored();
    my $RHS = $node->{RHS}->to_factored();
    
    if ( $LHS->to_string() ne $node->{LHS}->to_string() ) {
        my $new_node = "$LHS = " . $node->{RHS};
        $new_nodes{$new_node} = { LHS => $LHS, RHS => $node->{RHS}, previous => $node_name, plevel => $node->{level}, operation => 'Factor LHS' };
    }
    
    if ( $RHS->to_string() ne $node->{RHS}->to_string() ) {
        my $new_node = $node->{LHS} . " = $RHS";
        $new_nodes{$new_node} = { LHS => $node->{LHS}, RHS => $RHS, previous => $node_name, plevel => $node->{level}, operation => 'Factor RHS' };
    }
    
    if ( ($LHS->to_string() ne $node->{LHS}->to_string()) &&
            ($RHS->to_string() ne $node->{RHS}->to_string()) ) {
        my $new_node = "$LHS = $RHS";
        $new_nodes{$new_node} = { LHS => $LHS, RHS => $RHS, previous => $node_name, plevel => $node->{level}, operation => 'Factor LHS & RHS' };
    }

    return %new_nodes;
}

sub _expand_operator {
    my ($node_name, $node) = @_;
    
    my %new_nodes;
    my $t;
    
    $t = $node->{LHS};
    
    if ( $t->term_type() == T_OPERATOR ) {

        if ( $t->type() == B_DIVISION ) {    
            my $new_LHS = $t->op1();
            my $new_RHS = Math::Symbolic::Operator->new('*', $node->{RHS}, $t->op2() )->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'LHS unwind division' };
            } 
        }
        elsif ( $t->type() == B_DIFFERENCE ) {
            my $new_LHS = $t->op1();
            my $new_RHS = Math::Symbolic::Operator->new('+', $t->op2(), $node->{RHS})->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'LHS unwind subtraction' };
            }             
        }
        elsif ( $t->type() == B_PRODUCT ) {
            unless ( ($t->op2()->term_type() == T_CONSTANT) && ($t->op2()->value() == 0) ) {
                my $new_LHS = $t->op1();
                my $new_RHS = Math::Symbolic::Operator->new('/', $node->{RHS}, $t->op2())->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'LHS unwind product op2' };
                }            
            }
            unless ( ($t->op1()->term_type() == T_CONSTANT) && ($t->op1()->value() == 0) ) {                
                my $new_LHS = $t->op2();
                my $new_RHS = Math::Symbolic::Operator->new('/', $node->{RHS}, $t->op1())->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'LHS unwind product op1' };
                }
            }
        }
        elsif ( $t->type() == B_SUM ) {
            my $new_LHS = $t->op1();
            my $new_RHS = Math::Symbolic::Operator->new('-', $node->{RHS}, $t->op2())->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'LHS unwind addition op2' };
            }            
            $new_LHS = $t->op2();
            $new_RHS = Math::Symbolic::Operator->new('-', $node->{RHS}, $t->op1())->to_collected();
            $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'LHS unwind addition op1' };
            }            
        }            
        elsif ( $t->type() == B_EXP ) {

            # FIXME test with Math::Symbolic methods
            if ( ($t->op2()->to_string() eq '0.5') || ($t->op2()->to_string() eq '1 / 2') ) {
                my $new_LHS = $t->op1();
                my $new_RHS = Math::Symbolic::Operator->new('^', $node->{RHS}, Math::Symbolic::Constant->new(2))->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'LHS unwind sqrt' };
                }  
            }
            elsif ( $t->op2()->to_string() eq '2' ) {
                my $new_LHS = $t->op1();
                my $new_RHS1 = Math::Symbolic::Operator->new('^', $node->{RHS}, Math::Symbolic::Constant->new(0.5))->to_collected();
                my $eq_str1 = "$new_LHS = $new_RHS1";
                if ( (!exists $new_nodes{$eq_str1}) ) {
                    $new_nodes{$eq_str1} = { LHS => $new_LHS, RHS => $new_RHS1, previous => $node_name, plevel => $node->{level}, operation => 'LHS unwind sqr +ve' };
                }  
                my $new_RHS2 = Math::Symbolic::Operator->new('*', Math::Symbolic::Constant->new(-1), $new_RHS1)->to_collected();
                my $eq_str2 = "$new_LHS = $new_RHS2";
                if ( (!exists $new_nodes{$eq_str2}) ) {
                    $new_nodes{$eq_str2} = { LHS => $new_LHS, RHS => $new_RHS2, previous => $node_name, plevel => $node->{level}, operation => 'LHS unwind sqr -ve' };
                }  
            }
        } 
    }
 
    $t = $node->{RHS};
    
    if ( $t->term_type() == T_OPERATOR ) {

        if ( $t->type() == B_DIVISION ) {    
            my $new_RHS = $t->op1();
            my $new_LHS = Math::Symbolic::Operator->new('*', $node->{LHS}, $t->op2() )->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'RHS unwind division' };
            } 
        }
        elsif ( $t->type() == B_DIFFERENCE ) {
            my $new_RHS = $t->op1();
            my $new_LHS = Math::Symbolic::Operator->new('+', $t->op2(), $node->{LHS})->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'RHS unwind subtraction' };
            }             
        }
        elsif ( $t->type() == B_PRODUCT ) {
            unless ( ($t->op2()->term_type() == T_CONSTANT) && ($t->op2()->value() == 0) ) {
                my $new_RHS = $t->op1();
                my $new_LHS = Math::Symbolic::Operator->new('/', $node->{LHS}, $t->op2())->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'RHS unwind product op2' };
                }    
            }
            unless ( ($t->op1()->term_type() == T_CONSTANT) && ($t->op1()->value() == 0) ) {        
                my $new_RHS = $t->op2();
                my $new_LHS = Math::Symbolic::Operator->new('/', $node->{LHS}, $t->op1())->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'RHS unwind product op1' };
                }
            }
        }
        elsif ( $t->type() == B_SUM ) {
            my $new_RHS = $t->op1();
            my $new_LHS = Math::Symbolic::Operator->new('-', $node->{LHS}, $t->op2())->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'RHS unwind addition op2' };
            }            
            $new_RHS = $t->op2();
            $new_LHS = Math::Symbolic::Operator->new('-', $node->{LHS}, $t->op1())->to_collected();
            $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'RHS unwind addition op1' };
            }            
        }          
        elsif ( $t->type() == B_EXP ) {

            # FIXME test with Math::Symbolic methods
            if ( ($t->op2()->to_string() eq '0.5') || ($t->op2()->to_string() eq '1 / 2') ) {
                my $new_RHS = $t->op1();
                my $new_LHS = Math::Symbolic::Operator->new('^', $node->{LHS}, Math::Symbolic::Constant->new(2))->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'RHS unwind sqrt' };
                }  
            }
            elsif ( $t->op2()->to_string() eq '2' ) {
                my $new_RHS = $t->op1();
                my $new_LHS1 = Math::Symbolic::Operator->new('^', $node->{LHS}, Math::Symbolic::Constant->new(0.5))->to_collected();
                my $eq_str1 = "$new_LHS1 = $new_RHS";
                if ( (!exists $new_nodes{$eq_str1}) ) {
                    $new_nodes{$eq_str1} = { LHS => $new_LHS1, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'RHS unwind sqr +ve' };
                }  
                my $new_LHS2 = Math::Symbolic::Operator->new('*', Math::Symbolic::Constant->new(-1), $new_LHS1)->to_collected();
                my $eq_str2 = "$new_LHS2 = $new_RHS";
                if ( (!exists $new_nodes{$eq_str2}) ) {
                    $new_nodes{$eq_str2} = { LHS => $new_LHS2, RHS => $new_RHS, previous => $node_name, plevel => $node->{level}, operation => 'RHS unwind sqr -ve' };
                }  
            }
        }       
    } 
    
    return %new_nodes;
}


sub _complexity {
    my $self = shift;

    my $LHS_score = _test_complexity($self->LHS());
    my $RHS_score = _test_complexity($self->RHS());

    return $LHS_score + $RHS_score;
}

# Try to achieve a measure of "complexity" of a Math::Symbolic expression.
# The greater the score, the higher the "complexity".
sub _test_complexity {
    my ($tree) = @_;

    # Look at:
    # 1. the depth of the tree
    # 2. the number of constants
    # 3. the number of variable instances (e.g. x * x should count as 2 variables)
    # 4. the number of operations
    my %metrics = ( depth => 0, constants => 0, variables => 0, operations => 0 );
    _walk($tree, 0, \%metrics);

    my $score = 0;
    # it should be possible to weight these metrics;
    # for now all metrics are at weight 1.
    $score += $_ for values %metrics;

    return $score;
}

# helper routine to walk the Math::Symbolic expression tree and tot up the metrics.
sub _walk {
    my ($node, $depth, $hr) = @_;

    $hr->{depth} = $depth if $depth > $hr->{depth};

    if ($node->term_type() == T_CONSTANT) {
        $hr->{constants}++;
    } elsif ($node->term_type() == T_VARIABLE) {
        $hr->{variables}++;
    } else {
        $hr->{operations}++;
        foreach my $child (@{$node->{operands}}) {
            _walk($child, $depth + 1, $hr);
        }
    }
}


=head1 SEE ALSO

L<Math::Symbolic>

=head1 AUTHOR

Matt Johnson, C<< <mjohnson at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Steffen Mueller, author of Math::Symbolic

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Matt Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
__END__


