#
# This is a generated file using the command:
# /usr/bin/perl script/generateTemplate.pl ECMAScript-262-5
#
use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Template;

# ABSTRACT: Template for ECMAScript_262_5 transpilation using an AST


our $VERSION = '0.020'; # VERSION


sub new {
    my ($class, $optionsp) = @_;

    $optionsp //= {};

    my $self = {
                _nindent            => 0,
                _g1Callback         => exists($optionsp->{g1Callback})         ? $optionsp->{g1Callback}         : sub { return 1; },
                _g1CallbackArgs     => exists($optionsp->{g1CallbackArgs})     ? $optionsp->{g1CallbackArgs}     : [],
                _lexemeCallback     => exists($optionsp->{lexemeCallback})     ? $optionsp->{lexemeCallback}     : sub { return 0; },
                _lexemeCallbackArgs => exists($optionsp->{lexemeCallbackArgs}) ? $optionsp->{lexemeCallbackArgs} : []
               };
    bless($self, $class);
    return $self;
}


sub lexeme {
    my $self = shift;

    my $rc = '';

    if (! &{$self->{_lexemeCallback}}(@{$self->{_lexemeCallbackArgs}}, \$rc, @_)) {

        # my ($name, $ruleId, $value, $index, $lhs, @rhs) = @_;

        my $lexeme = $_[2]->[2];
        if    ($lexeme eq ';') { $rc = " ;\n" . $self->indent();  }
        elsif ($lexeme eq '{') { $rc = " {\n" . $self->indent(1); }
        elsif ($lexeme eq '}') { $rc = "\n"  . $self->indent(-1) . " }\n" . $self->indent();}
        else                   { $rc = " $lexeme"; }
      }

    return $rc;
}


sub indent {
    my ($self, $inc) = @_;

    if (defined($inc)) {
	$self->{_nindent} += $inc;
    }

    return '  ' x $self->{_nindent};
}


sub transpile {
    my ($self, $ast) = @_;

    my @worklist = ($ast);
    my $transpile = '';
    do {
	my $obj = shift(@worklist);
	if (ref($obj) eq 'HASH') {
	    my $g1 = 'G1_' . $obj->{ruleId};
	    # print STDERR "==> @{$obj->{values}}\n";
	    foreach (reverse 0..$#{$obj->{values}}) {
		my $value = $obj->{values}->[$_];
		if (ref($value) eq 'HASH') {
		    # print STDERR "Unshift $value\n";
		    unshift(@worklist, $value);
		} else {
		    # print STDERR "Unshift [ $g1, $value, $_ ]\n";
		    unshift(@worklist, [ $g1, $value, $_ ]);
		}
	    }
	} else {
	    my ($curMethod, $value, $index) = @{$obj};
	    # print STDERR "==> Calling $curMethod($value, $index)\n";
	    $transpile .= $self->$curMethod($value, $index);
	    # print STDERR "==> $transpile\n";
	}
    } while (@worklist);

    return $transpile;

#    my ($ruleId, $value) = ($ast->{ruleId}, $ast->{values});
#    my $method = "G1_$ruleId";
#    return $self->$method($value);
}



sub G1_0 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 0, $value, $index, 'Literal', 'NullLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_1 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 1, $value, $index, 'Literal', 'BooleanLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_2 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 2, $value, $index, 'Literal', 'NumericLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_3 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 3, $value, $index, 'Literal', 'StringLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_4 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 4, $value, $index, 'Literal', 'RegularExpressionLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_5 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 5, $value, $index, 'PrimaryExpression', 'THIS')) {
        if ($index == 0) {
            $rc = $self->lexeme('THIS', 5, $value, 0, 'PrimaryExpression', 'THIS');
        }
    }

    return $rc;
}



sub G1_6 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 6, $value, $index, 'PrimaryExpression', 'IDENTIFIER')) {
        if ($index == 0) {
            $rc = $self->lexeme('IDENTIFIER', 6, $value, 0, 'PrimaryExpression', 'IDENTIFIER');
        }
    }

    return $rc;
}



sub G1_7 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 7, $value, $index, 'PrimaryExpression', 'Literal')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_8 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 8, $value, $index, 'PrimaryExpression', 'ArrayLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_9 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 9, $value, $index, 'PrimaryExpression', 'ObjectLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_10 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 10, $value, $index, 'PrimaryExpression', 'LPAREN', 'Expression', 'RPAREN')) {
        if ($index == 0) {
            $rc = $self->lexeme('LPAREN', 10, $value, 0, 'PrimaryExpression', 'LPAREN', 'Expression', 'RPAREN');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('RPAREN', 10, $value, 2, 'PrimaryExpression', 'LPAREN', 'Expression', 'RPAREN');
        }
    }

    return $rc;
}



sub G1_11 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 11, $value, $index, 'ArrayLiteral', 'LBRACKET', 'Elisionopt', 'RBRACKET')) {
        if ($index == 0) {
            $rc = $self->lexeme('LBRACKET', 11, $value, 0, 'ArrayLiteral', 'LBRACKET', 'Elisionopt', 'RBRACKET');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('RBRACKET', 11, $value, 2, 'ArrayLiteral', 'LBRACKET', 'Elisionopt', 'RBRACKET');
        }
    }

    return $rc;
}



sub G1_12 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 12, $value, $index, 'ArrayLiteral', 'LBRACKET', 'ElementList', 'RBRACKET')) {
        if ($index == 0) {
            $rc = $self->lexeme('LBRACKET', 12, $value, 0, 'ArrayLiteral', 'LBRACKET', 'ElementList', 'RBRACKET');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('RBRACKET', 12, $value, 2, 'ArrayLiteral', 'LBRACKET', 'ElementList', 'RBRACKET');
        }
    }

    return $rc;
}



sub G1_13 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 13, $value, $index, 'ArrayLiteral', 'LBRACKET', 'ElementList', 'COMMA', 'Elisionopt', 'RBRACKET')) {
        if ($index == 0) {
            $rc = $self->lexeme('LBRACKET', 13, $value, 0, 'ArrayLiteral', 'LBRACKET', 'ElementList', 'COMMA', 'Elisionopt', 'RBRACKET');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('COMMA', 13, $value, 2, 'ArrayLiteral', 'LBRACKET', 'ElementList', 'COMMA', 'Elisionopt', 'RBRACKET');
        }
        elsif ($index == 3) {
        }
        elsif ($index == 4) {
            $rc = $self->lexeme('RBRACKET', 13, $value, 4, 'ArrayLiteral', 'LBRACKET', 'ElementList', 'COMMA', 'Elisionopt', 'RBRACKET');
        }
    }

    return $rc;
}



sub G1_14 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 14, $value, $index, 'ElementList', 'Elisionopt', 'AssignmentExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_15 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 15, $value, $index, 'ElementList', 'ElementList', 'COMMA', 'Elisionopt', 'AssignmentExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COMMA', 15, $value, 1, 'ElementList', 'ElementList', 'COMMA', 'Elisionopt', 'AssignmentExpression');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
        }
    }

    return $rc;
}



sub G1_16 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 16, $value, $index, 'Elision', 'COMMA')) {
        if ($index == 0) {
            $rc = $self->lexeme('COMMA', 16, $value, 0, 'Elision', 'COMMA');
        }
    }

    return $rc;
}



sub G1_17 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 17, $value, $index, 'Elision', 'Elision', 'COMMA')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COMMA', 17, $value, 1, 'Elision', 'Elision', 'COMMA');
        }
    }

    return $rc;
}



sub G1_18 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 18, $value, $index, 'Elisionopt', 'Elision')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_19 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 19, $value, $index, 'Elisionopt', )) {
    }

    return $rc;
}



sub G1_20 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 20, $value, $index, 'ObjectLiteral', 'LCURLY', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('LCURLY', 20, $value, 0, 'ObjectLiteral', 'LCURLY', 'RCURLY');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('RCURLY', 20, $value, 1, 'ObjectLiteral', 'LCURLY', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_21 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 21, $value, $index, 'ObjectLiteral', 'LCURLY', 'PropertyNameAndValueList', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('LCURLY', 21, $value, 0, 'ObjectLiteral', 'LCURLY', 'PropertyNameAndValueList', 'RCURLY');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('RCURLY', 21, $value, 2, 'ObjectLiteral', 'LCURLY', 'PropertyNameAndValueList', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_22 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 22, $value, $index, 'ObjectLiteral', 'LCURLY', 'PropertyNameAndValueList', 'COMMA', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('LCURLY', 22, $value, 0, 'ObjectLiteral', 'LCURLY', 'PropertyNameAndValueList', 'COMMA', 'RCURLY');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('COMMA', 22, $value, 2, 'ObjectLiteral', 'LCURLY', 'PropertyNameAndValueList', 'COMMA', 'RCURLY');
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RCURLY', 22, $value, 3, 'ObjectLiteral', 'LCURLY', 'PropertyNameAndValueList', 'COMMA', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_23 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 23, $value, $index, 'PropertyNameAndValueList', 'PropertyAssignment')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_24 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 24, $value, $index, 'PropertyNameAndValueList', 'PropertyNameAndValueList', 'COMMA', 'PropertyAssignment')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COMMA', 24, $value, 1, 'PropertyNameAndValueList', 'PropertyNameAndValueList', 'COMMA', 'PropertyAssignment');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_25 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 25, $value, $index, 'PropertyAssignment', 'PropertyName', 'COLON', 'AssignmentExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COLON', 25, $value, 1, 'PropertyAssignment', 'PropertyName', 'COLON', 'AssignmentExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_26 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 26, $value, $index, 'PropertyAssignment', 'GET', 'PropertyName', 'LPAREN', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('GET', 26, $value, 0, 'PropertyAssignment', 'GET', 'PropertyName', 'LPAREN', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('LPAREN', 26, $value, 2, 'PropertyAssignment', 'GET', 'PropertyName', 'LPAREN', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RPAREN', 26, $value, 3, 'PropertyAssignment', 'GET', 'PropertyName', 'LPAREN', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 4) {
            $rc = $self->lexeme('LCURLY', 26, $value, 4, 'PropertyAssignment', 'GET', 'PropertyName', 'LPAREN', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 5) {
        }
        elsif ($index == 6) {
            $rc = $self->lexeme('RCURLY', 26, $value, 6, 'PropertyAssignment', 'GET', 'PropertyName', 'LPAREN', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_27 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 27, $value, $index, 'PropertyAssignment', 'SET', 'PropertyName', 'LPAREN', 'PropertySetParameterList', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('SET', 27, $value, 0, 'PropertyAssignment', 'SET', 'PropertyName', 'LPAREN', 'PropertySetParameterList', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('LPAREN', 27, $value, 2, 'PropertyAssignment', 'SET', 'PropertyName', 'LPAREN', 'PropertySetParameterList', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 3) {
        }
        elsif ($index == 4) {
            $rc = $self->lexeme('RPAREN', 27, $value, 4, 'PropertyAssignment', 'SET', 'PropertyName', 'LPAREN', 'PropertySetParameterList', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 5) {
            $rc = $self->lexeme('LCURLY', 27, $value, 5, 'PropertyAssignment', 'SET', 'PropertyName', 'LPAREN', 'PropertySetParameterList', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 6) {
        }
        elsif ($index == 7) {
            $rc = $self->lexeme('RCURLY', 27, $value, 7, 'PropertyAssignment', 'SET', 'PropertyName', 'LPAREN', 'PropertySetParameterList', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_28 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 28, $value, $index, 'PropertyName', 'IDENTIFIERNAME')) {
        if ($index == 0) {
            $rc = $self->lexeme('IDENTIFIERNAME', 28, $value, 0, 'PropertyName', 'IDENTIFIERNAME');
        }
    }

    return $rc;
}



sub G1_29 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 29, $value, $index, 'PropertyName', 'StringLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_30 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 30, $value, $index, 'PropertyName', 'NumericLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_31 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 31, $value, $index, 'PropertySetParameterList', 'IDENTIFIER')) {
        if ($index == 0) {
            $rc = $self->lexeme('IDENTIFIER', 31, $value, 0, 'PropertySetParameterList', 'IDENTIFIER');
        }
    }

    return $rc;
}



sub G1_32 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 32, $value, $index, 'MemberExpression', 'PrimaryExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_33 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 33, $value, $index, 'MemberExpression', 'FunctionExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_34 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 34, $value, $index, 'MemberExpression', 'MemberExpression', 'LBRACKET', 'Expression', 'RBRACKET')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LBRACKET', 34, $value, 1, 'MemberExpression', 'MemberExpression', 'LBRACKET', 'Expression', 'RBRACKET');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RBRACKET', 34, $value, 3, 'MemberExpression', 'MemberExpression', 'LBRACKET', 'Expression', 'RBRACKET');
        }
    }

    return $rc;
}



sub G1_35 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 35, $value, $index, 'MemberExpression', 'MemberExpression', 'DOT', 'IDENTIFIERNAME')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('DOT', 35, $value, 1, 'MemberExpression', 'MemberExpression', 'DOT', 'IDENTIFIERNAME');
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('IDENTIFIERNAME', 35, $value, 2, 'MemberExpression', 'MemberExpression', 'DOT', 'IDENTIFIERNAME');
        }
    }

    return $rc;
}



