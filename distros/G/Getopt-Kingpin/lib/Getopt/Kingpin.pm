package Getopt::Kingpin;
use 5.008001;
use strict;
use warnings;
use Object::Simple -base;
use Getopt::Kingpin::Flags;
use Getopt::Kingpin::Args;
use Getopt::Kingpin::Commands;
use File::Basename;
use Carp;

our $VERSION = "0.09";

use overload (
    '""' => sub {$_[0]->name},
    fallback => 1,
);

has flags => sub {
    my $flags = Getopt::Kingpin::Flags->new;
    $flags->add(
        name        => 'help',
        description => 'Show context-sensitive help.',
    )->bool();
    return $flags;
};

has args => sub {
    my $args = Getopt::Kingpin::Args->new;
    return $args;
};

has commands => sub {
    my $commands = Getopt::Kingpin::Commands->new;
    return $commands;
};

has _version => sub {
    return "";
};

has parent => sub {
    return
};

has name => sub {
    return basename($0);
};

has description => sub {
    return "";
};

has terminate => sub {
    return sub {
        my $ret = defined $_[1] ? $_[1] : 0;
        exit $ret;
    };
};

sub new {
    my $class = shift;
    my @args = @_;

    my $self;
    if (@args == 2) {
        $self = $class->SUPER::new(
            name => $args[0],
            description => $args[1],
        );
    } else {
        $self = $class->SUPER::new(@args);
    }

    return $self;
}

sub flag {
    my $self = shift;
    my ($name, $description) = @_;
    my $ret = $self->flags->add(
        name        => $name,
        description => $description,
    );
    return $ret;
}

sub arg {
    my $self = shift;
    my ($name, $description) = @_;
    my $ret = $self->args->add(
        name        => $name,
        description => $description,
    );
    return $ret;
}

sub command {
    my $self = shift;
    my ($name, $description) = @_;
    if ($self->commands->count == 0) {
        $self->commands->add(
            name => "help",
            description => "Show help.",
        );
    }
    my $ret = $self->commands->add(
        name        => $name,
        description => $description,
        parent      => $self,
    );
    return $ret;
}

sub parse {
    my $self = shift;
    my @argv = @_;

    if (scalar @argv == 0) {
        @argv = @ARGV;
    }

    my ($ret, $exit_code) = $self->_parse(@argv);
    if (defined $exit_code) {
        return $self->terminate->($ret, $exit_code);
    }
    return $ret;
}

