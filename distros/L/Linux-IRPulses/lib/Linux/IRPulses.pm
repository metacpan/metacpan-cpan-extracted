package Linux::IRPulses;
$Linux::IRPulses::VERSION = '0.7';
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use Moose::Exporter;

use constant DEBUG => 0;

# ABSTRACT: Parse LIRC pulse data

Moose::Exporter->setup_import_methods(
    as_is => [ 'pulse', 'space', 'pulse_or_space' ],
);
sub pulse ($) {[ 'pulse', $_[0] ]}
sub space ($) {[ 'space', $_[0] ]}
sub pulse_or_space ($) {[ 'either', $_[0] ]}


has 'fh' => (
    is => 'ro',
);
has 'header' => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[ArrayRef[Str]]',
    required => 1,
    handles => {
        header_length => 'count',
    },
);
has 'zero' => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[ArrayRef[Str]]',
    required => 1,
    handles => {
        zero_length => 'count',
    },
);
has 'one' => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef[ArrayRef[Str]]',
    required => 1,
    handles => {
        one_length => 'count',
    },
);
has 'bit_count' => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);
has '_bits' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);
has 'tolerance' => (
    is => 'ro',
    isa => 'Num',
    required => 1,
    default => 0.20,
);
has 'callback' => (
    is => 'ro',
    isa => 'CodeRef',
    required => 1,
);
has '_do_close_file' => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);
has '_do_end_loop' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);
has '_did_see_header' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);
has '_header_index' => (
    traits => ['Number'],
    is => 'rw',
    isa => 'Int',
    default => 0,
    handles => {
        _add_header_index => 'add',
    },
);
has '_bit_count' => (
    traits => ['Number'],
    is => 'rw',
    isa => 'Int',
    default => 0,
    handles => {
        _add_bit_count => 'add',
    },
);
has '_is_maybe_zero' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);
has '_is_maybe_one' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);
has '_zero_index' => (
    traits => ['Number'],
    is => 'rw',
    isa => 'Int',
    default => 0,
    handles => {
        _add_zero_index => 'add',
    },
);
has '_one_index' => (
    traits => ['Number'],
    is => 'rw',
    isa => 'Int',
    default => 0,
    handles => {
        _add_one_index => 'add',
    },
);


sub BUILDARGS
{
    my ($class, $args) = @_;

    if( exists $args->{dev_file} ) {
        my $file = delete $args->{dev_file};

        open( my $in, '<', $file ) or die "Can't open file '$file': $!\n";
        $args->{fh} = $in;
        $args->{'_do_close_file'} = 1;
    }

    return $args;
}


sub run
{
    my ($self) = @_;
    my $in = $self->fh;

    while(
        (! $self->_do_end_loop) 
        && (my $line = readline($in))
    ) {
        chomp $line;
        $self->handle_line( $line );
    }

    close $in if $self->_do_close_file;
    return;
}

sub end
{
    my ($self) = @_;
    $self->_do_end_loop( 1 );
    return;
}


