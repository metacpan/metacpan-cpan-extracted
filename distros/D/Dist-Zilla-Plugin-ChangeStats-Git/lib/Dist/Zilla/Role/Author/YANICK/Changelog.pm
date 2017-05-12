package Dist::Zilla::Role::Author::YANICK::Changelog;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: provides an accessor for the changelog
$Dist::Zilla::Role::Author::YANICK::Changelog::VERSION = '0.6.0';
use strict;
use warnings;

use Moose::Role;
use List::Util qw/ first /;


has changelog_name => (
    is => 'ro',
    lazy => 1,  # required here because of the lazy role
    default => 'Changes',
);


sub changelog_file {
    my $self = shift;

    return first { $_->name eq $self->changelog_name } @{ $self->files };
};


sub changelog {
    my $self = shift;

    return CPAN::Changes->load_string( 
        $self->changelog_file->content, 
        next_token => qr/\{\{\$NEXT\}\}/
    );
}


sub save_changelog {
    my $self = shift;
    my $changes = shift;
    $self->changelog_file->content($changes->serialize);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Author::YANICK::Changelog - provides an accessor for the changelog

=head1 VERSION

version 0.6.0

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::Foo;

    use Moose;

    qith qw/ 
        Dist::Zilla::Role::Plugin
        Dist::Zilla::Role::FileMunger
    /;

    with 'Dist::Zilla::Role::Author::YANICK::RequireZillaRole' => {
        roles => [ qw/ Author::YANICK::Changelog / ],
    };

    sub munge_files {
        my $self = shift;

        my $changes = $self->changes;

        ...

        $self->save_changelog( $changes );
    }

=head1 DESCRIPTION

Allows to access directly the distribution's changelog.

=head1 ATTRIBUTES

=head1 changelog_name()

The name of the changelog file. Defaults to C<Changes>.

=head1 METHODS

=head2 changelog_file

Returns the changelog file object.

=head2 changelog()

Returns a L<CPAN::Changes> object representing the changelog.

=head2 save_changelog( $changes )

Commit I<$changes> as the changelog file for the distribution.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
