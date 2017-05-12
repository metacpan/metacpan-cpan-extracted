package Mail::POP3::Server;

use strict;
use IO::Socket;
use IO::File;
use POSIX;
use IO::Select;

# These are the only commands accepted
my %COMMAND2FUNC = (
    USER => \&commandUSER,
    PASS => \&commandPASS,
    LIST => \&commandLIST,
    STAT => \&commandSTAT,
    RETR => \&commandRETR,
    DELE => \&commandDELE,
    RSET => \&commandRSET,
    QUIT => \&commandQUIT,
    NOOP => \&commandNOOP,
    UIDL => \&commandUIDL,
    TOP => \&commandTOP,
);
my %COMMAND2OKNOLOGIN = (
    USER => 1,
    PASS => 1,
    QUIT => 1,
);
my $CRLF = "\015\012";

sub new {
    my ($class, $config) = @_;
    my $self = {};
    bless $self, $class;
    $self->{CONFIG} = $config;
    $self->{CLIENT_CRYPT_PASSWD} = '';
    $self->{MAILDIR} = "";
    $self->{RECEIVED_HEADER} = ""; # these two are set in commandUSER
    $self->{ADDEDBYTES} = 0;
    $self->{MAILBOX_OPENED} = 0;
    $self->{PASSWORD_GIVEN} = 0;
    $self->{AUTH_TYPE} = $self->{CONFIG}->{auth_type};
    $self;
}

sub _make_closure {
    my ($self, $subref) = @_;
    sub { $subref->($self) };
}

# Do the security checks and then get the first command
sub start {
    my ($self, $input_fh, $output_fh, $client_ip) = @_;
    $self->{CLIENT_IP} = $client_ip;
    $self->{CLIENT_FQDN} = $self->peer_lookup($self->{CLIENT_IP});
    $self->{INPUT_FH} = $input_fh;
    $self->{OUTPUT_FH} = $output_fh;
    # Set the default output file handle
    select $self->{OUTPUT_FH};
    $| = 1;
    # Try and catch anything nasty and restore mailbox. This can
    # lead to emails being downloaded more than once but at least they
    # shouldn't be lost.
    local $SIG{HUP} = $self->_make_closure(\&force_shutdown);
    local $SIG{TERM} = $self->_make_closure(\&force_shutdown);
    local $SIG{PIPE} = $self->_make_closure(\&force_shutdown);
    local $SIG{USR1} = $self->_make_closure(\&force_shutdown)
      unless $^O =~ /MSWin32/;
    local $SIG{SEGV} = $self->_make_closure(\&force_shutdown);
    # Catch kernel alarms and close gracefully if the client stalls
    local $SIG{ALRM} = $self->_make_closure(\&force_shutdown);
    my $security_connection = $self->{CONFIG}->{connection_class}->new(
        $self->{CONFIG}
    );
    my ($was_ok, $log_entry) = $security_connection->check(
        $client_ip,
        $self->{CLIENT_FQDN},
    );
    map { $self->log_entry($_) } @$log_entry if $self->{CONFIG}->{debug} == 1;
    $self->shutdown unless $was_ok;
    # Log the connection IP and time if global debugging is on
    if ($self->{CONFIG}->{debug} and $self->{CONFIG}->{debug} == 1) {
        $self->log_entry("$self->{CLIENT_IP}\tconnected at");
    }
    # Send the mpopd greeting.
    print "+OK $self->{CONFIG}->{greeting}$CRLF";
    while (1) {
        my $request = "";
        my $char;
        my $select = IO::Select->new;
        $select->add($input_fh);
        while (1) {
            # Set the kernel alarm for $self->{CONFIG}->{timeout}
            # seconds and then only wait that long for the next command
            # from the client.
            # The whole read process is eval'ed. See man perlfunc -> portability
            eval {
                if ($^O !~ /MSWin32/) {
                  # can_read doesn't work on win32! rely on it just blocking
                  die "alarm\n"
                    unless $select->can_read($self->{CONFIG}->{timeout});
                }
                sysread $input_fh, $char, 1;
            };
            if ($@) {
                $self->force_shutdown('timeout') if $@ eq "alarm\n";
            } else {
                last unless defined $char;
                last if $char eq "\012";
                $request .= $char;
# commented because one should "be liberal in what one accepts"
#                $self->force_shutdown('line too long') if (length($request) > 50);
            }
        }
        $self->force_shutdown unless defined $char;
        # remove all but alphanumeric chars and whitespace from the
        # request, and only accept 3-50 chars total (UIDL could be long'ish)
# commented because one should "be liberal in what one accepts"
#        $request =~ s/^([\s\w]{3,50})/$1/g;
        $request =~ s/\r|\n//g;
        my ($command, $arg, $arg1) = split /\s+/, $request, 3;
	$arg = '' unless defined $arg;
	$arg1 = '' unless defined $arg1;
        $command = uc $command;
        $self->log_user_entry("$command  $arg  $arg1");
        # Close and warn if an invalid command is received
        unless ($COMMAND2FUNC{$command}) {
            $self->log_entry("$self->{CLIENT_IP}\tWARN no command sent, port scan? at") if $self->{CONFIG}->{debug} == 1;
            $self->force_shutdown("So, that's the way you want it... :\(");
        }
        if (!$COMMAND2OKNOLOGIN{$command} and !$self->{PASSWORD_GIVEN}) {
            $self->send_to_user("-ERR not logged in yet!");
            next;
        }
        $COMMAND2FUNC{$command}->($self, $arg, $arg1);
    }
}

