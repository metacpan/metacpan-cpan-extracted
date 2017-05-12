package JSORB::Procedure;
use Moose;

use JSORB::Types;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

extends 'JSORB::Core::Element';

has 'body' => (
    is      => 'ro',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $self      = shift;
        my @full_name = @{ $self->fully_qualified_name };
        my $sub_name  = pop @full_name;
        my $pkg_name  = join '::' => @full_name;
        my $meta      = Class::MOP::Class->initialize($pkg_name || 'main');
        $meta->has_package_symbol({ name => $sub_name, sigil => '&', type => 'CODE' })
            || confess "Could not find $sub_name in package " . $meta->name;
        $meta->get_package_symbol({ name => $sub_name, sigil => '&', type => 'CODE' })
    }
);

has 'spec' => (
    is        => 'ro',
    isa       => 'JSORB::Spec',
    coerce    => 1,
    predicate => 'has_spec',
);

has 'parameter_spec' => (
    is      => 'ro',
    isa     => 'JSORB::ParameterSpec',
    lazy    => 1,
    default => sub {
        my $self = shift;
        ($self->has_spec)
            || confess "Cannot derive the parameter spec without an overall spec";
        [ @{ $self->spec }[ 0 .. ($#{ $self->spec } - 1) ] ]
    },
);

has 'return_value_spec' => (
    is      => 'ro',
    isa     => 'JSORB::Spec::Type',
    lazy    => 1,
    default => sub {
        my $self = shift;
        ($self->has_spec)
            || confess "Cannot derive the parameter spec without an overall spec";
        $self->spec->[-1]
    },
);

sub call {
    my ($self, @args) = @_;
    $self->check_parameter_spec(@args);
    my @result = ($self->body->(@args));
    $self->check_return_value_spec(@result);
    $result[0];
}

sub check_parameter_spec {
    my ($self, @args) = @_;

    return unless $self->has_spec;

    my @params = @{ $self->parameter_spec };

    if (scalar @params == 1 && $params[0]->name eq 'Unit') {
        (scalar @args == 0)
            || confess "Bad number of arguments, got ("
                     . scalar @args
                     . "), expected ("
                     . scalar @params
                     . ")";
    }

    my $arg_count = 0;
    foreach my $i (0 .. $#args) {

        ($i <= $#params)
            || confess "Bad number of arguments, got ("
                     . scalar @args
                     . "), expected ("
                     . scalar @params
                     . ")";

        ($params[$i]->check($args[$i]))
            || confess "Parameter at position $i ("
                     . (defined $args[$i] ? $args[$i] : 'undef')
                     . ") did not pass the spec, "
                     . "we expected "
                     . $params[$i]->name;

        $arg_count = $i;
    }

    ($arg_count == $#params)
        || confess "Bad number of arguments, got ("
                 . scalar @args
                 . "), expected ("
                 . scalar @params
                 . ")";
}

sub check_return_value_spec {
    my ($self, @result) = @_;

    return unless $self->has_spec;

    my $rv = $self->return_value_spec;

    if ($rv->name eq 'Unit') {
        (scalar @result == 0)
            || confess "Return value is Unit but a value was returned @result";
        return;
    }

    ($rv->check($result[0]))
        || confess "Return value " . (defined $result[0] ? $result[0] : 'undef') . " did not pass the return value spec, "
                 . "we expected " . $rv->name;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB::Procedure - A basic RPC procedure

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
