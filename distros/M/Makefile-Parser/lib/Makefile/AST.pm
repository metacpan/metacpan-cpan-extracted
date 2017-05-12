package Makefile::AST;

use strict;
use warnings;

our $VERSION = '0.216';

#use Smart::Comments;
#use Smart::Comments '####';

use Makefile::AST::StemMatch;
use Makefile::AST::Rule::Implicit;
use Makefile::AST::Rule;
use Makefile::AST::Variable;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_ro_accessors(qw{
    phony_targets targets prereqs makefile
    pad_stack named_pads pad_triggers
});

__PACKAGE__->mk_accessors(qw{
    default_goal
});

use List::Util 'first';
use List::MoreUtils qw( uniq pairwise ) ;
use Cwd qw/ realpath /;
use File::Spec;
use MDOM::Util 'trim_tokens';
use MDOM::Document::Gmake;

# XXX better name?
our $Runtime = undef;

sub new ($@) {
    my $class = ref $_[0] ? ref shift : shift;
    my $makefile = shift;
    return bless {
        explicit_rules => {},
        implicit_rules => [],
        pad_stack => [{}], # the last scope is
                           # the default GLOBAL
                           #  scope
        named_pads   => {}, # hooks for target-specific
                            # variables
        pad_triggers => {},
        targets => {},
        prereqs => {},
        phony_targets => {},
        makefile       => $makefile,
    }, $class;
}

sub is_phony_target ($$) {
    my ($self, $target) = @_;
    $self->phony_targets->{$target};
}

sub set_phony_target ($$) {
    my ($self, $target) = @_;
    $self->phony_targets->{$target} = 1;
}

sub target_exists ($$) {
    my $self = shift;
    # XXX provide hooks for mocking file systems
    # XXX access the mtime cache instead in the future
    my $target = shift;
    #### Test if target exists: $target
    #### Result: -e $target
    return -e $target;
}

sub target_ought_to_exist ($$) {
    my ($self, $target) = @_;
    my $res = $self->targets->{$target} ||
        $self->prereqs->{$target};
    ### Test if $target ought to exist: $res
    $res;
}

sub apply_explicit_rules ($$) {
    my ($self, $target) = @_;
    my $list = $self->{explicit_rules}->{$target} || [];
    wantarray ? @$list : $list->[0];
}

sub get_var ($$) {
    my ($self, $name) = @_;
    my $pads = $self->pad_stack;
    for my $pad (@$pads) {
        if (my $var = $pad->{$name}) {
            return $var;
        }
    }
    return undef;
}

# XXX sub find_var
# find_var(name => $name, flavor => $flavor)

# enter the pad for a lexical scope
sub enter_pad ($@) {
    my ($self, $name) = @_;
    #### Entering pad named: $name
    my $stack = $self->pad_stack;
    my $pad;
    if (defined $name) {
        $pad =
            $self->named_pads->{$name} ||= {};
    } else {
        $pad = {};
    }
    unshift @$stack, $pad;
    if (defined $name) {
        my $list = $self->pad_triggers->{$name};
        if ($list) {
            for my $trigger (@$list) {
                #### Firing pad trigger for: $name
                $trigger->($self);
            }
        }
    }
}

sub leave_pad ($@) {
    my ($self, $count) = @_;
    #### Leaving pad...
    my $stack = $self->pad_stack;
    $count = 1 if !defined $count;
    for (1..$count) {
        shift @$stack if @$stack > 1;
    }
}

sub pad_stack_len ($) {
    scalar(@{ $_[0]->pad_stack });
}

sub add_pad_trigger ($$$) {
    my ($self, $name, $sub) = @_;
    my $list = $self->pad_triggers->{$name} ||= [];
    push @$list, $sub;
}

sub add_var ($$) {
    my ($self, $var) = @_;
    # XXX variable overridding check
    ## variable name: $var->name()
    if (!ref $var->value) {
        $var->value(
            [MDOM::Document::Gmake::_tokenize_command(
                $var->value
            )]
        );
    }
    $self->pad_stack->[0]->{$var->name()} = $var;
}

