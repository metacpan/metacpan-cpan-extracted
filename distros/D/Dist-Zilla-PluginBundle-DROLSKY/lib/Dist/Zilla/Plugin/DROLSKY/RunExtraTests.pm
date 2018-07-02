package Dist::Zilla::Plugin::DROLSKY::RunExtraTests;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.99';

use File::Which qw( which );

use Moose;

extends 'Dist::Zilla::Plugin::RunExtraTests';

with 'Dist::Zilla::Plugin::DROLSKY::Role::CoreCounter';

# Dist::Zilla provides no way to pass a `-j` option when running dzil release
# but I really would like faster releases.
sub default_jobs {
    return shift->_core_count;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Subclasses RunExtraTests to always run tests in parallel

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DROLSKY::RunExtraTests - Subclasses RunExtraTests to always run tests in parallel

=head1 VERSION

version 0.99

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2018 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
