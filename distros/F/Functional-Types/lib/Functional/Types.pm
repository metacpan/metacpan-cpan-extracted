package Functional::Types;

use warnings;
use strict;
no strict 'subs';
use v5.16;
use version; our $VERSION = version->declare('v0.0.1');

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = (
    qw(
      Scalar
      Array
      Map
      Tuple
      Record
      Variant
      variant
      Function
      Int
      Float
      String
      Bool
      True
      False
      type
      newtype
      typename
      cast
      bind
      let
      untype
      show
      read
      a b c d t
      )

      #,@{TypeChecking::API::EXPORT}
);

use Data::Dumper;
our $VV = 1;
our $FIXME = 0;

=encoding utf-8

=head1 NAME

Functional::Types - a Haskell-inspired type system for Perl

=head1 SYNOPSIS

  use Functional::Types;

  sub ExampleType { newtype }
  sub MkExampleType { typename ExampleType, Record(Int,String), @_ }

  type my $v = ExampleType;
  bind $v, MkExampleType(42,"forty-two");
  say show $v;
  my $uv = untype $v;

=head1 DESCRIPTION

Functional::Types provides a runtime type system for Perl, the main purpose is to allow type checking and have self-documenting data structures. It is strongly influenced by Haskell's type system. More details are below, but at the moment they are not up-to-date. The /t folder contains examples of the use of each type.

=head1 AUTHOR

Wim Vanderbauwhede E<lt>Wim.Vanderbauwhede@mail.beE<gt>

=head1 COPYRIGHT

Copyright 2015- Wim Vanderbauwhede

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

# Some types don't have constructors. e.g. Int. As in Perl scalars are not typed at all, in order to do type checking we must do one of the following:
# What the newtype() call does is create an entry in the type table:

sub AUTOLOAD {
    our $AUTOLOAD;
    my $t = $AUTOLOAD;
    $t =~ s/^\w+:://;
    return [ $t, [@_] ];
}

################################################################################
# e.g. type my $x = IntVar;
sub type {
#    say "sub type():".Dumper(@_);
    my $tn = $_[0];
    if (@_>1) {
        my $tn_args=[];
        for my $arg (@_) {
            if (ref($arg) !~/ARRAY|Array|Map|Tuple/) { 
                say '# FIXME: What about proper types?' if $FIXME;
                push @{$tn_args},[$arg,[]];
            } else {
                push @{$tn_args},$arg;
            }
        }
        $tn = bless(['Function', $tn_args],'Function') ;  # So type my $f = Int => Int => Int should work OK
    }
    $_[0] = bless( { 'Type' => $tn, 'Val' => undef }, 'Functional::Types' );
#    die 'BOOM:'.Dumper(@_);
}

sub typename {
    my @c = caller(1);
    my $t = $c[3];
    $t =~ s/^.+:://;
    return [ $t, [@_] ];
}

sub a { return 'a'; }
sub b { return 'b'; }
sub c { return 'c'; }
sub d { return 'd'; }
sub t { return 't'; }

=head1 NEWTYPE

The function of newtype is to glue typename information together with the constructor information, and typecheck the arguments to the constructor.
I think it is best to treat all cases separately:

  - Primitive types: e.g. sub ArgType { newtype String,@_ } # Does ArgType expect a String or a bare value? I guess a bare value is better?
  - Record types: e.g. sub MkVarDecl { newtype VarDecl, Record( acc1 => ArgType, acc2 => Int), @_ }
  - Variant types: e.g. sub Just { newtype Maybe(a), Variant(a), @_ }
  - Map type: sub HashTable { newtype Map(String,Int), @_ } is a primitive type
  - Array type: sub IntList { newtype Array(Int), @_ } is a primitive type

