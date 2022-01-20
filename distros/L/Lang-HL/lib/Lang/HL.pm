package Lang::HL;

use strict;
use warnings;
use utf8;
use Regexp::Grammars;

our $VERSION = '0.33';

sub new {
	my ($class) = @_;
	return bless {}, $class;
}

sub PT::Lang::X {
    my ($class) = @_;

    my $code = 'use strict;
use warnings;
use utf8;

our $hash0 = {};
    ';

    for my $element ( @{ $class->{Class}} ) {
        $code .= $element->X();
    }

    $code .= 'my $object = Main->new(); $object->main();';
    return $code;
}

sub PT::Class::X {
    my ($class) = @_;

    my $className = $class->{ClassName}->X();
    my $classBlock = $class->{ClassBlock}->X($className);

    my $classCode = '
        package ' . $className . ';
        use strict;
        use warnings;
        use utf8;
        use Lang::HL::Export;
        use feature qw(signatures);
        no warnings "experimental::signatures";
	use Data::Printer;
    ';

    $classCode .= $classBlock . "\n1;";
    return $classCode;
}

sub PT::ClassName::X {
    my ($class) = @_;
    my $className = $class->{''};
    return $className;
}

sub PT::ClassBlock::X {
    my ($class, $className) = @_;

    my $classBlock = '
        sub new($class) {
            my $hashRef = { "' . $className . '" => {} };
            return bless $hashRef, $class;
        }
    ';
    my $classGroups = $class->{ClassGroups}->X($className);

    $classBlock .= $classGroups;
    return $classBlock;
}

sub PT::ClassGroups::X {
    my ($class, $className) = @_;

    my @classGroups;
    for my $element ( @{$class->{Group}} ) {
        push @classGroups, $element->X($className);
    }

    my $classGroups = join("", @classGroups);
    return $classGroups;
}

sub PT::Group::X {
    my ($class, $className) = @_;

    return (       $class->{Comment}
                || $class->{Function}
                || $class->{Parent} )->X($className);
}

sub PT::Parent::X {
    my ($class, $className) = @_;
    my $parent = 'our @ISA = qw(';

    my $classNames = $class->{ClassNames}->X($className);
    $parent .= $classNames . ");\n";
}

sub PT::ClassNames::X {
    my ($class, $className) = @_;

    my @classNames;
    for my $element ( @{$class->{ClassName}} ) {
        push @classNames, $element->X($className);
    }

    my $classNames = join(" ", @classNames);
    return $classNames;
}

sub PT::Comment::X {
    my ($class, $className) = @_;
    my $comment = $class->{LineComment}->X($className);
    $comment = "\n" . "# " . $comment . "\n";
    return $comment;
}

sub PT::LineComment::X {
    my ($class, $className) = @_;
    return $class->{''};
}

sub PT::Function::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);
    my $functionParamList = $class->{FunctionParamList}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $function = "\n sub " . $functionName . $functionParamList . $codeBlock;
    return $function;
}

sub PT::FunctionName::X {
    my ($class, $className) = @_;
    my $functionName = $class->{''};
    return $functionName;
}

sub PT::FunctionParamList::X {
    my ($class, $className) = @_;
    my @params = (       $class->{EmptyParamList}
                      || $class->{FunctionParams} )->X($className);
    my $functionParamList;
    $functionParamList = '( $class, ';

    if($#params >= 0) {
        foreach my $param (@params) {
            if( $param eq "" ) {} else {
                $functionParamList .= "\$" . $param . ",";
            }
        }
        if( substr($functionParamList, -1) eq "," ) {
            chop($functionParamList);
        }
    }
    else {
        chop($functionParamList);
    }
    $functionParamList .= ")";

    return $functionParamList;
}

sub PT::CodeBlock::X {
    my ($class, $className) = @_;
    my $blocks = $class->{Blocks}->X($className);
    my $codeBlock = "{\n" . $blocks . "\n}";
    return $codeBlock;
}

sub PT::EmptyParamList::X {
    my ($class, $className) = @_;
    return $class->{''};
}

sub PT::FunctionParams::X {
    my ($class, $className) = @_;
    my @functionParams;

    for my $element ( @{ $class->{Arg}} ) {
        push @functionParams, $element->X($className);
    }

    return @functionParams;
}

sub PT::Arg::X {
    my ($class, $className) = @_;
    return $class->{''};
}

sub PT::Blocks::X {
    my ($class, $className) = @_;
    my @blocks;

    for my $element ( @{$class->{Block}} ) {
        push @blocks, $element->X($className);
    }

    my $blocks = join("\n", @blocks);
    return $blocks;
}

