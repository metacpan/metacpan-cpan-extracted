# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::AFR::Numbers;
# ABSTRACT: This module is deprecated. Please use Lingua::AFR::Num2Word instead.

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Lingua::AFR::Num2Word qw(num2afr_cardinal parse);

# }}}
# {{{ var block

our $VERSION = '0.2603270';

# }}}

# {{{ re-export from Num2Word

sub num2afr_cardinal :Export { goto &Lingua::AFR::Num2Word::num2afr_cardinal }

# }}}
# {{{ new                              constructor (deprecated)

sub new {
    my $class  = shift;
    my $number = shift;

    carp "Lingua::AFR::Numbers is deprecated, use Lingua::AFR::Num2Word instead";

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

    return num2afr_cardinal($number) // '';
}

# }}}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::AFR::Numbers - Number to word conversion in Afrikaans (DEPRECATED)

=head1 VERSION

version 0.2603270

=head1 DESCRIPTION

B<This module is deprecated.> Please use L<Lingua::AFR::Num2Word> instead.

This module is a thin wrapper that delegates to L<Lingua::AFR::Num2Word>
for backward compatibility with code using the old C<Lingua::AFR::Numbers>
API.

=head1 SYNOPSIS

 # Old API (deprecated):
 use Lingua::AFR::Numbers;
 my $obj = Lingua::AFR::Numbers->new();
 my $text = $obj->parse(42);

 # New API (preferred):
 use Lingua::AFR::Num2Word qw(num2afr_cardinal);
 my $text = num2afr_cardinal(42);

=head1 FUNCTIONS

=over 2

=item B<new> (deprecated)

Constructor. Emits a deprecation warning. Delegates to
L<Lingua::AFR::Num2Word>.

=item B<parse> (positional, deprecated)

  1   num    number to convert
  =>  str    Afrikaans cardinal text

Delegates to C<num2afr_cardinal()>.

=back

=head1 SEE ALSO

L<Lingua::AFR::Num2Word> — the replacement module.

=head1 AUTHORS

 initial coding:
   Alistair Francis E<lt>cpan@alizta.comE<gt>
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
