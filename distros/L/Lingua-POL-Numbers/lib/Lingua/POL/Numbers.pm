# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::POL::Numbers;
# ABSTRACT: This module is deprecated. Please use Lingua::POL::Num2Word instead.

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Lingua::POL::Num2Word qw(num2pol_cardinal parse num2pol_ordinal);

# }}}
# {{{ var block

our $VERSION = '0.2603270';

# }}}

# {{{ re-export from Num2Word

sub num2pol_cardinal :Export { goto &Lingua::POL::Num2Word::num2pol_cardinal }
sub num2pol_ordinal  :Export { goto &Lingua::POL::Num2Word::num2pol_ordinal }

# }}}
# {{{ new                              constructor (deprecated)

sub new {
    my $class  = shift;
    my $number = shift;

    carp "Lingua::POL::Numbers is deprecated, use Lingua::POL::Num2Word instead";

    my $self = bless {}, $class;

    if (defined $number && $number =~ /^\d+$/) {
        return $self->parse($number);
    }

    return $self;
}

# }}}
# {{{ parse                            delegate to Num2Word (deprecated)

sub parse :Export {
    my $self   = ref($_[0]) ? shift : __PACKAGE__->new();
    my $number = shift // return '';

    return num2pol_cardinal($number) // '';
}

# }}}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::POL::Numbers - Number to word conversion in Polish (DEPRECATED)

=head1 VERSION

version 0.2603270

=head1 DESCRIPTION

B<This module is deprecated.> Please use L<Lingua::POL::Num2Word> instead.

This module is a thin wrapper that delegates to L<Lingua::POL::Num2Word>
for backward compatibility with code using the old C<Lingua::POL::Numbers>
API.

=head1 SYNOPSIS

 # Old API (deprecated):
 use Lingua::POL::Numbers;
 my $obj = Lingua::POL::Numbers->new();
 my $text = $obj->parse(42);

 # New API (preferred):
 use Lingua::POL::Num2Word qw(num2pol_cardinal);
 my $text = num2pol_cardinal(42);

=head1 FUNCTIONS

=over 2

=item B<new> (deprecated)

Constructor. Emits a deprecation warning. Delegates to
L<Lingua::POL::Num2Word>.

=item B<parse> (positional, deprecated)

  1   num    number to convert
  =>  str    Polish cardinal text

Delegates to C<num2pol_cardinal()>.

=back

=head1 SEE ALSO

L<Lingua::POL::Num2Word> — the replacement module.

=head1 AUTHORS

 initial coding:
   Henrik Steffen E<lt>cpan@topconcepts.deE<gt>
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
