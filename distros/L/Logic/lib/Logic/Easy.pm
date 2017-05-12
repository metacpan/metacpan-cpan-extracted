package Logic::Easy;

use strict;
no warnings;

use Exporter;
use base 'Exporter';

use Attribute::Handlers;

use Logic::Stack;
use Logic::Variable;
use Logic::Basic;
use Logic::Data;
use Carp;

# Devel::Caller::Perl is loud about its own warnings.  Shut it up.
our $PREWFLAG;
BEGIN { $PREWFLAG = $^W; $^W = 0; }
use Devel::Caller::Perl;
BEGIN { $^W = $PREWFLAG }

use Perl6::Attributes;
use Filter::Simple;
use Carp;


sub _filter_signature {
    # filters lines that look like SIG [$x, $y] where is($x, $y)
    my ($sig, $where) = @_;
    my (@vars) = $sig =~ /(\$[a-zA-Z_]\w*)/g;
    my $varstr = join(',', @vars);
    my $str = (@vars ? "my ($varstr); Logic::Easy::vars($varstr); " : "") 
            . "Logic::Easy->is([\@_], $sig)";
    
    if ($where =~ /^\s*\{/) {
        $str .= "->bind($varstr, sub { sub { $where }->() or Logic::Easy::fail() });";
    }
    elsif ($where) {
        $str .= "->$where->bind($varstr);";
    }
    else {
        $str .= "->bind($varstr);";
    }
    $str;
}

FILTER {
    s/^ [ \t]* SIG [ \t]* ([^\n]+?) [ \t]* 
      (?: where [ \t]* ([^\n]+) [ \t]* )? ; [ \t]* $/
        _filter_signature($1, $2)/mgex;
    $_;
};

our @EXPORT = qw<var vars cons fail sig any Logic>;

our %MULTI;

sub UNIVERSAL::Multi : ATTR(CODE) {
    my (undef, $glob, $code, undef, $name) = @_;
    push @{$MULTI{$name}}, $code;
    if ($glob ne 'ANON') {
        *$glob = sub { unshift @_, $name;  goto &_run_multi };
    }
}

sub _run_multi {
    my $name = shift;
    if ($MULTI{$name}) {
        for my $code (@{$MULTI{$name}}) {
            my ($ret, @rets);
            my $wantarray = wantarray;
            if (eval {
                if ($wantarray) {
                    @rets = $code->(@_);
                }
                else {
                    $ret = $code->(@_);
                }
                1;
            }) {
                if ($wantarray) {
                    return @rets;
                }
                else {
                    return $ret;
                }
            }

            if ($@ =~ /Logic::/) {
                next;
            }
            else {
                croak($@ || "Logic::Easy multi dispatch failed");
            }
        }
    }
    else {
        confess "No such method found: $name (I don't know how you made it to the dispatcher)";
    }
}

sub Logic() { 'Logic::Easy' }

sub new {
    my ($class, @preds) = @_;
    bless {
        preds => \@preds,
    } => ref $class || $class;
}

sub create {
    my ($self) = @_;
    _made $self;
    Logic::Basic::Sequence->new(@.preds);
}

sub _make {
    ref $_[0] ? $_[0] : $_[0]->new;
}

sub _made {
    $_[0] = _make $_[0];
}

# XXX clean up this implementation... a lot.
sub bind { 
    my $self = _make shift;
    if (@_ && ref $_[-1] eq 'CODE') {
        my $stack = Logic::Stack->new(@.preds);
        if ($stack->run) {
        AGAIN:
            my @vars = @_;
            for (@_[0..$#_-1]) {
                $_ = Logic::Data::resolve($_, $stack->state, vars => 1);
            }
            unless (eval { $_[-1]->(); 1 }) {
                for (0..$#_-1) {
                    $_[$_] = $vars[$_];
                }
                
                if ($@ =~ /Logic::/) {
                    if ($stack->backtrack) {
                        goto AGAIN;
                    }
                    else {
                        goto FAIL;
                    }
                }
                else {
                    croak($@ || "Logic::Easy binding predicate failed");
                }
            }
            return 1;
        }   

        FAIL:
        if (defined wantarray) {
            return();
        }
        else {
            croak($@ || "Logic::Easy predicate failed");
        }
    }
    else {   # not given a code argument
        $self->bind(@_, sub { });
    }
}

#### PREDICATES ####

sub all {   # generally redundant
    my ($self, @cands) = @_;
    _made $self;
    $self->new(@.preds, Logic::Basic::Sequence->new(@cands));
}

sub any {
    if ($_[0] eq 'Logic::Easy' || ref $_[0] eq 'Logic::Easy') {
        my ($self, @cands) = @_;
        _made $self;
        $self->new(@.preds, Logic::Basic::Alternation->new(@cands));
    }
    else {
        Logic::Data::Disjunction->new(@_);
    }
}

sub id {
    my ($self) = @_;
    _made $self;
    $self->new(@.preds, Logic::Basic::Identity->new);
}

sub fail {
    if (@_) {  # method call
        my ($self) = @_;
        _made $self;
        $self->new(@.preds, Logic::Basic::Fail->new);
    }
    else {     # control operator
        croak "Logic::Easy control failed";
    }
}

sub assert {
    my $self = _make shift;
    my $code = pop;
    my @args = @_;
    my @vars = map { \$_[$_] } 0..$#_;
    $self->new(@.preds, Logic::Basic::Assertion->new(sub {
        my $state = shift;
        my $result = eval {
            for (@vars) {
                $$_ = Logic::Data::resolve($$_, $state);
            }
            $code->();
        };
        for (0..$#vars) {
            ${$vars[$_]} = $args[$_];
        }
        $result;
    }));
}

sub rule {
    my ($self, $code) = @_;
    _made $self;
    $self->new(@.preds, Logic::Basic::Rule->new($code));
}

sub bound {
    my ($self, $var) = @_;
    _made $self;
    $self->new(@.preds, Logic::Basic::Bound->new($var));
}

sub is {
    my ($self, $a, $b) = @_;
    _made $self;
    $self->new(@.preds, Logic::Data::Unify->new($a, $b));
}

sub assign {
    my ($self, @vars) = @_;
    _made $self;
    my $code = pop @vars;
    croak "Usage: Logic->assign(\$var1, \$var2, ..., sub { code })" 
            unless ref $code eq 'CODE';
    $self->new(@.preds, Logic::Data::Assign->new($code, @vars));
}

sub block {
    my ($self) = @_;
    _made $self;
    $self->new(@.preds, Logic::Data::Stop->new);
}

sub for {
    my ($self, $var, @values) = @_;
    _made $self;
    $self->new(@.preds, Logic::Data::For->new($var, @values));
}

sub sig {
    my ($pattern) = @_;
    my @args = Devel::Caller::Perl::called_args(0);
    Logic::Easy->is(\@args, $pattern);
}

#### CONSTRUCTORS (exported) ####

sub cons {
    my ($head, $tail) = @_;
    Logic::Data::Cons->new($head, $tail);
}

sub var($) {
    $_[0] = Logic::Variable->new;
}

sub vars {
    for (@_) { $_ = Logic::Variable->new; }
    @_;
}


1;
