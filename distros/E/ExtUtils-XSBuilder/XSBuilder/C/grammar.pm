package ExtUtils::XSBuilder::C::grammar;

# initial grammar is taken from Inline::C::grammar & Inline::Struct::grammar

use strict;
use vars qw{$VERSION @EXPORT @ISA} ;
use Exporter ;
use Data::Dumper ;


$VERSION = '0.30';

@ISA = qw{Exporter} ;
@EXPORT = qw{cdef_define cdef_enum cdef_struct cdef_function_declaration} ;


# ============================================================================

sub cdef_define
    {
    my ($thisparser, $name, $comment) = @_ ;

    my $elem = { name => $name, $comment?(comment => $comment):() } ;
    if ($thisparser->{srcobj}->handle_define($elem)) 
        {
        push @{$thisparser->{data}{constants}}, $elem ;
        print "constant: $name\n" ;
        }
    else
        {
        print "constant: $name (ignore because handle_define returned false)\n" ;
        }
    }
    
# ============================================================================

sub cdef_enum
    {
    my ($thisparser, $names) = @_ ;

    for (@{$names})
        {
        if (ref $_) 
            {
	    my $elem = { name => $_ -> [0], $_->[1] && @{$_->[1]}?('comment' => join (' ', @{$_->[1]})):() } ;
            push @{$thisparser->{data}{constants}}, $elem if ($thisparser->{srcobj}->handle_enum($elem)) ; 
            }
        }
    1 ;
    }

# ============================================================================

sub cdef_struct
    {
    my ($thisparser, $perlname, $cname, $fields, $type) = @_;
    my $seen = \$thisparser->{data}{structure}{$cname || $type} ;
    my $s = $$seen ;
    return 0 if ($s && ($s -> {elts} && !$type)) ;
    #print "cdef $cname $type\n" ;
    $s ||= {} ;
    $s -> {type} ||= $cname ;
    $s -> {type} = $type if ($type) ;
    if ($fields)
        {
        my @fields;
        my @comment ;
        for (@$fields)
            {
            if (ref $_) 
                {
                push @fields, { 
                    'type' => $_->[0], 
                    'name' => $_->[1], 
                    ($_->[2] && @{$_->[2]}) || @comment?('comment' => join (' ', @{$_->[2]}, @comment)):(), 
                    $_->[3] && @{$_->[3]}?('args' => $_->[3]):(), 
                    } ; 
                @comment = () ;
                }
            else
                {
                push @comment, $_ ;
                }
            }
        $s -> {elts} = \@fields ;
        }
    $s -> {stype} = $cname if ($cname) ; 
    if ($fields)
        {
        if ($thisparser->{srcobj}->handle_struct($s)) 
            {
            push @{$thisparser->{data}{structures}}, $s ;
            print "struct:   $cname (type=$type)\n" ;
            }
        else
            {
            print "struct:   $cname (ignore because handle_struct returned false)\n" ;
            }
        }
    $$seen = $s ;
    return $s ;
    }


# ============================================================================

sub cdef_function_declaration
    {
    my ($thisparser, $function, $rettype, $args) = @_ ;
    return 0 if (!$function) ;
    return 0 if ($thisparser->{data}{function}{$function}++) ;
    my $s = { 'name' => $function } ;
    my $dummy = 'arg0' ;
    $s -> {return_type} = $rettype ;
    my @args ;
    my $i = 0 ;
    for (@{$args})
        {
        if (ref $_) 
            {
            push @args, { 
                'type' => $_->[0], 
                'name' => $_->[1] || "arg$i", 
                } if ($_->[0] ne 'void') ; 
            }
        $i++ ;
        }
    $s -> {args} = \@args ;
     if ($thisparser->{srcobj}->handle_function($s)) 
        {
        push @{$thisparser->{data}{functions}}, $s ;
        print "func:     $function\n" ;
        }
    else
        {
        print "func:     $function (ignore because handle_function returned false)\n" ;
        }
    return $s ;
    }

# ============================================================================

