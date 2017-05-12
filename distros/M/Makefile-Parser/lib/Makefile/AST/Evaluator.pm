package Makefile::AST::Evaluator;

use strict;
use warnings;

our $VERSION = '0.216';

#use Smart::Comments;
#use Smart::Comments '####';
use File::stat;
use Class::Trigger qw(firing_rule);

# XXX put these globals to some better place
our (
    $Quiet, $JustPrint, $IgnoreErrors,
    $AlwaysMake, $Question
);

sub new ($$) {
    my $class = ref $_[0] ? ref shift : shift;
    my $ast = shift;
    return bless {
        ast     => $ast,
        updated => {},
        mtime_cache => {},  # this is better for the AST?
        parent_target => undef,
        targets_making => {},
        required_targets => {},
    }, $class;
}

sub ast ($) { $_[0]->{ast} }

sub mark_as_updated ($$) {
    my ($self, $target) = @_;
    ### marking target as updated: $target
    $self->{updated}->{$target} = 1;
}

# XXX this should be moved to the AST
sub is_updated ($$) {
    my ($self, $target) = @_;
    $self->{updated}->{$target};
}

# update the mtime cache with -M $file
sub update_mtime ($$@) {
    my ($self, $file, $cache) = @_;
    $cache ||= $self->{mtime_cache};
    if (-e $file) {
        my $stat = stat $file or
            die "$::MAKE: *** stat failed on $file: $!\n";
        ### set mtime for file: $file
        ### mtime: $stat->mtime
        return ($cache->{$file} = $stat->mtime);
    } else {
        ## file not found: $file
        return ($cache->{$file} = undef);
    }
}

# get -M $file from cache (if any) or set the cache
#  key-value pair otherwise
sub get_mtime ($$) {
    my ($self, $file) = @_;
    my $cache = $self->{mtime_cache};
    if (!exists $cache->{$file}) {
        # set the cache
        return $self->update_mtime($file, $cache);
    }
    return $cache->{$file};
}

sub set_required_target ($$) {
    my ($self, $target) = @_;
    $self->{required_targets}->{$target} = 1;
}

sub is_required_target ($$) {
    my ($self, $target) = @_;
    $self->{required_targets}->{$target};
}

sub make ($$) {
    my ($self, $target) = @_;
    return 'UP_TO_DATE'
        if $self->is_updated($target);
    my $making = $self->{targets_making};
    if ($making->{$target}) {
        warn "$::MAKE: Circular $target <- $target ".
            "dependency dropped.\n";
        return 'UP_TO_DATE';
    } else {
        $making->{$target} = 1;
    }
    my $retval;
    my @rules = $self->ast->apply_explicit_rules($target);
    ### number of explicit rules: scalar(@rules)
    if (@rules == 0) {
        ### no rule matched the target: $target
        ### trying to make implicitly here...
        my $ret = $self->make_implicitly($target);
        delete $making->{$target};
        if (!$ret) {
            return $self->make_by_rule($target => undef);
        } else {
            return $ret;
        }
    }
    # run the double-colon rules serially or run the
    # single matched single-colon rule:
    for my $rule (@rules) {
        my $ret;
        ### explicit rule for: $target
        ### explicit rule: $rule->as_str
        if (!$rule->has_command) { # XXX is this really necessary?
            ### The explicit rule has no command, so
            ### trying to make implicitly...
            $ret = $self->make_implicitly($target);
            $retval = $ret if !$retval || $ret eq 'REBUILT';
        }
        $ret = $self->make_by_rule($target => $rule);
        ### make_by_rule returned: $ret
        $retval = $ret if !$retval || $ret eq 'REBUILT';
    }
    delete $making->{$target};

    # postpone the timestamp propagation until all individual
    # rules have been updated:
    $self->update_mtime($target);

    $self->mark_as_updated($target);

    return $retval;
}

sub make_implicitly ($$) {
    my ($self, $target) = @_;
    if ($self->ast->is_phony_target($target)) {
        ### make_implicitly skipped target since it's phony: $target
        return undef;
    }
    my $rule = $self->ast->apply_implicit_rules($target);
    if (!$rule) {
        return undef;
    }
    ### implicit rule: $rule->as_str
    my $retval = $self->make_by_rule($target => $rule);
    if ($retval eq 'REBUILT') {
        for my $target ($rule->other_targets) {
            $self->mark_as_updated($target);
        }
    }
    return $retval;
}

sub make_by_rule ($$$) {
    my ($self, $target, $rule) = @_;
    ### make_by_rule (target): $target
    return 'UP_TO_DATE'
        if $self->is_updated($target) and $rule->colon eq ':';
    # XXX the parent should be passed via arguments or local vars
    my $parent = $self->{parent_target};
    ## Retrieving parent target: $parent
    if (!$rule) {
        ## HERE!
        ## exists? : -f $target
        if (-f $target) {
            return 'UP_TO_DATE';
        } else {
            if ($self->is_required_target($target)) {
                my $msg =
                    "$::MAKE: *** No rule to make target `$target'";
                if (defined $parent) {
                    $msg .=
                        ", needed by `$parent'";
                }
                print STDERR "$msg.";
                if ($Makefile::AST::Runtime) {
                    die "  Stop.\n";
                } else {
                    warn "  Ignored.\n";
                    $self->mark_as_updated($target);
                    return 'UP_TO_DATE';
                }
            } else {
                return 'UP_TO_DATE';
            }
        }
    }
    ### make_by_rule (rule): $rule->as_str
    ### stem: $rule->stem

    # XXX solve pattern-specific variables here...

    # enter pads for target-specific variables:
    # XXX in order to solve '+=' and '?=',
    # XXX we actually should NOT call enter pad
    # XXX directly here...
    my $saved_stack_len = $self->ast->pad_stack_len;
    $self->ast->enter_pad($rule->target);
    ## pad stack: $self->ast->{pad_stack}->[0]

    my $target_mtime = $self->get_mtime($target);
    my $out_of_date =
        $self->ast->is_phony_target($target) ||
        !defined $target_mtime;
    my $prereq_rebuilt;
    ## Setting parent target to: $target
    $self->{parent_target} = $target;
    # process normal prereqs:
    for my $prereq (@{ $rule->normal_prereqs }) {
        # XXX handle order-only prepreqs here
        ### processing prereq: $prereq
        $self->set_required_target($prereq);
        my $res = $self->make($prereq);
        ### make returned: $res
        if ($res and $res eq 'REBUILT') {
            $out_of_date++;
            $prereq_rebuilt++;
        } elsif ($res and $res eq 'UP_TO_DATE') {
            if (!$out_of_date) {
                if ($self->get_mtime($prereq) > $target_mtime) {
                    ### prereq file is newer: $prereq
                    $out_of_date = 1;
                }
            }
        } else {
            die "make_by_rule: Unexpected returned value for prereq $prereq: $res";
        }
    }
    # process order-only prepreqs:
    for my $prereq (@{ $rule->order_prereqs }) {
        ## process order-only prereq: $prereq
        $self->set_required_target($prereq);
        $self->make($prereq);
    }
    $self->{parent_target} = undef;
    if ($AlwaysMake || $out_of_date) {
        my @ast_cmds = $rule->prepare_commands($self->ast);
        $self->call_trigger('firing_rule', $rule, \@ast_cmds);
        if (!$Question) {
            ### firing rule's commands: $rule->as_str
            $rule->run_commands(@ast_cmds);
        }
        $self->mark_as_updated($rule->target)
            if $rule->colon eq ':';
        if (my $others = $rule->other_targets) {
            # mark "other targets" as updated too:
            for my $other (@$others) {
                ### marking "other target" as updated: $other
                $self->mark_as_updated($other);
            }
        }
        $self->ast->leave_pad(
            $self->ast->pad_stack_len - $saved_stack_len
        );
        #### AST Commands: @ast_cmds
        return 'REBUILT'
            if @ast_cmds or $prereq_rebuilt;
    }
    $self->ast->leave_pad(
        $self->ast->pad_stack_len - $saved_stack_len
    );
    return 'UP_TO_DATE';
}

1;
__END__

=head1 NAME

Makefile::AST::Evaluator - Evaluator and runtime for Makefile::AST instances

=head1 SYNOPSIS

    use Makefile::AST::Evaluator;

    $Makefile::AST::Evaluator::JustPrint = 0;
    $Makefile::AST::Evaluator::Quiet = 1;
    $Makefile::AST::Evaluator::IgnoreErrors = 1;
    $Makefile::AST::Evaluator::AlwaysMake = 1;
    $Makefile::AST::Evaluator::Question = 1;

    # $ast is a Makefile::AST instance:
    my $eval = Makefile::AST::Evaluator->new($ast);

    Makefile::AST::Evaluator->add_trigger(
        firing_rule => sub {
            my ($self, $rule, $ast_cmds) = @_;
            my $target = $rule->target;
            my $colon = $rule->colon;
            my @normal_prereqs = @{ $rule->normal_prereqs };
            # ...
        }
    );
    $eval->set_required_target($user_makefile)
    $eval->make($goal);

=head1 DESCRIPTION

This module implementes an evaluator or a runtime for makefile ASTs represented by L<Makefile::AST> instances.

It "executes" the specified GNU make AST by the GNU makefile semantics. Note that, "execution" not necessarily mean building a project tree by firing makefile rule commands. Actually you can defining your own triggers by calling the L<add_trigger> method. (See the L</SYNOPSIS> for examples.) In other words, you can do more interesting things like plotting the call path tree of a Makefile using Graphviz, or translating the original makefile to another form (like what the L<makesimple> script does).

It's worth mentioning that, most of the construction algorithm for topological graph s (including implicit rule application) have already been implemented in L<Makefile::AST> and its child node classes.

=head1 CONFIGURE VARIABLES

This module provides several package variables (i.e. static class variables) for controlling the behavior of the evaluator.

Particularly the user needs to set the C<$AlwaysMake> variable to true and C<$Question> to true, if she wants to use the evaluator to do special tasks like plotting dependency graphs and translating GNU makefiles to other format.

Setting L<$AlwaysMake> to true will force the evaluator to ignore the timestamps of external files appeared in the makefiles while setting L<$Question> to true will prevent the evaluator from executing the shell commands specified in the makefile rules.

Here's the detailed listing for all the config variables:

=over

=item C<$Question>

This variable corresponds to the command-line option C<-q> or <--question> in GNU make. Its purpose is to make the evaluator enter the "questioning mode", i.e., a mode in which C<make> will never try executing rule commands unless it has to, C<and> echoing is suppressed at the same time.

=item C<$AlwaysMake>

This variable corresponds to the command-line option C<-B> or C<--always-make>. It forces re-constructing all the rule's targets related to the goal, ignoring the timestamp or existence of targets' dependencies.

=item C<$Quiet>

It corresponds to GNU make's command-line option C<-s>, C<--silent>, or C<--quiet>. Its effect is to cancel the echoing of shell commands being executed.

=item C<$JustPrint>

This variable corresponds to GNU make's command line option C<-n>, C<--just-print>, C<--dry-run>, or C<--recon>. Its effect is to print out the shell commands requiring execution but without actually executing them.

=item C<$IgnoreErrors>

This variable corresponds to GNU make's command line option C<-i> or C<--ignore-errors>. It's used to ignore the errors of shell commands being executed during the make process. The default behavior is quitting as soon as a shell command without the C<-> modifier fails.

=back

=head1 CLASS TRIGGERS

The C<make_by_rule> method of this class defines a trigger named C<firing_rule> via the L<Class::Trait> module. Everytime the C<make_by_rule> method reaches the trigger point, it will invoke the user's processing handler with the following three arguments: the self object, the L<Makefile::AST::Rule> object, and the corresponding C<Makefile::AST::Command> object in the context.

By registering his own processing handlers for the C<firing_rule> trigger, the user's code can reuse the evaluator to do his own cool things without traversing the makefile ASTs himself.

See the L</SYNOPSIS> for code examples.

=head1 CODE REPOSITORY

For the very latest version of this script, check out the source from

L<http://github.com/agentzh/makefile-parser-pm>.

There is anonymous access to all.

=head1 AUTHOR

Zhang "agentzh" Yichun C<< <agentzh@gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2008 by Zhang "agentzh" Yichun (agentzh).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Makefile::AST>, L<Makefile::Parser::GmakeDB>, L<pgmake-db>,
L<makesimple>, L<Makefile::DOM>.

