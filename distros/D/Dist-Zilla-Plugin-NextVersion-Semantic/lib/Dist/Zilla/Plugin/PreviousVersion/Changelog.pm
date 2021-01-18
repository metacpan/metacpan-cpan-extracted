package Dist::Zilla::Plugin::PreviousVersion::Changelog;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: extract previous version from changelog
$Dist::Zilla::Plugin::PreviousVersion::Changelog::VERSION = '0.2.6';

use strict;
use warnings;

use CPAN::Changes;
use List::Util qw/ first /;

use Moose;

with qw/ 
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::YANICK::PreviousVersionProvider
/;

has filename  => ( is => 'ro', isa=>'Str', default => 'Changes' );

has changelog => (
    is => 'ro',
    isa => 'CPAN::Changes',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $changes_file = first { $_->name eq $self->filename }
                                 @{ $self->zilla->files }
            or $self->log_fatal(
                    "changelog '@{[ $self->filename ]}' not found" );

        CPAN::Changes->load_string(
            $changes_file->content,
            next_token => qr/\{\{\$NEXT\}\}/
        );
    },
);

sub provide_previous_version {
    my $self = shift;

    # TODO {{$NEXT}} not generic enough
    return first { $_ ne '{{$NEXT}}' } 
           map   { $_->version }
           reverse $self->changelog->releases;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PreviousVersion::Changelog - extract previous version from changelog

=head1 VERSION

version 0.2.6

=head1 DESCRIPTION

Plugin implementing the L<Dist::Zilla::Role::PreviousVersionProvider> role.
It provides the previous released version by peeking at the C<Changelog> file
and returning its latest release, skipping over C<{{$NEXT}}> if its there
(see L<Dist::Zilla::Plugin::NextRelease>).

Note that this module uses L<CPAN::Changes> to parse the change log. If the
file is not well-formed according to its specs, strange things might happen.

=head1 CONFIGURATION

=head2 filename

Changelog filename. Defaults to 'Changes'.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2015, 2014, 2013, 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