sub grammar {
    <<'END';

{ 
use ExtUtils::XSBuilder::C::grammar ; # import cdef_xxx functions 
}

code:	comment_part(s) {1}

comment_part:
    comment(s?) part
        { 
        #print "comment: ", Data::Dumper::Dumper(\@item) ;
        $item[2] -> {comment} = "@{$item[1]}" if (ref $item[1] && @{$item[1]} && ref $item[2]) ;
        1 ;
        }
    | comment

part:   
    prepart 
    | stdpart
        {
        if ($thisparser -> {my_neednewline}) 
            {
            print "\n" ;
            $thisparser -> {my_neednewline} = 0 ;
            }
        $return = $item[1] ;
        }

# prepart can be used to extent the parser (for default it always fails)

prepart:  '?' 
        {0}

           
stdpart:   
    define
        {
        $return = cdef_define ($thisparser, $item[1][0], $item[1][1]) ;
        }
    | struct
        {
        $return = cdef_struct ($thisparser, @{$item[1]}) ;
        }
    | enum
        {
        $return = cdef_enum ($thisparser, $item[1][1]) ;
        }
    | function_declaration
        {
        $return = cdef_function_declaration ($thisparser, @{$item[1]}) ;
        }
    | struct_typedef
        {
        my ($type,$alias) = @{$item[1]}[0,1];
        $return = cdef_struct ($thisparser, undef, $type, undef, $alias) ;
        }
    | comment
    | anything_else

comment:
    m{\s* // \s* ([^\n]*) \s*? \n }x
        { $1 }
    | m{\s* /\* \s* ([^*]+|\*(?!/))* \s*? \*/  ([ \t]*)? }x
        { $item[1] =~ m#/\*\s*?(.*?)\s*?\*/#s ; $1 }

semi_linecomment:
    m{;\s*\n}x
        {
        $return = [] ;
        1 ;
        }
    | ';' comment(s?)
        {
        $item[2]
        }

function_definition:
    rtype IDENTIFIER '(' <leftop: arg ',' arg>(s?) ')' '{'
        {[@item[2,1], $item[4]]}

pTHX:
    'pTHX_'

function_declaration:
    type_identifier '(' pTHX(?) <leftop: arg_decl ',' arg_decl>(s?) ')' function_declaration_attr ( ';' | '{' )
        {
        #print Data::Dumper::Dumper (\@item) ;
            [
            $item[1][1], 
            $item[1][0], 
            @{$item[3]}?[['pTHX', 'aTHX' ], @{$item[4]}]:$item[4] 
            ]
        }

define:
    '#define' IDENTIFIER /.*?\n/
        {
        $item[3] =~ m{(?:/\*\s*(.*?)\s*\*/|//\s*(.*?)\s*$)} ; [$item[2], $1] 
        }

ignore_cpp:
    '#' /.*?\n/

struct: 
    'struct' IDENTIFIER '{' field(s) '}' ';'
        {
        # [perlname, cname, fields]
        [$item[2], "@item[1,2]", $item[4]]
        }
    | 'typedef' 'struct' '{' field(s) '}' IDENTIFIER ';'
        {
        # [perlname, cname, fields]
        [$item[6], undef, $item[4], $item[6]]
        }
    | 'typedef' 'struct' IDENTIFIER '{' field(s) '}' IDENTIFIER ';'
        {
        # [perlname, cname, fields, alias]
        [$item[3], "@item[2,3]", $item[5], $item[7]]
        }

struct_typedef: 
    'typedef' 'struct' IDENTIFIER IDENTIFIER ';'
        {
	["@item[2,3]", $item[4]]
	}

enum: 
    'enum' IDENTIFIER '{' enumfield(s) '}' ';'
        {
        [$item[2], $item[4]]
        }
    | 'typedef' 'enum' '{' enumfield(s) '}' IDENTIFIER ';'
        {
        [undef, $item[4], $item[6]]
        }
    | 'typedef' 'enum' IDENTIFIER '{' enumfield(s) '}' IDENTIFIER ';'
        {
        [$item[3], $item[5], $item[7]]
        }

field: 
    comment 
    | define
	{
        $return = cdef_define ($thisparser, $item[1][0], $item[1][1]) ;
	}
    | valuefield 
    | callbackfield
    | ignore_cpp

valuefield: 
    type_identifier comment(s?) semi_linecomment
        {
        $thisparser -> {my_neednewline} = 1 ;
        print "  valuefield: $item[1][0] : $item[1][1]\n" ;
	[$item[1][0], $item[1][1], [$item[2]?@{$item[2]}:() , $item[3]?@{$item[3]}:()] ]
        }


callbackfield: 
    rtype '(' '*' IDENTIFIER ')' '(' <leftop: arg_decl ',' arg_decl>(s?) ')' comment(s?) semi_linecomment
        {
        my $type = "$item[1](*)(" . join(',', map { "$_->[0] $_->[1]" } @{$item[7]}) . ')' ;
        my $dummy = 'arg0' ;
        my @args ;
        for (@{$item[7]})
            {
            if (ref $_) 
                {
                push @args, { 
                    'type' => $_->[0], 
                    'name' => $_->[1], 
                    } if ($_->[0] ne 'void') ; 
                }
            }
        my $s = { 'name' => $type, 'return_type' => $item[1], args => \@args } ;
        push @{$thisparser->{data}{callbacks}}, $s  if ($thisparser->{srcobj}->handle_callback($s)) ;

        $thisparser -> {my_neednewline} = 1 ;
        print "  callbackfield: $type : $item[4]\n" ;
        [$type, $item[4], [$item[9]?@{$item[9]}:() , $item[10]?@{$item[10]}:()]] ;
        }


enumfield: 
    comment
    | IDENTIFIER  comment(s?) /,?/ comment(s?)
        {
        [$item[1], [$item[2]?@{$item[2]}:() , $item[4]?@{$item[4]}:()] ] ;
        }

rtype:  
    modmodifier(s) TYPE star(s?)
        {
        my @modifier = @{$item[1]} ;
        shift @modifier if ($modifier[0] eq 'extern' || $modifier[0] eq 'static') ;

        $return = join ' ',@modifier, $item[2] ;
        $return .= join '',' ',@{$item[3]} if @{$item[3]};
        1 ;
	}
    | TYPE(s) star(s?)
        {
        $return = join (' ', @{$item[1]}) ;
        $return .= join '',' ',@{$item[2]} if @{$item[2]};
	#print "rtype $return \n" ;
        1 ;
        }
    modifier(s)  star(s?)
        {
        join ' ',@{$item[1]}, @{$item[2]} ;
	}

arg:
    type_identifier 
        {[$item[1][0],$item[1][1]]}
    | '...'
        {['...']}

arg_decl: 
    rtype '(' '*' IDENTIFIER ')' '(' <leftop: arg_decl ',' arg_decl>(s?) ')'
        {
        my $type = "$item[1](*)(" . join(',', map { "$_->[0] $_->[1]" } @{$item[7]}) . ')' ;
        my $dummy = 'arg0' ;
        my @args ;
        for (@{$item[7]})
            {
            if (ref $_) 
                {
                push @args, { 
                    'type' => $_->[0], 
                    'name' => $_->[1], 
                    } if ($_->[0] ne 'void') ; 
                }
            }
        my $s = { 'name' => $type, 'return_type' => $item[1], args => \@args } ;
        push @{$thisparser->{data}{callbacks}}, $s  if ($thisparser->{srcobj}->handle_callback($s)) ;

        [$type, $item[4], [$item[9]?@{$item[9]}:() , $item[11]?@{$item[11]}:()]] ;
        }
    | 'pTHX'
	{
	['pTHX', 'aTHX' ]
	}
    | type_identifier
	{
	[$item[1][0], $item[1][1] ]
	}
    | '...'
        {['...']}

function_declaration_attr:

type_identifier:
    type_varname 
        { 
        my $r ;
	my @type = @{$item[1]} ;
	#print "type = @type\n" ;
	my $name = pop @type ;
	if (@type && ($name !~ /\*/)) 
	    {
            $r = [join (' ', @type), $name] 
	    }
	else
	    {
	    $r = [join (' ', @{$item[1]})] ;
	    }	            
	#print "r = @$r\n" ;
        $r ;
        }
 
type_varname:   
    attribute(s?) TYPE(s) star(s) varname(?)
        {
	[@{$item[1]}, @{$item[2]}, @{$item[3]}, @{$item[4]}] ;	
	}
    | attribute(s?) varname(s)
        {
	$item[2] ;	
	}


varname:
    ##IDENTIFIER '[' IDENTIFIER ']'
    IDENTIFIER '[' /[^]]+/ ']'
	{
	"$item[1]\[$item[3]\]" ;
	}
    | IDENTIFIER ':' IDENTIFIER
	{
	$item[1]
	}
    | IDENTIFIER
	{
	$item[1]
	}


star: '*' | 'const' '*'
        
modifier: 'const' | 'struct' | 'enum' | 'unsigned' | 'long' | 'extern' | 'static' | 'short' | 'signed'

modmodifier: 'const' | 'struct' | 'enum' | 'extern' | 'static'

attribute: 'extern' | 'static' 

# IDENTIFIER: /[a-z]\w*/i
IDENTIFIER: /\w+/

TYPE: /\w+/

anything_else: /.*/

END
}

1;

__END__


=pod
	| function_definition
	{
	 my $function = $item[1][0];
         $return = 1, last if $thisparser->{data}{done}{$function}++;
	 push @{$thisparser->{data}{functions}}, $function;
	 $thisparser->{data}{function}{$function}{return_type} = 
             $item[1][1];
	 $thisparser->{data}{function}{$function}{arg_types} = 
             [map {ref $_ ? $_->[0] : '...'} @{$item[1][2]}];
	 $thisparser->{data}{function}{$function}{arg_names} = 
             [map {ref $_ ? $_->[1] : '...'} @{$item[1][2]}];
	}
=cut

