use strict;
use warnings;

package Footprintless::MixableBase;
$Footprintless::MixableBase::VERSION = '1.26';
# ABSTRACT: A base class for using mixins
# PODNAME: Footprintless::MixableBase

use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    my ( $class, $factory, $coordinate, @options ) = @_;
    $logger->tracef( "%s coordinate=[%s]\noptions=[%s]", $class, $coordinate, \@options );
    my $self = bless(
        {   factory    => $factory,
            coordinate => $coordinate
        },
        $class
    );

    return $self->_init(@options);
}

sub _init {
    return $_[0];
}

1;

__END__

=pod

=head1 NAME

Footprintless::MixableBase - A base class for using mixins

=head1 VERSION

version 1.26

=head1 SYNOPSIS

    package Foo;

    use parent qw(Footprintless::MixableBase)

    use Footprintless::Mixins qw(
        _sub_entity
        ...
    );

    sub _init {
        my ($self, %options);
        $self->{debug} = $options{debug};
        $self->{user} = $self->_entity('user', 1);
        return $self;
    }

    sub get_user {
        my ($self) = @_;
        print("getting user\n") if ($self->{debug});
        return $self->{user};
    }

    package main;

    use Footprintless::Util qw(factory);

    my $foo = Foo->new(
        factory({
            root => {
                foo => {
                    user => 'bar'
                }
            }
        }),
        'root.foo',
        debug => 1);

    my $user = $foo->get_user(); # returns 'bar'

=head1 DESCRIPTION

Provides the boilerplate constructor for packages that want to use
L<Footprintless::Mixins>.  Specifically, strips off the first two 
parameters (C<$factory> and C<$coordinate>) and sets them as member
variables (C<$self->{factory}> and C<$self->{coordinate}>).  Then it
passes on the remainder of the arguments to the C<_init> method.
Subclasses should override C<_init> for additional initialization.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::Mixins|Footprintless::Mixins>

=back

=for Pod::Coverage new

=cut
