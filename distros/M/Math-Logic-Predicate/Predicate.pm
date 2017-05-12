package Math::Logic::Predicate;

use Parse::RecDescent;
use Carp;

use strict;

our $GRAMMAR = join '', <DATA>;
our $DEBUG;

our $VERSION = 0.03;

sub new($)
{
    my ($class) = @_;
    bless {
        pred => { },
        nonterm => sub { $_[0] =~ /^[_A-Z]/ },
        no_code => undef,
        parser => undef,
    } => $class
}

sub rules(\$) : lvalue
{
    shift->{pred}
}

sub parse(\$$;$)
{
    my ($self, $expr, $auto) = @_;
    $self->{parser} ||= new Parse::RecDescent($GRAMMAR) or confess;
    $self->{parser}{LG} = $self;
    my $ret;
    if ($auto) {
        $ret = $self->{parser}->auto($expr);
    }
    else {
        $ret = $self->{parser}->statement($expr);
    }
    if ($ret) {
        return wantarray ? @$ret : $ret->[0];
    }
    return
}

sub newproc(\$$$;$$$)
{
    my ($self, $rule, $args, $context, $next, $prev) = @_;
    $context ||= 'true';

    unless (grep { $context == $_ } qw(true false and or sub bind)) {
        croak "'$context' is not a valid context type";
    }
    
    my $ret = {
        context => $context,
        rule => $rule,
        args => $args,
    };

    $ret->{next} = $next;
    $ret->{fail} = $prev;
    unless ($context eq 'true' || $context eq 'false' || $context eq 'bind') {
        $ret->{next}{fail} ||= $ret if $next;
    }
    $ret
}

sub add(\$$)
{
    my ($self, $proc) = @_;

    if (ref $proc) { 
    
    croak "You can't add an undefined rule" unless $proc;
    croak "You can't add queries to the database" if $proc->{rule} eq '^QUERY';
    croak "You can't add variable predicates"if $self->{nonterm}($proc->{rule});

    if (@{$proc->{args}}) {
        $self->{pred}{$proc->{rule}} = { } unless $self->{pred}{$proc->{rule}};
    }
    else {
        $self->{pred}{$proc->{rule}} = [ ] unless $self->{pred}{$proc->{rule}};
    }
    $self->addproc_h($proc, 0, $self->{pred}{$proc->{rule}});
    $proc
    
    } 
    else {
        $self->parse($proc, 'auto')
    }
}

sub retract(\$$)
{
    my ($self, $proc) = @_;
    
    $proc = $self->parse($proc) unless ref $proc;
    
    my ($pad, $frame) = ( {}, {} );
    while ($self->lookup($proc, $frame, $pad, 'delete')) { }
    1;
}

sub addproc_h(\$$$$)
{
    my ($self, $proc, $argn, $href) = @_;
    if (local $_ = $proc->{args}[$argn]) {
        my $r = $self->{nonterm}($_) ? '_' : $_;
        unless ($href->{$r}) {
            if ($argn == $#{$proc->{args}}) {       # Last argument
                $href->{$r} = [ ];
            }
            else {
                $href->{$r} = { };
            }
            delete $href->{'^SORT'}; 
        }
        $self->addproc_h($proc, $argn+1, $href->{$r});
    }
    else {
        # Don't duplicate
        if ($proc->{context} eq 'true' || 
            $proc->{context} eq 'false') {  # Don't duplicate
            return if grep { $_->{context} eq $proc->{context} } @$href;
        }
        # Is this rule directly recursive?
        if ($proc->{context} eq 'bind') {
            my $cptr = $proc->{next};
            while ($cptr) {
                if ($cptr->{rule} eq $proc->{rule}) {  #If so...
                    push @$href, $proc;
                    return 1;
                }
                $cptr = $cptr->{next};
            }
        }
        unshift @$href, $proc;
    }
    1;
}

