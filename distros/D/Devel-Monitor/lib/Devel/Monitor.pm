package Devel::Monitor;

use 5.008006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use Devel::Monitor ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our @EXPORT = qw();  #Export by default

our %EXPORT_TAGS = ( #Export as groups
    'all' => [ 
        qw(monitor
           print_circular_ref
        )
    ]
);

Exporter::export_ok_tags(    #Export by request (into @EXPORT_OK)
    'all');

our $VERSION = '0.9.0.7';

use Error qw(:try);
use Scalar::Util qw(isweak);
use Devel::Monitor::Common qw(:all);
use Devel::Monitor::Trace;
use Devel::Monitor::TraceItem;
use Devel::Monitor::Array;
use Devel::Monitor::Hash;
use Devel::Monitor::Scalar;
 
#Circular references type
use constant CRT_NONE              => undef;
use constant CRT_CIRC_REF          => 1;
use constant CRT_INTERNAL_CIRC_REF => 2;
use constant CRT_WEAK_CIRC_REF     => 3;

# METH monitor
#
# DESC Monitoring multiple variables
#      monitor('name for a' => \$a,
#              'name for b' => \$b,
#              'name for c' => \$c,
#              'name for d' => \@d,
#              'name for e' => \%e,
#              'name for F' => \&F);
# DESC Monitoring single constant variable (FOR INTERNAL USE ONLY)
#      monitor('name for F' => \&F, 1);
#      The last flag indicates that it is code reference          

sub monitor {
    my $isCode;
    $isCode = pop if scalar(@_) % 2 != 0;   
    my %values = @_;
    foreach my $key (keys %values) {
        my $varRef = $values{$key};
        if ($varRef) {  #If the value is undef
            _dereference(\$varRef);
            if ($varRef =~ /HASH/ ) {  #An hash object or an hash
                _tieHash($varRef,$key,$isCode);
            }
            elsif ($varRef =~ /SCALAR|REF/) {
                _tieScalar($varRef,$key,$isCode);
            }
            elsif ($varRef =~ /ARRAY/) {
                _tieArray($varRef,$key,$isCode);
            }
            elsif ($varRef =~ /CODE/) {
                ###########################################################
                # Info on constants
                ###########################################################
                # use constant CONST => [1,2];
                # print \&CONST."\n";
                # print &CONST."\n";
                # print \&CONST()."\n";
                # print &CONST()."\n";
                #
                # CODE(0x8203000)
                # ARRAY(0x81d4c04)
                # REF(0x820303c)
                # ARRAY(0x81d4c04)
                #
                # Code    Ref
                #   |      |
                # Array  Array
                #   |      |
                # +---+  +---+
                # |1,2|  |1,2|
                # +---+  +---+
                #
                ###########################################################
                # use constant CONST => 'a scalar';
                # print \&CONST."\n";
                # print &CONST."\n";
                # print \&CONST()."\n";
                # print &CONST()."\n";
                #
                # CODE(0x820300c)
                # a scalar
                # SCALAR(0x81fb2c4)
                # a scalar
                #
                #   Code        Scalar
                #     |            |
                # 'a scalar'  'a scalar'
                #
                # Instead of :
                #
                #   Code          Ref
                #     |            |
                #  Scalar       Scalar
                #     |            |
                # 'a scalar'  'a scalar'
                #
                ###########################################################
                if (ref(&$varRef) =~ /ARRAY|HASH/) {
                    _monitorRecursively($key => &$varRef);
                } else {
                    #_tieScalar($varRef);
                    Devel::Monitor::Common::printMsg("Scalar constant $key cannot be monitored\n");
                }
            }
            else {
                my $runPatch = 0;
                try {
                    _tieHash($varRef,$key);
                } otherwise {
                    ###########################################################
                    # Patch for Error.pm
                    # It seems there is a bug in this module
                    ###########################################################
                    # Example :
                    ###########################################################
                    # #!/usr/bin/perl
                    # use strict;
                    # use warnings;
                    # use Devel::Monitor;
                    # {
                    #     my @a = (1,2,3,4);
                    #     monitor('a'=>\@a);
                    #     print STDERR "Leaving scope\n";
                    # }
                    # print STDERR "Scope left\n";
                    ###########################################################
                    # Output without the patch (Very bad for mod_perl)
                    ###########################################################
                    # MONITOR ARRAY : a
                    # Leaving scope
                    # Scope left
                    # DESTROY ARRAY : a
                    ###########################################################
                    # Output with the patch (Ok)
                    ###########################################################
                    # MONITOR ARRAY : a
                    # Leaving scope
                    # DESTROY ARRAY : a
                    # Scope left
                    ###########################################################
                    $runPatch = 1;
                    #try {
                    #    _tieArray($varRef,$key);
                    #} otherwise {
                    #    Devel::Monitor::Common::printMsg("$varRef($key) cannot be monitored\n");
                    #};
                };
                if ($runPatch) {
                    try {
                        _tieArray($varRef,$key);
                    } otherwise {
                        Devel::Monitor::Common::printMsg("$varRef($key) cannot be monitored\n");
                    };
                }
            }
        }
    }
}
 
sub _monitorRecursively {
    my %values = @_;
    foreach my $key (keys %values) {
        my $varRef = $values{$key};
        if ($varRef) {  #If the value is undef
            _dereference(\$varRef);
            if ($varRef =~ /HASH/ ) {  #An hash object or an hash
                HASH_ITEM:
                foreach my $item (keys %$varRef) {
                    #print STDERR "ITEM : ".$varRef->{$item}."\n";
                    _monitorRecursively("$key {$item}" => \($varRef->{$item}));
                }
            }
            elsif ($varRef =~ /SCALAR/) {
                # nothing
            }
            elsif ($varRef =~ /ARRAY/) {
                ARRAY_ITEM:
                my $i = 0;
                foreach my $item (@$varRef) {
                    #print STDERR "ITEM : ".$item."\n";
                    _monitorRecursively("$key [$i]" => \$item);
                    $i++;
                }
            }
            elsif ($varRef =~ /CODE/) {
                # nothing
            }
            else {
                my $runPatch = 0;
                try {
                    goto HASH_ITEM;
                } otherwise {
                    $runPatch = 1;
                };
                if ($runPatch) {
                    try {
                        goto ARRAY_ITEM;
                    } otherwise {
                        #Devel::Monitor::Common::printMsg("$varRef($key) cannot be monitored recursively\n");
                        #we call monitor, this one will print the error
                    };
                }
            }
            # Finally, monitor current variable
            monitor($key => $varRef, 1);
        }
    }
}
 
