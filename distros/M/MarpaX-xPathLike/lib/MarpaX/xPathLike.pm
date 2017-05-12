package MarpaX::xPathLike;
use utf8;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.
use 5.006;
use strict;
use Carp;
#use warnings FATAL => 'all';
use warnings;
use Marpa::R2;
use Data::Dumper;
use Scalar::Util qw{looks_like_number weaken};

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();

our $VERSION = '0.203';
use MarpaX::xPathLike::DSL;
use MarpaX::xPathLike::Actions;
use Test::Deep qw {cmp_details deep_diag};



my $grammar = Marpa::R2::Scanless::G->new({
    #default_action => '::first',
    action_object    => 'MarpaX::xPathLike::Actions',
    source => \($MarpaX::xPathLike::DSL::xpath),

});

#############################end of rules################################

my @context = ();
sub _names{
            return map {$_->{name}} _getSubObjectsOrCurrent(@_);
}
sub _values{
    #print 'Values arg = ', Dumper \@_;
    return map {${$_->{data}}} _getSubObjectsOrCurrent(@_);
}
sub _positions{
    my @r = _getSubObjectsOrCurrent(@_);
    return map {$_->{pos}} @r;            
}
sub _lasts{
    my @r = _getSubObjectsOrCurrent(@_);
    return map {$_->{size}} @r;    
}

no warnings qw{uninitialized numeric};

