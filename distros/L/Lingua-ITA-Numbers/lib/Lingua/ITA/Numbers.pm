# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::ITA::Numbers;
# ABSTRACT: This module is deprecated. Please use Lingua::ITA::Num2Word instead.

use 5.16.0;
use utf8;
use warnings;

use Carp;
use Lingua::ITA::Num2Word qw(num2ita_cardinal number_to_it);
use Export::Attrs;

our $VERSION = '0.2603270';

# re-export from Num2Word
sub num2ita_cardinal :Export { goto &Lingua::ITA::Num2Word::num2ita_cardinal }
sub number_to_it     :Export { goto &Lingua::ITA::Num2Word::number_to_it }

# OO delegation
sub new {
    my $class = shift;
    carp "Lingua::ITA::Numbers is deprecated, use Lingua::ITA::Num2Word instead";
    return Lingua::ITA::Num2Word->new(@_);
}

sub parse       { return Lingua::ITA::Num2Word::parse(@_) }
sub get_string  { return Lingua::ITA::Num2Word::get_string(@_) }
sub get_number  { return Lingua::ITA::Num2Word::get_number(@_) }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::ITA::Numbers - Number to word conversion in Italian (DEPRECATED)

=head1 VERSION

version 0.2603270

=head1 DESCRIPTION

B<This module is deprecated.> Please use L<Lingua::ITA::Num2Word> instead.

This module is a thin wrapper that delegates to L<Lingua::ITA::Num2Word>
for backward compatibility.

=head1 SEE ALSO

L<Lingua::ITA::Num2Word> — the replacement module.

=head1 AUTHORS

 initial coding:
   Leo Cacciari E<lt>hobbit@cpan.orgE<gt>
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
