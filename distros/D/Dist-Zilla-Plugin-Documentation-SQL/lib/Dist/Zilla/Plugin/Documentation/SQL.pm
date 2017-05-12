package Dist::Zilla::Plugin::Documentation::SQL;
{
  $Dist::Zilla::Plugin::Documentation::SQL::VERSION = '0.03';
}

# ABSTRACT: Create a file gathering all =sql commands


use strict;
use warnings;

use Path::Class;
use Pod::Elemental;
use Pod::Elemental::Element::Nested;
use Pod::Weaver::Section::SQL 0.03;
use Moose;

with qw/
  Dist::Zilla::Role::FileInjector
  Dist::Zilla::Role::FileMunger
  Dist::Zilla::Role::Plugin
  /;

with 'Dist::Zilla::Role::FileFinderUser' =>
  { default_finders => [ ':InstallModules', ], };


sub documentation_dir {
    my ($self) = @_;
    ( my $package = $self->zilla->name ) =~ s@-@/@g;
    my $package_dir       = dir("lib/$package");
    my $documentation_dir = $package_dir->subdir('Documentation');
    $documentation_dir->mkpath;
    return $documentation_dir;
}


sub documentation_file {
    my ($self) = @_;
    my $documentation_file = $self->documentation_dir->file('SQL.pod');
    return $documentation_file . "";
}


sub munge_files {
    my ($self) = @_;

    my $document = Pod::Elemental::Document->new;

    for my $file ( @{ $self->found_files } ) {
        my $file_section = Pod::Elemental::Element::Nested->new(
            command => 'head1',
            content => $file->name,
        );

        $file_section->children(
            [

                # Remove the '=sql' command part
                map {
                    my $formatter = Pod::Weaver::Section::SQL->new(
                        plugin_name => 'Pod::Weaver::Section::SQL',
                        weaver => bless({}, 'Pod::Weaver'),
                    );
                    Pod::Elemental::Element::Pod5::Ordinary->new(
                        content => $formatter->format_sql($_->content) )
                  }

                  # Keep only sql commands content
                  grep {
                    $_
                      if ( $_->can('command') and $_->command eq 'sql' );
                  } @{ Pod::Elemental->read_file( $file->name )->children }
            ]
        );

        if ( @{ $file_section->children } ) {

            my $file_package = $file->name;
            $file_package =~ s,lib/,,g;
            $file_package =~ s,\.pm,,g;
            $file_package =~ s,/,::,g;

            # Push front of children a link to the file
            $file_section->children(
                [
                    Pod::Elemental::Element::Pod5::Ordinary->new(
                        content => "L<$file_package>",
                    ),
                    @{ $file_section->children }
                ]
            );

            # Push-back
            $document->children( [ @{ $document->children }, $file_section ] );
        }
    }

    $self->add_file(
        Dist::Zilla::File::InMemory->new(
            name    => $self->documentation_file,
            content => $document->as_pod_string,
        )
    );
    return;
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Documentation::SQL - Create a file gathering all =sql commands

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Put in your dist.ini file

  name = Sample-Package
  author = E. Xavier Ample <example@example.org>
  license = GPL_3
  copyright_holder = E. Xavier Ample
  copyright_year = 2014
  version = 0.42

  [Documentation::SQL]

Then, dist will automatically search all your package files for documentation that looks like

  =sql SELECT * FROM table

  =cut

And will put all of them in a single file, located at (for the example)

  lib/Sample/Package/Documentation/SQL.pod

=head1 METHODS

=head2 documentation_dir

This method returns your main_module documentation linked dir, to put
generated documentation in it.

  $documentation_dir = $self->documentation_dir;

=head2 documentation_file

Retrieve the location where to put the file, and give the filename.

=head2 munge_files

A L<Dist::Zilla::Role::FileMunger|FileMunger> overwriting in order to have
direct access to every content that are included in a =sql command.

This method is called directly by B<dist>.

=head1 AUTHOR

Armand Leclercq <armand.leclercq@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Armand Leclercq.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

