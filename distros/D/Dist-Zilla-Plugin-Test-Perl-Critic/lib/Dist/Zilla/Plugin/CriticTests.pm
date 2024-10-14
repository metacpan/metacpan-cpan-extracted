use strict;
use warnings;
package Dist::Zilla::Plugin::CriticTests;
# ABSTRACT: (DEPRECATED) tests to check your code against best practices.
our $VERSION = '3.002';
use Moose;
extends 'Dist::Zilla::Plugin::Test::Perl::Critic';
use namespace::autoclean;

before register_component => sub {
  warn "!!! [CriticTests] is deprecated and may be removed in the future; replace it with [Test::Perl::Critic]\n";
};

#pod =for stopwords LICENCE
#pod
#pod =head1 SYNOPSIS
#pod
#pod THIS MODULE IS DEPRECATED, PLEASE USE
#pod L<Dist::Zilla::Plugin::Test::Perl::Critic> INSTEAD. IT MAY BE REMOVED AT
#pod A LATER TIME (but not before 2012-08-29).
#pod
#pod This module is only a compatibility stub for that module, and should
#pod continue to work as expected - although with a warning.  Refer to the
#pod replacement for the actual documentation.
#pod
#pod =cut

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CriticTests - (DEPRECATED) tests to check your code against best practices.

=head1 VERSION

version 3.002

=head1 SYNOPSIS

THIS MODULE IS DEPRECATED, PLEASE USE
L<Dist::Zilla::Plugin::Test::Perl::Critic> INSTEAD. IT MAY BE REMOVED AT
A LATER TIME (but not before 2012-08-29).

This module is only a compatibility stub for that module, and should
continue to work as expected - although with a warning.  Refer to the
replacement for the actual documentation.

=for stopwords LICENCE

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-Perl-Critic>
(or L<bug-Dist-Zilla-Plugin-Test-Perl-Critic@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-Perl-Critic@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
