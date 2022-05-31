package Lang::HL;

use strict;
use warnings;
use utf8;
use Regexp::Grammars;

our $VERSION = '5.052';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

my $groupTable = {};

sub PT::Lang::X {
    my ($class) = @_;

    my $code = 'use strict;
        use warnings;
        use utf8;

        package Lang::HL::Export;

        use strict;
        no warnings;
        use utf8;
        use feature qw(signatures);
        no warnings "experimental::signatures";
        no warnings "experimental::smartmatch";
        use Hash::Merge;

        require Exporter;

        our @ISA = qw(Exporter);
        our @EXPORT = qw(
            arrayElement
            arrayLength
            arrayMerge
            arraySort
            arrayPop
            arrayPush
            arrayShift
            arrayUnshift
            arraySort
            arrayJoin
            arrayReverse
            arrayDelete
            hashKeys
            hashElement
            hashMerge
            hashDelete
            stringConcat
            readFile
            writeFile
            not
        );

        sub not($boolOperand) {
            my $not = ! $boolOperand;
            return $not;
        }

        sub arrayElement($array, $element) {
            if( $element ~~ @{$array} ) {
                return 1;
            } else {
                return 0;
            }
        }

        sub arrayDelete($array, $element) {
            delete($array->[$element]);
        }

        sub hashDelete($hash, $element) {
            delete($hash->{$element});
        }

        sub arrayReverse($array) {
            my @reversedArray = reverse(@{$array});
            return \@reversedArray;
        }

        sub arrayJoin($separator, $array) {
            my @array = @{$array};
            return join($separator, $array);
        }

        sub arraySort($array) {
            my @array = @{$array};
            my @sortedArray = sort(@array);
            return \@sortedArray;
        }

        sub arrayUnshift($array, $element) {
            unshift(@{$array}, $element);
        }

        sub arrayShift($array) {
            return shift(@{$array});
        }

        sub arrayPush($array, $element) {
            push(@{$array}, $element);
        }

        sub arrayPop($array) {
            return pop(@{$array});
        }

        sub stringConcat($textOne, $textTwo) {
            return $textOne . $textTwo;
        }

        sub arrayLength($array) {
            my @newArray = @{$array};
            return $#newArray;
        }

        sub arrayMerge($arrayOne, $arrayTwo) {
            my @newArray = ( @{$arrayOne}, @{$arrayTwo} );
            return \@newArray;
        }

        sub hashElement($hash, $element) {
            my %hashMap  = %{$hash};
            if( exists $hashMap{$element} ) {
                return 1;
            } else {
                return 0;
            }
        }

        sub hashKeys($hash) {
            my @keys = keys(%{$hash});
            return \@keys;
        }

        sub hashMerge($hashOne, $hashTwo) {
            my $mergedHash = merge($hashOne, $hashTwo);
            return $mergedHash;
        }

        sub readFile($fileName) {
            my $fileContent;
            open(my $fh, "<:encoding(UTF-8)", $fileName) or die "Cannot open the $fileName file";
            {
                local $/;
                $fileContent = <$fh>;
            }
            close($fh);
            return $fileContent;
        }

        sub writeFile($fileName, $fileContent) {
            open(my $fh, ">:encoding(UTF-8)", $fileName) or die "Cannot open the $fileName file";
            print $fh $fileContent;
            close($fh);
        }

        1;';

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
        use Try::Tiny;
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

    my $errorLBrace = $class->{ErrorLBrace}->X($className);
    my $classGroups = $class->{ClassGroups}->X($className);
    my $errorRBrace = $class->{ErrorRBrace}->X($className);

    $classBlock .= $classGroups;
    return $classBlock;
}

sub PT::ErrorLBrace::X {
    my ($class, $className) = @_;

    return (       $class->{LBrace}
                || $class->{LBraceError} )->X($className);
}

sub PT::ErrorRBrace::X {
    my ($class, $className) = @_;

    return (       $class->{RBrace}
                || $class->{RBraceError} )->X($className);       
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
                || $class->{Parent}
                || $class->{Packages}
                || $class->{ImplementFunction}
                || $class->{EmbedBlock}
                || $class->{Function}
                || $class->{GroupDeclaration}
                || $class->{NonSyntaxClass} )->X($className);
}

sub PT::ImplementFunction::X {
    my ($class, $className) = @_;

    my $functionName = $class->{FunctionName}->X($className);
    my $functionParamList = $class->{FunctionParamList}->X($className);

    my $multiLineComment = "";
    if(exists $class->{MultiLineComment}) {
        my $multiLineComment = $class->{MultiLineComment}->X($className);
    }

    my $dieMessage = "function " . $functionName . " in class " . $className . " is not defined \n";
    my $implementFunction = "sub " . $functionName . $functionParamList . "{\n" . $multiLineComment . "\n die(" . $dieMessage . ");}\n";

    return $implementFunction;
}

sub PT::MultiLineComment::X {
    my ($class, $className) = @_;

    my $mlComment = $class->{MLComment}->X($className);
    return $mlComment;
}

sub PT::MLComment::X {
    my ($class, $className) = @_;
    my $mlComment = $class->{''};
    return $mlComment;
}

sub PT::NonSyntaxClass::X {
    my ($class, $className) = @_;
    my $nonSyntax = $class->{''};

    my @nonSyntax = split(" ", $nonSyntax);
    $nonSyntax = $nonSyntax[0];

    print "SyntaxError", "\n";
    print "===========", "\n";
    print "ClassName: ", $className, "\n";
    die "Error: $nonSyntax \n";
}

sub PT::Packages::X {
    my ($class, $className) = @_;

    my @packageList = ($class->{PackageList})->X($className);
    my $packages = join("\n", @packageList);
    return $packages;
}

sub PT::PackageList::X {
    my ($class, $className) = @_;

    my @packageList;
    for my $element ( @{$class->{Package}} ) {
        push @packageList, $element->X($className);
    }

    return @packageList;
}

sub PT::Package::X {
    my ($class, $className) = @_;

    return (       $class->{PackageWithConstructor}
                || $class->{PackageWithoutConstructor} )->X($className);
}

