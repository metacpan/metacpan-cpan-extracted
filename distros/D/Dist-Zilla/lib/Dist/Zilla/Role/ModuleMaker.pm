package Dist::Zilla::Role::ModuleMaker 6.020;
# ABSTRACT: something that injects module files into the dist

use Moose::Role;
with qw(
  Dist::Zilla::Role::Plugin
  Dist::Zilla::Role::FileInjector
);

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role have their C<make_module> method called for each
#pod module requesting creation by the plugin with this name.  It is passed a
#pod hashref with the following data:
#pod
#pod   name - the name of the module to make (a MooseX::Types::Perl::ModuleName)
#pod
#pod Classes composing this role also compose
#pod L<FileInjector|Dist::Zilla::Role::FileInjector> and are expected to inject a
#pod file for the module being created.
#pod
#pod =cut

requires 'make_module';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::ModuleMaker - something that injects module files into the dist

=head1 VERSION

version 6.020

=head1 DESCRIPTION

Plugins implementing this role have their C<make_module> method called for each
module requesting creation by the plugin with this name.  It is passed a
hashref with the following data:

  name - the name of the module to make (a MooseX::Types::Perl::ModuleName)

Classes composing this role also compose
L<FileInjector|Dist::Zilla::Role::FileInjector> and are expected to inject a
file for the module being created.

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
