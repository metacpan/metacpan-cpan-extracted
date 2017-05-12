# $Id: LL.pm,v 1.17 2007/07/13 00:00:13 ask Exp $
# $Source: /opt/CVS/Getopt-LL/lib/Getopt/LL.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.17 $
# $Date: 2007/07/13 00:00:13 $
package Getopt::LL;
use strict;
use warnings;
use Carp qw(croak);
use Getopt::LL::DLList;
use English qw($PROGRAM_NAME);
use version qw(qv); our $VERSION = qv('1.0.0');
use 5.006_001;
{


    use Getopt::LL::SimpleExporter qw(getoptions opt_String opt_Digit opt_Flag);

    use Class::Dot 1.0 qw( property isa_Hash isa_Array isa_Object );

    #========================================================================
    #                           - CLASS PROPERTIES -
    #========================================================================
    property    rules       => isa_Hash;
    property    aliases     => isa_Hash;
    property    options     => isa_Hash;
    property    help        => isa_Hash;
    property    result      => isa_Hash;
    property    leftovers   => isa_Array;
    property    dll         => isa_Object('Getopt::LL::DLList');

    my $RE_SHORT_ARGUMENT = qr{
            \A          # starts with...
            -           # single dash.
            (?!-)       # with no dash after that.
            .
    }xms;

    my $RE_LONG_ARGUMENT = qr{
            \A          # starts with...
            -- [^-]?    # two dashes.
            (?!-)       # with no dash after that.
            .
    }xms;

    my $RE_ASSIGNMENT = qr{
            (?<! \\ )   # equal sign that does not have backslash 
            =           # in front of it.
    }xms;

    my %TYPE_CHECK = (
        digit       => \&is_digit,
        string      => \&is_string,
    );

    my %RULE_ACTION = (
        digit       => \&get_next_arg,
        string      => \&get_next_arg,
        flag        => sub {
            return 1;
        },
    );

    my %DEFAULT_OPTIONS = (
        allow_unspecified    => 0,
        die_on_type_mismatch => 0,
        silent               => 0,
        end_on_dashdash      => 0,
        split_multiple_shorts => 0,
        style                => 'default',
        long_option          => 'flag',
        short_option         => 'string',
    );

    my %DEFAULT_OPTIONS_GNU = (

        # GNU-style arguments ends argument processing on empty '--'
        end_on_dashdash      => 1,
        split_multiple_shorts => 1,
    );

    my $EXIT_FAILURE = 1;

    # When set to true, parseopts stop processing options.
    my $end_processing;

    #========================================================================
    #                            - CONSTRUCTOR -
    #========================================================================
    sub new {
        my ($class, $rules_ref, $options_ref, $argv_ref) = @_;
        $argv_ref         ||= \@ARGV;

        my $self = {};
        bless $self, $class;

        # If there are no rules, we must allowed unspecified
        # arguments. (also check if we a have a reference to an empty hash).
        if (!$rules_ref  || (ref $rules_ref && !scalar keys %{$rules_ref})) {
            $options_ref->{allow_unspecified} = 1;
        }

        while (my ($option, $default_value) = each %DEFAULT_OPTIONS) {
            if (!defined $options_ref->{$option}) {
                $options_ref->{$option} = $default_value;
            }
        }
        if ($options_ref->{style} eq 'GNU') {
            while (my ($option, $value) = each %DEFAULT_OPTIONS_GNU) {
                $options_ref->{$option} = $value;
            }
        }

        $self->set_options($options_ref);
        $self->rules_prepare($rules_ref);

        if (scalar @{ $argv_ref }) {
            $self->set_dll( Getopt::LL::DLList->new($argv_ref) );
            $self->_init();
        }

        $self->rules_postactions( );

        return $self;
    }

    #========================================================================
    #                           - INSTANCE METHODS -
    #========================================================================

    sub _init {
        my ($self) = @_;
        my $dll    = $self->dll;

        $end_processing = 0;
        $dll->traverse($self, 'parseoption');

        return $self->result;
    }

    sub rules_prepare {
        my ($self, $rules_ref) = @_;
        my $options_ref        = $self->options;
        my $help_ref           = $self->help;

        my %final_rules = ();
        my %aliases     = ();

    RULE:
        while (my ($rule_name, $rule_spec) = each %{$rules_ref}) {

            # User can type:
            #   '-arg'  => 'string',
            # instead of:
            #   '-arg'  => { type => 'string' }
            # and we will convert it here.
            if (ref $rule_spec ne 'HASH') {
                $rule_spec = {type => $rule_spec};
            }

            # If the rule has a help field; save it into help.
            if ($rule_spec->{help}) {
                $help_ref->{$rule_name} = $rule_spec->{help};
            }
            
            my($rule_name_final, @aliases)
                = split m/\|/xms, $rule_name;

# Split out the aliases (which are delimited by |)

            # Aliases can also be inside the spec, like this:
            #   '-arg' => { alias => '-gra' };
            # or a list of aliases:
            #   '-arg' => { alias => ['-gra', '-rag', '-rga'] };
            #  
            my $aliases_inside_spec   = $rule_spec->{alias};
            if ($aliases_inside_spec) {
                @aliases =
                    ref $aliases_inside_spec eq 'ARRAY'
                        ? (@aliases, @{$aliases_inside_spec})
                        : (@aliases, $aliases_inside_spec);
            }

            # if the name of the rule ends with !, remove the !
            # and set it as required.
            if ($rule_name_final =~ s/!\z//xms) {
                $rule_spec->{required} = 1;
            }

            # a default value can be defined inside parentheses.
            # i.e:
            #       '-arg(defaultValue)' => 'string';
            if ($rule_name_final =~ s/\( (.+?) \)//xms) {
                $rule_spec->{default}  = $1;
            }

            # Remove leading and trailing whitespace.
            $rule_name_final =~ s/\A \s+   //xms;
            $rule_name_final =~ s/   \s+ \z//xms;

            # Save the final version of the rule.
            $final_rules{$rule_name_final} = $rule_spec;

            # Save aliases to this rule.
            for my $alias (@aliases) {
                $aliases{$alias} = $rule_name_final;
            }
            
        }

        $self->set_aliases( \%aliases     );
        $self->set_rules(   \%final_rules );

        return;
    }

    sub rules_postactions {
        my ($self)     = @_;
        my $rules_ref  = $self->rules;
        my $result     = $self->result;

        while (my ($rule_name, $rule_spec) = each %{ $rules_ref }) {

            # Die if this is a required argument that we don't have.
            if ($rule_spec->{required} && !$result->{$rule_name}) {
                die "Missing required argument: $rule_name\n";
            }

            # Set this argument to the default if it doesn't exist
            # and a default value for this rule exists.
            if ($rule_spec->{default}  && !$result->{$rule_name}) {
                $result->{$rule_name}  =   $rule_spec->{default};
            }
        }

        return;
    }
    sub parseoption {
        my ($self, $argument, $node) = @_;
        my $result_argv = $self->result;
        my $leftovers   = $self->leftovers;
        my $rules       = $self->rules;
        my $options_ref = $self->options;
        my $aliases     = $self->aliases;

        my $is_arg_of_type = $self->find_arg_type($argument);

       # We stop processing options if this is a naked long option, ( '^--$' )
       # and the 'end_on_dashdash' option is set.
        if ($argument eq q{--} && $options_ref->{end_on_dashdash}) {
            $end_processing++;
        }

        # if find_arg_type said we have a special argument, start processing
        # it (as long as processing is not stopped).
        elsif ($is_arg_of_type && !$end_processing) {

            my @arguments = ($argument);

            if ($is_arg_of_type eq 'short' && $options_ref->{split_multiple_shorts}) {
                $argument =~ s/^-//xms;
                @arguments = map { "-$_" } split m//xms, $argument;
            };


            for my $argument (@arguments) {
                my $argument_name  = $argument;
                my $argument_value = q{};

                # ###
                # case: --argument_name=value
                # if argument name contains an equal sign, the value is embedded in the
                # argument. an example of inline assignement could be:
                #   --input-filename=/Users/ask/tmplog.txt
                if ($argument =~ $RE_ASSIGNMENT) {
                    my @fields = split $RE_ASSIGNMENT, $argument;
                    ($argument_name, $argument_value) = @fields;
                }

                # Try to find the rule for this argument...
                my $opt_has_rule = $rules->{$argument_name};

                # if we can't find this rule, check if it's an alias.
                if (!$opt_has_rule && $aliases->{$argument_name}) {

                    # set the argument name to the name of the original.
                    # and set the rule to the rule of the original.
                    $argument_name = $aliases->{$argument_name};
                    $opt_has_rule  = $rules->{$argument_name};
                }

                if (!$opt_has_rule && !$options_ref->{allow_unspecified}) {
                    $self->unknown_argument_error($argument);
                }

                $result_argv->{$argument_name} =
                    $opt_has_rule
                    ? $self->handle_rule($argument_name, $opt_has_rule, $node,
                    $argument_value)
                    : (
                    $argument_value || 1
                    );
            }

        }
        else {
            push @{$leftovers}, $argument;
        }

        return;
    }

    sub find_arg_type {
        my ($self, $argument) = @_;

        if ($argument =~ $RE_LONG_ARGUMENT) {
            return 'long';
        }

        if ($argument =~ $RE_SHORT_ARGUMENT) {
            return 'short';
        }

        # return nothing if this is not a special argument/option.
        return;
    }

    sub is_string {

        # we have no limits for what a string can be.
        return 1;
    }

    sub is_digit  {
        my ($self, $value, $option_name, $value_ref) = @_;
        return 0 if $value eq q{};
        my $is_digit = 0;

        my $first_two_chars = substr $value, 0, 2;
        if ($first_two_chars eq '0x') {

            # starts with 0x: is hexadecimal number
            $value = substr $value, 2, length $value;
            if ($value =~ m/\A [\dA-Fa-f]+ \z/xms) {

                # We get a reference to the value as argument #4.
                # convert the value to hex.
                ${$value_ref} = hex $value;
                $is_digit = 1;
            }
        }
        elsif ($value =~ m/\A [-+]? \d+ \z/xms) {
            $is_digit = 1;
        }

        if (!$is_digit) {
            return $self->type_mismatch_error('digit',
                "$option_name must be a digit (0-9).");
        }

        return 1;
    }

    sub type_mismatch_error {
        my ($self, $type, $message) = @_;
        my $options_ref = $self->options;

        $options_ref->{die_on_type_mismatch}
            ? croak  $message, "\n"
            : warn $message, "\n"
        ;

        return 0;
    }

    sub unknown_argument_error {
        my ($self, $argument) = @_;

        croak "Unknown argument: $argument.\n";
    }

    sub handle_rule {
        my ($self, $arg_name, $rule_ref, $node, $arg_value) = @_;
        my $rule_data;

        my $rule_type = $rule_ref->{type};

        if (ref $rule_type eq 'CODE') {
            return $rule_type->($self, $node, $arg_name, $arg_value);
        }
        elsif (ref $rule_type eq 'Regexp') {
            no warnings 'uninitialized'; ## no critic
            my $next_arg = $self->get_next_arg($node);
            if ($next_arg !~ $rule_type) {
                if (! defined $next_arg) {
                    $next_arg = '<no-value>';
                }
                croak sprintf('Argument %s [%s] does not match %s', ## no critic
                    $arg_name, $next_arg, _regex_as_text($rule_type)
                );
            }
            return $next_arg;

        }


        if ($RULE_ACTION{$rule_type}) {

            $arg_value ||= $RULE_ACTION{$rule_type}->($self, $node);

            if ($TYPE_CHECK{$rule_type}) {
                $TYPE_CHECK{$rule_type}
                    ->($self,$arg_value, $arg_name, \$arg_value);
            }
        }
        else {
            $Carp::CarpLevel = 2; ## no critic;
            croak "Unknown rule type [$rule_type] for argument [$arg_name]";
        }

        return $arg_value;
    }

    sub get_next_arg {
        my ($self, $node) = @_;

        return $self->delete_arg( $node->next );
    }

    sub get_prev_arg {
        my ($self, $node) = @_;

        return $self->delete_arg( $node->prev );
    }

    sub peek_next_arg {
        my ($self, $node) = @_;
        if ($node->next) {
            return $node->next->data;
        }
        return;
    }

    sub peek_prev_arg {
        my ($self, $node) = @_;
        if ($node->prev) {
            return $node->prev->data;
        }
        return;
    }

    sub delete_arg {
        my ($self, $node) = @_;
        my $dll = $self->dll;

        return $dll->delete_node($node);
    }

    # XXX this is not very complete.
    sub show_help {
        my ($self) = @_;

        while (my ($arg, $help) = each %{ $self->help }) {
            my $ret = print {*STDERR} "$arg\t\t\t$help\n";
            croak 'I/O Error. Cannot print to terminal' if !$ret;
        }

        return;
    }

    # XXX this is not very complete.
    sub show_usage {
        my ($self) = @_;

        my $program_name = $self->options->{program_name};

        if (! $program_name) {
            $program_name = $PROGRAM_NAME;
        }

        require File::Basename;
        $program_name = File::Basename::basename($program_name);

        my @arguments;
        while (my ($arg, $spec) = each %{ $self->rules }) {
            if ($spec->{type} eq 'string' || $spec->{type} eq 'digit') {
                push @arguments, "$arg <n>";
            }
            else {
                push @arguments, $arg;
            }
        }

        my $arguments = join q{|}, @arguments;

        my $ret = print {*STDERR} "Usage: $program_name [$arguments]\n";
        croak 'I/O Error. Cannot print to terminal' if !$ret;

        return;
    }

    #========================================================================
    #                           - CLASS METHODS -
    #========================================================================

    #------------------------------------------------------------------------
    # getoptions(\%rules, \%options, \@opt_argv)
    #
    #------------------------------------------------------------------------
    sub getoptions {
        my ($rules_ref, $options_ref, $argv_ref) = @_;

        my $getopts =
            __PACKAGE__->new($rules_ref, $options_ref, $argv_ref); ## no critic;
        my $result  = $getopts->result();

        # ARGV should be set to what is left of the argument vector.
        @ARGV = @{ $getopts->leftovers };

        return $result;
    }

    sub opt_String { ## no critic
        my ($help) = @_;
        return {
            type => 'string',
            help => $help,
        };
    }

    sub opt_Digit { ## no critic
        my ($help) = @_;
        return {
            type => 'digit',
            help => $help,
        };
    }

    sub opt_Flag { ## no critic
        my ($help) = @_;
        return {
            type => 'flag',
            help => $help,
        };
    }

    sub _regex_as_text {
        my $regex_as_text = scalar shift;
        my $regex_modifiers;

        # The quoted regex (?xmsi:hello) should look something like this
        #   /hello/xmsi
        # The job is to remove the (?: and capture xmsi into $1.
        my $ret = $regex_as_text =~ s{
            \A              # beginning of string.
                \(\?        # a paren start and a question mark.
                    ([\w-]+)?   # none or more word characters captured to $1
                :           # ends with a colon.
        }{}xms;

        if ($ret) {
            $regex_modifiers = $1;
        }

        # remove the closing paren at the end.
        $regex_as_text =~ s/\) \z//xms;

        # The final text we return should be:
        #   /hello/xmsi
        # if the regex we got was:
        #   (?xmsi:hello)
        $regex_as_text = "/$regex_as_text/";
        if ($regex_modifiers) {
            $regex_as_text .= $regex_modifiers;
        }

        return $regex_as_text;
    }
}