sub _parse {
    my $self = shift;
    my @argv = @_;

    if (defined $self->parent) {
        $self->flags->unshift($self->parent->flags->values);
    }

    my $required_but_not_found = {
        map {$_->name => $_} grep {$_->_required} $self->flags->values,
    };
    my $arg_index = 0;
    my $arg_only = 0;
    while (scalar @argv > 0) {
        my $arg = shift @argv;
        if ($arg eq "--") {
            $arg_only = 1;
        } elsif ($arg_only == 0 and $arg =~ /^--(no-)?(\S+?)(=(\S+))?$/) {
            my $no    = $1;
            my $name  = $2;
            my $equal = $3;
            my $val   = $4;

            delete $required_but_not_found->{$name} if exists $required_but_not_found->{$name};
            my $v = $self->flags->get($name);

            if (not defined $v) {
                printf STDERR "%s: error: unknown long flag '--%s', try --help\n", $self->name, $name;
                return undef, 1;
            }

            my $value;
            if ($v->type eq "Bool") {
                $value = defined $no ? 0 : 1;
            } elsif (defined $equal) {
                $value = $val;
            } else {
                $value = shift @argv;
            }

            my ($dummy, $exit) = $v->set_value($value);
            if (defined $exit) {
                return undef, $exit;
            }
        } elsif ($arg_only == 0 and $arg =~ /^-(\S+)$/) {
            my $short_name = $1;
            while (length $short_name > 0) {
                my ($s, $remain) = split //, $short_name, 2;
                my $name;
                foreach my $f ($self->flags->values) {
                    if (defined $f->short_name and $f->short_name eq $s) {
                        $name = $f->name;
                    }
                }
                if (not defined $name) {
                    printf STDERR "%s: error: unknown short flag '-%s', try --help\n", $self->name, $s;
                    return undef, 1;
                }
                delete $required_but_not_found->{$name} if exists $required_but_not_found->{$name};
                my $v = $self->flags->get($name);

                my $value;
                if ($v->type eq "Bool") {
                    $value = 1;
                } else {
                    if (length $remain > 0) {
                        $value = $remain;
                        $remain = "";
                    } else {
                        $value = shift @argv;
                    }
                }

                my ($dummy, $exit) = $v->set_value($value);
                if (defined $exit) {
                    return undef, $exit;
                }
                $short_name = $remain;
            }
        } else {
            if ($arg_index == 0) {
                my $cmd = $self->commands->get($arg);
                if (defined $cmd) {
                    if ($cmd->name eq "help") {
                        $self->flags->get("help")->set_value(1)
                    } else {
                        my @argv_for_command = @argv;
                        @argv = ();

                        if ($self->flags->get("help")) {
                            push @argv_for_command, "--help";
                        }
                        return $cmd->_parse(@argv_for_command);
                    }
                }
            }

            if (not ($arg_index == 0 and $arg eq "help")) {
                if ($arg_index < $self->args->count) {
                    my ($dummy, $exit) = $self->args->get_by_index($arg_index)->set_value($arg);
                    if (defined $exit) {
                        return undef, $exit;
                    }
                    if (not $self->args->get_by_index($arg_index)->is_cumulative) {
                        $arg_index++;
                    }
                } else {
                    printf STDERR "%s: error: unexpected %s, try --help\n", $self->name, $arg;
                    return undef, 1;
                }
            }
        }
    }

    if ($self->flags->get("help")) {
        $self->help;
        return undef, 0;
    }

    if ($self->flags->get("version")) {
        printf STDERR "%s\n", $self->_version;
        return undef, 0;
    }

    foreach my $f ($self->flags->values) {
        if (defined $f->value) {
            next;
        } elsif (defined $f->_envar) {
            my ($dummy, $exit) = $f->set_value($f->_envar);
            if (defined $exit) {
                return undef, $exit;
            }
        } elsif (defined $f->_default) {
            if ($f->type =~ /List$/) {
                foreach my $default (@{$f->_default}) {
                    my ($dummy, $exit) = $f->set_value($default);
                    if (defined $exit) {
                        return undef, $exit;
                    }
                }
            } else {
                my ($dummy, $exit) = $f->set_value($f->_default);
                if (defined $exit) {
                    return undef, $exit;
                }
            }
        } elsif ($f->type =~ /List$/) {
            $f->value([]);
        }
    }
    for (my $i = 0; $i < $self->args->count; $i++) {
        my $arg = $self->args->get_by_index($i);
        if (defined $arg->value) {
            next;
        } elsif (defined $arg->_envar) {
            my ($dummy, $exit) = $arg->set_value($arg->_envar);
            if (defined $exit) {
                return undef, $exit;
            }
        } elsif (defined $arg->_default) {
            if ($arg->type =~ /List$/) {
                foreach my $default (@{$arg->_default}) {
                    my ($dummy, $exit) = $arg->set_value($default);
                    if (defined $exit) {
                        return undef, $exit;
                    }
                }
            } else {
                my ($dummy, $exit) = $arg->set_value($arg->_default);
                if (defined $exit) {
                    return undef, $exit;
                }
            }
        } elsif ($arg->type =~ /List$/) {
            $arg->value([]);
        }
    }

    foreach my $r (values %$required_but_not_found) {
        printf STDERR "%s: error: required flag --%s not provided, try --help\n", $self->name, $r->name;
        return undef, 1;
    }
    for (my $i = 0; $i < $self->args->count; $i++) {
        my $arg = $self->args->get_by_index($i);
        if ($arg->_required and not $arg->_defined) {
            printf STDERR "%s: error: required arg '%s' not provided, try --help\n", $self->name, $arg->name;
            return undef, 1;
        }
    }

    return $self;
}

