#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Language::Befunge::Interpreter;
# ABSTRACT: an interpreter for Language::Befunge
$Language::Befunge::Interpreter::VERSION = '5.000';
use Carp;
use Language::Befunge::Debug;
use Language::Befunge::IP;
use UNIVERSAL::require;

# FIXME: wtf? always use get_/set_ or mutators, but not a mix of them!
use Class::XSAccessor
    getters => {
        get_dimensions => 'dimensions',
        get_file       => 'file',
        get_params     => 'params',
        get_retval     => 'retval',
        get_storage    => 'storage',
        get_curip      => 'curip',
        get_ips        => 'ips',
        get_newips     => 'newips',
        get_ops        => 'ops',
        get_handprint  => 'handprint',
        get_wrapping   => '_wrapping',
        _get_input     => '_input',
    },
    setters => {
        set_dimensions => 'dimensions',
        set_file       => 'file',
        set_params     => 'params',
        set_retval     => 'retval',
        set_curip      => 'curip',
        set_ips        => 'ips',
        set_newips     => 'newips',
        set_ops        => 'ops',
        set_handprint  => 'handprint',
        _set_input     => '_input',
    };


# Public variables of the module.
$| = 1;


# -- CONSTRUCTOR


#
# my $interpreter = LBI->new( $opts )
#
# Create a new funge interpreter. One can pass some options as a hash
# reference, with the following keys:
#  - file:     the filename to read funge code from (default: blank storage)
#  - syntax:   the tunings set (default: 'befunge98')
#  - dims:     the number of dimensions
#  - ops:      the Ops subclass used in this interpreter
#  - storage:  the Storage subclass used in this interpreter
#  - wrapping: the Wrapping subclass used in this interpreter
#
# Usually, the "dims", "ops", "storage" and "wrapping" keys are left
# undefined, and are implied by the "syntax" key.
#
# Depending on the value of syntax will change the interpreter
# internals: set of allowed ops, storage implementation, wrapping. The
# following values are recognized for 'syntax' (with in order: the
# number of dimensions, the set of operation loaded, the storage
# implementation and the wrapping implementation):
#
#  - unefunge98: 1, LBO:Unefunge98, LBS:Generic::AoA, LBW:LaheySpace
#  - befunge98:  2, LBO:Befunge98,  LBS:2D:Sparse,    LBW:LaheySpace
#  - trefunge98: 3, LBO:GenericFunge98, LBS:Generic::AoA, LBW:LaheySpace
#  - 4funge98:   4, LBO:GenericFunge98, LBS:Generic::AoA, LBW:LaheySpace
#  - 5funge98:   5, LBO:GenericFunge98, LBS:Generic::AoA, LBW:LaheySpace
#  ...and so on.
#
#
# If none of those values suit your needs, you can pass the value
# 'custom' and in that case you're responsible for also giving
# appropriate values for the keys 'dims', 'ops', 'storage', 'wrapping'.
# Note that those values will be ignored for all syntax values beside
# 'custom'.
#
sub new {
    my ($class, $opts) = @_;

    $opts //= { dims => 2 };
    unless(exists($$opts{syntax})) {
        $$opts{dims} //= 2;
        croak("If you pass a 'dims' attribute, it must be numeric.")
            if $$opts{dims} =~ /\D/;
        my %defaults = (
            1 => 'unefunge98',
            2 => 'befunge98',
            3 => 'trefunge98',
        );
        if(exists($defaults{$$opts{dims}})) {
            $$opts{syntax} = $defaults{$$opts{dims}};
        } else {
            $$opts{syntax} = $$opts{dims} . 'funge98';
        }
    }

    # select the classes to use, depending on the wanted syntax.
    my $lbo = 'Language::Befunge::Ops::';
    my $lbs = 'Language::Befunge::Storage::';
    my $lbw = 'Language::Befunge::Wrapping::';
    if ( $opts->{syntax} eq 'unefunge98' ) {
        $opts->{dims}     = 1                     unless defined $opts->{dims};
        $opts->{ops}      = $lbo . 'Unefunge98'   unless defined $opts->{ops};
        $opts->{storage}  = $lbs . 'Generic::AoA' unless defined $opts->{storage};
        $opts->{wrapping} = $lbw . 'LaheySpace'   unless defined $opts->{wrapping};
    } elsif ( $opts->{syntax} eq 'befunge98' ) {
        $opts->{dims}     = 2                     unless defined $opts->{dims};
        $opts->{ops}      = $lbo . 'Befunge98'    unless defined $opts->{ops};
        $opts->{storage}  = $lbs . '2D::Sparse'   unless defined $opts->{storage};
        $opts->{wrapping} = $lbw . 'LaheySpace'   unless defined $opts->{wrapping};
    } elsif ( $opts->{syntax} eq 'trefunge98' ) {
        $opts->{dims}     = 3                       unless defined $opts->{dims};
        $opts->{ops}      = $lbo . 'GenericFunge98' unless defined $opts->{ops};
        $opts->{storage}  = $lbs . 'Generic::AoA'   unless defined $opts->{storage};
        $opts->{wrapping} = $lbw . 'LaheySpace'     unless defined $opts->{wrapping};
    } elsif ( $opts->{syntax} =~ /(\d+)funge98$/ ) {
        $opts->{dims}     = $1                      unless defined $opts->{dims};
        $opts->{ops}      = $lbo . 'GenericFunge98' unless defined $opts->{ops};
        $opts->{storage}  = $lbs . 'Generic::AoA'   unless defined $opts->{storage};
        $opts->{wrapping} = $lbw . 'LaheySpace'     unless defined $opts->{wrapping};
    } else {
        croak "syntax '$opts->{syntax}' not recognized.";
    }

    # load the classes (through UNIVERSAL::require)
    $opts->{ops}->use;
    $opts->{storage}->use;
    $opts->{wrapping}->use;

    # create the object
    my $wrapping = $opts->{wrapping}->new;
    my $self  = {
        dimensions => $opts->{dims},
        storage    => $opts->{storage}->new( $opts->{dims}, Wrapping => $wrapping ),
        file       => "STDIN",
        _input     => '',
        params     => [],
        retval     => 0,
        curip      => undef,
        ops        => $opts->{ops}->get_ops_map,
        ips        => [],
        newips     => [],
        handprint  => 'JQBF', # the official handprint
        _wrapping  => $wrapping,
      };
    bless $self, $class;

    # read the file if needed.
    defined($opts->{file}) and $self->read_file( $opts->{file} );

    # return the object.
    return $self;
}




