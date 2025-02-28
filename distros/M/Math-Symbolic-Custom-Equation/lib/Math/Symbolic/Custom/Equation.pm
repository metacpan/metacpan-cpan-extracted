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

Version 0.1

=cut

our $VERSION = '0.1';

our $EQ_PH = 'EQ';

use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::Collect 0.32;
use Math::Symbolic::Custom::Factor 0.13;

=head1 DESCRIPTION

This class implements methods for equating two Math::Symbolic expressions, and performing various operations on that equation.

Please note that the methods/interfaces documented below are subject to change in later versions.

=head1 SYNOPSIS

    use strict;
    use Math::Symbolic qw(:all);
    use Math::Symbolic::Custom::Equation;

    # we have two symbolic expressions
    my $expr1 = parse_from_string('a - n'); 
    my $expr2 = parse_from_string('(a + 2) / n');

    # equate them
    my $eq = Math::Symbolic::Custom::Equation->new($expr1, $expr2);
    print $eq->to_string(), "\n"; # a - n = (a + 2) / n

    # We want an expression for a
    my ($a_eq, $type) = $eq->isolate('a');
    unless ( defined($a_eq) && ($type == 1) ) {
        die "Could not isolate 'a'!\n";
    }
    print $a_eq->to_string(), "\n"; # a = (2 + (n ^ 2)) / (n - 1)

    # we want values of a for various values of n
    my $expr3 = $a_eq->RHS();
    foreach my $n (2..5) {
        my $a_val = $expr3->value({'n' => $n});
        # check these values on original equation
        if ( $eq->holds({'a' => $a_val, 'n' => $n}) ) {
            print "At n = $n, a = $a_val\n";
        }
        else {
            print "Error for n = $n, a = $a_val\n";
        }
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
    my $proto = shift;
    my $class = ref($proto) || $proto;
        
    my ($LHS, $RHS) = @_;
    
    # might have been passed an equation in string form
    if ( !defined($RHS) && (ref($LHS) eq "") && ($LHS =~ /=/) ) {
        ($LHS, $RHS) = split(/=/, $LHS);
    }

    $LHS = Math::Symbolic::parse_from_string($LHS) if ref($LHS) !~ /^Math::Symbolic/;
    $RHS = Math::Symbolic::parse_from_string($RHS) if ref($RHS) !~ /^Math::Symbolic/;

    my $self = { LHS => $LHS, RHS => $RHS };
    bless $self, $class;

    return $self;
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

    my $LHS = $self->{LHS};
    my $RHS = $self->{RHS};

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

    my $LHS = $self->{LHS};
    my $RHS = $self->{RHS};

    unless ( defined($LHS) && defined($RHS) ) {
        carp "holds(): equation not properly set up, needs both sides.";
        return undef;
    }

    my $LHS_val = $LHS->value(%{$vals});
    my $RHS_val = $RHS->value(%{$vals});

    unless ( defined($LHS_val) && defined($RHS_val) ) {
        carp "holds(): some problem setting values for equation. Perhaps a variable is missing or there is a typo.";
        return undef;
    }

    return abs($LHS_val - $RHS_val) < $epsilon;
}

=head2 Method simplify

Takes no parameters. Calls Math::Symbolic's simplify() on both sides of the equation (or whichever simplify() is currently 
registered). Currently returns 0 on failure and 1 on success.

=cut

sub simplify {
    my $self = shift;
    
    my $LHS = $self->{LHS};
    my $RHS = $self->{RHS};

    unless ( defined($LHS) && defined($RHS) ) {
        carp "simplify(): equation not properly set up, needs both sides.";
        return 0;
    }

    $self->{LHS} = $LHS->simplify();
    $self->{RHS} = $RHS->simplify();

    return 1;
}

sub _transform {
    my $self = shift;
    my $t1 = shift;

    my $LHS = $self->{LHS};
    my $RHS = $self->{RHS};

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

    $self->{LHS} = $t1->implement($EQ_PH => $LHS);
    $self->{RHS} = $t2->implement($EQ_PH => $RHS);

    return 1;
}

=head2 Method add

Takes one parameter, a Math::Symbolic expression or a text string which can parse to a Math::Symbolic
expression. 

Adds the passed expression to both sides of the equation.

=cut

sub add {
    my $self = shift;
    my $t = shift;

    $t = Math::Symbolic::parse_from_string($t) if ref($t) !~ /^Math::Symbolic/;

    my $operation = Math::Symbolic::Operator->new('+', Math::Symbolic::Variable->new($EQ_PH), $t);

    return $self->_transform($operation);
}

=head2 Method multiply

Takes one parameter, a Math::Symbolic expression or a text string which can parse to a Math::Symbolic
expression. 

