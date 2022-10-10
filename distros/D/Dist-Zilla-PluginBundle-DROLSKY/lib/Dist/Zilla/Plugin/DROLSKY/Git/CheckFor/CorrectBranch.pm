package Dist::Zilla::Plugin::DROLSKY::Git::CheckFor::CorrectBranch;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.22';

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

Dist::Zilla::Plugin::DROLSKY::Git::CheckFor::CorrectBranch - Checks the branch on non-TRIAL releases

=head1 VERSION

version 1.22

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2022 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
