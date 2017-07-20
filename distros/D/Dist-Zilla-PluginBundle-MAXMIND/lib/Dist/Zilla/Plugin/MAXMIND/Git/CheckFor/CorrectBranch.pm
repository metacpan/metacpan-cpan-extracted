package Dist::Zilla::Plugin::MAXMIND::Git::CheckFor::CorrectBranch;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.81';

use Moose;

extends 'Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch';

override before_release => sub {
    my $self = shift;

    return if $self->zilla->is_trial;

    super();
};

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Checks the branch on non-TRIAL releases

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MAXMIND::Git::CheckFor::CorrectBranch - Checks the branch on non-TRIAL releases

=head1 VERSION

version 0.81

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
