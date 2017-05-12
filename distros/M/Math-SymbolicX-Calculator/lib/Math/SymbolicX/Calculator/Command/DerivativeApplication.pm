package Math::SymbolicX::Calculator::Command::DerivativeApplication;

use 5.006;
use strict;
use warnings;
use Params::Util qw/_INSTANCE/;
use base 'Math::SymbolicX::Calculator::Command';

our $VERSION = '0.02';

sub new {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my %args = @_;
    my $self = bless {
        symbol => $args{symbol},
        level => $args{level},
    } => $class;

    return $self;
}

sub _execute {
    my $self = shift;
    my $c = shift;
    
    my $sym = $self->{symbol};
    my $lvl = $self->{level};

    my $func = $c->{stash}{$sym};

    if (_INSTANCE($func, 'Math::Symbolic::Custom::Transformation')) {
        return "Cannot apply derivatives to a transformation '$sym'";
    }

    $func = $func->apply_derivatives(defined($lvl) ? $lvl : ());
    $c->{stash}{$sym} = $func;

    return($sym, '==', $func);
}

1;

__END__

=encoding utf8

=head1 NAME

Math::SymbolicX::Calculator::Command::DerivativeApplication

=head1 SYNOPSIS

  Refer to Math::SymbolicX::Calculator::Command instead.

=head1 DESCRIPTION

Refer to L<Math::SymbolicX::Calculator::Command> instead.

=head1 METHODS

=head2 new

Creates a new object of this class. Details are discussed in
L<Math::SymbolicX::Calculator::Command>.

=head1 SEE ALSO

L<Math::SymbolicX::Calculator::Command>

L<Math::SymbolicX::Calculator>

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2013 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut


