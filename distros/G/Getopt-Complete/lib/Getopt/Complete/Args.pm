package Getopt::Complete::Args;

use strict;
use warnings;

our $VERSION = $Getopt::Complete::VERSION;

use Getopt::Long;
use Scalar::Util;

sub new {
    my $class = shift;
    my $self = bless {
        'options' => undef,
        'values' => {},
        'errors' => [],
        'argv' => undef,
        @_,
    }, $class;

    unless ($self->{argv}) {
        die "No argv passed to " . __PACKAGE__ . " constructor!";
    }
   
    my $options = $self->{options};

    unless ($options) {
        die "No options passed to " . __PACKAGE__ . " constructor!";
    }

    my $type = ref($options);
    if (not $type) {
        die "Expected Getopt::Complete::Options, or a constructor ARRAY/HASH for ''options''.  Got: $type $options.";
    }
    elsif ($type eq 'ARRAY') {
        $self->{options} = Getopt::Complete::Options(@$options);
    }
    elsif ($type eq 'HASH') {
        $self->{options} = Getopt::Complete::Options(%$options);
    }
    elsif (Scalar::Util::blessed($options)) {
        if (not $options->isa("Getopt::Complete::Options")) {
            die "Expected Getopt::Complete::Options, or a constructor ARRAY/HASH for ''options''.  Got: $options.";
        }
    }
    else {
        die "Expected Getopt::Complete::Options, or a constructor ARRAY/HASH for ''options''.  Got reference $options.";
    }
    
    $self->_init();

    return $self;
}

sub options {
    shift->{options};
}

sub argv {
    @{ shift->{argv} };
}

sub errors {
    @{ shift->{errors} }
}

for my $method (qw/sub_commands option_names option_specs option_spec completion_handler/) {
    no strict 'refs';
    *{$method} = sub {
        my $self = shift;
        my $options = $self->options;
        return $options->$method(@_);
    }
}

sub has_value {
    my $self = shift;
    my $name = shift;
    return exists $self->{'values'}{$name};
}

sub value {
    my $self = shift;
    my $name = shift;
    my $value = $self->{'values'}{$name};
    return $value;
}

sub bare_args {
    my $self = shift;
    my $name = shift;
    my $value = $self->{'values'}{'<>'};
    return $value;
}

sub parent_sub_commands {
    my $self = shift;
    my $name = shift;
    my $value = $self->{'values'}{'>'};
    return $value;
}

sub _init {
    my $self = shift; 
    
    # as long as the first word is a valid sub-command, drill down to the subordinate options list,
    # and also shift the args into a special buffer
    # (if you have sub-commands AND bare arguments, and the arg is a valid sub-command ...don't do that
    local @ARGV = @{ $self->{argv} };
    my @sub_command_path;
    while (@ARGV and my $delegate = $self->options->completion_handler('>' . $ARGV[0])) {
        push @sub_command_path, shift @ARGV;
        $self->{options} = $delegate;
    }

    my %values;
    my @errors;

    do {
        local $SIG{__WARN__} = sub { push @errors, @_ };
        my $retval = Getopt::Long::GetOptions(\%values,$self->options->option_specs);
        if (!$retval and @errors == 0) {
            push @errors, "unknown error processing arguments!";
        }
        if ($ENV{COMP_CWORD}) {
            # we want to allow unknown option if the user puts them in, we just
            # didn't help complete it
            @errors = grep { $_ !~ /^Unknown option:/ } @errors;
        }
    };

    if (@ARGV) {
        if ($self->options->has_option('<>')) {
            my $a = $values{'<>'} ||= [];
            push @$a, @ARGV;
        }
        else {
            # in order to allow bare-args we only block unexpected arguments
            # for commands with sub-commands
            if ( $self->sub_commands ) {
                for my $arg (@ARGV) {
                    push @errors, "unexpected sub-command: $arg";
                }
            }
        }
    }

    if (@sub_command_path) {
        $values{'>'} = \@sub_command_path;
    }

    %{ $self->{'values'} } = %values;
    
    if (my @more_errors = $self->_validate_values()) {
        push @errors, @more_errors;
    }

    @{ $self->{'errors'} } = @errors;

    return (@errors ? () : 1);
}


