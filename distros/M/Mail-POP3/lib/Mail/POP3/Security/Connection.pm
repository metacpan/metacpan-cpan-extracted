package Mail::POP3::Security::Connection;

use strict;
use IO::Socket;

=head2 new

Params: Config hash-ref with keys:

=over

=item trusted_networks

Filename.

=item allow_non_fqdn

Boolean.

=item hosts_allow_deny

Filename.

=back

=cut

sub new {
    my ($class, $config) = @_;
    my $self = {};
    bless $self, $class;
    $self->{CONFIG} = $config;
    $self;
}

=head2 check

Params: C<$client_ip>, C<$fqdn>.

=cut

# return ($was_ok, \@log_entry)
sub check {
    my ($self, $client_ip, $fqdn) = @_;
    # Get the client's IP and FQDN. We don't have tcpwrapper
    # protection in daemon mode and therefore need to do a reverse
    # lookup. $self->{CONFIG}->{allow_non_fqdn} can be set to 1 to
    # effectively disable reverse lookups.
    # Make an exception for trusted networks
    my $secure = 0;
    if (-f $self->{CONFIG}->{trusted_networks}) {
        local *SECURENETS;
        open SECURENETS, $self->{CONFIG}->{trusted_networks};
        while (<SECURENETS>) {
            next if /^\#/;
            next if /^\s+$/;
            chomp;
            s/\s+|\*//g;
            if ($client_ip =~ /^$_/ || $fqdn =~ /^$_$/) {
                $secure = 1;
                last;
            }
        }
        close SECURENETS;
    }
    my @addr = gethostbyname($fqdn);
    # See if any of the domain names returned matches the IP
    # and return false if none does.
    my $lookup_ok = grep { $client_ip eq inet_ntoa($_) } @addr[4..$#addr];
    if (!$lookup_ok and !$self->{CONFIG}->{allow_non_fqdn} and !$secure) {
        return (0, [ "$client_ip\tFAILED reverse lookup at" ]);
    }
    my $log_entry = [];
    # Check a seperate blocking list for particular client's/networks
    if (-s $self->{CONFIG}->{hosts_allow_deny}) {
        my $deny_all = 0;
        my $allowed = 0;
        local *ALLOWDENY;
        open ALLOWDENY, $self->{CONFIG}->{hosts_allow_deny};
        while (<ALLOWDENY>) {
            next if /^\#/;
            next if /^\s+$/;
            chomp;
            # Each line can be one action, DENY, ALLOW or WARN, followed by
            # an IP, subnet or hostname, whereby 'ALL' is a special case.
            # If the special rule 'DENY ALL' appears anywhere then
            # a client will be refused unless they match an 'ALLOW' line.
            # Lines starting with '#' or whitespace are skipped.
            my ($action,$peer) = split /\s+/, $_;
            $action =~ s/\s+//g;
            $peer =~ s/\s+|\*//g;
            if ($action =~ /deny/i and $peer =~ /all/i) {
                $deny_all = 1;
            } elsif ($client_ip =~ /^$peer/ || $fqdn =~ /^$peer$/i) {
                if ($action =~ /allow/i) {
                    push @$log_entry, "$client_ip\tALLOWED connection at";
                    $allowed = 1;
                    last;
                } elsif ($action =~ /warn/i) {
                    push @$log_entry, "$client_ip\tWARN connected at";
                } elsif ($action =~ /deny/i and $peer !~ /all/i) {
                    return (
                        0, [ @$log_entry, "$client_ip\tDENIED connection at" ]
                    );
                }
            }
        }
        close ALLOWDENY;
        if ($deny_all == 1 and $allowed == 0) {
            return (0, [ @$log_entry, "$client_ip\tDENIED connection at" ]);
        }
        return (1, $log_entry);
    }
    return (1, $log_entry);
}

1;