# -- PUBLIC METHODS

# - Utilities


#
# move_ip( $ip )
#
# Move $ip according to its delta on the storage. Spaces and comments
# (enclosed with semi-colons ';') are skipped silently.
#
sub move_ip {
    my ($self, $ip) = @_;

    my $storage = $self->get_storage;
    $self->_move_ip_once($ip);
    my $char;
    my %seen_before;
    MOVE: while (1) {
        # sanity check
        my $pos = $ip->get_position;
        $self->abort("infinite loop")
            if exists($seen_before{$pos});
        $seen_before{$pos} = 1;
        $char = $storage->get_char($pos);

        # skip spaces
        if ( $char eq ' ' ) {
            $self->_move_ip_till( $ip, qr/ / );   # skip all spaces
            $self->_move_ip_once($ip);            # skip last space
            redo MOVE;
        }

        # skip comments
        if ( $char eq ';' ) {
            $self->_move_ip_once($ip);             # skip comment ';'
            $self->_move_ip_till( $ip, qr/[^;]/ ); # till just before matching ';'
            $self->_move_ip_once($ip);             # till matching ';'
            $self->_move_ip_once($ip);             # till just after matching ';'
            redo MOVE;
        }

        last MOVE;
    }
}


#
# abort( reason )
#
# Abort the interpreter with the given reason, as well as the current
# file and coordinate of the offending instruction.
#
sub abort {
    my $self = shift;
    my $file = $self->get_file;
    my $v = $self->get_curip->get_position;
    croak "$file $v: ", @_;
}


#
# set_input( $string )
#
# Preload the input buffer with the given value.
#
sub set_input {
    my ($self, $str) = @_;
    $self->_set_input($str);
}


#
# get_input(  )
#
# Fetch a character of input from the input buffer, or else, directly
# from stdin.
#

sub get_input {
    my $self = shift;
    return substr($$self{_input}, 0, 1, '') if length $self->_get_input;
    my $char;
    my $rv = sysread(STDIN, $char, 1);
    return $char if length $char;
    return undef;
}


# - Code and Data Storage

#
# read_file( filename )
#
# Read a file (given as argument) and store its code.
#
# Side effect: clear the previous code.
#
sub read_file {
    my ($self, $file) = @_;

    # Fetch the code.
    my $code;
    open BF, "<$file" or croak "$!";
    {
        local $/; # slurp mode.
        $code = <BF>;
    }
    close BF;

    # Store code.
    $self->set_file( $file );
    $self->store_code( $code );
}


