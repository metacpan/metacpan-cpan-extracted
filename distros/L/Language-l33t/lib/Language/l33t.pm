package Language::l33t;
our $AUTHORITY = 'cpan:YANICK'; 
# ABSTRACT: a l33t interpreter
$Language::l33t::VERSION = '1.0.1';
use 5.20.0;

use strict;
use warnings;

use Moo;
use MooX::HandlesVia;
use MooseX::MungeHas 'is_rw';

use Carp;

use Moose::Util::TypeConstraints;

use IO::Socket::INET;

use experimental 'signatures';

with 'Language::l33t::Operators';

use Types::Standard qw/ Int ArrayRef /;
use Type::Tiny;

my $l33tByteSize = Type::Tiny->new(
    name       => 'L33tByteSize',
    parent     => Int,
    constraint => sub { $_ > 10 },
    message    => sub  { "Byt3 s1z3 must be at l34st 11, n00b!" }
);

has debug => sub { 0 };

has code => ();

has source => (
    predicate => 1,
    clearer   => 1,
    trigger   => sub($self,@) {
        $self->_clear_memory;
        $self->_memory;
    },
);

has byte_size => ( is => 'ro', isa => $l33tByteSize, default => 256 );

has _memory => ( 
    writer => '_set_memory',
    predicate => '_has_memory',
    clearer => '_clear_memory',
    isa => ArrayRef[Int],
    lazy => 1,
    builder => 1,
    handles_via => 'Array',
    handles => {
        memory => 'elements',
        set_memory_cell => 'set',
        memory_size => 'count',
        memory_cell => 'get',
    },
);

sub _build__memory($self) {
    my @memory = ( map ( { my $s = 0; 
                        $s += $& while /\d/g; 
                        $s % $self->byte_size 
                      } split ' ', $self->source ), 0 );


    die "F00l! teh c0d3 1s b1g3R th4n teh m3m0ry!!1!\n" 
        if $self->memory_max_size < @memory;

    $self->mem_ptr( $#memory );
    return [ @memory ];
}

has memory_max_size => ( 
    is      => 'ro',
    default => 64 * 1024,
);

has mem_ptr => (); 

has op_ptr => ( 
    isa     => Int,
    default => 0,
);

after _clear_memory => sub($self) {
    $self->op_ptr(0);
    $self->mem_ptr(0);
};

sub reset($self) {
    $self->_clear_memory;
    $self->memory;
}


has stdout => sub { return \*STDOUT;  };
has stdin  => ();
has socket => ();

before run => sub($self,@) {
    die "L0L!!1!1!! n0 l33t pr0gr4m l04d3d, sUxX0r!\n"
        unless $self->_has_memory;
};

sub run ( $self, $nbr_iterations = -1 ) {
  
    while ( $self->_iterate ) {
        $nbr_iterations-- if $nbr_iterations != -1;
        return 1 unless $nbr_iterations;
    }

    return 0;
}

sub _iterate($self) {
    my $op_id = $self->memory_cell( $self->op_ptr ); 
 
    if ( $self->debug ) { 
        no warnings qw/ uninitialized /;
        warn "memory: ", join( ':', $self->memory ), "\n";
        warn "op_ptr: $self->op_ptr, ",
                "mem_ptr: $self->mem_ptr, ",
                "op: $op_id, ",
                "mem: ", $self->_get_current_mem, "\n";
    }

    return $self->opcode( $op_id );
}

sub _incr_op_ptr {
    $_[0]->op_ptr( $_[0]->op_ptr + ( $_[1] || 1 ) );
}

sub _incr_mem_ptr {
    my ( $self, $increment ) = @_;
    $increment ||= 1;
    $self->mem_ptr( ( $self->mem_ptr + $increment ) % $self->byte_size );
}

sub _incr_mem {
    my ( $self, $increment ) = @_;
    no warnings qw/ uninitialized /;
    $self->set_memory_cell( $self->mem_ptr => 
            ( $self->memory_cell( $self->mem_ptr ) + $increment ) %
            $self->byte_size );
}

sub _set_current_mem ($self, $value ) {
    return $self->memory_set( $self->mem_ptr => $value );
}


sub _get_current_mem($self) {
    return $self->memory_cell( $self->mem_ptr );
}

sub _current_op($self) {
    return $self->memory_cell( $self->op_ptr ) || 0;
}

'End of Language::l33t';

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::l33t - a l33t interpreter

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    use Language::l33t;

    my $interpreter = Language::l33t->new;
    $interpreter->set_source( 'Ph34r my l33t sk1llz' );
    $interpreter->run;

=head1 DESCRIPTION

Language::l33t is a Perl interpreter of the l33t language created by
Stephen McGreal and Alex Mole. For the specifications of l33t, refer
to L<Language::l33t::Specifications>.

=head1 METHODS

=head2 new( %options )

Creates a new interpreter. The options that can be passed to the function are:

=over

=item debug => $flag

If $flag is set to true, the interpreter will print debugging information
as it does its thing.

=item stdin => $io

Ties the stdin of the interpreter to the given object.

=item stdout => $io

Ties the stdout of the interpreter to the given object. 

E.g.:

    my $output;
    open my $fh_output, '>', \$output;

    my $l33t = Language::l33t->new( stdout => $fh_output );

    $l33t->set_source( $code );
    $l33t->run;

    print "l33t output: $output";

=item memory_max_size => $bytes

The size of the block of memory available to interpreter. By default set to
64K (as the specs recomment).

=item byte_size => $size

The size of a byte in the memory used by the interpreter. Defaults to
256 (so a memory byte can hold a value going from 0 to 255).

=back

=head2 source( $l33tcode )

Loads and "compiles" the string $l33tcode. If one program was already loaded,
it is clobbered by the newcomer. 

=head2 run( [ $nbr_iterations ] )

Runs the loaded program. If $nbr_iterations is given, interupts the program
after this number of iterations even if it hasn't terminated. Returns 0 in
case the program terminated by evaluating an END, 1 if it finished by reaching
$nbr_iterations.

=head2 reset

Reset the interpreter to its initial setting. Code is
recompiled, and pointers reset to their initial values. 

E.g.

    my $l33t = Language::l33t->new();
    $l33t->load( $code );
    $l33t->run;

    # to run the same code a second time
    $l33t->reset;
    $l33t->run;

=head2 memory

Returns the memory of the interpreter in its current state as an array.

=head1 DIAGNOSTICS

=over

=item F00l! teh c0d3 1s b1g3R th4n teh m3m0ry!!1!

You tried to load a program that is too big to fit in 
the memory. Note that at compile time, one byte is reserved
for the memory buffer, so the program's size must be less than
the memory size minus one byte.

=item Byt3 s1z3 must be at l34st 11, n00b!

The I<byte_size> argument of I<new()> was less than 11. 
The byte size of an interpreter must be at least 11 (to
accomodate for the opcodes).

=item L0L!!1!1!! n0 l33t pr0gr4m l04d3d, sUxX0r!

run() called before any program was load()ed.

=back

=head1 SEE ALSO

L<Language::l33t::Specifications>

=head1 THANKS 

It goes without saying, special thanks go 
to Stephen McGreal and Alex Mole for inventing l33t. 
They are teh rOxX0rs.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