sub PT::Block::X {
    my ($class, $className) = @_;
    my $block = (      $class->{IfElse}
                    || $class->{While}
                    || $class->{ForEach}
                    || $class->{For}
                    || $class->{Comment}
                    || $class->{Statement} )->X($className);
    return $block;
}

sub PT::While::X {
    my ($class, $className) = @_;
    my $boolExpression = $class->{BoolExpression}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $while = "\n while ( " . $boolExpression . " ) " . $codeBlock;
    return $while;
}

sub PT::ForEach::X {
    my ($class, $className) = @_;
    my $forEachVariableName = $class->{ForEachVariableName}->X($className);
    my $variableName = $class->{VariableName}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $forEach = "\n foreach my " . $forEachVariableName
                  . " ( \@{" . $variableName . "} ) " . $codeBlock;

    return $forEach;
}

sub PT::ForEachVariableName::X {
    my ($class, $className) = @_;
    my $variableName = $class->{VariableName}->X($className);
    return $variableName;
}

sub PT::For::X {
    my ($class, $className) = @_;
    my $variableName = $class->{VariableName}->X($className);
    my @forRange = $class->{ForRange}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $for = "\n for my " . $variableName . " ( " . $forRange[0]
              . " ... " . $forRange[1] . " ) " . $codeBlock;

    return $for;
}

sub PT::ForRange::X {
    my ($class, $className) = @_;
    my $lowerRange = $class->{LowerRange}->X($className);
    my $upperRange = $class->{UpperRange}->X($className);

    my @forRange = ($lowerRange, $upperRange);
    return @forRange;
}

sub PT::LowerRange::X {
    my ($class, $className) = @_;
    my $number = (     $class->{Number}
                    || $class->{VariableName}
                    || $class->{ArrayElement}
                    || $class->{HashElement} )->X($className);

    return $number;
}

sub PT::UpperRange::X {
    my ($class, $className) = @_;
    my $number = (     $class->{Number}
                    || $class->{VariableName}
                    || $class->{ArrayElement}
                    || $class->{HashElement} )->X($className);

    return $number;
}

sub PT::IfElse::X {
    my ($class, $className) = @_;
	my $if = $class->{If}->X($className);
    my $elsif;
    my $else;
    if( exists $class->{ElsIf} ) {
        $elsif = $class->{ElsIf}->X($className);
    }
    if( exists $class->{Else} ) {
        $else = $class->{Else}->X($className);
    }

    my $ifElseIf;
    if (defined $elsif) {
        $ifElseIf = $if . $elsif . $else;
        return $ifElseIf;
    }
    if (defined $else) {
        $ifElseIf = $if . $else;
        return $ifElseIf;
    }

    $ifElseIf = $if;
    return $ifElseIf;
}

sub PT::IfElseIf::X {
    my ($class, $className) = @_;
    my $if = $class->{If}->X($className);
    my $elsif;
    my $else;
    if( exists $class->{ElsIf} ) {
        $elsif = $class->{ElsIf}->X($className);
    }
    if( exists $class->{Else} ) {
        $else = $class->{Else}->X($className);
    }

    my $ifElseIf;
    if (defined $elsif) {
        $ifElseIf = $if . $elsif . $else;
        return $ifElseIf;
    }
    if (defined $else) {
        $ifElseIf = $if . $else;
        return $ifElseIf;
    }

    $ifElseIf = $if;
    return $ifElseIf;
}

sub PT::If::X {
    my ($class, $className) = @_;
    my $boolExpression = $class->{BoolExpression}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $if = "\n if ( " . $boolExpression . " ) " . $codeBlock;
    return $if;
}

sub PT::BoolExpression::X {
    my ($class, $className) = @_;
    my $boolExpression;

    my $boolOperand = $class->{BoolOperands}->X($className);
    if( exists $class->{BoolOperatorExpression} ) {
        my @boolOperatorExpression = $class->{BoolOperatorExpression}->X($className);
        $boolExpression = $boolOperand . " "
                          . $boolOperatorExpression[0] . " " . $boolOperatorExpression[1];
        return $boolExpression;
    }

    $boolExpression = $boolOperand;
    return $boolExpression;
}

sub PT::BoolOperatorExpression::X {
    my ($class, $className) = @_;
    my $boolOperator = $class->{BoolOperator}->X($className);
    my $boolOperand = $class->{BoolOperands}->X($className);

    my @boolOperatorExpression = ($boolOperator, $boolOperand);
    return @boolOperatorExpression;
}

sub PT::BoolOperator::X {
    my ($class, $className) = @_;
    return (	   $class->{GreaterThan}
		|| $class->{LessThan}
		|| $class->{Equals}
		|| $class->{GreaterThanEquals}
		|| $class->{LessThanEquals}
		|| $class->{StringEquals}
		|| $class->{StringNotEquals}
		|| $class->{NotEqulas}
		|| $class->{LogicalAnd}
		|| $class->{LogicalOr} )->X($className);
}