sub add_auto_var ($$$@) {
    my $self = shift;
    my %pairs = @_;
    while (my ($name, $value) = each %pairs) {
        my $var = Makefile::AST::Variable->new(
          { name   => $name,
            flavor => 'simple',
            origin => 'automatic',
            value  => $value,
          }
        );
        $self->add_var($var);
    }
}

sub explicit_rules ($) {
    my $self = shift;
    my @items = values %{ $self->{explicit_rules} };
    my @rules = map { @$_ } @items;
    \@rules;
}


sub implicit_rules ($) {
    $_[0]->{implicit_rules};
}

sub add_explicit_rule ($$) {
    my ($self, $rule) = @_;
    if (!defined $self->default_goal) {
        my $target = $rule->target;
        ### check if it's the default target: $target
        # XXX skip the makefile itself
        if ($target !~ m{^\./Makefile_\S+} and (substr($target, 0, 1) ne '.' or $target =~ m{/})) {
            $self->default_goal($target);
        }
    }
    if ($rule->colon eq ':') {
        # XXX check single colon rules for conflicts
        # XXX merge prereqs if no cmd given
        $self->{explicit_rules}->{$rule->target} =
            [$rule];
    } else {
        # XXX check double colon rules for conflicts
        my $list =
            $self->{explicit_rules}->{$rule->target} ||=
            [];
        # XXX check if $list is an ARRAY ref
        push @$list, $rule;
    }
    for my $prereq (@{$rule->normal_prereqs}, @{$rule->order_prereqs}) {
        $self->prereqs->{$prereq} = 1;
    }
    $self->targets->{$rule->target} = 1;
}

sub add_implicit_rule ($$) {
    my ($self, $rule) = @_;
    # XXX cancel a built-in implicit rule by defining
    # a pattern rule with the same target and
    # prerequisites, but no commands
    for my $target (@{ $rule->targets }) {
        # XXX better pattern recognition
        next if $target =~ /\%/;
        $self->targets->{$target} = 1;
    }
    for my $prereq (@{$rule->normal_prereqs}, @{$rule->order_prereqs}) {
        next if $prereq =~ /\%/;
        $self->prereqs->{$prereq} = 1;
    }
    my $list = $self->{implicit_rules};
    unshift @$list, $rule;
}

# implementation for the implicit rule search
# algorithm
sub apply_implicit_rules ($$) {
    my ($self, $target) = @_;

    # XXX handle archive(member) here

    #### step 2...
    my @rules = grep { $_->match_target($target) }
                     @{ $self->implicit_rules };
    #### rules: map { $_->as_str } @rules
    return undef if !@rules;

    #### step 3...
    if (first { ! $_->match_anything } @rules) {
        @rules = grep {
            !( $_->match_anything && !$_->is_terminal )
        } @rules;
    }
    #### rules: map { $_->as_str } @rules

    #### step 4...
    @rules = grep { @{ $_->commands } > 0 } @rules;
    #### rules: map { $_->as_str } @rules

    #### step 5...
    # XXX This is hacky...not sure if it's the right
    # XXX thing to do (it's unspec'd afaik)
    @rules = sort {
        -( scalar( @{ $a->normal_prereqs } ) <=>
        scalar( @{ $b->normal_prereqs } ) )
    } @rules;
    for my $rule (@rules) {
        #### target: $target
        #### rule: $rule->as_str
        #### file test: -e 'bar.hpp'
        my $applied = $rule->apply($self, $target);
        if ($applied) {
            #### applied rule: $applied->as_str
            return $applied;
        }
    }

    ### step 6...
    for my $rule (@rules) {
        next if $rule->is_terminal;
        #### applying the implicit rule recursively
        my $applied = $rule->apply(
            $self, $target,
            { recursive => 1 });
        if ($applied) {
            return $applied;
        }
        #### Failed to apply the rule recursively
    }

    ### step 7...
    my $applied = $self->apply_explicit_rules('.DEFAULT');
    if ($applied) {
        $applied->target($target);
        return $applied;
    }
    return undef;
}

