package Hex::Record;

use strict;
use warnings;
use Carp;

our $VERSION = '0.08';

sub new {
    my ($class, %args) = @_;

    $args{parts} = [] unless exists $args{parts};

    return bless \%args, $class;
}

sub import_intel_hex {
    my ($self, $hex_string) = @_;

    my $addr_high_dec = 0;

    for my $line (split m{\n\r?}, $hex_string) {
        my ($addr, $type, $bytes_str) = $line =~ m{
		  : # intel hex start
		   [[:xdigit:]]{2}  # bytecount
		  ([[:xdigit:]]{4}) # addr
		  ([[:xdigit:]]{2}) # type
		  ([[:xdigit:]] * ) # databytes
	       	   [[:xdigit:]]{2}  # checksum
	      }ix or next;

        my @bytes = unpack('(A2)*', $bytes_str);

        # data line?
        if ($type == 0) {
            $self->write($addr_high_dec + hex $addr, \@bytes);
        }
        # extended linear address type?
        elsif ($type == 4) {
            $addr_high_dec = hex( join '', @bytes ) << 16;
        }
        # extended segment address type?
        elsif ($type == 2) {
            $addr_high_dec = hex( join '', @bytes ) << 4;
        }
    }

    return;
}

sub import_srec_hex {
    my ($self, $hex_string) = @_;

    my %address_length_of_srec_type = (
        0 => 4,
        1 => 4,
        2 => 6,
        3 => 8,
        4 => undef,
        5 => 4,
        6 => 6,
        7 => 8,
        8 => 6,
        9 => 4,
    );

    my @parts;
    for my $line (split m{\n\r?}, $hex_string) {
        next unless substr( $line, 0, 1 ) =~ m{s}i;

        my $type = substr $line, 1, 1;

        my $addr_length = $address_length_of_srec_type{$type} || next;

        my ($addr, $bytes_str) = $line =~ m{
		      s #srec hex start
		   [[:xdigit:]]{1}             #type
		   [[:xdigit:]]{2}              #bytecount
		  ([[:xdigit:]]{$addr_length})  #addr
		  ([[:xdigit:]] * )             #databytes
		   [[:xdigit:]]{2}              #checksum
	      }ix or next;

        # data line?
        if ($type == 1 || $type == 2 || $type == 3) {
            $self->write(hex $addr, [ unpack '(A2)*', $bytes_str ]);
        }
    }

    return;
}

sub write {
    my ($self, $from, $bytes_hex_ref) = @_;

    $self->remove($from, scalar @$bytes_hex_ref);

    my $to = $from + @$bytes_hex_ref;

    for (my $part_i = 0; $part_i < @{ $self->{parts} }; $part_i++) {
        my $part = $self->{parts}->[$part_i];

        my $start_addr = $part->{start};
        my $end_addr   = $part->{start} + $#{ $part->{bytes} };

        # merge with this part
        if ($to == $start_addr) {
            $part->{start} = $from;
            unshift @{ $part->{bytes} }, @$bytes_hex_ref;
            return;
        }
        elsif ($from == $end_addr + 1) {
            push @{ $part->{bytes} }, @$bytes_hex_ref;

            return if $part_i+1 == @{ $self->{parts} };

            my $next_part = $self->{parts}->[$part_i+1];
            # merge with next part
            if ($to == $next_part->{start}) {
                push @{ $part->{bytes} }, @{ $next_part->{bytes} };
                splice @{ $self->{parts} }, $part_i+1, 1;
            }
            return;
        }
        elsif ($from < $start_addr) {
            splice @{ $self->{parts} }, $part_i, 0, {
                start => $from,
                bytes => $bytes_hex_ref
            };
            return;
        }
    }

    push @{ $self->{parts} }, {
        start => $from,
        bytes => $bytes_hex_ref
    };

    return;
}