sub version {
    my $self = shift;
    my ($version) = @_;

    my $f = $self->flags->add(
        name        => 'version',
        description => 'Show application version.',
    )->bool();
    $self->_version($version);
}

sub help_short {
    my $self = shift;
    my @help = ($self->name);

    push @help, "[<flags>]";

    if ($self->commands->count > 1) {
        push @help, "<command>";

        my $has_args = 0;
        foreach my $cmd ($self->commands->get_all) {
            if ($cmd->args->count > 0) {
                $has_args = 1;
            }
        }

        push @help, "[<args> ...]";
    } else {
        foreach my $arg ($self->args->get_all) {
            push @help, sprintf "<%s>", $arg->name;
        }
    }

    return join " ", @help;
}

sub help {
    my $self = shift;
    printf "usage: %s\n", $self->help_short;
    printf "\n";

    if ($self->description ne "") {
        printf "%s\n", $self->description;
        printf "\n";
    }

    printf "%s\n", $self->flags->help;

    if ($self->commands->count > 1) {
        printf "%s\n", $self->commands->help;
    } else {
        if ($self->args->count > 0) {
            printf "%s\n", $self->args->help;
        }
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin - command line options parser (like golang kingpin)

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    $kingpin->flags->get("help")->short('h');
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool;
    my $name    = $kingpin->arg('name', 'Name of user.')->required->string;

    $kingpin->parse;

    # perl sample.pl hello
    printf "name : %s\n", $name;

Automatically generate --help option.

    usage: script.pl [<flags>] <name>

    Flags:
      -h, --help     Show context-sensitive help.
      -v, --verbose  Verbose mode.

    Args:
      <name>  Name of user.

Support sub-command.

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;

    my $register      = $kingpin->command('register', 'Register a new user.');
    my $register_nick = $register->arg('nick', 'Nickname for user.')->required->string;
    my $register_name = $register->arg('name', 'Name for user.')->required->string;

    my $post       = $kingpin->command('post', 'Post a message to a channel.');
    my $post_image   = $post->flag('image', 'Image to post.')->file;
    my $post_channel = $post->arg('channel', 'Channel to post to.')->required->string;
    my $post_text    = $post->arg('text', 'Text to post.')->string_list;

    my $cmd = $kingpin->parse;

    if ($cmd eq 'register') {
        printf "register %s %s\n", $register_nick, $register_name;
    } elsif ($cmd eq 'post') {
        printf "post %s %s %s\n", $post_image, $post_channel, @{$post_text->value};
    } else {
        $kingpin->help;
    }

Help is below.

    usage: script.pl [<flags>] <command> [<args> ...]

    Flags:
      --help  Show context-sensitive help.

    Commands:
      help [<command>...]
        Show help.

      register [<nick>] [<name>]
        Register a new user.

      post [<flags>] [<channel>] [<text>]
        Post a message to a channel.

=head1 DESCRIPTION

Getopt::Kingpin is a command line parser.
It supports flags and positional arguments.

=over

=item *

Simple to use

=item *

Automatically generate help flag (--help).

=back


This module is inspired by Kingpin written in golang.
https://github.com/alecthomas/kingpin

=head1 METHOD

=head2 new()

Create a parser object.
Default script-name is basename($0).

    my $kingpin = Getopt::Kingpin->new;
    my $kingpin = Getopt::Kingpin->new("script-name.pl", "description of script");
    my $kingpin = Getopt::Kingpin->new(
        name        => "script-name.pl",
        description => "description of script",
    );

    # Use hash ref to set description only.
    my $kingpin = Getopt::Kingpin->new({
        description => "description of script",
    });

=head2 flag($name, $description)

Add and return Getopt::Kingpin::Flag object.

    # Define --debug option
    my $debug = $kingpin->flag("debug", "Enable debug mode.");

    # Set $debug to boolean value
    $debug->bool;

    # shorthand
    my $debug = $kingpin->flag("debug", "Enable debug mode.")->bool;

Getopt::Kingpin::Flag object has methods below.

=head3 value()

Get flag value.

    my $name = $kingpin->flag("name", "Set name.")->string;

    # perl script.pl --name 'kingpin'
    printf "%s\n", $name->value;  # -> kingpin

    # simple way
    printf "%s\n", $name;  # -> kingpin

=head3 short()

Set short flag.

    # Define --debug and -d
    my $debug = $kingpin->flag("debug", "Enable debug mode.")->short('-d')->bool;

=head3 default()

The default value can be overridden with the default($value).

    # Set default value to true (1)
    my $debug = $kingpin->flag("debug", "Enable debug mode.")->default(1)->bool;

=head3 override_default_from_envar()

The default value can be overridden with the override_default_from_envar($envar).

    # Set default value to environment value of __DEBUG__
    # export $__DEBUG__=1 to enable debug mode
    my $debug = $kingpin->flag("debug", "Enable debug mode.")->override_default_from_envar("__DEBUG__")->bool;

=head3 required()

Set required.

    my $debug = $kingpin->flag("debug", "Enable debug mode.")->required->bool;

=head3 placeholder()

Set placeholder value for flag in the help.
Here are some examples of flags with various permutations.

    --name=NAME        # flag("name")->string
    --name="Harry"     # flag("name")->default("Harry")->string
    --name=FULL-NAME   # flag("name")->placeholder("FULL-NAME")->string

=head3 hidden()

If set hidden(), flag does not appear in the help.

=head3 types

=head4 bool()

Boolean value. (0 or 1)
Boolean flag has a negative complement: --<name> and --no-<name>.

    # --debug or --no-debug
    my $debug = $kingpin->flag("debug")->bool;

=head4 existing_dir()

Path::Tiny object.

=head4 existing_file()

Path::Tiny object.

=head4 existing_file_or_dir()

Path::Tiny object.

=head4 file()

Path::Tiny object.

=head4 int()

Integer value.

=head4 string()

String value.
It is default type to flag.

=head2 arg($name, $description)

Add and return Getopt::Kingpin::Arg object.

    my $name = $kingpin->arg("name", "Set name")->string;

Getopt::Kingpin::Arg object has methods below.
Below are same as Flag's.

=head3 value()

Get value.

=head3 default()

Set default value.

=head3 override_default_from_envar()

Set default value by environment variable.

=head3 required()

Set required.

=head2 command()

Add sub-command.

    my $post    = $kingpin->command("post", "post image");

=head2 parse()

Parse @arguments.
If @arguments is empty, parse @ARGV.

    # parse @ARGV
    $kingpin->parse;

    # parse @arguments
    $kingpin->parse(@arguments);

If define sub-command, parse() return Getopt::Kingpin::Command object;

    my $kingpin = Getopt::Kingpin->new();
    my $post    = $kingpin->command("post", "post image");
    my $server  = $post->arg("server", "")->string();
    my $image   = $post->arg("image", "")->file();

    my $cmd = $kingpin->parse;
    printf "cmd : %s\n", $cmd;
    printf "cmd : %s\n", $cmd->name;

=head2 _parse()

Parse @_. Internal use only.

=head2 version($version)

Set application version to $version.

=head2 help_short()

Internal use only.

=head2 help()

Print help.

=head1 SEE ALSO

=over

=item *

L<Getopt::Long>

=item *

L<Getopt::Long::Descriptive>

=item *

L<Smart::Options>

=item *

L<MooseX::Getopt::Usage>

=back

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

