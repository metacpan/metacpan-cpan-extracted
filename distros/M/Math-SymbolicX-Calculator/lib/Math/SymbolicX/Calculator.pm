package Math::SymbolicX::Calculator;

use 5.006;
use strict;
use warnings;

use Params::Util qw/_INSTANCE/;

use Math::Symbolic ();
use Math::Symbolic::Custom::Transformation;
require Math::SymbolicX::Calculator::Command;

our $VERSION = '0.02';

use vars qw/$Identifier_Regex/;
$Identifier_Regex = qr/[a-zA-Z][a-zA-Z_0-9]*/;

=encoding utf8

=head1 NAME

Math::SymbolicX::Calculator - A representation of a Symbolic Calculator

=head1 SYNOPSIS

  # You probably want to use on of the interfaces instead such as
  # Math::SymbolicX::Calculator::Interface::Shell

  use Math::SymbolicX::Calculator;
  my $calc = Math::SymbolicX::Calculator->new();
  my $cmd = $calc->new_command(...);
  # ...
  $calc->execute($cmd);

=head1 DESCRIPTION

This class represents the state of a symbolic calculator. It is mainly
a glorified state hash of variables and their contents.

It can execute commands which are represented by
L<Math::SymbolicX::Calculator::Command> objects and which operate
on the symbol table on some way.

Any slot of the symbol table may either contain a L<Math::Symbolic> tree
or a L<Math::Symbolic::Custom::Transformation> object.

=head1 METHODS

=cut

=head2 new

Returns a new Calculator object.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my $self = {
        stash => {},
        history => [],
    };
    bless $self => $class;

    return $self;
}


=head2 new_command

This method is a short-cut to
L<Math::SymbolicX::Calculator::Command>'s C<new> method and
creates a new command object which can be executed using the
Calculator object.

=cut

sub new_command {
    my $self = shift;
    return Math::SymbolicX::Calculator::Command->new(@_);
}

=head2 execute

Executes the command given as first argument. The command should be a
L<Math::SymbolicX::Calculator::Command> object. Returns any
return values of the command's execution. (This may be a list!)

=cut

sub execute {
    my $self = shift;
    my $cmd = shift;
    
    my @output = $cmd->_execute($self);
    return @output;
}

=head2 stash

Accesses the symbol table hash with the symbol name given as first
argument. Valid symbol names match the regex C</[A-Za-z][A-Za-z0-9_]*/>.

(This is read only.)

=cut

sub stash {
    my $self = shift;
    my $sym = shift;
    return $self->{stash}{$sym};
}

=head2 get_transformation

First argument must be a symbol name. Accesses the Calculator symbol table
to fetch a transformation from it that is saved as the symbol.

If the smybol table contains a transformation in the specified slot,
that transformation is returned.

If it contains a formula, it manufactures a transformation from that
formula which amounts to replacing the specified symbol with
the formula.

If an error occurrs, an error message will be returned instead of
a C<Math::Symbolic::Custom::Transformation> object.

=cut

sub get_transformation {
    my $self = shift;
    my $sym = shift;

    my $obj = $self->stash($sym);
    
    if (_INSTANCE($obj, 'Math::Symbolic::Custom::Transformation')) {
        return $obj;
    }
    elsif (ref($obj) =~ /^Math::Symbolic::/) {
        # insertion of the form
        # "bar = baz^2; foo = bar+2; foo =~ bar;" ==> foo==baz^2+2
        my $trafo;
        eval {
            $trafo = Math::Symbolic::Custom::Transformation->new( $sym, $obj );
        };
        if ($@ or not defined $trafo) {
            my $error = "Invalid transformation: '$sym -> $obj' " . ($@?" Error: $@":"");
            return($error);
        }
        return $trafo;
    }
    else {
        my $error = "Invalid or undefined symbol '$sym'";
        return($error);
    }

    die "Sanity check";
}


1;

__END__

=head1 SEE ALSO

L<Math::SymbolicX::Calculator::Command>,
L<Math::SymbolicX::Calculator::Interface::Shell>

L<Math::Symbolic>, L<Math::Symbolic::Custom::Transformation>

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2013 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
