#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: lib/Dist/Zilla/Plugin/MetaResources/Template.pm
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Dist-Zilla-Plugin-MetaResources-Template.
#
#   perl-Dist-Zilla-Plugin-MetaResources-Template is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-MetaResources-Template is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-MetaResources-Template. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#pod =for :this This is C<Dist::Zilla::Plugin::MetaResources::Template> module documentation. Read this if you are going to hack or
#pod extend C<Dist-Zilla-Plugin-MetaResources-Template>.
#pod
#pod =for :that If you want to use Perl code in distribution "resource" metadata, read the L<manual|Dist::Zilla::Plugin::MetaResources::Template::Manual>. General
#pod topics like getting source, building, installing, bug reporting and some others are covered in the
#pod F<README>.
#pod
#pod =head1 SYNOPSIS
#pod
#pod Oops.
#pod
#pod =head1 DESCRIPTION
#pod
#pod C<Dist::Zilla::Plugin::MetaResources::Template> extends C<Dist::Zilla::Plugin::MetaResources>. The class implements C<BUILD>
#pod method, which expand templates in option values, all other work is done by the parent class.
#pod
#pod Template processing abilities achieved by consuming C<Dist::Zilla::Role::TextTemplater> role.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Role>
#pod = L<Dist::Zilla::Role::Plugin>
#pod = L<Dist::Zilla::Role::TextTemplater>
#pod = L<Dist::Zilla::Plugin::MetaResources>
#pod = L<Dist::Zilla::Plugin::MetaResources::Template::Manual>
#pod = L<CPAN::Meta::Spec>
#pod = L<CPAN::Meta::Spec/"resources">
#pod = L<Moose::Manual::Construction/"BUILD">
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Plugin::MetaResources::Template;

use Moose;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Use Perl code in distribution "resource" metadata
our $VERSION = 'v0.4.7'; # VERSION

extends 'Dist::Zilla::Plugin::MetaResources';
with 'Dist::Zilla::Role::TextTemplater' => { -version => 'v0.4.0' };
    # ^ `TextTemplater` v0.4.0 supports `filename` option.

# --------------------------------------------------------------------------------------------------

#pod =Method BUILDARGS
#pod
#pod Parent's C<BUILDARGS> mangles all the arguments: it moves them into resources, including
#pod C<TextTemplater> arguments: C<delimiters>, C<package>, C<prepend>. We have to protect
#pod C<TextTemplater> arguments from being misinterpreted.
#pod
#pod =cut

around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;
    my $save = {};
    for my $attr ( qw{ delimiters package prepend } ) {
        if ( exists( $args->{ $attr } ) ) {
            $save->{ $attr } = delete( $args->{ $attr } );
        };
    };
    $args = $class->$orig( $args );
    for my $attr ( keys( %$save ) ) {
        $args->{ $attr } = $save->{ $attr };
    };
    return $args;
};

# --------------------------------------------------------------------------------------------------

#pod =method BUILD
#pod
#pod The method is automatically called after object creation. The method recursively walks through the
#pod C<< $self->{resources} >> and expand templates in string by calling C<< $self->fill_in_string >>
#pod (it is a method from C<TextTemplater> role).
#pod
#pod Defining C<BUILDARGS> seems like a simpler approach because all the options are in plain list and
#pod so there is no need in recursive walking trough a complex data structure (C<< $self->{ resources }
#pod >>), but we need C<$self> to perform template expansion while C<BUILDARGS> is a class method.
#pod
#pod =cut

sub BUILD {
    my ( $self ) = @_;
    $self->{ resources } = $self->_expand( $self->{ resources } );
    return;
};

# --------------------------------------------------------------------------------------------------

sub _expand {
    my ( $self, $item, $name ) = @_;
    if ( 0 ) {
    } elsif ( ref( $item ) eq '' ) {
        $item = $self->fill_in_string( $item, undef, { filename => $name } );
    } elsif ( ref( $item ) eq 'ARRAY' ) {
        my $prefix = defined( $name ) ? $name . '#' : '';
        my $idx = 0;
        for my $elem ( @$item ) {
            ++ $idx;
            $elem = $self->_expand( $elem, $prefix . $idx );
        };
    } elsif ( ref( $item ) eq 'HASH' ) {
        my $prefix = defined( $name ) ? $name . '.' : '';
        for my $key ( keys( %$item ) ) {
            $item->{ $key } = $self->_expand( $item->{ $key }, $prefix . $key );
        };
    } else {
        die "Unexpected ref type: " . ref( $item );     ## no critic ( RequireCarping )
    };
    return $item;
};

# --------------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

# doc/what.pod #

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-Plugin-MetaResources-Template> is a C<Dist::Zilla> plugin, a replacement for standard plugin C<MetaResources>.
#pod Both provide resources for distribution metadata, but this one treats values as text templates.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaResources::Template - Use Perl code in distribution "resource" metadata

=head1 VERSION

Version v0.4.7, released on 2015-11-05 20:49 UTC.

=head1 WHAT?

C<Dist-Zilla-Plugin-MetaResources-Template> is a C<Dist::Zilla> plugin, a replacement for standard plugin C<MetaResources>.
Both provide resources for distribution metadata, but this one treats values as text templates.

This is C<Dist::Zilla::Plugin::MetaResources::Template> module documentation. Read this if you are going to hack or
extend C<Dist-Zilla-Plugin-MetaResources-Template>.

If you want to use Perl code in distribution "resource" metadata, read the L<manual|Dist::Zilla::Plugin::MetaResources::Template::Manual>. General
topics like getting source, building, installing, bug reporting and some others are covered in the
F<README>.

=head1 SYNOPSIS

Oops.

=head1 DESCRIPTION

C<Dist::Zilla::Plugin::MetaResources::Template> extends C<Dist::Zilla::Plugin::MetaResources>. The class implements C<BUILD>
method, which expand templates in option values, all other work is done by the parent class.

Template processing abilities achieved by consuming C<Dist::Zilla::Role::TextTemplater> role.

=head1 CLASS METHODS

=head2 BUILDARGS

Parent's C<BUILDARGS> mangles all the arguments: it moves them into resources, including
C<TextTemplater> arguments: C<delimiters>, C<package>, C<prepend>. We have to protect
C<TextTemplater> arguments from being misinterpreted.

=head1 OBJECT METHODS

=head2 BUILD

The method is automatically called after object creation. The method recursively walks through the
C<< $self->{resources} >> and expand templates in string by calling C<< $self->fill_in_string >>
(it is a method from C<TextTemplater> role).

Defining C<BUILDARGS> seems like a simpler approach because all the options are in plain list and
so there is no need in recursive walking trough a complex data structure (C<< $self->{ resources }
>>), but we need C<$self> to perform template expansion while C<BUILDARGS> is a class method.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role>

=item L<Dist::Zilla::Role::Plugin>

=item L<Dist::Zilla::Role::TextTemplater>

=item L<Dist::Zilla::Plugin::MetaResources>

=item L<Dist::Zilla::Plugin::MetaResources::Template::Manual>

=item L<CPAN::Meta::Spec>

=item L<CPAN::Meta::Spec/"resources">

=item L<Moose::Manual::Construction/"BUILD">

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