sub _pat2re ($@) {
    my ($pat, $capture) = @_;
    $pat = quotemeta $pat;
    if ($capture) {
        $pat =~ s/\\\%/(\\S*)/g;
    } else {
        $pat =~ s/\\\%/\\S*/g;
    }
    $pat;
}

sub _split_args($$$$) {
    my ($self, $func, $s, $m, $n) = @_;
    $n ||= $m;
    my @tokens = '';
    my @args;
    ### $n
    while (@args <= $n) {
        ### split args: @args
        ### split tokens: @tokens
        if ($s =~ /\G\s+/gc) {
            push @tokens, $&, '';
        }
        elsif ($s =~ /\G[^\$,]+/gc) {
            $tokens[-1] .= $&;
        }
        elsif ($s =~ /\G,/gc) {
            if (@args < $n - 1) {
                push @args, [grep { $_ ne '' } @tokens];
                @tokens = '';
            } else {
                $tokens[-1] .= $&;
            }
        }
        elsif (my $res = MDOM::Document::Gmake::extract_interp($s)) {
            #die $res;
            push @tokens, MDOM::Token::Interpolation->new($res), '';
        }
        elsif ($s =~ /\G\$./gc) {
            push @tokens, MDOM::Token::Interpolation->new($&), '';
        }
        elsif ($s =~ /\G./gc) {
            $tokens[-1] .= $&;
        }
        else {
            if (@args <= $n - 1) {
                push @args, [grep { $_ ne '' } @tokens];
            }
            last if @args >= $m and @args <= $n;
            warn $self->makefile, ":$.: ",
            "*** insufficient number of arguments (",
            scalar(@args), ") to function `$func'.  Stop.\n";
            exit(2);
        }
    }
    return @args;
}

sub eval_var_value ($$) {
    my ($self, $name) = @_;
    if (my $var = $self->get_var($name)) {
        ### eval_var_value: $var
        if ($var->flavor eq 'recursive') {
            ## HERE! eval_var_value
            ## eval recursive var: $var
            my $val =  $self->solve_refs_in_tokens(
                $var->value
            );
            $val =~ s/^\s+|\s+$//gs;
            #warn "value: $val\n";
            return $val;
        } else {
            # don't complain about uninitialized value:
            no warnings 'uninitialized';
            my $val = join '', @{$var->value};
            $val =~ s/^\s+|\s+$//gs;
            return $val;
        }
    } else {
        # process undefined var:
        return '';
    }
}

sub _text2words ($) {
    my ($text) = @_;
    $text =~ s/^\s+|\s+$//g;
    split /\s+/, $text;
}

sub _check_numeric ($$$$) {
    my ($self, $func, $order, $n) = @_;
    if ($n !~ /^\d+$/) {
        warn $self->makefile, ":$.: ",
            "*** non-numeric $order argument to `$func' function: '$n'.  Stop.\n";
        exit(2);
    }
}

sub _check_greater_than ($$$$$) {
    my ($self, $func, $order, $n, $value) = @_;
    if ($n <= $value) {
        warn $self->makefile, ":$.: *** $order argument to `$func' function must be greater than $value.  Stop.\n";
        exit(2);
   }
}

sub _trim ($@) {
    for (@_) {
        s/^\s+|\s+$//g;
    }
}

