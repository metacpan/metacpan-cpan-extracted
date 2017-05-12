package Math::SymbolicX::Calculator::Interface::Shell;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Term::ReadLine;
use Params::Util qw/_INSTANCE/;
use Math::SymbolicX::Calculator;
use base 'Math::SymbolicX::Calculator::Interface';

# For convenience, we extend the Math::Symbolic parser.
# This will become the shortcut derive() => partial derivative.
$Math::Symbolic::Operator::Op_Symbols{derive} = Math::Symbolic::ExportConstants::U_P_DERIVATIVE;
$Math::Symbolic::Parser = Math::Symbolic::Parser->new();
$Math::Symbolic::Parser->Extend(<<'GRAMMAR');
    function_name: 'derive'
GRAMMAR

# Matches identifiers
my $Ident = $Math::SymbolicX::Calculator::Identifier_Regex;

=head1 NAME

Math::SymbolicX::Calculator::Interface::Shell - A Calculator Shell

=head1 SYNOPSIS

  # simplest form of usage:
  use Math::SymbolicX::Calculator::Interface::Shell;
  my $shell = Math::SymbolicX::Calculator::Interface::Shell->new();
  $shell->run();

=head1 DESCRIPTION

This module implements a shell interface to the Math::SymbolicX::Calculator.

=head1 METHODS

=cut


# defined or
sub _dor {
    foreach (@_) {
        return $_ if defined $_;
    }
    return(undef);
}


=head2 new

Returns a new shell application object. Call the C<run()> method on it
to run the application.

Optional parameters: (default in parenthesis)

  calc => a Math::SymbolicX::Calculator object to use
  input_handle => a file handle to read from (\*STDIN)
  prompt => the prompt string to use ('~> ')
  continued_prompt => prompt string to use for continued lines ('>> ')
  app_name => the name of the application ('Symbolic Calculator Shell')

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my %args = @_;

    my $self = {
        calc             => $args{calculator}
                            || Math::SymbolicX::Calculator->new(),
        input_handle     => $args{input_handle} || \*STDIN,
        prompt           => _dor($args{prompt}, '~> '),
        continued_prompt => _dor($args{continued_prompt}, '>> '),
        app_name         => _dor($args{app_name}, 'Symbolic Calculator Shell'),
    };
    bless $self => $class;

    $self->_setup_readline();

    return $self;
}

sub _setup_readline {
    my $self = shift;
    $self->{readline} = Term::ReadLine->new(
        $self->{app_name}, $self->{input_handle}, *STDOUT,
    );
    $self->{readline}->ornaments(0);
}


=head2 run

Runs the main loop of the shell.

=cut

sub run {
    my $self = shift;

    # FIXME refactor
    # Main Loop
    while (1) {
        # get a new expression.
        my $expr = $self->get_expression();
        
        return $self->exit_hook() if not defined $expr;

        my $cmd;
        # What type of command?
        if ($expr =~ /=~~?/) {
            $cmd = $self->_parse_transformation($expr);
        }
        elsif ($expr =~ /=/) {
            $cmd = $self->_parse_assignment($expr);
        }
        else {
            $cmd = $self->_parse_command($expr);
        }
    
        if (not defined $cmd) {
            next;
        }
        elsif (_INSTANCE($cmd, 'Math::SymbolicX::Calculator::Command')) {
            my @output = $self->calc->execute($cmd);
            $self->_generic_out(@output);
        }
        elsif (ref($cmd) eq 'ARRAY') {
            if ($cmd->[0] eq 'print') {
                $self->_generic_out(@{$cmd}[1..$#$cmd]);
            }
        }
        elsif ($cmd eq 'exit') {
            return $self->exit_hook();
        }
        else {
    
        }

    }

    return();
}

=head2 calc

Returns the Calculator object of this Shell.

=cut

sub calc {
    my $self = shift;
    return $self->{calc};
}

=head2 exit_hook

Call this before stopping the shell. It runs all cleanup actions
such as those needed for a possible persistance.

This method doesn't actually kill your script, but returns after
doing the cleanup.

=cut

sub exit_hook {
    my $self = shift;
    return();
}


=head2 error

Used to issue a warning to the user. First argument must be an error
message to display.

=cut

sub error {
    my $self = shift;
    my $message = shift;
    print "!!! $message\n";
}

=head2 get_expression

Reads a new expression from the input handle. An expression ends
in a semicolon followed by a newline.

Used internally by the run loop. Probably not that useful outside of
that.

Returns the expression or the empty list on error.

=cut

sub get_expression {
    my $self = shift;

    my $readline = $self->{readline};
    my $expr;
    while (1) {
        my $prompt = '';
        if (not defined $expr and defined $self->{prompt}) {
            $prompt = $self->{prompt}
        }
        else {
            $prompt = $self->{continued_prompt}
        }
        my $line = $readline->readline($prompt);
        return() if not defined $line;
        chomp $line;
        $line .= ' ';
        $expr .= $line;
        last if $line =~ /;\s*$/;
    }
    $expr =~ s/;\s*$//;
    return $expr;
}


=head2 _parse_command

Parses generic commands such as exit and print.

This might change. (Name and implementation)

First argument: Expression to parse.

FIXME: Document what this does or refactor

=cut

sub _parse_command {
    my $self = shift;
    my $expr = shift;

    if ($expr =~ /^\s*exit\s*$/i) {
        return 'exit';
    }
    elsif ($expr =~ /^\s*print\s+($Ident)\s*$/) {
        my $id = $1;
        return [
            'print', $id, "==", _dor($self->calc->stash($id), '/Undefined/')
        ];
    }
    elsif ($expr =~ /^\s*apply_deriv\s+($Ident)(?:\s*|\s+(\d+))$/) {
        my $level = $2||undef;
        my $id = $1;
        my $cmd = $self->calc->new_command(
            type => 'DerivativeApplication', symbol => $id,
            level => $level,
        );
        return $cmd;
    }
    elsif ($expr =~ /^\s*insert\s+($Ident|\*)\s+in\s+($Ident)\s*$/) {
        my $what = $1;
        my $where = $2;
        my $cmd = $self->calc->new_command(
            type => 'Insertion', symbol => $where,
            what => $what
        );
        return $cmd;
    }
    elsif ($expr =~ /^\s*$/) {
        return();
    }
    else {
        $self->error("Could not parse command '$expr'.");
        return();
    }

    die "Sanity check";
}

=head2 _generic_out

Generic output routine: Print Formulas and messages alike

FIXME: Subject to change and refactoring.

=cut

sub _generic_out {
    my $self = shift;
    my @out = @_;
    if (not @out) {
        print "\n";
        return();
    }

    my $str = join ' ',
        map {
            if (not defined) {
                "\n"
            }
            # insert special cases here...
            elsif (_INSTANCE($_, 'Math::Symbolic::Custom::Transformation')) {
                $_->to_string();
            }
            else {
                "$_"
            }
        } @out;

    $str .= "\n" if not $str =~ /\n$/;
    print $str;
    return(1);
}



1;
__END__

=head1 SEE ALSO

L<Term::ReadLine>

L<Math::SymbolicX::Calculator>,
L<Math::SymbolicX::Calculator::Interface::Web>

L<Math::Symbolic>, L<Math::Symbolic::Custom::Transformation>

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