sub PT::BoolOperands::X {
    my ($class, $className) = @_;
    return (	   $class->{Number}
		|| $class->{String}
		|| $class->{ScalarVariable}
		|| $class->{ArrayElement}
		|| $class->{HashElement} )->X($className);
}

sub PT::ElsIf::X {
    my ($class, $className) = @_;
    my @elsIfChain;
    for my $element ( @{$class->{ElsIfChain}} ) {
        push @elsIfChain, $element->X($className);
    }

    my $elsIfChain;
    foreach my $elsIf (@elsIfChain) {
        $elsIfChain .= $elsIf;
    }

    return $elsIfChain;
}

sub PT::ElsIfChain::X {
    my ($class, $className) = @_;
    my $boolExpression = $class->{BoolExpression}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $elsIf = "\n elsif ( " . $boolExpression . " ) " . $codeBlock;
    return $elsIf;
}

sub PT::Else::X {
    my ($class, $className) = @_;
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $else = "\n else " . $codeBlock;
    return $else;
}

sub PT::Statement::X {
    my ($class, $className) = @_;
    return (       $class->{VariableDeclaration}
                || $class->{FunctionCall}
                || $class->{Assignment}
                || $class->{ClassFunctionCall}
                || $class->{Return}
                || $class->{Last}
                || $class->{Next} )->X($className);
}

sub PT::VariableDeclaration::X {
    my ($class, $className) = @_;
    return (       $class->{ScalarDeclaration}
                || $class->{ArrayDeclaration}
                || $class->{HashDeclaration} )->X($className);
}

sub PT::ScalarDeclaration::X {
    my ($class, $className) = @_;
    my $variableName = $class->{VariableName}->X($className);
    my $value = $class->{Value}->X($className);

    my $scalarDeclaration = "\n my " . $variableName
                            .  " = " . $value . ";\n";
    return $scalarDeclaration;
}

sub PT::VariableName::X {
    my ($class, $className) = @_;
    my $variableName = $class->{''};
    return "\$" . $variableName;
}

sub PT::Value::X {
    my ($class, $className) = @_;
    my $rhs = $class->{RHS}->X($className);
    return $rhs;
}

sub PT::Number::X {
    my ($class, $className) = @_;
    my $number = $class->{''};
    return $number;
}

sub PT::String::X {
    my ($class, $className) = @_;
    my $stringValue = $class->{StringValue}->X($className);

    my $string = "\"" . $stringValue . "\"";
}

sub PT::StringValue::X {
    my ($class, $className) = @_;
    my $stringValue = $class->{''};
    return $stringValue;
}

sub PT::ArrayDeclaration::X {
    my ($class, $className) = @_;
    my $variableName = $class->{VariableName}->X($className);
    my $arrayList = $class->{ArrayList}->X($className);

    my $arrayDeclaration = "\n my " . $variableName
                           . " = " . $arrayList . ";\n";

    return $arrayDeclaration;
}

sub PT::ArrayList::X {
    my ($class, $className) = @_;
    my $arrayList = "[";
    my @listElements = $class->{ListElements}->X($className);

    $arrayList .= join(",", @listElements);

    $arrayList .= "]";
    return $arrayList;
}

sub PT::ListElements::X {
    my ($class, $className) = @_;
    my @listElements;

    for my $element ( @{ $class->{ListElement}} ) {
        push @listElements, $element->X($className);
    }

    return @listElements;
}

sub PT::ListElement::X {
    my ($class, $className) = @_;
    return (       $class->{Number}
                || $class->{String}
                || $class->{ArrayList}
                || $class->{HashRef} )->X($className);
}

sub PT::HashDeclaration::X {
    my ($class, $className) = @_;
    my $variableName = $class->{VariableName}->X($className);
    my $hashRef = $class->{HashRef}->X($className);

    my $hashDeclaration = "\n my " . $variableName
                          . " = " . $hashRef . ";\n";
}

sub PT::HashRef::X {
    my ($class, $className) = @_;
    my $hashRef = "{";
    my $keyValuePairs = $class->{KeyValuePairs}->X($className);
    $hashRef .= $keyValuePairs . "}";
    return $hashRef;
}

sub PT::KeyValuePairs::X {
    my ($class, $className) = @_;
    my @keyValuePairs;

    my $keyValuePairs = "";
    for my $element ( @{ $class->{KeyValue}} ) {
        @keyValuePairs = ();
        push @keyValuePairs, $element->X($className);
        $keyValuePairs .= $keyValuePairs[0] . " => " . $keyValuePairs[1] . ", ";
    }

    return $keyValuePairs;
}