sub G1_36 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 36, $value, $index, 'MemberExpression', 'NEW', 'MemberExpression', 'Arguments')) {
        if ($index == 0) {
            $rc = $self->lexeme('NEW', 36, $value, 0, 'MemberExpression', 'NEW', 'MemberExpression', 'Arguments');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_37 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 37, $value, $index, 'NewExpression', 'MemberExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_38 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 38, $value, $index, 'NewExpression', 'NEW', 'NewExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('NEW', 38, $value, 0, 'NewExpression', 'NEW', 'NewExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_39 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 39, $value, $index, 'CallExpression', 'MemberExpression', 'Arguments')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_40 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 40, $value, $index, 'CallExpression', 'CallExpression', 'Arguments')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_41 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 41, $value, $index, 'CallExpression', 'CallExpression', 'LBRACKET', 'Expression', 'RBRACKET')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LBRACKET', 41, $value, 1, 'CallExpression', 'CallExpression', 'LBRACKET', 'Expression', 'RBRACKET');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RBRACKET', 41, $value, 3, 'CallExpression', 'CallExpression', 'LBRACKET', 'Expression', 'RBRACKET');
        }
    }

    return $rc;
}



sub G1_42 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 42, $value, $index, 'CallExpression', 'CallExpression', 'DOT', 'IDENTIFIERNAME')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('DOT', 42, $value, 1, 'CallExpression', 'CallExpression', 'DOT', 'IDENTIFIERNAME');
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('IDENTIFIERNAME', 42, $value, 2, 'CallExpression', 'CallExpression', 'DOT', 'IDENTIFIERNAME');
        }
    }

    return $rc;
}



sub G1_43 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 43, $value, $index, 'Arguments', 'LPAREN', 'RPAREN')) {
        if ($index == 0) {
            $rc = $self->lexeme('LPAREN', 43, $value, 0, 'Arguments', 'LPAREN', 'RPAREN');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('RPAREN', 43, $value, 1, 'Arguments', 'LPAREN', 'RPAREN');
        }
    }

    return $rc;
}



sub G1_44 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 44, $value, $index, 'Arguments', 'LPAREN', 'ArgumentList', 'RPAREN')) {
        if ($index == 0) {
            $rc = $self->lexeme('LPAREN', 44, $value, 0, 'Arguments', 'LPAREN', 'ArgumentList', 'RPAREN');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('RPAREN', 44, $value, 2, 'Arguments', 'LPAREN', 'ArgumentList', 'RPAREN');
        }
    }

    return $rc;
}



sub G1_45 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 45, $value, $index, 'ArgumentList', 'AssignmentExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_46 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 46, $value, $index, 'ArgumentList', 'ArgumentList', 'COMMA', 'AssignmentExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COMMA', 46, $value, 1, 'ArgumentList', 'ArgumentList', 'COMMA', 'AssignmentExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_47 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 47, $value, $index, 'LeftHandSideExpression', 'NewExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_48 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 48, $value, $index, 'LeftHandSideExpression', 'CallExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_49 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 49, $value, $index, 'PostfixExpression', 'LeftHandSideExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_50 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 50, $value, $index, 'PostfixExpression', 'LeftHandSideExpression', 'PLUSPLUS_POSTFIX')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('PLUSPLUS_POSTFIX', 50, $value, 1, 'PostfixExpression', 'LeftHandSideExpression', 'PLUSPLUS_POSTFIX');
        }
    }

    return $rc;
}



sub G1_51 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 51, $value, $index, 'PostfixExpression', 'LeftHandSideExpression', 'MINUSMINUS_POSTFIX')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('MINUSMINUS_POSTFIX', 51, $value, 1, 'PostfixExpression', 'LeftHandSideExpression', 'MINUSMINUS_POSTFIX');
        }
    }

    return $rc;
}



sub G1_52 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 52, $value, $index, 'UnaryExpression', 'PostfixExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_53 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 53, $value, $index, 'UnaryExpression', 'DELETE', 'UnaryExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('DELETE', 53, $value, 0, 'UnaryExpression', 'DELETE', 'UnaryExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_54 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 54, $value, $index, 'UnaryExpression', 'VOID', 'UnaryExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('VOID', 54, $value, 0, 'UnaryExpression', 'VOID', 'UnaryExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_55 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 55, $value, $index, 'UnaryExpression', 'TYPEOF', 'UnaryExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('TYPEOF', 55, $value, 0, 'UnaryExpression', 'TYPEOF', 'UnaryExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_56 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 56, $value, $index, 'UnaryExpression', 'PLUSPLUS', 'UnaryExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('PLUSPLUS', 56, $value, 0, 'UnaryExpression', 'PLUSPLUS', 'UnaryExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_57 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 57, $value, $index, 'UnaryExpression', 'MINUSMINUS', 'UnaryExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('MINUSMINUS', 57, $value, 0, 'UnaryExpression', 'MINUSMINUS', 'UnaryExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_58 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 58, $value, $index, 'UnaryExpression', 'PLUS', 'UnaryExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('PLUS', 58, $value, 0, 'UnaryExpression', 'PLUS', 'UnaryExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_59 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 59, $value, $index, 'UnaryExpression', 'MINUS', 'UnaryExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('MINUS', 59, $value, 0, 'UnaryExpression', 'MINUS', 'UnaryExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_60 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 60, $value, $index, 'UnaryExpression', 'INVERT', 'UnaryExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('INVERT', 60, $value, 0, 'UnaryExpression', 'INVERT', 'UnaryExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_61 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 61, $value, $index, 'UnaryExpression', 'NOT', 'UnaryExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('NOT', 61, $value, 0, 'UnaryExpression', 'NOT', 'UnaryExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_62 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 62, $value, $index, 'MultiplicativeExpression', 'UnaryExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_63 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 63, $value, $index, 'MultiplicativeExpression', 'MultiplicativeExpression', 'MUL', 'UnaryExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('MUL', 63, $value, 1, 'MultiplicativeExpression', 'MultiplicativeExpression', 'MUL', 'UnaryExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_64 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 64, $value, $index, 'MultiplicativeExpression', 'MultiplicativeExpression', 'DIV', 'UnaryExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('DIV', 64, $value, 1, 'MultiplicativeExpression', 'MultiplicativeExpression', 'DIV', 'UnaryExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_65 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 65, $value, $index, 'MultiplicativeExpression', 'MultiplicativeExpression', 'MODULUS', 'UnaryExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('MODULUS', 65, $value, 1, 'MultiplicativeExpression', 'MultiplicativeExpression', 'MODULUS', 'UnaryExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_66 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 66, $value, $index, 'AdditiveExpression', 'MultiplicativeExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_67 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 67, $value, $index, 'AdditiveExpression', 'AdditiveExpression', 'PLUS', 'MultiplicativeExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('PLUS', 67, $value, 1, 'AdditiveExpression', 'AdditiveExpression', 'PLUS', 'MultiplicativeExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_68 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 68, $value, $index, 'AdditiveExpression', 'AdditiveExpression', 'MINUS', 'MultiplicativeExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('MINUS', 68, $value, 1, 'AdditiveExpression', 'AdditiveExpression', 'MINUS', 'MultiplicativeExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_69 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 69, $value, $index, 'ShiftExpression', 'AdditiveExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_70 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 70, $value, $index, 'ShiftExpression', 'ShiftExpression', 'LEFTMOVE', 'AdditiveExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LEFTMOVE', 70, $value, 1, 'ShiftExpression', 'ShiftExpression', 'LEFTMOVE', 'AdditiveExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_71 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 71, $value, $index, 'ShiftExpression', 'ShiftExpression', 'RIGHTMOVE', 'AdditiveExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('RIGHTMOVE', 71, $value, 1, 'ShiftExpression', 'ShiftExpression', 'RIGHTMOVE', 'AdditiveExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_72 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 72, $value, $index, 'ShiftExpression', 'ShiftExpression', 'RIGHTMOVEFILL', 'AdditiveExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('RIGHTMOVEFILL', 72, $value, 1, 'ShiftExpression', 'ShiftExpression', 'RIGHTMOVEFILL', 'AdditiveExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_73 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 73, $value, $index, 'RelationalExpression', 'ShiftExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_74 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 74, $value, $index, 'RelationalExpression', 'RelationalExpression', 'LT', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LT', 74, $value, 1, 'RelationalExpression', 'RelationalExpression', 'LT', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_75 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 75, $value, $index, 'RelationalExpression', 'RelationalExpression', 'GT', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('GT', 75, $value, 1, 'RelationalExpression', 'RelationalExpression', 'GT', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_76 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 76, $value, $index, 'RelationalExpression', 'RelationalExpression', 'LE', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LE', 76, $value, 1, 'RelationalExpression', 'RelationalExpression', 'LE', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_77 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 77, $value, $index, 'RelationalExpression', 'RelationalExpression', 'GE', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('GE', 77, $value, 1, 'RelationalExpression', 'RelationalExpression', 'GE', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_78 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 78, $value, $index, 'RelationalExpression', 'RelationalExpression', 'INSTANCEOF', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('INSTANCEOF', 78, $value, 1, 'RelationalExpression', 'RelationalExpression', 'INSTANCEOF', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_79 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 79, $value, $index, 'RelationalExpression', 'RelationalExpression', 'IN', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('IN', 79, $value, 1, 'RelationalExpression', 'RelationalExpression', 'IN', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_80 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 80, $value, $index, 'RelationalExpressionNoIn', 'ShiftExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_81 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 81, $value, $index, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'LT', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LT', 81, $value, 1, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'LT', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_82 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 82, $value, $index, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'GT', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('GT', 82, $value, 1, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'GT', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_83 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 83, $value, $index, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'LE', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LE', 83, $value, 1, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'LE', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_84 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 84, $value, $index, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'GE', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('GE', 84, $value, 1, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'GE', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_85 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 85, $value, $index, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'INSTANCEOF', 'ShiftExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('INSTANCEOF', 85, $value, 1, 'RelationalExpressionNoIn', 'RelationalExpressionNoIn', 'INSTANCEOF', 'ShiftExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_86 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 86, $value, $index, 'EqualityExpression', 'RelationalExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_87 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 87, $value, $index, 'EqualityExpression', 'EqualityExpression', 'EQ', 'RelationalExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('EQ', 87, $value, 1, 'EqualityExpression', 'EqualityExpression', 'EQ', 'RelationalExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_88 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 88, $value, $index, 'EqualityExpression', 'EqualityExpression', 'NE', 'RelationalExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('NE', 88, $value, 1, 'EqualityExpression', 'EqualityExpression', 'NE', 'RelationalExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_89 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 89, $value, $index, 'EqualityExpression', 'EqualityExpression', 'STRICTEQ', 'RelationalExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('STRICTEQ', 89, $value, 1, 'EqualityExpression', 'EqualityExpression', 'STRICTEQ', 'RelationalExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_90 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 90, $value, $index, 'EqualityExpression', 'EqualityExpression', 'STRICTNE', 'RelationalExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('STRICTNE', 90, $value, 1, 'EqualityExpression', 'EqualityExpression', 'STRICTNE', 'RelationalExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_91 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 91, $value, $index, 'EqualityExpressionNoIn', 'RelationalExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_92 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 92, $value, $index, 'EqualityExpressionNoIn', 'EqualityExpressionNoIn', 'EQ', 'RelationalExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('EQ', 92, $value, 1, 'EqualityExpressionNoIn', 'EqualityExpressionNoIn', 'EQ', 'RelationalExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_93 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 93, $value, $index, 'EqualityExpressionNoIn', 'EqualityExpressionNoIn', 'NE', 'RelationalExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('NE', 93, $value, 1, 'EqualityExpressionNoIn', 'EqualityExpressionNoIn', 'NE', 'RelationalExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_94 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 94, $value, $index, 'EqualityExpressionNoIn', 'EqualityExpressionNoIn', 'STRICTEQ', 'RelationalExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('STRICTEQ', 94, $value, 1, 'EqualityExpressionNoIn', 'EqualityExpressionNoIn', 'STRICTEQ', 'RelationalExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_95 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 95, $value, $index, 'EqualityExpressionNoIn', 'EqualityExpressionNoIn', 'STRICTNE', 'RelationalExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('STRICTNE', 95, $value, 1, 'EqualityExpressionNoIn', 'EqualityExpressionNoIn', 'STRICTNE', 'RelationalExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_96 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 96, $value, $index, 'BitwiseANDExpression', 'EqualityExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_97 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 97, $value, $index, 'BitwiseANDExpression', 'BitwiseANDExpression', 'BITAND', 'EqualityExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('BITAND', 97, $value, 1, 'BitwiseANDExpression', 'BitwiseANDExpression', 'BITAND', 'EqualityExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_98 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 98, $value, $index, 'BitwiseANDExpressionNoIn', 'EqualityExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_99 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 99, $value, $index, 'BitwiseANDExpressionNoIn', 'BitwiseANDExpressionNoIn', 'BITAND', 'EqualityExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('BITAND', 99, $value, 1, 'BitwiseANDExpressionNoIn', 'BitwiseANDExpressionNoIn', 'BITAND', 'EqualityExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_100 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 100, $value, $index, 'BitwiseXORExpression', 'BitwiseANDExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_101 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 101, $value, $index, 'BitwiseXORExpression', 'BitwiseXORExpression', 'BITXOR', 'BitwiseANDExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('BITXOR', 101, $value, 1, 'BitwiseXORExpression', 'BitwiseXORExpression', 'BITXOR', 'BitwiseANDExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_102 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 102, $value, $index, 'BitwiseXORExpressionNoIn', 'BitwiseANDExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_103 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 103, $value, $index, 'BitwiseXORExpressionNoIn', 'BitwiseXORExpressionNoIn', 'BITXOR', 'BitwiseANDExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('BITXOR', 103, $value, 1, 'BitwiseXORExpressionNoIn', 'BitwiseXORExpressionNoIn', 'BITXOR', 'BitwiseANDExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_104 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 104, $value, $index, 'BitwiseORExpression', 'BitwiseXORExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_105 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 105, $value, $index, 'BitwiseORExpression', 'BitwiseORExpression', 'BITOR', 'BitwiseXORExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('BITOR', 105, $value, 1, 'BitwiseORExpression', 'BitwiseORExpression', 'BITOR', 'BitwiseXORExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_106 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 106, $value, $index, 'BitwiseORExpressionNoIn', 'BitwiseXORExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_107 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 107, $value, $index, 'BitwiseORExpressionNoIn', 'BitwiseORExpressionNoIn', 'BITOR', 'BitwiseXORExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('BITOR', 107, $value, 1, 'BitwiseORExpressionNoIn', 'BitwiseORExpressionNoIn', 'BITOR', 'BitwiseXORExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_108 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 108, $value, $index, 'LogicalANDExpression', 'BitwiseORExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_109 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 109, $value, $index, 'LogicalANDExpression', 'LogicalANDExpression', 'AND', 'BitwiseORExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('AND', 109, $value, 1, 'LogicalANDExpression', 'LogicalANDExpression', 'AND', 'BitwiseORExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_110 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 110, $value, $index, 'LogicalANDExpressionNoIn', 'BitwiseORExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_111 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 111, $value, $index, 'LogicalANDExpressionNoIn', 'LogicalANDExpressionNoIn', 'AND', 'BitwiseORExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('AND', 111, $value, 1, 'LogicalANDExpressionNoIn', 'LogicalANDExpressionNoIn', 'AND', 'BitwiseORExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_112 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 112, $value, $index, 'LogicalORExpression', 'LogicalANDExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_113 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 113, $value, $index, 'LogicalORExpression', 'LogicalORExpression', 'OR', 'LogicalANDExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('OR', 113, $value, 1, 'LogicalORExpression', 'LogicalORExpression', 'OR', 'LogicalANDExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_114 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 114, $value, $index, 'LogicalORExpressionNoIn', 'LogicalANDExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_115 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 115, $value, $index, 'LogicalORExpressionNoIn', 'LogicalORExpressionNoIn', 'OR', 'LogicalANDExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('OR', 115, $value, 1, 'LogicalORExpressionNoIn', 'LogicalORExpressionNoIn', 'OR', 'LogicalANDExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_116 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 116, $value, $index, 'ConditionalExpression', 'LogicalORExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_117 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 117, $value, $index, 'ConditionalExpression', 'LogicalORExpression', 'QUESTION_MARK', 'AssignmentExpression', 'COLON', 'AssignmentExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('QUESTION_MARK', 117, $value, 1, 'ConditionalExpression', 'LogicalORExpression', 'QUESTION_MARK', 'AssignmentExpression', 'COLON', 'AssignmentExpression');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('COLON', 117, $value, 3, 'ConditionalExpression', 'LogicalORExpression', 'QUESTION_MARK', 'AssignmentExpression', 'COLON', 'AssignmentExpression');
        }
        elsif ($index == 4) {
        }
    }

    return $rc;
}



sub G1_118 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 118, $value, $index, 'ConditionalExpressionNoIn', 'LogicalORExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_119 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 119, $value, $index, 'ConditionalExpressionNoIn', 'LogicalORExpressionNoIn', 'QUESTION_MARK', 'AssignmentExpression', 'COLON', 'AssignmentExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('QUESTION_MARK', 119, $value, 1, 'ConditionalExpressionNoIn', 'LogicalORExpressionNoIn', 'QUESTION_MARK', 'AssignmentExpression', 'COLON', 'AssignmentExpressionNoIn');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('COLON', 119, $value, 3, 'ConditionalExpressionNoIn', 'LogicalORExpressionNoIn', 'QUESTION_MARK', 'AssignmentExpression', 'COLON', 'AssignmentExpressionNoIn');
        }
        elsif ($index == 4) {
        }
    }

    return $rc;
}



sub G1_120 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 120, $value, $index, 'AssignmentExpression', 'ConditionalExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_121 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 121, $value, $index, 'AssignmentExpression', 'LeftHandSideExpression', 'ASSIGN', 'AssignmentExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('ASSIGN', 121, $value, 1, 'AssignmentExpression', 'LeftHandSideExpression', 'ASSIGN', 'AssignmentExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_122 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 122, $value, $index, 'AssignmentExpression', 'LeftHandSideExpression', 'AssignmentOperator', 'AssignmentExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_123 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 123, $value, $index, 'AssignmentExpressionNoIn', 'ConditionalExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_124 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 124, $value, $index, 'AssignmentExpressionNoIn', 'LeftHandSideExpression', 'ASSIGN', 'AssignmentExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('ASSIGN', 124, $value, 1, 'AssignmentExpressionNoIn', 'LeftHandSideExpression', 'ASSIGN', 'AssignmentExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_125 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 125, $value, $index, 'AssignmentExpressionNoIn', 'LeftHandSideExpression', 'AssignmentOperator', 'AssignmentExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_126 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 126, $value, $index, 'AssignmentOperator', 'MULASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('MULASSIGN', 126, $value, 0, 'AssignmentOperator', 'MULASSIGN');
        }
    }

    return $rc;
}



sub G1_127 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 127, $value, $index, 'AssignmentOperator', 'DIVASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('DIVASSIGN', 127, $value, 0, 'AssignmentOperator', 'DIVASSIGN');
        }
    }

    return $rc;
}



sub G1_128 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 128, $value, $index, 'AssignmentOperator', 'MODULUSASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('MODULUSASSIGN', 128, $value, 0, 'AssignmentOperator', 'MODULUSASSIGN');
        }
    }

    return $rc;
}



sub G1_129 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 129, $value, $index, 'AssignmentOperator', 'PLUSASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('PLUSASSIGN', 129, $value, 0, 'AssignmentOperator', 'PLUSASSIGN');
        }
    }

    return $rc;
}



sub G1_130 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 130, $value, $index, 'AssignmentOperator', 'MINUSASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('MINUSASSIGN', 130, $value, 0, 'AssignmentOperator', 'MINUSASSIGN');
        }
    }

    return $rc;
}



sub G1_131 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 131, $value, $index, 'AssignmentOperator', 'LEFTMOVEASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('LEFTMOVEASSIGN', 131, $value, 0, 'AssignmentOperator', 'LEFTMOVEASSIGN');
        }
    }

    return $rc;
}



sub G1_132 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 132, $value, $index, 'AssignmentOperator', 'RIGHTMOVEASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('RIGHTMOVEASSIGN', 132, $value, 0, 'AssignmentOperator', 'RIGHTMOVEASSIGN');
        }
    }

    return $rc;
}



sub G1_133 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 133, $value, $index, 'AssignmentOperator', 'RIGHTMOVEFILLASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('RIGHTMOVEFILLASSIGN', 133, $value, 0, 'AssignmentOperator', 'RIGHTMOVEFILLASSIGN');
        }
    }

    return $rc;
}



