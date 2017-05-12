use strict;
use warnings;

package Dist::Zilla::Plugin::Control::Debian;

# PODNAME: Dist::Zilla::Plugin::Control::Debian
# ABSTRACT: Add a debian/control file to your distribution
#
# This file is part of Dist-Zilla-Plugin-Control-Debian
#
# This software is copyright (c) 2013 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.002'; # VERSION

# Dependencies

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use Software::Release;
use Software::Release::Change;


has file_name => (
    is      => 'ro',
    isa     => 'Str',
    default => 'debian/control',
);


has 'maintainer_email' => (
    is      => 'rw',
    isa     => 'Str',
    default => defined( $ENV{'DEBEMAIL'} )
    ? $ENV{'DEBEMAIL'}
    : 'cpan@example.com'
);


has 'maintainer_name' => (
    is      => 'rw',
    isa     => 'Str',
    default => defined( $ENV{'DEBFULLNAME'} )
    ? $ENV{'DEBFULLNAME'}
    : 'CPAN Author'
);


has priority => (
    is      => 'ro',
    isa     => 'Str',
    default => 'optional',
);


has buildDepends => (
    is      => 'ro',
    isa     => 'Str',
    default => 'debhelper (>= 8)',
);


sub gather_files {
    my ( $self, $arg ) = @_;
    my $file = Dist::Zilla::File::InMemory->new(
        {
            content => $self->render_control,
            name    => $self->file_name,
        }
    );

    $self->add_file($file);
}


sub render_control {
    my ($self) = @_;
    my $content = "Source: lib" . lc( $self->zilla->name ) . "-perl
Section: perl
Priority: " . $self->priority . "
Maintainer: " . $self->maintainer_name . " <" . $self->maintainer_email . ">
Build-Depends: " . $self->buildDepends . "
Build-Depends-Indep: perl
Standards-Version: 3.9.2
Homepage: http://search.cpan.org/dist/" . $self->zilla->name . "/

Package: lib" . lc( $self->zilla->name ) . "-perl
Architecture: all
Depends: \${misc:Depends}, \${perl:Depends}
Desciprion: " . $self->zilla->abstract;
    return $content;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::Control::Debian - Add a debian/control file to your distribution

=head1 VERSION

version 0.002

=head1 ATTRIBUTES

=head2 file_name

 file_name=debian/control
You will not need to change this from the default.

=head2 maintainer_email

=head2 maintainer_name

=head2 priority

 priority=optional

Default value is 'optional'

=head2 buildDepends

    buildDepends=debhelper (>= 8)

value for Build-Depends

=head1 METHODS

=head2 gather_files

imported from FileGatherer

=head2 render_control

Simple method used to generate the content for control files

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/dist-zilla-plugin-control-debian/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/dist-zilla-plugin-control-debian>

  git clone git://github.com/shantanubhadoria/dist-zilla-plugin-control-debian.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu at cpan dott org>

=head1 CONTRIBUTOR

Shantanu <shantanu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