sub _tieHash {
    my $varRef = shift;
    my $name = shift;
    my $isCode = shift;
 
    if (not tied %$varRef) {
        tie %$varRef, 'Devel::Monitor::Hash', $varRef, $name, $isCode;
    } else {
        my $self = tied %$varRef;
        #if tied by our Devel::Monitor
        if (ref($self) =~ /Devel::Monitor/) {
            Devel::Monitor::Common::printMsg("Hash from $name is already tied by ".$self->{Devel::Monitor::Common::F_ID()}."\n");
        } else {
            Devel::Monitor::Common::printMsg("Array from $name is already tied by the ".ref($self)." package\n");
        }
    }
}
 
sub _tieArray {
    my $varRef = shift;
    my $name = shift;
    my $isCode = shift;
 
    if (not tied @$varRef) {
        tie @$varRef, 'Devel::Monitor::Array', $varRef, $name, $isCode;
    } else {
        my $self = tied @$varRef;
        #if tied by our Devel::Monitor
        if (ref($self) =~ /Devel::Monitor/) {
            Devel::Monitor::Common::printMsg("Array from $name is already tied by ".$self->{Devel::Monitor::Common::F_ID()}."\n");
        } else {
            Devel::Monitor::Common::printMsg("Array from $name is already tied by the ".ref($self)." package\n");
        }
    }
}
 
sub _tieScalar {
    my $varRef = shift;
    my $name = shift;
    my $isCode = shift;
 
    if (not tied $$varRef) {
        try {
            tie $$varRef, 'Devel::Monitor::Scalar', $varRef, $name, $isCode;
        } otherwise {
            Devel::Monitor::Common::printMsg("Scalar from $name is read-only, monitor skipped\n");
        };
    } else {
        my $self = tied $$varRef;
        #if tied by our Devel::Monitor
        if (ref($self) =~ /Devel::Monitor/) {
            Devel::Monitor::Common::printMsg("Scalar from $name is already tied by ".$self->{Devel::Monitor::Common::F_ID()}."\n");
        } else {
            Devel::Monitor::Common::printMsg("Array from $name is already tied by the ".ref($self)." package\n");
        }
    }
}
 
#Not used
# sub unmonitor {
    # my @varsRef = @_;
    # foreach my $varRef (@varsRef) {
        # if ($varRef) {
            # _dereference(\$varRef);
            # if ($varRef =~ /HASH/ ) {  #An object or an hash
                # Devel::Monitor::Hash::unmonitor($varRef);
            # }
            # elsif ($varRef =~ /SCALAR/) {
                # Devel::Monitor::Scalar::unmonitor($varRef);
            # }
            # elsif ($varRef =~ /ARRAY/) {
                # Devel::Monitor::Array::unmonitor($varRef);
            # }
            # elsif ($varRef =~ /CODE/) {
                # unmonitor(&$varRef); #TODO : Unmonitor recursively, do not touch scalars
            # }
            # else {
                # my $runPatch = 0;
                # try {
                    # Devel::Monitor::Hash::unmonitor($varRef);
                # } otherwise {
                    # $runPatch = 1;
                # };
                # if ($runPatch) {
                    # try {
                        # Devel::Monitor::Array::unmonitor($varRef);
                    # } otherwise {
                         # Devel::Monitor::Common::printMsg("$varRef cannot be unmonitored\n");
                    # };
                # }
            # }
        # }
    # }
# }
 
sub _dereference {
    my $varRefRef = shift;
    my $type = ref($$varRefRef);
    #print STDERR "VARIABLE : $$varRefRef\n";
    #print STDERR "TYPE     : $type\n";
    ##############################################################
    # You need to dereference, otherwise, you may
    # get this error : Modification of a read-only value attempted
    # is you monitor a variable that use a constant by example
    ##############################################################
    while ($type =~ /REF/) {
        $$varRefRef = $$$varRefRef;
        $type = ref($$varRefRef);
        #print STDERR "V        : $$varRefRef\n";
        #print STDERR "T        : $type\n";
    }
}
 
# METH printCircularRef
#  
# DESC Try to find circular references and print it out into STDERR

#Little redirect to be "Perl compliant"
#TODO : use the underscore syntax
sub print_circular_ref { return printCircularRef(@_); }

sub printCircularRef {
    my $varRef = shift;
    my $hideWeakenedCircRef = shift; #Boolean
    my $source = shift;
    my $trace = shift; #A array container containing the current trace
    my $weakenedRef = shift; #A array containing the trace to the weakened ref it any
    my $origRef = shift; #Contains original reference to verify circular references
    my $seenRef = shift;
    my $circRefTypesRef = shift;
           
    #print STDERR "###############################################################\n";
    #print STDERR "VARIABLE : ".$varRef."\n";
    #print STDERR "TYPE     : ".ref($varRef)."\n";
    my $isFirst = (!$origRef);    
    $trace = Devel::Monitor::Trace->new() if not $trace;
    $weakenedRef = [] if not $weakenedRef;
    $seenRef = {} if not $seenRef;
    $circRefTypesRef = [] if not $circRefTypesRef;

    return undef if not $varRef;
        
    my $isWeak = 0;
    my $simpleSeenRef = {};
    #Since we dereference scalars, they are not displayed on the final prints
    while ($varRef =~ /REF/) {
        #print STDERR "DEREFERING $varRef ($$varRef)\n";
        #print STDERR "Current variable : $varRef from ".\$varRef."\n";
        if (isweak($$varRef)) {
            $isWeak = 1;
            #print STDERR "WEAK for $$varRef\n";            
            push(@$weakenedRef, $$varRef);
        }
        _addSeenRef($varRef,$simpleSeenRef);
        #Exceptional case : $a = \$a or $a = \$b = \$c
        #TODO : This "if" should not be handled as an exception (At least, we should try)     
        if (exists($simpleSeenRef->{$varRef}) && ($simpleSeenRef->{$varRef} > 1)) {         
            if ($isFirst) {
                _printCircularRefHeader($varRef);
                push(@$circRefTypesRef, CRT_CIRC_REF());
                Devel::Monitor::Common::printMsg("-------------------------------------------------------------------------------\n");                
                Devel::Monitor::Common::printMsg("Circular reference on scalar(s) starting at $varRef\n");
                Devel::Monitor::Common::printMsg("-------------------------------------------------------------------------------\n");                
                _printCircularRefResults($varRef,$circRefTypesRef);
            } else {
                push(@$circRefTypesRef, CRT_INTERNAL_CIRC_REF());
                Devel::Monitor::Common::printMsg("-------------------------------------------------------------------------------\n");
                Devel::Monitor::Common::printMsg('Internal circular reference on scalar(s) starting at : '.$trace->getCircularPath()."\n");
                $trace->dump();
                Devel::Monitor::Common::printMsg("-------------------------------------------------------------------------------\n");
            }
            return undef;
        }
        
        $varRef = $$varRef;
    }
    $trace->push($varRef,$source);
    _addSeenRef($varRef,$seenRef) if $origRef; #We skip the first item which is $origRef
    #print STDERR "--------------------------------------------\n";
    #print STDERR "Current variable : $varRef from ".\$varRef."\n";    
    my $circRefType = _checkCircularRef($varRef,$hideWeakenedCircRef,$trace,$weakenedRef,$origRef,$seenRef);
    #print STDERR "\$circRefType : $circRefType\n";
    if ($circRefType) {
        $trace->pop();
        push(@$circRefTypesRef, $circRefType);
        return undef; #Don't go any further because we loop
    }
    if ($isFirst) {
        $origRef = $varRef;
        _printCircularRefHeader($origRef);
    }    
    
    #print STDERR 'Current trace : '.$trace->getCircularPath()."\n";
    _printCircularRef($varRef,$hideWeakenedCircRef,$source,$trace,$weakenedRef,$origRef,$seenRef,$circRefTypesRef);
    
    #We go into another branch
    $trace->pop();
    pop(@$weakenedRef) if $isWeak; # Remove weakened item 
    delete($seenRef->{$varRef});  # Remove varRef from "seen" hash
    
    _printCircularRefResults($origRef,$circRefTypesRef) if $isFirst;
    
    return undef;
}
 
