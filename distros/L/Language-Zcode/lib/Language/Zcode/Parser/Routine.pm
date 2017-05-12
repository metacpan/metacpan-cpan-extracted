package Language::Zcode::Parser::Routine;

use strict;
use warnings;

=head1 NAME

Language::Zcode::Parser::Routine - A single Z-code subroutine

=head2 SYNOPSIS

    # New routine at address $start, ends at $end
    my $routine = new Language::Zcode::Parser::Routine $address;
    $routine->end($end);

    # Now actually parse it
    $routine => parse();

    # ... and look at the parsed commands (which are simple hashes, not objects)
    my @commands = $routine->commands();
    print map {$_->{opcode_address}, " ", $_->{opcode}, "\n"} @commands;

=head1 DESCRIPTION

A set of Z-code commands at a given address.

=cut

=head2 new (address)

Create a new subroutine at given address. The Z-code will not be parsed until
a parse() command is explicitly given.

=cut

sub new {
    my ($class, $address, %arg) = @_;
    my $self = {
	locals => [], # default values for local variables
	commands => [], # parsed Z-code commands in this sub
	txd_commands => [], # commands in this sub read by txd (for debugging)
	%arg,
    };
    bless $self, $class;
    $self->address($address);
#    print "New $address: ",%$self,"\n";
    return $self;
}

=head2 address (val)

get/set start address of the subroutine

=cut

sub address { 
    my ($self, $val) = @_; 
    $self->{address} = $val if defined $val;
    return $self->{address};
}

=head2 end (val)

get/set end address (including padding zeroes!) of the subroutine

=cut

sub end { 
    my ($self, $val) = @_; 
    $self->{end} = $val if defined $val;
    return $self->{end};
}

=head2 last_command_address (val)

get/set address of last command in the subroutine (needed because "end"
may include padding zeroes)

=cut

sub last_command_address { 
    my ($self, $val) = @_; 
    $self->{last_command_address} = $val if defined $val;
    return $self->{last_command_address};
}

=head2 locals (list of values)

get/set default values of this sub's local variables (returns list, not ref)

=cut

sub locals { 
    my $self = shift; 
    $self->{locals} = [@_] if @_;
    return @{ $self->{locals} }
}

=head2 commands (list of values)

get/set parsed Z-code commands in this sub (returns list, not ref)

=cut

sub commands { 
    my $self = shift;
    $self->{commands} = [@_] if @_;
    return @{ $self->{commands} }
}

=head2 txd_commands (list of values)

get/set commands in this sub as returned by the txd Z-code parsing program,
to compare with my Pure Perl results. (returns list, not ref)

=cut

sub txd_commands { 
    my $self = shift;
    $self->{txd_commands} = [@_] if @_;
    return @{ $self->{txd_commands} }
}

=head2 parse()

Parse (and store) the commands in this sub

=cut

sub parse {
    my $self = shift;
    my ($addr, $stop) = ($self->address, $self->last_command_address);
    # Side effect: moves PC to first command in the sub
    $self->locals(&Language::Zcode::Parser::Opcode::parse_sub_header($addr));
    my @commands;
    push @commands, { &Language::Zcode::Parser::Opcode::parse_command() }
	until $Language::Zcode::Parser::Opcode::PC > $stop;
    $self->commands(@commands);
    return;
}

1;