sub lookup(\$$$$;$)
{
    my ($self, $proc, $lse, $pad, $delete) = @_;

    my $rule = $proc->{rule};
    $rule = $pad->{$rule} if $self->{nonterm}($rule);

    $lse->{fail}++,return if $lse->{fail};
    $lse->{fail}++,return unless $rule && $self->{pred}{$rule};

    $lse->{pred_stack} ||= [ $self->{pred}{$rule} ];
    $lse->{iter_stack} ||= [ 0 ];
    $lse->{bind_stack} ||= [ 0 ];
    $lse->{pos} ||= 0;
    
    my $pred = $lse->{pred_stack};
    my $iter = $lse->{iter_stack};
    my $bind = $lse->{bind_stack};
   
    
    while (@$pred) {
        my $p;
        unless ($lse->{pos} == @{$proc->{args}}) {
            $p = $proc->{args}[$lse->{pos}];
            $pred->[0]{'^SORT'} = [ sort keys %{$pred->[0]} ]
                    unless $pred->[0]{'^SORT'};
        }
        my $state = 'push';
        $p = exists $pad->{$p} ? $pad->{$p} : $p;

        if ($lse->{pos} == @{$proc->{args}}) {
            $state = 'pop' if $iter->[0] == @{$pred->[0]};
        }
        else {
            if ($self->{nonterm}($p)) {
                $state = 'pop' if $iter->[0] == @{$pred->[0]{'^SORT'}};
            }
            else {
                my $len = exists($pred->[0]{$p}) + exists($pred->[0]{_});
                $state = 'pop' if $iter->[0] >= $len;
            }
        }
       
        if ($state eq 'pop') {
            my $free = shift @$bind;
            shift @$iter;
            shift @$pred;
            delete $pad->{$free} if $free;
            $lse->{pos}--;
            
                
            unless (@$iter) {
                $lse->{fail}++;
                return;
            }
        }
        else {
            my $ind;
            my $pi = $iter->[0]++;
            unless (defined $p) {
                if ($delete) {
                    delete $pred->[1]{'^SORT'};
                    return splice @{$pred->[0]}, --$iter->[0], 1;
                }
                else {
                    return $pred->[0][$pi];
                }
            }
            elsif ($self->{nonterm}($p)) {
                $ind = $pred->[0]{'^SORT'}[$pi];
                # No binding to anonymous vars
                unless ($p eq '_' || $ind eq '_' ||
                        exists $pad->{$p}) {  
                    $pad->{$p} = $ind;
                    unshift @$bind, $p;
                }
                else {                  # Still need a frame, though
                    unshift @$bind, (undef);
                }
            }
            else {
                if ($pi) { 
                    $ind = '_';
                }
                else {
                    $ind = exists $pred->[0]{$p} ? $p : '_';
                }
                unshift @$bind, 0;
            }
            unshift @$pred, $pred->[0]{$ind};
            unshift @$iter, 0;
            $lse->{pos}++;
        }
    }
}

sub copy_pad(\$$$$$;$) {
    my ($self, $srule, $scon, $drule, $dcon, $bindtrack) = @_;
    
    return unless @{$srule->{args}} == @{$drule->{args}};
    
    # I want perl6 parallel iteration!!
    for (my $i = 0; $i < @{$drule->{args}}; $i++) {
        if ($self->{nonterm}($drule->{args}[$i])) {
            my $bind = $srule->{args}[$i];
            $bind = $scon->{pad}{$bind} if $self->{nonterm}($bind);
            if (defined $bind && $drule->{args}[$i] ne '_' && 
                    !exists $dcon->{pad}{$drule->{args}[$i]}) {
                $dcon->{pad}{$drule->{args}[$i]} = $bind;
                $dcon->{stack}[0]{bindings} ||= [ ];
                push @{$dcon->{stack}[0]{bindings}}, 
                     $drule->{args}[$i] if $bindtrack;
            }
        }
    }
    1;
}

