package Device::Power::Synaccess::NP05B;

# ABSTRACT: Manage and monitor the Synaccess NP-05B networked power strip

use strict;
use warnings;
use Net::Telnet;
our $VERSION = '1.03';

=head1 NAME

Device::Power::Synaccess::NP05B -- Manage and monitor the Synaccess NP05B networked power strip

=head1 SYNOPSIS

    my $np = Device::Power::Synaccess::NP05B->new(addr => '10.0.0.1');

    # must initiate a connection and log in before issuing commands:
    ($ok, $err) = $np->connect;
    ($ok, $err) = $np->login;

    # are we still connected?
    $np->is_connected or die "whoops";

    # get the status of the connection:
    say $np->cond;

    # get the on/off status of the power outlets:
    ($ok, $hashref) = $np->power_status;

    # turn on outlet 2:
    ($ok, $err) = $np->power_set(2, 1)

    # get the full system status, including network attributes:
    ($ok, $hashref) = $np->status;

    # must log out cleanly or device can get confused:
    ($ok, $err) = $np->logout;
    

=head1 ABSTRACT

Synaccess makes a power strip product called the C<NP-05B> which can be remotely accessed and controlled via telnet or http.

C<Device::Power::Synaccess::NP05B> accesses the C<NP-05B> via telnet and provides programmatic access to some of its functions, notably system status and turning on/off specific power outlets.

=head1 METHODS

=head2 new

    my $np = Device::Power::Synaccess::NP05B->new();
    my $np = Device::Power::Synaccess::NP05B->new(addr => '10.0.0.6', ...);

Instantiates an C<Device::Power::Synaccess> object.  It takes some optional named parameters:

=over 4

=item * addr => string

Specify the IP address of the C<NP-05B> device.  Defaults to "192.168.1.100", which was the factory default of the device sold to me.

=item * user => string

Specify the login username.  Defaults to "admin", which was the factory default of the device sold to me.

=item * pass => string

Specify the login password.  Defaults to "admin", which was the factory default of the device sold to me.

=back

A new C<NP05B> object will have a condition of "disconnected".

=cut

sub new {
    my ($class, %opt_hr) = @_;
    my $self = {
        opt_hr   => \%opt_hr,
        ok       => 'OK',
        n_err    => 0,
        n_warn   => 0,
        err      => '',
        err_ar   => [],
        cond     => 'disconnected',
        status   => undef,
        buffer   => undef
    };
    bless ($self, $class);

    foreach my $k0 (keys %{$self->{opt_hr}}) {
        my $k1 = join('_', split(/-/, $k0));
        next if ($k0 eq $k1);
        $self->{opt_hr}->{$k1} = $self->{opt_hr}->{$k0};
        delete $self->{opt_hr}->{$k0};
    }

    $self->addr = $self->opt('addr', '192.168.1.100');
    $self->user = $self->opt('user', 'admin');
    $self->pass = $self->opt('pass', 'admin');

    return $self;
}

=head2 connect

    my ($ok, $err) = $np->connect;
    die "connect: $err" unless ($ok eq 'OK');

Attempt to open a telnet connection to the C<NP-05B> device.  This must be done before attempting C<login> or any other method.

After successful connection, the C<NP-05B> object will have a condition of "connected".

Returns ('OK', '') on success, or ('ERROR', $error_message) on failure, where $error_message is a short string describing the error (or, in some cases, the exception string thrown by L<Net::Telnet>).

=cut

sub connect {
    my ($self) = @_;
    my $t;  # reference to Net::Telnet object or Mock::Net::Telnet
    if ($self->opt('telnet_or','')) {
        # Using mocked object for unit testing
        $t = $self->opt('telnet_or');
    } else {
        $t = new Net::Telnet(Timeout => 3, Prompt => '/>$/');
    }
    $t->open($self->addr);
    $self->{telnet_or} = $t;
    my @results;
    select(undef, undef, undef, 0.5);  # to avoid command line pollution on remote end -- mysterious \0's injected.
    eval { @results = $t->cmd("ver") };
    if (@results) {
        $self->cond = 'connected';
        $self->{buffer} = \@results;
        return $self->ok();
    }
    $self->cond = 'disconnected';
    return $self->err("did not connect", $@);
}