sub _printCircularRef {
    my $varRef = shift;
    my $hideWeakenedCircRef = shift;
    my $source = shift;
    my $trace = shift;
    my $weakenedRef = shift;
    my $origRef = shift;
    my $seenRef = shift;
    my $circRefTypesRef = shift;
      
    if ($varRef =~ /HASH/ ) {  #An object or an hash
        HASH_ITEM:
        Devel::Monitor::Common::printMsg('Object '.$trace->getCircularPath().' = '.$varRef." is tied. Untie it to check circular references for this object.\n") if tied(%$varRef);          
        foreach my $item (keys %$varRef) {
            my $ref = _getVarRef(\($varRef->{$item}));
            printCircularRef($ref,$hideWeakenedCircRef,'{'.$item.'}',$trace,$weakenedRef,$origRef,$seenRef,$circRefTypesRef);
        }
    }
    elsif ($varRef =~ /SCALAR|CODE/) {
        #No circular references are possible here, so we don't do anything
    }
    elsif ($varRef =~ /ARRAY/) {
        ARRAY_ITEM:
        Devel::Monitor::Common::printMsg('Object '.$trace->getCircularPath().' = '.$varRef." is tied. Untie it to check circular references for this object.\n") if tied(@$varRef);
        for (my $i=0; $i<scalar(@$varRef); $i++) {
            #print STDERR "CURRENT VAR  : ".\($varRef->[$i])." ::: ".$varRef->[$i]."\n";
            my $ref = _getVarRef(\($varRef->[$i]));
            #Devel::Monitor::Common::printMsg('Object at '.$trace->getCircularPath().'['.$i.']'.
            #" is ARRAY ARRAY ARRAY tied. We cannot check circular references for this object.\n") if $ref =~ /SCALAR/;            
            printCircularRef($ref,$hideWeakenedCircRef,'['.$i.']',$trace,$weakenedRef,$origRef,$seenRef,$circRefTypesRef);
        }
    } else {
        #Other objects
        my $runPatch = 0;
        try {
             goto HASH_ITEM;
        } otherwise {
            $runPatch = 1;
        };
        if ($runPatch) {
            try {
                goto ARRAY_ITEM;
            } otherwise {
                die("Cannot verify circular references for $varRef of type ".ref($varRef)."\n"); 
            };
        }
    }
}

sub _printCircularRefHeader {
    my $origRef = shift;
    
    Devel::Monitor::Common::printMsg("-------------------------------------------------------------------------------\n");
    Devel::Monitor::Common::printMsg("Checking circular references for $origRef\n");
}
        
sub _printCircularRefResults {
    my ($origRef, $circRefTypesRef) = @_;
    
    my $circRefsCount = 0;
    my $internalCircRefsCount = 0;
    my $weakCircRefsCount = 0;
    foreach my $crt (@$circRefTypesRef) {
        $weakCircRefsCount++ if $crt == CRT_WEAK_CIRC_REF();
        $circRefsCount++ if $crt == CRT_CIRC_REF();
        $internalCircRefsCount++ if $crt == CRT_INTERNAL_CIRC_REF();
    }
    Devel::Monitor::Common::printMsg("-------------------------------------------------------------------------------\n");        
    Devel::Monitor::Common::printMsg("Results for $origRef\n");
    Devel::Monitor::Common::printMsg("Circular reference          : $circRefsCount\n");
    Devel::Monitor::Common::printMsg("Internal circular reference : $internalCircRefsCount\n");
    Devel::Monitor::Common::printMsg("Weak circular reference     : $weakCircRefsCount\n");
    Devel::Monitor::Common::printMsg("-------------------------------------------------------------------------------\n");        
}
    
# METH _checkCircularRef
# 
# DESC Verify if there is a circular reference on the current variable
# RETV Circular Reference Type
#      One of : CRT_NONE, CRT_CIRC_REF, CRT_WEAK_CIRC_REF, CRT_INTERNAL_CIRC_REF

sub _checkCircularRef {
    my $varRef = shift;
    my $hideWeakenedCircRef = shift;
    my $trace = shift;
    my $weakenedRef = shift;
    my $origRef = shift;
    my $seenRef = shift;
    if ($varRef) {
        #print STDERR "\$varRef  : $varRef\n";
        #print STDERR "\$origRef : $origRef\n";
        if ($origRef) {
            #If we found the original reference
            my $isCircRef = ($varRef eq $origRef);
            #If we found a reference more than one time, it means we loop infinitely
            my $isInternalCircRef = (exists($seenRef->{$varRef}) && ($seenRef->{$varRef} > 1));
            
            if ($isCircRef || $isInternalCircRef) {
                my $weakenedInCircRefRef = _getWeakenedInCircRef($trace,$weakenedRef);
                my $isWeakenedItems = (scalar(@$weakenedInCircRefRef) > 0);
                if (!$hideWeakenedCircRef ||  #If we show everything
                    ($hideWeakenedCircRef && !$isWeakenedItems)) {  #Otherwise, if there is no weak reference
                    
                    Devel::Monitor::Common::printMsg("-------------------------------------------------------------------------------\n");
                    if ($isCircRef) {
                        Devel::Monitor::Common::printMsg('Circular reference found : '.$trace->getCircularPath()."\n");
                    }
                    elsif ($isInternalCircRef) {
                        Devel::Monitor::Common::printMsg('Internal circular reference found : '.$trace->getCircularPath()." on $varRef\n");    
                    }                
                    if ($isWeakenedItems) {
                        Devel::Monitor::Common::printMsg('with weakened reference on : '.join(', ', @$weakenedInCircRefRef)."\n");
                    }
                    $trace->dump();
                    Devel::Monitor::Common::printMsg("-------------------------------------------------------------------------------\n");
                    return CRT_WEAK_CIRC_REF()     if $isWeakenedItems;
                    return CRT_CIRC_REF()          if $isCircRef;
                    return CRT_INTERNAL_CIRC_REF() if $isInternalCircRef;
                    die("_checkCircularRef : Should not be here (1)\n");
                }
                elsif ($hideWeakenedCircRef && $isWeakenedItems) {
                    return CRT_WEAK_CIRC_REF();
                }
            }
        }            
        return CRT_NONE();
    }
    die("_checkCircularRef : \$varRef is undefined\n");
}