sub commandUSER {
    my ($self, $arg, $arg1) = @_;
    my $user_name = $arg;
    $self->{CLIENT_USERNAME} = $user_name;
    if ($self->{CONFIG}->{addreceived}->{$user_name}) {
        $self->{RECEIVED_HEADER} =
            "Received: from $self->{CONFIG}->{receivedfrom}$CRLF" .
            "    by mpopd V$self->{CONFIG}->{mpopd_conf_version}$CRLF" .
            "    for $user_name; " .
                localtime(time) .
                " $self->{CONFIG}->{timezone}$CRLF";
        $self->{ADDEDBYTES} = length($self->{RECEIVED_HEADER});
    }
    $self->bad_user unless $self->{CONFIG}->{user_check}->(
        $self->{CONFIG},
        $user_name,
        $self->{CLIENT_FQDN},
    );
    $self->log_user_open($user_name);
    $self->log_user_entry("USER  $user_name");
    $self->send_to_user("+OK $user_name send me your password");
}

sub commandPASS {
    my ($self, $arg, $arg1) = @_;
    if ($self->{MAILBOX_OPENED}) {
        $self->send_to_user("-ERR already authenticated");
        return;
    }
    unless ($self->{CLIENT_USERNAME}) {
        $self->send_to_user("-ERR I need your USER name first!");
        return;
    }
    # Check the password supplied
    $self->{PASSWORD_GIVEN} = $self->{CONFIG}->{password_check}->(
        $self->{CONFIG},
        $self->{CLIENT_USERNAME},
        $self->{CLIENT_FQDN},
        $arg,
    );
    unless ($self->{PASSWORD_GIVEN}) {
        $self->send_to_user(
            "-ERR access denied $self->{CLIENT_USERNAME} $arg"
        );
        $self->shutdown;
    }
    load_class($self->{CONFIG}->{mailbox_class});
    $self->{MAILBOX} = $self->{CONFIG}->{mailbox_class}->new(
        $self->{CLIENT_USERNAME},
        $arg,
        $self->{CONFIG}->{mailbox_args}->(
            $self->{CONFIG},
            $self->{CLIENT_USERNAME},
            $self->{CLIENT_FQDN},
        ),
    );
    my $lockcnt = 0;
    until ($self->{MAILBOX}->lock_acquire) {
        if (
            !$self->{CONFIG}->{retry_on_lock} or
            $self->{CONFIG}->{retry_on_lock} == $lockcnt
        ) {
            $self->send_to_user("-ERR Could not get a lock on mailbox!");
            return;
        }
        $lockcnt++; # here so if retry == 1, don't drop out first time
        sleep 1;
    }
    $self->send_to_user("+OK thanks $self->{CLIENT_USERNAME}...");
    $self->{MAILBOX_OPENED} = 1;
}

sub load_class {
    my ($class) = @_;
    my $class_file = $class;
    $class_file =~ s#::#/#g;
    $class_file .= '.pm';
    require $class_file;
}

