package Mardem::RefactoringPerlCriticPolicies;

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

Mardem::RefactoringPerlCriticPolicies - Perl-Critic policies for simple and isolated Refactoring-Support.

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

This Perl-Crictic Policy-Modules should help where to start a safe
refactoring in old leagacy Perl code.

The McCabe complexity check within the standard Perl-Critic Module are a good
overall starting point see:

=over 4

=item * L<Perl::Critic::Policy::Modules::ProhibitExcessMainComplexity>

=item * L<Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity>

=back

but these are for some bigger scans, so these new policies should check (or begin) in smaller chunks:

=head2 L<Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt>

return boolean as int "return 1;"

=head2 L<Perl::Critic::Policy::Mardem::ProhibitConditionComplexity>

condition complexity "if/while/for/... (...){}"

=head2 L<Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub>

subs has many conditionals "if, while, for, ..."

=head2 L<Perl::Critic::Policy::Mardem::ProhibitLargeBlock>

large code block as statement count "{...}"

=head2 L<Perl::Critic::Policy::Mardem::ProhibitBlockComplexity>

code block complexity "{...}"

=head2 L<Perl::Critic::Policy::Mardem::ProhibitLargeSub>

large subs as statement count

=head1 AFFILIATION

This module has no functionality, but instead contains documentation for this
distribution and acts as a means of pulling other modules into a bundle.
All of the Policy modules contained herein will have an "AFFILIATION" section
announcing their participation in this grouping.

=head1 BUG REPORTS

Please report bugs on GitHub.

The source code repository can be found at L<https://github.com/mardem1//mardem-refactoring-perlcritic-policies>

=head1 AUTHOR

Markus Demml, mardem@cpan.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2022, Markus Demml

This library is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.
The full text of this license can be found in the LICENSE file included
with this module.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut
