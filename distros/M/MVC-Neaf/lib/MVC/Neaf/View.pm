package MVC::Neaf::View;

use strict;
use warnings;
our $VERSION = '0.2901';

=head1 NAME

MVC::Neaf::View - Base [V]iew for Not Even A Framework.

=head1 DESCRIPTION

Subclass this class to make your own content rendering engine under Neaf.

Neaf stands for Not Even A Framework. It works by
(1) getting a hash from a sub which is pathetically called Controller,
and (2) passing that hash over to an object called View.

A subset of hash keys is used to control the framework's own behaviour.
Such -keys -are -prefixed -with -a -dash for greater visibility.
These keys are NOT guaranteed to get to your engine,
unless documentation explicitly states otherwise.

View in turn has a single method called C<render()>.

B<NOTE> Please always use C<$self-E<gt>dir($path)> whenever dealing with
templates or resources when subclassing this class.

=head1 METHODS

As of current, the one and only method (except constructor)
is needed, C<render>.

=cut

use Carp;
use parent qw(MVC::Neaf::X);

=head2 new( %options )

Options may include:

=over

=item * on_render - a callback to be called in the render sub was not defined.
Useful if you are too lazy to subclass.

=item * neaf_base_path - a directory to calculate relative template paths from.

=back

B<NOTE> The constructor of this particular class happily encloses itself
over any data one gives to it. No checks are performed.
This may change in the future.

=cut

=head2 render( \%hash )

C<render> MUST return a pair of values:

    my ($content, $content_type) = $obj->render( \%hash );

C<render> MAY die, resulting in a special view being processed,
or a text error message as a last resort.

=cut

sub render {
    my $self = shift;

    return $self->{on_render}->(shift) if exists $self->{on_render};

    croak( (ref $self)."->render() unimplemented (in MVC::Neaf::View)" );
};

=head1 CONCLUSION

There are a lot of templating engines, serializers etc. in the world.
The author of this tiny framework is not able to keep an eye on all of them.
Thus making your custom views is encouraged.

Please send patches, improvements, suggestions and bug reports to

L<https://github.com/dallaylaen/perl-mvc-neaf>

=cut

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2023 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