1;

__END__

=for stopwords expandtab shiftround

=begin wikidoc

= NAME

Getopt::LL - Flexible argument processing.

= VERSION

This document describes *Getopt::LL* version %%VERSION%%

= SYNOPSIS

    use Getopt:LL qw(getoptions);

    my $use_foo = 0;

    my $options = getoptions({
        '-t'            => 'string',
        '--verbose|-v'  => 'flag',
        '--debug|-d'    => 'digit',
        '--use-foo'     => sub {
            $use_foo = 1;
        },
        '-output|-o'    => sub {
            my ($getopt, $node) = @_;
            my $next_arg = $getopt->get_next_arg($node);

            if ($next_arg eq '-') {
                $out_to_stdout = 1;
            }

            return $next_arg;
        };
    });
            
= DESCRIPTION

Getopt::LL provides several ways for defining the arguments you want.
There is [Getopt::LL::Simple] for defining arguments on the -use-line-,
[Getopt::LL::Short] for abbreviated rules (that looks like [Getopt::Long]).

== RULES

-Rules- is the guidelines Getopt::LL follows when it meets new options.
The rules defines what options we want, which options are required,
and what to do with an option.

A simple rule-set could be written like this:

    my $rules = {
        '-foo'      => 'string',
        '-bar'      => 'string',
        '--verbose' => 'digit',
        '--debug'   => 'flag',
    };

=== Rule types/actions.

The argument to an rule is what we call a rule type or rule action.
It can be one of the following:

*   {'flag'}

The option is a flag. The value of the option will be boolean true.
 
*   {'string'}

The option is a string. The value of the option will be the next argument
in the argument list.

*   {'digit'}

The option is a number. The value of the option will be the next argument
in the argument list. The value will be sent to {is_digit($value)} to check
that it's really a number. If it's not a number and the {die_on_type_mismatch}
option is set, the program will die with a type mismatch error message.

A digit can also be a hex value if it begins with -0x-, any hex value
will be converted to a decimal value.

*   A regular expression: {qr/ /}

The next argument will be matched against the regular expression.
If it doesn't match the program will die with the message

    Argument [--arg] doesn't match [regular-expression].

*   An anonymous subroutine. {sub { }}

The sub-routine will be called with the following arguments

0    {$_[0]} - The Getopt::LL object.
0    {$_[1]} - The current argument node (A Getopt::LL::DLList::Node] object).
0    {$_[2]} - The argument name.
0    {$_[3]} - If an argument value was set by the user with {--arg=value}, the value is in this variable.

The return value of the anonymous subroutine will be the value of the option.

Here is an example of a rule sub that simply assigns the value of the next
argument to the option value:

    my $rules = {
    
        '-foo'  => sub {
            my ($getopt, $node, $arg_name, $arg_value) = @_;
                return $arg_value if $arg_value;

                my $next_arg = $getopt->get_next_arg($node);
                
                return $next_arg;
        },
    };

    my $result = getoptions($rules);

    print 'FOO IS: [', $result->{'-foo'}, "]\n";