sub _process_func_ref ($$$) {
    my ($self, $name, $args) = @_;
    ### process func ref: $name
    # XXX $name = $self->_process_refs($name);
    my @args;
    my $nargs = scalar(@args);
    if ($name eq 'subst') {
        my @args = $self->_split_args($name, $args, 3);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        ### arguments: @args
        my ($from, $to, $text) = @args;
        $from = quotemeta($from);
        $text =~ s/$from/$to/g;
        return $text;
    }
    if ($name eq 'patsubst') {
        my @args = $self->_split_args($name, $args, 3);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($pattern, $replacement, $text) = @args;
        my $re = _pat2re($pattern, 1);
        $replacement =~ s/\%/\${1}/g;
        $replacement = qq("$replacement");
        #### pattern: $re
        #### replacement: $replacement
        #### text: $text
        my $code = "s/^$re\$/$replacement/e";
        #### code: $code
        my @words = _text2words($text);
        map { eval $code; } @words;
        return join ' ', grep { $_ ne '' } @words;
    }
    if ($name eq 'strip') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($string) = @args;
        $string =~ s/^\s+|\s+$//g;
        $string =~ s/\s+/ /g;
        return $string;
    }
    if ($name eq 'findstring') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($find, $in) = @args;
        if (index($in, $find) >= 0) {
            return $find;
        } else {
            return '';
        }
        my ($patterns, $text) = @args;
        my @regexes = map { _pat2re($_) }
            split /\s+/, $patterns;
        ## regexes: @regexes
        my $regex = join '|', map { "(?:$_)" } @regexes;
        ## regex: $regex
        my @words = _text2words($text);
        return join ' ', grep /^$regex$/, @words;

    }
    if ($name eq 'filter') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($patterns, $text) = @args;
        my @regexes = map { _pat2re($_) }
            split /\s+/, $patterns;
        ## regexes: @regexes
        my $regex = join '|', map { "(?:$_)" } @regexes;
        ## regex: $regex
        my @words = _text2words($text);
        return join ' ', grep /^$regex$/, @words;
    }
    if ($name eq 'filter-out') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($patterns, $text) = @args;
        my @regexes = map { _pat2re($_) }
            split /\s+/, $patterns;
        ## regexes: @regexes
        my $regex = join '|', map { "(?:$_)" } @regexes;
        ## regex: $regex
        my @words = _text2words($text);
        return join ' ', grep !/^$regex$/, @words;
    }
    if ($name eq 'sort') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($list) = @args;
        _trim($list);
        return join ' ', uniq sort split /\s+/, $list;
    }
    if ($name eq 'words') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @words = _text2words($text);
        return scalar(@words);
    }
    if ($name eq 'word') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($n, $text) = @args;
        _trim($n);
        $self->_check_numeric('word', 'first', $n);
        $self->_check_greater_than('word', 'first', $n, 0);
        my @words = _text2words($text);
        return $n > @words ? '' : $words[$n - 1];
    }
    if ($name eq 'wordlist') {
        my @args = $self->_split_args($name, $args, 3);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($s, $e, $text) = @args;
        _trim($s, $e, $text);
        $self->_check_numeric('wordlist', 'first', $s);
        $self->_check_numeric('wordlist', 'second', $e);
        $self->_check_greater_than('wordlist', 'first', $s, 0);
        $self->_check_greater_than('wordlist', 'second', $s, -1);
        my @words = _text2words($text);
        if ($s > $e || $s > @words || $e == 0) {
            return '';
        }
        $e = @words if $e > @words;
        return join ' ', @words[$s-1..$e-1];
    }
    if ($name eq 'firstword') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @words = _text2words($text);
        return @words > 0 ? $words[0] : '';
    }
    if ($name eq 'lastword') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @words = _text2words($text);
        return @words > 0 ? $words[-1] : '';
    }
    if ($name eq 'dir') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        return join ' ', map { /.*\// ? $& : './' } @names;
    }
    if ($name eq 'notdir') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        return join ' ', map { s/.*\///; $_ } @names;
    }
    if ($name eq 'suffix') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        my $s = join ' ', map { /.*(\..*)/ ? $1 : '' } @names;
        $s =~ s/\s+$//g;
        return $s;
    }
    if ($name eq 'basename') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        my $s = join ' ', map { /(.*)\./ ? $1 : $_ } @names;
        $s =~ s/\s+$//g;
        return $s;
    }
    if ($name eq 'addsuffix') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($suffix, $text) = @args;
        #_trim($suffix);
        my @names = _text2words($text);
        return join ' ', map { $_ . $suffix } @names;
    }
    if ($name eq 'addprefix') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($suffix, $text) = @args;
        #_trim($suffix);
        my @names = _text2words($text);
        return join ' ', map { $suffix . $_ } @names;
    }
    if ($name eq 'join') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($list_1, $list_2) = @args;
        my @list_1 = _text2words($list_1);
        my @list_2 = _text2words($list_2);
        return join ' ', pairwise {
            no warnings 'uninitialized';
            $a . $b
        } @list_1, @list_2;
    }
    if ($name eq 'wildcard') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($pattern) = @args;
        return join ' ', grep { -e $_ } glob $pattern;
    }
    if ($name eq 'realpath') {
        no warnings 'uninitialized';
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        return join ' ', map { realpath($_) } @names;
    }
    if ($name eq 'abspath') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        my @paths = map { File::Spec->rel2abs($_) } @names;
        for my $path (@paths) {
            my @f = split '/', $path;
            my @new_f;
            for (@f) {
                if ($_ eq '..') {
                    pop @new_f;
                } else {
                    push @new_f, $_;
                }
            }
            $path = join '/', @new_f;
        }
        return join ' ', @paths;
    }
    if ($name eq 'shell') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($cmd) = @args;
        my $output = `$cmd`;
        $output =~ s/(?:\r?\n)+$//g;
        $output =~ s/\r?\n/ /g;
        return $output;
    }
    if ($name eq 'if') {
        my @args = $self->_split_args($name, $args, 2, 3);
        #map { $_ = $self->solve_refs_in_tokens($_) } @args;
        my ($condition, $then_part, $else_part) = @args;
        trim_tokens($condition);
        $condition = $self->solve_refs_in_tokens($condition);
        return $condition eq '' ?
                    $self->solve_refs_in_tokens($else_part)
               :
                    $self->solve_refs_in_tokens($then_part);
    }
    if ($name eq 'or') {
        my @args = $self->_split_args($name, $args, 1, 1000_000_000);
        #map { $_ = $self->solve_refs_in_tokens($_) } @args;
        for my $arg (@args) {
            trim_tokens($arg);
            my $value = $self->solve_refs_in_tokens($arg);
            return $value if $value ne '';
        }
        return '';
    }
    if ($name eq 'and') {
        my @args = $self->_split_args($name, $args, 1, 1000_000_000);
        #map { $_ = $self->solve_refs_in_tokens($_) } @args;
        ## arguments for 'and': @args
        my $value;
        for my $arg (@args) {
            trim_tokens($arg);
            $value = $self->solve_refs_in_tokens($arg);
            return '' if $value eq '';
        }
        return $value;
    }
    if ($name eq 'foreach') {
        my @args = $self->_split_args($name, $args, 3);
        my ($var, $list, $text) = @args;
        $var = $self->solve_refs_in_tokens($var);
        $list = $self->solve_refs_in_tokens($list);
        my @words = _text2words($list);
        # save the original status of $var
        my $rvars = $self->{_vars};
        my $not_exist = !exists $rvars->{$var};
        my $old_val = $rvars->{$var};

        my @results;
        for my $word (@words) {
            $rvars->{$var} = $word;
            #warn "$word";
            push @results, $self->solve_refs_in_tokens($text);
        }

        # restore the original status of $var
        if ($not_exist) {
            delete $rvars->{$var};
        } else {
            $rvars->{$var} = $old_val;
        }

        return join ' ', @results;
    }
    if ($name eq 'error') {
        my ($text) = $self->_split_args($name, $args, 1);
        $text = $self->solve_refs_in_tokens($text);
        warn $self->makefile, ":$.: *** $text.  Stop.\n";
        exit(2) if $Runtime;
        return '';
    }
    if ($name eq 'warning') {
        my ($text) = $self->_split_args($name, $args, 1);
        $text = $self->solve_refs_in_tokens($text);
        warn $self->makefile, ":$.: $text\n";
        return '';
    }
    if ($name eq 'info') {
        my ($text) = $self->_split_args($name, $args, 1);
        $text = $self->solve_refs_in_tokens($text);
        print "$text\n";
        return '';
    }

    return undef;
}