sub _addSeenRef {
    my $varRef = shift;
    my $seenRef = shift;
    #print STDERR "_addSeenRef: $varRef\n";
    if (exists($seenRef->{$varRef})) {
        $seenRef->{$varRef}++;
    } else { 
        $seenRef->{$varRef} = 1;
    }
}

sub _getVarRef {
    my $varRef = shift;
    ###########################################################
    # We cannot use tied objects because it reuse memory space
    ###########################################################
    # use Tie::Hash;
    #
    # my $self = {'a' => 1,
    #             'b' => 2};
    # #monitor('self' => \$self);
    # tie %$self, 'Tie::StdHash';
    # print STDERR \($self->{'a'})."\n";
    # print STDERR \($self->{'b'})."\n";
    # print STDERR \($self->{'a'}).\($self->{'b'})."\n";
    # foreach my $key (keys %$self) {
    #     my $keyRef = \$key;
    #     my $value = $self->{$key};
    #     my $valueRef = \($self->{$key});
    #     print STDERR "KEY:$key, KEY REF:$keyRef, VALUE:$value, VALUE REF:$valueRef\n";
    # }   
    ###########################################################
    # Output
    ###########################################################
    # MONITOR HASH : self
    # SCALAR(0x8141384)
    # SCALAR(0x8141384)
    # SCALAR(0x8141384)SCALAR(0x81413cc)
    # KEY:a, KEY REF:SCALAR(0x8141420), VALUE:1, VALUE REF:SCALAR(0x824becc)
    # KEY:b, KEY REF:SCALAR(0x81413cc), VALUE:2, VALUE REF:SCALAR(0x824becc)
    # DESTROY HASH : self
    ###########################################################
    # We see clearly that it reuse memory space instead of
    # refering to the original values from the untied object 
    ###########################################################
    my $ref;
    #if ($$varRef &&
    #    ($varRef =~ /SCALAR/) &&
    #    ($$varRef =~ /(ARRAY|HASH)/)) {
    #    $ref = $$varRef;
    #} else {
        $ref = $varRef;   
    #}  
    return $ref;
}