#
# store_code( code )
#
# Store the given code in the Lahey space.
#
# Side effect: clear the previous code.
#
sub store_code {
    my ($self, $code) = @_;
    debug( "Storing code\n" );
    $self->get_storage->clear;
    $self->get_storage->store( $code );
}


# - Run methods


#
# run_code( [params]  )
#
# Run the current code. That is, create a new Instruction Pointer and
# move it around the code.
#
# Return the exit code of the program.
#
sub run_code {
    my $self = shift;
    $self->set_params( [ @_ ] );

    # Cosmetics.
    debug( "\n-= NEW RUN (".$self->get_file.") =-\n" );

    # Create the first Instruction Pointer.
    $self->set_ips( [ Language::Befunge::IP->new($$self{dimensions}) ] );
    $self->set_retval(0);

    # Loop as long as there are IPs.
    $self->next_tick while scalar @{ $self->get_ips };

    # Return the exit code.
    return $self->get_retval;
}


#
# next_tick(  )
#
# Finish the current tick and stop just before the next tick.
#
sub next_tick {
    my $self = shift;

    # Cosmetics.
    debug( "Tick!\n" );

    # Process the set of IPs.
    $self->set_newips( [] );
    $self->process_ip while $self->set_curip( shift @{ $self->get_ips } );

    # Copy the new ips.
    $self->set_ips( $self->get_newips );
}


#
# process_ip(  )
#
# Process the current ip.
#
sub process_ip {
    my ($self, $continue) = @_;
    $continue = 1 unless defined $continue;
    my $ip = $self->get_curip;

    # Fetch values for this IP.
    my $v  = $ip->get_position;
    my $ord  = $self->get_storage->get_value( $v );
    my $char = $self->get_storage->get_char( $v );

    # Cosmetics.
    debug( "#".$ip->get_id.":$v: $char (ord=$ord)  Stack=(@{$ip->get_toss})\n" );

    # Check if we are in string-mode.
    if ( $ip->get_string_mode ) {
        if ( $char eq '"' ) {
            # End of string-mode.
            debug( "leaving string-mode\n" );
            $ip->set_string_mode(0);

        } elsif ( $char eq ' ' ) {
            # A serie of spaces, to be treated as one space.
            debug( "string-mode: pushing char ' '\n" );
            $self->_move_ip_till( $ip, qr/ / );
            $ip->spush( $ord );

        } else {
            # A banal character.
            debug( "string-mode: pushing char '$char'\n" );
            $ip->spush( $ord );
        }

    } else {
        $self->_do_instruction($char);
    }

    if ($continue) {
        # Tick done for this IP, let's move it and push it in the
        # set of non-terminated IPs.
        if ( $ip->get_string_mode ) {
            $self->_move_ip_once( $self->get_curip );
        } else {
            $self->move_ip( $self->get_curip );
        }
        push @{ $self->get_newips }, $ip unless $ip->get_end;
    }
}

#-- PRIVATE METHODS

#
# $lbi->_do_instruction( $char );
#
# interpret instruction $char according to loaded ops map.
#
sub _do_instruction {
    my ($self, $char) = @_;

    if ( exists $self->get_ops->{$char} ) {
        # regular instruction.
        my $meth = $self->get_ops->{$char};
        $meth->($self, $char);

    } else {
        # not a regular instruction: reflect.
        my $ord = ord($char);
        debug( "the command value $ord (char='$char') is not implemented.\n");
        $self->get_curip->dir_reverse;
    }
}


#
# $lbi->_move_ip_once( $ip );
#
# move $ip one step further, according to its velocity. if $ip gets out
# of bounds, then a wrapping is performed (according to current
# interpreter wrapping implementation) on the ip.
#
sub _move_ip_once {
    my ($self, $ip) = @_;
    my $storage = $self->get_storage;

    # fetch the current position of the ip.
    my $v = $ip->get_position;
    my $d = $ip->get_delta;

    # now, let's move the ip.
    $v += $d;

    if ( $v->bounds_check($storage->min, $storage->max) ) {
        # within bounds - store new position.
        $ip->set_position( $v );
    } else {
        # wrap needed - this will update the position.
        $self->get_wrapping->wrap( $storage, $ip );
    }
}


#
# _move_ip_till( $ip,regex )
#
# Move $ip according to its delta on the storage,  as long as the pointed
# character match the supplied regex (a qr// object).
#
# Example: given the code C<;foobar;> (assuming the IP points on the
# first C<;>) and the regex C<qr/[^;]/>, the IP will move in order to
# point on the C<r>.
#
sub _move_ip_till {
    my ($self, $ip, $re) = @_;
    my $storage = $self->get_storage;

    my $orig = $ip->get_position;
    # moving as long as we did not reach the condition.
    while ( $storage->get_char($ip->get_position) =~ $re ) {
        $self->_move_ip_once($ip);
        $self->abort("infinite loop")
        if $ip->get_position == $orig;
    }

    # we moved one char too far.
    $ip->dir_reverse;
    $self->_move_ip_once($ip);
    $ip->dir_reverse;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Interpreter - an interpreter for Language::Befunge

=head1 VERSION

version 5.000

=head1 CONSTRUCTOR

=head2 new( [filename, ] [ Key => Value, ... ] )

Create a new Befunge interpreter.  As an optional first argument, you
can pass it a filename to read Funge code from (default: blank
torus).  All other arguments are key=>value pairs.  The following
keys are accepted, with their default values shown:

    Dimensions => 2,
    Syntax     => 'befunge98',
    Storage    => 'laheyspace'

=head1 ACCESSORS

The following is a list of attributes of a Language::Befunge
object. For each of them, a method C<get_foobar> and C<set_foobar>
exists, which does what you can imagine - and if you can't, then i
wonder why you are reading this! :-)

=over 4

=item get_curip() / set_curip()

the current Instruction Pointer processed (a L::B::IP object)

=item get_dimensions() / set_dimensions()

the number of dimensions this interpreter works in.

=item get_file() / set_file()

the script filename (a string)

=item get_handprint() / set_handprint()

the handprint of the interpreter

=item get_ips() / set_ips()

the current set of IPs travelling in the Lahey space (an array
reference)

=item get_newips() / set_newips()

the set of IPs that B<will> travel in the Lahey space B<after> the
current tick (an array reference)

=item get_ops() / set_ops()

the current supported operations set.

=item get_params() / set_params()

the parameters of the script (an array reference)

=item get_retval() / set_retval()

the current return value of the interpreter (an integer)

=item get_storage()

the C<LB::Storage> object containing the playfield.

=item get_wrapping()

the C<LB::Wrapping> object driving wrapping policy. Private.

=back

=head1 PUBLIC METHODS

=head2 Utilities

=over 4

=item move_ip( $ip [, $regex] )

Move the C<$ip> according to its delta on the storage.

If C<$regex> ( a C<qr//> object ) is specified, then C<$ip> will move as
long as the pointed character match the supplied regex.

Example: given the code C<;foobar;> (assuming the IP points on the
first C<;>) and the regex C<qr/[^;]/>, the IP will move in order to
point on the C<r>.

=item abort( reason )

Abort the interpreter with the given reason, as well as the current
file and coordinate of the offending instruction.

=item set_input( $string )

Preload the input buffer with the given value.

=item get_input(  )

Fetch a character of input from the input buffer, or else, directly
from stdin.

=back

=head2 Code and Data Storage

=over 4

=item read_file( filename )

Read a file (given as argument) and store its code.

Side effect: clear the previous code.

=item store_code( code )

Store the given code in the Lahey space.

Side effect: clear the previous code.

=back

=head2 Run methods

=over 4

=item run_code( [params]  )

Run the current code. That is, create a new Instruction Pointer and
move it around the code.

Return the exit code of the program.

=item next_tick(  )

Finish the current tick and stop just before the next tick.

=item process_ip(  )

Process the current ip.

=back

=head1 TODO

=over 4

=item o

Write standard libraries.

=back

=head1 BUGS

Although this module comes with a full set of tests, maybe there are
subtle bugs - or maybe even I misinterpreted the Funge-98
specs. Please report them to me.

There are some bugs anyway, but they come from the specs:

=over 4

=item o

About the 18th cell pushed by the C<y> instruction: Funge specs just
tell to push onto the stack the size of the stacks, but nothing is
said about how user will retrieve the number of stacks.

=item o

About the load semantics. Once a library is loaded, the interpreter is
to put onto the TOSS the fingerprint of the just-loaded library. But
nothing is said if the fingerprint is bigger than the maximum cell
width (here, 4 bytes). This means that libraries can't have a name
bigger than C<0x80000000>, ie, more than four letters with the first
one smaller than C<P> (C<chr(80)>).

Since perl is not so rigid, one can build libraries with more than
four letters, but perl will issue a warning about non-portability of
numbers greater than C<0xffffffff>.

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