# Returns a context or undef
# Changes are reflected in the pad
sub match(\$$;$$)
{
    my ($self, $proc, $state, $indent) = @_; 

    $proc = $self->parse($proc) unless ref $proc;

    my $cptr;                   # Pointer to frame of chain
    my $res = 0;                # Did the last thing executed succeed (1,0)?
    my $dir = 1;                # Are we going forward or backtracking (1,0)?
   
    $state ||= { pad => {}, stack => [] };
    
    return $state if $proc->{context} eq 'true';
    return undef if $proc->{context} eq 'false';

    if ($proc->{context} eq 'bind' && $proc->{code}) {
        $state->{stack}[0]{bindings} ||= [];
        delete $state->{pad}{$_} for @{$state->{stack}[0]{bindings}};
        @{$state->{stack}[0]{bindings}} = ();

        my @nt = grep { $self->{nonterm}($_) } @{$proc->{args}};

        unless ($proc->{bindcode}) {
        
            my $ev;
            $ev = "package main; no strict; my \%r;\n";
            $ev .= 'my ($pad, $stack) = @_;';
            $ev .= "local \$$_ = \$pad->{$_};"
                  ."\$r{$_} = \$$_ =~ s/^'//;\n"  for @nt;
            $ev .= <<'EOC';
                local $track = !$stack->{track}; 
                $stack->{track} = 1;
                $stack->{local} ||= { };
                local $local = $stack->{local};
                my $res = $proc->{code}();
EOC
            for (@nt) {
                $ev .= <<EOC;
                if (defined \$$_) {
                    \$$_ = q{'}.\$$_ if \$r{$_} || \$$_ =~ /\\W/;
                    push \@{\$stack->{bindings}}, '$_'
                      unless exists \$pad->{$_};
                    \$pad->{$_} = \$$_;
                } else { 
                    delete \$pad->{$_} 
                }
EOC
            }
            $ev .= "\$res\n";
            $proc->{bindcode} = eval "sub { $ev }";
            confess $@ if $@;
        }

        $res = $proc->{bindcode}($state->{pad}, $state->{stack}[0]);
        return $res ? $state : undef
    }
   
    if ($state->{stack}[0]{ptr}) {   # Anything meaningful on the stack?
        print "$indent Loading stack...\n"  if $DEBUG;
        delete $state->{pad}{$_} for @{$state->{stack}[0]{bindings}};
        @{$state->{stack}[0]{bindings}} = ();
        $cptr = $state->{stack}[0]{ptr};
        $dir = 0;
    }
    else {                          # Put something there
        # $proc is the name of the rule; we want $proc->{next}
        $state->{stack}[0]{ptr} = $cptr = $proc->{next};
    }

    while ($cptr) {
        $state->{stack}[0]{ptr} = $cptr;        # Tell the stack where we are
        
        # If we're backtracking, and we skipped on the forward, skip back too
        goto skip if $cptr->{context} eq 'or' and $state->{stack}[0]{skip}
                                          and not $dir;
                                          
        goto skip if $cptr->{context} eq 'sub' 
                     and not $dir and not $state->{stack}[0]{last};
        goto skip if $cptr->{context} eq 'sub' && not $res;

        # On forward success in an or chain, skip the current rule
        goto skip if $cptr->{context} eq 'or'  and  $res  and  $dir
                     and $state->{stack}[0]{skip} = 1;
       
        $state->{stack}[0]{skip} = 0;
        
        # In true context, just go forward
        if ($cptr->{context} eq 'true') {
            $res = $dir = 1;
            goto retry;
        }

        # In false context, just go backward (duh)
        if ($cptr->{context} eq 'false') {
            $res = $dir = 0;
            goto retry;
        }
        
        # If we don't have something to try, try to get something to try
        my $try = $state->{stack}[0]{rule};
        my $frame = $state->{stack}[0]{frame};
        unless ($frame) {
            print "$indent Look:  $cptr->{rule}(", 
                join(', ', map { "$_($state->{pad}{$_})" } @{$cptr->{args}}), 
                ")\n" if $DEBUG;
            $try = $self->lookup($cptr, $state->{stack}[0], $state->{pad});
            # Fail entirely if we couldn't find anything new 
            unless ($try) {
                print "$indent Lost\n" if $DEBUG;
                $res = 0;
                goto retry;
            }
            print "$indent Find:  $try->{rule}(", join(', ', @{$try->{args}}), 
                  ")\n" if $DEBUG;

            if ($try->{context} eq 'bind') {    # Only if it's complex
                $state->{stack}[0]{rule} = $try;
                $state->{stack}[0]{frame} = $frame = { stack => [], pad => {} };
            }
        }
        
        # Give them variables they need and we have
        $self->copy_pad($cptr, $state  =>  $try, $frame);
       
        print "$indent Try:   $cptr->{rule}(", join(', ',
            map { $_ . "($state->{pad}{$_})" } @{$cptr->{args}}), ")\n"
                if $DEBUG;
        
        unless ( $res = ! !$self->match($try, $frame, "$indent  ") ) {
            print "$indent Fail\n" if $DEBUG;
            undef $state->{stack}[0]{frame};    # Clear the frame
            next;                               # Try again
        }
        
        
        $dir = 1 if $res;

        # Get their variables if they bound any we want
        $self->copy_pad($try, $frame  =>  $cptr, $state,  'bind');
        
        print "$indent Match: $cptr->{rule}(", join(', ',
            map { $_ . "($state->{pad}{$_})" } @{$cptr->{args}}), ")\n"
                if $DEBUG;
        
retry:
        if ($cptr->{context} eq 'sub') {
            if ($dir) {
                if ($res && $state->{stack}[1]{last}) {
                    $dir = $res = 0;
                }
                elsif (!$state->{stack}[1]{last}) {
                    $dir = $res = 0;
                    if ($cptr->{next} &&
                           ($cptr->{next}{context} eq 'or'
                         || $cptr->{next}{context} eq 'sub')) {
                        $dir = 1 unless $state->{stack}[0]{fail} > 1;
                    }
                }
                else {
                    $dir = $res = 1;
                }
            }
        }
        else {
            $dir = $res;
            if ($cptr->{next} &&
                  ($cptr->{next}{context} eq 'or'
                || $cptr->{next}{context} eq 'sub')) {
                $dir = 1 unless $state->{stack}[0]{fail} > 1;
            }
        }

skip:   
        if ($dir) {             # If we're going forward
            $state->{stack}[0]{last} = $res;

            $cptr = $cptr->{next};
            unshift @{$state->{stack}}, { };    # Establish new stack frame
        }
        else {                  # We're going backward
            $cptr = $cptr->{fail};
            for (@{$state->{stack}[0]{bind_stack}}) {
                delete $state->{pad}{$_};
            }
            @{$state->{stack}[0]{bind_stack}} = ();
            shift @{$state->{stack}};           # Clear the frame
                # Unbind any variables in the new frame
                # in order to rebind them this run.
            delete $state->{pad}{$_} for @{$state->{stack}[0]{bindings}};
            @{$state->{stack}[0]{bindings}} = ();
        }
    }

    shift @{$state->{stack}};
    $res ? $state : undef;
}

sub get(\$$$) {
    my ($self, $iter, $sym) = @_;
    if (exists $iter->{pad}{$sym}) {
        my $ret = $iter->{pad}{$sym};
        $ret =~ s/^'//;
        $ret
    }
    else {
        undef
    }
}

1

__DATA__

auto: definition '.' auto(?)
  { $thisparser->{LG}->add( $item[1] ); 
    [ @item[1..2] ] }

statement: definition '.'
  { [ @item[1..2] ] }
         | query '?'
  { [ @item[1..2] ] }
         | <error>

definition: pred ':=' chain
  { $item[1]->{context} = 'bind'; 
    $item[1]->{next} = $item[3];
    $item[1] }
          | pred ':=' code
  { $item[1]->{context} = 'bind';
    $item[1]->{code} = $item[3];
    $item[1] }
          | pred
  { $item[1]->{context} = 'true'; $item[1] }

query: chain
  { $thisparser->{LG}->newproc('^QUERY', [ ], 'bind', $item[1]) }

chain: pred op chain
  { $item[1]->{next} = $item[3]; 
    $item[3]->{fail} = $item[1];
    $item[3]->{context} = 'or' if $item[2] eq '|';
    $item[3]->{context} = 'sub' if $item[2] eq '-';
    $item[1] }
     | pred

op: '&' | '|' | '-'

pred: id '(' arglist ')'
  { $thisparser->{LG}->newproc($item[1], $item[3], 'and') }
    | id
  { $thisparser->{LG}->newproc($item[1], [ ], 'and') }

code: <perl_codeblock>
  { if ($thisparser->{LG}{no_code}) {
        warn "No code allowed on line $thisline";
        undef
    } else {
        my $ret = eval "package main; no strict; sub $item[1]";
        warn "$@ on line $thisline" unless $ret;
        $ret
  } }


arglist: id ',' arglist
  { [ $item[1], @{$item[3]} ] }
       | id
  { [ $item[1] ] }

id: /[a-zA-Z_]\w*/
  | /-?(?:\d+\.\d*|\d*\.\d+|\d+)/
  | <perl_quotelike>
  { "'$item[1][2]" }