sub G1_134 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 134, $value, $index, 'AssignmentOperator', 'BITANDASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('BITANDASSIGN', 134, $value, 0, 'AssignmentOperator', 'BITANDASSIGN');
        }
    }

    return $rc;
}



sub G1_135 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 135, $value, $index, 'AssignmentOperator', 'BITXORASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('BITXORASSIGN', 135, $value, 0, 'AssignmentOperator', 'BITXORASSIGN');
        }
    }

    return $rc;
}



sub G1_136 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 136, $value, $index, 'AssignmentOperator', 'BITORASSIGN')) {
        if ($index == 0) {
            $rc = $self->lexeme('BITORASSIGN', 136, $value, 0, 'AssignmentOperator', 'BITORASSIGN');
        }
    }

    return $rc;
}



sub G1_137 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 137, $value, $index, 'Expression', 'AssignmentExpression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_138 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 138, $value, $index, 'Expression', 'Expression', 'COMMA', 'AssignmentExpression')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COMMA', 138, $value, 1, 'Expression', 'Expression', 'COMMA', 'AssignmentExpression');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_139 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 139, $value, $index, 'ExpressionNoIn', 'AssignmentExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_140 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 140, $value, $index, 'ExpressionNoIn', 'ExpressionNoIn', 'COMMA', 'AssignmentExpressionNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COMMA', 140, $value, 1, 'ExpressionNoIn', 'ExpressionNoIn', 'COMMA', 'AssignmentExpressionNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_141 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 141, $value, $index, 'Statement', 'Block')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_142 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 142, $value, $index, 'Statement', 'VariableStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_143 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 143, $value, $index, 'Statement', 'EmptyStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_144 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 144, $value, $index, 'Statement', 'ExpressionStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_145 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 145, $value, $index, 'Statement', 'IfStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_146 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 146, $value, $index, 'Statement', 'IterationStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_147 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 147, $value, $index, 'Statement', 'ContinueStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_148 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 148, $value, $index, 'Statement', 'BreakStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_149 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 149, $value, $index, 'Statement', 'ReturnStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_150 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 150, $value, $index, 'Statement', 'WithStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_151 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 151, $value, $index, 'Statement', 'LabelledStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_152 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 152, $value, $index, 'Statement', 'SwitchStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_153 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 153, $value, $index, 'Statement', 'ThrowStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_154 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 154, $value, $index, 'Statement', 'TryStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_155 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 155, $value, $index, 'Statement', 'DebuggerStatement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_156 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 156, $value, $index, 'Block', 'LCURLY_BLOCK', 'StatementListopt', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('LCURLY_BLOCK', 156, $value, 0, 'Block', 'LCURLY_BLOCK', 'StatementListopt', 'RCURLY');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('RCURLY', 156, $value, 2, 'Block', 'LCURLY_BLOCK', 'StatementListopt', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_157 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 157, $value, $index, 'StatementList', 'Statement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_158 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 158, $value, $index, 'StatementList', 'StatementList', 'Statement')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_159 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 159, $value, $index, 'VariableStatement', 'VAR', 'VariableDeclarationList', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('VAR', 159, $value, 0, 'VariableStatement', 'VAR', 'VariableDeclarationList', 'SEMICOLON');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('SEMICOLON', 159, $value, 2, 'VariableStatement', 'VAR', 'VariableDeclarationList', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_160 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 160, $value, $index, 'VariableDeclarationList', 'VariableDeclaration')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_161 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 161, $value, $index, 'VariableDeclarationList', 'VariableDeclarationList', 'COMMA', 'VariableDeclaration')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COMMA', 161, $value, 1, 'VariableDeclarationList', 'VariableDeclarationList', 'COMMA', 'VariableDeclaration');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_162 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 162, $value, $index, 'VariableDeclarationListNoIn', 'VariableDeclarationNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_163 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 163, $value, $index, 'VariableDeclarationListNoIn', 'VariableDeclarationListNoIn', 'COMMA', 'VariableDeclarationNoIn')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COMMA', 163, $value, 1, 'VariableDeclarationListNoIn', 'VariableDeclarationListNoIn', 'COMMA', 'VariableDeclarationNoIn');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_164 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 164, $value, $index, 'VariableDeclaration', 'IDENTIFIER', 'Initialiseropt')) {
        if ($index == 0) {
            $rc = $self->lexeme('IDENTIFIER', 164, $value, 0, 'VariableDeclaration', 'IDENTIFIER', 'Initialiseropt');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_165 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 165, $value, $index, 'VariableDeclarationNoIn', 'IDENTIFIER', 'InitialiserNoInopt')) {
        if ($index == 0) {
            $rc = $self->lexeme('IDENTIFIER', 165, $value, 0, 'VariableDeclarationNoIn', 'IDENTIFIER', 'InitialiserNoInopt');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_166 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 166, $value, $index, 'Initialiseropt', 'Initialiser')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_167 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 167, $value, $index, 'Initialiseropt', )) {
    }

    return $rc;
}