sub PT::KeyValue::X {
    my ($class, $className) = @_;
    my $pairKey = $class->{PairKey}->X($className);
    my $pairValue = $class->{PairValue}->X($className);

    my @keyValue = ($pairKey, $pairValue);
    return @keyValue;
}

sub PT::PairKey::X {
    my ($class, $className) = @_;
    return (       $class->{Number}
                || $class->{String} )->X($className);
}

sub PT::PairValue::X {
    my ($class, $className) = @_;
    return (	   $class->{Number}
		|| $class->{String}
		|| $class->{ArrayList}
		|| $class->{HashRef}
		|| $class->{VariableName}
		|| $class->{ArrayElement}
		|| $class->{HashElement} )->X($className);
}

sub PT::FunctionCall::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);

    my $functionCall = $functionName . "(" ;

    if(exists $class->{Parameters}) {
        my @parameters = $class->{Parameters}->X($className);
        $functionCall .= join(",", @parameters);
    }

    $functionCall .= ");";
    return $functionCall;
}

sub PT::Parameters::X {
    my ($class, $className) = @_;
    my @parameters;

    for my $element (@{ $class->{Param} }) {
        push @parameters, $element->X($className);
    }

    return @parameters;
}

sub PT::Param::X {
    my ($class, $className) = @_;
    return (       $class->{Number}
                || $class->{String}
                || $class->{VariableName}
                || $class->{ArrayElement}
                || $class->{HashElement} )->X($className);
}

sub PT::Assignment::X {
    my ($class, $className) = @_;
    return (       $class->{ScalarAssignment}
                || $class->{ArrayAssignment}
                || $class->{HashAssignment}
                || $class->{AccessorAssignment} )->X($className);
}

sub PT::AccessorAssignment::X {
    my ($class, $className) = @_;

    my $variableName = $class->{HashKeyStringValue}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $accessorAssignment  = '$class->{"' . $className . '"}->{"'. $variableName .'"} = ' . $rhs .';';
    $accessorAssignment .= '$hash0->{"' . $className . '"}->{"'. $variableName .'"} = ' . $rhs .';';

    return $accessorAssignment;
}

sub PT::ScalarAssignment::X {
    my ($class, $className) = @_;
    my $lhs = $class->{ScalarVariable}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $scalarAssignment = $lhs . " = " . $rhs . ";\n";
    return $scalarAssignment;
}

sub PT::LHS::X {
    my ($class, $className) = @_;
    my $scalarVariable = $class->{ScalarVariable}->X($className);

    return $scalarVariable;
}

sub PT::ScalarVariable::X {
    my ($class, $className) = @_;

    my $scalarVariable = "\$";
    $scalarVariable .= $class->{''};

    return $scalarVariable;
}

sub PT::RHS::X {
    my ($class, $className) = @_;
    return (       $class->{Number}
                || $class->{FunctionReturn}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{ScalarVariable}
                || $class->{Calc}
                || $class->{ArrayList}
                || $class->{HashRef}
                || $class->{ClassAccessor}
                || $class->{OtherClassAccesor}
                || $class->{ClassFunctionReturn}
                || $class->{String}
                || $class->{STDIN} )->X($className);
}

sub PT::STDIN::X {
    my ($class, $className) = @_;
    my $stdin = '<STDIN>';
    return $stdin;
}

sub PT::ClassAccessor::X {
    my ($class, $className) = @_;
    my $variableName = $class->{HashKeyStringValue}->X($className);

    my $classAccessor = '$class->{"' . $className . '"}->{"'. $variableName .'"}';
    return $classAccessor;
}

sub PT::OtherClassAccesor::X {
    my ($class, $className) = @_;
    my $variableName = $class->{HashKeyStringValue}->X($className);
    my $parentClassName = $class->{ClassName}->X($className);

    my $otherClassAccessor = '$hash0->{"'. $parentClassName .'"}->{"'. $variableName .'"}';
    return $otherClassAccessor;
}

sub PT::ClassFunctionCall::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);
    my @parameters;
    my $parameters = "";
    if(exists $class->{Parameters}) {
        @parameters = $class->{Parameters}->X($className);
        $parameters = join(",", @parameters);
    }

    my $classFunctionReturn = '$class->' . $functionName . '('. $parameters .');';
    return $classFunctionReturn;
}

sub PT::ClassFunctionReturn::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);
    my @parameters;
    my $parameters = "";

    if(exists $class->{Parameters}) {
        @parameters = $class->{Parameters}->X($className);
        $parameters = join(",", @parameters);
    }

    my $classFunctionReturn = '$class->' . $functionName . '('. $parameters .')';
    return $classFunctionReturn;
}