sub handle_line
{
    my ($self, $line) = @_;
    warn "Matching: $line\n" if DEBUG;
    
    if( $self->_did_see_header ) {
        my $is_matched = 0;

        if( $self->_is_maybe_zero() ) {
            if( $self->_match_line( $line, $self->zero->[$self->_zero_index] ) ) {
                $self->_add_zero_index(1);
                if( $self->_zero_index >= $self->zero_length ) {
                    warn "\tWe have a complete zero signal\n" if DEBUG;
                    $self->_zero_index(0);
                    $self->_one_index(0);
                    $self->_is_maybe_zero(1);
                    $self->_is_maybe_one(1);
                    $self->_add_bit_count(1);
                    $self->_bits( $self->_bits() << 1 | 0 );
                    $is_matched = 1;
                }
                else {
                    warn "\tWe might have a zero, but we're not sure so sit tight\n"
                        if DEBUG;
                }
            }
            else {
                warn "\tIt's definately not a zero\n" if DEBUG;
                $self->_is_maybe_zero( 0 );
            }
        }

        if( (! $is_matched) && $self->_is_maybe_one() ) {
            if( $self->_match_line( $line, $self->one->[$self->_one_index] ) ) {
                $self->_add_one_index(1);
                if( $self->_one_index >= $self->one_length ) {
                    # We have a complete one signal, reset state
                    warn "\tWe have a complete one signal\n" if DEBUG;
                    $self->_zero_index(0);
                    $self->_one_index(0);
                    $self->_is_maybe_zero(1);
                    $self->_is_maybe_one(1);
                    $self->_add_bit_count(1);
                    $self->_bits( $self->_bits() << 1 | 1 );
                    $is_matched = 1;
                }
                else {
                    # Might be a one, but we're not sure yet, so sit tight
                    warn "\tWe might have a one, but we're not sure so sit tight\n"
                        if DEBUG;
                }
            }
            else {
                warn "\tIt's definately not a one\n" if DEBUG;
                $self->_is_maybe_one( 0 );
            }
        }

        if( $self->_bit_count >= $self->bit_count ) {
            warn "\tWe met our bit count, so call the callback\n" if DEBUG;
            $self->callback->({
                pulse_obj => $self,
                code => $self->_bits
            });

            $self->_zero_index(0);
            $self->_one_index(0);
            $self->_is_maybe_zero(1);
            $self->_is_maybe_one(1);
            $self->_bit_count(0);
            $self->_did_see_header(0);
            $self->_bits(0);

        }
        elsif( (! $self->_is_maybe_zero) && (! $self->_is_maybe_one) ) {
            warn "\tWe've gotten to a bad state where nothing looks right. Resetting.\n"
                if DEBUG;
            $self->_zero_index(0);
            $self->_one_index(0);
            $self->_is_maybe_zero(1);
            $self->_is_maybe_one(1);
            $self->_bit_count(0);
            $self->_did_see_header(0);
            $self->_bit_count(0);
        }
    }
    else {
        if( $self->_match_line( $line, $self->header->[$self->_header_index] ) ) {
            $self->_add_header_index(1);

            if( $self->_header_index >= $self->header_length ) {
                warn "\tWe have a complete, valid header\n" if DEBUG;
                $self->_did_see_header( 1 );
                $self->_header_index( 0 );
            }
            else {
                warn "\tHave a partial header, sit tight for now\n" if DEBUG;
            }
        }
        else {
            warn "\tThis isn't the part of the header we were expecting. Reset.\n" if DEBUG;
            $self->_did_see_header( 0 );
            $self->_header_index( 0 );
        }
    }

    return;
}

sub _match_line
{
    my ($self, $line, $expect) = @_;
    my ($expect_type, $expect_num) = @{ $expect };
    warn "\tMatching '$line', expecting '$expect_type $expect_num'\n" if DEBUG;
    my ($type, $num) = $line =~ /\A (pulse|space) \s+ (\d+) /x;
    $expect_type = $type if $expect_type eq 'either';

    return (
        $self->_is_value_in_range( $num, $expect_num )
        && ($expect_type eq $type)
    ) ? 1 : 0;
}

