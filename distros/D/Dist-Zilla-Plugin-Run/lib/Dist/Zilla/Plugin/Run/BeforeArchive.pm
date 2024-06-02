use strict;
use warnings;

package Dist::Zilla::Plugin::Run::BeforeArchive;
# ABSTRACT: execute a command of the distribution before creating the archive

our $VERSION = '0.050';

use Moose;
with qw(
  Dist::Zilla::Role::BeforeArchive
  Dist::Zilla::Plugin::Run::Role::Runner
);

use namespace::autoclean;

sub before_archive {
  my ($self) = @_;
  $self->_call_script({});
}

#pod =head1 SYNOPSIS
#pod
#pod   [Run::BeforeArchive]
#pod   run = script/do_this.pl --dir %d --version %v
#pod   run = script/do_that.pl
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin executes the specified command before the archive file is built.
#pod
#pod =head1 POSITIONAL PARAMETERS
#pod
#pod See L<Dist::Zilla::Plugin::Run/CONVERSIONS>
#pod for the list of common formatting variables available to all plugins.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Run::BeforeArchive - execute a command of the distribution before creating the archive

=head1 VERSION

version 0.050

=head1 SYNOPSIS

  [Run::BeforeArchive]
  run = script/do_this.pl --dir %d --version %v
  run = script/do_that.pl

=head1 DESCRIPTION

This plugin executes the specified command before the archive file is built.

=head1 POSITIONAL PARAMETERS

See L<Dist::Zilla::Plugin::Run/CONVERSIONS>
for the list of common formatting variables available to all plugins.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Run>
(or L<bug-Dist-Zilla-Plugin-Run@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Run@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by L<Raudssus Social Software|https://raudss.us/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