sub PT::FunctionReturn::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);

    my $functionReturn = $functionName . "(" ;

    if(exists $class->{Parameters}) {
        my @parameters = $class->{Parameters}->X($className);
        my $parameters = join(",", @parameters);
        $functionReturn .= $parameters;
    }

    $functionReturn .= ")";
    return $functionReturn;
}

sub PT::ArrayElement::X {
    my ($class, $className) = @_;
    my $arrayName = $class->{ArrayName}->X($className);
    my @accessList;

    for my $element (@{ $class->{ArrayAccess} }) {
        push @accessList, $element->X($className);
    }

    my $arrayElement =  "\$" . $arrayName;
    foreach my $element (@accessList) {
        $arrayElement .= "->[" . $element . "]";
    }

    return $arrayElement;
}

sub PT::ArrayAccess::X {
    my ($class, $className) = @_;
    my $number = $class->{Number}->X($className);
    return $number;
}

sub PT::ArrayName::X {
    my ($class, $className) = @_;
    my $arrayName = $class->{''};
    return $arrayName;
}

sub PT::HashElement::X {
    my ($class, $className) = @_;
    my $hashName = $class->{HashName}->X($className);
    my @accessList;

    for my $element (@{ $class->{HashAccess} }) {
        push @accessList, $element->X($className);
    }

    my $hashElement = "\$" . $hashName;
    foreach my $element (@accessList) {
        $hashElement .= "->{" . $element . "}";
    }

    return $hashElement;
}

sub PT::HashAccess::X {
    my ($class, $className) = @_;
    my $hashKey = $class->{HashKey}->X($className);
    return $hashKey;
}

sub PT::HashName::X {
    my ($class, $className) = @_;
    my $hashName = $class->{''};
    return $hashName;
}

sub PT::HashKey::X {
    my ($class, $className) = @_;
    return (       $class->{HashKeyString}
                || $class->{HashKeyNumber} )->X($className);
}

sub PT::HashKeyString::X {
    my ($class, $className) = @_;

    my $hashKeyStringValue = "\"";
    $hashKeyStringValue .= $class->{HashKeyStringValue}->X($className);
    $hashKeyStringValue .= "\"";

    return $hashKeyStringValue;
}

sub PT::HashKeyStringValue::X {
    my ($class, $className) = @_;
    my $hashKeyStringValue = $class->{''};
    return $hashKeyStringValue;
}

sub PT::HashKeyNumber::X {
    my ($class, $className) = @_;
    my $hashKeyNumber = $class->{''};
    return $hashKeyNumber;
}

sub PT::ArrayAssignment::X {
    my ($class, $className) = @_;
    my $arrayElement = $class->{ArrayElement}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $arrayAssignment = $arrayElement . " = " . $rhs . ";\n";
    return $arrayAssignment;
}

sub PT::HashAssignment::X {
    my ($class, $className) = @_;
    my $hashElement = $class->{HashElement}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $hashAssignment = $hashElement . " = " . $rhs . ";\n";
    return $hashAssignment;
}

sub PT::Calc::X {
    my ($class, $className) = @_;
    my $calcExpression = $class->{CalcExpression}->X($className);
    return $calcExpression;
}

sub PT::CalcExpression::X {
    my ($class, $className) = @_;
    my @calcOperands;
    my @calcOperator;

    for my $element (@{ $class->{CalcOperands} }) {
        push @calcOperands, $element->X($className);
    }

    for my $element (@{ $class->{CalcOperator} }) {
        push @calcOperator, $element->X($className);
    }

    my $calcExpression = $calcOperands[0];
    for my $counter (1..$#calcOperands) {
        $calcExpression .= $calcOperator[$counter - 1] . " " . $calcOperands[$counter];
    }

    return $calcExpression;
}

sub PT::CalcOperands::X {
    my ($class, $className) = @_;
    return (       $class->{Number}
                || $class->{ScalarVariable}
                || $class->{ArrayElement}
                || $class->{HashElement} )->X($className);
}

sub PT::CalcOperator::X {
    my ($class, $className) = @_;
    return (       $class->{Plus}
                || $class->{Minus}
                || $class->{Multiply}
                || $class->{Divide} )->X($className);
}

sub PT::Return::X {
    my ($class, $className) = @_;
	if(exists $class->{RHS}) {
		my $rhs = $class->{RHS}->X($className);
	    my $return = "return " . $rhs . ";\n";
		return $return;
	} else {
		return "return;";
	}

}

sub PT::Last::X {
    my ($class, $className) = @_;
    return "last;";
}

sub PT::Next::X {
    my ($class, $className) = @_;
    return "next;";
}

sub PT::GreaterThan::X {
    my ($class, $className) = @_;
    my $greaterThan = $class->{''};
    return $greaterThan;
}