Multiplies the passed expression with both sides of the equation.

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

Divides both sides of the equation by the passed expression.

=cut

sub divide {
    my $self = shift;
    my $t = shift;

    $t = Math::Symbolic::parse_from_string($t) if ref($t) !~ /^Math::Symbolic/;

    my $operation = Math::Symbolic::Operator->new('/', Math::Symbolic::Variable->new($EQ_PH), $t);

    return $self->_transform($operation);
}

=head2 Method subtract

Takes one parameter, a Math::Symbolic expression or a text string which can parse to a Math::Symbolic
expression. 

Subtracts the passed expression from both sides of the equation.

=cut

sub subtract {
    my $self = shift;
    my $t = shift;

    $t = Math::Symbolic::parse_from_string($t) if ref($t) !~ /^Math::Symbolic/;

    my $operation = Math::Symbolic::Operator->new('-', Math::Symbolic::Variable->new($EQ_PH), $t);

    return $self->_transform($operation);
}

=head2 Method to_zero

Takes no parameters. Re-arranges the equation to equate to zero, by 
subracting the right-hand side from both sides.

    my $eq = Math::Symbolic::Custom::Equation->new('3*x^3 - 2*x^2 + 5*x - 10 = 5*x + 8');
    $eq->to_zero();
    print $eq->to_string(), "\n"; # ((3 * (x ^ 3)) - 18) - (2 * (x ^ 2)) = 0

=cut

