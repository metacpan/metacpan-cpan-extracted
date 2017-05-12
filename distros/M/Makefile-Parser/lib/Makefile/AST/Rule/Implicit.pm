package Makefile::AST::Rule::Implicit;

use strict;
use warnings;

#use Smart::Comments;
#use Smart::Comments '####';
use base 'Makefile::AST::Rule::Base';
use List::Util qw( first );

__PACKAGE__->mk_ro_accessors(qw{
    targets
});

sub as_str ($) {
    my $self = shift;
    my $order_part = '';
    ## as_str: order_prereqs: $self->order_prereqs
    if (@{ $self->order_prereqs }) {
        $order_part = " | " . join(" ",@{ $self->order_prereqs });
    }
    ### colon: $self->colon
    my $str = join(" ", @{ $self->targets }) . " " .
            $self->colon . " " .
            join(" ", @{ $self->normal_prereqs }) . "$order_part ; " .
            join("", map { "[$_]" } @{ $self->commands });
    $str =~ s/\n+//g;
    $str =~ s/  +/ /g;
    $str;
}

# judge if $self is a match anything rule
sub match_anything ($) {
    my $self = shift;
    first { $_ eq '%' } $self->targets;
}

sub is_terminal ($) {
    $_[0]->colon eq '::';
}

sub match_target ($$) {
    my ($self, $target) = @_;
    for my $pat (@{ $self->targets }) {
        ### match_target: pattern: $pat
        ### match_target: target: $target
        my $match = Makefile::AST::StemMatch->new(
            { target => $target, pattern => $pat }
        );
        return $match if $match;
    }
    return undef;
}

# apply the current rule to the given target
sub apply ($$$@) {
    my ($self, $ast, $target, $opts) = @_;
    #### applying implicit rule to target: $target
    my $recursive;
    $recursive = $opts->{recursive} if $opts;
    #### $recursive
    my $match = $self->match_target($target);
    ## $match
    return undef if !$match;
    my (@other_targets, @normal_prereqs, @order_prereqs);
    for (@{ $self->targets }) {
        next if $_ eq $match->pattern;
        push @other_targets, $match->subs_stem($_);
    }
    for (@{ $self->normal_prereqs }) {
        push @normal_prereqs, $match->subs_stem($_);
    }
    for (@{ $self->order_prereqs }) {
        push @order_prereqs, $match->subs_stem($_);
    }
    for my $prereq (@order_prereqs, @normal_prereqs) {
        #### Test whether the prereq exists or ought to exist: $prereq
        #### target exists? : $ast->target_exists($prereq)
        ## file test: -e 'bar.hpp'
        #### Target ought to exists? : $ast->target_ought_to_exist($prereq)
        next if $ast->target_exists($prereq) or
            $ast->target_ought_to_exist($prereq);
        #### Failed to pass...
        # XXX mark intermedia files here
        next if $recursive and
            $ast->apply_implicit_rules($prereq);
        return undef;
    }
    return Makefile::AST::Rule->new(
      {
        target         => $target,
        colon          => $self->colon,
        stem           => $match->stem,
        normal_prereqs => \@normal_prereqs,
        order_prereqs  => \@order_prereqs,
        other_targets  => \@other_targets,
        commands       => $self->commands,
      }
    );
}

1;