sub solve_refs_in_tokens ($$) {
    my ($self, $tokens) = @_;
    return '' if !$tokens;
    my @new_tokens;
    for my $token (@$tokens) {
        if (!ref $token or !$token->isa('MDOM::Token::Interpolation')) {
            ### solve_refs: non-var-ref token: $token
            push @new_tokens, $token;
            next;
        }
        if ($token =~ /^\$[{(](.*)[)}]$/) {
            my $s = $1;
            if ($s =~ /^([-\w]+)\s+(.*)$/) {
                my $res = $self->_process_func_ref($1, $2);
                if (defined $res) {
                    push @new_tokens, $res;
                    next;
                }
            } elsif ($s =~ /^(\S+?):(\S+?)=(\S+)$/) {
                my ($var, $from, $to) = ($1, $2, $3);
                my $res = $self->_process_func_ref(
                    'patsubst', "\%$from,\%$to,\$($var)"
                );
                if (defined $res) {
                    push @new_tokens, $res;
                    next;
                }
            }
            ### found variable reference: $1
            ### evaluating variable : $s
            push @new_tokens, $self->eval_var_value($s);
            next;
        } elsif ($token =~ /^\$\$$/) {
            push @new_tokens, '$';
            next;
        } elsif ($token =~ /^\$(.)$/) {
            push @new_tokens, $self->eval_var_value($1);
            next;
        }
        push @new_tokens, $token;
    }
    ### solving results: join '', @new_tokens
    return join '', @new_tokens;
}