I expect String to be called and it will return ['$',String] so ArgType(String("str")) should typecheck

  String("str") will return {Type => ['$',String], Val =>"str"}

  MkVarDecl will return {Type => ['~',MkVarDecl,[],VarDecl,[]], Val => ...}
  Just(Int(42)) will return {Type => ['|',Just,[{a => 'any'}],Maybe,[{a => 'any'}}, Val => {Type => ['$',Int], Val => 42}}
  
To typecheck this against type Maybe(Int) will require checking the type of the Val
So maybe newtype must do this: if the typename or type ctor (yes, rather) has a variable then we need the actual type of the value

=cut

sub isprim {
    ( my $tn ) = @_;
#    say Dumper($tn);
    if (ref($tn) eq 'ARRAY') { 
        $tn = $tn->[0];
    }
    if ( $tn =~ /^[a-z]|Bool|String|Int|Float|Double/ ) {
        return 1;
    } else {
        return 0;
    }
}
sub iscontainer {
    (my $td) = @_;
    if ( ref($td) eq 'Array' or
    ref($td) eq 'Map' or
    ref($td) eq 'Tuple'
    ) {
        return 1;
    } else {
        return 0;
    }
}

sub isprimcontainer {
      (my $td) = @_;
    iscontainer($td) && isprim($td->[2][0]); 
}

sub istypedval {
    ( my $v ) = @_;
#    say "istypedval: " . Dumper($v);

    if ( ref($v) eq 'Functional::Types' )
    {    # || (ref($v) eq 'HASH' and exists $v->{Type} and exists $v->{Val})) {
        return 1;
    } else {
        return 0;
    }
}

=head1 TYPECHECKING

This is a bit rough. We should maybe just check individual types, and always we must use the constructed type as a starting point, and the declared type to check against.
We typecheck in two different contexts:

  1/ Inside the newtype() call: for every element in @_, we should check against the arguments of the type constructor. 
  2/ Inside the bind() call: this call takes a typed value. For this typed value, all we really need to check is if its typename matches with the declared name. 

I think it might be better to have the same Type record structure for every type:

  Variant, Record: ['|~:', $ctor, [@ctor_args],$typename,[@typename_args]]

  Map, Tuple, Array: ['@%*', $ctor, [@ctor_args], $typename=$ctor,[]]

  Scalar: ['$', $ctor, [@ctor_args], $typename=$ctor,[]]

=cut

sub typecheck {
#    local $VV=1;
    say '%' x 80 if $VV;
    say "TYPECHECK: " . Dumper(@_) if $VV;
    say '%' x 80 if $VV;
    ( my $t1, my $t2 ) = @_;    
    if (ref($t1) eq 'Functional::Types') {
        $t1=$t1->{Type};
    } 
    if (ref($t2) eq 'Functional::Types') {
        $t2=$t2->{Type};
    }    
    if (iscontainer($t1) ) {
        my $tn1 = $t1->[1];
        if (not iscontainer($t2) ) {            
            return (0,$tn1, $t2);
        } else {
            my $tn2 = $t2->[1];
            if ($tn1 ne $tn2) {
                  return (($tn1 eq $tn2),$tn1, $tn2);
            } else {
                # Containers match, now check the enclosed type(s)
                my $ctn1 = $t1->[2];
                my $ctn2 = $t2->[2];
                my $ii=0;
                for my $et1 (@{$ctn1}) {
                    my $et2=$ctn2->[$ii++];
                    (my $st, my $ttn1, my $ttn2) = typecheck($et1, $et2);
                    if (!$st) {
                        return (0,$et1,$et2);
                    }
                }
                return (1,$tn1, $tn2);
            }
        }
        
    } else {
     # At this point, we know the type is not a container. 
     # We can now test t1 to see if it is a Scalar, or bare string or an array containing a string
#        say "REF:".ref($t1);
#        say "REF:".ref($t2);
    my $tn1= (ref($t1) eq 'ARRAY') ? $t1->[0] :  (ref($t1) eq '' ? $t1 : (ref($t1) eq 'Scalar' ? $t1->[1] : $t1->[3]));
    my $tn2= (ref($t2) eq 'ARRAY') ? $t2->[0] :  (ref($t2) eq '' ? $t2 : (ref($t2) eq 'Scalar' ? $t2->[1] : $t2->[3]));
    if ($tn1 =~/^[a-z]/ && $tn2!~/^[a-z]/) {
        $tn1=$tn2;
    } elsif ($tn2 =~/^[a-z]/  && $tn1!~/^[a-z]/) {
        $tn2 = $tn1;
    }
    return (($tn1 eq $tn2),$tn1, $tn2);
    }

#    # The actual type check
#    my $tvarvals = {};
#    for my $val ( @{$vals} ) {
#        my $t = shift @{$tc_fields};
#        if ( istypedval($t) ) {
#            say "TYPEDVAL!";
#            $t = $t->{Type};
#        }
#
#        # otherwise we compare field by field with $tc
#        say 'VALTYPE:', Dumper($val);
#        my $valtype = (
#            istypedval($val)
#            ? (
#                ( ref( $val->{Type}[-1] ) eq 'ARRAY' )
#                ? $val->{Type}[-2]
#                : $val->{Type}[-1]
#              )
#            : $val
#        );    # HACK!
#        if ( istypedval($valtype) ) {
#            say "TYPEDVAL!";
#            $valtype = $valtype->{Type};
#        }
#        say 'VALTYPE2:', Dumper($valtype);
#
#        if ( $valtype eq $t ) {
#            say "TYPE CHECK OK!";
#        } elsif ( $t =~ /^[a-z]$/ ) {
#            say "TYPE CHECK: FOUND TYPE VAR $t, setting to $valtype";
#
#            #            $t=$valtype;
#            $tvarvals->{$t} = $valtype;
#        } elsif ( ref($t) eq 'ARRAY' and $t->[1] eq $valtype ) {
#            say "TYPE CHECK AGAINST PRIM TYPE OK!";
#        } else {
#            die "TYPE CHECK NOK:", $valtype, "<>", Dumper($t);
#        }
#    }    
#    return $tvarvals;
}

sub typecheck_prim {
    say "PRIM:", Dumper(@_);

  # If it's a primitive type, there is no $tc, we compare with $t
  # In this case the argument *must* be a scalar, so array ref rather than array
    ( my $val, my $t ) = @_;
    say "TYPE:", Dumper($t);
    say "VAL:",  Dumper($val);
    if ( $t eq $val->{Type}[1] ) {
        say "PRIM TYPE CHECK OK!";
    } else {
        die "PRIM TYPE CHECK NOK:", $val->{Type}[1], "<>", $t->[1];
    }
}

# So calls to primitive constructors don't ever return typed valies
sub newtype {
    my @c = caller(1);
    if($VV) {
    say '=' x 80;
    say "NEWTYPE Called from ", $c[3];
    say "NEWTYPE ARGS:<<<";
    say Dumper(@_);
    say ">>>";
    }
    if ( scalar @_ == 1 and ref( $_[0] ) eq 'HASH' ) {
        # This means we just got a value, should not happen I guess
        die "Not enough arguments in call to newtype() :" . Dumper(@_);
    } else {
        my $t = shift @_;
        say "TYPE:" . Dumper($t) if $VV;
        my $arg = shift @_;
        say "ARG:" . Dumper($arg) if $VV;
        if ( ref($arg) =~ /OLD/ ) {

            # We need to treat the differnt types differntly I guess.
            # There is a type constructor, get it
            my $tc = shift;
            say "TYPE CONSTRUCTOR:" . Dumper($tc) if $VV;
            my @vals      = @_;
            my @tc_fields = @{ $tc->[2] };
#            typecheck( \@vals, \@tc_fields );
            if ( ref($t) ne 'ARRAY' ) {
                say "WARNING: TYPE NAME NOT ARRAY for $t!";
                $t = [ $t, [] ];
            }

# If the type check is OK, we combine the type constructor and the type name and the typename arguments
# Assuming $t = ['Typename',[@args]] and $tc=[ $kind, $ctor, [@ctor_arg_typenames]]
            return
              bless( { Type => [ @{$tc}, @{$t} ], Val => [@vals] }, 'Functional::Types' );
# ------------------------------------------------------------------------------------------------              
        } elsif ( ref($arg) eq 'Variant' ) {

            # newtype $t = Maybe(a), $tc = Variant(a), $v = @_
            my $tc = $arg; 
#bless( [
#                 '|',
#                 'Just',
#                 [
#                   'a'
#                 ]
#               ], 'Variant' );            
            my $v  = (@_>1)?[@_]:$_[0];
            
              ; # Assumption is that these are type value objects, but must check
                # So I must compare $v against $tc->[1] I guess
                my $ii=0;
            for my $elt ( @_ ) {
                say "ELT:".Dumper($elt) if $VV;
                my $tc_tn = $tc->[2]->[$ii++];
                say "TYPENAME:".Dumper($tc_tn) if $VV;
                if ( ref($elt) eq 'Functional::Types' ) {
                    my $tn    = $elt->{Type};#->[1];
                   if (defined $tn->[3]) { # HACK!
                      $tn= $tn->[3];
                   }
                    if ( not ($tc_tn=~/^[a-z]/) ) {
#                        say '#####'.Dumper($tn).'<>'.Dumper($tc_tn);
                        (my $st, my $t1, my $t2)=typecheck($tn, $tc_tn );
                            if( not $st ) {
#                                say '<',$tn->[3],'><',$tc_tn->[0],'>'  if $VV;
                        die "Type error in Variant type check: $t1 <> $t2";
                            }
                    } else {
                        $tc_tn=$tn;
                    }
                } else {
                    if ( !isprim( $tc_tn ) ) {
                        die
"Type error in Variant type check: $elt is not typed but $tc_tn is not a Primitive type.";#.Dumper($t);
                    }
                }
            }
#            say Dumper($tc);
            $tc=bless( [@{$tc},@{$t}], 'Variant');#die Dumper($tc);
#die 'HERE:'.Dumper($tc);
# What we should return is a typed value where the Val is a bare $v, and the Type is a Variant
# Now, U guess this is fine, but could we not have something like
# VarT a = Var1 a | Var2 Int String | Var3 (a,Bool) | Var4
# Then the type constructor would take several arguments so
            return bless( { Type => $tc, Val => $v }, 'Functional::Types' );
# ------------------------------------------------------------------------------------------------            
        } elsif ( ref($arg) eq 'Record' ) {

#  - Record types: e.g. sub MkVarDecl { newtype $t=VarDecl, $tc=Record( ArgType, Int), $v=@_ }
# the Type field should become $tc,$t just as in Variant
            my $tc = $arg;
            my $v  = [@_];
#say Dumper($tc,$v);
# bless( ['~','MkAlgType',[['String',[]],['Int',[]]]], 'Record' )
# ['GO!GO!',7188]
        my $ii=0;
            for my $elt ( @{$v} ) {
                if ( ref($elt) eq 'Functional::Types' ) {
                    my $tn    = $elt->{Type}->[1];
                    my $tc_tn =  $tc->[2]->[$ii++];
                    if ( not typecheck( $tn, $tc_tn ) ) {
                        die "Type error in Record type check:";
                    }
                } else { # bare value
                    my $tc_tn =  $tc->[2]->[$ii++]  ;
                    if ( !isprim( $tc_tn->[0] ) ) {
                        die
"Type error in Record type check: $tc is not a Primitive type";
                    }
                }
            }
#            say Dumper($tc).Dumper($t);die;
$tc=bless( [@{$tc},@{$t}], 'Record');
            return bless( { Type => $tc, Val => $v }, 'Functional::Types' );
# ------------------------------------------------------------------------------------------------
        } elsif ( ref($arg) eq 'NamedRecord' ) {

#  - Record types: e.g. sub MkVarDecl { newtype $t=VarDecl, $tc=Record( acc1 => ArgType, acc2 => Int), $v=@_ }
            my $tc  = $arg;
            my $v   = [@_];
            my $kvs = {};
            my $ii=0;
            for my $elt ( @{$v} ) {
                my $tc_tf = $tc->[2]->[$ii++];
                my $tc_tn = $tc->[2]->[$ii++];
#                say 'TC:'.Dumper($tc_tn)."\nELT:".Dumper($elt->{Type});
                if ( ref($elt) eq 'Functional::Types' ) {
                    my $tn = $elt->{Type}->[1];
#                    my $tc_tn =  $tc->[2]->[$ii++];
                    (my $st, my $tn1, my $tn2) =typecheck( $tn, $tc_tn );
                    if ( not $st ) {
                        die "Type error in NamedRecord type check: $tn1, $tn2";
                    }
                    
                } elsif ( !isprim( $tc->[0] ) ) {
                    die
"Type error in NamedRecord type check: $tc is not a Primitive type";
                }
                $kvs->{$tc_tf} = $elt;
            }
$tc=bless( [@{$tc},@{$t}], 'NamedRecord');
            return bless( { Type => $tc, Val => $kvs }, 'Functional::Types' );
# ------------------------------------------------------------------------------------------------
        } elsif ( ref($arg) eq 'Function' ) {
            die "FUNCTION NOT YET IMPLEMENTED!";
# ------------------------------------------------------------------------------------------------            
        } elsif ( ref($arg) eq 'Array' ) {

     #  - Array type: sub IntList { newtype $tc = Array(Int), $v=@_ } is a primitive type
     # This can only be used as IntList([T]) where in principle we should test *every* element of the list.
     my $tc = $t; # ['Array',[Int]]
     die Dumper($tc);
     # What it should be is bless( ['@','Array',['Int'],'Array',[]],'Array'
     my $v = (@_==1 && ref($_[0]) eq 'ARRAY') ? $_[0] : [@_];
     my $elt_type= $tc->[1]->[0];
     if (!isprim($elt_type)) {
         if (not ($tc->[1] ~~ $v->[0]->{Type}->[1]) ) {
              die "Type error in Array type check:";
         }
     }
     return bless( { Type => $tc, Val => $v }, 'Functional::Types' );
# ------------------------------------------------------------------------------------------------     
        } elsif ( ref($arg) eq 'Map' ) {

#  - Map type: sub HashTable { newtype Map(String,Int), @_ } is a primitive type
# ------------------------------------------------------------------------------------------------
        } elsif ( ref($arg) eq 'Tuple' ) {
# ------------------------------------------------------------------------------------------------
        } elsif ( ref($arg) eq 'Scalar' ) {
    die "TODO: SCALAR!";
# A scalar
#  - Primitive types: e.g. sub ArgType { newtype String,@_ } #  ArgType expects bare value. TODO: check it it's a typed value and untype

        } elsif ( ref($arg) eq 'HASH' ) {    
            # sub MyInt { newtype Scalar, @_ } and MyInt(Int(42))
            die " GOT HASH, WHY?";
            my $val = shift @_;
            typecheck_prim( $val, $t );
            return bless( { Type => $t, Val => $val }, 'Functional::Types' );
        } else {
            if (not defined $arg) {
                say "TYPE ALIAS (only for scalar?)<".Dumper($t).','.Dumper(@_).'>' if $VV;
                if ( isprim($t) ) {
                    return bless( { Type => bless([ '$', @{$t} ],'Scalar'), Val => $_[0] }, 'Functional::Types' );
                } else {
                    # This is just pass-through
                    return $t;
                }
            } else {
                say "TYPE ALIAS CALLED:".Dumper($t).','.Dumper($arg) if $VV;
                my $tn = $t->[0];
                if (isprim($tn) ) {
                    return bless( { Type => bless( [ '$', @{$t} ], 'Scalar'), Val => $arg }, 'Functional::Types' );
                } else {
                    die "NO HANDLER FOR ".Dumper($t);
                }
            }

        }
    }
}    # END of newtype()

=head1 BIND

  bind():
  
  bind $scalar, Int($v);
  bind $list, SomeList($vs);
  bind $map, SomeMap($kvs);
  bind $rec, SomeRec(...); 
  bind $func, SomeFunc(...);

For functions, bind() should do:

  - Take the arguments, which should be typed, typecheck them;
  - call the original function with the typed args
  - the return value should also be typed, just return it.

So it might be very practical to have a typecheck() function

Furthermore, we can do something similar to pattern matching by using a variant() function like this:

  given(variant $t) {
	when (Just) : untype $t;
	when (Nothing) : <do something else>
  }
  
So variant() simply extracts the type constructor from a Variant type.

=cut

sub cast {
    ( my $t, my $v ) = @_;
    $t->{Val} = $v;
}

# What should the complete type for a Variant be? Maybe, [ [Int,[]]], Just, []
sub bind {
    ( my $t, my $tv, my @rest ) = @_;
    if (@rest) { 
        $tv = [$tv,@rest];
    }
    say "BIND: T:<" . Dumper($t) . '>; V:<' . Dumper($tv) . '>' if $VV;

if (istypedval($tv)) { 
        (my $st, my $t1, my $t2)=typecheck($t,$tv);
    if (not $st) {
        die "Typecheck failed in bind($t1,$t2)"; 
    }
        # We need the typenames from $t and from $tv
    my $t_from_v = $tv->{Type};    # so [$k,...]
    if (ref($t_from_v) eq 'Variant') {
        if (ref($t->{Type}) eq 'Variant') {
        if ($t_from_v->[3] eq $t->{Type}->[3]) {
            $t->{Type}=$t_from_v;
        } else { die "Type error in bind() for Variant";} 
        } else {
        if ($t_from_v->[3] eq $t->{Type}->[0]) {
            $t->{Type}=$t_from_v;
        } else { die "Type error in bind() for Variant";} 
             
        }
    } elsif (ref($t_from_v) eq 'Record') {
#            die Dumper($t_from_v);
        if ($t_from_v->[3] eq $t->{Type}->[0]) {
            $t->{Type}=$t_from_v;
        }        else { die "Type error in bind() for Record";}
    } elsif (ref($t_from_v) eq 'NamedRecord') {
#            die Dumper($t_from_v);
        if ($t_from_v->[3] eq $t->{Type}->[0]) {
            $t->{Type}=$t_from_v;
        }        else { die "Type error in bind() for NamedRecord";}

    } elsif (ref($t_from_v) eq 'Scalar') {
               $t->{Type}=$t_from_v;
    }
    # $t is [$tn,[@targs]]
    $t->{Val} = $tv->{Val};
    
} else { 
    # must check if prim type for bare val
#    say 'T:'. Dumper($t);
    if  (isprim($t->{Type}->[0])) {
#        $t->{Type}->[3]
#         $t->{Type}->[3]=ref($t->{Type});
#            $t->{Type}->[4]=[];
            $t->{Type}=bless(['$',@{$t->{Type}},@{$t->{Type}}],'Scalar');
        $t->{Val} = $tv;
        
    } elsif (isprim($t->{Type}->[1])) {
         $t->{Type}->[3]=ref($t->{Type});
            $t->{Type}->[4]=[];
        $t->{Val} = $tv;
    } else {
        if ( iscontainer($t->{Type}) ){
            say '# FIXME: bind(): need to check the types of the elements of the container!' if $FIXME; 
            $t->{Type}->[3]=ref($t->{Type});
            $t->{Type}->[4]=[];
#            die Dumper($t->{Type});
            $t->{Val} = $tv;
        } elsif(ref($tv) eq 'CODE') {#die 'CODE';
            # Function. We are assuming functions are typed but prim type args can be bare
            # So we check the arguments when the function is call, if they are prim but not bare we make them that way
            # Maybe do the same for containers holding prims
            my $wrapper = sub { (my @args)=@_;
                  my $tt=$t;
               if(ref($t) eq 'CODE') {
                   $tt=$t->();
               }
#               say 'QQ:'.Dumper($tt);
                if (@args == 0) {
                    return $tt->{Type};
                }
              
                my $ii=0;
                for my $arg (@args) {      
                    say 'ARG:'.Dumper($arg);              
                    my $argtype=$tt->{Type}->[1]->[$ii++];
                    if (istypedval($arg)) {
                        say 'ARGTYPE:'.Dumper($argtype).Dumper($arg->{Type});
                        (my $st, my $t1, my $t2)=typecheck($argtype,$arg->{Type});                        
                        if (not $st) {
                            die "Typecheck failed in bind($t1,$t2)"; 
                        }
                        if (isprim($argtype)) {
                            $arg = untype $arg;
                        } elsif (isprimcontainer($argtype)) {
                               $arg = untype $arg;
                        }
                    } elsif (isprim($argtype)) {
                        # OK
                    } else {
                        # arg is bare
                        die "Type error: untyped arg, expecting $argtype!";
                    }
                    
                }
                my $retval = $tv->(@args);
                if (ref($retval) ne 'Functional::Types') {
                    my $ret_type=$tt->{Type}->[1]->[-1];
                    if(ref($ret_type) eq 'ARRAY') {
                        $ret_type=$ret_type->[0];
                    }
                    if (isprim($ret_type) ) {
                        return bless({Type=>bless(['$',$ret_type,[],$ret_type,[]],'Scalar'),Val=>$retval},'Functional::Types')
                    } elsif( isprimcontainer($ret_type)) {                         
                           return bless( {Type=>$ret_type,Val=>$retval},'Functional::Types');
                    } else {
                    # type the return value
                    die 'RETVAL:'.Dumper($retval)."\nRETTYPE:".Dumper($ret_type);       
                                 
                    return eval("$ret_type($retval)");
                    }
                } else {
                    return $retval;
                }                
            };            
#            $t=$wrapper;
            $_[0] = $wrapper;            
        } else {
            die "TYPE NOT PRIM:".Dumper($t);
        }        
    }
    }
}

# untype just recursively removes the type information
sub untype {    
    ( my $th ) = @_;
    say "UNTYPE():".Dumper($th) if $VV;
    if (ref($th) eq 'ARRAY') {
        my @untyped_vals = ();
        for my $elt ( @{$th} ) {
                say "UNTYPE RECURSION IN ARRAY (TOP)\n";
                die "SHOULD NOT HAPPEN!";
                push @untyped_vals, untype($elt);
            }
             return [@untyped_vals];
    } elsif (ref($th) eq 'Functional::Types') {
    my $k   = $th->{Type}[0];
    my $val = $th->{Val};
    if ( not defined $k ) {
        die 'UNTYPE:' . Dumper($th);
    }
    if ( $k ne '@' and $k ne '$' and $k ne '%' and $k ne '*' ) {  # NOT a scalar
        if ( ref($val) eq 'ARRAY' ) {
            my @untyped_vals = ();
            for my $elt ( @{$val} ) {
                say "UNTYPE RECURSION IN ARRAY\n" if $VV;
                push @untyped_vals, untype($elt);
            }
            return [@untyped_vals];
        } elsif ( ref($val) eq 'HASH' ) {

# As this is not a scalar, it must be a record with named fields. Unless of course it is a typed value!
            if ( istypedval($val) ) {

                # it's a typed value, just untype it
                say "UNTYPE RECURSION IN HASH\n" if $VV;
                return untype($val);
            } else {
                my $untyped_rec = {};
                for my $k ( keys %{$val} ) {
                    say "UNTYPE RECURSION IN HASH VALUES\n" if $VV;
                    $untyped_rec->{$k} = untype( $val->{$k} );
                }
                return $untyped_rec;
            }
        } elsif ( ref($val) eq 'Functional::Types' ) {

            # This is basically the same as a typed value
            say "UNTYPE RECURSION IN Types\n" if $VV;
            return untype($val);
        } else {

            # must be a scalar, just return it
            return $val;
        }
    } elsif ( $k eq '&' ) {

        # a function
        my $tf = $val->();
        return $tf->{Val};
    } else {    # it must be a scalar
        return $val;    # AS-IS
    }
    } else {
#        die "UNTYPE: NOT A REF: ".Dumper($th);
        return $th;
    }
}    # END of untype()



sub show_prim {
    ( my $v, my $tn ) = @_;    
    if (ref($tn) eq 'ARRAY') {
        $tn=$tn->[0];
    }
    if ( $tn eq 'String' ) {
        return '"' . $v . '"';
    } elsif ( $tn eq 'Bool' ) {
        return ( $v ? 'True' : 'False' );
    } else {
        return $v;
    }
}

sub show {
    ( my $tv ) = @_;
#    local $VV=1;
    say '=' x 80 if $VV;
    say 'SHOW:'.Dumper($tv) if $VV;
    if (ref($tv) eq 'Functional::Types') {
    my $t  = $tv->{Type};
    
#    my $k  = $t->[0];
# This is the typename, so only a 'first guess', actual value depends on the prototype 
    my $tn = $t->[1];       # Note that this can actually be an array ref!
    my $v  = $tv->{Val};
    if ( $t->isa('Scalar') ) {        
        return show_prim( $v, $tn );
    } elsif ( $t->isa('Array' ) ) {
        $tn = $t->[2]->[0];
        my @s_vals = ();
        
 # Now, if the type is prim, I should just return it. Otherwise, first show() it
 # so I need isprim as a check
        if ( isprim($tn) ) { 
            for my $elt ( @{$v} ) {
                push @s_vals, show_prim( $elt, $tn );
            }
        } else {
            for my $elt ( @{$v} ) {
                push @s_vals, show($elt);
            }
        }
        my $sv_str = join( ', ', @s_vals );
        return "[$sv_str]";

    } elsif ( $t->isa( 'Map' ) ) {
        my $hvt = $t->[2][1];

        # we return a list of key-value pairs
        my @kv_lst = ();
        if ( isprim($hvt) ) {
            for my $hk ( keys %{$v} ) {
                my $hv = show_prim( $v->{$hk}, $hvt );
                push @kv_lst, [ $hk, $hv ];
            }
        } else {

            # first show the values
            for my $hk ( keys %{$v} ) {
                my $hv = show( $v->{$hk} );
                push @kv_lst, [ $hk, $hv ];
            }
        }
        my @kv_str_lst = map { '("' . $_->[0] . '", ' . $_->[1] . ')' } @kv_lst;
        my $kv_lst_str = join( ', ', @kv_str_lst );
        return 'fromList [' . $kv_lst_str . ']';

    } elsif ( $t->isa(  'Tuple' ) ) {    # Tuple type
        $tn=$t->[2];    
        my @tns    = @{$tn};
        my @s_vals = ();
        my $ii=0;
        for my $et (@tns) {
            my $ev = $v->[$ii++];
            say 'E:'.Dumper($et).isprim($et);
            my $sv = isprim($et) ? show_prim( $ev, $et ) : do { say 'HERE'.Dumper($et);show($ev)};
            push @s_vals, $sv;
        }
        return '(' . join( ', ', @s_vals ) . ')';
    } elsif ( $t->isa(  'Record' ) ) {
#        die Dumper($t);
        my $ctor   = $t->[1];
        my @tns    = @{ $t->[2] };
        my @s_vals = ();
        my $ii=0;
        for my $et (@tns) {
            my $ev = $v->[$ii++];
            my $sv = isprim($et) ? show_prim( $ev, $et ) : show($ev);
            if ( $sv =~ /\s/ ) { $sv = "($sv)" }
            push @s_vals, $sv;
        }
        my $svret= $ctor . ' ' . join( ' ', @s_vals );
#        say Dumper($svret);
        return $svret;
    } elsif ( $t->isa(  'NamedRecord' ) ) { #say 'SHOW NAMEDREC: T:'. Dumper($t)."\nV:".Dumper($v);
        my $ctor   = $tn;
        my @tns    = @{ $t->[2] };
        my @s_vals = ();
        my $idx    = 0;
#        my $ii=0;
        while ( $idx < @tns )
        { # Note that the first elt is the field name! Maybe I should encode them as arefs
            my $fn = $tns[$idx];
            my $ft = $tns[ $idx + 1 ];
            $idx += 2;
            my $ev = $v->{$fn};
            my $sv = isprim($ft) ? show_prim( $ev, $ft ) : show($ev);
            if ( $sv =~ /\s/ ) { $sv = "($sv)" }
            push @s_vals, "$fn = $sv";
        }        
        return $ctor . ' {' . join( ', ', @s_vals ) . '}';
    } elsif ( $t->isa( 'Variant' ) ) {
        my $ctor = $tn;    # This is fine.
        # A Variant will always take a typed value, so we just show that
        if (defined $v) {
            if (ref($v) eq 'ARRAY' and @{$v}) {
        return '('.$ctor . ' ' . join(' ',map {show($_)} @{$v}).')';
            } elsif (ref($v) eq 'Functional::Types') {
                $tn.' '.show($v);
            } else {
                die 'NOT ARRAY:'.Dumper($v);
            }
        } else {
            return $ctor; 
        }
    } elsif ( $t->isa(  'Function' ) ) {
        die "It is not possible to show() a function\n";
    } else {
        die "Unknown kind ".ref($t)."\n";
    }
    } else {
        return $tv;
    }
} # END of show()

sub read {
    say Dumper(@_);
    my $res = eval($_[0]);
    return $res;
}

sub match {
    (my $tv)=@_;
    if (ref($tv->{Val}) eq 'ARRAY') {
        return @{$tv->{Val}}
    } else {
    return $tv->{Val};
    }
}

################################################################################
#   PROTOTYPES
################################################################################

=head1 PROTOTYPES

* These are *not* to be called directly, only as part of a newtype call, unless you know what you're doing.

* I realise it would be faster for sure to have numeric codes rather than strings for the different prototypes. 

The prototype call returns information on the kind of type, the type constructor and the arguments. Currently:

* PRIM, storing untyped values:

  Scalar: ['$', $type], Val = $x => NEVER used as-is
  
  Array: ['@', $type], Val = [@xs] 
  Hash: ['%', [$ktype,$vtype]], Val = {@kvpairs}
  Tuple: ['*', [@tupletypes]], Val = [@ts]

* PROPER, storing only typed values:

  Variant: ['|', $ctor, [@ctor_args],$typename,[@typename_args]], Val = ???
  Record: ['~', $ctor, [@ctor_args],$typename,[@typename_args]], Val = ???
  Record with fields: [':', $ctor, [@ctor_args_fields],$typename,[@typename_args]] , Val = {}

* FUNCTION, the function can itself take typed values or untyped ones, depending on cast() or bind()
    What we store is actually a wrapper around the function, to deal with the types
    So we should somehow get the original function back. I think we can do this by calling the wrapper without any arguments,
    in which case it should return a typed value with the function's type in Type and the original function in Value
    Anyhow untype() only makes sense for a function that works on untyped values of course
    
  Function: ['&',[@function_arg_types]], Val = \&f

In a call to type() the argument will only return [$typename,[@typename_args]]
For a scalar type I could just return $typename but maybe consistency? 

In a newtype call, the primitive types don't have a constructor.
There is some asymmetry in the '$' type compared to the others:

Normally the pattern is Prototype($typename) but for primitive types it is just Scalar() and the prim type's typename comes from caller()

Also, prim types are created without newtype(), I think I should hide this behaviour.

Maybe I need to distinguish between a new data and a type alias, it would certainly clarify things; 
Also, I guess for a type alias for a prim type we can feed it an untyped value.
 
=cut

sub Scalar {
    my @c = caller(1);
    my $t = $c[3];
    $t =~ s/^.+:://;
    if (@_) {
        my $v = $_[0];
        if ( istypedval($v) ) {
            die 'Scalar:' . Dumper($v);
            untype($v);
        }
        return
          bless( { Val => $v, Type => bless( [ '$', $t, [], $t, [] ], 'Scalar' ) },
            'Functional::Types' );
    } else {
        return
        [$t,[]];
#          bless(['$',$t,[]],'Scalar');
          ; # Scalar should never be called without args except in a newtype() context.
    }
}


# What the Record() call does is create a type representation for the constructor. We need to complement this with the typename, newtype() should do that.
# For that reason, the typename should maybe be the last argument, we simply append it to the list. I don't think we need the '[', instead I will use ':' for named fields.

# --------------------------------------------------------------------------
sub Record {
    my @c                = caller(1);
    my $type_constructor = $c[3];
    $type_constructor =~ s/^.+:://;
    my $kind =
      $_[0] =~ /^[a-z_]/
      ? ':'
      : '~'
      ; # oblique way of saying that this record has named fields. newtype() should use this to create a hash for the values.
    my $maybe_named = ( $kind eq '~' ) ? '' : 'Named';
    my $type_representation =
      bless( [ $kind, $type_constructor, [@_] ], $maybe_named . 'Record' );
#      say 'RECORD:'.Dumper($type_representation);
    return $type_representation;
}

sub field {
(my $r, my $fn, my $v) = @_;

if (defined $v) {
    $r->{Val}->{$fn}=$v;
} else {
    return $r->{Val}->{$fn};
}

}
# --------------------------------------------------------------------------
sub Variant {
    my @c  = caller(1);
    my $tc = $c[3];
    $tc =~ s/^.+:://;
    say "Variant: TYPENAME: $tc" if $VV;
    say "Variant: TYPE ARGS: ", Dumper(@_) if $VV;
    my $type_representation = bless( [ '|', $tc, [@_] ], 'Variant' );
    return $type_representation;
}
# Given a typed value object, and assuming it is a Variant, return the type constuctor
sub variant {
    (my $tv) = @_;
#    say Dumper($tv->{Type});
        return $tv->{Type}->[1];    
}
# sub IntList { newtype Array(Int),@_ }
# type my $int_lst => Array(Int)
# let $int_lst, $untyped_lst;
# OR
# NO: let $int_lst, Array(@untyped_lst); # This is direct use of a prototype, NOT GOOD!
# OR
# my $int_lst = IntList(@untyped_lst);
# --------------------------------------------------------------------------
sub Array {    # Array Ctor only ever takes a single argument
    my @c   = caller(1);
    my $arg = $_[0] // [];
    say "Array: TYPE ARGS: ", Dumper(@_) if $VV;
    my $tc = 'Array';
    if (@c) {
        my $tc = $c[3];
        $tc =~ s/^.+:://;
        say "Array: TYPENAME: $tc";
    }
    my $type_representation = bless( [ '@', $tc, [$arg] ], 'Array' );
    return $type_representation;
}
# 'at' for array indexing
sub at {
    (my $a, my $idx, my $v) =@_;
    if (defined $v) { say '# FIXME: $v could be an untyped value!' if $FIXME;
        if (ref($v) eq 'Functional::Types') {
            if (typecheck($v->{Type}, $a->{Type})) {           
            $a->{Val}->[$idx] = $v->{Val};
            } else {
                die "Type error: ::at(".$v->{Type}[1] .") ";
            }   
        } else {
            say '# FIXME: at() must check if the corresponding type is primitive!' if $FIXME;
             $a->{Val}->[$idx] = $v;
        }
     } else {
        return  $a->{Val}->[$idx];
    }
}
sub length {
    (my $a)=@_;
    return scalar @{$a->{Val}};
}
sub push {
    say "PUSH:". Dumper(@_) if $VV;
    (my $a, my $v) =@_;
    push @{ $a->{Val} }, $v;
#            die "Type error: Array::push(".$v->{Type}[1] .") <> ";
}
sub pop {
    (my $a)=@_;
    return {'Val' => pop( @{$a->{Val}}), 'Type' => $a->{Type}->[2]};
}
sub shift {
    (my $a)=@_;
    return {'Val' => shift( @{$a->{Val}}), 'Type' => $a->{Type}->[2]};    
}
sub unshift {
    (my $a, my $v) =@_;
            if ($v->{Type} ~~ $a->{Type}[2]) {           

    unshift @{$a->{Val}}, $v->{Val};
     } else {
            die "Type error: Array::unshift(".$v->{Type}[1] .") ";
        }

}

sub elts {
    (my $a)=@_;
    return  @{ $a->{Val} };
}
# --------------------------------------------------------------------------


# The main question is always, should constructors with primitive types take typed values or bare values?
# 
# If I have a Map(String,Int) I think it is more intuitive to accept bare values. In this case, the underlying hash will store bare keys and values. 
# If I have a Map(String,ArgRec) then  the underlying hash will store typed values but bare keys. 
# The problem is what to return:
#  
#   my $v = $h->of ($k);
# 
# So, should $v be bare or typed? My feeling is that it should be typed. 
# But in case of
# 
#   $h->of($k,$v);
#   
# I think $v could be untyped. 
# 
# Which means that if $v is of a primitive type I should construct a typed value and return it. Does that make sense? Because we could always allow primitive values to be handled untyped. 
# In that case returning them untyped is better!
#   


# sub Hash { newtype Map(String,T2),@_ }
sub Map {
    my @c  = caller(1);
    my $tc = 'Map';
    if (@c) {
        $tc = $c[3];
        $tc =~ s/^.+:://;
        say "Map: TYPENAME: $tc";
        say "Map: TYPE ARGS: ", Dumper(@_);
    }
    my $type_representation = bless( [ '%', $tc, [@_] ], 'Map' );
    return $type_representation;
}

sub insert {
    ( my $h, my $k, my $v ) = @_;
    $h->{Val}{$k} = $v;
}    # but we could use 'of' with two arguments

sub of {
    ( my $h, my $k, my $v ) = @_;
    if ( defined $v ) {
say '# FIXME
     # To be correct, we need to unbox typed values
     # But I think I will assume $k is always a bare string and $v is stored as-is' if $FIXME;
        $h->{Val}{$k} = $v;
    } else {
#        say 'h->of():' . Dumper($h);
#        say 'of(k):' . Dumper($k);
        my $kv = $k;
        if ( istypedval($k) ) {
            $kv = $k->{Val};
        }
        my $retval = $h->{Val}{$kv};
#        say Dumper($retval);
        return $retval;
    }
}

sub has {
    ( my $h, my $k ) = @_;
    return exists $h->{Val}{ $k->{Val} };
}    # exists

sub keys {
    ( my $h ) = @_;

    #return ( map { { 'Val' => $_, 'Type' => $h->{Type}->[2] } }
    return keys( %{ $h->{Val} } );

}

sub size {
    ( my $h ) = @_;
    return scalar( CORE::keys( %{ $h->{Val} } ) );
}

# --------------------------------------------------------------------------
# sub ArgTup { newtype Tuple(T1,T2,T3),@_ }
sub Tuple {
    my @c  = caller(1);
    my $tc = 'Tuple';
    if (@c) {
        $tc = $c[3];
        $tc =~ s/^.+:://;
        say "Tuple: TYPENAME: $tc";
        say "Tuple: TYPE ARGS: ", Dumper(@_);
    }
    my $type_representation = bless( [ '*', $tc, [@_] ], 'Tuple' );
    return $type_representation;

}

# For function types, if we do e.g.
# sub MkParser {newtype Parser(a),Function(String => Tuple(Maybe a, String)),@_}
sub Function {
    my @c  = caller(1);
    my $tc = $c[3];
    $tc =~ s/^.+:://;
    my $type_representation = bless( [ '&', $tc, [@_] ], 'Function' );
    return $type_representation;
}
################################################################################

sub Int  (;$)  { Scalar(@_) }
sub String (;$) { Scalar(@_) }
sub Float (;$)  { Scalar(@_) }
sub Double (;$) { Scalar(@_) }

# Bool should evaluate its arg and return a type { Type => ['$','Bool'], Val => 1 or 0 }
sub Bool {
    if (@_) {
    my $b = $_[0] ? 1 : 0;
    Scalar($b);
    } else {
        Scalar();
    }
}
sub True {
    bless( { Type => bless(['$','True',[],'Bool',[]], 'Scalar'), Val => 1 }, 'Functional::Types');
}
sub False {
    bless( { Type => bless(['$','False',[],'Bool',[]], 'Scalar'), Val => 0 }, 'Functional::Types');
}
################################################################################

1;
