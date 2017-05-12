package Linux::Proc::Net::TCP::Base;

use strict;
use warnings;

use Carp;

my %regexp = ( tcp => qr/^\s*
                         (\d+):\s                                     # sl                        -  0
                         ([\dA-F]{8}(?:[\dA-F]{24})?):([\dA-F]{4})\s  # local address and port    -  1 &  2
                         ([\dA-F]{8}(?:[\dA-F]{24})?):([\dA-F]{4})\s  # remote address and port   -  3 &  4
                         ([\dA-F]{2})\s                               # st                        -  5
                         ([\dA-F]{8}):([\dA-F]{8})\s                  # tx_queue and rx_queue     -  6 &  7
                         (\d\d):([\dA-F]{8}|F{9,}|1AD7F[\dA-F]{6})\s  # tr and tm->when           -  8 &  9
                         ([\dA-F]{8})\s+                              # retrnsmt                  - 10
                         (\d+)\s+                                     # uid                       - 11
                         (\d+)\s+                                     # timeout                   - 12
                         (\d+)\s+                                     # inode                     - 13
                         (\d+)\s+                                     # ref count                 - 14
                         ((?:[\dA-F]{8}){1,2})                        # memory address            - 15
                         (?:
                             \s+
                             (\d+)\s+                                 # retransmit timeout        - 16
                             (\d+)\s+                                 # predicted tick            - 17
                             (\d+)\s+                                 # ack.quick                 - 18
                             (\d+)\s+                                 # sending congestion window - 19
                             (-?\d+)                                  # slow start size threshold - 20
                         )?
                         \s*
                         (.*)                                         # more                      - 21
                         $
                        /xi,

               udp => qr/^\s*
                         (\d+):\s                                     # sl                        -  0
                         ([\dA-F]{8}(?:[\dA-F]{24})?):([\dA-F]{4})\s  # local address and port    -  1 &  2
                         ([\dA-F]{8}(?:[\dA-F]{24})?):([\dA-F]{4})\s  # remote address and port   -  3 &  4
                         ([\dA-F]{2})\s                               # st                        -  5
                         ([\dA-F]{8}):([\dA-F]{8})\s                  # tx_queue and rx_queue     -  6 &  7
                         (\d\d):([\dA-F]{8}|F{9,}|1AD7F[\dA-F]{6})\s  # tr and tm->when           -  8 &  9
                         ([\dA-F]{8})\s+                              # retrnsmt                  - 10
                         (\d+)\s+                                     # uid                       - 11
                         (\d+)\s+                                     # timeout                   - 12
                         (\d+)\s+                                     # inode                     - 13
                         (\d+)\s+                                     # ref count                 - 14
                         ((?:[\dA-F]{8}){1,2})                        # memory address            - 15
                         (?:
                             \s+
                             (\d+)                                    # drops                     - 16
                         )?
                         \s*
                         (.*)                                         # more                      - 17
                         $
                        /xi
             );

sub _read {
    my $class = shift;
    @_ & 1 and croak "Usage: $class->read(\%opts)";
    my %opts = @_;

    my $proto = delete $opts{_proto} || 'tcp';

    my $ip4 = delete $opts{ip4};
    my $ip6 = delete $opts{ip6};
    my $mnt = delete $opts{mnt};
    my $files = delete $opts{files};

    %opts and croak "Unknown option(s) ". join(", ", sort keys %opts);

    my @fn;
    if ($files) {
        @fn = @$files;
    }
    else {
        $mnt = "/proc" unless defined $mnt;

        unless (-d $mnt and (stat _)[12] == 0) {
            croak "$mnt is not a proc filesystem";
        }

        push @fn, "$mnt/net/${proto}"  unless (defined $ip4 and not $ip4);
        push @fn, "$mnt/net/${proto}6" if (defined $ip6 ? $ip6 : -f "$mnt/net/${proto}6");
    }

    my $regexp = $regexp{$proto} or croak "Internal error: unexpected protocol '$proto'";

    my @entries;
    for my $fn (@fn) {
        local $_;
        open my $fh, '<', $fn
            or croak "Unable to open $fn: $!";
        <$fh>; # discard header
        while (<$fh>) {
            if (my @entry = $_ =~ $regexp) {
                my $entry = \@entry;
                bless $entry, "${class}::Entry";
                push @entries, $entry
            }
            else {
                warn "unparseable line: $_";
            }
        }
    }
    bless \@entries, $class;
}

package Linux::Proc::Net::TCP::Base::Entry;

sub _hex2ip {
    my $bin = pack "C*" => map hex, $_[0] =~ /../g;
    my @l = unpack "L*", $bin;
    if (@l == 4) {
        return join ':', map { sprintf "%x:%x", $_ >> 16, $_ & 0xffff } @l;
    }
    elsif (@l == 1) {
        return join '.', map { $_ >> 24, ($_ >> 16 ) & 0xff, ($_ >> 8) & 0xff, $_ & 0xff } @l;
    }
    else { die "internal error: bad hexadecimal encoded IP address '$_[0]'" }
}

sub sl                        {          shift->[ 0] }
sub local_address             { _hex2ip  shift->[ 1] }
sub local_port                { hex      shift->[ 2] }
sub rem_address               { _hex2ip  shift->[ 3] }
sub rem_port                  { hex      shift->[ 4] }
# st is defined in subclasses
sub tx_queue                  { hex      shift->[ 6] }
sub rx_queue                  { hex      shift->[ 7] }
sub timer                     {          shift->[ 8] }
sub retrnsmt                  { hex      shift->[10] }
sub uid                       {          shift->[11] }
sub timeout                   {          shift->[12] }
sub inode                     {          shift->[13] }
sub reference_count           {          shift->[14] }
sub memory_address            { hex      shift->[15] }

sub ip4                       { length(shift->[ 1]) ==  8 }
sub ip6                       { length(shift->[ 1]) == 32 }

sub tm_when { # work around bug in Linux kernel
    my $when = shift->[9];
    $when =~ /^(?:F{8,}|1AD7F[\dA-F]{6})$/ ? -1 : hex $when
}



1;