sub commandSTAT {
    my ($self, $arg, $arg1) = @_;
    $self->send_to_user(
        "+OK ".$self->{MAILBOX}->messages." ".$self->{MAILBOX}->octets
    );
}

sub commandLIST {
    my ($self, $arg, $arg1) = @_;
    if ($arg) {
        if (!$self->{MAILBOX}->is_valid($arg)) {
            $self->send_to_user("-ERR message $arg is not valid");
            return;
        }
        $self->send_to_user("+OK $arg " . $self->{MAILBOX}->octets($arg));
        return;
    }
    $self->send_to_user("+OK ".$self->{MAILBOX}->messages." messages");
    for (1..$self->{MAILBOX}->messages) {
        if (!$self->{MAILBOX}->is_deleted($_)) {
            print "$_ " . $self->{MAILBOX}->octets($_) . " octets$CRLF";
        }
    }
    print ".$CRLF";
}

# Send the email requested by $arg to the client
sub commandRETR {
    my ($self, $arg, $arg1) = @_;
    if (!$self->{MAILBOX}->is_valid($arg)) {
        $self->send_to_user("-ERR message $arg is not valid");
        return;
    }
    my $octets = $self->{MAILBOX}->octets($arg) + $self->{ADDEDBYTES};
    print "+OK $octets octets$CRLF";
    print $self->{RECEIVED_HEADER};
    $self->{MAILBOX}->retrieve($arg, $self->{OUTPUT_FH});
    print ".$CRLF";
    $self->log_user_entry("RETRieved\t$octets");
}

sub commandDELE {
    my ($self, $arg, $arg1) = @_;
    if (!$self->{MAILBOX}->is_valid($arg)) {
        $self->send_to_user("-ERR message $arg is not valid");
        return;
    }
    $self->send_to_user("+OK message $arg flagged for deletion");
    $self->{MAILBOX}->delete($arg);
}

sub commandNOOP {
    my ($self, $arg, $arg1) = @_;
    $self->send_to_user("+OK");
}

sub commandRSET {
    my ($self, $arg, $arg1) = @_;
    $self->{MAILBOX}->reset;
    $self->send_to_user("+OK all message flags reset");
}

sub commandUIDL {
    my ($self, $arg, $arg1) = @_;
#print Data::Dumper::Dumper($self->{MAILBOX});
    if ($arg) {
        if (!$self->{MAILBOX}->is_valid($arg)) {
            $self->send_to_user("-ERR message $arg is not valid");
            return;
        }
        # must be valid
        $self->send_to_user("+OK $arg " . $self->{MAILBOX}->uidl($arg));
        return;
    }
    $self->send_to_user("+OK unique-id listing follows");
    $self->{MAILBOX}->uidl_list($self->{OUTPUT_FH});
}

sub commandTOP {
    my ($self, $arg, $arg1) = @_;
    my $cnt;
    if (!$self->{MAILBOX}->is_valid($arg)) {
        $self->send_to_user("-ERR message $arg is not valid");
        return;
    }
    unless ($arg1 >= 0) {
        $self->send_to_user("-ERR TOP with wrong number of lines ($arg1)");
        return;
    }
    $self->send_to_user("+OK top of message $arg follows");
    print $self->{RECEIVED_HEADER};
    my $top_bytes =
        $self->{MAILBOX}->top($arg, $self->{OUTPUT_FH}, $arg1) +
        $self->{ADDEDBYTES};
    print ".$CRLF";
    $self->log_user_entry(
        "TOPped\t$top_bytes"
    );
}

sub commandQUIT {
    my ($self, $arg, $arg1) = @_;
    if (!$self->{CONFIG}->{user_debug}->{$self->{CLIENT_USERNAME}}) {
        eval { $self->{MAILBOX}->flush_delete; };
        if ($@) {
            chomp $@;
            $self->log_entry(
                "$self->{CLIENT_IP}\t$self->{CLIENT_USERNAME} $@"
            ) if $self->{CONFIG}->{debug} == 1;
        }
    }
    $self->force_shutdown("+OK TTFN $self->{CLIENT_USERNAME}...");
}