sub _getWeakenedInCircRef {
    my $trace = shift;
    my $weakenedRef = shift;

    my @weakenedInCircRef;
    my $traceItemsRef = $trace->getTraceItems;
    #The last item represent the circular reference    
    my $traceItemCircRef = $traceItemsRef->[$#$traceItemsRef];
    #for my $i (($#$traceItemsRef-1)..0) {
    for (my $i=($#$traceItemsRef-1); $i>=0; $i--) {
        #Get the current item
        my $traceItem = $traceItemsRef->[$i];
        #print STDERR "traceItem ".$traceItem->getVarRef()."\n";
        #We verify that the item is a weaken reference or not
        foreach my $weakened (@$weakenedRef) {
            #print STDERR "weakened ".$weakened."\n";
            if ($traceItem->getVarRef() eq $weakened) {
                #print STDERR "push\n";
                push(@weakenedInCircRef, $weakened);   
            }
        }
        #We finish when we end the circular reference
        last if ($traceItem->getVarRef() eq $traceItemCircRef->getVarRef());
    }
    #print STDERR "RETURN ".join(', ', @weakenedInCircRef)."\n";
    return \@weakenedInCircRef;
}
 
1;

__END__
 
=head1 NAME

Devel::Monitor - Monitor your variables/objects for memory leaks
    
=head1 DESCRIPTION

You have memory leaks, and you want to remove it... You can use this tool to help
you find which variables/objects that are not destroyed when they should be, and
thereafter, you can visualise exactly where is the circular reference for some
specific variables/objects.

=head1 WHAT IT CAN'T DO

Even if your modules are memory leak free, it doesn't mean that external modules
that you are using don't have it. So, before running your application on mod_perl,
you should be sure that EVERY modules are ok. (In particular those perl extensions
calling C++ code)

=head1 SYNOPSIS
 
    use Devel::Monitor qw(:all);
 
    #-----------------------------------------------------------------------------
    # Monitor scalars, arrays, hashes, references, constants                      
    #-----------------------------------------------------------------------------
    my ($a,$b) = (Foo::Bar->new(), Foo::Bar->new());
    my ($c, @d, %e);
    use constant F => [1,2];
    monitor('name for a' => \$a,
            'name for b' => \$b,
            'name for c' => \$c,
            'name for d' => \@d,
            'name for e' => \%e,
            'name for F' => \&F); #NOTE : Dont add parentheses to the end of the constant (\&F())
 
    #-----------------------------------------------------------------------------
    # Print circular references                                                   
    #-----------------------------------------------------------------------------
    # NOTE : You cannot use print_circular_ref on a monitored/tied variable 
    #        (See "We cannot use tied objects references because it reuse memory space" doc)
    print_circular_ref(\$a);
    print_circular_ref(\$b);
    print_circular_ref(\$c);
    print_circular_ref(\@d);
    print_circular_ref(\%e);
    print_circular_ref(\&F); #NOTE : Dont add parentheses to the end of the constant (\&F())

=head1 USAGE : monitor
 
=head2 Example with a circular reference

    +----------------------+
    | Code                 |
    +----------------------+
    {
        my @a;
        monitor('a' => \@a);
        $a[0] = \@a; #Add a circular reference
        print STDERR "Leaving scope\n";
    }
    print STDERR "Scope left\n";
     
    +----------------------+
    | Output               |
    +----------------------+
    MONITOR ARRAY a
    Leaving scope
    Scope left                       
    DESTROY ARRAY a
     
    +----------------------+
    | Meaning              |
    +----------------------+
    The line "DESTROY ARRAY a" should be between scope prints.
    @a were deleted on program exit.
     
=head2 Example without a circular reference

    +----------------------+
    | Code                 |
    +----------------------+
    {
        my @a;
        monitor('a' => \@a);
        print STDERR "Leaving scope\n";
    }
    print STDERR "Scope left\n";
     
    +----------------------+
    | Output               |
    +----------------------+
    MONITOR ARRAY a
    Leaving scope
    DESTROY ARRAY a
    Scope left
     
    +----------------------+
    | Meaning              |
    +----------------------+
    Everything is ok
 

Now that you know there is a circular reference, you can track it down using the print_circular_ref method

=head1 USAGE : print_circular_ref

=head2 Example

    +----------------------+
    | Code                 |
    |         a            |
    |        / \           |
    |      [0] [1]         |
    |      /     \         |
    |  'asdf'     b <--|   |
    |              \   |   |
    |              [3]-|   |
    |                      |
    +----------------------+
    my (@a, @b);
    $a[0] = 'asdf';
    $a[1] = \@b;
    $b[3] = \@b;
    print_circular_ref(\@a);
    print_circular_ref(\@b);
 
    +----------------------+
    | Output               |
    +----------------------+
    -------------------------------------------------------------------------------
    Checking circular references for ARRAY(0x814e358)
    -------------------------------------------------------------------------------
    Internal circular reference found : ARRAY(0x814e358)[1][3] on ARRAY(0x814e370)
    1 - Item     : ARRAY(0x814e358)
    2 - Source   : [1]
        Item     : ARRAY(0x814e370)
    3 - Source   : [3]
        Item     : ARRAY(0x814e370)
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    Results for ARRAY(0x814e358)
    Circular reference          : 0
    Internal circular reference : 1
    Weak circular reference     : 0
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    Checking circular references for ARRAY(0x814e370)
    -------------------------------------------------------------------------------
    Circular reference found : ARRAY(0x814e370)[3]
    1 - Item     : ARRAY(0x814e370)
    2 - Source   : [3]
        Item     : ARRAY(0x814e370)
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    Results for ARRAY(0x814e370)
    Circular reference          : 1
    Internal circular reference : 0
    Weak circular reference     : 0
    -------------------------------------------------------------------------------
 
=head1 TRACKING MEMORY LEAKS
 
=head2 How to remove Circular references in Perl
 
    #------------------------------------------------------------------------------+
    #
    # Let's say we have this basic code :
    #
    #------------------------------------------------------------------------------+
     
    #!/usr/bin/perl
     
    #--------------------------------------------------------------------
    # Little program
    #--------------------------------------------------------------------
     
    use strict;
    use warnings;
    use Devel::Monitor qw(:all);
     
    {
        my $a = ClassA->new();
        my $b = $a->getClassB();
        monitor('$b' => \$b);
        $b->getClassA()->printSomething();
        print "Leaving scope\n";
    }
    print "Scope left\n";
     
    #--------------------------------------------------------------------
    # ClassA (Just a class with the "printSomething" method)
    #--------------------------------------------------------------------
     
    package ClassA;
    use strict;
    use warnings;
    use Scalar::Util qw(weaken isweak);
     
    sub new {
        my ($class) = @_;
        my $self = {};
        bless($self => $class);
        return $self;
    }
     
    sub getClassB {
        my $self = shift;
        $self->{_classB} = ClassB->new($self);
        return $self->{_classB};
    }
     
    sub printSomething {
        print "Something\n";
    }
     
    #--------------------------------------------------------------------
    # ClassB (A class that got a "parent" which is a ClassA instance)
    #--------------------------------------------------------------------
     
    package ClassB;
    use strict;
    use warnings;
    use Scalar::Util qw(weaken isweak);
     
    sub new {
        my ($class, $classA) = @_;
        my $self = {};
        bless($self => $class);
        $self->setClassA($classA);
        return $self;
    }
     
    sub setClassA {
        my ($self, $classA) = @_;
        $self->{_classA} = $classA;
    }
     
    sub getClassA {
        return shift->{_classA};
    }
     
    1;
     
    #------------------------------------------------------------------------------+
    #
    # The output will be
    #
    #------------------------------------------------------------------------------+
     
    MONITOR HASH : $b
    Something
    Leaving scope
    Scope left
    DESTROY HASH : $b
     
    #------------------------------------------------------------------------------+
    #
    # We see that the object reference by $b isn't destroyed when leaving the scope
    # because $a->{_classB} still use it. So, we got a circular reference here. We must
    # weaken one side of the circular reference to help Perl disallocate memory.
    #
    #------------------------------------------------------------------------------+
    #------------------------------------------------------------------------------+
    # Wrong way to break circular references
    #------------------------------------------------------------------------------+
    sub getClassB {
        my $self = shift;
        $self->{_classB} = ClassB->new($self);  #$self->{_classB} is the only
                                                #reference to the objects
        weaken($self->{_classB});               #we weaken the only reference,
                                                #so, $self->{_classB} is DESTROYED HERE,
                                                #which is very bad
        print "\$self->{_classB} is now weaken\n" if isweak($self->{_classB});
        return $self->{_classB};
    }
    #------------------------------------------------------------------------------+
    # Good way
    #------------------------------------------------------------------------------+
    sub getClassB {
        my $self = shift;
        my $b = ClassB->new($self);
        $self->{_classB} = $b;                  #we create a second reference to the object
        weaken($self->{_classB});               #we weaken this reference, which is not deleted
                                                #because thre is another reference
        print "\$self->{_classB} is now weaken\n" if isweak($self->{_classB});
        return $self->{_classB};
    }
    #------------------------------------------------------------------------------+
    # Be careful ! With this code, it won't work
    #------------------------------------------------------------------------------+
    sub getClassB {
        my $self = shift;
        {
            my $b = ClassB->new($self);
            $self->{_classB} = $b;                  #we create a second reference to the object
            weaken($self->{_classB});               #we weaken this reference, which is not deleted
                                                    #because thre is another reference
            print "\$self->{_classB} is now weaken\n" if isweak($self->{_classB});
        } #$b is destroyed here, and the other reference $self->{_classB} is a weak reference,
          #so the ClassB instance is destroyed, $self->{_classB} now equal undef
        return $self->{_classB};
    }
    #------------------------------------------------------------------------------+
    # Good way
    #------------------------------------------------------------------------------+
    sub getClassB {
        my $self = shift;
        my $b;
        {
            $b = ClassB->new($self);
            $self->{_classB} = $b;                  #we create a second reference to the object
            weaken($self->{_classB});               #we weaken this reference, which is not deleted
                                                    #because thre is another reference
            print "\$self->{_classB} is now weaken\n" if isweak($self->{_classB});
        } #$b is still not destroyed, so we didn't lose our not weak reference
        return $self->{_classB}; #We return the object, someone on the other side will now keep
                                 #the reference, so we don't care if $b lose the reference.
                                 #Our job is done !
    }
    #------------------------------------------------------------------------------+
    #
    # Conclusion : You must be sure that you keep a non weak reference to the object
    #
    #------------------------------------------------------------------------------+
     
    #------------------------------------------------------------------------------+
    #
    # The output (Using the good way) will be
    #
    #------------------------------------------------------------------------------+
     
    $self->{_classB} is now weaken
    MONITOR HASH : $b
    Something
    Leaving scope
    DESTROY HASH : $b
    Scope left
     
    #------------------------------------------------------------------------------+
    #
    # There is no circular references now...
    #
    #------------------------------------------------------------------------------+
     
    #------------------------------------------------------------------------------+
    #
    # IMPORTANT : Always weaken the caller's reference because someone may use the
    # child objects (ClassB) this way. Let's see what can happen if you don't.
    #
    # If we get the following code
    #
    #------------------------------------------------------------------------------+
    my $b;
    {
        my $a = ClassA->new();
        monitor('$a' => \$a);
        $b = ClassB->new($a);
        $b->getClassA()->printSomething();
        print "Leaving scope\n";
    }
    print "Scope left\n";
    $b->getClassA()->printSomething();
     
    #------------------------------------------------------------------------------+
    #
    # And the sub setClassA
    #
    #------------------------------------------------------------------------------+
    sub setClassA {
        my ($self, $classA) = @_;
        $self->{_classA} = $classA;
        weaken($self->{_classA});
        print "\$self->{_classA} is now weaken\n" if isweak($self->{_classA});
    }
     
    #------------------------------------------------------------------------------+
    #
    # You'll get this error
    #
    #------------------------------------------------------------------------------+
    MONITOR HASH : $a
    $self->{_classA} is now weaken
    Something
    Leaving scope
    DESTROY HASH : $a
    Scope left
    Can't call method "printSomething" on an undefined value at test3.pl line 29.
     
    #------------------------------------------------------------------------------+
    #
    # $a is destroyed when leaving the scope, and the other reference to this variable
    # is weaken, so this one is destroyed too. This clearly demonstrate that you must
    # weaken the caller's reference.
    #
    #------------------------------------------------------------------------------+
    
=head1 THINGS YOU SHOULD BE AWARE OF
 
=head2 Loop variables are passed by references

    Let's see in details what output you get when monitoring variables inside a loop. 

    +----------------------+
    | Code                 |
    +----------------------+
    {
        my @list = (1,2,3);
        print STDERR join(", ",@list)."\n";
        for my $item (@list) {
            monitor("item $item" => \$item);
            $item+=1000;
            print "$item\n";
        }
        print STDERR join(", ",@list)."\n";
        print "Leaving scope\n";
    }
    print "Scope left\n";
     
    +------------------------+
    | What you might want    |
    |(Or something like that)|
    +------------------------+
    1, 2, 3
    MONITOR SCALAR : item 1
    1001
    DESTROY SCALAR : item 1
    MONITOR SCALAR : item 2
    1002
    DESTROY SCALAR : item 2
    MONITOR SCALAR : item 3
    1003
    DESTROY SCALAR : item 3
    1, 2, 3
    Leaving scope
    Scope left
 
    +----------------------+
    | Real Output          |
    +----------------------+
    1, 2, 3
    MONITOR SCALAR : item 1
    1001
    MONITOR SCALAR : item 2
    1002
    MONITOR SCALAR : item 3
    1003
    1001, 1002, 1003
    Leaving scope
    DESTROY SCALAR : item 3
    DESTROY SCALAR : item 2
    DESTROY SCALAR : item 1
    Scope left
     
    +----------------------+
    | Meaning              |
    +----------------------+
    Perl passes variables by reference within for/foreach, so the variables you are using
    are the original ones. (You can print the scalar adresses to be sure)
    The difference is that normaly, Perl passes variables by value.
    So, if you monitor those variables, they won't be destroyed until the initial declaration is. 
    
=head2 Variable using constants are destroyed when the constant is destroyed

    Let's look at this small example :
    
    +----------------------+
    | Code                 |
    +----------------------+
    #!/usr/bin/perl
    use strict;
    use warnings;
    use Devel::Monitor qw(:all);
    
    use constant CONST => [1,2,3]; 
    #monitor('CONST', \&CONST);
    print &CONST."\n";
    {
        my $item = CONST();
        monitor('item', \$item);
        print $item."\n";
        print "Leaving scope\n";
    }
    print "Scope left\n";
    
    +------------------------+
    | What you might want    |
    |(Or something like that)|
    +------------------------+
    ARRAY(0x81c503c)
    MONITOR ARRAY : item
    ARRAY(0x1234567)
    Leaving scope
    DESTROY ARRAY : item
    Scope left
    
    +----------------------+
    | Real Output          |
    +----------------------+
    ARRAY(0x81c503c)
    MONITOR ARRAY : item
    ARRAY(0x81c503c)
    Leaving scope
    Scope left
    DESTROY ARRAY : item
    
    +----------------------+
    | Meaning              |
    +----------------------+
    It looks like your variable is not destroyed ! But in fact, $item is the same
    reference that CONST is. So, you are monitoring CONST directly ! If you
    absolutely want to monitor this code, you must uncomment the 
    "#monitor('CONST', \&CONST);" line in code.
    
    +----------------------+
    | Output with monitor  |
    | on \&CONST           |
    +----------------------+
    MONITOR CODE SCALAR : CONST [0]
    MONITOR CODE SCALAR : CONST [1]
    MONITOR CODE SCALAR : CONST [2]
    MONITOR CODE ARRAY : CONST
    ARRAY(0x81c4e30)
    Array from item is already tied by CONST
    ARRAY(0x81c4e30)
    Leaving scope
    Scope left
    DESTROY CODE SCALAR : CONST [0]
    DESTROY CODE SCALAR : CONST [1]
    DESTROY CODE SCALAR : CONST [2]
    DESTROY CODE ARRAY : CONST
    
    +----------------------+
    | Meaning              |
    +----------------------+
    You monitored a constant and you cannot monitor twice a variable, so $item won't
    be monitored. This way, you can see that there is no memory leak.
    
=head2 Perl problems

=head3 You cannot use references from a tied object because it reuse memory space

    Let's see in details what happen when you try to print circular references
    with a tied object (An object with a monitor by example !!!)

    +----------------------+
    | Code                 |
    +----------------------+
    my $self = {'a' => 1,
                'b' => 2};
    monitor('self' => \$self);
    print STDERR \($self->{'a'})."\n";
    print STDERR \($self->{'b'})."\n";
    print STDERR \($self->{'a'}).\($self->{'b'})."\n";
    foreach my $key (keys %$self) {
        my $keyRef = \$key;
        my $value = $self->{$key};
        my $valueRef = \($self->{$key});
        print STDERR "KEY:$key, KEY REF:$keyRef, VALUE:$value, VALUE REF:$valueRef\n";
    }   
    
    +----------------------+
    | Output               |
    +----------------------+
    MONITOR HASH : self
    SCALAR(0x8141384)
    SCALAR(0x8141384)
    SCALAR(0x8141384)SCALAR(0x81413cc)
    KEY:a, KEY REF:SCALAR(0x8141420), VALUE:1, VALUE REF:SCALAR(0x824becc)
    KEY:b, KEY REF:SCALAR(0x81413cc), VALUE:2, VALUE REF:SCALAR(0x824becc)
    DESTROY HASH : self
    
    +----------------------+
    | Code 2               |
    +----------------------+
    my %self;
    #monitor('self' => \$self);
    tie %self, 'Devel::Monitor::TestHash';
    $self{a} = 1;
    $self{b} = 2;
    print STDERR \($self{a})."\n";
    print STDERR \($self{b})."\n";
    print STDERR \($self{a}).\($self{b})."\n";
    foreach my $key (keys %self) {
        my $keyRef = \$key;
        my $value = $self{$key};
        my $valueRef = \($self{$key});
        print STDERR "KEY:$key, KEY REF:$keyRef, VALUE:$value, VALUE REF:$valueRef\n";
    }  

    +----------------------+
    | Output 2             |
    +----------------------+
    SCALAR(0x8141378)
    SCALAR(0x8141378)
    SCALAR(0x8141378)SCALAR(0x8248fe8)
    KEY:a, KEY REF:SCALAR(0x81413cc), VALUE:1, VALUE REF:SCALAR(0x825567c)
    KEY:b, KEY REF:SCALAR(0x825564c), VALUE:2, VALUE REF:SCALAR(0x825567c)
    Devel::Monitor::TestHash::DESTROY : Devel::Monitor::TestHash=HASH(0x81412e8)
    
    +----------------------+
    | Meaning              |
    +----------------------+
    Hash keys refering 1 and 2 can't be the same reference. But we see the
    opposite on these small examples. It seems like tied objects reuse memory space
    instead of refering to the original value from the untied object.
    
=head3 You cannot weaken a tied object

This is actually an unhandled reference by Perl (Verified with 5.9.2-). It means
that if you monitor (or tie explicitly) an object, any weaken references into
this one will simply be ignored.

=head4 Proof 01 : Basic test

    +----------------------+
    | Code                 |
    +----------------------+
    #!/usr/bin/perl
    
    use Scalar::Util qw(weaken isweak);
    my (@a, @b);
    tie @a, 'Monitor::TestArray';
    tie @b, 'Monitor::TestArray';
    $a[0] = \@b;
    $b[0] = \@a;
    weaken($b[0]);
    if (isweak($a[0])) {
       print "\$a[0] is weak\n";
    } else {
       print "\$a[0] is not weak\n";
    }  
    if (isweak($b[0])) {
       print "\$b[0] is weak\n";
    } else {
       print "\$b[0] is not weak\n";
    }    
    package Monitor::TestArray;
    use Tie::Array;
    use base 'Tie::StdArray';
    
    sub DESTROY { "Monitor::TestArray::DESTROY : $_[0]\n"; }
    
    1; 
    
    +----------------------+
    | Wanted output        |
    +----------------------+
    $a[0] is not weak
    $b[0] is weak
    
    +----------------------+
    | Real output          |
    +----------------------+
    $a[0] is not weak
    $b[0] is not weak
    
    +----------------------+
    | Meaning              |
    +----------------------+
    We still have this output if we remove one of the "tie" call. But, if we remove those
    two "tie", it works and we get the wanted output. So there is a problem.

=head4 Proof 02 : mod_perl

    +----------------------+
    | Code                 |
    +----------------------+
    +------------+
    | test.pl    |
    +------------+
    #!/usr/bin/perl
    use strict;
    use warnings;
    use Scalar::Util qw(weaken);
    use Devel::Monitor qw(:all);
    use Util::Junk;
    
    my (@a, $b);
    #tie @a, 'Devel::Monitor::TestArray';
    $a[0] = \$b;
    $b = \@a;
    $a[1] = Util::Junk::_20M();
    weaken($a[0]);
    
    +------------+
    | Util::Junk |
    +------------+
    package Util::Junk;
    use strict;
    use warnings;
    
    sub _20M() { 'A 20 megs string here filled with zeros' }
    
    1;
    
    +----------------------+
    | wget-test.pl         |
    +----------------------+
    #!/usr/bin/perl
    
    use strict;
    use warnings;
    
    my $baseUrl = 'http://localhost/perl/test.pl';
    
    my $i = 0;
    while (1) {
        print "Loop ".++$i."\n";
        
        system('wget "'.$baseUrl.'" -O /dev/null') == 0
            or die "\nwget failed or has been interrupted : $?\n";
    }
    
    +----------------------+
    | Test 01              |
    +----------------------+
    Now that we got a program and a caller (and mod_perl on our apache server), we can start the program.
    
    perl wget-test.pl
    
    When @a is not tied (See the commented tie in test.pl), after loading the page like ten times, the
    page will be in cache in every apache processes and other loading will be VERY fast. You'll also
    notice that memory is stable.
    
    However, if you uncomment the tie call in test.pl, you'll see your memory being filled to death and
    every page loaded will be as long as at the beginning 
    
=head4 Proof 03 : Final assault
    
    Firstly, we must be sure that the methods Scalar::Util::weaken and Scalar::Util::isweak
    doesn't contain bugs. The code for these method follows : 
    
    void
    weaken(sv)
       SV *sv
    PROTOTYPE: $
    CODE:
    #ifdef SvWEAKREF
       sv_rvweaken(sv);
    #else
       croak("weak references are not implemented in this release of perl");
    #endif
    
    void
    isweak(sv)
       SV *sv
    PROTOTYPE: $
    CODE:
    #ifdef SvWEAKREF
       ST(0) = boolSV(SvROK(sv) && SvWEAKREF(sv));
       XSRETURN(1);
    #else
       croak("weak references are not implemented in this release of perl");
    #endif
    
    We easily see that there is absolutely no problems here.

    Now let's see what happen if we dump a tied variable by using Devel::Peek.
    It should activate the WEAKREF flag if the reference is weak.
    
    Let's see what result we should get :
    
    +----------------------+
    | Code                 |
    +----------------------+
    #!/usr/bin/perl
    use strict;
    use warnings;
    use Devel::Monitor qw(:all);
     
    use Scalar::Util qw(weaken);
    use Devel::Peek;
    {
        my (@a);
        $a[0] = \@a;
        #tie @a, 'TestArray';
        Dump($a[0],1);
        weaken($a[0]);
        Dump($a[0],1);
        print "Leaving scope\n";
    }
    print "Scope left\n";
     
    package TestArray;
    use Tie::Array;
    use base 'Tie::StdArray';
     
    sub DESTROY { print "Monitor::TestArray::DESTROY : $_[0]\n"; }
     
    1;
    
    +-------------------------------+
    | Output without the "tie" call |
    +-------------------------------+
    SV = RV(0x81829c0) at 0x814127c
      REFCNT = 1
      FLAGS = (ROK)
      RV = 0x814e740
      SV = PVAV(0x81426cc) at 0x814e740
        REFCNT = 2
        FLAGS = (PADBUSY,PADMY)
        IV = 0
        NV = 0
        ARRAY = 0x8148888
        FILL = 0
        MAX = 3
        ARYLEN = 0x0
        FLAGS = (REAL)
    SV = RV(0x81829c0) at 0x814127c
      REFCNT = 1
      FLAGS = (ROK,WEAKREF,IsUV)
      RV = 0x814e740
      SV = PVAV(0x81426cc) at 0x814e740
        REFCNT = 1
        FLAGS = (PADBUSY,PADMY,RMG)
        IV = 0
        NV = 0
        MAGIC = 0x8266f08
          MG_VIRTUAL = &PL_vtbl_backref
          MG_TYPE = PERL_MAGIC_backref(<)
          MG_FLAGS = 0x02
            REFCOUNTED
          MG_OBJ = 0x81411c8
          SV = PVAV(0x8263704) at 0x81411c8
            REFCNT = 2
            FLAGS = ()
            IV = 0
            NV = 0
            ARRAY = 0x82677e8
            FILL = 0
            MAX = 3
            ARYLEN = 0x0
            FLAGS = (REAL)
        ARRAY = 0x8148888
        FILL = 0
        MAX = 3
        ARYLEN = 0x0
        FLAGS = (REAL)
    Leaving scope
    Scope left
    
    +----------------------+
    | Explanations         |
    +----------------------+
    We actually see the WEAKREF flag that confirms us that the reference is weak.
    However, let's see what happen when we uncomment the 11th line (the tie call on @a)
    
    +----------------------------+
    | Output with the "tie" call |
    +----------------------------+
    SV = PVLV(0x817c568) at 0x81413f0
      REFCNT = 1
      FLAGS = (TEMP,GMG,SMG,RMG)
      IV = 0
      NV = 0
      PV = 0
      MAGIC = 0x81505b8
        MG_VIRTUAL = &PL_vtbl_packelem
        MG_TYPE = PERL_MAGIC_tiedelem(p)
        MG_FLAGS = 0x02
          REFCOUNTED
        MG_OBJ = 0x814139c
        SV = RV(0x81829ac) at 0x814139c
          REFCNT = 2
          FLAGS = (ROK)
          RV = 0x8141354
      TYPE = t
      TARGOFF = 0
      TARGLEN = 0
      TARG = 0x81413f0
    SV = PVLV(0x817c568) at 0x81413f0
      REFCNT = 1
      FLAGS = (TEMP,GMG,SMG,RMG)
      IV = 0
      NV = 0
      PV = 0
      MAGIC = 0x81505b8
        MG_VIRTUAL = &PL_vtbl_packelem
        MG_TYPE = PERL_MAGIC_tiedelem(p)
        MG_FLAGS = 0x02
          REFCOUNTED
        MG_OBJ = 0x814139c
        SV = RV(0x81829ac) at 0x814139c
          REFCNT = 2
          FLAGS = (ROK)
          RV = 0x8141354
      TYPE = t
      TARGOFF = 0
      TARGLEN = 0
      TARG = 0x81413f0
    Leaving scope
    Scope left
    Monitor::TestArray::DESTROY : TestArray=ARRAY(0x8141354)
    
    +----------------------+
    | Explanations         |
    +----------------------+
    Absolutely nothing has changed before and after. IT IS A PROBLEM ! So, I debugged
    the perl source code to verify what happen with a tied variable. The method goes
    like this :
    
    /*
    =for apidoc sv_rvweaken
     
    Weaken a reference: set the C<SvWEAKREF> flag on this RV; give the
    referred-to SV C<PERL_MAGIC_backref> magic if it hasn't already; and
    push a back-reference to this RV onto the array of backreferences
    associated with that magic.
     
    =cut
    */
     
    SV *
    Perl_sv_rvweaken(pTHX_ SV *sv)
    {
        SV *tsv;
        if (!SvOK(sv))  /* let undefs pass */
            return sv;
        if (!SvROK(sv))
            Perl_croak(aTHX_ "Can't weaken a nonreference");
        else if (SvWEAKREF(sv)) {
            if (ckWARN(WARN_MISC))
                Perl_warner(aTHX_ packWARN(WARN_MISC), "Reference is already weak");
            return sv;
        }
        tsv = SvRV(sv);
        sv_add_backref(tsv, sv);
        SvWEAKREF_on(sv);
        SvREFCNT_dec(tsv);
        return sv;
    }
    
    The problem is at the line "if (!SvOK(sv))". A tied variable enter this condition
    and returns itself without any modifications... The reason is that our variables
    has those flags FLAGS = (TEMP,GMG,SMG,RMG). The code should be something like
    this :

    if (!SvOK(sv))
        if (SvMAGIC(sv)) {
            //***************************************
            //Do something here !!!
            //***************************************
        } else {
            return sv;
        }

    This bug has been submitted and is unanswered for now. (See http://rt.perl.org/rt3/Ticket/Display.html?id=34524)

=head4 Conclusion

    It is actually impossible to weaken a tied variable

=head1 TRICKS

=head2 Checking modules syntax

    Since monitored are executed when you check syntax of a module, it will print out 
    to stderr some messages with constants and some global variables. So to remove 
    those prints, simple grep it by redirecting stderr to stdout and grep it

    perl -c MyModule.pm 2>&1 | grep -iv '^(DESTROY|MONITOR|Scalar constant)'

=head1 MODULES THAT PRODUCE MEMORY LEAKS

    You must destroy them when you don't need anymore those object instances
    
    +----------------------+
    | Bio::Graphics::Panel |
    +----------------------+
    my $panel = Bio::Graphics::Panel->new(%options);
    ...
    $panel->finished(); #Don't forget to call this destructor
      
    +----------------------+
    | XML::DOM             |
    +----------------------+
    my $parser  = new XML::DOM::Parser;
    my $doc = $parser->parsefile ("file.xml");
    ...
    $doc->dispose(); #Don't forget to call this destructor
    
    NOTE : I suggest that you use XML::LibXML instead
     
=head1 NOTE

This module has been tested with scalars, hashes, arrays, blessed hashes, blessed arrays, tied hashes, tied arrays, tied scalars.

=head1 BUGS

None known

=head1 AUTHOR
 
Philippe Cote E<lt> philippe.cote@usherbrooke.ca E<gt>
Génome Québec E<lt> http://www.genomequebec.com E<gt>

=head1 CREDITS
 
I got the main idea from a module that is not on CPAN. 
See http://www.infocopter.com/perl/monitored-variables.htm (Monitor.pm)

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
