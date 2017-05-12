package CPU::Emulator::6502;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

use Text::SimpleTable;
use CPU::Emulator::6502::Addressing;
use Module::Pluggable::Object;

# status constants
use constant SET_CARRY     => 0x01;
use constant SET_ZERO      => 0x02;
use constant SET_INTERRUPT => 0x04;
use constant SET_DECIMAL   => 0x08;
use constant SET_BRK       => 0x10;
use constant SET_UNUSED    => 0x20;
use constant SET_OVERFLOW  => 0x40;
use constant SET_SIGN      => 0x80;

use constant CLEAR_CARRY     => 0xFE;
use constant CLEAR_ZERO      => 0xFD;
use constant CLEAR_INTERRUPT => 0xFB;
use constant CLEAR_DECIMAL   => 0xF7;
use constant CLEAR_BRK       => 0xEF;
use constant CLEAR_UNUSED    => 0xDF;
use constant CLEAR_OVERFLOW  => 0xBF;
use constant CLEAR_SIGN      => 0x7F;

use constant CLEAR_SZC  => CLEAR_SIGN & CLEAR_ZERO & CLEAR_CARRY;
use constant CLEAR_SOZ  => CLEAR_SIGN & CLEAR_OVERFLOW & CLEAR_ZERO;
use constant CLEAR_ZS   => CLEAR_ZERO & CLEAR_SIGN;
use constant CLEAR_ZOCS => CLEAR_ZERO & CLEAR_OVERFLOW & CLEAR_CARRY & CLEAR_SIGN;

# interrupt constants
use constant BRK    => 0x01;
use constant IRQ    => 0x02;
use constant NMI    => 0x04;
use constant RESET  => 0x08;
use constant APUIRQ => 0x10;

__PACKAGE__->mk_accessors(
    qw( registers memory interrupt_line toggle
    frame_counter cycle_counter instruction_table
    current_op current_op_address
    )
);

my @registers = qw( acc x y pc sp status );

=head1 NAME

CPU::Emulator::6502 - Class representing a 6502 CPU

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 REGISTERS

=over 4

=item * acc - Accumulator

=item * x

=item * y

=item * pc - Program Counter

=item * sp - Stack Pointer

=item * status

=back

=head1 METHODS

=head2 new( )

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );

    $self->registers( {
        map { $_ => undef } @registers
    } );
    $self->interrupt_line( 0 );
    $self->cycle_counter( 0 );

    return $self;
}

=head2 init( )

=cut

sub init {
    my $self = shift;
    my $reg = $self->registers;

    $self->memory( [ ( undef ) x 0xFF ] );
    for( @registers ) {
        $reg->{ $_ } =  0;
    }

    $reg->{ status } = SET_UNUSED;
    $self->create_instruction_table;
}

=head2 create_instruction_table

Dynamically loads all instructions from the CPU::Emulator::6502::Op
namespace and creates a table.

=cut

sub create_instruction_table {
    my $self  = shift;
    my %table;

    my $class = __PACKAGE__ . '::Op';
    my $locator = Module::Pluggable::Object->new(
        search_path => $class,
        require     => 1
    );
    
    for my $instruction ( $locator->plugins ) {
        my $ops = $instruction->INSTRUCTIONS;
        ( my $name = $instruction ) =~ s{$class\::}{};
        @table{ keys %$ops } = map { $_->{ name } = $name; $_ } values %$ops;
    }

    $self->instruction_table( \%table );
}

=head2 reset( )

Simulate a hardware reset or power-on

=cut

sub reset {
    my $self = shift;
    
}

=head2 RAM_read( $address )

Reads data from C<$address> in memory.

=cut

sub RAM_read {
    my $self = shift;
    return $self->memory->[ shift ];
}

=head2 RAM_write( $address => $data )

Writes C<$data> to C<$address> in memory.

=cut

sub RAM_write {
    my $self = shift;
    $self->memory->[ shift ] = shift;
}

=head2 interrupt_request()

=cut

sub interrupt_request {
    my $self = shift;
    my $mem  = $self->memory;
    my $reg  = $self->registers;
    my $pc   = $reg->{ pc };
    my $int  = $self->interrupt_line;

    $self->push_stack( $self->hi_byte( $pc + 2 ) );
    $self->push_stack( $self->lo_byte( $pc + 2 ) );
    $self->push_stack( $reg->{ status } );

    if( $int == IRQ ) {
        $reg->{ pc } = $self->make_word( $mem->[ 0xFFFE ], $mem->[ 0xFFFF ] );
    }
    elsif( $int == NMI ) {
        $reg->{ pc } = $self->make_word( $mem->[ 0xFFFA ], $mem->[ 0xFFFB ] );
    }

    $self->interrupt_line( 0 );
    $self->cycle_counter( $self->cycle_counter + 7 );
}

=head2 execute_instruction( )

=cut

sub execute_instruction {
    my $self = shift;
    my $reg = $self->registers;

    if ( $self->interrupt_line ) {
        if( $reg->{ status } & SET_INTERRUPT ) {
            if( $self->interrupt_line & NMI ) {
                $self->interrupt_line( NMI );
                $self->interrupt_request;
            }
        }
        else {
            $self->interrupt_request;
        }
    }

    my $op = $self->get_instruction;
    my $table = $self->instruction_table;
    my $mode;

    $mode = $table->{ $op }->{ addressing } if $table->{ $op };

    my @args;
    if( $mode and my $sub = CPU::Emulator::6502::Addressing->can( $mode ) ) {
        @args = $sub->( $self );
    }

    if( !$table->{ $op } ) {
        $self->cycle_counter( $self->cycle_counter + 2 );
    }
    else {
        no strict 'refs';
        $table->{ $op }->{ code }->( $self, @args );
        $self->cycle_counter( $self->cycle_counter + $table->{ $op }->{ cycles } );
    }

}

=head2 get_instruction( )

Reads the op from memory then moves the program counter forward 1.

=cut

sub get_instruction {
    my $self = shift;
    my $reg  = $self->registers;
    
    $self->current_op_address( $reg->{ pc } );
    my $op = $self->RAM_read( $reg->{ pc }++ );
    return $self->current_op( $op );
}

=head2 debug( )

This will return of a string with some debugging info, including: the current
instruction, the pc location of the instruction, 10 lines of context from the
PRG at the pc location and the state of the stack, sp, a, x, y and status
registers after the op has executed.

=cut

sub debug { 
    my $self = shift;
    my $reg = $self->registers;

    my $t = Text::SimpleTable->new(
        [ 4, 'PC' ], [ 4, 'OP' ], [ 4, 'SP' ], [ 2, 'A' ], [ 2, 'X' ], [ 2, 'Y' ], [ 8, 'Status' ],
    );

    my $status = $reg->{ status };
    my $a_status = '';
    $a_status .= $status & SET_SIGN ? 'N' : '.';
    $a_status .= $status & SET_OVERFLOW ? 'V' : '.';
    $a_status .= $status & SET_UNUSED ? '-' : '.';
    $a_status .= $status & SET_BRK ? 'B' : '.';
    $a_status .= $status & SET_DECIMAL ? 'D' : '.';
    $a_status .= $status & SET_INTERRUPT ? 'I' : '.';
    $a_status .= $status & SET_ZERO ? 'Z' : '.';
    $a_status .= $status & SET_CARRY ? 'C' : '.';

    my $addr = $self->current_op_address;
    $t->row(
        $addr ? sprintf( '%x', $addr ) : '-',
        defined $self->current_op ? sprintf( '%s', $self->instruction_table->{ $self->current_op }->{ name } ) : '-',
        ( map { sprintf( '%x', $reg->{ $_ } ) } qw( sp acc x y ) ),
        $a_status,
    );

    my $t_stack = Text::SimpleTable->new(
        [ 5,  'Stack' ]
    );

    my $t_code = Text::SimpleTable->new(
        [ 4, 'Addr' ], [ 27,  'Code' ]
    );

    for( 0..9 ) {
        $t_stack->row( sprintf( '%x', $self->memory->[ 0x1FF - $_ ] ) );
        if( $addr ) {
            my $line = $addr + $_;
            $t_code->row( sprintf( '%x', $line ), sprintf( '%x', $self->memory->[ $line ] ) );
        }
        else {
            $t_code->row( '-', '-' );
        }
    }

    my @s_rows = split( "\n", $t_stack->draw );
    my @c_rows = split( "\n", $t_code->draw );
    my $output = '';

    while( @s_rows ) {
        $output .= join( ' ', shift( @s_rows ), shift( @c_rows ) );
        $output .= "\n";
    }
    

    return $t->draw . $output;
}

=head2 set_nz( $value )

Sets the Sign and Zero status flags based on C<$value>.

=cut

sub set_nz {
    my $self = shift;
    my $value = shift;
    my $reg = $self->registers;

    $reg->{ status } &= CLEAR_ZS;

    if( $value & 0x80 ) {
        $reg->{ status } |= SET_SIGN;
    }
    elsif( $value == 0 ) {
        $reg->{ status } |= SET_ZERO;
    }
}

=head2 push_stack( $value )

Pushes C<$value> onto the stack and decrements the stack pointer.

=cut

sub push_stack {
    my $self = shift;
    my $value = shift;
    my $reg  = $self->registers;

    $self->memory->[ $reg->{ sp } + 0x100 ] = $value;
    $reg->{ sp }--;
}

=head2 pop_stack( )

Increments the stack pointer and returns the current stack value.

=cut

sub pop_stack {
    my $self = shift;
    my $reg  = $self->registers;

    $reg->{ sp }++;
    my $value = $self->memory->[ $reg->{ sp } + 0x100 ];
    return $value;
}

=head2 branch_if( $bool )

Branches if C<$bool> is true.

=cut

sub branch_if {
    my $self = shift;
    my $reg  = $self->registers;

    $reg->{ pc }++;

    # branch or not
    return if !shift;

    my $old_pc = $reg->{ pc } - 2;
    # address to branch to
    my $data = $self->memory->[ $reg->{ pc } - 1 ];

    if( $data & 0x80 ) {
        $reg->{ pc } -= ( 128 - ( $data & 0x7f ) );
    }
    else {
        $reg->{ pc } += $data;
    }

    # same mem page, add 1 cycles
    if( ( $reg->{ pc } & 0xff00 ) == ( $old_pc & 0xff00 ) ) {
        $self->cycle_counter( $self->cycle_counter + 1 );
    }
    # cross-page, add 2 cycles
    else {
        $self->cycle_counter( $self->cycle_counter + 2 );
    }
}

=head2 make_word( $lo, $hi )

Combines C<$lo> and C<$hi> into a 16-bit word.

=cut

sub make_word {
    my ( $self, $lo, $hi ) = @_;
    return $lo | ( $hi << 8 );
}

=head2 lo_byte( $word )

Returns the lower byte of C<$word>.

=cut

sub lo_byte {
    my( $self, $word ) = @_;
    return $word & 0xff;
}

=head2 hi_byte( $word )

Returns the higher byte of C<$word>.

=cut

sub hi_byte {
    my( $self, $word ) = @_;
    return ($word & 0xff00) >> 8;
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<Games::NES::Emulator>

=back

=cut

1;