# Reject bogus login name and exit or fake a password auth
sub bad_user {
    my $self = shift;
    $self->log_entry("$self->{CLIENT_IP}\tBOGUS user name given at") if $self->{CONFIG}->{debug} == 1;
    if ($self->{CONFIG}->{reject_bogus_user} == 1) {
        print "-ERR no record here of $self->{CLIENT_USERNAME},...$CRLF";
        $self->shutdown;
    } else {
        my $request;
        print "+OK $self->{CLIENT_USERNAME} send me your password....$CRLF";
        alarm 10;
        sysread $self->{INPUT_FH}, $request, 1;
        alarm 0;
        print "-ERR access denied$CRLF";
        $self->shutdown;
    }
}

# do a reverse lookup
sub peer_lookup {
    my ($self, $ip) = @_;
    lc gethostbyaddr(inet_aton($ip), IO::Socket::AF_INET);
}

# Optional per-user brief logging of connection times
sub log_user_open {
    my ($self, $user_name) = @_;
    return unless defined $self->{CONFIG}->{user_log}->{$user_name};
    if (!-d $self->{CONFIG}->{user_log_dir}) {
        mkdir $self->{CONFIG}->{user_log_dir};
        chmod 01777, $self->{CONFIG}->{user_log_dir};
    }
    my $logfile = "$self->{CONFIG}->{user_log_dir}/${user_name}_log";
    $self->{USERLOG_FH} = IO::File->new(
        ">>$logfile"
    );
    eval {
        # in case we're on Windoze...
        chown((getpwnam $self->{CLIENT_USERNAME})[2], $logfile);
        chmod 0600, $logfile;
    };
    $self->log_user_entry("CONNECTION OPENED");
}

sub log_user_close {
    my ($self) = @_;
    return unless
        $self->{USERLOG_FH} and
        defined $self->{CONFIG}->{user_log}->{$self->{CLIENT_USERNAME}};
    close $self->{USERLOG_FH};
}

# Record mpopd conversations in the individual mailbox log
sub log_user_entry {
    my ($self, $response) = @_;
    return unless
        $self->{USERLOG_FH} and
        $self->{CONFIG}->{user_log}->{$self->{CLIENT_USERNAME}} and
        $self->{CONFIG}->{user_log}->{$self->{CLIENT_USERNAME}} == 2;
    if ($response =~ /^PASS\s+(.*)/ and $self->{CONFIG}->{passsecret}) {
        $response =~ s/$1/******/;
    }
    $self->{USERLOG_FH}->print(localtime() . " $response\n");
}

# CRLF is added here, and also logged if $log_suppress is false
sub send_to_user {
    my ($self, $text, $log_suppress) = @_;
    print "$text$CRLF";
    $self->log_user_entry($text) unless $log_suppress;
}

# Close the mailbox in a sane state and close the connection
sub force_shutdown {
    my ($self, $signoff) = @_;
    if ($signoff) {
        if ($signoff eq "ALRM") {
            $signoff = "Haven't got all day you know...";
        } elsif ($signoff eq "USR1") {
            $signoff = "My parent told me to close...";
        }
        $self->send_to_user(
            $signoff
        );
    } else {
        $self->send_to_user(
            "Sorry your time is up :)"
        );
    }
    $self->log_user_close;
    if ($self->{MAILBOX_OPENED}) {
        $self->{MAILBOX}->lock_release;
    }
    $self->shutdown;
}

# Write something in the main mpopd log
sub log_entry {
    my ($self, $error) = @_;
    return unless defined $self->{CONFIG}->{debug_log};
    $> = 0;
    unless ($self->{DEBUG_FH}) {
        my ($debuglog_dir) = $self->{CONFIG}->{debug_log} =~ /^(.+)\//;
        if (!-d $debuglog_dir) {
            mkdir $debuglog_dir, 0700;
        }
        $self->{DEBUG_FH} = IO::File->new(">>$self->{CONFIG}->{debug_log}")
            or die "open >>$self->{CONFIG}->{debug_log}: $!\n";
        my $gid = $^O =~ /MSWin32/ ? 0 : getgrnam("root");
        chown 0, $gid, $self->{CONFIG}->{debug_log};
        chmod 0600, $self->{CONFIG}->{debug_log};
    }
    my $logtime = localtime(time);
    $self->{DEBUG_FH}->print("$error\t$logtime\n");
    $> = $self->{CLIENT_USER_ID} if $self->{CLIENT_USER_ID};
}

# Clean up and exit
sub shutdown {
    my $self = shift;
    close $self->{INPUT_FH};
    exit(0);
}

1;