=head2 login

    my ($ok, $err) = $np->login;

Attempt to log in to the C<NP-05B> device.  This must be done before attempting any other access or control methods.

Once successfully logged in, it is inadvisable to terminate the connection without first calling the C<logout> method.  The device can get into a sick state otherwise and misbehave in subsequent connections.

After successful login, the C<NP-05B> object will have a condition of "authenticated".

Returns ('OK', '') on success, or ('ERROR', $error_message) on failure, where $error_message is a short string describing the error (or, in some cases, the exception string thrown by L<Net::Telnet>).

=cut

sub login {  # Can't use telnet_or->login method because Synaccess uses nonstandard prompt format that telnet_or cannot accomodate.
    my ($self) = @_;
    return $self->err("not connected") unless ($self->is_connected);
    my $t = $self->{telnet_or};
    $t->print("");  # Sometimes there's garbage on the commandline
    $t->print("login");
    sleep(1);
    $t->print($self->user);
    sleep(1);
    $t->print($self->pass);
    sleep(1);
    my @results;
    eval { @results = $t->cmd("ver") };
    if (@results) {
        $self->cond = 'authenticated';
        $self->{buffer} = \@results;
        return $self->ok();
    }
    $self->cond = 'disconnected';
    return $self->err("login failed", $@);
}

=head2 is_connected

    say $np->is_connected ? "still connected" : "not connected";

Check the connection status.  Returns 1 if C<NP-05B> condition is "connected" or "authenticated", or 0 otherwise.

=cut

sub is_connected {
    my ($self) = @_;
    return 1 if ($self->cond eq 'connected');
    return 1 if ($self->cond eq 'authenticated');
    return 0;
}

=head2 logout

    my ($ok, $err) = $np->logout;

Needed to cleanly terminate the remote connection.

After successful logout, the C<NP05B> object will have a condition of "disconnected", and further access will require calling L<connect> and L<login>.

Returns ('OK', '') on success, or ('ERROR', $error_message) on failure, where $error_message is a short string describing the error (or, in some cases, the exception string thrown by L<Net::Telnet>).

=cut

sub logout {
    my ($self) = @_;
    return $self->err("not connected") unless ($self->is_connected);
    my @results;
    eval { @results = ($self->{telnet_or}->cmd("ver"), $self->{telnet_or}->cmd("logout")) };
    $self->{telnet_or}->close();
    $self->{telnet_or} = undef;
    $self->cond = 'disconnected';
    $self->{buffer} = [@results, $@];
    return $self->ok();
    # return $self->warn("might have disconnected uncleanly", $@);
}

=head2 power_status

    my ($ok, $hashref) = $np->power_status;

Retrieves the on/off status of the C<NP-05B> device's power outlets in the form of a hashref which keys on the port number to either 0 (off) or 1 (on).

For instance, if ports 1 2 and 3 are on and ports 4 and 5 are off, $hashref will reference:

    {1 => 1, 2 => 1, 3 => 1, 4 => 0, 5 => 0}

Returns ('OK', $hashref) on success, or ('ERROR', $error_message) on failure, where $error_message is a short string describing the error (or, in some cases, the exception string thrown by L<Net::Telnet>).

=cut

sub power_status {
    my ($self) = @_;
    return $self->err("not connected") unless ($self->is_connected);
    my @results;
    eval { @results = ($self->{telnet_or}->cmd("ver"),$self->{telnet_or}->cmd("pshow"),$self->{telnet_or}->cmd("ver")) };
    $self->{buffer} = \@results;
    return $self->err("telnet exception", $@) unless (@results);
    my %ps;
    # "\rPort | Name       |Status\n","\r   1 |    Outlet1 |   ON |   2 |    Outlet2 |   ON |
    #                                       3 |    Outlet3 |   ON |   4 |    Outlet4 |   OFF|
    #                                       5 |    Outlet5 |   ON |\n"
    foreach my $s (@results) {
        next unless ($s =~ /^\s+\d+\s+\|\s+Outlet\d/);
        foreach my $outlet (split(/(\d+\s+\|\s+Outlet\d+\s+\|\s+[OFN]+\s*\|)/, $s)) {
            $ps{$1} = $2 eq 'ON' ? 1 : 0 if ($outlet =~ /\s+Outlet(\d+)\s+\|\s+([OFN]+)\s*\|/);
        }
    }
    return $self->err("could not parse power status", \@results) unless (keys %ps);
    return $self->ok(\%ps);
}