sub PT::LessThan::X {
    my ($class, $className) = @_;
    my $lessThan = $class->{''};
    return $lessThan;
}

sub PT::Equals::X {
    my ($class, $className) = @_;
    my $equals = $class->{''};
    return $equals;
}

sub PT::Plus::X {
    my ($class, $className) = @_;
    my $plus = $class->{''};
    return $plus;
}

sub PT::Minus::X {
    my ($class, $className) = @_;
    my $minus = $class->{''};
    return $minus;
}

sub PT::Multiply::X {
    my ($class, $className) = @_;
    my $multiply = $class->{''};
    return $multiply;
}

sub PT::Divide::X {
    my ($class, $className) = @_;
    my $divide = $class->{''};
    return $divide;
}

sub PT::GreaterThanEquals::X {
    my ($class, $className) = @_;
    my $greaterThanEquals = $class->{''};
    return $greaterThanEquals;
}

sub PT::LessThanEquals::X {
    my ($class, $className) = @_;
    my $lessThanEquals = $class->{''};
    return $lessThanEquals;
}

sub PT::StringEquals::X {
    my ($class, $className) = @_;
    my $stringEquals = $class->{''};
    return $stringEquals;
}

sub PT::StringNotEquals::X {
    my ($class, $className) = @_;
    my $stringNotEquals = $class->{''};
    return $stringNotEquals;
}

sub PT::NotEqulas::X {
    my ($class, $className) = @_;
    my $notEqulas = $class->{''};
    return $notEqulas;
}

sub PT::LogicalAnd::X {
    my ($class, $className) = @_;
    my $logicalAnd = $class->{''};
    return $logicalAnd;
}

sub PT::LogicalOr::X {
    my ($class, $className) = @_;
    my $logicalOr = $class->{''};
    return $logicalOr;
}