if this program is called with the arguments: {-foo bar} or {-foo=bar} it will
print out this message:

    FOO IS [bar]


=== Specifying required arguments.

There are two ways of specifying required arguments.

* Embedded in the rule name, by an exclamation point *!*.

    my $rules = {
        '-foo!' => 'string',
    };

* Or by adding the {required} flag.

    my $rules = {
        '-foo'  => {
            type        => 'string',
            required    => 1,
        },
    }

=== Adding default values to non-required arguments.

There are two ways of specifying default values.

* Embedded in the rule name, inside parens *( .. )*

    my $rules = {
        '-bar(defaultValue)' => 'string',
    };

* Or by adding a {default} key to the spec.

    my $rules = {
        '-bar'  => {
            type    => 'string',
            default => 'defaultValue',
        },
    };

== DID YOU SAY SIMPLE?

With [Getopt::LL::Simple] you can define the arguments you want on the
-use-line-:

    #!/usr/bin/perl
    use strict;
    use warnings;
    
    # we have three arguments:
    #   -f!          (our filename, which is a s(tring) the ! means that it's
    #               a required argument.
    #   --verbose   (print extra information about what we're doing, is a flag).
    #   --debug     (the level of debugging information to print. is a
    #                d(igit).
    #
    use Getopt::LL::Simple qw(
        -f!=s
        --verbose
        --debug|d=d
    );

    if ($ARGV{'--verbose'}) {
        print "In verbose mode...\n";
    }
    
    if ($ARGV{'--debug'}) {
        print 'Debugging level is set to: ', $ARGV{'--debug'}, "\n";
    }

    print "The contents of @ARGV is:\n";
    prnit "\t", join{q{, }, @ARGV), "\n";

