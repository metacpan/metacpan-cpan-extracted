# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::FRA::Numbers;
# ABSTRACT: This module is deprecated. Please use Lingua::FRA::Num2Word instead.

use 5.16.0;
use utf8;
use warnings;

use Carp;
use Lingua::FRA::Num2Word qw(num2fra_cardinal number_to_fr ordinate_to_fr);
use Export::Attrs;

our $VERSION = '0.2603270';

# re-export everything from Num2Word
sub num2fra_cardinal :Export { goto &Lingua::FRA::Num2Word::num2fra_cardinal }
sub number_to_fr     :Export { goto &Lingua::FRA::Num2Word::number_to_fr }
sub ordinate_to_fr   :Export { goto &Lingua::FRA::Num2Word::ordinate_to_fr }

# OO delegation
sub new {
    my $class = shift;
    carp "Lingua::FRA::Numbers is deprecated, use Lingua::FRA::Num2Word instead";
    return Lingua::FRA::Num2Word->new(@_);
}

sub parse      { shift; return Lingua::FRA::Num2Word::parse(@_) }
sub get_string { shift; return Lingua::FRA::Num2Word::get_string(@_) }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::FRA::Numbers - Number to word conversion in French (DEPRECATED)

=head1 VERSION

version 0.2603270

=head1 DESCRIPTION

B<This module is deprecated.> Please use L<Lingua::FRA::Num2Word> instead.

This module is a thin wrapper that delegates to L<Lingua::FRA::Num2Word>
for backward compatibility.

=head1 SEE ALSO

L<Lingua::FRA::Num2Word> — the replacement module.

=head1 AUTHORS

 initial coding:
   Briac Pilpré E<lt>briac@cpan.orgE<gt>
 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5 itself.

=cut
