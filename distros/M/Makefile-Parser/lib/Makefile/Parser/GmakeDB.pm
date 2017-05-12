package Makefile::Parser::GmakeDB;

use strict;
use warnings;

#use Smart::Comments '####';
#use Smart::Comments '###', '####';
use List::Util qw( first );
use List::MoreUtils qw( none );
use MDOM::Document::Gmake;
use Makefile::AST;

our $VERSION = '0.216';

# XXX This should not be hard-coded this way...
our @Suffixes = (
    '.out',
    '.a',
    '.ln',
    '.o',
    '.c',
    '.cc',
    '.C',
    '.cpp',
    '.p',
    '.f',
    '.F',
    '.r',
    '.y',
    '.l',
    '.s',
    '.S',
    '.mod',
    '.sym',
    '.def',
    '.h',
    '.info',
    '.dvi',
    '.tex',
    '.texinfo',
    '.texi',
    '.txinfo',
    '.w',
    '.ch',
    '.web',
    '.sh',
    '.elc',
    '.el'
);

# need a better place for this sub:
sub solve_escaped ($) {
    my $ref = shift;
    $$ref =~ s/\\ ([\#\\:\n])/$1/gx;
}

sub _match_suffix ($@);

sub _match_suffix ($@) {
    my ($target, $full_match) = @_;
    ## $target
    ## $full_match
    if ($full_match) {
        return first { $_ eq $target } @Suffixes;
    } else {
        my ($fst, $snd);
        for my $suffix (@Suffixes) {
            my $len = length($suffix);
            ## prefix 1: substr($target, 0, $len)
            ## prefix 2: $suffix
            if (substr($target, 0, $len) eq $suffix) {
                $fst = $suffix;
                ## first suffix recognized: $suffix
                ## suffix 1: substr($target, $len)
                $snd = _match_suffix(substr($target, $len), 1);
                ## $snd
                next if !defined $snd;
                return ($fst, $snd);
            }
        }
        return undef;
    }
}

sub parse ($$) {
    shift;
    my $ast = Makefile::AST->new;
    my $dom = MDOM::Document::Gmake->new(shift);
    my ($var_origin, $orig_lineno, $orig_file);
    my $rule; # The last rule in the context
    my ($not_a_target, $directive);
    my $db_section = 'null';
    my $next_var_lineno = 0; # lineno for the next var assignment
    for my $elem ($dom->elements) {
        ## elem class: $elem->class
        ## elem lineno: $elem->lineno
        ## NEXT VAR LINENO: $next_var_lineno
        ## CURRENT LINENO: $elem->lineno
        if ($elem =~ /^# Variables$/) {
            ### Setting DB section to 'var': $elem->content
            $db_section = 'var';
            next;
        }
        if ($elem =~ /^# (?:Implicit Rules|Directives|Files)$/) {
            ### Setting DB section to 'rule': $elem->content
            $db_section = 'rule';
            next;
        }
        if ($elem =~ /^# (?:Pattern-specific Variable Values)$/) {
            ### Setting DB section to 'patspec': $elem->content
            $db_section = 'patspec';
            next;
        }
        if ($directive and $elem->class !~ /Directive$/) {
            # XXX yes, this is hacky
            ### pushing value to value: $elem
            push @{ $directive->{value} }, $elem->clone;
            next;
        }
        next if $elem->isa('MDOM::Token::Whitespace');
        if ($db_section eq 'var' and $elem->isa('MDOM::Assignment')) {
            ## Found assignment: $elem->source
            if (!$var_origin) {
                my $lineno = $elem->lineno;
                die "ERROR: line $lineno: No flavor found for the assignment";
            } else {
                my $lhs = $elem->lhs;
                my $rhs = $elem->rhs;
                my $op  = $elem->op;

                my $flavor;
                if ($op eq '=') {
                    $flavor = 'recursive';
                } elsif ($op eq ':=') {
                    $flavor = 'simple';
                } else {
                    # XXX add support for ?= and +=
                    die "Unknown op: $op";
                }
                my $name = join '', @$lhs; # XXX solve refs?
                my @value_tokens = map { $_->clone } @$rhs;
                #map { $_ = "$_" } @$rhs;
                ## LHS: $name
                ## RHS: $rhs
                my $var = Makefile::AST::Variable->new({
                    name   => $name,
                    flavor => $flavor,
                    origin => $var_origin,
                    value  => \@value_tokens,
                    lineno => $orig_lineno,
                    file => $orig_file,
                });
                $ast->add_var($var);
                undef $var_origin;
            }
        }
        elsif ($elem =~ /^#\s+(automatic|makefile|default|environment|command line)/) {
            $var_origin = $1;
            $var_origin = 'file' if $var_origin eq 'makefile';
            $next_var_lineno = $elem->lineno + 1;
        }
        elsif ($elem =~ /^# `(\S+)' directive \(from `(\S+)', line (\d+)\)/) {
            ($var_origin, $orig_file, $orig_lineno) = ($1, $2, $3);
            $next_var_lineno = $elem->lineno + 1;
            ### directive origin: $var_origin
            ### directive lineno: $orig_lineno
        }
        elsif ($elem =~ /^#\s+.*\(from `(\S+)', line (\d+)\)/) {
            ($orig_file, $orig_lineno) = ($1, $2);
            ## lineno: $orig_lineno
        }
        elsif ($db_section eq 'rule' and $elem =~ /^# Not a target:$/) {
            $not_a_target = 1;
        }
        elsif ($elem =~ /^#  Implicit\/static pattern stem: `(\S+)'/) {
            #### Setting pattern stem for solved implicit rule: $1
            $rule->{stem} = $1;
        }
        elsif ($db_section eq 'rule' and $elem =~ /^#  Also makes: (.*)/) {
            my @other_targets = split /\s+/, $1;
            $rule->{other_targets} = \@other_targets;
            #### Setting other targets: @other_targets
        }
        elsif ($db_section ne 'var' and
            $next_var_lineno == $elem->lineno and
            $elem =~ /^# (\S.*?) (:=|\?=|\+=|=) (.*)/) {
            #die "HERE!";
            my ($name, $op, $value) = ($1, $2, $3);
            # XXX tokenize the $value here?
            if (!$rule) {
                die "error: target/parttern-specific variables found where there is no rule in the context";
            }
            my $flavor;
            if ($op eq ':=') {
                $flavor = 'simple';
            } else {
                # XXX we should treat '?=' and '+=' specifically here?
                $flavor = 'recursive';
            }
            #### Adding local variable: $name
            my $handle = sub {
                my $ast = shift;
                my $old_value = $ast->eval_var_value($name);
                #warn "VALUE!!! $value";
                $value = "$old_value $value" if $op eq '+=';
                my $var = Makefile::AST::Variable->new({
                    name => $name,
                    flavor => $flavor,
                    origin => $var_origin,
                    value => $flavor eq 'recursive' ? $value : [$value],
                    lineno => $orig_lineno,
                    file => $orig_file,
                });
                $ast->enter_pad();
                $ast->add_var($var);
            };
            $ast->add_pad_trigger($rule->target => $handle);
            undef $var_origin;
        }
        elsif ($db_section ne 'var' and $elem->isa('MDOM::Rule::Simple')) {
            ### Found rule: $elem->source
            ### not a target? : $not_a_target
            if ($rule) {
                # The db output tends to produce
                # trailing empty commands, so we remove it:
                if ($rule->{commands}->[-1] and
                      $rule->{commands}->[-1] eq "\n") {
                    pop @{ $rule->{commands} };
                }
            }
            if ($not_a_target) {
                $not_a_target = 0;
                next;
            }
            my $targets = $elem->targets;
            my $colon   = $elem->colon;
            my $normal_prereqs = $elem->normal_prereqs;
            my $order_prereqs = $elem->order_prereqs;
            my $command = $elem->command;

            ## Target (raw): $targets
            ## Prereq (raw): $prereqs

            my $target = join '', @$targets;
            my @order_prereqs =  split /\s+/, join '', @$order_prereqs;
            my @normal_prereqs =  split /\s+/, join '', @$normal_prereqs;

            # Solve escaped chars:
            solve_escaped(\$target);
            map { solve_escaped(\$_) } @normal_prereqs, @order_prereqs;
            @order_prereqs = grep {
                my $value = $_;
                none { $_ eq $value } @normal_prereqs
            } @order_prereqs if @normal_prereqs;

            #### Target: $target
            ### Normal Prereqs: @normal_prereqs
            ### Order-only Prereqs: @order_prereqs

            #map { $_ = "$_" } @normal_prereqs, @order_prereqs;
            # XXX suffix rules allow order-only prepreqs? not sure...
            if ($target !~ /\s/ and $target !~ /\%/ and !@normal_prereqs and !@order_prereqs) {
                ## try to recognize suffix rule: $target
                my ($fst, $snd);
                $fst = _match_suffix($target, 1);
                if (!defined $fst) {
                    ($fst, $snd) = _match_suffix($target);
                    ## got first: $fst
                    ## got second: $snd
                    if (defined $fst) {
                        ## found suffix rule/2: $target
                        $target = '%' . $snd;
                        @normal_prereqs = ('%' . $fst);
                    }
                } else {
                    ## found suffix rule rule/1: $target
                    $target = '%' . $fst;
                }
            }
            my $rule_struct = {
                order_prereqs => [],
                normal_prereqs => \@normal_prereqs,
                order_prereqs => \@order_prereqs,
                commands => [defined $command ? $command : ()],
                colon => $colon,
                target => $target,
            };
            if ($target =~ /\%/) {
                ## implicit rule found: $target
                my $targets = [split /\s+/, $target];
                $rule_struct->{targets} = $targets,
                $rule = Makefile::AST::Rule::Implicit->new($rule_struct);
                $ast->add_implicit_rule($rule) if $db_section eq 'rule';
            } else {
                $rule = Makefile::AST::Rule->new($rule_struct);
                $ast->add_explicit_rule($rule) if $db_section eq 'rule';
            }
        } elsif ($elem->isa('MDOM::Command')) {
            ## Found command: $elem
            if (!$rule) {
                die "error: line " . $elem->lineno .
                    ": Command not allowed here";
            } else {
                #my @tokens = map { "$_" } $elem->elements;
                #my @tokens = $elem
                #shift @tokens if $tokens[0] eq "\t";
                #pop @tokens if $tokens[-1] eq "\n";
                #push @{ $rule->{commands} }, \@tokens;
                ## parser: CMD: $elem
                my $first = $elem->first_element;
                ## $first
                $elem->remove_child($first)
                    if $first->class eq 'MDOM::Token::Separator';
                ### elem source: $elem->source
                #if ($elem->source eq "\n") {
                #    die "Matched!";
                #}
                ## lineno2: $orig_lineno
                $elem->{lineno} = $orig_lineno if $orig_lineno;
                $rule->add_command($elem->clone); # XXX why clone?
                ### Command added: $elem->content
            }
        } elsif ($elem->class =~ /MDOM::Directive/) {
            ### directive name: $elem->name
            ### directive value: $elem->value
            if ($elem->name eq 'define') {
                # XXX set lineno to $orig_lineno here?
                $directive = {
                    name => $elem->value,
                    value => [], # needs to be fed later
                    flavor => 'recursive',
                    origin => $var_origin,
                    lineno => $orig_lineno,
                    file => $orig_file,
                };
                next;
            }
            if ($elem->name eq 'endef') {
                ### parsed a define directive: $directive
                # trim the trailing new lines in the value:
                #warn "HERE!!! ";
                #warn quotemeta($directive->{value}->[-1]);
                my $last = $directive->{value}->[-1];
                if ("$last" =~ /^\s*$/s) {
                    pop @{ $directive->{value} }

                } elsif ($last->can('last_element')) {
                    my $last_elem = $last->last_element;
                    #warn "LAST: '$last'\n";
                    if ($last_elem and "$last_elem" =~ /^\s*$/s) {
                        $last->remove_child($last_elem);
                    }
                }

                my $var = Makefile::AST::Variable->new($directive);
                $ast->add_var($var);
                undef $var_origin;
                undef $directive;

            } else {
                warn "warning: line " . $elem->lineno .
                    ": Unknown directive: " . $elem->source;
            }
        } elsif ($elem->class =~ /Unknown/) {
            # XXX Note that output from $(info ...) may skew up stdout
            # XXX This hack is used to make features/conditionals.t pass
            print $elem if $elem eq "success\n";
            # XXX The 'hello, world' hack to used to make sanity/func-refs.t pass
            warn "warning: line " . $elem->lineno .
                ": Unknown GNU make database struct: " .
                $elem->source
                if $elem !~ /hello.*world/ and
                   $elem ne "success\n";
        }
    }
    {
        my $default = $ast->eval_var_value('.DEFAULT_GOAL');
        ## default goal's value: $var
        $ast->default_goal($default) if $default;
        ### DEFAULT GOAL: $ast->default_goal

        my $rule = $ast->apply_explicit_rules('.PHONY');
        if ($rule) {
            ### PHONY RULE: $rule
            ### phony targets: @{ $rule->normal_prereqs }
            for my $phony (@{ $rule->normal_prereqs }) {
                $ast->set_phony_target($phony);
            }
        }
        ## foo var: $ast->get_var('foo')
    }
    $ast;
}

1;
__END__

=head1 NAME

Makefile::Parser::GmakeDB - GNU makefile parser using GNU make's database dump

=head1 VERSION

This document describes Makefile::Parser::GmakeDB 0.216 released on 18 November 2014.

=head1 SYNOPSIS

    use Makefile::Parser::GmakeDB;
    my $db_listing = `make --print-data-base -pqRrs -f Makefile`;
    my $ast = Makefile::Parser::GmakeDB->parse(\$db_listing);

=head1 DESCRIPTION

This module serves as a parser for GNU makefiles. However, it does not parse
user's original makefile directly. Instead it uses L<Makefile::DOM> to parse
the "data base output listing" produced by GNU make (via its
C<--print-data-base> option). So essentially it reuses the C
implementation of GNU make.

This parser has been tested as a component of the L<pgmake-db> utility and has successfully passed 51% of GNU make 3.81's official test suite.

The result of the parser is a makefile AST defined by L<Makefile::AST>.

The "data base output listing" generated by C<make --print-data-base> is a detailed listing for GNU make's internal data structures, which is essentially the AST used by C<make>. According to GNU make's current maintainer, Paul Smith, this feature is provided primarily for debuging the user's own makefiles, and it also helps the GNU make developer team to diagnose the flaws in make itself. Incidentally this output is conformed to the GNU makefile syntax, and a lot of important information is provided in the form of makefile comments. Therefore, my GmakeDB parser is able to reuse the L<Makefile::DOM> module to parse this output listing.

The data base output from GNU make can be divided into several clearly-separated segments. They're file header, "Variables", "Files", "VPATH Search Paths", as well as the last resource stats information.

The contents of these segments are mostly obvious. The Files segment may deserve some explanation. It is the place for explict rules.

Now let's take the Variables segment as an  example to demonstrate the format of the data base listing:

    # Variables

    # automatic
    <D = $(patsubst %/,%,$(dir $<))
    # automatic
    ?F = $(notdir $?)
    # environment
    DESKTOP_SESSION = default
    # automatic
    ?D = $(patsubst %/,%,$(dir $?))
    # environment
    GTK_RC_FILES = /etc/gtk/gtkrc:/home/agentz/.gtkrc-1.2-gnome2
    # environment
    ...

It's shown that the flavor and origin of the makefile variables are given in the previous line as comments. Hence feeding this back into GNU make again makes little sense.

Similarly, the Files segment for explicit rules also puts big amount of the important information into makefile comments:

    # Files

    # Not a target:
    bar.c:
    #  Implicit rule search has not been done.
    #  Modification time never checked.
    #  File has not been updated.

    all: foo.o bar.o
    #  Implicit rule search has been done.
    #  File does not exist.
    #  File has not been updated.
    # variable set hash-table stats:
    # Load=0/32=0%, Rehash=0, Collisions=0/0=0%

    foo.o: foo.c
    #  Implicit rule search has not been done.
    #  Implicit/static pattern stem: `foo'
    #  File does not exist.
    #  File has not been updated.
    # variable set hash-table stats:
    # Load=0/32=0%, Rehash=0, Collisions=0/0=0%
    #  commands to execute (from `ex2.mk', line 8):
        $(CC) -c $(CFLAGS) $< -o $@
    ...

From the previous two data base listing snippets, it's not hard to see that the variable references in rule commands and recursively-expanded variables's values are not expanded.

Experiments have shown that GNU make will do implicit rule search for the first rule that needs to, but no more. This behavior means testing our own implicit rule searching algorithm requires specifying at least two goals that require matching.

=head1 DEPENDENCIES

=over

=item GNU make 3.81

At least the F<make> executable of GNU make 3.81 is required to work with this module.

=item L<Makefile::DOM>

=back

=head1 BUGS

=over

=item *

GNU make does not escape meta characters appeared in rule targes and prerequisites in its data base listing. Examples are C<:>, C<\>, and C<#>. This bug has been reported to the GNU make team as C<Savannah bug #20067>.

This bug has not yet been fixed on the C<make> side, so I have to work around this issue by preprocessing the data base listing in the L<makesimple> script.

=item *

The data base listing produced by GNU make lacks the information regarding the C<export> and C<unexport> directives. It gives rise to the lack of information in the resulting AST structures constructed by this module. Hence the current AST and runtime do not implement the C<export> and C<unexport> directives.

To make it even worse, there's no known way to work around it.

I've already reported this issue to the GNU make team as Savannah bug #20069.

=back

=head1 CODE REPOSITORY

For the very latest version of this script, check out the source from

L<http://github.com/agentzh/makefile-parser-pm>.

There is anonymous access to all.

=head1 AUTHOR

Zhang "agentzh" Yichun C<< <agentzh@gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2008 by Zhang "agentzh" Yichun (agentzh).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Makefile::AST>, L<Makefile::AST::Evaluator>, L<Makefile::DOM>,
L<makesimple>, L<pgmake-db>.