=head2 power_set

    my ($ok, $hashref) = $np->power_set(3, 1);

Turns a specified C<NP-05B> device's power outlet on or off.  Its first parameter is the outlet number (1..5 on my device), and the second parameter is either 0 (to turn it off) or 1 (to turn it on).

Upon success, the returned $hashref is identical in format and semantics to the one returned by L<power_status>.

Returns ('OK', $hashref) on success, or ('ERROR', $error_message) on failure, where $error_message is a short string describing the error (or, in some cases, the exception string thrown by L<Net::Telnet>).

=cut

sub power_set {
    my ($self, $outlet, $on_or_off) = @_;
    return $self->err("not connected") unless ($self->is_connected);
    $self->{telnet_or}->cmd("ver");
    $self->{telnet_or}->cmd("pset $outlet $on_or_off");
    $self->{telnet_or}->cmd("ver");
    my ($ok, $ps_hr, @errs) = $self->power_status;
    return ('ERROR', $ps_hr, @errs) unless ($ok eq 'OK');
    my $normalized_on_or_off = $on_or_off ? 1 : 0;
    return $self->warn('outlet number out of range') unless(defined($ps_hr->{$outlet}));
    return $self->err('unexpected outlet status') unless($ps_hr->{$outlet} == $normalized_on_or_off);
    return $self->ok($ps_hr);
}

=head2 status

    my ($ok, $hashref) = $np->status;

Retrieves the full system status of the C<NP-05B> device.  The returned hashref is a bit complex:

    {
      'src_ip' => '0.0.0.0',
      's_mask' => '255.255.0.0',
      'source' => 'static',
      'port_telnet' => '23',
      'port_http' => '80',
      'model' => 'NP-05B',
      'mask' => '255.255.0.0',
      'eth' => 'on',
      'ip' => '192.168.1.100',
      's_ip' => '192.168.1.100',
      's_gw' => '192.168.1.1',
      'mac' => '00:90:c2:12:34:56',
      'power_hr' => {
        '2' => 1,
        '5' => 1,
        '3' => 1,
        '1' => 1,
        '4' => 1
      },
      'gw' => '192.168.1.1'
    }

Returns ('OK', $hashref) on success, or ('ERROR', $error_message) on failure, where $error_message is a short string describing the error (or, in some cases, the exception string thrown by L<Net::Telnet>).

=cut

sub status {
    my ($self) = @_;
    return $self->err("not connected") unless ($self->is_connected);
    my @results;
    eval { @results = ($self->{telnet_or}->cmd("ver"),$self->{telnet_or}->cmd("sysshow"),$self->{telnet_or}->cmd("ver")) };
    $self->{buffer} = \@results;
    return $self->err("telnet exception", $@) unless (@results);
    my %st_h;
    push @results, '';  # to make lookahead safe
    for (my $i = 0; $i < @results; $i++) { # yes, really, a C-style for loop .. easiest way to parse this evil soup
        my $s = $results[$i];
        my $v = $results[$i+1];
        if ($s =~ /^\s*Sys\s?Name\s*:\s*([^\s]+)/)                 { $st_h{'model'}  = $1; }
        if ($s =~ /^\s*IP Static or DHCP/ && $v =~ /Using (\w+)/)  { $st_h{'source'} = lc($1); }
        if ($s =~ /^\s*IP-Mask-GW\s*:\s*([^-]+)-([^-]+)-([^\s]+)/) { ($st_h{'ip'}, $st_h{'mask'}, $st_h{'gw'}) = ($1, $2, $3); }
        if ($s =~ /^\s*Static IP\/Mask\/Gateway\s*:\s*([^-]+)-([^-]+)-([^\s]+)/) { ($st_h{'s_ip'}, $st_h{'s_mask'}, $st_h{'s_gw'}) = ($1, $2, $3); }
        if ($s =~ /^\s*Ethernet Port is (\w+)/) { $st_h{'eth'} = lc($1); }
        if ($s =~ /^\s*HTTP\/Telnet Port .s\s*:\s*(\d+)[^\d]+(\d+)/) { ($st_h{'port_http'}, $st_h{'port_telnet'}) = ($1, $2); }
        if ($s =~ /^\s*MAC Address\s*:\s*([\w\:]+)/) { $st_h{'mac'} = lc($1); }
        if ($s =~ /^\s*Designated Source IP/ && $v =~ /^\s*(\d+\.\d+\.\d+\.\d+)/) { $st_h{'src_ip'} = $1; }
        if ($s =~ /^\s*Outlet Status[^:]+: ([\d\s]+)/) {
            my $outlets = $1;
            my $ix = 1;
            $st_h{'power_hr'} = {};
            foreach my $o (split(/\s+/, $outlets)) {
                $st_h{'power_hr'}->{$ix++} = int($o);
            }
        }
    }
    return $self->err('no recognizable status', \@results) unless (keys %st_h);
    $self->{status} = \%st_h;
    return $self->ok(\%st_h);
}