The options that was found is placed into {%ARGV}, the arguments that is not
an option is placed into {@ARGV}. So say we have run the program with the
following arguments:

    ./myprogram -f tmp.log --verbose --debug=3 foo bar

or
    ./myprogram -f tmp.log --verbose --debug 3 foo bar

it will give this output:

    In verbose mode...
    Debugging level is set to: 3
    The contents of @ARGV is:
        foo, bar 


= SUBROUTINES/METHODS


== CONSTRUCTOR


=== {new(\%rules, \%options, \@opt_argv )}

Uses {@ARGV} if no {\@opt_argv} is present.


== ATTRIBUTES

=== {rules}

=== {set_rules}

The list of rules passed to {new}.

=== {options}

=== {set_options}

The options passed  to {new}.

=== {dll}

=== {set_dll}

Our arguments converted to a doubly linked list.
(is a [Getopt::LL::DLList] object).

=== {result}

=== {set_result}

The final argument hash.

=== {leftovers}

=== {set_leftovers}

Array of items in the argument list that does not start with *-* or *--*.

== INSTANCE METHODS

=== {parseoption($argument, $node)}

This method is called for each argument to decide what to do with it.

=== {find_arg_type($argument)}

Find out what kind of argument this is.

If the argument starts with *-* (a single dash) it returns {short},
but if it starts with *--* (two dashes) it returns {long}.