sub PT::PackageWithConstructor::X {
    my ($class, $className) = @_;

    my $object = $class->{Object}->X($className);
    my $packageName = $class->{PackageName}->X($className);
    my $constructor = $class->{Constructor}->X($className);

    if(exists $class->{ObjectParameters}) {
        my $objectParameters = $class->{ObjectParameters}->X($className);
        my $parameters;

        if(ref($objectParameters)) {
            $parameters = join(",", @{$objectParameters});
        } else {
            $parameters = $objectParameters;
        }

        my $packageWithConstructor = "use " . $packageName . ";\n"
                                     . "my \$" . $object . " = " . $packageName . "->"
                                     . $constructor . "(" . $parameters . ");\n";
        return $packageWithConstructor;
    }

    my $packageWithConstructor = "use " . $packageName . ";\n"
                                 . "my \$" . $object . " = " . $packageName
                                 . "->" . $constructor . "();\n";
    return $packageWithConstructor;
}

sub PT::ObjectParameters::X {
    my ($class, $className) = @_;

    return (       $class->{PackageParams}
                || $class->{Parameters} )->X($className);
}

sub PT::PackageParams::X {
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

sub PT::PackageName::X {
    my ($class, $className) = @_;

    my @packageDir;
    for my $element ( @{ $class->{PackageDir}} ) {
        push @packageDir, $element->X($className);
    }

    my $packageName = join("::", @packageDir);
    return $packageName;
}

sub PT::PackageWithoutConstructor::X {
    my ($class, $className) = @_;
    my $packageName = $class->{PackageName}->X($className);

    if(exists $class->{QW}) {
        my $qw = $class->{QW}->X($className);

        my $packageWithoutConstructor = "use " . $packageName . $qw . ";\n";
        return $packageWithoutConstructor;
    }

    my $packageWithoutConstructor = "use " . $packageName . ";\n";
    return $packageWithoutConstructor;
}

sub PT::QW::X {
    my ($class, $className) = @_;

    my @functionList = $class->{FunctionList}->X($className);
    my $qw = " qw(";
    my $funcitonList = join(" ", @functionList);
    $qw .= $funcitonList . ")";
}

sub PT::FunctionList::X {
    my ($class, $className) = @_;

    my @functionList;
    for my $element ( @{ $class->{FunctionName}} ) {
        push @functionList, $element->X($className);
    }

    return @functionList;
}

sub PT::Constructor::X {
    my ($class, $className) = @_;

    my $constructor = $class->{''};
    return $constructor;
}

sub PT::Object::X {
    my ($class, $className) = @_;

    my $object = $class->{''};
    return $object;
}

sub PT::PackageDir::X {
    my ($class, $className) = @_;

    my $packageDir = $class->{''};
    return $packageDir;
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
    my $codeBlock = $class->{CodeBlock}->X($className, $functionName);

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
    my ($class, $className, $functionName) = @_;
    my $blocks = $class->{Blocks}->X($className, $functionName);
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
    my ($class, $className, $functionName) = @_;
    my @blocks;

    for my $element ( @{$class->{Block}} ) {
        push @blocks, $element->X($className, $functionName);
    }

    my $blocks = join("\n", @blocks);
    return $blocks;
}

sub PT::Block::X {
    my ($class, $className, $functionName) = @_;

    my $block = (      $class->{IfElse}
                    || $class->{While}
                    || $class->{ForEach}
                    || $class->{ArrayEach}
                    || $class->{HashEach}
                    || $class->{For}
                    || $class->{RegexMatch}
                    || $class->{TryCatch}
                    || $class->{EmbedBlock}
                    || $class->{Comment}
                    || $class->{Statement}
                    || $class->{Packages}
                    || $class->{NonSyntaxFunction} )->X($className, $functionName);
    return $block;
}

sub PT::RegexMatch::X {
    my ($class, $className) = @_;

    my $pattern = $class->{Pattern}->X($className);
    my $matchString = $class->{MatchString}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $regexMatch = "if(" . $matchString . " =~ " . $pattern . ")" . $codeBlock;
    return $regexMatch;
}

sub PT::Pattern::X {
    my ($class, $className) = @_;

    my $pattern = $class->{VariableName}->X($className);
    return $pattern;
}

sub PT::MatchString::X {
    my ($class, $className) = @_;

    my $matchString = $class->{VariableName}->X($className);
    return $matchString;
}

sub PT::TryCatch::X {
    my ($class, $className) = @_;

    my $codeBlock = $class->{CodeBlock}->X($className);
    if(exists $class->{CatchBlock}) {
        my $catchBlock = $class->{CatchBlock}->X($className);
        my $tryCatch = "try " . $codeBlock . $catchBlock . ";";
        return $tryCatch;
    } else {
        my $tryCatch = "try {\n " . $codeBlock . "\n}";
        return $tryCatch;
    }
}

sub PT::CatchBlock::X {
    my ($class, $className) = @_;

    my $codeBlock = $class->{CodeBlock}->X($className);
    my @codeBlock = split(" ", $codeBlock);
    shift(@codeBlock);
    my $catchBlock = " catch {\n my \$error = \$_;\n " . join(" ", @codeBlock);

    return $catchBlock;
}

sub PT::NonSyntaxFunction::X {
    my ($class, $className, $functionName) = @_;
    my $nonSyntax = $class->{''};

    my @nonSyntax = split(" ", $nonSyntax);
    $nonSyntax = $nonSyntax[0];

    print "SyntaxError", "\n";
    print "===========", "\n";
    print "ClassName: ", $className, "\n";

    if(defined $functionName) {
    	print "FunctionName: ", $functionName, "\n";
    }

    die "Error: $nonSyntax \n";
}

sub PT::EmbedBlock::X {
    my ($class, $className) = @_;

    my $embedBlock = $class->{EmbedCodeBlock}->X($className);
    return $embedBlock;
}

sub PT::EmbedCodeBlock::X {
    my ($class, $className) = @_;

    my $embedCode = $class->{EmbeddedCode}->X($className);
    return $embedCode;
}

sub PT::EmbeddedCode::X {
    my ($class, $className) = @_;

    my $embedCode = $class->{''};
    return $embedCode;
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

    my $forEachVariableName = $class->{VariableName}->X($className);
    my @forRange = $class->{ForRange}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $forEach = "\n foreach my " . $forEachVariableName . " ( " . $forRange[0]
                  . " ... " . $forRange[1] . " ) " . $codeBlock;

    return $forEach;
}

sub PT::ForEachVariableName::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    return $variableName;
}