sub _validate_values {
    my $self = shift;

    my @failed;
    for my $key (keys %{ $self->options->{completion_handlers} }) {
        my $completion_handler= $self->options->completion_handler($key);
        my $completions;
        if (ref($completion_handler) eq 'CODE') {
            # defer setting $completions
        }
        elsif (ref($completion_handler) eq 'ARRAY') {
            $completions = $completion_handler;
            $completion_handler = undef;
        }
        else {
            #warn "unexpected completion specification for $key: $completion_handler???";
            next;
        }

        my ($name,$spec) = ($key =~ /^([\w|-|\>][\w|-]*|\<\>|)(\W.*|)/);
        #my ($dashes,$name,$spec) = ($key =~ /^(\-*?)([\w|-]*|\<\>|)(\W.*|)/);
        if (not defined $name) {
            print STDERR "key $key is unparsable in " . __PACKAGE__ . " spec inside of $0 !!!";
            next;
        }
        if ($name eq '<>' and not $spec) {
            $spec = '=s@';
        }

        my $value_returned = $self->value($name);
        my @values = (ref($value_returned) ? @$value_returned : $value_returned);
        
        my $all_valid_values;
        for my $value (@values) {
            next if not defined $value;
            next if not defined $completions;
            my @valid_values_shown_in_message;
            if ($completion_handler) {
                # we pass in the value as the "completeme" word, so that the callback
                # can be as optimal as possible in determining if that value is acceptable.
                $completions = $completion_handler->(undef,$value,$key,$self->{'values'});
                if (not defined $completions or not ref($completions) eq 'ARRAY' or @$completions == 0) {
                    # if not, we give it the chance to give us the full list of options
                    $completions = $completion_handler->(undef,undef,$key,$self->{'values'});
                }
                unless (ref($completions) eq 'ARRAY') {
                    warn "unexpected completion specification for $key: $completions???";
                    next;
                }
            }
            my @valid_values = @$completions;
            @valid_values_shown_in_message = @valid_values;
            
            if (ref($valid_values[-1]) eq 'ARRAY') {
                push @valid_values, @{ pop(@valid_values) };
                pop @valid_values_shown_in_message;
            }
            unless (grep { $_ eq $value } map { /(.*)\t$/ ? $1 : $_ } @valid_values) {
                my $msg = ($key eq '<>' ? "invalid argument $value." : "$key has invalid value $value."); 
                if (@valid_values_shown_in_message) {
                    $msg .= "  Select from: " . join(", ", map { /^(.+)\t$/ ? $1 : $_ } @valid_values_shown_in_message);
                }
                push @failed, $msg;
            }
        }
    }
    return @failed;
}

sub resolve_possible_completions {
    my ($self, $command, $current, $previous) = @_;

    my $all = $self->{values};

    $previous = '' if not defined $previous;

    my @possibilities;

    my ($dashes,$resolve_values_for_option_name) = ($previous =~ /^(-{1,2})(.*)/); 
    my $is_option_name = 0;
    if (not length $previous) {
        # no specific option is before this: a sub-command, a bare argument, or an option name
        if ($current =~ /^(-+)/
            or (
                $current eq ''
                and not ($self->sub_commands)
                and not ($self->options->has_option('<>'))
            )
        ) {
            # the incomplete word is an option name
            $is_option_name = 1;

            my @args = $self->option_names;
            
            # We only show the negative version of boolean options 
            # when the user already has "--no-" on the line.
            # Otherwise, we just include --no- as a possible (partial) completion
            no warnings; #########
            my %boolean = 
                map { $_ => 1 } 
                grep { not $self->has_value($_) }
                grep { $self->option_spec($_) =~ /\!/ } 
                grep { $_ ne '<>' and substr($_,0,1) ne '>' }  
                @args;

            my $show_negative_booleans = ($current =~ /^--no-/ ? 1 : 0);
            @possibilities = 
                map { length($_) ? ('--' . $_) : ('-') } 
                map {
                    ($self->option_spec($_) =~ /\=/ ? "$_=\t" : $_ )
                }
                map {
                    ($show_negative_booleans and $boolean{$_} and not substr($_,0,3) eq 'no-')
                        ? ($_, 'no-' . $_)
                        : $_
                }
                grep {
                    not (defined $self->value($_) and not $self->option_spec($_) =~ /@/)
                }
                grep { $_ ne '<>' and substr($_,0,1) ne '>' } 
                @args;
            if (%boolean and not $show_negative_booleans) {
                # a partial completion for negating booleans when we're NOT
                # already showing the complete list
                push @possibilities, "--no-\t";
            }
            if ($current =~ /-{1,2}(.+?)=(.*)/) {
                # using the --key=value syntax..
                my ($option,$value) = ($1,$2);
                @possibilities = $self->reduce_possibilities_for_current_word('--' . $option, @possibilities);
                if (!@possibilities || @possibilities == 1 and length($current) >= $possibilities[0]) {
                    # the key portion is complete
                    # continue below as though were were doing a regular value completion
                    $resolve_values_for_option_name = $option;
                    $current = ($value eq "\t" ? '' : $value);
                    @possibilities = ();
                }
            }
        }
        else {
            # bare argument or sub-command
            $resolve_values_for_option_name = '<>';
        }
    }
    
    if ($resolve_values_for_option_name) {
        # either a value for a named option, or a bare argument.
        if (my $handler = $self->completion_handler($resolve_values_for_option_name)) {
            # the incomplete word is a value for some option (possible the option '<>' for bare args)
            if (defined($handler) and not ref($handler) eq 'ARRAY') {
                $handler = $handler->($command,$current,$previous,$all);
            }
            unless (ref($handler) eq 'ARRAY') {
                die "values for $previous must be an arrayref! got $handler\n";
            }
            @possibilities = @$handler;
        }
        elsif ($resolve_values_for_option_name && !$self->sub_commands) {
            my $handler = Getopt::Complete::files->($command,$current,$previous,$all);
            @possibilities = @$handler;
        }
        else {
            # no possibilities
            @possibilities = ();
        }

        if ($resolve_values_for_option_name eq '<>') {
            push @possibilities, $self->sub_commands;
            if (grep { $_ ne '<>' and substr($_,0,1) ne '>' } $self->option_names) {
                # do a partial completion on dashes if there are any non-bare (option) arguments
                #push @possibilities, "--\t"
            }
        }
    }

    my @matches = $self->reduce_possibilities_for_current_word($current,@possibilities);
    return @matches;
}

sub reduce_possibilities_for_current_word {
    my ($self, $current, @possibilities) = @_;
    
    my $uncompletable_valid_possibilities = pop @possibilities if ref($possibilities[-1]);
    
    # Determine which possibilities will actually match the current word
    # The shell does this for us, but we need to do it to predict a few things
    # and to adjust what we show the shell.
    # This loop also determines which options should complete with a space afterward,
    # and which options can be abbreviated when showing a list for the user.
    my @matches; 
    my @nospace;
    my @abbreviated_matches;
    for my $p (@possibilities) {
        my $i =index($p,$current);
        if ($i == 0) {
            push @matches, $p;
        }
    }
    return @matches;
}

sub translate_completions_for_shell_display {
    my ($self, $current, @matches) = @_;

    my $uncompletable_valid_matches = pop @matches if ref($matches[-1]);
    
    # Determine which matches will actually match the current word
    # The shell does this for us, but we need to do it to predict a few things
    # and to adjust what we show the shell.
    # This loop also determines which options should complete with a space afterward,
    # and which options can be abbreviated when showing a list for the user.
    my @printable; 
    my @nospace;
    my @abbreviated_printable;
    for my $p (@matches) {
        my $m;
        if (substr($p,length($p)-1,1) eq "\t") {
            # a partial match: no space at the end so the user can "drill down"
            $m = substr($p,0,length($p)-1);
            $nospace[$#printable+1] = 1;
        }
        else {
            $m = $p;
            $nospace[$#printable+1] = 0;
        }
        if (substr($m,0,1) eq "\t") {
            # abbreviatable...
            # (nothing does this currently, and the code below which uses it does not work yet)
            my ($prefix,$abbreviation) = ($m =~ /^\t(.*)\t(.*)$/);
            push @printable, $prefix . $abbreviation;
            push @abbreviated_printable, $abbreviation;
        }
        else {
            push @printable, $m;
            push @abbreviated_printable, $m;
        }
    }

    if (@printable == 1) {
        # there is one match
        # the shell will complete it if it is not already complete, and put a space at the end
        if ($nospace[0]) {
            # We don't want a space, and there is no way to tell bash that, so we trick it.
            if ($printable[0] eq $current) {
                # It IS done completing the word: return nothing so it doesn't stride forward with a space
                # It will think it has a bad completion, effectively.
                @printable = ();
            }
            else {
                # It is NOT done completing the word.
                # We return 2 items which start with the real value, but have an arbitrary ending.
                # It will show everything but that ending, and then stop.
                push @printable, $printable[0];
                $printable[0] .= 'A';
                $printable[1] .= 'B';
            }
        }
        else {
            # we do want a space, so just let this go normally
        }
    }
    else {
        # There are multiple printable to the text already typed.
        # If all of them have a prefix in common, the shell will complete that much.
        # If not, it will show a list.
        # We may not want to show the complete text of each word, but a shortened version,
        my $first_mismatch = eval {
            my $pos;
            no warnings;
            for ($pos=0; $pos < length($printable[0]); $pos++) {
                my $expected = substr($printable[0],$pos,1);
                for my $match (@printable[1..$#printable]) {  
                    if (substr($match,$pos,1) ne $expected) {
                        return $pos;            
                    }
                }
            }
            return $pos;
        };
        

        # NOTE: nothing does this currently, and the code below does not work.
        # Enable to get file/directory completions to be short, like is default in the shell. 
        if (0) {
            my $current_length = length($current);
            if (@printable and ($first_mismatch == $current_length)) {
                # No partial completion will occur: the shell will show a list now.
                # Attempt abbreviation of the displayed options:

                my @printable = @abbreviated_printable;

                #my $cut = $current;
                #$cut =~ s/[^\/]+$//;
                #my $cut_length = length($cut);
                #my @printable =
                #    map { substr($_,$cut_length) } 
                #    @printable;

                # If there are > 1 abbreviated items starting with the same character
                # the shell won't realize they're abbreviated, and will do completion
                # instead of listing options.  We force some variation into the list
                # to prevent this.
                my $first_c = substr($printable[0],0,1);
                my @distinct_firstchar = grep { substr($_,0,1) ne $first_c } @printable[1,$#printable];
                unless (@distinct_firstchar) {
                    # this puts an ugly space at the beginning of the completion set :(
                    push @printable,' '; 
                }
            }
            else {
                # some partial completion will occur, continue passing the list so it can do that
            }
        }
    }

    for (@printable) {
        s/ /\\ /g;
    }

    return @printable;
}

sub __install_as_default__ {
    my $self = shift;
    *Getopt::Complete::ARGS = \$self;
    *Getopt::Complete::ARGS = \%{ $self->{values} };
}

1;

=pod 

=head1 NAME

Getopt::Complete::Args - a set of option/value pairs 

=head1 VERSION

This document describes Getopt::Complete::Args 0.26.

=head1 SYNOPSIS

This is used internally by Getopt::Complete during compile.

A hand-built implementation might use the objects directly, and 
look like this:

 # process @ARGV...
 
 my $args = Getopt::Complete::Args->new(
    options => [                            # or pass a Getopt::Complete::Options directly                          
        'myfiles=s@' => 'f',
        'name'       => 'u',
        'age=n'      => undef,
        'fast!'      => undef,
        'color'      => ['red','blue','yellow'],
    ]
    argv => \@ARGV
 );

 $args->options->handle_shell_completion;   # support 'complete -F _getopt_complete myprogram'

 if (my @e = $args->errors) {
    for my $e (@e) {
        warn $e;
    }
    exit 1; 
 }

 # on to normal running of the program...

 for my $name ($args->option_names) {
    my $spec = $args->option_spec($name);
    my $value = $args->value($name);
    print "option $name has specification $spec and value $value\n";
 }

=head1 DESCRIPTION

An object of this class describes a set of option/value pairs, built from a L<Getopt::Complete::Options> 
object and a list of command-line arguments (@ARGV).

This is the class of the $Getopt::Complete::ARGS object, and $ARGS alias created at compile time.
It is also the source of the %ARGS hash injected into both of those namepaces at compile time.

=head1 METHODS

=over 4

=item argv

Returns the list of original command-line arguments.

=item options

Returns the L<Getopt::Complete::Options> object which was used to parse the command-line.

=item value($option_name)

Returns the value for a given option name after parsing.

=item bare_args

Returns the bare arguments.  The same as ->value('<>')

=item parent_sub_commands

When using a tree of sub-commands, gives the list of sub-commands selected, in order to
get to this point.   The options and option/value pairs apply to just this particular sub-command.

The same as ->value('>').

Distinct from ->sub_commands(), which returns the list of next possible choices when
drilling down.

=item option_spec($name)

Returns the GetOptions specification for the parameter in question.

=item completion_handler($name)

Returns the arrayref or code ref which handles resolving valid completions.

=item sub_commands

The list of sub-commands which are options at this level of a command tree.

This is distinct from sub_command_path, which are the sub-commands which were chosen
to get to this level in the tree.

=back

=head1 SEE ALSO

L<Getopt::Complete>, L<Getopt::Complete::Options>, L<Getopt::Complete::Compgen>

=head1 COPYRIGHT

Copyright 2010 Scott Smith and Washington University School of Medicine

=head1 AUTHORS

Scott Smith (sakoht at cpan .org)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this
module.

=cut