=== {is_string($value, $option_name)}

Check if value is a proper string.

=== {is_digit($value, $option_name)}

Check if value is a digit. ({0-9+})
If value starts with -0x-, it is treated as a hex value.

=== {type_mismatch_error($type, $message)}

Called whenever a type does not match it's requirements.

=== {unknown_argument_error($argument)}

Called when a argument that has no rule is found.
(turn off by setting the {allow_unspecified} option to a true value).

=== {handle_rule($option_name, $rule, $node)}

Called when {parseoption()} finds an argument that we have an existing rule for.
This function decides what to do with the argument based on it's {RULE_ACTION}.

=== {get_next_arg($node)}

Get and delete the next argument.
(Gets the next node in our doubly linked list and deletes the current node)

=== {peek_next_arg($node)}

Look at the next argument, but don't delete it.

=== {get_prev_arg($node)}

Get and delete the previous argument.

=== {peek_prev_arg($node)}

Look at the previous argument, but don't delete it.

== {delete_arg($node)}

Deletes the argument.

== {rules_prepare(\%rules)}

Find and prepare aliases in the rule set.

== {rules_postactions( )}

Things to do with rules after argument processing is done.
Like adding default values for arguments with default values defined and
checking for required arguments.

== {show_help( )}

Print help for arguments to standard error.
This is experimental and the implementation is not exactly complete.

== {show_usage( )}

Print usage to standard error.
This is experimental and the implementation is not exactly complete.

== CLASS METHODS 

=== {getoptions(\%rules, \%options, \@opt_argv)}

Parses and gets arguments based on the rules in {\%rules}.
Uses {@ARGV} if {\@opt_arg} is not specified.

Returns hash with the arguments it found.
{@ARGV} is replaced with the arguments that does not start with *-* or *--*.

=== {opt_String($help_for_option)} 

Shortcut for writing:

    {
        type => 'string',
        help => $help_for_option,
    }

=== {opt_Digit($help_for_option)} 

Shortcut for writing:

    {
        type => 'digit',
        help => $help_for_option,
    }

=== {opt_Flag($help_for_option)} 

Shortcut for writing:

    {
        type => 'flag',
        help => $help_for_option,
    }

== PRIVATE INSTANCE METHODS

=== {_init()}

Called by new to traverse and parse the doubly linked list of arguments.

=== {_warn(@messages)}

Print a warning on the screen, but only if {$options->{silent}} is not set.

== PRIVATE CLASS METHODS

=== {_regex_as_text($regex)}

Quoted regexes are not very user-friendly to print directly, so this
function turns a quoted regex like:

    (?xmsi:hello)

into:

    /hello/xmsii


= DIAGNOSTICS


= CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

= DEPENDENCIES

* [Class::Dot]

* [version]

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
[bug-getopt-ll@rt.cpan.org|mailto:bug-getopt-ll@rt.cpan.org], or through the web interface at
[CPAN Bugtracker|http://rt.cpan.org].

= SEE ALSO

* [Getopt::Long]

* [Getopt::Euclid]

* [Getopt::Declare]

* [Getopt::Attribute]

= TEST SUITE CODE COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    lib/Getopt/LL.pm              100.0   98.6   94.4  100.0  100.0   38.2   99.2
    lib/Getopt/LL/DLList.pm       100.0  100.0  100.0  100.0  100.0   15.1  100.0
    lib/Getopt/LL/DLList/Node.pm  100.0  100.0    n/a  100.0  100.0    9.9  100.0
    lib/Getopt/LL/Short.pm        100.0  100.0  100.0  100.0  100.0    1.4  100.0
    lib/Getopt/LL/Simple.pm       100.0  100.0  100.0  100.0    n/a    0.6  100.0
    ...topt/LL/SimpleExporter.pm  100.0  100.0    n/a  100.0  100.0    4.6  100.0
    lib/Getopt/LL/properties.pm   100.0  100.0    n/a  100.0    n/a   30.2  100.0
    Total                         100.0   99.0   96.2  100.0  100.0  100.0   99.6
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

The summary was generated by [Devel::Cover].

= AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.


= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

= DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=end wikidoc

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround

