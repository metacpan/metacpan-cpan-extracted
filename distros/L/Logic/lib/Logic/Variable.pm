package Logic::Variable;

use 5.006001;

use strict;
no warnings;

use Perl6::Attributes;

use Carp;

{
    my $counter = '0';
    sub new {
        my ($class) = @_;
        bless {
            id    => 'VAR' . $counter++,
        } => ref $class || $class;
    }
}

sub id {
    my ($self) = @_;
    $.id;
}

sub bound {
    my ($self, $state) = @_;
    $state->{$.id} && $state->{$.id}{bound};
}

sub binding {
    my ($self, $state) = @_;
    croak "variable not bound!" unless $state->{$.id}{bound};
    $state->{$.id} && $state->{$.id}{to};
}

sub bind {
    my ($self, $state, $to) = @_;
    $state->{$.id}{bound} = 1;
    $state->{$.id}{to} = $to;
}

sub unbind {
    my ($self, $state) = @_;
    delete $state->{$.id};
}

package Logic::Variable::Pad;

use Carp;

sub new {
    my ($class, $parent) = @_;
    tie my %self => ref $class || $class, $parent;
    bless \%self => ref $class || $class;
}

sub save {
    my ($self) = @_;
    $self = tied %$self || $self;
    ++$.rev;
    push @.diff, { add => { }, alter => { }, src => $.rev, dest => $.rev+1 };
    $.rev;
}

sub restore {
    my ($self) = @_;
    $self = tied %$self || $self;

    croak "Already at revision zero" unless @.diff;
    my $diff = pop @.diff;
    for (keys %{$diff->{alter}}) {
        $.pad{$_} = $diff->{alter}{$_};
    }
    for (keys %{$diff->{add}}) {
        delete $.pad{$_};
    }
    $.rev = $diff->{src};
}

sub revision {
    my ($self) = @_;
    $self = tied %$self || $self;
    $.rev;
}

sub merge {
    my ($self, $src, $dest) = @_;
    $self = tied %$self || $self;

    my $si = $self->find_internal_diff($src);
    my $di = $self->find_internal_diff($dest);
    my $diff = { 
        add => { }, 
        alter => { }, 
        src => $.diff[$si]{src}, 
        dest => $.diff[$di]{dest},
    };
    
    for my $rev ($src..$dest) {
        $diff->{add}{$_} = $.diff[$rev]{add}{$_} for keys %{$.diff[$rev]{add}};
        $diff->{alter}{$_} = $.diff[$rev]{alter}{$_} for keys %{$.diff[$rev]{alter}};
    }
    splice @.diff, $si, $di-$si+1, $diff;
}

sub commit {
    my ($self, $rev) = @_;
    $self = tied %$self || $self;
    $self->merge($rev, $.rev);
}

sub find_internal_diff {
    # Yeah, I implement my own binary search.  Search::Binary's interface is crap.
    my ($self, $rev) = @_;
    $self = tied %$self || $self;
    my $lo = 0;
    my $hi = @.diff-1;

    if ($rev > $.rev) {
        return scalar @.diff;
    }

    while ($hi > $lo) {
        my $i = int(($hi+$lo)/2);
        if ($rev < $.diff[$i]{src}) {
            $hi = $i - 1;
        }
        elsif ($rev >= $.diff[$i]{dest}) {
            $lo = $i + 1;
        }
        else {
            return $i;
        }
    }
    return $lo;
}

# for saving memory for gc'd variables
sub prune {
    my ($self, $key) = @_;
    $self = tied %$self || $self;

    delete $.pad{$key};
    for (@.diff) {
        delete $_->{alter}{$key};
        delete $_->{add}{$key};
    }
}

sub TIEHASH {
    my ($class, $parent) = @_;
    bless {
        parent => $parent && tied %$parent,
        pad => { },
        rev => 0,
        diff => [ { add => { }, alter => { }, src => 0, dest => 1 } ],
    } => $class;
}

sub FETCH {
    my ($self, $key) = @_;
    $.pad{$key} && $.pad{$key}{value};
}

sub STORE {
    my ($self, $key, $value) = @_;
    if (exists $.pad{$key}) {
        if ($.pad{$key}{rev} < $.rev) {
            $.diff[-1]{alter}{$key} = $.pad{$key};
        }
    }
    else {
        $.diff[-1]{add}{$key} = 1;
    }
    $.pad{$key} = { value => $value, rev => $.rev };
}

1;
