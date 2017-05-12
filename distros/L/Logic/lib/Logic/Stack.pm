package Logic::Stack;

use 5.006001;

use strict;
no warnings;

use Carp;
use Perl6::Attributes;
use Logic::Variable;

sub new {
    my ($class, @init) = @_;
    bless {
        state => Logic::Variable::Pad->new,
        run => [ ],
        cur => { 
            up => undef, 
            back => undef, 
            ptr => 0, 
            gen => \@init, 
        },
    } => ref $class || $class;
}

sub state {
    my ($self) = @_;
    $.state;
}

sub descend {
    my ($self, @gen) = @_;
    $.cur = { 
        up => $.cur, 
        back => $.cur,
        ptr => 0, 
        gen => \@gen 
    };
    1;
}

# criteria for when you can replace a descend with a tail_descend:
#   you're only descending into one thing
#   your backtrack does nothing (or will do nothing after this time)
#   your cleanup does nothing
sub tail_descend {
    my ($self, @gen) = @_;   #only single gen allowed
    croak "Only one gen allowed on tail_descend" unless @gen == 1;
    my $new = $gen[0]->create($self, $.state);
    if ($new) {
        pop @.run;
        push @.run, $new;
        $.run[-1]->enter($self, $.state);
    }
    else {
        undef;
    }
}

sub print_stack {
    my ($self) = @_;
    print STDERR "-----\nSTACK:\n";
    my $cptr = $.cur;
    while ($cptr) {
        print STDERR "  PTR: $cptr->{ptr}; FRAME: (@{$cptr->{gen}})\n";
        $cptr = $cptr->{up};
    }
    print STDERR "RUN:\n";
    for (reverse @.run) {
        print "  $_\n";
    }
    print STDERR "-----\n";
}

sub advance {
    my ($self) = @_;
    return unless $.cur;
    if ($.cur{ptr} < @{$.cur{gen}}) {
        my $next = $.cur{gen}[$.cur{ptr}++]->create($self, $.state);
        if ($next) {
            push @.run, $next;
            goto &{$self->can('enter')};
        }
        else {
            goto &{$self->can('backup')};
        }
    }
    else {
        if ($.cur{up}) {
            $.cur = { 
                up => $.cur{up}{up}, 
                back => $.cur, 
                ptr => $.cur{up}{ptr}, 
                gen => $.cur{up}{gen}, 
            };
            goto &{$self->can('advance')};
        }
        else {
            return;
        }
    }
}

sub enter {
    my ($self) = @_;
    if ($.run[-1]->enter($self, $.state)) {
        return 1;
    }
    else {
        goto &{$self->can('backup')};
    }
}

sub backup {
    my ($self) = @_;
    
    $self->backup_gen;
    (pop @.run)->cleanup($self, $.state);
    return unless @.run;
    
    if ($.run[-1]->backtrack($self, $.state)) {
        return 1;
    }
    else {
        goto &{$self->can('backup')};
    }
}

sub backup_gen {
    my ($self) = @_;
    return unless $.cur;
    if ($.cur{ptr}) {
        $.cur{ptr}--;
        my $ret = $.cur;
        until (!$.cur || $.cur{ptr}) {
            $.cur = $.cur{back};
        }
        return $ret;
    }
    else {
        $.cur = $.cur{back};
        goto &{$self->can('backup_gen')};
    }
}

sub failto {
    my ($self, $mark) = @_;
    $self->backtrack until !@.run || $.run[-1] == $mark;
}

sub run {
    my ($self) = @_;
    while ($self->advance) { }
    scalar @.run;   # if there's nothing on the stack, we fail
}

sub backtrack {
    my ($self) = @_;
    $self->backup;
    goto &{$self->can('run')};
}

sub snip {
    my ($self) = @_;
    my $run = pop @.run;
    my $top = $self->backup_gen;
    my ($gen) = splice @{$top->{gen}}, $top->{ptr}, 1;
    ($run, $gen);
}

sub cut {
    my ($self, $mark) = @_;
    my ($cutter_run, $cutter_gen) = $self->snip;
    until (!@.run || $.run[-1] == $mark) {
        $self->snip;
    }
    splice @{$.cur{gen}}, $.cur{ptr}, 0, $cutter_gen;
    push @.run, $cutter_run;
    $.cur{ptr}++;
    $.state->commit($mark->revision);
    1;
}

package Logic::Stack::Mark;

sub new {
    my ($class) = @_;
    bless { 
        rev => undef,
    } => ref $class || $class;
}

sub revision {
    my ($self) = @_;
    $.rev;
}

sub create {
    my ($self) = @_;
    $self;
}

sub enter { 
    my ($self, $stack, $state) = @_;
    $.rev = $state->save;
    1;
}

sub backtrack { }
sub cleanup { 
    my ($self, $stack, $state) = @_;
    $state->restore;
}

package Logic::Stack::Cut;

sub new {
    my ($class, $mark) = @_;
    bless {
        mark => $mark,
    } => ref $class || $class;
}

sub create {
    my ($self) = @_;
    $self;
}

sub enter {
    my ($self, $stack, $state) = @_;
    $stack->cut($.mark);
}

sub backtrack { }   # the cut already did it for us
sub cleanup { }

1;
