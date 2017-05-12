package Language::Tea::JavaEmitter;

use strict;
use warnings;
use Symbol;
use Language::Tea::Traverse;
use Scalar::Util qw(blessed);
use IPC::Open2;

our $IF_CONDITION_COUNTER = 0;
# This variable is used in the conversion of tdbc.TCallableStatement
our @registeredOuts;

our @functions;
our %methods;
our $compFunction;

# Hash used for type conversion
# In case you want to substitute a Tea type for a Java type, just add here
our %typeConversion = (
    "TFileInput"  => "BufferedReader",
    "TFileOutput" => "BufferedWriter",
    "TUrlInput"   => "BufferedReader",
    "TConnection"   => "Connection",
    "TDate"   => "java.util.Date",
    "THashtable" => "java.util.Hashtable",
    "TVector" => "java.util.Vector"
);

# Hash used for method name conversion
# In case you want to substitute a Tea method for a Java method, just add here
our %methodConvertion = ( "readln" => "readLine",
        "writeln" => "write",
        "autocommit" => "setAutoCommit",
        "prepare"    => "prepareStatement",
        "statement"  => "createStatement",
        "update"  => "executeUpdate",
        "query"  => "executeQuery",
        "connect"  => "tdbcConnect",
        "getColumnCount"  => "getMetaData().getColumnCount",
        "getColumnName"  => "getMetaData().getColumnName",
        "hasMoreRows"  => "isLast",
        "skip"  => "relative",
        "getDayOfWeek"  => "getDay",
        "getDay"  => "getDate",
        "getHour"  => "getHours",
        "getMinute"  => "getMinutes",
        "getSecond"  => "getSeconds",
         "isKey" => "containsKey",
         "getSize" => "size",
         "getAt" => "get",
         "push" => "add",
         "resize" => "setSize",
        );

