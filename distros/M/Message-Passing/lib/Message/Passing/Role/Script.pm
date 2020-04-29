package Message::Passing::Role::Script;
use Moo::Role;
use MooX::Options;
use MooX::Types::MooseLike::Base qw/ Bool Str /;
use Getopt::Long qw(:config pass_through);
use POSIX qw(setuid setgid);
use Message::Passing::DSL;
use Carp qw/ confess /;
use namespace::clean -except => 'meta';

requires 'build_chain';

option daemonize => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
    doc => 'pass 1 to daemonize',
);

option io_priority => (
    isa => sub { $_[0] =~ /^(none|be|rt|idle)$/ },
    coerce => sub { lc $_[0] },
    is => 'ro',
    predicate => "_has_io_priority",
    format => 's',
    doc => 'the IO priority to run the script at: none, be, rt, idle',
);

option user => (
    isa => Str,
    is => 'ro',
    predicate => "_has_user",
    format => 's',
    doc => 'changes the user the script is running as',
);

option pid_file => (
    isa => Str,
    is => 'ro',
    predicate => "_has_pid_file",
    format => 's',
    doc => 'the name of the pid file including the directory',
);

sub daemonize_if_needed {
    my ($self) = @_;
    my $fh;
    if ($self->_has_pid_file) {
        open($fh, '>', $self->pid_file)
            or confess("Could not open pid file '". $self->pid_file . "': $?");
    }
    if ($self->daemonize) {
        fork && exit;
        POSIX::setsid();
        fork && exit;
        chdir '/';
        umask 0;
    }
    if ($fh) {
        print $fh $$ . "\n";
        close($fh);
    }
}

sub change_uid_if_needed {
    my $self = shift;
    my ($uid, $gid);
    if ($self->_has_user) {
        my $user = $self->user;
        $uid = getpwnam($user) ||
            die("User '$user' does not exist, cannot become that user!\n");
        (undef, undef, undef, $gid ) = getpwuid($uid);
    }
    if ($gid) {
        setgid($gid) || die("Could not setgid to '$gid' are you root? : $!\n");
    }
    if ($uid) {
        setuid($uid) || die("Could not setuid to '$uid' are you root? : $!\n");
    }
}

sub set_io_priority_if_needed {
    my $self = shift;
    return unless $self->_has_io_priority;
    require Linux::IO_Prio;
    my $sym = do {
        no strict 'refs';
        &{"Linux::IO_Prio::IOPRIO_CLASS_" . uc($self->io_priority)}();
    };
    Linux::IO_Prio::ioprio_set(Linux::IO_Prio::IOPRIO_WHO_PROCESS(), $$,
        Linux::IO_Prio::IOPRIO_PRIO_VALUE($sym, 0)
    );
}

sub start {
    my $class = shift;
    my $instance = $class->new_with_options(@_);
    $instance->set_io_priority_if_needed;
    $instance->change_uid_if_needed;
    $instance->daemonize_if_needed;
    run_message_server $instance->build_chain;
}

1;

=head1 NAME

Message::Passing::Role::Script - Handy role for building messaging scripts.

=head1 SYNOPSIS

    # my_message_passer.pl
    package My::Message::Passer;
    use Moo;
    use MooX::Options;
    use MooX::Types::MooseLike::Base qw/ Bool /;
    use Message::Passing::DSL;

    with 'Message::Passing::Role::Script';

    option foo => (
        is => 'ro',
        isa => Bool,
    );

    sub build_chain {
        my $self = shift;
        message_chain {
            input example => ( output_to => 'test_out', .... );
            output test_out => ( foo => $self->foo, ... );
        };
    }

    __PACKAGE__->start unless caller;
    1;

=head1 DESCRIPTION

This role can be used to make simple message passing scripts.

The user implements a L<MooX::Options> type script class, with a
C<build_chain> method, that builds one or more
L<Message::Passing> chains and returns them.

    __PACKAGE__->start unless caller;

is then used before the end of the script.

This means that when the code is run as a script, it'll parse
the command line options, and start a message passing server..

=head1 REQUIRED METHODS

=head1 build_chain

Return a chain of message processors, or an array reference with
multiple chains of message processors.

=head1 ATTRIBUTES

=head2 daemonize

Do a double fork and lose controlling terminal.

Used to run scripts in the background.

=head2 io_priority

The IO priority to run the script at..

Valid values for the IO priority are:

=over

=item none

=item be

=item rt

=item idle

=back

=head2 user

Changes the user the script is running as. You probably need to run the script as root for this option to work.

=head2 pid_file

Write a pid file out. Useful for running Message::Passing scripts as daemons and/or from init.d scripts.

=head1 METHODS

=head2 start

Called as a class method, it will build the current class as a
command line script (parsing ARGV), setup the daemonization options,
call the ->build_chain method supplied by the user to build the
chains needed for this application.

Then enters the event loop and never returns.

=head2 change_uid_if_needed

Tries to change uid if the --user option has been supplied

=head2 daemonize_if_needed

Tires to daemonize if the --daemonize option has been supplied

=head2 set_io_priority_if_needed

Tries to set the process' IO priority if the --io_priority option
has been supplied.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API -
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut
