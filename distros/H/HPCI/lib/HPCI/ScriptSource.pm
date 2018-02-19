package HPCI::ScriptSource;

# safe Perl
use warnings;
use strict;
use Carp;

use Moose::Role;

our @source_commands;

our @pre_commands;
our @post_success_commands;
our @post_failure_commands;
our @post_always_commands;

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

sub print_list {
    my $self   = shift;
    my $fh     = shift;
    my $list   = shift;
    my $indent = shift // '';
    for my $elem (@$list) {
        print $fh "$indent$_\n" for ref $elem ? @$elem : $elem;
    }
}

sub print_script_source {
	my $self = shift;
	my $fh   = shift;
    $self->print_list( $fh, \@source_commands );
    $self->print_list( $fh, $self->source_command ) if $self->_has_source_command;
}

sub print_pre_commands {
    my $self = shift;
    my $fh   = shift;
    $self->print_list( $fh, \@pre_commands )
        if @pre_commands;
}

sub print_post_commands {
    my $self = shift;
    my $fh   = shift;
    if (@post_success_commands or @post_failure_commands or @post_always_commands) {
        print $fh "__STAGE_STATUS__=\$?\n";
        print $fh "if [[ \$__STAGE_STATUS__ -eq 0 ]]\n";
        print $fh "then\n";

        my $indent = '    ';

        if (@post_success_commands) {
            $self->print_list( $fh, \@post_success_commands, $indent );
        }
        else {
            print $fh "${indent}__IGNORE_ME_=0\n";
        }

        if (@post_failure_commands) {
            print $fh "else\n";
            $self->print_list( $fh, \@post_failure_commands, $indent );
        }

        print $fh "fi\n";

        $self->print_list( $fh, \@post_always_commands, $indent )
            if @post_always_commands;

        print $fh "exit \$__STAGE_STATUS__\n";
    }
}

1;