sub to_zero {
    my $self = shift;

    my $LHS = $self->{LHS};
    my $RHS = $self->{RHS};

    unless ( defined($LHS) && defined($RHS) ) {
        carp "transform(): equation not properly set up, needs both sides.";
        return;
    }

    $LHS = Math::Symbolic::Operator->new('-', $self->{LHS}, $self->{RHS})->to_collected();
    $self->LHS($LHS);
    $self->RHS('0');

    return;
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
    
    my $LHS = $self->{LHS};
    my $RHS = $self->{RHS};

    unless ( defined($LHS) && defined($RHS) ) {
        carp "explicit_signature(): equation not properly set up, needs both sides.";
        return 0;
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
the equation. It will return undef if it doesn't succeed.

Currently it returns a new Equation object containing the re-arranged equation, and a flag indicating 
how well it managed to achieve its goal. If the flag is 1, then it successfully isolated the variable.
If it is 2, then it managed to move all instances of the variable to the left-hand side. If it
is 3, then there are instances of the variable on both sides of the equation. To illustrate:-

    my ($new_eq, $type);

    my $eq1 = Math::Symbolic::Custom::Equation->new('y = 2*x + 4');
    print "Original equation: '", $eq1->to_string(), "'\n"; 
    # Original equation: 'y = (2 * x) + 4'
    ($new_eq, $type) = $eq1->isolate('x');
    print "Isolating 'x', got: '", $new_eq->to_string(), "' (flag = $type)\n"; 
    # Isolating 'x', got: 'x = (y - 4) / 2' (flag = 1)

    my $eq2 = Math::Symbolic::Custom::Equation->new('v^2 = u^2 + 2*a*s');
    print "Original equation: '", $eq2->to_string(), "'\n"; 
    # Original equation: 'v ^ 2 = (u ^ 2) + ((2 * a) * s)'
    ($new_eq, $type) = $eq2->isolate('u');
    print "Isolating 'u', got: '", $new_eq->to_string(), "' (flag = $type)\n"; 
    # Isolating 'u', got: 'u ^ 2 = (v ^ 2) - ((2 * a) * s)' (flag = 2)

    my $eq3 = Math::Symbolic::Custom::Equation->new('s = u*t + (1/2) * a * t^2');
    print "Original equation: '", $eq3->to_string(), "'\n"; 
    # Original equation: 's = (u * t) + (((1 / 2) * a) * (t ^ 2))'
    ($new_eq, $type) = $eq3->isolate('t');
    print "Isolating 't', got: '", $new_eq->to_string(), "' (flag = $type)\n"; 
    # Isolating 't', got: 't = (2 * s) / ((2 * u) + (a * t))' (flag = 3)

This interface and approach is likely to change significantly in later versions.

=cut

sub isolate {
    my ($self, $expr) = @_;
    
    $expr = Math::Symbolic::parse_from_string($expr) 
        if ref($expr) !~ /^Math::Symbolic/;
        
    # ensure we've been passed a variable
    if ( ref($expr) ne 'Math::Symbolic::Variable' ) {
        carp "isolate: not passed a variable.";
        return undef;
    }
    
    # ensure it's a var in the equation
    my @v = $self->explicit_signature();
    my @r = grep { $expr->{name} eq $_ } @v;
    
    if ( scalar(@r) == 0 ) {
        carp "isolate: not passed a variable that is present in the equation. (Was passed: '" . 
                $expr->{name} . "'. Variables in equation: ['" . join("', '", @v) . "'])";
        return undef;
    }
    
    # is it already in the correct form? 
    if ( $expr->is_identical( $self->LHS() ) ) {
        return (Math::Symbolic::Custom::Equation->new($self->LHS(), $self->RHS()), 1);
    }
    
    # init search
    my %nodes_todo;
    my %nodes_done;
    my $node_key = $self->to_string();
    $nodes_todo{$node_key} = { LHS => $self->{LHS}, RHS => $self->{RHS} };   
    
    # process the list
    # FIXME: must be a better way to limit the loop
    NODE_LOOP: foreach my $i (0..100) {  
            
        my @todo = keys %nodes_todo;
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
                        # succesfully isolated, return it
                        return (Math::Symbolic::Custom::Equation->new($subject, $object), 1);
                    }
                }
                    
                # put new nodes on the todo pile if appropriate
                if (    !exists($nodes_done{$new_node}) && 
                        !exists($nodes_todo{$new_node}) ) {
                    $nodes_todo{$new_node} = $hash->{$new_node};
                }
            }
        }
        
        # move this node to the done pile
        $nodes_done{$next} = $nodes_todo{$next};
        delete $nodes_todo{$next};
    }    

    # At this point, we don't have a precise isolation of the variable.
    # But perhaps we've managed to get it onto one side of the equation
    my %nodes_2;
    my %nodes_3;
    while ( my ($node_eq, $node_d) = each %nodes_done ) {

        my $LHS = $node_d->{LHS};
        my $RHS = $node_d->{RHS};

        my @RHS_v = $RHS->explicit_signature();
        my @RHS_r = grep { $expr->{name} eq $_ } @RHS_v;
        my @LHS_v = $LHS->explicit_signature();
        my @LHS_r = grep { $expr->{name} eq $_ } @LHS_v;

        if ( (scalar(@LHS_v) == 1) && (scalar(@LHS_r) == 1) ) {
    
            if ( scalar(@RHS_r) == 0 ) {
                $nodes_2{$node_eq} = $node_d;
            }
            else {
                $nodes_3{$node_eq} = $node_d;
            }
        }
        elsif ( (scalar(@RHS_v) == 1) && (scalar(@RHS_r) == 1) ) {      

            if ( scalar(@LHS_r) == 0 ) {   
                $nodes_2{"$RHS = $LHS"} = { LHS => $RHS, RHS => $LHS };
            }
            else {
                $nodes_3{"$RHS = $LHS"} = { LHS => $RHS, RHS => $LHS };
            }
        }        
    }
    
    if ( scalar(keys %nodes_2) ) {

        my @sorted = 
            map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, length($nodes_2{$_}{LHS}->to_string()) ] }
            keys %nodes_2;

        my $LHS = $nodes_2{$sorted[0]}{LHS};
        my $RHS = $nodes_2{$sorted[0]}{RHS};

        return (Math::Symbolic::Custom::Equation->new($LHS, $RHS), 2);
    }

    if ( scalar(keys %nodes_3) ) {

        my @sorted = 
            map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, length($_) ] }
            keys %nodes_3;

        my $LHS = $nodes_3{$sorted[0]}{LHS};
        my $RHS = $nodes_3{$sorted[0]}{RHS};

        return (Math::Symbolic::Custom::Equation->new($LHS, $RHS), 3);
    }

    return undef;
}