sub _is_value_in_range
{
    my ($self, $val, $target_val) = @_;
    my $tolerance = $self->tolerance;
    my $min = $target_val - ($target_val * $tolerance);
    my $max = $target_val + ($target_val * $tolerance);
    warn "\tMatching $min <= $val <= $max\n" if DEBUG;
    return (($min <= $val) && ($val <= $max)) ? 1 : 0;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=encoding utf8

=head1 NAME

  Linux::IRPulses - Parse IR data from LIRC

=head1 SYNOPSIS

  use Linux::IRPulses; # exports pulse(), space(), and pulse_or_space()
  
  open( my $in, '-|', 'mode2' ) or die "Can't exec mode2: $!\n";
  
  my $ir = Linux::IRPulses->new({
      fh => $in,
      header => [ pulse 9000, space 4500 ],
      zero => [ pulse 563, space 563 ],
      one => [ pulse 563, space 1688 ],
      bit_count => 32,
      callback => sub {
          my ($args) = @_;
          my $ir = $args->{pulse_obj};
          my $code = $args->{code};
          ...
      },
  });
  $ir->run;

=head1 DESCRIPTION

Parses the pulse/space data coming from LIRC. Note that this works at a little lower 
level down the LIRC stack than usual. LIRC usually works by translating the pulses on 
its own, mapping that to a button on a remote, and then mapping that to a command to 
execute. If you want that, then look at L<Lirc::Client>.

This module grabs the pulse data coming out of LIRC and then translates that to binary. 
That lets you manipulate the raw encoding.

=head1 HOW IR REMOTES WORK

Perhaps not surprisingly, every company has their own weird way of encoding IR data. 
This usually breaks down to sending a header followed by zeros and ones that are 
encoded through sending pulses of different lengths. Everyone also has their own 
frequency for sending data, although 36KHz is common. Your IR receiver module needs 
to be set to the same frequency.

The length for encoding pulses has to deal with the fact that in the real world, 
the IR emitter and receiver won't shut off at exactly the right time. The pulse will 
tend to be a bit longer than specified; I've seen as high as 18%. Parsing must therefore 
allow a fudge factor in the exact numbers.

=head1 EXPORTS

The exports are to help you build a datastructure that the parser can use. In general, 
remotes tend to start with a long header, then a space, then a series of pulses and 
spaces.

For example, NEC remotes start with a header that pulses (voltage high) for 9000μs, 
followed by a space (voltage low) for 4500μs. After that, there are 32 bits. A zero is 
sent by a pulse of 563μs followed by a space of 563μs. A one is sent by a pulse of 
563μs followed by a space of 1688μs. We can build this in C<Linux::IRPulses> with:

  my $ir = Linux::IRPulses->new({
      header => [ pulse 9000, space 4500 ],
      zero => [ pulse 563, space 563 ],
      one => [ pulse 563, space 1688 ],
      ...
  });

Notice that the C<pulse()> and C<space()> exports help you to specify the datastructure.

Another example is EasyRaceLapTimer, which is an IR-based timing system for quadcopter 
FPV racing. To save on message time length, it encodes by the time of either the 
pulses or the spaces. For example, a 0110 would be sent by a pulse of 300μs, a space 
of 600μs, a pulse of 600μs, and a space of 300μs. That is, spaces and pulses always 
alternate, and the time of the space or pulse tells you if it's a one or zero.

To handle this, we use C<pulse_or_space()>:

  my $ir = Linux::IRPulses->new({
      header => [ pulse 300, space 300 ],
      zero => [ pulse_or_space 300 ],
      one => [ pulse_or_space 600 ],
      ...
  });

Which doesn't care if it comes across as a pulse or space, as long as the length is correct.

=head1 METHODS

=head2 new

  new({
      fh => $fh,
      header => [ pulse 9000, space 4500 ],
      zero => [ pulse 563, space 563 ],
      one => [ pulse 563, space 1688 ],
      bit_count => 32,
      callback => sub {
          my ($args) = @_;
          my $ir = $args->{pulse_obj};
          my $code = $args->{code};
          ...
      },
  });

Constructor.  The C<fh> argument is a filehandle that will be read for pulse data. In 
general, this should be a filehandle open for reading that's piped from LIRC's C<mode2> 
program. The C<bit_count> argument is the expected length of each message.

The C<header>, C<zero>, and C<one> arguments are arrayrefs that specify the format of 
the respective datapoint. The first data would match the first entry in C<header>, and 
then matching each subsequent entry in turn. Once we reach the end of the C<headers> 
list, we start matching C<zero> and C<one> in the same way. We continue matching 
zeros and ones until we hit C<bit_count>. At that point, we consider the message complete 
and pass the data to the subref in C<callback>.

=head2 run

Starts reading the data from the filehandle.  The callback will be hit during this 
process.

=head2 handle_line

  handle_line( $line );

Processes a single line of the forms:

  pulse 1000
  space 2000

Hits the callback if we gathered enough lines to get a full code. Be sure to C<chomp> the 
line before passing.

=head2 end

Stops the process of reading from the filehandle, returning to normal execution flow 
after the place C<run()> was called.

=head1 LICENSE

Copyright (c) 2016  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of 
      conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of
      conditions and the following disclaimer in the documentation and/or other materials 
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