1;
__END__

=head1 NAME

Makefile::AST - AST for (GNU) makefiles

=head1 DESCRIPTION

The structure of this (GNU) makefile AST is designed based on GNU make's data base listing output produced by C<--print-data-base>.

This AST library provides the following classes:

=over

=item Makefile::AST

The primary class for ASTs. Provides interface for node adding and querying, such as C<add_implicit_rule>, C<apply_implicit_rules>, C<add_explicit_rule>, C<apply_explicit_rules>, C<add_var>, C<add_auto_var>, C<get_var>, as well as lots of other utility functions, like method C<eval_var_value> for computing the ultimate values of makefile variables, method C<enter_pad> and C<leave_pad> for local variable's scoping pad.

=item L<Makefile::AST::Rule::Base>

This is the base class for the rule nodes in the AST. It has properties like C<normal_prereqs>, C<order_prereqs>, C<commands>, and C<colon>.

=item L<Makefile::AST::Rule>

This class represents the de-sugared form of simple rules and implicite rules I<after> application. It inherits from L<Makefile::AST::Rule::Base>, and adds new properties C<target> and C<other_targets>.

=item L<Makefile::AST::Rule::Implicit>

This class represents the implicit rule nodes in the AST. It inherits from L<Makefile::AST::Rule::Base>, and adds new properties C<targets>, C<match_anything>, and C<is_terminal>.

=item L<Makefile::AST::StemMatch>

This class encapsulates the file pattern matching (file names containing C<%>) and stem substitution algorithms.

=item L<Makefile::AST::Variable>

It represents the makefile variable nodes in the AST, including C<name>, C<value>, C<flavor>, and C<origin>.

=item L<Makefile::AST::Command>

Used to encapsulate information regarding makefile rule commands (e.g. command body, command modifiers C<@>, C<->, C<+>, and etc.) as a whole.

=back

=head1 LIMITATIONS AND TODO

Adding support for other flavors' makes into this AST library should make a huge amount of sense. The most interesting candiate is Microsoft's NMAKE.

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

L<Makefile::AST::Evaluator>, L<Makefile::Parser::GmakeDB>,
L<makesimple>, L<pgmake-db>, L<Makefile::DOM>.

