#
# This file is part of Dist-Zilla-Plugin-Test-Perl-Critic
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
package Dist::Zilla::Plugin::CriticTests;
# ABSTRACT: (DEPRECATED) tests to check your code against best practices.
$Dist::Zilla::Plugin::CriticTests::VERSION = '3.000';
use Moose;
extends 'Dist::Zilla::Plugin::Test::Perl::Critic';
use namespace::autoclean;

before register_component => sub {
  warn "!!! [CriticTests] is deprecated and may be removed in the future; replace it with [Test::Perl::Critic]\n";
};


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CriticTests - (DEPRECATED) tests to check your code against best practices.

=head1 VERSION

version 3.000

=head1 SYNOPSIS

THIS MODULE IS DEPRECATED, PLEASE USE
L<Dist::Zilla::Plugin::Test::Perl::Critic> INSTEAD. IT MAY BE REMOVED AT
A LATER TIME (but not before 2012-08-29).

This module is only a compatibility stub for that module, and should
continue to work as expected - although with a warning.  Refer to the
replacement for the actual documentation.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
