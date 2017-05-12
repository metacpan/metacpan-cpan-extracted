#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Templates.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Templates.
#
#   perl-Dist-Zilla-Plugin-Templates is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Templates is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Templates. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for :this This is C<Dist::Zilla::Plugin::Templates> module documentation. Read this if you are going to hack or
#pod extend C<Dist-Zilla-Plugin-Templates>.
#pod
#pod =for :those If you want to treat source files as templates, read the L<manual|Dist::Zilla::Plugin::Templates::Manual>. General
#pod topics like getting source, building, installing, bug reporting and some others are covered in the
#pod F<README>.
#pod
#pod =head1 DESCRIPTION
#pod
#pod Implementation of the plugin is trivial. It just consumes few roles which do all the work:
#pod C<FileFinderUser> provides a list of files, C<TextTemplater> process them.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Role::FileFinderUser>
#pod = L<Dist::Zilla::Role::TextTemplater>
#pod = L<Text::Template>
#pod = L<Dist::Zilla::Plugin::Templates::Manual>
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Plugin::Templates;

use Moose;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Treat source files as templates
our $VERSION = 'v0.6.4'; # VERSION

with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::FileFinderUser' => {
    finder_arg_names => [ qw{ template templates } ],
    default_finders  => [ ':NoFiles' ],
};
with 'Dist::Zilla::Role::TextTemplater' => { -version => 0.007 };   # need nested packages support.
with 'Dist::Zilla::Role::ErrorLogger' => { -version => 0.005 };

use Carp qw{ croak };
use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Plugin::Templates::File;

# --------------------------------------------------------------------------------------------------

#pod =method munge_files
#pod
#pod This is the primary method of the plugin. It is called by C<Dist::Zilla> during build. The method
#pod iterates through the files provided by C<< $self->found_files >> (a method defined in
#pod C<FileFinderUser> role) and process each file with C<< $self->fill_in_file >> (a method defined in
#pod C<TextTemplater> role). That's all, folks.
#pod
#pod =cut

sub munge_files {
    my ( $self ) = @_;
    for my $file ( @{ $self->found_files } ) {
        $self->fill_in_file(
            $file,
            {
                include => \ &{ sub {       # `Text::Template` wants double reference.
                    return $self->include( @_ );
                } },
            },
        );
    };
    return;
};

# --------------------------------------------------------------------------------------------------

#pod =method include
#pod
#pod This method implements same-name template function. Normally, templates should call the function,
#pod not method:
#pod
#pod     {{ include( 'filename' ); }}
#pod
#pod However, if something wrong with the function, file inclusion can be made through the method call:
#pod
#pod     {{ $plugin->include( 'filename' ); }}
#pod
#pod =cut

sub include {
    my ( $self, $arg ) = @_;
    defined( $arg ) or croak "Can't include undefined file";
    my $class = blessed( $arg );
    my $file;
    if ( $class ) {
        $arg->isa( 'Moose::Object' ) and $arg->does( 'Dist::Zilla::Role::File' )
            or croak "Can't include object of $class class";
        $file = $arg;       # `$arg` is a file object.
    } else {
        my $name = "$arg";  # `$arg` is a file name.
        $name ne '' or croak "Can't include file with empty name";
        my @files = grep( { $_->name eq $name } @{ $self->zilla->files } );
        if ( @files > 1 ) {
            croak "Oops: Can't include $name file: more than one file found";
        };
        if ( @files ) {
            $file = $files[ 0 ];
        } else {
            $file = Dist::Zilla::File::OnDisk->new( { name => $name } );
        };
    };
    return Dist::Zilla::Plugin::Templates::File->new( {
        name    => $file->name,
        content => $file->content,
        _plugin => $self,
    } );
};

# --------------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

#   ------------------------------------------------------------------------------------------------
#
#   file: doc/what.pod
#
#   This file is part of perl-Dist-Zilla-Plugin-Templates.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-Plugin-Templates> (or just C<Templates> for brevity) is a C<Dist-Zilla> plugin allowing developers
#pod to insert Perl code fragments into arbitrary source text files, which become I<templates>. When
#pod C<Dist::Zilla> builds the distribution each code fragment is evaluated and replaced with result of
#pod evaluation.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Templates - Treat source files as templates

=head1 VERSION

Version v0.6.4, released on 2016-12-28 20:24 UTC.

=head1 WHAT?

C<Dist-Zilla-Plugin-Templates> (or just C<Templates> for brevity) is a C<Dist-Zilla> plugin allowing developers
to insert Perl code fragments into arbitrary source text files, which become I<templates>. When
C<Dist::Zilla> builds the distribution each code fragment is evaluated and replaced with result of
evaluation.

This is C<Dist::Zilla::Plugin::Templates> module documentation. Read this if you are going to hack or
extend C<Dist-Zilla-Plugin-Templates>.

If you want to treat source files as templates, read the L<manual|Dist::Zilla::Plugin::Templates::Manual>. General
topics like getting source, building, installing, bug reporting and some others are covered in the
F<README>.

=head1 DESCRIPTION

Implementation of the plugin is trivial. It just consumes few roles which do all the work:
C<FileFinderUser> provides a list of files, C<TextTemplater> process them.

=head1 OBJECT METHODS

=head2 munge_files

This is the primary method of the plugin. It is called by C<Dist::Zilla> during build. The method
iterates through the files provided by C<< $self->found_files >> (a method defined in
C<FileFinderUser> role) and process each file with C<< $self->fill_in_file >> (a method defined in
C<TextTemplater> role). That's all, folks.

=head2 include

This method implements same-name template function. Normally, templates should call the function,
not method:

    {{ include( 'filename' ); }}

However, if something wrong with the function, file inclusion can be made through the method call:

    {{ $plugin->include( 'filename' ); }}

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role::FileFinderUser>

=item L<Dist::Zilla::Role::TextTemplater>

=item L<Text::Template>

=item L<Dist::Zilla::Plugin::Templates::Manual>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
