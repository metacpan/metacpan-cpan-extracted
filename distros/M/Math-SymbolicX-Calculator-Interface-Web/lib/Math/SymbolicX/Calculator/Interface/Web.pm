package Math::SymbolicX::Calculator::Interface::Web;
use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

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

Math::SymbolicX::Calculator::Interface::Web - An AJAXy web interface to the calculator

=head1 SYNOPSIS

  # simplest form of usage:
  use Math::SymbolicX::Calculator::Interface::Web;
  my $interface = Math::SymbolicX::Calculator::Interface::Web->new();
  # But you probably want to use
  # Math::SymbolicX::Calculator::Interface::Web::Server instead!

=head1 DESCRIPTION

This module implements an AJAX-enabled web interface to the
Math::SymbolicX::Calculator.

B<This is alpha software!>

You probably want to look at the C<symbolic_calculator_web_server>
script or the L<Math::SymbolicX::Calculator::Interface::Web::Server>
module which come with this distribution instead!

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

Returns a new web interface object.

Optional parameters: (default in parenthesis)

  calc => a Math::SymbolicX::Calculator object to use

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my %args = @_;

    my $self = {
        calc             => $args{calculator}
                            || Math::SymbolicX::Calculator->new(),
    };
    bless $self => $class;

    return $self;
}

=head2 execute_expression

Runs a single expression.

=cut

sub execute_expression {
    my $self = shift;

    my $expr = shift;
    my $out;
        
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
            return("ERROR: Invalid expression. Neither assignment, replacement, nor command.");
        }
        elsif (_INSTANCE($cmd, 'Math::SymbolicX::Calculator::Command')) {
            my @output = $self->calc->execute($cmd);
            $out .= $self->_generic_out(@output);
        }
        elsif (ref($cmd) eq 'ARRAY') {
            if ($cmd->[0] eq 'print') {
                $out .= $self->_generic_out(@{$cmd}[1..$#$cmd]);
            }
        }
        else {
    
        }


    return($out);
}

=head2 calc

Returns the Calculator object of this Web Interface.

=cut

sub calc {
    my $self = shift;
    return $self->{calc};
}

=head2 exit_hook

Call this before stopping the web interface. It runs all cleanup actions
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
message to display. This is currently ignored for the web
interface. Investigating methods to pass this to the client in
a reliable fashion.

=cut

sub error {
    my $self = shift;
    my $message = shift;
#    print "!!! $message\n";
}

=head2 _parse_command

Parses generic commands such as exit and print.

This might change. (Name and implementation)

First argument: Expression to parse.

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

Subject to change and refactoring.

=cut

sub _generic_out {
    my $self = shift;
    my @out = @_;
    if (not @out) {
        return("\n");
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
    return($str);
}

1;

__END__

=head1 SEE ALSO

L<Math::SymbolicX::Calculator::Interface::Web::Server>

L<CGI::Ajax>, L<HTTP::Server::Simple::CGI>

L<Math::SymbolicX::Calculator>,
L<Math::SymbolicX::Calculator::Interface::Shell>

L<Math::Symbolic>, L<Math::Symbolic::Custom::Transformation>

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
                       