=head1 ACCESSORS

=head2 addr

    my $address = $np->addr;
    $np->addr = '10.0.0.6';

Get/set the C<addr> attribute, which determines where L<connect> will attempt to open a connection.

=head2 user

    my $username = $np->user;
    $np->addr = 'bob';

Get/set the C<user> attribute, which must be correct for L<login> to work.

=head2 pass

    my $password = $np->pass;
    $np->pass = 'sekrit';

Get/set the C<pass> attribute, which must be correct for L<login> to work.

=head2 cond

    my $condition = $np->cond;
    $np->addr = 'disconnected';

Get/set the C<cond> attribute, which reflects the connectedness/authentication status of the object.

Setting this attribute yourself is B<not recommended>.

=cut

sub addr :lvalue { $_[0]->{addr} }
sub user :lvalue { $_[0]->{user} }
sub pass :lvalue { $_[0]->{pass} }
sub cond :lvalue { $_[0]->{cond} }

sub all_is_well {
    my ($self) = @_;
    $self->{ok}  = 'OK';
    $self->{err} = '';
    $self->{err_ar} = [];
    return;
}

sub opt {
    my ($self, $name, $default_value, $alt_hr) = @_;
    return def($self->{opt_hr}->{$name}, $alt_hr->{$name}, $default_value);
}

sub def {
    foreach my $v (@_) { return $v if (defined($v)); }
    return undef;
}

sub ok {
    my $self = shift(@_);
    $self->all_is_well();
    return ('OK', @_);
}

sub err {
    my $self = shift(@_);
    $self->{n_err}++;
    $self->{err}    = $_[0];
    $self->{err_ar} = \@_;
    return ('ERROR', @_);
}

sub warn {
    my $self = shift(@_);
    $self->{n_warn}++;
    $self->{err}    = $_[0];
    $self->{err_ar} = \@_;
    return ('WARNING', @_);
}

=head1 CAVEATS

This module works for the specific device shipped to the author, and might not work for you if Synaccess changes the behavior of their product.

The C<NP-05B> can misbehave in odd ways if commands are sent to it too quickly or if connections are not terminated cleanly.  The module uses short delays which helps mitigate some of these problems.  (Despite these problems, the C<NP-05B> is pretty good value for the price.)

=head1 TO DO

=over 4

=item * Support commands for changing the C<NP-05B> network configuration.

=item * Improve the unit tests, which are a little shallow.

=item * Support nonstandard port mapping.

=back

=head1 SEE ALSO

L<App::np05bctl> - a light CLI utility wrapping this module.  Not distributed with C<Device::Power::Synaccess::NP05B> to avoid spurious dependencies.

=head1 AUTHOR

TTK Ciar E<lt>ttk@ciar.orgE<gt>

=head1 COPYRIGHT

You may use and distribute this module under the same terms as Perl itself.

=cut

1;
