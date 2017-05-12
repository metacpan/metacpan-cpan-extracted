package MasonX::MiniMVC::Dispatcher;

use strict;
use warnings;
use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(controllers));

=head1 NAME

MasonX::MiniMVC::Dispatcher -- Dispatcher class for MasonX::MiniMVC

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

For detailed documentation on how to use MasonX::MiniMVC, see the docs
for that module.

=head2 new(\%controllers)

Takes a hashref of urls/controllers.  

=cut

sub new {
    my ($class, $controllers) = @_;
    my $self = {
        controllers => $controllers,
    };
    bless $self, $class;
    return $self;
}

=head2 dispatch($m)

Dispatches to the appropriate controller.

=cut

sub dispatch {
    my ($self, $m) = @_;

    my $dhandler_args = $m->dhandler_arg();

    $dhandler_args =~ s/\/$//; # strip trailing slash

    my ($class, $method, @args) = $self->_find_controller($dhandler_args);
    if ($class) {
        eval "require $class";
        if ($method) {
            if ($class->can($method)) {
                $class->$method($m, @args);
            } else {
                $class->not_found($m, $method, @args);
            }
        } else {
            $class->default($m, @args);
        }
    } else {
        # we want a 404 if we can't find a controller.
        # however, this isn't working for me under CGIHandler.
        $m->clear_and_abort(404);
    }
}

sub _find_controller {
    my ($self, $desired_component, @extra_args) = @_;

    # this probably means we've exhausted the arg stack
    return undef unless $desired_component;

    foreach my $controller (sort keys %{$self->controllers()}) {
        if ($controller =~ /^$desired_component/) {
            return $self->controllers->{$controller}, @extra_args;
        }
    }

    # nothing found yet, so shift the rightmost part of the desired
    # component into the extra args.  ie. "foo/bar/baz", "quux" becomes
    # "foo/bar", "baz", "quux".
    my @parts = split "/", $desired_component;
    unshift @extra_args, pop @parts;
    $desired_component = join "/", @parts;

    $self->_find_controller($desired_component, @extra_args);
}

=head1 AUTHOR

Kirrily "Skud" Robert, C<< <skud at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-masonx-minimvc at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MasonX-MiniMVC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MasonX::MiniMVC

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MasonX-MiniMVC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MasonX-MiniMVC>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MasonX-MiniMVC>

=item * Search CPAN

L<http://search.cpan.org/dist/MasonX-MiniMVC>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Kirrily "Skud" Robert, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