sub emit {
    my ( $root, $package ) = @_;
    return Language::Tea::Traverse::visit_postfix(
        $root,
        sub {
            my ($node) = @_;
            for ( ref $node ) {
                /^TeaPart::Comment$/ && do {
                    return '   // '
                      . $node->{comment_text}
                      . ( $node->{context}{liner} ? "\n" : "" );
                };
                /^TeaPart::arg_symbol$/ && do {
                    my $name = $node->{mangled};
                    $name ||= $node->{arg_symbol};
                    return $name . eol($node);
                };
                /^TeaPart::definition_list$/ && do {
                    return $node->{arg};
                };
                /^TeaPart::arg_list$/ && do {
                    return '('
                      . ( join ', ', @{ $node->{arg_list} } ) . ')'
                      . eol($node);
                };
                /^TeaPart::arg_string$/ && do {
                    return '"' . $node->{arg_string} . '"' . eol($node);
                };
                /^TeaPart::arg_substitution$/ && do {
                    return $node->{arg_substitution} . eol($node);
                };
                /^TeaPart::arg_integer$/ && do {
                    return 'new Integer('
                      . $node->{arg_integer} . ')'
                      . eol($node);
                };
                /^TeaPart::arg_double$/ && do {
                    return 'new Double('
                      . $node->{arg_double} . ')'
                      . eol($node);
                };
                /^TeaPart::arg_code$/ && do {
                    return "{\n"
                      . ( join "", @{ $node->{arg_code}{statement} } ) . "}\n";
                };
                /^TeaPart::arg_do$/ && do {
                    return "("
                      . $node->{arg_do}{statement}[0] . ")"
                      . eol($node);
                };
                /^TeaPart::Define$/ && do {
                    my $type = $node->{type} || 'TeaUnkownType';
                    $type = $typeConversion{$type}
                      if defined $typeConversion{$type};
                    my $val = $node->{statement}[0];
                    $val =~ s/\(\)$//g;
                    if ( blessed $val || !ref $val ) {
                        $val = ' = ' . $val;
                    }
                    else {
                        $val = '';
                    }
                    
                    return $type . ' '
                      . $node->{mangled}
                      . $val
                      . eol($node);  
                };
                /^TeaPart::DefineFunc$/ && do {

                    # the code is not here, it's saved on the top level entity.
                    my $type = $node->{type} || 'TeaUnknownType';
                    
                    unless ( $node->{arg_code}{statement}[0] && 
                            ref $node->{arg_code}{statement}[0] ne 'HASH') { 
                    # This is not a function. This is a List
                        my $listCode = "Vector $node->{arg_symbol} = new Vector();";
                            for (@{$node->{arg_list}}) {
                                $listCode .= "$node->{arg_symbol}.add($_);";
                            }
                        return $listCode;
                    }

                    my $code = 'public static ' . $type . ' '
                      . $node->{arg_symbol} . "(";
                      
                    $code .=  join( ", ", @{ $node->{arg_list} } ) if ref $node->{arg_list} eq 'ARRAY';
                    $code .= ")" . "{\n";
                    
                    $code .= ( join "", @{ $node->{arg_code}{statement} } ) if @{ $node->{arg_code}{statement} };
                    $code .= "}\n";


                    push @functions , $code;                

                    return ' ';
                };
                
                /^TeaPart::Global$/ && do {
                    my $type = $node->{type} || 'TeaUnkownType';
                    $type = $typeConversion{$type}
                      if defined $typeConversion{$type};
                    my $val = $node->{statement}[0];
                    if ( blessed $val || !ref $val ) {
                        $val = ' = ' . $val;
                    }
                    else {
                        $val = '';
                    }
                    return 'public static '.$type . ' '
                      . $node->{mangled}
                      . $val
                      . eol($node);
                };
                /^TeaPart::GlobalFunc$/ && do {

                    # the code is not here, it's saved on the top level entity.
                    my $type = $node->{type} || 'TeaUnknownType';

                    my $code =
                        'public static ' . $type . ' '
                      . $node->{arg_symbol} . "("
                      . join( ", ", @{ $node->{arg_list} } ) . ")" . "{\n"
                      . ( join "", @{ $node->{arg_code}{statement} } ) . "}\n";
                    my $walker = $node;
                    while (( ref($walker) ne 'TeaProgram' )
                        && ( ref($walker) ne 'TeaPart::Method' ) )
                    {
                        $walker = $walker->{__node_parent__};
                    }
                    $walker->{functions} ||= [];
                    push @{ $walker->{functions} }, $code;

                    #return ' ';
                    return $code;
                };


                /^TeaPart::Apply$/ && do {
                    my $ereturn = "";
                    $ereturn = "return " if $node->{context}{ireturn};
                    return $ereturn.Language::Tea::Function::emit_java($node)
                      . eol($node);
                };
                /^TeaPart::If$/ && do {
                    my $comment = '';
                    $comment = $node->{comment} . "\n" if $node->{comment};
                    return $comment . "if ("
                      . $node->{condition} . ') '
                      . $node->{then}
                      . ( $node->{else} ? ' else ' . $node->{else} : '' );

                };
                /^TeaPart::Cond$/ && do {
                    my $comment = '';
                    $comment = $node->{comment} . "\n" if $node->{comment};

                    $node->{condition}[0] =~ s/[{\n|;\n}]//g;
#die $node->{condition}[0];

                    my $code = 'if ('
                                .$node->{condition}[0] .')'
                                .$node->{instructions}[0];
                    for (my $i = 1; $i < (@{$node->{condition}}); ++$i) {
                        $node->{condition}[$i] =~ s/[{\n|;\n}]//g;
                        $code .= 'else if ('
                                .$node->{condition}[$i] .')'
                                .$node->{instructions}[$i];
                    }
                    $code .= 'else'
                        . $node->{else};

                    return $code; 

                };
                /^TeaPart::While$/ && do {
                    my $comment = '';
                    $comment = $node->{comment} . "\n" if $node->{comment};
                    return $comment
                      . "while ("
                      . $node->{condition} . ') '
                      . $node->{block};
                };
                /^TeaPart::foreach$/ && do {
                    my $comment = '';
                    $comment = $node->{comment} . "\n" if $node->{comment};
                    return $comment
                      . "for (TeaUnknownType "
                      . $node->{var1}.' : ' 
                      . $node->{var2}.') '
                      . $node->{block};
                };
                /^TeaProgram$/ && do {
                    my $code = <<START;
//package $package;

class MainProgram {
                
public static void main(String[] args) {
try{
START

                    $code .= ( join "", @{ $node->{statement} } );

                    $code .= "}catch(Exception e) {
                        System.out.println(e.getMessage());
                        }
                        } \n\n";

#print "$code \n\n\n\n\n\n";
#$code .= join '', @{ $node->{functions} }
#if $node->{functions};


                    # Is this the sort function??
                    my $sortClass;
                    foreach my $funct (@functions) {
                        if (defined $compFunction && $funct =~/.* $compFunction\s*\(/) {
                            $funct =~ m/(\()(.*)(,)(.*)(\))/;
                            my $v1 = $2;
                            my $v2 = $4;
                            $funct =~ s/^.*\n//;
                            $funct =~ s/}$/}}/;
                            $sortClass = "\n\nclass Comparer implements Comparator {"
                              . "public int compare(Integer $v1, Integer $v2) {"
                              . $funct; 
                        }else{
                            $code .= "\n\n". $funct;
                        }
                    }
                    
                    
                    $code .= "}\n";
                    $code .= $sortClass if defined $sortClass;
#                    die $code;
                    return indent($code);
                };
                /^TeaPart::Class$/ && do {
                    my $members = " ";
                    my $extends = '';
                    $extends = "extends " .$node->{super_class}.' ' if defined $node->{super_class};
                    if (ref $node->{arg_list} eq 'ARRAY'){
                        $members = "\nprivate unknownType ";
                        $members .= join( ";\nprivate unknownType ", @{ $node->{arg_list} } );
                        $members .= ";";
                    }

                    # if we have a sort method, the we have to have a special class
                    # This is that special class
                    my $code .= 
                       "public class $node->{class} $extends\{ ";
                    $code .= $members
                      . "\n\n"
                      . "//########################################################################### \n"
                      . "//########################### END OF PRIVATE MEMBERS ######################## \n"
                      . "//########################################################################### \n\n";

                    if (ref $methods{$node->{class}} eq 'ARRAY'){
                        $code .= join "", @{ $methods{$node->{class}} };
                    }else{
                        $code .= $methods{$node->{class}};
                    }
                    $code .= join '', @{ $node->{functions} }
                      if $node->{functions};

                    $code .= "}\n";
                    return indent($code);
                };
                /^TeaPart::Method/ && do {
                    my $code = "";
                    my $type = $node->{type} || 'TeaUnknownType';
                    $type = 'void' if ($node->{method} =~ /set.*/i);

                    my $args;

                    if  ( ref $node->{arg_list} eq 'ARRAY' ) {
                        $args = join( ', ', @{ $node->{arg_list}} );
                    }elsif (ref $node->{arg_list} eq 'HASH') {
                        $args = "";
                    }else{
                        $args = $node->{arg_list};
                    }

                    if ($node->{method} eq 'constructor') {
                        $code .= 'public '. $node->{class}. '('
                            . $args
                            . ')';
                    }
                    else{
                        $code .= 'public '. $type .' ' .$node->{method}.'('
                            . $args.')';
                    }

                    $code .= $node->{arg}[0];
                    $code .= "\n";

#$methods{$node->{class}} = [];
                    push @{$methods{$node->{class}}}, $code;
                    #return indent($code);
                    return " ";
                };
                /^TeaPart::New/ && do {
                    my $class = $node->{class};
                    return "new $typeConversion{$class} (new FileWriter(" 
                        . join( ", ", @{ $node->{arg} } )."))" if ( $node->{class} eq "TFileOutput");
                    return "new $typeConversion{$class} (new FileReader(" 
                        . join( ", ", @{ $node->{arg} } )."))" if ( $node->{class} eq "TFileInput");
                    return "new $typeConversion{$class} (new InputStreamReader( (new URL(" 
                        . join( ", ", @{ $node->{arg} } ).")).openStream()))" if ( $node->{class} eq "TUrlInput");
                    return "TDBC.tdbcConstructor("
                        . join( ", ", @{ $node->{arg} } ).")" if ( $node->{class} eq "TConnection");
                    return "TDBC.tdbcDateConstructor("
                        . join( ", ", @{ $node->{arg} } ).")" if ( $node->{class} eq "TDate");
                    

                    return "new ". ($typeConversion{$class} || $class) . "("
                      . join( ", ", @{ $node->{arg} } ) . ")";
                };
                /^TeaPart::Call/ && do {
                    my $methodName = $methodConvertion{ $node->{method} }
                      || $node->{method};          
                    my $code;

                    if($methodName eq 'registerDate'
                            || $methodName eq 'registerFloat'
                            || $methodName eq 'registerInt'
                            || $methodName eq 'registerString') {
                        
                        my %aux;

                        $aux{invocant} = $node->{invocant};
                        $aux{method} = $methodName;
                        $aux{ind} = $node->{arg}[0];
                        $aux{symbol} = $node->{arg}[1];
                        
                        return registerOuts(\%aux);
                    }elsif ($methodName eq 'fetchOutParameters'){
                        return fetchOuts();
                        
                    }

                    
                    # METHODS CONVERTED INTO FUNCTIONS
                    if($methodName eq 'tdbcConnect'){
                        $code .= 'TDBC.'.$methodName
                            . '('
                            . $node->{invocant}
                            . ','
                            . join( ", ", @{ $node->{arg} } ) . ")";
                    }elsif( $methodName eq 'hasRows'){
                        $code .= 'TDBC.tdbcHasRows('
                                . $node->{invocant}
                                .')';
                    }elsif( $methodName eq 'compare') {
                        $code .= 'TDBC.tdbcCompareDates('
                            .$node->{invocant}
                            .', '
                            .$node->{arg}[0]
                            .')';

                    }elsif( $methodName eq 'format'){
                        $code .= '(new SimpleDateFormat('
                            . $node->{arg}[0]
                            . ')).format('
                            . $node->{invocant}
                            . ')';
                    }elsif( $methodName eq 'getMonth'){
                        $code .= 'TDBC.tdbcGetMonth('
                            . $node->{invocant}
                            .')';
                    }elsif( $methodName eq 'getYear'){
                        $code .= 'TDBC.tdbcGetYear('
                            . $node->{invocant}
                            .')';
                    }elsif( $methodName eq 'setDate'){
                        $code .= 'TDBC.tdbcSetDate('
                            . $node->{invocant}
                            . ", "
                            . (join ", ", @{$node->{arg}})
                            .')'; 
 
                    }elsif( $methodName eq 'setTime'){
                        $code .= 'TDBC.tdbcSetTime('
                            . $node->{invocant}
                            . ", "
                            . (join ", ", @{$node->{arg}})
                            .')';
                     }elsif( $methodName eq 'getElements'){
                        $code .= 'Util.getElements('
                            . $node->{invocant}
                            .')'; 
                     }elsif( $methodName eq 'getKeys'){
                        $code .= 'Util.getKeys('
                            . $node->{invocant}
                            .')';  
 
                    }elsif( $methodName eq 'append'){
                        $code .= 'Util.append('
                            . $node->{invocant}
                            . ', new Object[] {'
                            . (join ", ", @{$node->{arg}})
                            . '}'
                            .')';   
                     }elsif( $methodName eq 'init'){
                        $code .= 'Util.init('
                            . $node->{invocant}
                            . ', new Object[] '
                            . '{'
                            . (join ", ", @{$node->{arg}})
                            . '})';
                     }elsif( $methodName eq 'pop'){
                        $code .= 'Util.pop('
                            . $node->{invocant}
                            . ')';
                    #END OF METHODS CONVERTED TO FUNCTIONS

                    #METHODS THAT NEED SPECIAL TREATMENT
                    }elsif ($methodName eq 'getFloat'){
                        $code .= '(double)'.$node->{invocant}
                            .'.'
                            .$methodName
                            .'('
                            . join( ", ", @{ $node->{arg} } ) . ")";
                    }
                    elsif ($methodName eq "write") {
                             $code .= $node->{invocant}
                                . "."
                                . $methodName
                                . '(' 
                                . $node->{arg}[0]
                                . ')'
                                . eol($node)
                                . $node->{invocant}
                                . '.newLine()';

                    }elsif ($methodName eq "addElements") {
                        my @arg_list= split /, /, $node->{arg}[0];
                        foreach (@arg_list) {
                            s/(^\(*) (.*) (\d\)) (\)*$)/$2$3/xg;
                            s/^\(//g;
                        }
                        for (my $i = 0; $i < @arg_list; $i+=2){
                            $code .= $node->{invocant} 
                                . '.put('
                                . $arg_list[$i]
                                .', '
                                . $arg_list[$i+1]
                                .')';
                            $code .= eol($node) if ($i+2 != @arg_list);
                        }

                    }elsif ($methodName eq "constructor") {
                        $code .= $node->{invocant}. '('
                            . (join ", ", @{$node->{arg}})
                            . ')';
                    }elsif ($methodName eq "sort") {
                        $code .= "Collections.sort($node->{invocant}, new Comparer())";
                        $compFunction = $node->{arg}[0];
                    }elsif ($methodName eq "setAt") {
                        $code .= $node->{invocant}
                            . '.'
                            . 'set('
                            . $node->{arg}[1]
                            . ', '
                            . $node->{arg}[0]
                            . ')';
                    }elsif ($methodName eq 'notSame'){
                        $code .= '!' . $node->{invocant} 
                            . '.' 
                            . 'equals('
                            . $node->{arg}[0]
                            . ')';
                    }elsif ($methodName eq 'same'){
                        $code .= $node->{invocant} 
                            . '.' 
                            . 'equals('
                            . $node->{arg}[0]
                            . ')'; 
                    }else{

                        #            DEFAULT BEHAVIOR
                        $code =
                          "$node->{invocant}.$methodName" . "("
                          . join( ", ", @{ $node->{arg} } ) . ")";
                    }

                    $code .= eol($node);
                    return $code;
                
                };
                /^TeaPart::Dereference/ && do {
                    return $node->{arg_symbol};
                };
            }
        }
    );
}

sub eol {
    my $node = shift;
    my $comment = $node->{comment} || '';
    if ( $node->{context}{liner} ) {
        return ';' . $comment . "\n";
    }
    else {
        return '';
    }
}

sub indent {
    my $code = shift;
    my ( $in, $out ) = gensym() for 1 .. 2;
    my $pid = open2( $out, $in, 'astyle', '--style=java' )
      || die 'Cannot open indentation engine: ' . $!;
    print {$in} $code;
    close $in;
    my $ret = join '', <$out>;
    waitpid( $pid, 0 );
    close $out;
    return $ret;
}

sub registerOuts {
    my $info = shift;
    my $type;
    $type = 'Types.DOUBLE' if($info->{method} eq 'registerFloat');
    $type = 'Types.INTEGER' if($info->{method} eq 'registerInt');
    $type = 'Types.VARCHAR' if($info->{method} eq 'registerString');
    $type = 'Types.DATE' if($info->{method} eq 'registerDate');
    push @registeredOuts, $info;
    my $code = $info->{invocant} . '.registerOutParameter('
            . $info->{ind}
            .', '
            . $type
            . ');';
}

sub fetchOuts {
    my $type;
    my $javaMethod;
    my $code;
    foreach (@registeredOuts){
         if($_->{method} eq 'registerFloat'){
            $type = 'Double';
            $javaMethod = 'getDouble';
         }
         if($_->{method} eq 'registerInt') {
            $type = 'Integer';
            $javaMethod = 'getInt';
         }
         if($_->{method} eq 'registerString'){
            $type = 'String'; 
            $javaMethod = 'getString';
         }
         if($_->{method} eq 'registerDate'){
            $type = 'Date'; 
            $javaMethod = 'getDate';
         }

        $code .= $type. " " 
            . $_->{symbol}
            . ' = ' 
            . $_->{invocant}
            . '.'.$javaMethod
            . '('
            . $_->{ind}
            .');';
                            
    }
    return $code;
}
1;