sub G1_168 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 168, $value, $index, 'Initialiser', 'ASSIGN', 'AssignmentExpression')) {
        if ($index == 0) {
            $rc = $self->lexeme('ASSIGN', 168, $value, 0, 'Initialiser', 'ASSIGN', 'AssignmentExpression');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_169 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 169, $value, $index, 'InitialiserNoInopt', 'InitialiserNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_170 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 170, $value, $index, 'InitialiserNoInopt', )) {
    }

    return $rc;
}



sub G1_171 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 171, $value, $index, 'InitialiserNoIn', 'ASSIGN', 'AssignmentExpressionNoIn')) {
        if ($index == 0) {
            $rc = $self->lexeme('ASSIGN', 171, $value, 0, 'InitialiserNoIn', 'ASSIGN', 'AssignmentExpressionNoIn');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_172 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 172, $value, $index, 'EmptyStatement', 'VISIBLE_SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('VISIBLE_SEMICOLON', 172, $value, 0, 'EmptyStatement', 'VISIBLE_SEMICOLON');
        }
    }

    return $rc;
}



sub G1_173 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 173, $value, $index, 'ExpressionStatement', 'Expression', 'SEMICOLON')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('SEMICOLON', 173, $value, 1, 'ExpressionStatement', 'Expression', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_174 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 174, $value, $index, 'IfStatement', 'IF', 'LPAREN', 'Expression', 'RPAREN', 'Statement', 'ELSE', 'Statement')) {
        if ($index == 0) {
            $rc = $self->lexeme('IF', 174, $value, 0, 'IfStatement', 'IF', 'LPAREN', 'Expression', 'RPAREN', 'Statement', 'ELSE', 'Statement');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 174, $value, 1, 'IfStatement', 'IF', 'LPAREN', 'Expression', 'RPAREN', 'Statement', 'ELSE', 'Statement');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RPAREN', 174, $value, 3, 'IfStatement', 'IF', 'LPAREN', 'Expression', 'RPAREN', 'Statement', 'ELSE', 'Statement');
        }
        elsif ($index == 4) {
        }
        elsif ($index == 5) {
            $rc = $self->lexeme('ELSE', 174, $value, 5, 'IfStatement', 'IF', 'LPAREN', 'Expression', 'RPAREN', 'Statement', 'ELSE', 'Statement');
        }
        elsif ($index == 6) {
        }
    }

    return $rc;
}



sub G1_175 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 175, $value, $index, 'IfStatement', 'IF', 'LPAREN', 'Expression', 'RPAREN', 'Statement')) {
        if ($index == 0) {
            $rc = $self->lexeme('IF', 175, $value, 0, 'IfStatement', 'IF', 'LPAREN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 175, $value, 1, 'IfStatement', 'IF', 'LPAREN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RPAREN', 175, $value, 3, 'IfStatement', 'IF', 'LPAREN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 4) {
        }
    }

    return $rc;
}



sub G1_176 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 176, $value, $index, 'ExpressionNoInopt', 'ExpressionNoIn')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_177 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 177, $value, $index, 'ExpressionNoInopt', )) {
    }

    return $rc;
}



sub G1_178 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 178, $value, $index, 'Expressionopt', 'Expression')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_179 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 179, $value, $index, 'Expressionopt', )) {
    }

    return $rc;
}



sub G1_180 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 180, $value, $index, 'IterationStatement', 'DO', 'Statement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('DO', 180, $value, 0, 'IterationStatement', 'DO', 'Statement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'SEMICOLON');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('WHILE', 180, $value, 2, 'IterationStatement', 'DO', 'Statement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'SEMICOLON');
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('LPAREN', 180, $value, 3, 'IterationStatement', 'DO', 'Statement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'SEMICOLON');
        }
        elsif ($index == 4) {
        }
        elsif ($index == 5) {
            $rc = $self->lexeme('RPAREN', 180, $value, 5, 'IterationStatement', 'DO', 'Statement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'SEMICOLON');
        }
        elsif ($index == 6) {
            $rc = $self->lexeme('SEMICOLON', 180, $value, 6, 'IterationStatement', 'DO', 'Statement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_181 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 181, $value, $index, 'IterationStatement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'Statement')) {
        if ($index == 0) {
            $rc = $self->lexeme('WHILE', 181, $value, 0, 'IterationStatement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 181, $value, 1, 'IterationStatement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RPAREN', 181, $value, 3, 'IterationStatement', 'WHILE', 'LPAREN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 4) {
        }
    }

    return $rc;
}



sub G1_182 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 182, $value, $index, 'IterationStatement', 'FOR', 'LPAREN', 'ExpressionNoInopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement')) {
        if ($index == 0) {
            $rc = $self->lexeme('FOR', 182, $value, 0, 'IterationStatement', 'FOR', 'LPAREN', 'ExpressionNoInopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 182, $value, 1, 'IterationStatement', 'FOR', 'LPAREN', 'ExpressionNoInopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('VISIBLE_SEMICOLON', 182, $value, 3, 'IterationStatement', 'FOR', 'LPAREN', 'ExpressionNoInopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 4) {
        }
        elsif ($index == 5) {
            $rc = $self->lexeme('VISIBLE_SEMICOLON', 182, $value, 5, 'IterationStatement', 'FOR', 'LPAREN', 'ExpressionNoInopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 6) {
        }
        elsif ($index == 7) {
            $rc = $self->lexeme('RPAREN', 182, $value, 7, 'IterationStatement', 'FOR', 'LPAREN', 'ExpressionNoInopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 8) {
        }
    }

    return $rc;
}



sub G1_183 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 183, $value, $index, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationListNoIn', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement')) {
        if ($index == 0) {
            $rc = $self->lexeme('FOR', 183, $value, 0, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationListNoIn', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 183, $value, 1, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationListNoIn', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('VAR', 183, $value, 2, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationListNoIn', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 3) {
        }
        elsif ($index == 4) {
            $rc = $self->lexeme('VISIBLE_SEMICOLON', 183, $value, 4, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationListNoIn', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 5) {
        }
        elsif ($index == 6) {
            $rc = $self->lexeme('VISIBLE_SEMICOLON', 183, $value, 6, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationListNoIn', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 7) {
        }
        elsif ($index == 8) {
            $rc = $self->lexeme('RPAREN', 183, $value, 8, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationListNoIn', 'VISIBLE_SEMICOLON', 'Expressionopt', 'VISIBLE_SEMICOLON', 'Expressionopt', 'RPAREN', 'Statement');
        }
        elsif ($index == 9) {
        }
    }

    return $rc;
}



sub G1_184 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 184, $value, $index, 'IterationStatement', 'FOR', 'LPAREN', 'LeftHandSideExpression', 'IN', 'Expression', 'RPAREN', 'Statement')) {
        if ($index == 0) {
            $rc = $self->lexeme('FOR', 184, $value, 0, 'IterationStatement', 'FOR', 'LPAREN', 'LeftHandSideExpression', 'IN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 184, $value, 1, 'IterationStatement', 'FOR', 'LPAREN', 'LeftHandSideExpression', 'IN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('IN', 184, $value, 3, 'IterationStatement', 'FOR', 'LPAREN', 'LeftHandSideExpression', 'IN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 4) {
        }
        elsif ($index == 5) {
            $rc = $self->lexeme('RPAREN', 184, $value, 5, 'IterationStatement', 'FOR', 'LPAREN', 'LeftHandSideExpression', 'IN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 6) {
        }
    }

    return $rc;
}



sub G1_185 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 185, $value, $index, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationNoIn', 'IN', 'Expression', 'RPAREN', 'Statement')) {
        if ($index == 0) {
            $rc = $self->lexeme('FOR', 185, $value, 0, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationNoIn', 'IN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 185, $value, 1, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationNoIn', 'IN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('VAR', 185, $value, 2, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationNoIn', 'IN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 3) {
        }
        elsif ($index == 4) {
            $rc = $self->lexeme('IN', 185, $value, 4, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationNoIn', 'IN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 5) {
        }
        elsif ($index == 6) {
            $rc = $self->lexeme('RPAREN', 185, $value, 6, 'IterationStatement', 'FOR', 'LPAREN', 'VAR', 'VariableDeclarationNoIn', 'IN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 7) {
        }
    }

    return $rc;
}



sub G1_186 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 186, $value, $index, 'ContinueStatement', 'CONTINUE', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('CONTINUE', 186, $value, 0, 'ContinueStatement', 'CONTINUE', 'SEMICOLON');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('SEMICOLON', 186, $value, 1, 'ContinueStatement', 'CONTINUE', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_187 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 187, $value, $index, 'ContinueStatement', 'CONTINUE', 'INVISIBLE_SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('CONTINUE', 187, $value, 0, 'ContinueStatement', 'CONTINUE', 'INVISIBLE_SEMICOLON');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('INVISIBLE_SEMICOLON', 187, $value, 1, 'ContinueStatement', 'CONTINUE', 'INVISIBLE_SEMICOLON');
        }
    }

    return $rc;
}



sub G1_188 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 188, $value, $index, 'ContinueStatement', 'CONTINUE', 'IDENTIFIER', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('CONTINUE', 188, $value, 0, 'ContinueStatement', 'CONTINUE', 'IDENTIFIER', 'SEMICOLON');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('IDENTIFIER', 188, $value, 1, 'ContinueStatement', 'CONTINUE', 'IDENTIFIER', 'SEMICOLON');
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('SEMICOLON', 188, $value, 2, 'ContinueStatement', 'CONTINUE', 'IDENTIFIER', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_189 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 189, $value, $index, 'BreakStatement', 'BREAK', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('BREAK', 189, $value, 0, 'BreakStatement', 'BREAK', 'SEMICOLON');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('SEMICOLON', 189, $value, 1, 'BreakStatement', 'BREAK', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_190 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 190, $value, $index, 'BreakStatement', 'BREAK', 'INVISIBLE_SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('BREAK', 190, $value, 0, 'BreakStatement', 'BREAK', 'INVISIBLE_SEMICOLON');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('INVISIBLE_SEMICOLON', 190, $value, 1, 'BreakStatement', 'BREAK', 'INVISIBLE_SEMICOLON');
        }
    }

    return $rc;
}



sub G1_191 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 191, $value, $index, 'BreakStatement', 'BREAK', 'IDENTIFIER', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('BREAK', 191, $value, 0, 'BreakStatement', 'BREAK', 'IDENTIFIER', 'SEMICOLON');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('IDENTIFIER', 191, $value, 1, 'BreakStatement', 'BREAK', 'IDENTIFIER', 'SEMICOLON');
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('SEMICOLON', 191, $value, 2, 'BreakStatement', 'BREAK', 'IDENTIFIER', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_192 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 192, $value, $index, 'ReturnStatement', 'RETURN', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('RETURN', 192, $value, 0, 'ReturnStatement', 'RETURN', 'SEMICOLON');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('SEMICOLON', 192, $value, 1, 'ReturnStatement', 'RETURN', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_193 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 193, $value, $index, 'ReturnStatement', 'RETURN', 'INVISIBLE_SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('RETURN', 193, $value, 0, 'ReturnStatement', 'RETURN', 'INVISIBLE_SEMICOLON');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('INVISIBLE_SEMICOLON', 193, $value, 1, 'ReturnStatement', 'RETURN', 'INVISIBLE_SEMICOLON');
        }
    }

    return $rc;
}



sub G1_194 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 194, $value, $index, 'ReturnStatement', 'RETURN', 'Expression', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('RETURN', 194, $value, 0, 'ReturnStatement', 'RETURN', 'Expression', 'SEMICOLON');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('SEMICOLON', 194, $value, 2, 'ReturnStatement', 'RETURN', 'Expression', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_195 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 195, $value, $index, 'WithStatement', 'WITH', 'LPAREN', 'Expression', 'RPAREN', 'Statement')) {
        if ($index == 0) {
            $rc = $self->lexeme('WITH', 195, $value, 0, 'WithStatement', 'WITH', 'LPAREN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 195, $value, 1, 'WithStatement', 'WITH', 'LPAREN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RPAREN', 195, $value, 3, 'WithStatement', 'WITH', 'LPAREN', 'Expression', 'RPAREN', 'Statement');
        }
        elsif ($index == 4) {
        }
    }

    return $rc;
}



sub G1_196 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 196, $value, $index, 'SwitchStatement', 'SWITCH', 'LPAREN', 'Expression', 'RPAREN', 'CaseBlock')) {
        if ($index == 0) {
            $rc = $self->lexeme('SWITCH', 196, $value, 0, 'SwitchStatement', 'SWITCH', 'LPAREN', 'Expression', 'RPAREN', 'CaseBlock');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 196, $value, 1, 'SwitchStatement', 'SWITCH', 'LPAREN', 'Expression', 'RPAREN', 'CaseBlock');
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RPAREN', 196, $value, 3, 'SwitchStatement', 'SWITCH', 'LPAREN', 'Expression', 'RPAREN', 'CaseBlock');
        }
        elsif ($index == 4) {
        }
    }

    return $rc;
}