my $parser = qr {
    #<nocontext:>
    <debug: off>
    #<logfile: parserLog>
	#<timeout: 100>

    <Lang>
    <objrule:  PT::Lang>                       <[Class]>+

    <objrule:  PT::Class>                      <TokenClass> <ClassName> <ClassBlock>
    <objrule:  PT::ClassName>                  [a-zA-Z]+?
    <objrule:  PT::ClassBlock>                 <LBrace> <ClassGroups> <RBrace>
    <objrule:  PT::ClassGroups>                <[Group]>+

    <objrule:  PT::Group>                      <ws: (\s++)*> <Comment> | <Function> | <Parent>

    <objrule:  PT::Comment>                    [#] <LineComment> @
    <objtoken: PT::LineComment>                .*?

    <objrule:  PT::Parent>                     <TokenParent> <LParen> <ClassNames> <RParen> <SemiColon>
    <objrule:  PT::ClassNames>                 <[ClassName]>+ % <Comma>

    <objrule:  PT::Function>                   <TokenFunction> <FunctionName> <LParen> <FunctionParamList> <RParen> <CodeBlock>
    <objtoken: PT::FunctionName>               [a-zA-Z]+?

    <objrule:  PT::FunctionParamList>          <EmptyParamList> | <FunctionParams>
    <objtoken: PT::EmptyParamList>             .{0}
    <objrule:  PT::FunctionParams>             <[Arg]>+ % <Comma>
    <objrule:  PT::Arg>                        [a-zA-Z]+?

    <objrule:  PT::CodeBlock>                  <LBrace> <Blocks> <RBrace>
    <objrule:  PT::Blocks>                     <[Block]>+

    <objrule:  PT::Block>                      <IfElse> | <While> | <ForEach> | <For> | <Comment> | <Statement>

    <objrule:  PT::While>                      <TokenWhile> <LParen> <BoolExpression> <RParen> <CodeBlock>
    <objrule:  PT::ForEach>                    <TokenForeach> <Var> <ForEachVariableName> <LParen> <VariableName> <RParen> <CodeBlock>
    <objrule:  PT::ForEachVariableName>        <VariableName>

    <objrule:  PT::For>                        <TokenFor> <Var> <VariableName> <LParen> <ForRange> <RParen> <CodeBlock>
    <objrule:  PT::ForRange>                   <LowerRange> <Dot><Dot><Dot> <UpperRange>
    <objrule:  PT::LowerRange>                 <Number> | <VariableName> | <ArrayElement> | <HashElement>
    <objrule:  PT::UpperRange>                 <Number> | <VariableName> | <ArrayElement> | <HashElement>

    <objrule:  PT::IfElse>                     <If> <ElsIf>? <Else>?
    <objrule:  PT::If>                         <TokenIf> <LParen> <BoolExpression> <RParen> <CodeBlock>
    <objrule:  PT::BoolExpression>             <BoolOperands> <BoolOperatorExpression>?
    <objrule:  PT::BoolOperatorExpression>     <BoolOperator> <BoolOperands>
    <objrule:  PT::BoolOperands>               <Number> | <String> | <ScalarVariable> | <ArrayElement> | <HashElement>
    <objrule:  PT::BoolOperator>               <GreaterThan> | <LessThan> | <Equals> | <GreaterThanEquals> | <LessThanEquals>
                                               | <StringEquals> | <StringNotEquals> | <NotEqulas> | <LogicalAnd> | <LogicalOr>
    <objrule:  PT::ElsIf>                      <[ElsIfChain]>+
    <objrule:  PT::ElsIfChain>                 <TokenElsIf> <LParen> <BoolExpression> <RParen> <CodeBlock>
    <objrule:  PT::Else>                       <TokenElse> <CodeBlock>

    <objrule:  PT::Statement>                  <VariableDeclaration> | <FunctionCall> | <ClassFunctionCall>
                                               | <Assignment> | <Return> | <Last> | <Next>
    <objrule:  PT::ClassFunctionCall>          <TokenClass> <Dot> <FunctionName> <LParen> <Parameters>? <RParen> <SemiColon>

    <objrule:  PT::VariableDeclaration>        <ArrayDeclaration> | <HashDeclaration> | <ScalarDeclaration>

    <objrule:  PT::ScalarDeclaration>          <Var> <VariableName> <Equal> <Value> <SemiColon>

    <objtoken: PT::Var>                        var
    <objtoken: PT::VariableName>               [a-zA-Z]+?
    <objrule:  PT::Value>                      <RHS>
    <objtoken: PT::Number>                     [0-9]+
    <objrule:  PT::String>                     <LQuote> <StringValue> <RQuote>
    <objrule:  PT::LQuote>                     <Quote>
    <objrule:  PT::RQuote>                     <Quote>
    <objtoken: PT::StringValue>                (?<=")\s*.*?\s*(?=")

    <objrule:  PT::ArrayDeclaration>           <Var> <VariableName> <Equal> <ArrayList> <SemiColon>
    <objrule:  PT::ArrayList>                  <LBracket> <ListElements> <RBracket>
    <objrule:  PT::ListElements>               .{0} | <[ListElement]>+ % <Comma>
    <objrule:  PT::ListElement>                <Number> | <String> | <ArrayList> | <HashRef>

    <objrule:  PT::HashDeclaration>            <Var> <VariableName> <Equal> <HashRef> <SemiColon>
    <objrule:  PT::HashRef>                    <LBrace> <KeyValuePairs> <RBrace>
    <objrule:  PT::KeyValuePairs>              .{0} | <[KeyValue]>+ % <Comma>
    <objrule:  PT::KeyValue>                   <PairKey> <Colon> <PairValue>
    <objrule:  PT::PairKey>                    <Number> | <String>
    <objrule:  PT::PairValue>                  <Number> | <String> | <ArrayList> | <HashRef>
											   | <VariableName> | <ArrayElement> | <HashElement>

    <objrule:  PT::FunctionCall>               <FunctionName> <LParen> <Parameters>? <RParen> <SemiColon>
    <objrule:  PT::Parameters>                 <[Param]>+ % <Comma>
    <objrule:  PT::Param>                      <Number> | <String> | <VariableName> | <ArrayElement> | <HashElement>

    <objrule:  PT::Assignment>                 <ScalarAssignment> | <ArrayAssignment> | <HashAssignment> | <AccessorAssignment>

    <objrule:  PT::ScalarAssignment>           <ScalarVariable> <Equal> <RHS> <SemiColon>
    <objtoken: PT::ScalarVariable>             [a-zA-Z]+
    <objrule:  PT::RHS>                        <Number> | <FunctionReturn> | <ArrayElement> | <HashElement>
                                               | <ScalarVariable> | <Calc> | <ArrayList> | <HashRef> | <ClassAccessor>
                                               | <OtherClassAccesor> | <ClassFunctionReturn> | <String> | <STDIN>
    <objrule:  PT::FunctionReturn>             <FunctionName> <LParen> <Parameters>? <RParen>
    <objrule:  PT::ArrayElement>               <ArrayName> <[ArrayAccess]>+
    <objrule:  PT::ArrayAccess>                <LBracket> <Number> <RBracket>
    <objrule:  PT::ArrayName>                  [a-zA-Z]+?
    <objrule:  PT::HashElement>                <HashName> <[HashAccess]>+
    <objrule:  PT::HashAccess>                 <LBrace> <HashKey> <RBrace>
    <objtoken: PT::HashName>                   [a-zA-Z]+?
    <objrule:  PT::HashKey>                    <HashKeyString> | <HashKeyNumber>
    <objrule:  PT::HashKeyString>              <LQuote> <HashKeyStringValue> <RQuote>
    <objtoken: PT::HashKeyStringValue>         [a-zA-Z]+?
    <objtoken: PT::HashKeyNumber>              [0-9]+?

    <objrule:  PT::STDIN>                      <LessThan>  <TokenSTDIN> <GreaterThan>

    <objrule:  PT::AccessorAssignment>         <TokenClass> <Dot> <HashKeyStringValue> <Equal> <RHS> <SemiColon>
    <objrule:  PT::ClassAccessor>              <TokenClass> <Dot> <HashKeyStringValue>
    <objrule:  PT::OtherClassAccesor>          <TokenClass> <Dot> <ClassName> <Dot> <HashKeyStringValue>
    <objrule:  PT::ClassFunctionReturn>        <TokenClass> <Dot> <FunctionName> <LParen> <Parameters>? <RParen>

    <objrule:  PT::ArrayAssignment>            <ArrayElement> <Equal> <RHS> <SemiColon>
    <objrule:  PT::HashAssignment>             <HashElement> <Equal> <RHS> <SemiColon>

    <objrule:  PT::Calc>                       <CalcExpression>
    <objrule:  PT::CalcExpression>             <[CalcOperands]>+ % <[CalcOperator]>
    <objrule:  PT::CalcOperands>               <Number> | <ScalarVariable> | <ArrayElement> | <HashElement>
    <objtoken: PT::CalcOperator>               <Plus> | <Minus> | <Multiply> | <Divide>

    <objrule:  PT::Return>                     <TokenReturn> <RHS>? <SemiColon>
    <objrule:  PT::Last>                       <TokenLast> <SemiColon>
    <objrule:  PT::Next>                       <TokenNext> <SemiColon>

    <objtoken: PT::TokenReturn>                return
    <objtoken: PT::TokenNext>                  next
    <objtoken: PT::TokenLast>                  last
    <objtoken: PT::TokenElse>                  else
    <objtoken: PT::TokenElsIf>                 elsif
    <objtoken: PT::TokenIf>                    if
    <objtoken: PT::TokenFor>                   for
    <objtoken: PT::TokenForeach>               foreach
    <objtoken: PT::TokenWhile>                 while
    <objtoken: PT::TokenFunction>              function
    <objtoken: PT::TokenParent>                parent
    <objtoken: PT::TokenClass>                 class

    <objtoken: PT::TokenSTDIN>                 STDIN

    <objtoken: PT::LogicalAnd>		        \&\&
    <objtoken: PT::LogicalOr>            	\|\|
    <objtoken: PT::NotEqulas>                  \!=
    <objtoken: PT::StringNotEquals>            ne
    <objtoken: PT::StringEquals>               eq
    <objtoken: PT::LessThanEquals>             \<=
    <objtoken: PT::GreaterThanEquals>          \>=
    <objtoken: PT::GreaterThan>                \>
    <objtoken: PT::LessThan>                   \<
    <objtoken: PT::Equals>                     ==
    <objtoken: PT::Plus>                       \+
    <objtoken: PT::Minus>                      \-
    <objtoken: PT::Multiply>                   \*
    <objtoken: PT::Divide>                     \/
    <objtoken: PT::Quote>                      "
    <objtoken: PT::SemiColon>                  ;
    <objtoken: PT::Colon>                      :
    <objtoken: PT::Dot>                        \.
    <objtoken: PT::Equal>                      =
    <objtoken: PT::Comma>                      ,
    <objtoken: PT::LParen>                     \(
    <objtoken: PT::RParen>                     \)
    <objtoken: PT::LBrace>                     \{
    <objtoken: PT::RBrace>                     \}
    <objtoken: PT::LBracket>                   \[
    <objtoken: PT::RBracket>                   \]
}xms;

sub parse {
    my ($class, $program) = @_;
    if($program =~ $parser) {
        my $code = $/{Lang}->X();
        return $code;
    } else {
        print "Not matched";
    }
}

1;
__END__


=head1 NAME

Lang::HL HL programming language.

=head1 SYNOPSIS

  $> hlc <directoryName>
  $> hlp <directoryName>

=head1 DESCRIPTION

HL is a programming language.

=head1 EXAMPLE

	class NotePad {
	    function notePad() {
	        var text = "NotePad Example";
	        class.text = text;
	    }
	}

	class Main {
	    parent(NotePad);

	    function main() {
	        class.notePad();
	        var text = class.NotePad.text;
	        print(text, "\n");
	    }
	}

=head1 AUTHOR

Rajkumar Reddy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Rajkumar Reddy. All rights reserved.

Open Source.

=cut
