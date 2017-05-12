package HTML::Widgets::NavMenu::Object;

use strict;
use warnings;

use Class::XSAccessor;

sub new
{
    my $class = shift;
    my $self = {};

    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my $self = shift;

    return 0;
}

sub destroy_
{
    my $self = shift;

    return 0;
}

sub DESTROY
{
    my $self = shift;

    $self->destroy_();
}


=head2 __PACKAGE__->mk_accessors(qw(method1 method2 method3))

Equivalent to L<Class::Accessor>'s mk_accessors only using Class::XSAccessor.
It beats running an ugly script on my code, and can be done at run-time.

Gotta love dynamic languages like Perl 5.

=cut

sub mk_accessors
{
    my $package = shift;
    return $package->mk_acc_ref([@_]);
}

=head2 __PACKAGE__->mk_acc_ref([qw(method1 method2 method3)])

Creates the accessors in the array-ref of names at run-time.

=cut

sub mk_acc_ref
{
    my $package = shift;
    my $names = shift;

    my $mapping = +{ map { $_ => $_ } @$names };

    eval <<"EOF";
package $package;

Class::XSAccessor->import(
    accessors => \$mapping,
);
EOF

}

=head1 NAME

HTML::Widgets::NavMenu::Object - a base object for HTML::Widgets::NavMenu

=head1 SYNOPSIS

For internal use only

=head1 FUNCTIONS

=head2 my $obj = HTML::Widgets::NavMenu::Object->new(@args)

Instantiates a new object. Calls C<$obj-E<gt>_init()> with C<@args>.

=head2 my $obj = HTML::Widgets::NavMenu::Object->destroy_();

A method that can be used to explicitly destroy an object.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;
