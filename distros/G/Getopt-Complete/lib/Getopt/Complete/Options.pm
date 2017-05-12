package Getopt::Complete::Options;

use strict;
use warnings;

our $VERSION = $Getopt::Complete::VERSION;

use IPC::Open2;
use Data::Dumper;
use Getopt::Complete::LazyOptions;

sub new {
    my $class = shift;
    my $self = bless {
        sub_commands => [],
        option_specs => {},
        completion_handlers => {},
        parse_errors => undef,
    }, $class;

    # process the params into normalized completion handlers
    # if there are problems, the ->errors method will return a list.
    $self->_init(@_);
    return $self;
}

sub sub_commands {
    return @{ shift->{sub_commands} };
}

sub option_names {
    return keys %{ shift->{completion_handlers} };
}

sub option_specs { 
    Carp::confess("Bad params") if @_ > 1;
    my $self = shift;
    my @specs;
    for my $key (keys %{ $self->{option_specs} }) {
        next if $key eq '<>';
        my $value = $self->{option_specs}{$key};
        push @specs, $key . $value;
    }
    return @specs;
}

sub option_spec {
    my $self = shift;
    my $name = shift;
    Carp::confess("Bad params") if not defined $name;
    return $self->{option_specs}{$name};
}

sub has_option {
    my $self = shift;
    my $name = shift;
    return exists $self->{completion_handlers}{$name};
}

sub completion_handler {
    my $self = shift;
    my $name = shift;
    Carp::confess("Bad params") if not defined $name;
    return $self->{completion_handlers}{$name};
}

sub _init {
    my $self = shift;
    
    my $completion_handlers = $self->{completion_handlers} = {};
    my $option_specs    = $self->{option_specs} = {};

    my @parse_errors;
    while (my $key = shift @_) {
        my $handler = shift @_;
        
        my ($name,$spec) = ($key =~ /^([\w|-|\>][\w|-]*|\<\>|)(\W.*|)/);
        if (not defined $name) {
            push @parse_errors,  __PACKAGE__ . " is unable to parse '$key' from spec!";
            next;
        }
        if ($handler and not ref $handler) {
            my $code;
            if ($handler =~ /::/) {
                # fully qualified
                eval {
                    $code = \&{ $handler };
                };
                unless (ref($code)) {
                    push @parse_errors,  __PACKAGE__ . " $key! references callback $handler which is not found!  Did you use its module first?!";
                }
            }
            else {
                $code = Getopt::Complete::Compgen->can($handler);
                unless (ref($code)) {
                    push @parse_errors,  __PACKAGE__ . " $key! references builtin $handler which is not found!  Select from:"
                        . join(", ", map { my $short = substr($_,0,1); "$_($short)"  } @Getopt::Complete::Compgen::builtins);
                }
            }
            if (ref($code)){
                $handler = $code;
            }
        }
        if (substr($name,0,1) eq '>') {
            # a "sub-command": make a sub-options tree, which may happen recursively
            my $word = substr($name,1);
            if (ref($handler) eq 'ARRAY') {
                $handler = Getopt::Complete::Options->new(@$handler);
            }
            elsif (ref($handler) eq 'CODE' or ref($handler) eq 'SCALAR') {
                # be lazy about actually resolving this               
                $handler = Getopt::Complete::LazyOptions->new($handler);
            }
            else {
                die "expected arrayref or code for $name value!";
            }
            $handler->{command} = ($self->{command} || '') . " " . $word; 
            $completion_handlers->{$name} = $handler;
            push @{ $self->{sub_commands} }, $word;
            next;
        }

        $completion_handlers->{$name} = $handler;
        if ($name eq '<>') {
            next;
        }
        if ($name eq '-') {
            if ($spec and $spec ne '!') {
                push @parse_errors,  __PACKAGE__ . " $key errors: $name is implicitly stand-alone!";
            }
            $spec ||= '!';
        }
        $spec ||= '=s';
        $option_specs->{$name} = $spec;
        if ($spec =~ /[\!\+]/ and defined $completion_handlers->{$key}) {
            push @parse_errors,  __PACKAGE__ . " error on option $key: ! and + expect an undef completion list, since they do not have values!";
            next;
        }
        if (ref($completion_handlers->{$key}) eq 'ARRAY' and @{ $completion_handlers->{$key} } == 0) {
            push @parse_errors,  __PACKAGE__ . " error on option $key: an empty arrayref will never be valid!";
        }
    }
    
    $self->{parse_errors} = \@parse_errors;
   
    return (@parse_errors ? () : 1);
}

sub handle_shell_completion {
    my $self = shift;
    if ($ENV{COMP_CWORD}) {
        my ($command,$current,$previous,$other) = $self->parse_completion_request(\@ARGV,$ENV{COMP_CWORD});
        unless ($command) {
            # parse error
            # this typically only happens when there are mismatched quotes, which means something you can't complete anyway
            # don't complete anything...
            exit;
        }
        my $args = Getopt::Complete::Args->new(options => $self, argv => $other);
        my @matches;
        my @printable_matches;
        unless ($args->errors) {
            @matches = $args->resolve_possible_completions($command,$current,$previous);
            @printable_matches = $args->translate_completions_for_shell_display($current, @matches);
        }
        print join("\n",@printable_matches),"\n";
        exit;
    }
    return 1;
}

sub _expand_token {
    my $self = shift;
    my $token = shift;

    return '' unless $token;

    my ($reader, $writer);
    my $pid = open2($reader,$writer,'bash 2>/dev/null');
    return unless $pid;
    print $writer "echo $token";
    close $writer;
    my $result = join("",<$reader>);
    chomp $result;
    return $result || $token;
}

sub parse_completion_request {
    my $self = shift;
    my ($comp_words, $comp_cword) = @_;

    @$comp_words = map($self->_expand_token($_), @$comp_words);

    my @left = @$comp_words[0..$comp_cword];
    my $want_new_word = (!defined $left[-1]);  #if starting new word, last value will be undef
    my $left = join(" ", map(defined($_) ? $_ : '', @left)); #want an extra space at end if $want_new_word
    if($want_new_word) {
        pop @left;
    }
    # find options for last sub-command if it has a completion handler
    # skipping first command but old code didn't but it also never seemed to trigger before
    my @sub_cmds = @left[1..$#left];
    while (@sub_cmds and my $delegate = $self->completion_handler('>' . $sub_cmds[0])) {
        shift @sub_cmds;
        $self = $delegate;
    }

    my @right = @$comp_words[($comp_cword+1)..$#$comp_words];
    my $right = join(" ", @right);

    unless (@left) {
        # parse error
        return;
    }
 
    my $command = shift @left;
    my $current;
    if (substr($left, -1) ne ' ' || substr($left, -2) eq '\ ') {
        # we're at the end of the final word in the @left list, and are trying to complete it
        $current = pop @left;
    }
    else {
        $current = '';
    }
    $left =~ s/\\ / /g;
    my $previous = ( (@left and $left[-1] =~ /^-{1,2}/ and not $left[-1] =~ /^-{1,2}[\w\-]+\=/) ? (pop @left) : ()) ;
    # TODO: this might be a good spot to make sure we don't complete a new sub-command
    my @other_options = (@left,@right);

    # it's hard to spot the case in which the previous word is "boolean", and has no value specified
    if ($previous) {
        my ($name) = ($previous =~ /^-+(.*)/);
        my $spec = $self->option_spec($name);
        if ($spec and $spec =~ /[\!\+]/) {
            push @other_options, $previous;
            $previous = undef;
        }
        elsif ($name =~ /no-(.*)/) {
            # Handle a case of an option which natively starts with "--no-"
            # and is set to boolean.  There is one of everything in this world. 
            $name =~ s/^no-//;
            $spec = $self->option_spec($name);
            if ($spec and $spec =~ /[\!\+]/) {
                push @other_options, $previous;
                $previous = undef;
            }
        }
        
    }

    my $quote;
    if ($current =~ /^([\'\"])/) {
        $quote = $1;
        $current = substr($current,1);
        if (substr($current,-1,1) eq $quote and not substr($current,-2,1) eq '\\') {
           $current = substr($current,0,length($current)-1); 
        };
    }
    return ($command,$current,$previous,\@other_options, $quote);
}

1;

=pod 

=head1 NAME

Getopt::Complete::Options - a command-line options specification 

=head1 VERSION

This document describes Getopt::Complete 0.26

=head1 SYNOPSIS

This is used internally by Getopt::Complete during compile.

 my $opts = Getopt::Complete::Options->new(
    'myfile=s' => 'f',
    'mydir=s@'  => 'd',
    '<>' => ['one','two','three']
 );

 $opts->option_names;
 # myfile mydir
 
 $opts->option_spec("mydir")
 # '=s@'
 
 $opts->option_handler("myfile")
 # 'f'
 
 $opts->option_handler("<>")
 # ['one','two','three'];

 $opts->handle_shell_completion;
 # if it detects it is talking to the shell completer, it will respond and then exit

 # this method is used by the above, then makes a Getopt::Complete::Args.
 ($text_typed,$option_name,$remainder_of_argv) = $self->parse_completion_request($comp_words,$comp_cword);

=head1 DESCRIPTION

Objects of this class are used to construct a Getop::Complete::Args from a list of
command-line arguments.  It specifies what options are available to the command
line, helping to direct the parser.   

It also specifies what values are valid for those options, and provides an API
for access by the shell to do tab-completion.

The valid values list is also used by Getopt::Complete::Args to validate its
option values, and produce the error list it generates.

=head1 SEE ALSO

L<Getopt::Complete>, L<Getopt::Complete::Args>, L<Getopt::Complete;:Compgen>

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

