package Lim::CLI;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);
use Module::Find qw(findsubmod);
use Fcntl qw(:seek);
use File::Temp ();
use IO::File ();
use Digest::SHA ();

use Lim ();
use Lim::Error ();
use Lim::Agent ();
use Lim::Plugins ();

use IO::Handle ();
use AnyEvent::Handle ();

=encoding utf8

=head1 NAME

Lim::CLI - The command line interface to Lim

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our @BUILTINS = (qw(quit exit help));

=head1 SYNOPSIS

=over 4

use Lim::CLI;

$cli = Lim::CLI->new(...);

=back

=head1 DESCRIPTION

This is the CLI that takes the input from the user and sends it to the plugin in
question. It uses L<AnyEvent::ReadLine::Gnu> if it is available and that enables
command line completion and history functions. It will load all plugins present
on the system and use their CLI part if it exists.

Failing to have a supported readline module it will use a basic
L<AnyEvent::Handle> to read each line of input and process it.

Built in commands that can not be used by any plugins are:

=over 4

quit - Will quit the CLI
exit - Will exit the relative section or quit the CLI
help - Will show help for the relative section where the user is

=back

=head1 METHODS

=over 4

=item $cli = Lim::CLI->new(key => value...)

Create a new Lim::CLI object.

=over 4

=item on_quit => $callback->($cli_object)

Callback to call when the CLI quits, either with the user doing CTRL-D, CTRL-C
or the command 'quit'.

=back

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        cli => {},
        busy => 0,
        no_completion => 0,
        prompt => 'lim> '
    };
    bless $self, $class;
    weaken($self->{logger});
    my $real_self = $self;
    weaken($self);

    unless (defined $args{on_quit}) {
        confess __PACKAGE__, ': Missing on_quit';
    }
    unless (ref($args{on_quit}) eq 'CODE') {
        confess __PACKAGE__, ': on_quit is not CODE';
    }
    $self->{on_quit} = $args{on_quit};

    foreach my $module (qw(Lim::Agent)) {
        my $name = lc($module->Name);

        if (exists $self->{cli}->{$name}) {
            Lim::WARN and $self->{logger}->warn('Can not load internal CLI module ', $module, ': name ', $name, ' already in use');
            next;
        }

        if (defined (my $obj = $module->CLI(cli => $self))) {
            $self->{cli}->{$name} = {
                name => $name,
                module => $module,
                obj => $obj
            };
        }
    }

    foreach my $module (Lim::Plugins->instance->LoadedModules) {
        my $name = lc($module->Name);

        if (exists $self->{cli}->{$name}) {
            Lim::WARN and $self->{logger}->warn('Can not use CLI module ', $module, ': name ', $name, ' already in use');
            next;
        }

        if (defined (my $obj = $module->CLI(cli => $self))) {
            $self->{cli}->{$name} = {
                name => $name,
                module => $module,
                obj => $obj
            };
        }
    }

    eval {
        require AnyEvent::ReadLine::Gnu;
    };
    unless ($@) {
        $self->{rl} = AnyEvent::ReadLine::Gnu->new(
            prompt => 'lim> ',
            on_line => sub {
                unless (defined $self) {
                    return;
                }

                $self->process(@_);
            });

        $self->{rl}->Attribs->{completion_entry_function} = $self->{rl}->Attribs->{list_completion_function};
        $self->{rl}->Attribs->{attempted_completion_function} = sub {
            my ($text, $line, $start, $end) = @_;

            unless (defined $self) {
                return;
            }

            my @parts = split(/\s+/o, substr($line, 0, $start));
            my $builtins = 0;

            if ($self->{current}) {
                unshift(@parts, $self->{current}->{name});
                $builtins = 1;
            }

            if (scalar @parts) {
                my $part = shift(@parts);

                if (exists $self->{cli}->{$part}) {
                    my $cmd = $self->{cli}->{$part}->{module}->Commands;

                    while (defined ($part = shift(@parts))) {
                        unless (exists $cmd->{$part} and ref($cmd->{$part}) eq 'HASH') {
                            if ($self->{no_completion}++ == 2) {
                                if (ref($cmd->{$part}) eq 'ARRAY') {
                                    if (@{$cmd->{$part}} == 1) {
                                        $self->println('completion finished: ', $part, '<RET> - ', $cmd->{$part}->[0]);
                                    }
                                    elsif (@{$cmd->{$part}} == 2) {
                                        $self->println('completion finished: ', $part, ' ', $cmd->{$part}->[0], ' <RET> - ', $cmd->{$part}->[1]);
                                    }
                                    else {
                                        $self->println('no completion found');
                                    }
                                }
                                else {
                                    $self->println('no completion found');
                                }
                            }
                            $self->{rl}->Attribs->{completion_word} = [];
                            return ();
                        }

                        $builtins = 0;
                        $cmd = $cmd->{$part};
                    }
                    if ($builtins) {
                        $self->{rl}->Attribs->{completion_word} = [keys %{$cmd}, @BUILTINS];
                    }
                    else {
                        $self->{rl}->Attribs->{completion_word} = [keys %{$cmd}];
                    }
                }
                else {
                    if ($self->{no_completion}++ == 2) {
                        $self->println('no completion found');
                    }
                    $self->{rl}->Attribs->{completion_word} = [];
                    return;
                }
            }
            else {
                $self->{rl}->Attribs->{completion_word} = [keys %{$self->{cli}}, @BUILTINS];
            }
            $self->{no_completion} = 0;
            return ();
        };

        $self->{rl}->StifleHistory(Lim::Config->{cli}->{history_length});
        if (Lim::Config->{cli}->{history_file} and -r Lim::Config->{cli}->{history_file}) {
            $self->{rl}->ReadHistory(Lim::Config->{cli}->{history_file});
            $self->{rl}->history_set_pos($self->{rl}->Attribs->{history_length});
        }
    }
    else {
        $self->{stdin_watcher} = AnyEvent::Handle->new(
            fh => \*STDIN,
            on_error => sub {
            my ($handle, $fatal, $msg) = @_;
            $handle->destroy;
            unless (defined $self) {
                return;
            }
            $self->{on_quit}($self);
        },
        on_eof => sub {
            my ($handle) = @_;
            $handle->destroy;
            unless (defined $self) {
                return;
            }
            $self->{on_quit}($self);
        },
        on_read => sub {
            my ($handle) = @_;

            $handle->push_read(line => sub {
                shift;
                unless (defined $self) {
                    return;
                }
                $self->process(@_);
            });
        });

        IO::Handle::autoflush STDOUT 1;
    }

    if (defined (my $appender = Log::Log4perl->appender_by_name('LimCLI'))) {
        Log::Log4perl->eradicate_appender('Screen');
        $appender->{cli} = $self;
        weaken($appender->{cli});
    }

    $self->println('Welcome to LIM ', $Lim::VERSION, ' command line interface');
    $self->prompt;

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);

    if (exists $self->{rl}) {
        if (Lim::Config->{cli}->{history_file}) {
            $self->{rl}->WriteHistory(Lim::Config->{cli}->{history_file});
        }
    }

    delete $self->{current};
    delete $self->{rl};
    delete $self->{stdin_watcher};
    delete $self->{cli};
}

=item $cli->process($line)

Process a line of input, called from the input watcher
(L<AnyEvent::ReadLine::Gnu> or L<AnyEvent::Handle>).

=cut

sub process {
    my ($self, $line) = @_;
    my ($cmd, $args);

    if ($self->{busy}) {
        return;
    }

    if (defined $line) {
        ($cmd, $args) = split(/\s+/o, $line, 2);
        $cmd = lc($cmd);
    }
    else {
        $cmd = 'quit';
    }

    if ($cmd eq 'quit') {
        $self->{on_quit}($self);
        return;
    }
    elsif ($cmd eq 'exit') {
        if (exists $self->{current}) {
            delete $self->{current};
            $self->set_prompt('lim> ');
            $self->prompt;
        }
        else {
            $self->{on_quit}($self);
            return;
        }
    }
    elsif ($cmd eq 'help') {
        if (exists $self->{current}) {
            $self->print_command_help($self->{current}->{module}->Commands);
        }
        else {
            my @cmds = keys %{$self->{cli}};
            push(@cmds, @BUILTINS);
            $self->println('Available commands: ', join(' ', sort @cmds));
        }
        $self->prompt;
    }
    else {
        if ($cmd) {
            if (exists $self->{current}) {
                if ($self->{current}->{module}->Commands->{$cmd} and
                    $self->{current}->{obj}->can($cmd))
                {
                    $self->{busy} = 1;
                    $self->set_prompt('');
                    $self->{current}->{obj}->$cmd($args);
                }
                else {
                    $self->unknown_command($cmd);
                }
            }
            elsif (exists $self->{cli}->{$cmd}) {
                if ($args) {
                    my $current = $self->{cli}->{$cmd};
                    ($cmd, $args) = split(/\s+/o, $args, 2);
                    $cmd = lc($cmd);

                    if ($current->{module}->Commands->{$cmd} and
                        $current->{obj}->can($cmd))
                    {
                        $self->{busy} = 1;
                        $self->set_prompt('');
                        $current->{obj}->$cmd($args);
                    }
                    else {
                        $self->unknown_command($cmd);
                    }
                }
                else {
                    $self->{current} = $self->{cli}->{$cmd};
                    $self->set_prompt('lim'.$self->{current}->{obj}->Prompt.'> ');
                    $self->prompt;
                }
            }
            else {
                $self->unknown_command($cmd);
            }
        }
        else {
            $self->prompt;
        }
    }
}

=item $cli->prompt

Print the prompt, called from C<process>.

=cut

sub prompt {
    my ($self) = @_;

    if (exists $self->{rl}) {
        return;
    }

    $self->print($self->{prompt});
    IO::Handle::flush STDOUT;
}

=item $cli->set_prompt

Set the prompt, called from C<process>.

=cut

sub set_prompt {
    my ($self, $prompt) = @_;

    $self->{prompt} = $prompt;

    if (exists $self->{rl}) {
        $self->{rl}->hide;
        $AnyEvent::ReadLine::Gnu::prompt = $prompt;
        $self->{rl}->show;
    }

    $self;
}

=item $cli->clear_line

Reset the input.

=cut

sub clear_line {
    my ($self) = @_;

    if (exists $self->{rl}) {
        $self->{rl}->replace_line('', 1);
        $self->{rl}->hide;
        $self->{rl}->show;
    }
    else {
        $self->{stdin_watcher}->{rbuf} = '';
        print "\r";
        IO::Handle::flush STDOUT;
    }

    $self;
}

=item $cli->unknown_command

Prints the "unknown command" error if the command can not be found.

=cut

sub unknown_command {
    my ($self, $cmd) = @_;

    $self->println('unknown command: ', $cmd);
    $self->prompt;

    $self;
}

=item $cli->print

Print some output, called from L<Lim::Component::CLI> and here.

=cut

sub print {
    my $self = shift;

    if (exists $self->{rl}) {
        $self->{rl}->print(@_);
    }
    else {
        foreach (@_) {
            print;
            IO::Handle::flush STDOUT;
        }
    }

    $self;
}

=item $cli->println

Print some output and add a newline, called from L<Lim::Component::CLI> and
here.

=cut

sub println {
    my $self = shift;

    if (exists $self->{rl}) {
        $self->{rl}->hide;
        $self->{rl}->print(@_, "\n");
        $self->{rl}->show;
    }
    else {
        foreach (@_) {
            print;
            IO::Handle::flush STDOUT;
        }
        print "\n";
        IO::Handle::flush STDOUT;
    }

    $self;
}

=item $cli->print_command_help($module->Commands)

Print the help for all commands from a plugin.

=cut

sub print_command_help {
    my ($self, $commands, $level) = @_;
    my $space = ' ' x ($level * 4);

    if (ref($commands) eq 'HASH') {
        foreach my $key (sort (keys %$commands)) {
            if (ref($commands->{$key}) eq 'HASH') {
                $self->println($space, $key);
                $self->print_command_help($commands->{$key}, $level+1);
            }
            elsif (ref($commands->{$key}) eq 'ARRAY') {
                if (@{$commands->{$key}} == 1) {
                    $self->println($space, $key, ' - ', $commands->{$key}->[0]);
                }
                elsif (@{$commands->{$key}} == 2) {
                    $self->println($space, $key, ' ', $commands->{$key}->[0], ' - ', $commands->{$key}->[1]);
                }
                else {
                    $self->println($space, $key, ' - unknown/invalid help');
                }
            }
            else {
                $self->println($space, $key, ' - no help');
            }
        }
    }

    $self;
}

=item $cli->Successful

Called from L<Lim::Component::CLI> when a command was successful.

=cut

sub Successful {
    my ($self) = @_;

    $self->{busy} = 0;
    if (exists $self->{current}) {
        $self->set_prompt('lim'.$self->{current}->{obj}->Prompt.'> ');
    }
    else {
        $self->set_prompt('lim> ');
    }
    $self->prompt;
    return;
}

=item $cli->Error($LimError || @error_text)

Called from L<Lim::Component::CLI> when a command issued an error. The error can
be a L<Lim::Error> object or list of strings that will be joined to produce an
error string.

=cut

sub Error {
    my $self = shift;

    $self->print('Command Error: ', ( scalar @_ > 0 ? '' : 'unknown' ));
    foreach (@_) {
        if (blessed $_ and $_->isa('Lim::Error')) {
            $self->print($_->toString);
        }
        else {
            $self->print($_);
        }
    }
    $self->println;

    $self->{busy} = 0;
    if (exists $self->{current}) {
        $self->set_prompt('lim'.$self->{current}->{obj}->Prompt.'> ');
    }
    else {
        $self->set_prompt('lim> ');
    }
    $self->prompt;
}

=item $cli->Editor($content)

Call up an editor for the C<$content> provided. Will return the new content if
it has changed or undef on error or if nothing was changed.

Will use L<Lim::Config>->{cli}->{editor} which will be the environment variable
EDITOR or what ever your configure it to be.

=cut

sub Editor {
    my ($self, $content) = @_;
    my $tmp = File::Temp->new;
    my $sha = Digest::SHA::sha1_base64($content);

    Lim::DEBUG and $self->{logger}->debug('Editing ', $tmp->filename, ', hash before ', $sha);

    print $tmp $content;
    $tmp->flush;

    # TODO check if editor exists

    if (system(Lim::Config->{cli}->{editor}, $tmp->filename)) {
        Lim::DEBUG and $self->{logger}->debug('EDITOR returned failure');
        return;
    }

    my $fh = IO::File->new;
    unless ($fh->open($tmp->filename)) {
        Lim::DEBUG and $self->{logger}->debug('Unable to reopen temp file');
        return;
    }

    $fh->seek(0, SEEK_END);
    my $tell = $fh->tell;
    $fh->seek(0, SEEK_SET);
    unless ($fh->read($content, $tell) == $tell) {
        Lim::DEBUG and $self->{logger}->debug('Unable to read temp file');
        return;
    }

    if ($sha eq Digest::SHA::sha1_base64($content)) {
        Lim::DEBUG and $self->{logger}->debug('No change detected, checksum is the same');
        return;
    }

    return $content;
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::CLI

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::CLI