sub PT::ArrayEach::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    my $arrayEachVariableName = $class->{ArrayEachVariableName}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $arrayEach = "\n foreach my " . $arrayEachVariableName . "( \@{" . $variableName . "})" . $codeBlock;
    return $arrayEach;
}

sub PT::ArrayEachVariableName::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    return $variableName;
}

sub PT::HashEach::X {
    my ($class, $className) = @_;

    my $variableName = $class->{VariableName}->X($className);
    my $hashEachKey = $class->{HashEachKey}->X($className);
    my $hashEachValue = $class->{HashEachValue}->X($className);
    my $codeBlock = $class->{CodeBlock}->X($className);

    my $hashEach = "\n keys %{" . $variableName . "};\n while(my (" . $hashEachKey 
                   . ", " . $hashEachValue . ") = each %{ " . $variableName . " }) " . $codeBlock;

    return $hashEach;
}

sub PT::HashEachKey::X {
    my ($class, $className) = @_;

    my $hashEachKey = $class->{VariableName}->X($className);
    return $hashEachKey;
}

sub PT::HashEachValue::X {
    my ($class, $className) = @_;

    my $hashEachValue = $class->{VariableName}->X($className);
    return $hashEachValue;
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
                    || $class->{HashElement}
                    || $class->{ClassAccessor}
                    || $class->{ClassFunctionReturn}
                    || $class->{FunctionReturn} )->X($className);

    return $number;
}

sub PT::UpperRange::X {
    my ($class, $className) = @_;

    my $number = (     $class->{Number}
                    || $class->{VariableName}
                    || $class->{ArrayElement}
                    || $class->{HashElement}
                    || $class->{ClassAccessor}
                    || $class->{ClassFunctionReturn}
                    || $class->{FunctionReturn} )->X($className);

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
    my @booleanExpressions;

    for my $element ( @{ $class->{BooleanExpression}} ) {
        push @booleanExpressions, $element->X($className);
    }

    my @boolOperators;

    for my $element (@{ $class->{BoolOperator} }) {
        push @boolOperators, $element->X($className);
    }

    my $boolExpression = $booleanExpressions[0];
    for my $counter (1 .. $#booleanExpressions) {
        $boolExpression .= $boolOperators[$counter - 1] . " " . $booleanExpressions[$counter];
    }

    return $boolExpression;
}