my $operatorBy = {
    '=' => sub($$){
        return _logicalOper(sub {$_[0] == $_[1]}, $_[0], $_[1]);
    },
    '==' => sub($$){
        return _logicalOper(sub {$_[0] == $_[1]}, $_[0], $_[1]);
    },
    '!=' => sub($$){
        return _logicalOper(sub {$_[0] != $_[1]}, $_[0], $_[1]);
    },
    'eq' => sub($$){
        return _logicalOper(sub {$_[0] eq $_[1]}, $_[0], $_[1]);
    },
    'ne' => sub($$){
        return _logicalOper(sub {$_[0] ne $_[1]}, $_[0], $_[1]);
    },
    '===' => sub($$){
        return _logicalOper(sub {
            looks_like_number($_[0])
            and looks_like_number($_[1])
            and $_[0] == $_[1]
        }, $_[0], $_[1]);
    },
    '!==' => sub($$){
        return _logicalOper(sub {
            $_[0] != $_[1]
        }, $_[0], $_[1]);
    },
    '>' => sub($$){
        return _logicalOper(sub {$_[0] > $_[1]}, $_[0], $_[1]);
    },
    '>=' => sub($$){
        return _logicalOper(sub {$_[0] >= $_[1]}, $_[0], $_[1]);
    },
    '<' => sub($$){
        return _logicalOper(sub {$_[0] < $_[1]}, $_[0], $_[1]);
    },
    '<=' => sub($$){
        return _logicalOper(sub {$_[0] <= $_[1]}, $_[0], $_[1]);
    },
    '>=' => sub($$){
        return _logicalOper(sub {$_[0] >= $_[1]}, $_[0], $_[1]);
    },
    'lt' => sub($$){
        return _logicalOper(sub {$_[0] lt $_[1]}, $_[0], $_[1]);
    },
    'le' => sub($$){
        return _logicalOper(sub {$_[0] le $_[1]}, $_[0], $_[1]);
    },
    'gt' => sub($$){
        return _logicalOper(sub {$_[0] gt $_[1]}, $_[0], $_[1]);
    },
    'ge' => sub($$){
        return _logicalOper(sub {$_[0] ge $_[1]}, $_[0], $_[1]);
    },
    'and' => sub($$){
        return _logicalOper(sub {$_[0] and $_[1]}, $_[0], $_[1]);
    },
    'or' => sub($$){
        return _logicalOper(sub {$_[0] or $_[1]}, $_[0], $_[1]);
    },
    '~' => sub($$){
        return _logicalOper(sub {$_[0] =~ $_[1]}, $_[0], $_[1]);
    },
    '!~' => sub($$){
        return _logicalOper(sub {$_[0] !~ $_[1]}, $_[0], $_[1]);
    },
    '*' => sub($$;@){
        return _naryOper(sub {$_[0] * $_[1]}, $_[0], $_[1], @_[2..$#_]);
    },
    'div' => sub($$;@){
        return _naryOper(sub {
            my $r = eval {$_[0] / $_[1]};
            carp qq|Division problems\n$@| if $@;
            return $r;
        }, $_[0], $_[1], @_[2..$#_]);
    },
    '/' => sub($$;@){
        return _naryOper(sub {
            my $r = eval {$_[0] / $_[1]};
            carp qq|Division problems\n$@| if $@;
            return $r;
        }, $_[1], @_[2..$#_]);
    },
    '+' => sub($$;@){
        return _naryOper(sub {$_[0] + $_[1]}, $_[0], $_[1], @_[2..$#_]);
    },
    '-' => sub($$;@){
        return _naryOper(sub {$_[0] - $_[1]}, $_[0], $_[1], @_[2..$#_]);
    },
    'mod' => sub($$;@){
        return _naryOper(sub {$_[0] % $_[1]}, $_[0], $_[1], @_[2..$#_]);
    },
    '%' => sub($$;@){
        return _naryOper(sub {$_[0] % $_[1]}, $_[0], $_[1], @_[2..$#_]);
    },
    '||' => sub{
        return _naryOper(sub {$_[0] . $_[1]}, $_[0], $_[1], @_[2..$#_])
    },
    names => \&_names,
    values => \&_values,
    positions => \&_positions,
    lasts => \&_lasts,
    name => sub {
        return (_names(@_))[0] // q||;
    },
    value => sub(){
        return (_values(@_))[0] // q||;
    },
    position => sub{
        my @r = _positions(@_);
        return $r[$#r] // 0;        
    },
    last => sub{
        my @r = _lasts(@_);
        return $r[$#r] // 0;
    },
    isHash => sub{
        my @r = grep {ref ${$_->{data}} eq q|HASH|} _getSubObjectsOrCurrent(@_);
        return @r > 0;
    },
    isArray => sub{
        my @r = grep {ref ${$_->{data}} eq q|ARRAY|} _getSubObjectsOrCurrent(@_);
        return @r > 0;    
    },
    isCode => sub{
        my @r = grep {ref ${$_->{data}} eq q|CODE|} _getSubObjectsOrCurrent(@_);
        return @r > 0;                
    },
    isRef => sub{
        my @r = grep {ref ${$_->{data}}} _getSubObjectsOrCurrent(@_);
        return @r > 0;    
    },
    isScalar => sub{
        my @r = grep {!ref ${$_->{data}}} _getSubObjectsOrCurrent(@_);
        return @r > 0;        
    },
    count =>sub{
        my @r = _getSubObjectsOrCurrent(@_);
        return scalar @r;
    },
    exists => sub{
        my @r = _getSubObjectsOrCurrent(@_);
        return scalar @r > 0;        
    },
    not => sub{
        return !_operation($_[0]);
    },
    sum => sub{
        my @r = _getSubObjectsOrCurrent($_[0]);
        my @s = grep{ref $_->{data} eq q|SCALAR| and looks_like_number(${$_->{data}})} @r; #ignore entry if it is not a scalar
        my $s = 0;
        $s += ${$_->{data}} foreach (@s);
        return $s;    
    },
    sumproduct => sub{
        my @r = _getSubObjectsOrCurrent($_[0]);
        my @s = _getSubObjectsOrCurrent($_[1]);
        my $size = $#r < $#s ? $#r: $#s;
        my $s = 0;
        foreach (0..$size){
            $s += ${$r[$_]->{data}} * ${$s[$_]->{data}} 
                if ref $r[$_]->{data} eq q|SCALAR| 
                and ref $s[$_]->{data} eq q|SCALAR|
                and looks_like_number(${$r[$_]->{data}})
                and looks_like_number(${$s[$_]->{data}}) 
        }
        return $s;    
    },
};
sub _operation($){
    my $operData = $_[0];
    return undef unless defined $operData and ref $operData eq q|HASH|;
    my %types = (
        oper => sub{
            my ($oper, @args) = @{$operData->{oper}};
            #print "oper=$oper";
            #my $oper = $params[0];
            return undef unless defined $oper and exists $operatorBy->{$oper};
            #my @args = @params[1..$#params];
            return $operatorBy->{$oper}->(@args);              
        },
        values =>sub{
            my @r = $operatorBy->{values}->($operData->{values});
            return @r;
        }
    );
    #print 'operdata = ', Dumper $operData;
    my @r = map {$types{$_}->()} grep {exists $types{$_}} keys %$operData;
    return @r if wantarray();
    return $r[0];
}
sub _naryOper(&$$;@){
        my ($oper,$x,$y,@e) = @_;
        $x = _operation($x) if ref $x;
        $y = _operation($y) if ref $y;
        my $res = $oper->($x,$y);
        foreach my $e (@e){
            $e = _operation($e) if ref $e;
            $res = $oper->($res,$e);
        }
        return $res
}
sub _logicalOper(&$$){
        my ($oper,$x,$y) = @_;
        #print "x=", Dumper $x;
        #print "y=", Dumper $y;
        my @x = ($x);
        my @y = ($y);
        @x = _operation($x) if ref $x and ref $x ne q|Regexp|;
        @y = _operation($y) if ref $y and ref $y ne q|Regexp|;
        #my @r = eval {};
        #warn qq|Warning: $@| if $@;
        foreach my $x (@x){
            foreach my $y (@y){
                return 1 if $oper->($x,$y)
            }    
        }
        return 0;
        #return $oper->($x,$y);
}


sub _evaluate{
    my $x = $_[0];
    return $x unless ref $x eq q|HASH| and exists $x->{oper};
    return _operation($x);
}
sub _getStruct{
    my ($context, $subpath) = @_;
    return ($context) unless defined $subpath;
    push @context, $context;
    my @r = _getObjectSubset(${$context->{data}}, $subpath);
    pop @context;
    return @r; 
}
my %filterType = (
    boolean => sub {
        return  _operation($_[0]);
    }
    , indexes => sub{
        sub __computeIndex{
            my $index = 0 + _evaluate($_[0]);
            $index += 1 + $context[$#context]->{size} if $index < 0;
            return $index;
        };
        my %indexType = (
            index => sub{
                return $context[$#context]->{pos} == __computeIndex($_[0]);
            }
            , range => sub{
                #print 'range', Dumper $_[0];
                my $pos = $context[$#context]->{pos};
                my ($start, $end) = map {__computeIndex($_)} @{$_[0]};
                return $pos >= $start && $pos <= $end;
            }
            , from => sub{
                #print 'from', Dumper $_[0];
                return $context[$#context]->{pos} >= __computeIndex($_[0]);                
            }
            , to => sub{
                #print 'to', Dumper $_[0];
                return $context[$#context]->{pos} <= __computeIndex($_[0]);                
            }
        );
        #print 'indexes filter ',Dumper @_;
        my $indexes = $_[0];
        foreach my $index (@$indexes){
            #print 'evaluate', Dumper $index;
            return 1 if (map {$indexType{$_}->($index->{$_})} grep {exists $indexType{$_}} keys %$index)[0]; 
        }
        return 0;
    }    
);
sub _filter{
    my ($context,$filter) = @_;
    #print 'validate -> ', Dumper \@_;
    return 1 unless defined $filter and ref $filter eq q|HASH|;  #just in case
    push @context, $context;
    my ($r) = map {$filterType{$_}->($filter->{$_})} grep {exists $filterType{$_}} keys %$filter;
    pop @context;
    return $r;    
}
sub _getFilteredKeys{
    my ($data,$filter,@keys) = @_;
    $filter //= [];
    my $order = $context[$#context]->{order} // q||;
    my $size = scalar @keys;

    my @keyIndex = map{{
        name => $keys[$_], 
        type => q|HASH|, 
        data  => \$data->{$keys[$_]}, 
        order => qq|$order/$keys[$_]|, 
        size => scalar @keys
    }} 0..$#keys;
    foreach my $filter (@$filter){
        my $pos = 1;
        $size = scalar @keyIndex;
        @keyIndex = grep {_filter(
                    $_
                    ,$filter
        )} map {@{$_}{qw|pos size|} = ($pos++, $size); $_} @keyIndex ;
    }

    my $pos = 1;
    $size = scalar @keyIndex;
    return map {@{$_}{qw|pos size|} = ($pos++, $size); $_} @keyIndex    
}
sub _getFilteredIndexes{
    my ($data,$filter,@indexes) = @_;
    $filter //= [];
    my $order = $context[$#context]->{order} // q||;
    my $size = scalar @indexes;
    my $large = 1;
    {    use integer;    my $n = $size; $large++ while($n /= 10); } #a scope to do integer operations;

    my @r = map {{                                                            #init result array     
        name => $_, 
        type => q|ARRAY|, 
        data  => \$data->[$_], 
        order => qq|$order/|.sprintf("%0*u",$large,$_), 
        size => $size
    }} @indexes;
    
    foreach my $filter (@$filter){
        my $pos = 1;
        $size = scalar @r;
        @r = grep {_filter(                                                #filter out from result
                    $_                
                    ,$filter
        )} map {@{$_}{qw|pos size|} = ($pos++, $size); $_} @r ;
    }

    my $pos = 1;
    $size = scalar @r;
    return map{    @{$_}{qw|pos size|} = ($pos++, $size); $_} @r;             #compute final positions in context
}
sub _anyChildType{
    my ($type,$name,$data,$subpath,$filter) = @_;
    my %filterByDataType = (
            HASH => sub{
                return () if defined $type and $type ne q|HASH|;
                my @keys = keys %$data;
                @keys = grep {$_ eq $name} @keys if defined $name;
                return _getFilteredKeys($data,$filter, sort @keys);
            }
            , ARRAY => sub{
                return () if defined $type and $type ne q|ARRAY|;
                my @indexes = 0..$#$data;
                @indexes = grep {$_ == $name} @indexes if defined $name;
                return _getFilteredIndexes($data,$filter, @indexes);
            }
    );
    return 
        map {_getStruct($_, $subpath)} 
        map { $filterByDataType{$_}->()} 
        grep {exists $filterByDataType{$_}} 
        (ref $data);
}
sub _descendant{
    my ($data,$path) = @_;
    #print 'context', Dumper \@context;
    my @r = _getObjectSubset($data,$path);    
    my $order = $context[$#context]->{order} // q||;
    #print "order = $order";
    if (ref $data eq q|HASH|){
            my @keys = sort keys %$data;
            foreach (@keys){
                push @context, {name => $_, type => q|HASH|, data  => \$data->{$_}, order => qq|$order/$_|, pos =>1, size => scalar @keys };
                push @r, _descendant($data->{$_}, $path);
                pop @context;
            }
    }
    if (ref $data eq q|ARRAY|){
            foreach (0 .. $#$data){
                push @context, {name => $_, type => q|ARRAY|, data  => \$data->[$_], order =>  qq|$order/$_|, pos=> 1, size => scalar @$data};
                push @r, _descendant($data->[$_], $path);
                pop @context;
            }
    } 
    return @r;
}
sub _getDescendants{
    my($descendants,$subpath) = @_;
    my @r=();
    foreach (0..$#$descendants){
            if (defined $descendants->[$_]){                        #only if descendants was selected
                    my $last = $#context;
                    #print "descendant of $_", Dumper $descendants->[$_];
                    #print "subpath", Dumper $subpath;
                    push @context, @{$descendants->[$_]};
                    push @r, defined $subpath ?
                        _getObjectSubset(${$context[$#context]->{data}}, $subpath)
                        : ($context[$#context]);
                    $#context = $last;                        
            }
    }
    return @r;
}

sub _getDescContexts{
        my (@context) = @_;
        my @r = ();
        my $order = $context[$#context]->{order} // q||;
        my $data = ${$context[$#context]->{data}};
        my $pos = 1;
        if (ref $data eq q|HASH|){
                my @keys = sort keys %$data;
                foreach (@keys){
                    push @r, _getDescContexts(@context, {name => $_, type => q|HASH|, data  => \$data->{$_}, order => qq|$order/$_|, pos =>$pos++, size => scalar @keys });
                }
        }
        if (ref $data eq q|ARRAY|){
                foreach (0 .. $#$data){
                    push @r, _getDescContexts(@context, {name => $_, type => q|ARRAY|, data  => \$data->[$_], order =>  qq|$order/$_|, pos => $pos++, size => scalar @$data});
                }
        }
        return (\@context, @r);
}

sub _filterOutDescendants{
    my ($filters,$size,$descendants) = @_;
    $filters //= [];

    
    #print 'descendants', scalar @$descendants, Dumper \@$descendants;
    foreach my $filter (@$filters){
        my $pos = 1;
        my $cnt = 0;
        foreach my $k (0..$#$descendants){
            if (defined $descendants->[$k]){
                my $last = $#context;
                push @context, @{$descendants->[$k]};
                my ($s,$p) = @{$context[$#context]}{qw|size pos|};
                @{$context[$#context]}{qw|size pos|} = ($size,$pos++);    
                $cnt++, undef $descendants->[$k] if !_filter($context[$#context],$filter);
                @{$context[$#context]}{qw|size pos|} = ($s,$p);    
                $#context = $last;
            }
        }
        $size -= $cnt;
    }
    #print 'Selected descendants', scalar @$descendants, Dumper \@$descendants;
    return $descendants;    
}
sub _getDescendantsByTypeAndName{
        my ($type, $name, $subpath,$filter,$self) = @_;
        my $descendants = [_getDescContexts($context[$#context])];
        shift @$descendants unless $self;
        $descendants = [grep {$_->[$#$_]->{name} eq $name} @$descendants] if defined $name;
        $descendants = [grep {$_->[$#$_]->{type} eq $type} @$descendants] if defined $type;
        shift @{$descendants->[$_]} foreach (0..$#$descendants); #remove the current context from context list.
        my $size = scalar @$descendants;
        return _getDescendants(_filterOutDescendants($filter,$size,$descendants), $subpath);
}

sub _getAncestorsOrSelf{ 
    my ($ancestors,$subpath) = @_; 
    my @tmp = ();
    my @r;
    foreach (0..$#$ancestors){
            if (defined $ancestors->[$_]){                        #only if ancestor was selected
                    push @r, defined $subpath ?
                        _getObjectSubset(${$context[$#context]->{data}}, $subpath)
                        : ($context[$#context])                        
            }
            push @tmp, pop @context;
    }
    push @context, pop @tmp while(scalar @tmp > 0); #repo @context
    return @r;
}
        # foreach (0..$#$ancestors){    #pre filter ancestors with named ones, only!
        #     $size--, undef $ancestors->[$_] if $context[$_]->{name} ne $name;
        # }
sub _filterOutAncestorsOrSelf{
    my($type,$name,$filter,$ancestorsIndex) = @_;
    $filter //= [];

    #as array of flags. Each position flags a correpondent ancestor
    #my @ancestorsIndex = map {1} (0..$#context); 
    

    #filter out ancestors with a different name!
    map {    
        undef $ancestorsIndex->[$_] if $context[$#context - $_]->{name} ne $name;
    } 0..$#$ancestorsIndex if defined $name;

    #filter out ancestors of a different type!
    map {    
        undef $ancestorsIndex->[$_] if $context[$#context - $_]->{type} ne $type;#Não se devia decrementar duplamente
    } 0..$#$ancestorsIndex if defined $type;
    
    my $size = 0;
    map {$size++ if defined $_} @$ancestorsIndex;

    foreach my $filter (@$filter){
        my $pos = 1;
        my @tmp = ();
        my $cnt = 0;
        foreach my $k (0..$#$ancestorsIndex){
            if (defined $ancestorsIndex->[$k]){
                my ($s,$p) = @{$context[$#context]}{qw|size pos|};
                 @{$context[$#context]}{qw|size pos|} = ($size,$pos++);        
                $cnt++, undef $ancestorsIndex->[$k] if !_filter($context[$#context],$filter);
                @{$context[$#context]}{qw|size pos|} = ($s,$p);
            }        
            push @tmp, pop @context;
        }
        push @context, pop @tmp while(scalar @tmp > 0); #repo @context
        $size -= $cnt;                 #adjust the group's size;
    }
    return $ancestorsIndex;
} 
sub _filterOutSiblings{
    my ($type, $name, $subpath,$filter,$direction) = @_;
    my $mySelf = $context[$#context]->{data};
    my $context = pop @context;
    my $data = ${$context[$#context]->{data}};

    my %filterByDataType = (
            HASH => sub{
                my @keys = sort keys %$data;
                my $cnt = $#keys;
                $cnt-- while($cnt >= 0 and \$data->{$keys[$cnt]} != $mySelf);    
                my @siblings = do {
                    if ($direction eq q|preceding|){
                        $#keys = $cnt-1;
                        reverse @keys[0 .. $cnt-1];
                    }elsif($direction eq q|following|){
                        @keys[$cnt+1 .. $#keys]
                    }
                };
                @siblings = grep {$_ eq $name} @siblings if defined $name;
                @siblings = grep {q|HASH| eq $type} @siblings if defined $type;
                return _getFilteredKeys($data,$filter, @siblings);
            }
            , ARRAY => sub{
                my $cnt = $#$data;
                $cnt-- while($cnt >= 0 and \$data->[$cnt] != $mySelf);
                my @siblings = do {
                    if ($direction eq q|preceding|){
                        reverse 0..$cnt-1
                    }elsif($direction eq q|following|){
                        $cnt+1 .. $#$data        
                    }
                };
                @siblings = grep {$_ eq $name} @siblings if defined $name;
                @siblings = grep {q|ARRAY| eq $type} @siblings if defined $type;
                return _getFilteredIndexes($data,$filter, @siblings);
            }
    );
    my @r = 
        map {_getStruct($_, $subpath)} 
        map { $filterByDataType{$_}->()} 
        grep {exists $filterByDataType{$_}} 
        (ref $data);
    push @context, $context;
    return @r;
}

my $dispatcher = {
    self => sub{
        my (undef, undef, $subpath,$filter) = @_;
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, undef, $filter, [0]), $subpath);
    },
    selfArray => sub{
        my (undef, undef, $subpath,$filter) = @_;
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, undef, $filter, [0]), $subpath);
    },
    selfHash => sub {
        my (undef, undef, $subpath,$filter) = @_;
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, undef, $filter, [0]), $subpath);
    },
    selfNamed => sub{
        my (undef, $name, $subpath,$filter) = @_;
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, $name, $filter, [0]), $subpath);
    },
    selfIndexed => sub{
        my (undef, $index, $subpath,$filter) = @_;
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, $index, $filter, [0]), $subpath);
    },
    selfIndexedOrNamed => sub{
        my (undef, $index, $subpath,$filter) = @_;
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, $index, $filter, [0]), $subpath);
    },
    parent => sub{
        my (undef, undef, $subpath,$filter) = @_;

        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, undef, $filter, [0]), $subpath);
        push @context, $current;
        return @r;
    },
    parentArray => sub{
        my (undef, undef, $subpath,$filter) = @_;

        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, undef, $filter, [0]), $subpath);
        push @context, $current;
        return @r;
    },
    parentHash => sub{
        my (undef, undef, $subpath,$filter) = @_;

        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, undef, $filter, [0]), $subpath);
        push @context, $current;
        return @r;
    },
    parentNamed => sub{
        my (undef, $name, $subpath,$filter) = @_;

        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, $name, $filter, [0]), $subpath);
        push @context, $current;
        return @r;
    },
    parentIndexed => sub{
        my (undef, $index, $subpath,$filter) = @_;

        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, $index, $filter, [0]), $subpath);
        push @context, $current;
        return @r;
    },
    parentIndexedOrNamed => sub{
        my (undef, $index, $subpath,$filter) = @_;

        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, $index, $filter, [0]), $subpath);
        push @context, $current;
        return @r;
    },
    ancestor => sub{
        my (undef, undef, $subpath,$filter) = @_;

        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, undef, $filter, [0..$#context]), $subpath);
        push @context, $current;
        return @r;
    },
    ancestorArray => sub{
        my (undef, undef, $subpath,$filter) = @_;

        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, undef, $filter, [0..$#context]), $subpath);
        push @context, $current;
        return @r;
    },
    ancestorHash => sub{
        my (undef, undef, $subpath,$filter) = @_;

        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, undef, $filter, [0..$#context]), $subpath);
        push @context, $current;
        return @r;
    },
    ancestorNamed => sub{
        my (undef, $name, $subpath,$filter) = @_;
    
        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, $name, $filter, [0..$#context]), $subpath);
        push @context, $current;
        return @r;
    },
    ancestorIndexed => sub{
        my (undef, $index, $subpath,$filter) = @_;
    
        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, $index, $filter, [0..$#context]), $subpath);
        push @context, $current;
        return @r;
    },
    ancestorIndexedOrNamed => sub{
        my (undef, $index, $subpath,$filter) = @_;
    
        my $current = pop @context;
        my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, $index, $filter, [0..$#context]), $subpath);
        push @context, $current;
        return @r;
    },
    ancestorOrSelf => sub{
        my (undef, undef, $subpath,$filter) = @_;
    
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, undef, $filter, [0..$#context]), $subpath);
    }, 
    ancestorOrSelfArray => sub{
        my (undef, undef, $subpath,$filter) = @_;
    
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, undef, $filter, [0..$#context]), $subpath);
    }, 
    ancestorOrSelfHash => sub{
        my (undef, undef, $subpath,$filter) = @_;
    
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, undef, $filter, [0..$#context]), $subpath);
    }, 
    ancestorOrSelfNamed => sub{
        my (undef, $name, $subpath,$filter) = @_;
    
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|,$name,$filter, [0..$#context]), $subpath);
    }, 
    ancestorOrSelfIndexed => sub{
        my (undef, $index, $subpath,$filter) = @_;
    
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|,$index,$filter, [0..$#context]), $subpath);
    }, 
    ancestorOrSelfIndexedOrNamed => sub{
        my (undef, $index, $subpath,$filter) = @_;
    
        return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef,$index,$filter,[0..$#context]), $subpath);
    }, 
    child => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _anyChildType(undef,undef,$data,$subpath,$filter);        
    },
    childArray => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _anyChildType(q|ARRAY|,undef,$data,$subpath,$filter);        
    },
    childHash => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _anyChildType(q|HASH|,undef,$data,$subpath,$filter);        
    },
    childNamed => sub{
        my ($data, $name, $subpath,$filter) = @_;
        return _anyChildType(q|HASH|,$name,$data,$subpath,$filter);        
    },
    childIndexed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _anyChildType(q|ARRAY|,$index,$data,$subpath,$filter);        
    },
    childIndesxedOrNamed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _anyChildType(undef,$index,$data,$subpath,$filter);        
    },
    descendant => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(undef,undef,$subpath,$filter)
    },
    descendantArray => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(q|ARRAY|,undef,$subpath,$filter)
    },
    descendantHash => sub{
        my ($data, undef, $subpath,$filter) = @_;
        print "AQUI";
        return _getDescendantsByTypeAndName(q|HASH|,undef,$subpath,$filter)
    },
    descendantNamed => sub{
        my ($data, $name, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(q|HASH|,$name,$subpath,$filter)
    },
    descendantIndexed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(q|ARRAY|,$index,$subpath,$filter)
    },
    descendantIndexedOrNamed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(undef,$index,$subpath,$filter)
    },
    descendantOrSelf => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(undef,undef,$subpath,$filter,1)
    },
    descendantOrSelfArray => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(q|ARRAY|,undef,$subpath,$filter,1)
    },
    descendantOrSelfHash => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(q|HASH|,undef,$subpath,$filter,1)
    },
    descendantOrSelfNamed => sub{
        my ($data, $name, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(q|HASH|,$name,$subpath,$filter,1)
    },
    descendantOrSelfIndexed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(q|ARRAY|,$index,$subpath,$filter,1)
    },
    descendantOrSelfIndexedOrNamed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _getDescendantsByTypeAndName(undef,$index,$subpath,$filter,1)
    },
    precedingSibling => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _filterOutSiblings(undef,undef,$subpath, $filter,q|preceding|)        
    },
    precedingSiblingArray => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _filterOutSiblings(q|ARRAY|,undef,$subpath, $filter,q|preceding|)        
    },
    precedingSiblingHash => sub{
        my ($data, undef, $subpath,$filter) = @_;
        _filterOutSiblings(q|HASH|,undef,$subpath, $filter,q|preceding|)        
    },
    precedingSiblingNamed => sub{
        my ($data, $name, $subpath,$filter) = @_;
        return _filterOutSiblings(q|HASH|,$name,$subpath, $filter,q|preceding|)        
    },
    precedingSiblingIndexed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _filterOutSiblings(q|ARRAY|,$index,$subpath, $filter,q|preceding|)        
    },
    precedingSiblingIndexedOrNamed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _filterOutSiblings(undef,$index,$subpath, $filter,q|preceding|)        
    },
    followingSibling => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _filterOutSiblings(undef,undef,$subpath, $filter,q|following|)        
    },
    followingSiblingArray => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _filterOutSiblings(q|ARRAY|,undef,$subpath, $filter,q|following|)        
    },
    followingSiblingHash => sub{
        my ($data, undef, $subpath,$filter) = @_;
        return _filterOutSiblings(q|HASH|,undef,$subpath, $filter,q|following|)        
    },
    followingSiblingNamed => sub{
        my ($data, $name, $subpath,$filter) = @_;
        return _filterOutSiblings(q|HASH|,$name,$subpath, $filter,q|following|)        
    },
    followingSiblingIndexed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _filterOutSiblings(q|ARRAY|,$index,$subpath, $filter,q|following|)        
    },
    followingSiblingIndexedOrNamed => sub{
        my ($data, $index, $subpath,$filter) = @_;
        return _filterOutSiblings(undef,$index,$subpath, $filter,q|following|)        
    },
    slashslash => sub{
        my ($data, undef, $subpath,undef) = @_;
        return _descendant($data,$subpath);
    }
};


sub _getObjectSubset{
    my ($data,$path) = @_;
    $path //= {};                        #if not defined $path

    my %seen;
    return 
        sort {
            $a->{order} cmp $b->{order}
        }grep {
            defined $_ 
            and defined $_->{data} 
            and defined $_->{order} 
            and !$seen{$_->{data}}++
        } map {
            $dispatcher->{$_}->($data, $path->{$_}, $path->{subpath}, $path->{filter})
        } grep{
            exists $path->{$_}
        } keys %$dispatcher;
}
sub _getSubObjectsOrCurrent{
    my $paths = $_[0];
    return _getObjects(@$paths) if defined $paths and ref $paths eq q|ARRAY| and scalar @$paths > 0;
    return ($context[$#context]);
}
sub _getObjects{
        my @paths = @_;
        my @r = ();
        foreach my $entry (@paths){
            my $data = ${$context[defined $entry->{absolute} ? 0 : $#context]->{data}};
            push @r, _getObjectSubset($data,$entry->{path});
        }
        return @r;
}

###########object based invocation methods ########################
sub _execute{
    my ($self,$data,$query) = @_;
    return undef unless ref $data eq q|HASH| or ref $data eq q|ARRAY|; 
    return undef unless defined $query and (defined $query->{oper} or defined $query->{paths});
    push @context, {data  => \$data, type => ref $data, order => '', name => '/', size => 1, pos => 1};
    my @r = defined $query->{oper} ? 
        map {\$_} (_operation($query))                                #if an operation    
        : map {$_->{data}} sort {$a->{order} cmp $b->{order}} _getObjects(@{$query->{paths}});     #else is a path
    pop @context;
    return MarpaX::xPathLike::Results->new(@r);
}

#########################################public methods ###################################################################
$Data::Dumper::Deepcopy = 1;
sub new {}                 #The Marpa::R2 needs it
sub compile{
    my ($self,$q) = @_; 
    return undef unless $q;

    my $reader = Marpa::R2::Scanless::R->new({
        grammar => $grammar,
        trace_terminals => 0,
    }) or return undef;
    #code utf8 characters with sequece #utfcode#. Marpa problem?
    $q =~ s/[#\N{U+A0}-\N{U+10FFFF}]/sprintf "#%d#", ord $&/ge;
    #and, if we replace, we need to delimite the key if not already delimited  
    #and $q =~ s/\/{(?!["'])(.*?#\d+#.*?)(?!["'])}/\/{"$1"}/g; # and print "new q = $q"; 
    eval {$reader->read(\$q)};
    carp qq|Wrong xPathLike Expression $q\n$@| and return undef if $@; 
    #my $qp = $reader->value or return undef;
    my @ptree = ();
    while(my $pt = $reader->value){
        push @ptree, $pt; 
    }
    my $nt = scalar @ptree;
    return undef unless $nt;
    if ($nt > 1){
        foreach my $got (@ptree[1..$#ptree]){
            my ($ok, $stack) = cmp_details($got, $ptree[0]);
            unless ($ok){
                my $fh = *STDOUT;
                *STDOUT = *STDERR;
                carp qq|Found $nt trees for query $q, I will use the first\n|; 
                deep_diag($stack);
                *STDOUT = $fh;
            }        
        }
    }
    #print "compile", Dumper [@ptree];
    return MarpaX::xPathLike::Data->new(${$ptree[0]})
}

sub data{
    my ($self,$data) = @_;
    return MarpaX::xPathLike::Compiler->new($data)
}

sub DESTROY{
}

package MarpaX::xPathLike::Compiler;
use Data::Dumper;
sub new{
    my ($self,$data) = @_;
    return undef unless defined $data and (ref $data eq q|HASH| or ref $data eq q|ARRAY|); 
    return bless {data=>$data}, $self;
}

sub query{
    my ($self,$xPathLikeString) = @_;
    my $c = MarpaX::xPathLike->compile($xPathLikeString) or return undef;
    return $c->data($self->{data});    
}
sub DESTROY{
}


package MarpaX::xPathLike::Data;
#use Data::Dumper;

sub new{
    my ($self,$xPathLike) = @_;
    return undef unless defined $xPathLike and (defined $xPathLike->{oper} or defined $xPathLike->{paths});
    return bless {xPathLike=>$xPathLike}, $self;
}

sub data{
    my ($self,$data) = @_;
    return MarpaX::xPathLike->_execute($data,$self->{xPathLike});
}

sub DESTROY{
}

package MarpaX::xPathLike::Results;
#use Data::Dumper;

sub new {
    my ($self,@results) = @_;
    return bless {results=>[@results]}, $self;
}

sub getrefs{
    my $self = shift;
    return @{$self->{results}};
}
sub getref{
    my $self = shift;
    return $self->{results}->[0];
}
sub getvalues{
    my $self = shift;
    return map {$$_} @{$self->{results}};
}
sub getvalue{
    my $self = shift;
    return undef unless ref $self->{results}->[0];
    return ${$self->{results}->[0]};
}

1;
