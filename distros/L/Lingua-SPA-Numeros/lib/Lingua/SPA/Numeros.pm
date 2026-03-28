# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::SPA::Numeros;
# ABSTRACT: This module is deprecated. Please use Lingua::SPA::Num2Word instead.

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Lingua::SPA::Num2Word qw(num2spa_cardinal num2spa_ordinal);

# }}}
# {{{ var block

our $VERSION = '0.2603270';

# }}}

# {{{ re-export from Num2Word

sub num2spa_cardinal :Export { goto &Lingua::SPA::Num2Word::num2spa_cardinal }
sub num2spa_ordinal  :Export { goto &Lingua::SPA::Num2Word::num2spa_ordinal }

# }}}
# {{{ new                              constructor (deprecated)

sub new {
    my $class = shift;
    carp "Lingua::SPA::Numeros is deprecated, use Lingua::SPA::Num2Word instead";
    return Lingua::SPA::Num2Word->new(@_);
}

# }}}
# {{{ parse                            delegate to Num2Word (deprecated)

sub parse :Export {
    my $self   = ref($_[0]) ? shift : __PACKAGE__->new();
    my $number = shift // return '';

    return num2spa_cardinal($number) // '';
}

# }}}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::SPA::Numeros - Number to word conversion in Spanish (DEPRECATED)

=head1 VERSION

version 0.2603270

=head1 DESCRIPTION

B<This module is deprecated.> Please use L<Lingua::SPA::Num2Word> instead.

This module is a thin wrapper that delegates to L<Lingua::SPA::Num2Word>
for backward compatibility with code using the old C<Lingua::SPA::Numeros>
API.

=head1 SYNOPSIS

 # Old API (deprecated):
 use Lingua::SPA::Numeros;
 my $obj = Lingua::SPA::Numeros->new();
 my $text = $obj->parse(42);

 # New API (preferred):
 use Lingua::SPA::Num2Word qw(num2spa_cardinal);
 my $text = num2spa_cardinal(42);

=head1 FUNCTIONS

=over 2

=item B<new> (deprecated)

Constructor. Emits a deprecation warning. Delegates to
L<Lingua::SPA::Num2Word>.

=item B<parse> (positional, deprecated)

  1   num    number to convert
  =>  str    Spanish cardinal text

Delegates to C<num2spa_cardinal()>.

=back

=head1 SEE ALSO

L<Lingua::SPA::Num2Word> — the replacement module.

=head1 AUTHORS

 initial coding:
   Jose Luis Rey Barreira E<lt>jrey@cpan.orgE<gt>
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