sub PT::BooleanExpression::X {
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
    return (       $class->{GreaterThan}
                || $class->{LessThan}
                || $class->{Equals}
                || $class->{GreaterThanEquals}
                || $class->{LessThanEquals}
                || $class->{StringEquals}
                || $class->{StringNotEquals}
                || $class->{NotEqulas}
                || $class->{LogicalAnd}
                || $class->{LogicalOr}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::BoolOperands::X {
    my ($class, $className) = @_;
    return (       $class->{RealNumber}
                || $class->{String}
                || $class->{ScalarVariable}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{ClassAccessor}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{GroupAccess}
                || $class->{EmbedBlock} )->X($className);
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
                || $class->{Regex}
                || $class->{MakeGroup}
                || $class->{ClassFunctionCall}
                || $class->{FunctionReferenceCall}
                || $class->{Return}
                || $class->{Last}
                || $class->{Next}
                || $class->{ObjectCall} )->X($className);
}

sub PT::FunctionReferenceCall::X {
    my ($class, $className) = @_;

    my $functionName = $class->{FunctionName}->X($className);

    my $parametersList = "\$class";
    if(exists $class->{Parameters}) {
        my @parameters = @{$class->{Parameters}->X($className)};
        $parametersList = join(",", @parameters);
    }

    my $functionReferenceCall = "\&\$" . $functionName . "(" . $parametersList . ");";
    return $functionReferenceCall;
}

sub PT::Regex::X {
    my ($class, $className) = @_;
    
    my $regexVariable = $class->{RegexVariable}->X($className);
    my $regexp = $class->{Regexp}->X($className);
    my $modifiers = $class->{Modifiers}->X($className);

    my $regex = "my ". $regexVariable . " = qr{\n " . $regexp . "\n}" . $modifiers . ";";
    return $regex;
}

sub PT::RegexVariable::X {
    my ($class, $className) = @_;

    my $regexVariable = $class->{VariableName}->X($className);
    return $regexVariable;
}

sub PT::Regexp::X {
    my ($class, $className) = @_;

    my $regex = $class->{Pre}->X($className);
    return $regex;
}

sub PT::Pre::X {
    my ($class, $className) = @_;

    my $regex = $class->{''};
    return $regex;
}

sub PT::Modifiers::X {
    my ($class, $className) = @_;

    my $regexModifiers = $class->{RegexModifiers}->X($className);
    return $regexModifiers;
}

sub PT::RegexModifiers::X {
    my ($class, $className) = @_;

    my $regexModifiers = $class->{''};
    return $regexModifiers;
}

sub PT::ObjectCall::X {
        my ($class, $className) = @_;
        my $objectCall = "";

        $objectCall .= $class->{ObjectFunctionCall}->X($className);
        $objectCall .= ";\n";

        return $objectCall;
}

sub PT::VariableDeclaration::X {
    my ($class, $className) = @_;
    return (       $class->{ScalarDeclaration}
                || $class->{ArrayDeclaration}
                || $class->{HashDeclaration} )->X($className);
}

sub PT::GroupDeclaration::X {
    my ($class, $className) = @_;

    my $groupName = $class->{GroupName}->X($className);
    my @groupElements = $class->{GroupBlock}->X($className);

    $groupTable->{$groupName} = {};
    for my $element (@groupElements) {
        $groupTable->{$className}->{$groupName}->{$element} = "";
    }

    my $groupElementsList = "";
    foreach my $groupElement (@groupElements) {
        $groupElementsList .= $groupElement . " => '', ";
    }

    # my $groupElementsList = join(" => '', ", @groupElements);
    my $groupDeclaration = "my " . $groupName . " = {" . $groupElementsList . "};\n";

    return $groupDeclaration;
}

sub PT::GroupName::X {
    my ($class, $className) = @_;

    my $groupName = $class->{VariableName}->X($className);
    return $groupName;
}

sub PT::GroupBlock::X {
    my ($class, $className) = @_;

    my @groupElements = $class->{GroupElements}->X($className);
    return @groupElements;
}

sub PT::GroupElements::X {
    my ($class, $className) = @_;

    my @groupElements;
    for my $element ( @{ $class->{GroupElement} } ) {
        push @groupElements, $element->X($className);
    }

    return @groupElements;
}

sub PT::GroupElement::X {
    my ($class, $className) = @_;

    my $variableName = $class->{''};
    return $variableName;
}

sub PT::MakeGroup::X {
    my ($class, $className) = @_;

    my $groupName = $class->{GroupName}->X($className);
    my $groupNameObject = $class->{GroupNameObject}->X($className);
    my @groupElements = keys %{ $groupTable->{$className}->{$groupName} };

    # if(exists $groupTable->{groupNameObject}) {};

    my $makeGroup = "my " . $groupNameObject . " = {};\n" ;
    for my $groupElement (@groupElements) {
        $makeGroup .=  $groupNameObject . "->{" . $groupElement . "} = '';\n";
    }

    return $makeGroup;
}

sub PT::GroupNameObject::X {
    my ($class, $className) = @_;

    my $groupNameObject = $class->{VariableName}->X($className);
    return $groupNameObject;
}

sub PT::GroupReference::X {
    my ($class, $className) = @_;

    my $groupName = $class->{GroupName}->X($className);
    my $groupReference = $groupTable->{$groupName};

    return $groupReference;
}

sub PT::GroupAssignment::X {
    my ($class, $className) = @_;

    my $groupAccess = $class->{GroupAccess}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $groupAssignment = "if(exists(" . $groupAccess . ")){\n";
    $groupAssignment .= $groupAccess . " = " . $rhs . ";\n";
    $groupAssignment .= "\n}\n";

    return $groupAssignment;
}

sub PT::GroupAccess::X {
    my ($class, $className) = @_;

    my $groupName = $class->{GroupName}->X($className);

    my @groupAccessElements;
    for my $groupElement ( @{ $class->{GroupAccessElement} }) {
        push @groupAccessElements, $groupElement->X($className);
    }

    my $counter = 0;
    my $groupAccess = $groupName;

    #if(exists $groupTable->{$groupName}->{$groupAccessElements[0]}) {
        while( $counter <= $#groupAccessElements ) {
            $groupAccess .= "->{" . $groupAccessElements[$counter] . "}";
            $counter = $counter + 1;
        }
    #}

    return $groupAccess;
}

sub PT::GroupAccessElement::X {
    my ($class, $className) = @_;

    my $groupElement = $class->{GroupElement}->X($className);
    return $groupElement;
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

sub PT::RealNumber::X {
    my ($class, $className) = @_;
    my $realNumber = $class->{''};
    return $realNumber;
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
    return (       $class->{RealNumber}
                || $class->{String}
                || $class->{ArrayList}
                || $class->{HashRef}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{VariableName}
                || $class->{EmbedBlock} )->X($className);
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
                || $class->{String}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{VariableName}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::PairValue::X {
    my ($class, $className) = @_;
    return (       $class->{RealNumber}
                || $class->{String}
                || $class->{ArrayList}
                || $class->{HashRef}
                || $class->{VariableName}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::FunctionCall::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);

    my $functionCall = $functionName . "(" ;

    if(exists $class->{Parameters}) {
        my @parameters = @{$class->{Parameters}->X($className)};
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

    return \@parameters;
}

sub PT::Param::X {
    my ($class, $className) = @_;
    return (       $class->{RealNumber}
                || $class->{String}
                || $class->{VariableName}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{HashRef}
                || $class->{GroupAccess}
                || $class->{FunctionReturn}
                || $class->{ClassFunctionReturn}
                || $class->{EmbedBlock}
                || $class->{FunctionReference}
                || $class->{GroupAccess}
                || $class->{ClassFunctionReturn}
                || $class->{Calc}
                || $class->{ParamChars}
                || $class->{ObjectFunctionCall} )->X($className);
}

sub PT::ParamChars::X {
    my ($class, $className) = @_;
    my $paramChars = $class->{''};
    return $paramChars;
}

sub PT::Assignment::X {
    my ($class, $className) = @_;
    return (       $class->{ScalarAssignment}
                || $class->{ArrayAssignment}
                || $class->{GroupAssignment}
                || $class->{HashAssignment}
                || $class->{AccessorAssignment} )->X($className);
}

sub PT::AccessorAssignment::X {
    my ($class, $className) = @_;

    my $variableName = $class->{HashKeyStringValue}->X($className);
    my $rhs = $class->{RHS}->X($className);

    my $accessorAssignment  = '$class->{"' . $className . '"}->{"'. $variableName .'"} = ' . $rhs .';';
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

    return (       $class->{RealNumber}
                || $class->{FunctionReturn}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{ScalarVariable}
                || $class->{Calc}
                || $class->{RegexMatchVariables}
                || $class->{ArrayList}
                || $class->{HashRef}
                || $class->{GroupReference}
                || $class->{GroupElement}
                || $class->{GroupAccess}
                || $class->{FunctionReference}
                || $class->{ClassAccessor}
                || $class->{ClassFunctionReturn}
                || $class->{String}
                || $class->{STDIN}
                || $class->{ObjectFunctionCall}
                || $class->{EmbedBlock} )->X($className);
}

sub PT::RegexMatchVariables::X {
    my ($class, $className) = @_;

    my $matchVariable = $class->{MatchVariable}->X($className);
    my $regexMatchVariables = "";

    if( $matchVariable =~ /\d+/ ) {
        $regexMatchVariables = "\$" . $matchVariable;
    }

    if( $matchVariable eq "Match" ) {
        $regexMatchVariables = "\$" . "\&";
    }

    if( $matchVariable eq "PREMATCH" ) {
        $regexMatchVariables = "\$" . "\'";
    }

    if( $matchVariable eq "POSTMATCH" ) {
        $regexMatchVariables = "\$" . "\`";
    }

    return $regexMatchVariables;
}

sub PT::MatchVariable::X {
    my ($class, $className) = @_;

    return (        $class->{Number}
                 || $class->{MatchParts} )->X($className);
}

sub PT::MatchParts::X {
    my ($class, $className) = @_;
    return $class->{''};
}

sub PT::FunctionReference::X {
    my ($class, $className) = @_;

    my $functionName = $class->{FunctionName}->X($className);
    my $functionReference = "\\&" . $functionName;
    return $functionReference;
}

sub PT::STDIN::X {
    my ($class, $className) = @_;
    my $stdin = '<STDIN>';
    return $stdin;
}

sub PT::ObjectFunctionCall::X {
    my ($class, $className) = @_;

    my $object = $class->{Object}->X($className);
    my $functionName = $class->{FunctionName}->X($className);

    my $objectFunctionCall;
    if(exists $class->{Parameters}) {
        my @parameters = @{$class->{Parameters}->X($className)};
        my $parameters = join(",", @parameters);
        $objectFunctionCall = "\$" . $object . "->" . $functionName . "(" . $parameters . ")";
    } else {
        $objectFunctionCall = "\$" . $object . "->" . $functionName . "()";
    }

    return $objectFunctionCall;
}

sub PT::ClassAccessor::X {
    my ($class, $className) = @_;
    my $variableName = $class->{HashKeyStringValue}->X($className);

    my $classAccessor = '$class->{"' . $className . '"}->{"'. $variableName .'"}';
    return $classAccessor;
}

sub PT::ClassFunctionCall::X {
    my ($class, $className) = @_;
    my $functionName = $class->{FunctionName}->X($className);
    my @parameters;
    my $parameters = "";
    if(exists $class->{Parameters}) {
        @parameters = @{$class->{Parameters}->X($className)};
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
        @parameters = @{$class->{Parameters}->X($className)};
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
        my @parameters = @{$class->{Parameters}->X($className)};
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
    my $number = $class->{ArrayKey}->X($className);
    return $number;
}

sub PT::ArrayKey::X {
    my ($class, $className) = @_;
    return (       $class->{Number}
                || $class->{ScalarVariable}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{FunctionReturn}
                || $class->{ClassFunctionReturn} )->X($className);
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
    return (       $class->{String}
                || $class->{Number}
                || $class->{ScalarVariable}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{FunctionReturn}
                || $class->{ClassFunctionReturn} )->X($className);
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
    for my $counter (1 .. $#calcOperands) {
        $calcExpression .= $calcOperator[$counter - 1] . " " . $calcOperands[$counter];
    }

    return $calcExpression;
}

sub PT::CalcOperands::X {
    my ($class, $className) = @_;
    return (       $class->{RealNumber}
                || $class->{ScalarVariable}
                || $class->{ArrayElement}
                || $class->{HashElement}
                || $class->{ClassAccessor}
                || $class->{ClassFunctionReturn}
                || $class->{FunctionReturn}
                || $class->{EmbedBlock}
                || $class->{ObjectFunctionCall} )->X($className);
}

sub PT::CalcOperator::X {
    my ($class, $className) = @_;
    return (       $class->{Plus}
                || $class->{Minus}
                || $class->{Multiply}
                || $class->{Divide}
                || $class->{EmbedBlock} )->X($className);
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

sub PT::Modulus::X {
    my ($class, $className) = @_;
    my $divide = $class->{''};
    return $divide;
}

sub PT::Exponent::X {
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

sub PT::TokenImplement::X {
    my ($class, $className) = @_;
    my $tokenImplement = $class->{''};
    return $tokenImplement;
}

sub PT::TokenTry::X {
    my ($class, $className) = @_;
    my $tokenTry = $class->{''};
    return $tokenTry;
}

sub PT::TokenCatch::X {
    my ($class, $className) = @_;
    my $tokenCatch = $class->{''};
    return $tokenCatch;
}

sub PT::TokenError::X {
    my ($class, $className) = @_;
    my $tokenError = $class->{''};
    return $tokenError;
}

sub PT::EachSymbol::X {
    my ($class, $className) = @_;
    my $eachSymbol = $class->{''};
    return $eachSymbol;
}

sub PT::LBrace::X {
    my ($class, $className) = @_;
    my $lBrace = $class->{''};
    return $lBrace;
}

sub PT::LBraceError::X {
    my ($class, $className) = @_;
    my $lBraceError = $class->{''};

    print "SyntaxError", "\n";
    print "===========", "\n";
    die "Missing { after className '", $className, "', instead found ", $lBraceError, "\n";
}

sub PT::RBrace::X {
    my ($class, $className) = @_;
    my $rBrace = $class->{''};
    return $rBrace;
}

sub PT::RBraceError::X {
    my ($class, $className) = @_;
    my $rBraceError = $class->{''};

    print "SyntaxError", "\n";
    print "===========", "\n";
    die "Missing } after class '", $className, "', instead found ", $rBraceError, "\n";
}

my $parser = qr {
    <nocontext:>
    # <debug: on>

    <Lang>
    <objrule:  PT::Lang>                       <[Class]>+

    <objrule:  PT::Class>                      <ws: (\s++)*> <TokenClass> <ClassName> <ClassBlock>
    <objrule:  PT::ClassName>                  [a-zA-Z]+?

    <objrule:  PT::ClassBlock>                 <ErrorLBrace> <ClassGroups> <ErrorRBrace>
    <objrule:  PT::ErrorLBrace>                <LBrace> | <LBraceError>
    <objrule:  PT::ErrorRBrace>                <RBrace> | <RBraceError>

    <objrule:  PT::ClassGroups>                <[Group]>+
    <objrule:  PT::Group>                      <Comment> | <Parent> | <Packages> | <EmbedBlock> | <GroupDeclaration>
                                               | <ImplementFunction> | <Function> | <NonSyntaxClass>

    <objtoken: PT::NonSyntaxClass>             \b.*\b

    <objrule:  PT::ImplementFunction>          <TokenImplement> <TokenFunction> <FunctionName> <LParen> <FunctionParamList> <RParen> <LBrace> <MultiLineComment>? <RBrace>
    <objrule:  PT::MultiLineComment>           <MLCommentBegin> <MLComment> <MLCommentEnd>
    <objtoken: PT::MLCommentBegin>             \/\*
    <objtoken: PT::MLCommentEnd>               \*\/
    <objrule:  PT::MLComment>                  (?<=\/\*)\s*.*?\s*(?=\*\/)

    <objrule:  PT::Comment>                    [#] <LineComment> @
    <objtoken: PT::LineComment>                .*?

    <objrule:  PT::Parent>                     <TokenParent> <LParen> <ClassNames> <RParen> <SemiColon>
    <objrule:  PT::ClassNames>                 <[ClassName]>+ % <Comma>

    <objrule:  PT::Packages>                   <LParen> <PackageList> <RParen> <SemiColon>
    <objrule:  PT::PackageList>                <[Package]>+ % <Comma>
    <objrule:  PT::Package>                    <PackageWithConstructor> | <PackageWithoutConstructor>
    <objrule:  PT::PackageWithConstructor>     [!] <Object> <Equal> <PackageName> <Dot> <Constructor> <LParen> <ObjectParameters>? <RParen>
    <objrule:  PT::ObjectParameters>           <PackageParams> | <Parameters>
    <objrule:  PT::PackageParams>              <[KeyValue]>+ % <Comma>
    <objrule:  PT::PackageName>                <[PackageDir]>+ % (::)
    <objrule:  PT::PackageWithoutConstructor>  <PackageName> <QW>?
    <objrule:  PT::QW>                         <Dot> <LParen> <FunctionList> <RParen>
    <objrule:  PT::FunctionList>               <[FunctionName]>+ % <Comma>
    <objrule:  PT::Constructor>                [a-zA-Z]+?
    <objrule:  PT::Object>                     [a-zA-Z]+?
    <objrule:  PT::PackageDir>                 [a-zA-Z]+?

    <objrule:  PT::Function>                   <TokenFunction> <FunctionName> <LParen> <FunctionParamList> <RParen> <CodeBlock>
    <objtoken: PT::FunctionName>               [a-zA-Z_]+?

    <objrule:  PT::FunctionParamList>          <EmptyParamList> | <FunctionParams>
    <objtoken: PT::EmptyParamList>             .{0}
    <objrule:  PT::FunctionParams>             <[Arg]>+ % <Comma>
    <objrule:  PT::Arg>                        [a-zA-Z]+?

    <objrule:  PT::CodeBlock>                  <LBrace> <Blocks> <RBrace>
    <objrule:  PT::Blocks>                     <[Block]>+

    <objrule:  PT::Block>                      <IfElse> | <While> | <ForEach> | <For> | <ArrayEach> | <HashEach> | <EmbedBlock>
                                               | <Comment> | <Statement> | <TryCatch> | <RegexMatch> | <Packages> | <NonSyntaxFunction>

    <objtoken: PT::NonSyntaxFunction>          \b.*\b

    <objrule:  PT::TryCatch>                   <TokenTry> <CodeBlock> <CatchBlock>?
    <objrule:  PT::CatchBlock>                 <TokenCatch> <LParen> <TokenError> <RParen> <CodeBlock>

    <objrule:  PT::EmbedBlock>                 <TokenEmbedBlock> <EmbedCodeBlock>
    <objrule:  PT::EmbedCodeBlock>             <EmbedBegin> <EmbeddedCode> <EmbedEnd>
    <objrule:  PT::EmbedBegin>                 <LParen>\?
    <objrule:  PT::EmbedEnd>                   \?<RParen>
    <objrule:  PT::EmbeddedCode>               (?<=\(\?)\s*.*?\s*(?=\?\))

    <objrule:  PT::While>                      <TokenWhile> <LParen> <BoolExpression> <RParen> <CodeBlock>

    <objrule:  PT::ForEach>                    <TokenForeach> <LParen> <ForRange> <RParen> <EachSymbol> <VariableName> <CodeBlock>

    <objrule:  PT::ArrayEach>                  <TokenArrayEach> <LParen> <VariableName> <RParen> <EachSymbol> <ArrayEachVariableName> <CodeBlock>
    <objrule:  PT::ArrayEachVariableName>      <VariableName>

    <objrule:  PT::HashEach>                   <TokenHashEach> <LParen> <VariableName> <RParen> <EachSymbol> <LParen> <HashEachKey> <Comma> <HashEachValue> <RParen> <CodeBlock>
    <objrule:  PT::HashEachKey>                <VariableName>
    <objrule:  PT::HashEachValue>              <VariableName>

    <objrule:  PT::For>                        <TokenFor> <Var> <VariableName> <LParen> <ForRange> <RParen> <CodeBlock>
    <objrule:  PT::ForRange>                   <LowerRange> <Dot><Dot><Dot> <UpperRange>

    <objrule:  PT::LowerRange>                 <Number> | <VariableName> | <ArrayElement> | <HashElement>
                                                | <ClassAccessor> | <ClassFunctionReturn> | <FunctionReturn>

    <objrule:  PT::UpperRange>                 <Number> | <VariableName> | <ArrayElement> | <HashElement>
                                                | <ClassAccessor> | <ClassFunctionReturn> | <FunctionReturn>

    <objrule:  PT::RegexMatch>                 <TokenMatchRegex> <LParen> <Pattern> <RegexMatchSymbol> <MatchString> <RParen> <CodeBlock>
    <objrule:  PT::Pattern>                    <VariableName>
    <objrule:  PT::MatchString>                <VariableName>

    <objrule:  PT::IfElse>                     <If> <ElsIf>? <Else>?
    <objrule:  PT::If>                         <TokenIf> <LParen> <BoolExpression> <RParen> <CodeBlock>

    <objrule:  PT::BoolExpression>             <[BooleanExpression]>+ % <[BoolOperator]>
    <objrule:  PT::BooleanExpression>          <BoolOperands> <BoolOperatorExpression>?
    <objrule:  PT::BoolOperatorExpression>     <BoolOperator> <BoolOperands>

    <objrule:  PT::BoolOperands>               <RealNumber> | <String> | <ScalarVariable> | <ArrayElement> | <HashElement>
                                               | <ClassAccessor> | <ClassFunctionReturn> | <FunctionReturn> | <GroupAccess> | <EmbedBlock>

    <objrule:  PT::BoolOperator>               <GreaterThan> | <LessThan> | <Equals> | <GreaterThanEquals> | <LessThanEquals>
                                               | <StringEquals> | <StringNotEquals> | <NotEqulas> | <LogicalAnd> | <LogicalOr>
                                               | <EmbedBlock>

    <objrule:  PT::ElsIf>                      <[ElsIfChain]>+
    <objrule:  PT::ElsIfChain>                 <TokenElsIf> <LParen> <BoolExpression> <RParen> <CodeBlock>
    <objrule:  PT::Else>                       <TokenElse> <CodeBlock>

    <objrule:  PT::Statement>                  <FunctionReferenceCall> | <VariableDeclaration> | <Regex> | <MakeGroup> | <FunctionCall> 
                                               | <ClassFunctionCall> | <ObjectCall> | <Assignment> | <Return> | <Last> | <Next>

    <objrule:  PT::Regex>                      <TokenMakeRegex> <LParen> <RegexVariable> <Comma> <Regexp> <Comma> <Modifiers> <RParen> <SemiColon>
    <objrule:  PT::RegexVariable>              <VariableName>
    <objrule:  PT::Regexp>                     <BackSlash> <Pre> <BackSlash>
    <objrule:  PT::Pre>                        (?<=\/)\s*.*?\s*(?=\/\,)
    <objrule:  PT::Modifiers>                  <LParen> <RegexModifiers> <RParen>
    <objtoken: PT::RegexModifiers>             [nmasdilxpu]+

    <objrule:  PT::ClassFunctionCall>          <TokenClass> <Dot> <FunctionName> <LParen> <Parameters>? <RParen> <SemiColon>

    <objrule:  PT::ObjectCall>                 <ObjectFunctionCall> <SemiColon>
    <objrule:  PT::VariableDeclaration>        <ArrayDeclaration> | <HashDeclaration> | <ScalarDeclaration>

    <objrule:  PT::GroupDeclaration>           <TokenGroup> <GroupName> <GroupBlock> <SemiColon>
    <objtoken: PT::GroupName>                  <VariableName>
    <objrule:  PT::GroupBlock>                 <LessThan> <GroupElements> <GreaterThan>
    <objrule:  PT::GroupElements>              <[GroupElement]>+ % <Comma>
    <objrule:  PT::GroupElement>               [A-Za-z]+

    <objrule:  PT::MakeGroup>                  <TokenMakeGroup> <LParen> <GroupName> <Comma> <GroupNameObject> <RParen> <SemiColon>
    <objrule:  PT::GroupNameObject>            <VariableName>
    <objrule:  PT::GroupReference>             <TokenGroupReference> <GroupName>

    <objrule:  PT::GroupAssignment>            <GroupAccess> <Equal> <RHS> <SemiColon>
    <objrule:  PT::GroupAccess>                <GroupName> <[GroupAccessElement]>+
    <objrule:  PT::GroupAccessElement>         <LessThan> <GroupElement> <GreaterThan>

    <objrule:  PT::ScalarDeclaration>          <Var> <VariableName> <Equal> <Value> <SemiColon>
    <objtoken: PT::Var>                        var
    <objtoken: PT::VariableName>               [a-zA-Z_]+?
    <objrule:  PT::Value>                      <RHS>
    <objtoken: PT::Number>                     [0-9]+
    <objtoken: PT::RealNumber>                 [-]?[0-9]+\.?[0-9]+|[0-9]+
    <objrule:  PT::String>                     <LQuote> <StringValue> <RQuote>
    <objrule:  PT::LQuote>                     <Quote>
    <objrule:  PT::RQuote>                     <Quote>
    <objtoken: PT::StringValue>                (?<=")\s*.*?\s*(?=")

    <objrule:  PT::ArrayDeclaration>           <Var> <VariableName> <Equal> <ArrayList> <SemiColon>
    <objrule:  PT::ArrayList>                  <LBracket> <ListElements> <RBracket>
    <objrule:  PT::ListElements>               .{0} | <[ListElement]>+ % <Comma>

    <objrule:  PT::ListElement>                <RealNumber> | <String> | <ClassFunctionReturn> | <FunctionReturn>
                                                | <ArrayElement> | <HashElement> | <ArrayList> | <HashRef>
                                                | <VariableName> | <EmbedBlock>

    <objrule:  PT::HashDeclaration>            <Var> <VariableName> <Equal> <HashRef> <SemiColon>
    <objrule:  PT::HashRef>                    <LBrace> <KeyValuePairs> <RBrace>
    <objrule:  PT::KeyValuePairs>              .{0} | <[KeyValue]>+ % <Comma>
    <objrule:  PT::KeyValue>                   <PairKey> <Colon> <PairValue>

    <objrule:  PT::PairKey>                    <Number> | <String> | <ClassFunctionReturn> | <FunctionReturn>
                                                | <VariableName> | <EmbedBlock>

    <objrule:  PT::PairValue>                  <RealNumber> | <String> | <ClassFunctionReturn> | <FunctionReturn>
                                                | <ArrayElement> | <HashElement> | <ArrayList> | <HashRef>
                                                | <VariableName> | <EmbedBlock>

    <objrule:  PT::FunctionCall>               <FunctionName> <LParen> <Parameters>? <RParen> <SemiColon>
    <objrule:  PT::Parameters>                 <[Param]>+ % <Comma>
    <objrule:  PT::Param>                      <RealNumber> | <String> | <VariableName> | <ArrayElement> | <HashElement>
                                               | <HashRef> | <FunctionReturn> | <ClassFunctionReturn> | <GroupAccess> | <EmbedBlock>
                                               | <FunctionReference> | <GroupAccess> | <ClassFunctionReturn> | <Calc> | <ParamChars> | <ObjectFunctionCall>

    <objtoken: PT::ParamChars>                 [A-Za-z]+

    <objrule:  PT::Assignment>                 <ScalarAssignment> | <ArrayAssignment> | <HashAssignment> | <AccessorAssignment> | <GroupAssignment>

    <objrule:  PT::ScalarAssignment>           <ScalarVariable> <Equal> <RHS> <SemiColon>
    <objtoken: PT::ScalarVariable>             [a-zA-Z]+

    <objrule:  PT::RHS>                        <RealNumber> | <FunctionReference> | <FunctionReturn> | <ArrayElement> | <HashElement>
                                               | <ScalarVariable> | <Calc> | <ArrayList> | <HashRef> | <ClassAccessor>
                                               | <GroupElement> | <GroupReference> | <MakeGroup> | <GroupAccess> | <ClassFunctionReturn>
                                               | <String> | <STDIN> | <RegexMatchVariables> | <ObjectFunctionCall> | <EmbedBlock>

    <objrule:  PT::RegexMatchVariables>        <RegexMatchSymbol> <MatchVariable>
    <objrule:  PT::MatchVariable>              <Number> | <MatchParts>
    <objtoken: PT::MatchParts>                 PREMATCH|MATCH|POSTMATCH

    <objrule:  PT::FunctionReference>          <TokenReference> <TokenClass> <Dot> <FunctionName> <LParen> <RParen>
    <objrule:  PT::FunctionReferenceCall>      <TokenReferenceCall> <FunctionName> <LParen> <Parameters>? <RParen> <SemiColon>

    <objrule:  PT::FunctionReturn>             <FunctionName> <LParen> <Parameters>? <RParen>

    <objrule:  PT::ArrayElement>               <ArrayName> <[ArrayAccess]>+
    <objrule:  PT::ArrayAccess>                <LBracket> <ArrayKey> <RBracket>
    <objrule:  PT::ArrayKey>                   <Number> | <ScalarVariable> | <ArrayElement>
                                               | <HashElement> | <FunctionReturn> | <ClassFunctionReturn>
    <objrule:  PT::ArrayName>                  [a-zA-Z]+?

    <objrule:  PT::HashElement>                <HashName> <[HashAccess]>+
    <objrule:  PT::HashAccess>                 <LBrace> <HashKey> <RBrace>
    <objtoken: PT::HashName>                   [a-zA-Z]+?
    <objrule:  PT::HashKey>                    <String> | <Number> | <ScalarVariable> | <ArrayElement>
                                               | <HashElement> | <FunctionReturn> | <ClassFunctionReturn>

    <objrule:  PT::STDIN>                      <LessThan> <TokenSTDIN> <GreaterThan>

    <objtoken: PT::HashKeyStringValue>         [a-zA-Z]+?
    <objrule:  PT::AccessorAssignment>         <TokenClass> <Dot> <HashKeyStringValue> <Equal> <RHS> <SemiColon>
    <objrule:  PT::ClassAccessor>              <TokenClass> <Dot> <HashKeyStringValue>
    <objrule:  PT::ClassFunctionReturn>        <TokenClass> <Dot> <FunctionName> <LParen> <Parameters>? <RParen>

    <objrule:  PT::ArrayAssignment>            <ArrayElement> <Equal> <RHS> <SemiColon>
    <objrule:  PT::HashAssignment>             <HashElement> <Equal> <RHS> <SemiColon>

    <objrule:  PT::Calc>                       <CalcExpression>
    <objrule:  PT::CalcExpression>             <[CalcOperands]>+ % <[CalcOperator]>
    <objrule:  PT::CalcOperands>               <RealNumber> | <ScalarVariable> | <ArrayElement> | <HashElement> | <ClassAccessor>
                                               | <ClassFunctionReturn> | <FunctionReturn> | <EmbedBlock> | <ObjectFunctionCall>

    <objtoken: PT::CalcOperator>               <Plus> | <Minus> | <Multiply> | <Divide> | <Modulus> | <Exponent> | <EmbedBlock>

    <objrule:  PT::Return>                     <TokenReturn> <RHS>? <SemiColon>
    <objrule:  PT::Last>                       <TokenLast> <SemiColon>
    <objrule:  PT::Next>                       <TokenNext> <SemiColon>

    <objrule:  PT::ObjectFunctionCall>         [!] <Object> <Dot> <FunctionName> <LParen> <Parameters>? <RParen>

    <objtoken: PT::TokenReturn>                return
    <objtoken: PT::TokenNext>                  next
    <objtoken: PT::TokenLast>                  last
    <objtoken: PT::TokenElse>                  else
    <objtoken: PT::TokenElsIf>                 elsif
    <objtoken: PT::TokenIf>                    if
    <objtoken: PT::TokenFor>                   for
    <objtoken: PT::TokenForeach>               forEach
    <objtoken: PT::TokenWhile>                 while
    <objtoken: PT::TokenFunction>              function
    <objtoken: PT::TokenParent>                parent
    <objtoken: PT::TokenClass>                 class
    <objtoken: PT::TokenEmbedBlock>            embed
    <objtoken: PT::TokenSTDIN>                 STDIN
    <objtoken: PT::TokenNot>                   not
    <objtoken: PT::TokenArrayEach>             arrayEach
    <objtoken: PT::TokenHashEach>              hashEach
    <objtoken: PT::TokenImplement>             implement
    <objtoken: PT::TokenTry>                   try
    <objtoken: PT::TokenCatch>                 catch
    <objtoken: PT::TokenError>                 error
    <objtoken: PT::TokenMakeRegex>             makeRegex
    <objtoken: PT::TokenMatchRegex>            matchRegex
    <objtoken: PT::TokenReference>             reference
    <objtoken: PT::TokenReferenceCall>         referenceCall
    <objtoken: PT::TokenGroup>                 group
    <objtoken: PT::TokenMakeGroup>             makeGroup
    <objtoken: PT::TokenGroupReference>        groupReference

    <objtoken: PT::BackSlash>                  \/
    <objtoken: PT::RegexMatchSymbol>           \@
    <objtoken: PT::EachSymbol>                 =\>
    <objtoken: PT::Ampersand>                  \&
    <objtoken: PT::Asterisk>                   \*
    <objtoken: PT::Modulus>                    \%
    <objtoken: PT::Exponent>                   \*\*
    <objtoken: PT::LogicalAnd>                 \&\&
    <objtoken: PT::LogicalOr>                  \|\|
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
    <objtoken: PT::LBraceError>                \s.
    <objtoken: PT::RBrace>                     \}
    <objtoken: PT::RBraceError>                \s*.
    <objtoken: PT::LBracket>                   \[
    <objtoken: PT::RBracket>                   \]
}xms;

sub parse {
    my ($class, $program) = @_;
    if($program =~ $parser) {
        my $code = $/{Lang}->X();
        return $code;
    } else {
        my $notMatch = "print 'Error';";
        return $notMatch;
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

    class Main {
    	(JSON,
    	 !mechanize = WWW::Mechanize.new());

    	function main() {
    		class.counter = 0;

    		var hash = class.returnNumber();
    		var json = encode_json(hash);
    		print(json, "\n");

    		var url = "https://metacpan.org/pod/WWW::Mechanize";
    		!mechanize.get(url);
    		var page = !mechanize.text();
    		print(page, "\n");
    	}

    	function returnNumber() {
    		var number = {};

    		if(class.counter < 10) {
    			class.counter = class.counter + 1;

    			number = { "number" : class.returnNumber() };
    			return number;
    		}

    		return class.counter;
    	}
    }

=head1 AUTHOR

Rajkumar Reddy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Rajkumar Reddy. All rights reserved.


=cut
