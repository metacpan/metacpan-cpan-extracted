package FIX::Parser::FIX44;
use 5.010;
use strict;
use warnings;
use POSIX qw(strftime);

our $VERSION = '0.02';    ## VERSION

=for Pod::Coverage new add make_message parse_message

=cut

sub new {
    my ($class) = @_;
    return bless {_buf => ''}, $class;
}

sub add {
    my ($self, $data) = @_;
    $self->{_buf} .= $data;
    my @msgs;

    if ($self->{_len}) {
        return if $self->{_len} > length $self->{_buf};
        push @msgs, parse_message(substr $self->{_buf}, 0, $self->{_len}, '');
        delete $self->{_len};
    }

    while ($self->{_buf} =~ s/^8=FIX.4.4\x{01}9=([0-9]+)\x{01}//) {
        $self->{_len} = $1 + 7;
        return @msgs if $self->{_len} > length $self->{_buf};
        push @msgs, parse_message(substr $self->{_buf}, 0, $self->{_len}, '');
        delete $self->{_len};
    }

    if (length $self->{_buf} > 14
        and $self->{_buf} !~ /^8=FIX.4.4\x{01}9=[0-9]/)
    {
        die "Invalid FIX message header: $self->{_buf}";
    }

    return @msgs;
}

sub parse_message {
    my ($fix) = @_;
    my @tags = map { [split /=/] } split /\x{01}/, $fix;
    die "Message doesn't start with MsgType tag: $fix" unless $tags[0][0] == 35;

    my $message;
    if ($tags[0][1] eq 'W') {
        $message->{msg_type} = 'W';
        while (@tags and $tags[0][0] != 10) {
            my $tag = shift @tags;

            my $symbol;

            if ($tag->[0] == 52) {
                $message->{msg_datetime} = $tag->[1];
            } elsif ($tag->[0] == 55) {
                $message->{symbol} = $tag->[1];
                #$symbol = $tag->[1];
            } elsif ($tag->[0] == 268) {
                my ($date, $time);

                for (1 .. $tag->[1]) {
                    my ($price, $bprice, $aprice, $type);

                    while (1) {
                        my $tag = shift @tags;
                        if ($tag->[0] == 269) {
                            $type =
                                  $tag->[1] eq '0' ? 'bid'
                                : $tag->[1] eq '1' ? 'ask'
                                : $tag->[1] eq 'H' ? 'mid'
                                :                    $tag->[1];
                        } elsif ($tag->[0] == 55) {
                            die "symbols in different MDEntries do not match: $fix"
                                if $symbol and $symbol ne $tag->[1];
                            $symbol = $tag->[1];
                        } elsif ($tag->[0] == 270) {
                            $price = $tag->[1];
                            if ($type eq 'bid') { $bprice = $price; }
                            if ($type eq 'ask') { $aprice = $price; }
                        } elsif ($tag->[0] == 272) {
                            die "dates in differend MDEntries do not match: $fix"
                                if $date and $date ne $tag->[1];
                            $date = $tag->[1];
                        } elsif ($tag->[0] == 273) {
                            die "times in differend MDEntries do not match: $fix"
                                if $time and $time ne $tag->[1];
                            $time = $tag->[1];
                        } elsif ($tag->[0] == 167 and $tag->[1] ne 'FXSPOT') {
                            die "expected FXSPOT in MDEntries but found $tag->[1]: $fix";
                        } elsif ($tag->[0] == 279 or $tag->[0] == 10) {
                            last;
                        }

                        #end of while loop
                    }

                    die "MDEntry doesn't have price or type: $fix"
                        unless defined $price and $type;
                    $message->{bid} = $bprice;
                    $message->{ask} = $aprice;

                    last;
                }

                $message->{datetime} = $message->{msg_datetime};

            }

        }

    } elsif ($tags[0][1] eq '0') {

        # Heartbeat
        $message->{msg_type} = '0';
    } elsif ($tags[0][1] eq '1') {

        # Test request
        $message->{msg_type} = '1';
        while (@tags and $tags[0][0] != 10) {
            my $tag = shift @tags;
            if ($tag->[0] == 112) {
                $message->{test_req_id} = $tag->[1];
                last;
            }
        }
    } elsif ($tags[0][1] eq '2') {

        # Resend request
        $message->{msg_type} = '2';
        while (@tags and $tags[0][0] != 10) {
            my $tag = shift @tags;
            if ($tag->[0] == 7) {
                $message->{begin_seq_no} = $tag->[1];
            } elsif ($tag->[0] == 16) {
                $message->{end_seq_no} = $tag->[1];
            }
        }
    } elsif ($tags[0][1] eq 'A') {

        # Logon message
        $message->{msg_type} = 'A';
    } elsif ($tags[0][1] eq '5') {

        # Logout message
        $message->{msg_type} = '5';
        while (@tags and $tags[0][0] != 10) {
            my $tag = shift @tags;
            if ($tag->[0] == 58) {
                $message->{logout_message} = $tag->[1];
            }
        }
    } else {
        die "Don't know how to parse message of type $tags[0][1]: $fix";
    }

    return $message;
}

sub make_message {
    my ($self, $type, $sender_id, $target_id, @tags) = @_;
    $self->{_seq}++;
    my $ts = strftime("%Y%m%d-%H:%M:%S.000", gmtime);
    my $msg = join "\x{01}", "35=$type", "49=$sender_id", "52=$ts", "56=$target_id", "34=$self->{_seq}", @tags, '';
    my $len = length $msg;
    $msg = join "\x{01}", '8=FIX.4.4', "9=$len", $msg;
    my $sum = 0;
    $sum += ord $_ for split //, $msg;
    $sum %= 256;
    $msg .= '10=' . sprintf("%03d\x{01}", $sum);

    return $msg;
}

1;