sub G1_197 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 197, $value, $index, 'CaseBlock', 'LCURLY', 'CaseClausesopt', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('LCURLY', 197, $value, 0, 'CaseBlock', 'LCURLY', 'CaseClausesopt', 'RCURLY');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('RCURLY', 197, $value, 2, 'CaseBlock', 'LCURLY', 'CaseClausesopt', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_198 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 198, $value, $index, 'CaseBlock', 'LCURLY', 'CaseClausesopt', 'DefaultClause', 'CaseClausesopt', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('LCURLY', 198, $value, 0, 'CaseBlock', 'LCURLY', 'CaseClausesopt', 'DefaultClause', 'CaseClausesopt', 'RCURLY');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
        }
        elsif ($index == 4) {
            $rc = $self->lexeme('RCURLY', 198, $value, 4, 'CaseBlock', 'LCURLY', 'CaseClausesopt', 'DefaultClause', 'CaseClausesopt', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_199 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 199, $value, $index, 'CaseClausesopt', 'CaseClauses')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_200 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 200, $value, $index, 'CaseClausesopt', )) {
    }

    return $rc;
}



sub G1_201 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 201, $value, $index, 'CaseClauses', 'CaseClause')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_202 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 202, $value, $index, 'CaseClauses', 'CaseClauses', 'CaseClause')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_203 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 203, $value, $index, 'CaseClause', 'CASE', 'Expression', 'COLON', 'StatementListopt')) {
        if ($index == 0) {
            $rc = $self->lexeme('CASE', 203, $value, 0, 'CaseClause', 'CASE', 'Expression', 'COLON', 'StatementListopt');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('COLON', 203, $value, 2, 'CaseClause', 'CASE', 'Expression', 'COLON', 'StatementListopt');
        }
        elsif ($index == 3) {
        }
    }

    return $rc;
}



sub G1_204 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 204, $value, $index, 'StatementListopt', 'StatementList')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_205 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 205, $value, $index, 'StatementListopt', )) {
    }

    return $rc;
}



sub G1_206 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 206, $value, $index, 'DefaultClause', 'DEFAULT', 'COLON', 'StatementListopt')) {
        if ($index == 0) {
            $rc = $self->lexeme('DEFAULT', 206, $value, 0, 'DefaultClause', 'DEFAULT', 'COLON', 'StatementListopt');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COLON', 206, $value, 1, 'DefaultClause', 'DEFAULT', 'COLON', 'StatementListopt');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_207 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 207, $value, $index, 'LabelledStatement', 'IDENTIFIER', 'COLON', 'Statement')) {
        if ($index == 0) {
            $rc = $self->lexeme('IDENTIFIER', 207, $value, 0, 'LabelledStatement', 'IDENTIFIER', 'COLON', 'Statement');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COLON', 207, $value, 1, 'LabelledStatement', 'IDENTIFIER', 'COLON', 'Statement');
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_208 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 208, $value, $index, 'ThrowStatement', 'THROW', 'Expression', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('THROW', 208, $value, 0, 'ThrowStatement', 'THROW', 'Expression', 'SEMICOLON');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('SEMICOLON', 208, $value, 2, 'ThrowStatement', 'THROW', 'Expression', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_209 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 209, $value, $index, 'TryStatement', 'TRY', 'Block', 'Catch')) {
        if ($index == 0) {
            $rc = $self->lexeme('TRY', 209, $value, 0, 'TryStatement', 'TRY', 'Block', 'Catch');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_210 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 210, $value, $index, 'TryStatement', 'TRY', 'Block', 'Finally')) {
        if ($index == 0) {
            $rc = $self->lexeme('TRY', 210, $value, 0, 'TryStatement', 'TRY', 'Block', 'Finally');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
        }
    }

    return $rc;
}



sub G1_211 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 211, $value, $index, 'TryStatement', 'TRY', 'Block', 'Catch', 'Finally')) {
        if ($index == 0) {
            $rc = $self->lexeme('TRY', 211, $value, 0, 'TryStatement', 'TRY', 'Block', 'Catch', 'Finally');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
        }
        elsif ($index == 3) {
        }
    }

    return $rc;
}



sub G1_212 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 212, $value, $index, 'Catch', 'CATCH', 'LPAREN', 'IDENTIFIER', 'RPAREN', 'Block')) {
        if ($index == 0) {
            $rc = $self->lexeme('CATCH', 212, $value, 0, 'Catch', 'CATCH', 'LPAREN', 'IDENTIFIER', 'RPAREN', 'Block');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('LPAREN', 212, $value, 1, 'Catch', 'CATCH', 'LPAREN', 'IDENTIFIER', 'RPAREN', 'Block');
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('IDENTIFIER', 212, $value, 2, 'Catch', 'CATCH', 'LPAREN', 'IDENTIFIER', 'RPAREN', 'Block');
        }
        elsif ($index == 3) {
            $rc = $self->lexeme('RPAREN', 212, $value, 3, 'Catch', 'CATCH', 'LPAREN', 'IDENTIFIER', 'RPAREN', 'Block');
        }
        elsif ($index == 4) {
        }
    }

    return $rc;
}



sub G1_213 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 213, $value, $index, 'Finally', 'FINALLY', 'Block')) {
        if ($index == 0) {
            $rc = $self->lexeme('FINALLY', 213, $value, 0, 'Finally', 'FINALLY', 'Block');
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_214 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 214, $value, $index, 'DebuggerStatement', 'DEBUGGER', 'SEMICOLON')) {
        if ($index == 0) {
            $rc = $self->lexeme('DEBUGGER', 214, $value, 0, 'DebuggerStatement', 'DEBUGGER', 'SEMICOLON');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('SEMICOLON', 214, $value, 1, 'DebuggerStatement', 'DEBUGGER', 'SEMICOLON');
        }
    }

    return $rc;
}



sub G1_215 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 215, $value, $index, 'FunctionDeclaration', 'FUNCTION', 'IDENTIFIER', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('FUNCTION', 215, $value, 0, 'FunctionDeclaration', 'FUNCTION', 'IDENTIFIER', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('IDENTIFIER', 215, $value, 1, 'FunctionDeclaration', 'FUNCTION', 'IDENTIFIER', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('LPAREN', 215, $value, 2, 'FunctionDeclaration', 'FUNCTION', 'IDENTIFIER', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 3) {
        }
        elsif ($index == 4) {
            $rc = $self->lexeme('RPAREN', 215, $value, 4, 'FunctionDeclaration', 'FUNCTION', 'IDENTIFIER', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 5) {
            $rc = $self->lexeme('LCURLY', 215, $value, 5, 'FunctionDeclaration', 'FUNCTION', 'IDENTIFIER', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 6) {
        }
        elsif ($index == 7) {
            $rc = $self->lexeme('RCURLY', 215, $value, 7, 'FunctionDeclaration', 'FUNCTION', 'IDENTIFIER', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_216 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 216, $value, $index, 'Identifieropt', 'IDENTIFIER')) {
        if ($index == 0) {
            $rc = $self->lexeme('IDENTIFIER', 216, $value, 0, 'Identifieropt', 'IDENTIFIER');
        }
    }

    return $rc;
}



sub G1_217 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 217, $value, $index, 'Identifieropt', )) {
    }

    return $rc;
}



sub G1_218 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 218, $value, $index, 'FunctionExpression', 'FUNCTION', 'Identifieropt', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY')) {
        if ($index == 0) {
            $rc = $self->lexeme('FUNCTION', 218, $value, 0, 'FunctionExpression', 'FUNCTION', 'Identifieropt', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 1) {
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('LPAREN', 218, $value, 2, 'FunctionExpression', 'FUNCTION', 'Identifieropt', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 3) {
        }
        elsif ($index == 4) {
            $rc = $self->lexeme('RPAREN', 218, $value, 4, 'FunctionExpression', 'FUNCTION', 'Identifieropt', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 5) {
            $rc = $self->lexeme('LCURLY', 218, $value, 5, 'FunctionExpression', 'FUNCTION', 'Identifieropt', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
        elsif ($index == 6) {
        }
        elsif ($index == 7) {
            $rc = $self->lexeme('RCURLY', 218, $value, 7, 'FunctionExpression', 'FUNCTION', 'Identifieropt', 'LPAREN', 'FormalParameterListopt', 'RPAREN', 'LCURLY', 'FunctionBody', 'RCURLY');
        }
    }

    return $rc;
}



sub G1_219 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 219, $value, $index, 'FormalParameterListopt', 'FormalParameterList')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_220 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 220, $value, $index, 'FormalParameterListopt', )) {
    }

    return $rc;
}



sub G1_221 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 221, $value, $index, 'FormalParameterList', 'IDENTIFIER')) {
        if ($index == 0) {
            $rc = $self->lexeme('IDENTIFIER', 221, $value, 0, 'FormalParameterList', 'IDENTIFIER');
        }
    }

    return $rc;
}



sub G1_222 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 222, $value, $index, 'FormalParameterList', 'FormalParameterList', 'COMMA', 'IDENTIFIER')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
            $rc = $self->lexeme('COMMA', 222, $value, 1, 'FormalParameterList', 'FormalParameterList', 'COMMA', 'IDENTIFIER');
        }
        elsif ($index == 2) {
            $rc = $self->lexeme('IDENTIFIER', 222, $value, 2, 'FormalParameterList', 'FormalParameterList', 'COMMA', 'IDENTIFIER');
        }
    }

    return $rc;
}



sub G1_223 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 223, $value, $index, 'SourceElementsopt', 'SourceElements')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_224 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 224, $value, $index, 'SourceElementsopt', )) {
    }

    return $rc;
}



sub G1_225 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 225, $value, $index, 'FunctionBody', 'SourceElementsopt')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_226 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 226, $value, $index, 'Program', 'SourceElementsopt')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_227 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 227, $value, $index, 'SourceElements', 'SourceElement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_228 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 228, $value, $index, 'SourceElements', 'SourceElements', 'SourceElement')) {
        if ($index == 0) {
        }
        elsif ($index == 1) {
        }
    }

    return $rc;
}



sub G1_229 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 229, $value, $index, 'SourceElement', 'Statement')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_230 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 230, $value, $index, 'SourceElement', 'FunctionDeclaration')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_231 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 231, $value, $index, 'NullLiteral', 'NULL')) {
        if ($index == 0) {
            $rc = $self->lexeme('NULL', 231, $value, 0, 'NullLiteral', 'NULL');
        }
    }

    return $rc;
}



sub G1_232 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 232, $value, $index, 'BooleanLiteral', 'TRUE')) {
        if ($index == 0) {
            $rc = $self->lexeme('TRUE', 232, $value, 0, 'BooleanLiteral', 'TRUE');
        }
    }

    return $rc;
}



sub G1_233 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 233, $value, $index, 'BooleanLiteral', 'FALSE')) {
        if ($index == 0) {
            $rc = $self->lexeme('FALSE', 233, $value, 0, 'BooleanLiteral', 'FALSE');
        }
    }

    return $rc;
}



sub G1_234 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 234, $value, $index, 'StringLiteral', 'STRINGLITERAL')) {
        if ($index == 0) {
            $rc = $self->lexeme('STRINGLITERAL', 234, $value, 0, 'StringLiteral', 'STRINGLITERAL');
        }
    }

    return $rc;
}



sub G1_235 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 235, $value, $index, 'RegularExpressionLiteral', 'REGULAREXPRESSIONLITERAL')) {
        if ($index == 0) {
            $rc = $self->lexeme('REGULAREXPRESSIONLITERAL', 235, $value, 0, 'RegularExpressionLiteral', 'REGULAREXPRESSIONLITERAL');
        }
    }

    return $rc;
}



sub G1_236 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 236, $value, $index, 'NumericLiteral', 'DecimalLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_237 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 237, $value, $index, 'NumericLiteral', 'HexIntegerLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_238 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 238, $value, $index, 'NumericLiteral', 'OctalIntegerLiteral')) {
        if ($index == 0) {
        }
    }

    return $rc;
}



sub G1_239 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 239, $value, $index, 'DecimalLiteral', 'DECIMALLITERAL')) {
        if ($index == 0) {
            $rc = $self->lexeme('DECIMALLITERAL', 239, $value, 0, 'DecimalLiteral', 'DECIMALLITERAL');
        }
    }

    return $rc;
}



sub G1_240 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 240, $value, $index, 'HexIntegerLiteral', 'HEXINTEGERLITERAL')) {
        if ($index == 0) {
            $rc = $self->lexeme('HEXINTEGERLITERAL', 240, $value, 0, 'HexIntegerLiteral', 'HEXINTEGERLITERAL');
        }
    }

    return $rc;
}



sub G1_241 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 241, $value, $index, 'OctalIntegerLiteral', 'OCTALINTEGERLITERAL')) {
        if ($index == 0) {
            $rc = $self->lexeme('OCTALINTEGERLITERAL', 241, $value, 0, 'OctalIntegerLiteral', 'OCTALINTEGERLITERAL');
        }
    }

    return $rc;
}