sub _expand_collect {
    my ($node_name, $node) = @_;

    my %new_nodes;

    my $LHS = $node->{LHS}->to_collected();
    my $RHS = $node->{RHS}->to_collected();
    
    if ( $LHS->to_string() ne $node->{LHS}->to_string() ) {
        my $new_node = "$LHS = " . $node->{RHS};
        $new_nodes{$new_node} = { LHS => $LHS, RHS => $node->{RHS} };
    }
    
    if ( $RHS->to_string() ne $node->{RHS}->to_string() ) {
        my $new_node = $node->{LHS} . " = $RHS";
        $new_nodes{$new_node} = { LHS => $node->{LHS}, RHS => $RHS };
    }
    
    if ( ($LHS->to_string() ne $node->{LHS}->to_string()) &&
            ($RHS->to_string() ne $node->{RHS}->to_string()) ) {
        my $new_node = "$LHS = $RHS";
        $new_nodes{$new_node} = { LHS => $LHS, RHS => $RHS };
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
        $new_nodes{$new_node} = { LHS => $LHS, RHS => $node->{RHS} };
    }
    
    if ( $RHS->to_string() ne $node->{RHS}->to_string() ) {
        my $new_node = $node->{LHS} . " = $RHS";
        $new_nodes{$new_node} = { LHS => $node->{LHS}, RHS => $RHS };
    }
    
    if ( ($LHS->to_string() ne $node->{LHS}->to_string()) &&
            ($RHS->to_string() ne $node->{RHS}->to_string()) ) {
        my $new_node = "$LHS = $RHS";
        $new_nodes{$new_node} = { LHS => $LHS, RHS => $RHS };
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
            my $new_RHS = Math::Symbolic::Operator->new('*', $t->op2(), $node->{RHS})->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
            } 
        }
        elsif ( $t->type() == B_DIFFERENCE ) {
            my $new_LHS = $t->op1();
            my $new_RHS = Math::Symbolic::Operator->new('+', $t->op2(), $node->{RHS})->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
            }             
        }
        elsif ( $t->type() == B_PRODUCT ) {
            unless ( ($t->op2()->term_type() == T_CONSTANT) && ($t->op2()->value() == 0) ) {
                my $new_LHS = $t->op1();
                my $new_RHS = Math::Symbolic::Operator->new('/', $node->{RHS}, $t->op2())->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
                }            
            }
            unless ( ($t->op1()->term_type() == T_CONSTANT) && ($t->op1()->value() == 0) ) {                
                my $new_LHS = $t->op2();
                my $new_RHS = Math::Symbolic::Operator->new('/', $node->{RHS}, $t->op1())->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
                }
            }
        }
        elsif ( $t->type() == B_SUM ) {
            my $new_LHS = $t->op1();
            my $new_RHS = Math::Symbolic::Operator->new('-', $node->{RHS}, $t->op2())->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
            }            
            $new_LHS = $t->op2();
            $new_RHS = Math::Symbolic::Operator->new('-', $node->{RHS}, $t->op1())->to_collected();
            $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
            }            
        }            
        elsif ( $t->type() == B_EXP ) {

            # FIXME test with Math::Symbolic methods
            if ( ($t->op2()->to_string() eq '0.5') || ($t->op2()->to_string() eq '1 / 2') ) {
                my $new_LHS = $t->op1();
                my $new_RHS = Math::Symbolic::Operator->new('^', $node->{RHS}, Math::Symbolic::Constant->new(2))->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
                }  
            }
        } 
    }
 
    $t = $node->{RHS};
    
    if ( $t->term_type() == T_OPERATOR ) {

        if ( $t->type() == B_DIVISION ) {    
            my $new_RHS = $t->op1();
            my $new_LHS = Math::Symbolic::Operator->new('*', $t->op2(), $node->{LHS})->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
            } 
        }
        elsif ( $t->type() == B_DIFFERENCE ) {
            my $new_RHS = $t->op1();
            my $new_LHS = Math::Symbolic::Operator->new('+', $t->op2(), $node->{LHS})->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
            }             
        }
        elsif ( $t->type() == B_PRODUCT ) {
            unless ( ($t->op2()->term_type() == T_CONSTANT) && ($t->op2()->value() == 0) ) {
                my $new_RHS = $t->op1();
                my $new_LHS = Math::Symbolic::Operator->new('/', $node->{LHS}, $t->op2())->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
                }    
            }
            unless ( ($t->op1()->term_type() == T_CONSTANT) && ($t->op1()->value() == 0) ) {        
                my $new_RHS = $t->op2();
                my $new_LHS = Math::Symbolic::Operator->new('/', $node->{LHS}, $t->op1())->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
                }
            }
        }
        elsif ( $t->type() == B_SUM ) {
            my $new_RHS = $t->op1();
            my $new_LHS = Math::Symbolic::Operator->new('-', $node->{LHS}, $t->op2())->to_collected();
            my $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
            }            
            $new_RHS = $t->op2();
            $new_LHS = Math::Symbolic::Operator->new('-', $node->{LHS}, $t->op1())->to_collected();
            $eq_str = "$new_LHS = $new_RHS";
            if ( (!exists $new_nodes{$eq_str}) ) {
                $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
            }            
        }          
        elsif ( $t->type() == B_EXP ) {

            # FIXME test with Math::Symbolic methods
            if ( ($t->op2()->to_string() eq '0.5') || ($t->op2()->to_string() eq '1 / 2') ) {
                my $new_RHS = $t->op1();
                my $new_LHS = Math::Symbolic::Operator->new('^', $node->{LHS}, Math::Symbolic::Constant->new(2))->to_collected();
                my $eq_str = "$new_LHS = $new_RHS";
                if ( (!exists $new_nodes{$eq_str}) ) {
                    $new_nodes{$eq_str} = { LHS => $new_LHS, RHS => $new_RHS };
                }  
            }
        }       
    } 
    
    return %new_nodes;
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


