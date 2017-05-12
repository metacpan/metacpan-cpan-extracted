package HPCI::ScriptSource;

# safe Perl
use warnings;
use strict;
use Carp;

use Moose::Role;

our @source_commands;

has 'source_command' => (
	is        => 'ro',
	isa       => 'Str|ArrayRef[Str]',
	predicate => '_has_source_command'
);

before 'BUILD' => sub {
	my $self = shift;

	my $cmds = $self->_command_expansion_methods;
	unshift @$cmds, 'print_script_source';
};

sub print_script_source {
	my $self = shift;
	my $fh   = shift;
	my @sc = @source_commands, ($self->_has_source_command ? $self->source_command : ());
	for my $cmd (@sc) {
		print $fh "$_\n" for ref $cmd ? @$cmd : $cmd;
	}
}

1;
