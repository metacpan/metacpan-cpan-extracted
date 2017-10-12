package Dist::Zilla::Plugin::MAXMIND::CheckChangesHasContent;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.83';

use CPAN::Changes;

use Moose;

with 'Dist::Zilla::Role::BeforeRelease';

sub before_release {
    my $self = shift;

    $self->log('Checking Changes');

    $self->zilla->ensure_built_in;

    my $file = $self->zilla->built_in->child('Changes');

    if ( !-e $file ) {
        $self->log_fatal('No Changes file found');
    }
    elsif ( $self->_get_changes($file) ) {
        $self->log('Changes file has content for release');
    }
    else {
        $self->log_fatal(
            'Changes has no content for ' . $self->zilla->version );
    }

    return;
}

sub _get_changes {
    my $self = shift;
    my $file = shift;

    my $changes = CPAN::Changes->load($file);
    my $release = $changes->release( $self->zilla->version )
        or return;
    my $all = $release->changes
        or return;

    return 1 if grep { @{ $all->{$_} // [] } } keys %{$all};
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Checks Changes for content using CPAN::Changes;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MAXMIND::CheckChangesHasContent - Checks Changes for content using CPAN::Changes;

=head1 VERSION

version 0.83

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Dist-Zilla-PluginBundle-MAXMIND/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky and MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