sub G1_242 {
    my ($self, $value, $index) = @_;

    my $rc = '';

    if (&{$self->{_g1Callback}}(@{$self->{_g1CallbackArgs}}, \$rc, 242, $value, $index, '[:start]', 'Program')) {
        if ($index == 0) {
        }
    }

    return $rc;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Template - Template for ECMAScript_262_5 transpilation using an AST

=head1 VERSION

version 0.020

=head1 DESCRIPTION

Generated generic template.

=head1 SUBROUTINES/METHODS

=head2 new($class, $optionsp)

Instantiate a new object. Takes as optional argument a reference to a hash that may contain the following key/values:

=over

=item g1Callback

G1 callback (CODE ref).

=item g1CallbackArgs

G1 callback arguments (ARRAY ref). The g1 callback is called like: &$g1Callback(@{$g1CallbackArgs}, \$rc, $ruleId, $value, $index, $lhs, @rhs), where $value is the AST parse tree value of RHS No $index of this G1 rule number $ruleId, whose full definition is $lhs ::= @rhs. If the callback is defined, this will always be executed first, and it must return a true value putting its eventual result in $rc. Only when it returns true, lexemes are processed.

=item lexemeCallback

lexeme callback (CODE ref).

=item lexemeCallbackArgs

Lexeme callback arguments (ARRAY ref). The lexeme callback is called like: &$lexemeCallback(@{$lexemeCallbackArgs}, \$rc, $name, $ruleId, $value, $index, $lhs, @rhs), where $value is the AST parse tree value of RHS No $index of this G1 rule number $ruleId, whose full definition is $lhs ::= @rhs. The RHS being a lexeme, $name contains the lexeme's name. If the callback is defined, this will always be executed first, and it must return a true value putting its result in $rc, otherwise default behaviour applies: return the lexeme value as-is.

=back

=head2 lexeme($self, $value)

Returns the characters of lexeme inside $value, that is an array reference. C.f. grammar default lexeme action.

=head2 indent($self, $inc)

Returns indentation, i.e. two spaces times current number of indentations. Optional $inc is used to change the number of indentations.

=head2 transpile($self, $ast)

Tranpiles the $ast AST, that is the parse tree value from Marpa.

=head2 G1_0($self, $value, $index)

Transpilation of G1 rule No 0, i.e. Literal ::= NullLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_1($self, $value, $index)

Transpilation of G1 rule No 1, i.e. Literal ::= BooleanLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_2($self, $value, $index)

Transpilation of G1 rule No 2, i.e. Literal ::= NumericLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_3($self, $value, $index)

Transpilation of G1 rule No 3, i.e. Literal ::= StringLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_4($self, $value, $index)

Transpilation of G1 rule No 4, i.e. Literal ::= RegularExpressionLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_5($self, $value, $index)

Transpilation of G1 rule No 5, i.e. PrimaryExpression ::= THIS

$value is the value of RHS No $index (starting at 0).

=head2 G1_6($self, $value, $index)

Transpilation of G1 rule No 6, i.e. PrimaryExpression ::= IDENTIFIER

$value is the value of RHS No $index (starting at 0).

=head2 G1_7($self, $value, $index)

Transpilation of G1 rule No 7, i.e. PrimaryExpression ::= Literal

$value is the value of RHS No $index (starting at 0).

=head2 G1_8($self, $value, $index)

Transpilation of G1 rule No 8, i.e. PrimaryExpression ::= ArrayLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_9($self, $value, $index)

Transpilation of G1 rule No 9, i.e. PrimaryExpression ::= ObjectLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_10($self, $value, $index)

Transpilation of G1 rule No 10, i.e. PrimaryExpression ::= LPAREN Expression RPAREN

$value is the value of RHS No $index (starting at 0).

=head2 G1_11($self, $value, $index)

Transpilation of G1 rule No 11, i.e. ArrayLiteral ::= LBRACKET Elisionopt RBRACKET

$value is the value of RHS No $index (starting at 0).

=head2 G1_12($self, $value, $index)

Transpilation of G1 rule No 12, i.e. ArrayLiteral ::= LBRACKET ElementList RBRACKET

$value is the value of RHS No $index (starting at 0).

=head2 G1_13($self, $value, $index)

Transpilation of G1 rule No 13, i.e. ArrayLiteral ::= LBRACKET ElementList COMMA Elisionopt RBRACKET

$value is the value of RHS No $index (starting at 0).

=head2 G1_14($self, $value, $index)

Transpilation of G1 rule No 14, i.e. ElementList ::= Elisionopt AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_15($self, $value, $index)

Transpilation of G1 rule No 15, i.e. ElementList ::= ElementList COMMA Elisionopt AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_16($self, $value, $index)

Transpilation of G1 rule No 16, i.e. Elision ::= COMMA

$value is the value of RHS No $index (starting at 0).

=head2 G1_17($self, $value, $index)

Transpilation of G1 rule No 17, i.e. Elision ::= Elision COMMA

$value is the value of RHS No $index (starting at 0).

=head2 G1_18($self, $value, $index)

Transpilation of G1 rule No 18, i.e. Elisionopt ::= Elision

$value is the value of RHS No $index (starting at 0).

=head2 G1_19($self, $value, $index)

Transpilation of G1 rule No 19, i.e. Elisionopt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_20($self, $value, $index)

Transpilation of G1 rule No 20, i.e. ObjectLiteral ::= LCURLY RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_21($self, $value, $index)

Transpilation of G1 rule No 21, i.e. ObjectLiteral ::= LCURLY PropertyNameAndValueList RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_22($self, $value, $index)

Transpilation of G1 rule No 22, i.e. ObjectLiteral ::= LCURLY PropertyNameAndValueList COMMA RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_23($self, $value, $index)

Transpilation of G1 rule No 23, i.e. PropertyNameAndValueList ::= PropertyAssignment

$value is the value of RHS No $index (starting at 0).

=head2 G1_24($self, $value, $index)

Transpilation of G1 rule No 24, i.e. PropertyNameAndValueList ::= PropertyNameAndValueList COMMA PropertyAssignment

$value is the value of RHS No $index (starting at 0).

=head2 G1_25($self, $value, $index)

Transpilation of G1 rule No 25, i.e. PropertyAssignment ::= PropertyName COLON AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_26($self, $value, $index)

Transpilation of G1 rule No 26, i.e. PropertyAssignment ::= GET PropertyName LPAREN RPAREN LCURLY FunctionBody RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_27($self, $value, $index)

Transpilation of G1 rule No 27, i.e. PropertyAssignment ::= SET PropertyName LPAREN PropertySetParameterList RPAREN LCURLY FunctionBody RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_28($self, $value, $index)

Transpilation of G1 rule No 28, i.e. PropertyName ::= IDENTIFIERNAME

$value is the value of RHS No $index (starting at 0).

=head2 G1_29($self, $value, $index)

Transpilation of G1 rule No 29, i.e. PropertyName ::= StringLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_30($self, $value, $index)

Transpilation of G1 rule No 30, i.e. PropertyName ::= NumericLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_31($self, $value, $index)

Transpilation of G1 rule No 31, i.e. PropertySetParameterList ::= IDENTIFIER

$value is the value of RHS No $index (starting at 0).

=head2 G1_32($self, $value, $index)

Transpilation of G1 rule No 32, i.e. MemberExpression ::= PrimaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_33($self, $value, $index)

Transpilation of G1 rule No 33, i.e. MemberExpression ::= FunctionExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_34($self, $value, $index)

Transpilation of G1 rule No 34, i.e. MemberExpression ::= MemberExpression LBRACKET Expression RBRACKET

$value is the value of RHS No $index (starting at 0).

=head2 G1_35($self, $value, $index)

Transpilation of G1 rule No 35, i.e. MemberExpression ::= MemberExpression DOT IDENTIFIERNAME

$value is the value of RHS No $index (starting at 0).

=head2 G1_36($self, $value, $index)

Transpilation of G1 rule No 36, i.e. MemberExpression ::= NEW MemberExpression Arguments

$value is the value of RHS No $index (starting at 0).

=head2 G1_37($self, $value, $index)

Transpilation of G1 rule No 37, i.e. NewExpression ::= MemberExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_38($self, $value, $index)

Transpilation of G1 rule No 38, i.e. NewExpression ::= NEW NewExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_39($self, $value, $index)

Transpilation of G1 rule No 39, i.e. CallExpression ::= MemberExpression Arguments

$value is the value of RHS No $index (starting at 0).

=head2 G1_40($self, $value, $index)

Transpilation of G1 rule No 40, i.e. CallExpression ::= CallExpression Arguments

$value is the value of RHS No $index (starting at 0).

=head2 G1_41($self, $value, $index)

Transpilation of G1 rule No 41, i.e. CallExpression ::= CallExpression LBRACKET Expression RBRACKET

$value is the value of RHS No $index (starting at 0).

=head2 G1_42($self, $value, $index)

Transpilation of G1 rule No 42, i.e. CallExpression ::= CallExpression DOT IDENTIFIERNAME

$value is the value of RHS No $index (starting at 0).

=head2 G1_43($self, $value, $index)

Transpilation of G1 rule No 43, i.e. Arguments ::= LPAREN RPAREN

$value is the value of RHS No $index (starting at 0).

=head2 G1_44($self, $value, $index)

Transpilation of G1 rule No 44, i.e. Arguments ::= LPAREN ArgumentList RPAREN

$value is the value of RHS No $index (starting at 0).

=head2 G1_45($self, $value, $index)

Transpilation of G1 rule No 45, i.e. ArgumentList ::= AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_46($self, $value, $index)

Transpilation of G1 rule No 46, i.e. ArgumentList ::= ArgumentList COMMA AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_47($self, $value, $index)

Transpilation of G1 rule No 47, i.e. LeftHandSideExpression ::= NewExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_48($self, $value, $index)

Transpilation of G1 rule No 48, i.e. LeftHandSideExpression ::= CallExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_49($self, $value, $index)

Transpilation of G1 rule No 49, i.e. PostfixExpression ::= LeftHandSideExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_50($self, $value, $index)

Transpilation of G1 rule No 50, i.e. PostfixExpression ::= LeftHandSideExpression PLUSPLUS_POSTFIX

$value is the value of RHS No $index (starting at 0).

=head2 G1_51($self, $value, $index)

Transpilation of G1 rule No 51, i.e. PostfixExpression ::= LeftHandSideExpression MINUSMINUS_POSTFIX

$value is the value of RHS No $index (starting at 0).

=head2 G1_52($self, $value, $index)

Transpilation of G1 rule No 52, i.e. UnaryExpression ::= PostfixExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_53($self, $value, $index)

Transpilation of G1 rule No 53, i.e. UnaryExpression ::= DELETE UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_54($self, $value, $index)

Transpilation of G1 rule No 54, i.e. UnaryExpression ::= VOID UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_55($self, $value, $index)

Transpilation of G1 rule No 55, i.e. UnaryExpression ::= TYPEOF UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_56($self, $value, $index)

Transpilation of G1 rule No 56, i.e. UnaryExpression ::= PLUSPLUS UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_57($self, $value, $index)

Transpilation of G1 rule No 57, i.e. UnaryExpression ::= MINUSMINUS UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_58($self, $value, $index)

Transpilation of G1 rule No 58, i.e. UnaryExpression ::= PLUS UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_59($self, $value, $index)

Transpilation of G1 rule No 59, i.e. UnaryExpression ::= MINUS UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_60($self, $value, $index)

Transpilation of G1 rule No 60, i.e. UnaryExpression ::= INVERT UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_61($self, $value, $index)

Transpilation of G1 rule No 61, i.e. UnaryExpression ::= NOT UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_62($self, $value, $index)

Transpilation of G1 rule No 62, i.e. MultiplicativeExpression ::= UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_63($self, $value, $index)

Transpilation of G1 rule No 63, i.e. MultiplicativeExpression ::= MultiplicativeExpression MUL UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_64($self, $value, $index)

Transpilation of G1 rule No 64, i.e. MultiplicativeExpression ::= MultiplicativeExpression DIV UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_65($self, $value, $index)

Transpilation of G1 rule No 65, i.e. MultiplicativeExpression ::= MultiplicativeExpression MODULUS UnaryExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_66($self, $value, $index)

Transpilation of G1 rule No 66, i.e. AdditiveExpression ::= MultiplicativeExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_67($self, $value, $index)

Transpilation of G1 rule No 67, i.e. AdditiveExpression ::= AdditiveExpression PLUS MultiplicativeExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_68($self, $value, $index)

Transpilation of G1 rule No 68, i.e. AdditiveExpression ::= AdditiveExpression MINUS MultiplicativeExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_69($self, $value, $index)

Transpilation of G1 rule No 69, i.e. ShiftExpression ::= AdditiveExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_70($self, $value, $index)

Transpilation of G1 rule No 70, i.e. ShiftExpression ::= ShiftExpression LEFTMOVE AdditiveExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_71($self, $value, $index)

Transpilation of G1 rule No 71, i.e. ShiftExpression ::= ShiftExpression RIGHTMOVE AdditiveExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_72($self, $value, $index)

Transpilation of G1 rule No 72, i.e. ShiftExpression ::= ShiftExpression RIGHTMOVEFILL AdditiveExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_73($self, $value, $index)

Transpilation of G1 rule No 73, i.e. RelationalExpression ::= ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_74($self, $value, $index)

Transpilation of G1 rule No 74, i.e. RelationalExpression ::= RelationalExpression LT ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_75($self, $value, $index)

Transpilation of G1 rule No 75, i.e. RelationalExpression ::= RelationalExpression GT ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_76($self, $value, $index)

Transpilation of G1 rule No 76, i.e. RelationalExpression ::= RelationalExpression LE ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_77($self, $value, $index)

Transpilation of G1 rule No 77, i.e. RelationalExpression ::= RelationalExpression GE ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_78($self, $value, $index)

Transpilation of G1 rule No 78, i.e. RelationalExpression ::= RelationalExpression INSTANCEOF ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_79($self, $value, $index)

Transpilation of G1 rule No 79, i.e. RelationalExpression ::= RelationalExpression IN ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_80($self, $value, $index)

Transpilation of G1 rule No 80, i.e. RelationalExpressionNoIn ::= ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_81($self, $value, $index)

Transpilation of G1 rule No 81, i.e. RelationalExpressionNoIn ::= RelationalExpressionNoIn LT ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_82($self, $value, $index)

Transpilation of G1 rule No 82, i.e. RelationalExpressionNoIn ::= RelationalExpressionNoIn GT ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_83($self, $value, $index)

Transpilation of G1 rule No 83, i.e. RelationalExpressionNoIn ::= RelationalExpressionNoIn LE ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_84($self, $value, $index)

Transpilation of G1 rule No 84, i.e. RelationalExpressionNoIn ::= RelationalExpressionNoIn GE ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_85($self, $value, $index)

Transpilation of G1 rule No 85, i.e. RelationalExpressionNoIn ::= RelationalExpressionNoIn INSTANCEOF ShiftExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_86($self, $value, $index)

Transpilation of G1 rule No 86, i.e. EqualityExpression ::= RelationalExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_87($self, $value, $index)

Transpilation of G1 rule No 87, i.e. EqualityExpression ::= EqualityExpression EQ RelationalExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_88($self, $value, $index)

Transpilation of G1 rule No 88, i.e. EqualityExpression ::= EqualityExpression NE RelationalExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_89($self, $value, $index)

Transpilation of G1 rule No 89, i.e. EqualityExpression ::= EqualityExpression STRICTEQ RelationalExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_90($self, $value, $index)

Transpilation of G1 rule No 90, i.e. EqualityExpression ::= EqualityExpression STRICTNE RelationalExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_91($self, $value, $index)

Transpilation of G1 rule No 91, i.e. EqualityExpressionNoIn ::= RelationalExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_92($self, $value, $index)

Transpilation of G1 rule No 92, i.e. EqualityExpressionNoIn ::= EqualityExpressionNoIn EQ RelationalExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_93($self, $value, $index)

Transpilation of G1 rule No 93, i.e. EqualityExpressionNoIn ::= EqualityExpressionNoIn NE RelationalExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_94($self, $value, $index)

Transpilation of G1 rule No 94, i.e. EqualityExpressionNoIn ::= EqualityExpressionNoIn STRICTEQ RelationalExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_95($self, $value, $index)

Transpilation of G1 rule No 95, i.e. EqualityExpressionNoIn ::= EqualityExpressionNoIn STRICTNE RelationalExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_96($self, $value, $index)

Transpilation of G1 rule No 96, i.e. BitwiseANDExpression ::= EqualityExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_97($self, $value, $index)

Transpilation of G1 rule No 97, i.e. BitwiseANDExpression ::= BitwiseANDExpression BITAND EqualityExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_98($self, $value, $index)

Transpilation of G1 rule No 98, i.e. BitwiseANDExpressionNoIn ::= EqualityExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_99($self, $value, $index)

Transpilation of G1 rule No 99, i.e. BitwiseANDExpressionNoIn ::= BitwiseANDExpressionNoIn BITAND EqualityExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_100($self, $value, $index)

Transpilation of G1 rule No 100, i.e. BitwiseXORExpression ::= BitwiseANDExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_101($self, $value, $index)

Transpilation of G1 rule No 101, i.e. BitwiseXORExpression ::= BitwiseXORExpression BITXOR BitwiseANDExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_102($self, $value, $index)

Transpilation of G1 rule No 102, i.e. BitwiseXORExpressionNoIn ::= BitwiseANDExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_103($self, $value, $index)

Transpilation of G1 rule No 103, i.e. BitwiseXORExpressionNoIn ::= BitwiseXORExpressionNoIn BITXOR BitwiseANDExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_104($self, $value, $index)

Transpilation of G1 rule No 104, i.e. BitwiseORExpression ::= BitwiseXORExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_105($self, $value, $index)

Transpilation of G1 rule No 105, i.e. BitwiseORExpression ::= BitwiseORExpression BITOR BitwiseXORExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_106($self, $value, $index)

Transpilation of G1 rule No 106, i.e. BitwiseORExpressionNoIn ::= BitwiseXORExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_107($self, $value, $index)

Transpilation of G1 rule No 107, i.e. BitwiseORExpressionNoIn ::= BitwiseORExpressionNoIn BITOR BitwiseXORExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_108($self, $value, $index)

Transpilation of G1 rule No 108, i.e. LogicalANDExpression ::= BitwiseORExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_109($self, $value, $index)

Transpilation of G1 rule No 109, i.e. LogicalANDExpression ::= LogicalANDExpression AND BitwiseORExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_110($self, $value, $index)

Transpilation of G1 rule No 110, i.e. LogicalANDExpressionNoIn ::= BitwiseORExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_111($self, $value, $index)

Transpilation of G1 rule No 111, i.e. LogicalANDExpressionNoIn ::= LogicalANDExpressionNoIn AND BitwiseORExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_112($self, $value, $index)

Transpilation of G1 rule No 112, i.e. LogicalORExpression ::= LogicalANDExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_113($self, $value, $index)

Transpilation of G1 rule No 113, i.e. LogicalORExpression ::= LogicalORExpression OR LogicalANDExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_114($self, $value, $index)

Transpilation of G1 rule No 114, i.e. LogicalORExpressionNoIn ::= LogicalANDExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_115($self, $value, $index)

Transpilation of G1 rule No 115, i.e. LogicalORExpressionNoIn ::= LogicalORExpressionNoIn OR LogicalANDExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_116($self, $value, $index)

Transpilation of G1 rule No 116, i.e. ConditionalExpression ::= LogicalORExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_117($self, $value, $index)

Transpilation of G1 rule No 117, i.e. ConditionalExpression ::= LogicalORExpression QUESTION_MARK AssignmentExpression COLON AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_118($self, $value, $index)

Transpilation of G1 rule No 118, i.e. ConditionalExpressionNoIn ::= LogicalORExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_119($self, $value, $index)

Transpilation of G1 rule No 119, i.e. ConditionalExpressionNoIn ::= LogicalORExpressionNoIn QUESTION_MARK AssignmentExpression COLON AssignmentExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_120($self, $value, $index)

Transpilation of G1 rule No 120, i.e. AssignmentExpression ::= ConditionalExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_121($self, $value, $index)

Transpilation of G1 rule No 121, i.e. AssignmentExpression ::= LeftHandSideExpression ASSIGN AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_122($self, $value, $index)

Transpilation of G1 rule No 122, i.e. AssignmentExpression ::= LeftHandSideExpression AssignmentOperator AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_123($self, $value, $index)

Transpilation of G1 rule No 123, i.e. AssignmentExpressionNoIn ::= ConditionalExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_124($self, $value, $index)

Transpilation of G1 rule No 124, i.e. AssignmentExpressionNoIn ::= LeftHandSideExpression ASSIGN AssignmentExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_125($self, $value, $index)

Transpilation of G1 rule No 125, i.e. AssignmentExpressionNoIn ::= LeftHandSideExpression AssignmentOperator AssignmentExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_126($self, $value, $index)

Transpilation of G1 rule No 126, i.e. AssignmentOperator ::= MULASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_127($self, $value, $index)

Transpilation of G1 rule No 127, i.e. AssignmentOperator ::= DIVASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_128($self, $value, $index)

Transpilation of G1 rule No 128, i.e. AssignmentOperator ::= MODULUSASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_129($self, $value, $index)

Transpilation of G1 rule No 129, i.e. AssignmentOperator ::= PLUSASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_130($self, $value, $index)

Transpilation of G1 rule No 130, i.e. AssignmentOperator ::= MINUSASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_131($self, $value, $index)

Transpilation of G1 rule No 131, i.e. AssignmentOperator ::= LEFTMOVEASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_132($self, $value, $index)

Transpilation of G1 rule No 132, i.e. AssignmentOperator ::= RIGHTMOVEASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_133($self, $value, $index)

Transpilation of G1 rule No 133, i.e. AssignmentOperator ::= RIGHTMOVEFILLASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_134($self, $value, $index)

Transpilation of G1 rule No 134, i.e. AssignmentOperator ::= BITANDASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_135($self, $value, $index)

Transpilation of G1 rule No 135, i.e. AssignmentOperator ::= BITXORASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_136($self, $value, $index)

Transpilation of G1 rule No 136, i.e. AssignmentOperator ::= BITORASSIGN

$value is the value of RHS No $index (starting at 0).

=head2 G1_137($self, $value, $index)

Transpilation of G1 rule No 137, i.e. Expression ::= AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_138($self, $value, $index)

Transpilation of G1 rule No 138, i.e. Expression ::= Expression COMMA AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_139($self, $value, $index)

Transpilation of G1 rule No 139, i.e. ExpressionNoIn ::= AssignmentExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_140($self, $value, $index)

Transpilation of G1 rule No 140, i.e. ExpressionNoIn ::= ExpressionNoIn COMMA AssignmentExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_141($self, $value, $index)

Transpilation of G1 rule No 141, i.e. Statement ::= Block

$value is the value of RHS No $index (starting at 0).

=head2 G1_142($self, $value, $index)

Transpilation of G1 rule No 142, i.e. Statement ::= VariableStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_143($self, $value, $index)

Transpilation of G1 rule No 143, i.e. Statement ::= EmptyStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_144($self, $value, $index)

Transpilation of G1 rule No 144, i.e. Statement ::= ExpressionStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_145($self, $value, $index)

Transpilation of G1 rule No 145, i.e. Statement ::= IfStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_146($self, $value, $index)

Transpilation of G1 rule No 146, i.e. Statement ::= IterationStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_147($self, $value, $index)

Transpilation of G1 rule No 147, i.e. Statement ::= ContinueStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_148($self, $value, $index)

Transpilation of G1 rule No 148, i.e. Statement ::= BreakStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_149($self, $value, $index)

Transpilation of G1 rule No 149, i.e. Statement ::= ReturnStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_150($self, $value, $index)

Transpilation of G1 rule No 150, i.e. Statement ::= WithStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_151($self, $value, $index)

Transpilation of G1 rule No 151, i.e. Statement ::= LabelledStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_152($self, $value, $index)

Transpilation of G1 rule No 152, i.e. Statement ::= SwitchStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_153($self, $value, $index)

Transpilation of G1 rule No 153, i.e. Statement ::= ThrowStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_154($self, $value, $index)

Transpilation of G1 rule No 154, i.e. Statement ::= TryStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_155($self, $value, $index)

Transpilation of G1 rule No 155, i.e. Statement ::= DebuggerStatement

$value is the value of RHS No $index (starting at 0).

=head2 G1_156($self, $value, $index)

Transpilation of G1 rule No 156, i.e. Block ::= LCURLY_BLOCK StatementListopt RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_157($self, $value, $index)

Transpilation of G1 rule No 157, i.e. StatementList ::= Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_158($self, $value, $index)

Transpilation of G1 rule No 158, i.e. StatementList ::= StatementList Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_159($self, $value, $index)

Transpilation of G1 rule No 159, i.e. VariableStatement ::= VAR VariableDeclarationList SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_160($self, $value, $index)

Transpilation of G1 rule No 160, i.e. VariableDeclarationList ::= VariableDeclaration

$value is the value of RHS No $index (starting at 0).

=head2 G1_161($self, $value, $index)

Transpilation of G1 rule No 161, i.e. VariableDeclarationList ::= VariableDeclarationList COMMA VariableDeclaration

$value is the value of RHS No $index (starting at 0).

=head2 G1_162($self, $value, $index)

Transpilation of G1 rule No 162, i.e. VariableDeclarationListNoIn ::= VariableDeclarationNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_163($self, $value, $index)

Transpilation of G1 rule No 163, i.e. VariableDeclarationListNoIn ::= VariableDeclarationListNoIn COMMA VariableDeclarationNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_164($self, $value, $index)

Transpilation of G1 rule No 164, i.e. VariableDeclaration ::= IDENTIFIER Initialiseropt

$value is the value of RHS No $index (starting at 0).

=head2 G1_165($self, $value, $index)

Transpilation of G1 rule No 165, i.e. VariableDeclarationNoIn ::= IDENTIFIER InitialiserNoInopt

$value is the value of RHS No $index (starting at 0).

=head2 G1_166($self, $value, $index)

Transpilation of G1 rule No 166, i.e. Initialiseropt ::= Initialiser

$value is the value of RHS No $index (starting at 0).

=head2 G1_167($self, $value, $index)

Transpilation of G1 rule No 167, i.e. Initialiseropt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_168($self, $value, $index)

Transpilation of G1 rule No 168, i.e. Initialiser ::= ASSIGN AssignmentExpression

$value is the value of RHS No $index (starting at 0).

=head2 G1_169($self, $value, $index)

Transpilation of G1 rule No 169, i.e. InitialiserNoInopt ::= InitialiserNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_170($self, $value, $index)

Transpilation of G1 rule No 170, i.e. InitialiserNoInopt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_171($self, $value, $index)

Transpilation of G1 rule No 171, i.e. InitialiserNoIn ::= ASSIGN AssignmentExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_172($self, $value, $index)

Transpilation of G1 rule No 172, i.e. EmptyStatement ::= VISIBLE_SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_173($self, $value, $index)

Transpilation of G1 rule No 173, i.e. ExpressionStatement ::= Expression SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_174($self, $value, $index)

Transpilation of G1 rule No 174, i.e. IfStatement ::= IF LPAREN Expression RPAREN Statement ELSE Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_175($self, $value, $index)

Transpilation of G1 rule No 175, i.e. IfStatement ::= IF LPAREN Expression RPAREN Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_176($self, $value, $index)

Transpilation of G1 rule No 176, i.e. ExpressionNoInopt ::= ExpressionNoIn

$value is the value of RHS No $index (starting at 0).

=head2 G1_177($self, $value, $index)

Transpilation of G1 rule No 177, i.e. ExpressionNoInopt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_178($self, $value, $index)

Transpilation of G1 rule No 178, i.e. Expressionopt ::= Expression

$value is the value of RHS No $index (starting at 0).

=head2 G1_179($self, $value, $index)

Transpilation of G1 rule No 179, i.e. Expressionopt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_180($self, $value, $index)

Transpilation of G1 rule No 180, i.e. IterationStatement ::= DO Statement WHILE LPAREN Expression RPAREN SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_181($self, $value, $index)

Transpilation of G1 rule No 181, i.e. IterationStatement ::= WHILE LPAREN Expression RPAREN Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_182($self, $value, $index)

Transpilation of G1 rule No 182, i.e. IterationStatement ::= FOR LPAREN ExpressionNoInopt VISIBLE_SEMICOLON Expressionopt VISIBLE_SEMICOLON Expressionopt RPAREN Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_183($self, $value, $index)

Transpilation of G1 rule No 183, i.e. IterationStatement ::= FOR LPAREN VAR VariableDeclarationListNoIn VISIBLE_SEMICOLON Expressionopt VISIBLE_SEMICOLON Expressionopt RPAREN Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_184($self, $value, $index)

Transpilation of G1 rule No 184, i.e. IterationStatement ::= FOR LPAREN LeftHandSideExpression IN Expression RPAREN Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_185($self, $value, $index)

Transpilation of G1 rule No 185, i.e. IterationStatement ::= FOR LPAREN VAR VariableDeclarationNoIn IN Expression RPAREN Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_186($self, $value, $index)

Transpilation of G1 rule No 186, i.e. ContinueStatement ::= CONTINUE SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_187($self, $value, $index)

Transpilation of G1 rule No 187, i.e. ContinueStatement ::= CONTINUE INVISIBLE_SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_188($self, $value, $index)

Transpilation of G1 rule No 188, i.e. ContinueStatement ::= CONTINUE IDENTIFIER SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_189($self, $value, $index)

Transpilation of G1 rule No 189, i.e. BreakStatement ::= BREAK SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_190($self, $value, $index)

Transpilation of G1 rule No 190, i.e. BreakStatement ::= BREAK INVISIBLE_SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_191($self, $value, $index)

Transpilation of G1 rule No 191, i.e. BreakStatement ::= BREAK IDENTIFIER SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_192($self, $value, $index)

Transpilation of G1 rule No 192, i.e. ReturnStatement ::= RETURN SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_193($self, $value, $index)

Transpilation of G1 rule No 193, i.e. ReturnStatement ::= RETURN INVISIBLE_SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_194($self, $value, $index)

Transpilation of G1 rule No 194, i.e. ReturnStatement ::= RETURN Expression SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_195($self, $value, $index)

Transpilation of G1 rule No 195, i.e. WithStatement ::= WITH LPAREN Expression RPAREN Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_196($self, $value, $index)

Transpilation of G1 rule No 196, i.e. SwitchStatement ::= SWITCH LPAREN Expression RPAREN CaseBlock

$value is the value of RHS No $index (starting at 0).

=head2 G1_197($self, $value, $index)

Transpilation of G1 rule No 197, i.e. CaseBlock ::= LCURLY CaseClausesopt RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_198($self, $value, $index)

Transpilation of G1 rule No 198, i.e. CaseBlock ::= LCURLY CaseClausesopt DefaultClause CaseClausesopt RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_199($self, $value, $index)

Transpilation of G1 rule No 199, i.e. CaseClausesopt ::= CaseClauses

$value is the value of RHS No $index (starting at 0).

=head2 G1_200($self, $value, $index)

Transpilation of G1 rule No 200, i.e. CaseClausesopt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_201($self, $value, $index)

Transpilation of G1 rule No 201, i.e. CaseClauses ::= CaseClause

$value is the value of RHS No $index (starting at 0).

=head2 G1_202($self, $value, $index)

Transpilation of G1 rule No 202, i.e. CaseClauses ::= CaseClauses CaseClause

$value is the value of RHS No $index (starting at 0).

=head2 G1_203($self, $value, $index)

Transpilation of G1 rule No 203, i.e. CaseClause ::= CASE Expression COLON StatementListopt

$value is the value of RHS No $index (starting at 0).

=head2 G1_204($self, $value, $index)

Transpilation of G1 rule No 204, i.e. StatementListopt ::= StatementList

$value is the value of RHS No $index (starting at 0).

=head2 G1_205($self, $value, $index)

Transpilation of G1 rule No 205, i.e. StatementListopt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_206($self, $value, $index)

Transpilation of G1 rule No 206, i.e. DefaultClause ::= DEFAULT COLON StatementListopt

$value is the value of RHS No $index (starting at 0).

=head2 G1_207($self, $value, $index)

Transpilation of G1 rule No 207, i.e. LabelledStatement ::= IDENTIFIER COLON Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_208($self, $value, $index)

Transpilation of G1 rule No 208, i.e. ThrowStatement ::= THROW Expression SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_209($self, $value, $index)

Transpilation of G1 rule No 209, i.e. TryStatement ::= TRY Block Catch

$value is the value of RHS No $index (starting at 0).

=head2 G1_210($self, $value, $index)

Transpilation of G1 rule No 210, i.e. TryStatement ::= TRY Block Finally

$value is the value of RHS No $index (starting at 0).

=head2 G1_211($self, $value, $index)

Transpilation of G1 rule No 211, i.e. TryStatement ::= TRY Block Catch Finally

$value is the value of RHS No $index (starting at 0).

=head2 G1_212($self, $value, $index)

Transpilation of G1 rule No 212, i.e. Catch ::= CATCH LPAREN IDENTIFIER RPAREN Block

$value is the value of RHS No $index (starting at 0).

=head2 G1_213($self, $value, $index)

Transpilation of G1 rule No 213, i.e. Finally ::= FINALLY Block

$value is the value of RHS No $index (starting at 0).

=head2 G1_214($self, $value, $index)

Transpilation of G1 rule No 214, i.e. DebuggerStatement ::= DEBUGGER SEMICOLON

$value is the value of RHS No $index (starting at 0).

=head2 G1_215($self, $value, $index)

Transpilation of G1 rule No 215, i.e. FunctionDeclaration ::= FUNCTION IDENTIFIER LPAREN FormalParameterListopt RPAREN LCURLY FunctionBody RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_216($self, $value, $index)

Transpilation of G1 rule No 216, i.e. Identifieropt ::= IDENTIFIER

$value is the value of RHS No $index (starting at 0).

=head2 G1_217($self, $value, $index)

Transpilation of G1 rule No 217, i.e. Identifieropt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_218($self, $value, $index)

Transpilation of G1 rule No 218, i.e. FunctionExpression ::= FUNCTION Identifieropt LPAREN FormalParameterListopt RPAREN LCURLY FunctionBody RCURLY

$value is the value of RHS No $index (starting at 0).

=head2 G1_219($self, $value, $index)

Transpilation of G1 rule No 219, i.e. FormalParameterListopt ::= FormalParameterList

$value is the value of RHS No $index (starting at 0).

=head2 G1_220($self, $value, $index)

Transpilation of G1 rule No 220, i.e. FormalParameterListopt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_221($self, $value, $index)

Transpilation of G1 rule No 221, i.e. FormalParameterList ::= IDENTIFIER

$value is the value of RHS No $index (starting at 0).

=head2 G1_222($self, $value, $index)

Transpilation of G1 rule No 222, i.e. FormalParameterList ::= FormalParameterList COMMA IDENTIFIER

$value is the value of RHS No $index (starting at 0).

=head2 G1_223($self, $value, $index)

Transpilation of G1 rule No 223, i.e. SourceElementsopt ::= SourceElements

$value is the value of RHS No $index (starting at 0).

=head2 G1_224($self, $value, $index)

Transpilation of G1 rule No 224, i.e. SourceElementsopt ::= 

$value is the value of RHS No $index (starting at 0).

=head2 G1_225($self, $value, $index)

Transpilation of G1 rule No 225, i.e. FunctionBody ::= SourceElementsopt

$value is the value of RHS No $index (starting at 0).

=head2 G1_226($self, $value, $index)

Transpilation of G1 rule No 226, i.e. Program ::= SourceElementsopt

$value is the value of RHS No $index (starting at 0).

=head2 G1_227($self, $value, $index)

Transpilation of G1 rule No 227, i.e. SourceElements ::= SourceElement

$value is the value of RHS No $index (starting at 0).

=head2 G1_228($self, $value, $index)

Transpilation of G1 rule No 228, i.e. SourceElements ::= SourceElements SourceElement

$value is the value of RHS No $index (starting at 0).

=head2 G1_229($self, $value, $index)

Transpilation of G1 rule No 229, i.e. SourceElement ::= Statement

$value is the value of RHS No $index (starting at 0).

=head2 G1_230($self, $value, $index)

Transpilation of G1 rule No 230, i.e. SourceElement ::= FunctionDeclaration

$value is the value of RHS No $index (starting at 0).

=head2 G1_231($self, $value, $index)

Transpilation of G1 rule No 231, i.e. NullLiteral ::= NULL

$value is the value of RHS No $index (starting at 0).

=head2 G1_232($self, $value, $index)

Transpilation of G1 rule No 232, i.e. BooleanLiteral ::= TRUE

$value is the value of RHS No $index (starting at 0).

=head2 G1_233($self, $value, $index)

Transpilation of G1 rule No 233, i.e. BooleanLiteral ::= FALSE

$value is the value of RHS No $index (starting at 0).

=head2 G1_234($self, $value, $index)

Transpilation of G1 rule No 234, i.e. StringLiteral ::= STRINGLITERAL

$value is the value of RHS No $index (starting at 0).

=head2 G1_235($self, $value, $index)

Transpilation of G1 rule No 235, i.e. RegularExpressionLiteral ::= REGULAREXPRESSIONLITERAL

$value is the value of RHS No $index (starting at 0).

=head2 G1_236($self, $value, $index)

Transpilation of G1 rule No 236, i.e. NumericLiteral ::= DecimalLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_237($self, $value, $index)

Transpilation of G1 rule No 237, i.e. NumericLiteral ::= HexIntegerLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_238($self, $value, $index)

Transpilation of G1 rule No 238, i.e. NumericLiteral ::= OctalIntegerLiteral

$value is the value of RHS No $index (starting at 0).

=head2 G1_239($self, $value, $index)

Transpilation of G1 rule No 239, i.e. DecimalLiteral ::= DECIMALLITERAL

$value is the value of RHS No $index (starting at 0).

=head2 G1_240($self, $value, $index)

Transpilation of G1 rule No 240, i.e. HexIntegerLiteral ::= HEXINTEGERLITERAL

$value is the value of RHS No $index (starting at 0).

=head2 G1_241($self, $value, $index)

Transpilation of G1 rule No 241, i.e. OctalIntegerLiteral ::= OCTALINTEGERLITERAL

$value is the value of RHS No $index (starting at 0).

=head2 G1_242($self, $value, $index)

Transpilation of G1 rule No 242, i.e. [:start] ::= Program

$value is the value of RHS No $index (starting at 0).

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