sub get {
    my ($self, $from, $length) = @_;

    my @bytes;
    my $end_last = $from;
    my $get = sub {
        my ($part, $part_i_ref, $overlap) = @_;

        my $gap = $part->{start} - $end_last;
        push @bytes, (undef) x $gap if $gap > 0;

        if ($overlap eq 'a') {
            push @bytes, @{ $part->{bytes} };
        }
        elsif ($overlap eq 'l') {
            push @bytes, @{ $part->{bytes} }[ 0 .. $length - 1 ];
        }
        elsif ($overlap eq 'r') {
            push @bytes, @{ $part->{bytes} }[ $from - $part->{start} .. $#{ $part->{bytes} } ];
        }
        else {
            my $start_i = $from - $part->{start};
            push @bytes, @{ $part->{bytes} }[ $start_i .. $start_i + $length - 1];
        }

        $end_last = $part->{start} + @{ $part->{bytes} };
    };

    $self->_traverse($from, $length, $get);

    return [ @bytes, (undef) x ($length - @bytes) ];
}

sub remove {
    my ($self, $from, $length) = @_;

    my $to = $from + $length;

    my $remove = sub {
        my ($part, $part_i_ref, $overlap) = @_;
        if ($overlap eq 'a') {
            splice @{ $self->{parts} }, $$part_i_ref, 1;
            --$$part_i_ref;
        }
        elsif ($overlap eq 'l') {
            my $to_remove = $to - $part->{start};
            splice @{ $part->{bytes} }, 0, $to_remove;
            $part->{start} += $to_remove;
        }
        elsif ($overlap eq 'r') {
            splice @{ $part->{bytes} }, $from - $part->{start};
        }
        else {
            splice @{ $self->{parts} }, $$part_i_ref, 1,
                {
                    start => $part->{start},
                    bytes => [ @{ $part->{bytes} }[ 0 .. $from - $part->{start} - 1 ] ],
                },
                {
                    start => $from + $length,
                    bytes => [ @{ $part->{bytes} }[
                        $from - $part->{start} + $length .. $#{ $part->{bytes} }
                    ] ],
                };
        };
    };

    $self->_traverse($from, $length, $remove);

    return;
}

sub _traverse {
    my ($self, $from, $length, $process) = @_;

    my $to = $from + $length;

    for (my $part_i = 0; $part_i < @{ $self->{parts} }; $part_i++) {
        my $part = $self->{parts}->[$part_i];

        my $start_addr = $part->{start};
        my $end_addr   = $part->{start} + @{ $part->{bytes} };

        if ($from < $end_addr && $to > $start_addr) {
            if ($from <= $start_addr) {
                if ($to < $end_addr -1) {
                    $process->($part, \$part_i, 'l');
                    return;
                }
                $process->($part, \$part_i, 'a');
            }
            elsif ($to < $end_addr - 1) {
                $process->($part, \$part_i, 'm');
                return;
            }
            else {
                $process->($part, $part_i, 'r');
            }

            # found start -> search for end
            while ( defined (my $part = $self->{parts}->[++$part_i]) ) {
                my $start_addr = $part->{start};
                return if $start_addr > $to;

                my $end_addr = $part->{start} + @{ $part->{bytes} };

                if ($to >= $end_addr) {
                    $process->($part, \$part_i, 'a');
                }
                else {
                    $process->($part, \$part_i, 'l');
                    return;
                }
            }
            return;
        }
    }
}

sub as_intel_hex {
    my ($self, $bytes_hex_a_line) = @_;

    my $intel_hex_string = '';
    for (my $part_i = 0; $part_i < @{ $self->{parts} }; $part_i++) {
        my $part = $self->{parts}->[$part_i];

        my $start_addr = $part->{start};
        my $end_addr   = $part->{start} + $#{ $part->{bytes} };

        my $cur_high_addr_hex = '0000';

        for (my $slice_i = 0; $slice_i * $bytes_hex_a_line < @{ $part->{bytes} }; $slice_i++) {
            my $total_addr = $start_addr + $slice_i*$bytes_hex_a_line;

            my ($addr_high_hex, $addr_low_hex) = unpack '(A4)*', sprintf('%08X', $total_addr);

            if ($cur_high_addr_hex ne $addr_high_hex) {
                $cur_high_addr_hex = $addr_high_hex;
                $intel_hex_string .=  _intel_hex_line_of( '0000', 4, [unpack '(A2)*', $cur_high_addr_hex]);
            }

            if ( ($slice_i + 1) * $bytes_hex_a_line <=  $#{ $part->{bytes} } ) {
                $intel_hex_string .= _intel_hex_line_of(
                    $addr_low_hex, 0,
                    [
                        @{ $part->{bytes} }[
                            $slice_i * $bytes_hex_a_line .. ($slice_i + 1) * $bytes_hex_a_line - 1
                        ]
                    ]
                );
            }
            else {
                $intel_hex_string .= _intel_hex_line_of(
                    $addr_low_hex, 0, [
                        @{ $part->{bytes} }[
                            $slice_i * $bytes_hex_a_line .. $#{ $part->{bytes} }
                        ]
                    ]
                );
            }
        }
    }
                               # intel hex eof
    return $intel_hex_string . ":00000001FF\n";
}

sub _intel_hex_line_of {
    my ($addr_low_hex, $type, $bytes_hex_ref) = @_;

    my $byte_count = @$bytes_hex_ref;

    my $sum = 0;
    $sum += $_ for ( $byte_count, (map { hex $_ } unpack '(A2)*', $addr_low_hex),
                     $type,       (map { hex $_ } @$bytes_hex_ref) );

    #convert to hex, take lsb
    $sum = substr(sprintf( '%02X', $sum ), -2);

    my $checksum_hex = sprintf '%02X', (hex $sum ^ 255) + 1;
    $checksum_hex    = '00' if length $checksum_hex != 2;

    return join '',
        (
            ':',
            sprintf( '%02X', $byte_count ),
            $addr_low_hex,
            sprintf( '%02X', $type ),
            @$bytes_hex_ref,
            $checksum_hex,
            "\n"
        );
}

sub as_srec_hex {
    my ($self, $bytes_hex_a_line) = @_;

    my $srec_hex_string = '';
    for (my $part_i = 0; $part_i < @{ $self->{parts} }; $part_i++) {
        my $part = $self->{parts}->[$part_i];

        my $start_addr = $part->{start};
        my $end_addr   = $part->{start} + $#{ $part->{bytes} };

        for (my $slice_i = 0; $slice_i * $bytes_hex_a_line < @{ $part->{bytes} }; $slice_i++) {
            my $total_addr = $start_addr + $slice_i*$bytes_hex_a_line;

            if ( ($slice_i + 1) * $bytes_hex_a_line <=  $#{ $part->{bytes} } ) {
                $srec_hex_string .= _srec_hex_line_of(
                    $total_addr,
                    [@{ $part->{bytes} }[$slice_i * $bytes_hex_a_line .. ($slice_i + 1) * $bytes_hex_a_line - 1]]
                );
            }
            else {
                $srec_hex_string .= _srec_hex_line_of(
                    $total_addr,
                    [@{ $part->{bytes} }[$slice_i * $bytes_hex_a_line .. $#{ $part->{bytes} }]]
                );
            }
        }
    }

    return $srec_hex_string;
}

sub _srec_hex_line_of {
    my ($total_addr, $bytes_hex_ref) = @_;

    my $total_addr_hex = sprintf '%04X', $total_addr;

    my $type;
    # 16 bit addr
    if (length $total_addr_hex == 4) {
        $type = 1;
    }
    # 24 bit addr
    elsif (length $total_addr_hex <= 6) {
        $total_addr_hex = "0$total_addr_hex" if length $total_addr_hex == 5;
        $type = 2;
    }
    # 32 bit addr
    else {
        $total_addr_hex = "0$total_addr_hex" if length $total_addr_hex == 7;
        $type = 3;
    }

    # count of data bytes + address bytes
    my $byte_count = @$bytes_hex_ref + length($total_addr_hex) / 2;

    my $sum = 0;
    $sum += $_ for ( $byte_count,
                     (map { hex $_ } unpack '(A2)*', $total_addr_hex),
                     (map { hex $_ } @$bytes_hex_ref) );

    #convert to hex, take lsb
    $sum = substr(sprintf( '%02X', $sum ), -2);

    my $checksum_hex = sprintf '%02X', (hex $sum ^ 255);

    return join '',
        (
            "S$type",
            sprintf('%02X', $byte_count),
            $total_addr_hex,
            @$bytes_hex_ref,
            $checksum_hex,
            "\n"
        );
}

1;

=head1 NAME

Hex::Record - manipulate intel and srec hex records

=head1 SYNOPSIS

  use Hex::Record;

  my $hex_record = Hex::Record->new;

  $hex_record->import_intel_hex($intel_hex_str);
  $hex_record->import_srec_hex($srec_hex_str);

  $hex_record->write(0x100, [qw(AA BB CC)]);

  # get 10 bytes (hex format) starting at address 0x100
  # every single byte that is not found is returned as undef
  my $bytes_ref = $hex_record->get(0x100, 10);

  # remove 10 bytes starting at address 0x100
  $hex_record->remove(0x100, 10);

  # dump as intel hex (will use extended linear addresses for offset)
  # maximum of 10 bytes in data field
  my $intel_hex_string = $hex_record->as_intel_hex(10);

  # dump as srec hex (always tries to use smallest address, 16 bit, 24 bit, 32 bit)
  # maximum of 10 bytes in data field
  my $srec_hex_string = $hex_record->as_srec_hex(10);

=head1 DESCRIPTION

Manipulate intel/srec hex files.

=head1 Methods

=head2 import_intel_hex($intel_hex_str)

Imports hex bytes from a string containing intel hex formatted data.
Ignores unknown lines, does not check if the checksum at the end is correct.

  $hex_record->import_intel_hex($intel_hex_str);

=head2 import_srec_hex($srec_hex_str)

Imports hex bytes from a string containing srec hex formatted data.
Ignores unknown lines, does not check if the checksum at the end is correct.

  $hex_record->import_srec_hex($srec_hex_str);

=head2 get($from, $count)

Returns $count hex bytes in array reference starting at address $from.
If hex byte is not found, undef instead. For example:

  my $bytes_ref = $hex_record->get(0x0, 6); # ['AA', '00', undef, undef, 'BC', undef]

=head2 remove($from, $count)

Removes $count bytes starting at address $from.

  $hex_record->remove(0x123, 10);

=head2 write($from, $bytes_ref)

(Over)writes bytes starting at address $from with bytes in $bytes_ref.

  $hex_record->write(0x10, [qw(AA BB CC DD EE FF 11)]);

=head2 as_intel_hex($bytes_hex_a_line)

Returns a string containing hex bytes formatted as intel hex.
Maximum of $bytes_hex_a_line in data field.
Extended linear addresses as offset are used if needed.
Extended segment addresses are not supported. (yet? let me know!)

  my $intel_hex_str = $hex_record->as_intel_hex(10);

=head2 as_srec_hex($bytes_hex_a_line)

Returns a string containing hex bytes formatted as srec hex.
Maximum of $bytes_hex_a_line in data field.
Tries to use the smallest address field. (16 bit, 24 bit, 32 bit)

  my $srec_hex_str = $hex_record->as_srec_hex(10);

=head1 LICENSE

This is released under the Artistic License.

=head1 AUTHOR

spebern <bernhard@specht.net>

=cut
