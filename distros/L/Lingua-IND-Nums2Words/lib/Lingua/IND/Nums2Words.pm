# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::IND::Nums2Words;
# ABSTRACT: This module is deprecated. Please use Lingua::IND::Num2Word instead.

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Lingua::IND::Num2Word qw(num2ind_cardinal nums2words nums2words_simple);

# }}}
# {{{ var block

our $VERSION = '0.2603270';

# }}}

# {{{ re-export from Num2Word

sub num2ind_cardinal  :Export { goto &Lingua::IND::Num2Word::num2ind_cardinal }
sub nums2words        :Export { goto &Lingua::IND::Num2Word::nums2words }
sub nums2words_simple :Export { goto &Lingua::IND::Num2Word::nums2words_simple }

# }}}
# {{{ new                              constructor (deprecated)

sub new {
    my $class = shift;
    carp "Lingua::IND::Nums2Words is deprecated, use Lingua::IND::Num2Word instead";
    return Lingua::IND::Num2Word->new(@_);
}

# }}}
# {{{ parse                            delegate to Num2Word (deprecated)

sub parse :Export {
    my $self   = ref($_[0]) ? shift : __PACKAGE__->new();
    my $number = shift // return '';

    return num2ind_cardinal($number) // '';
}

# }}}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::IND::Nums2Words - Number to word conversion in Indonesian (DEPRECATED)

=head1 VERSION

version 0.2603270

=head1 DESCRIPTION

B<This module is deprecated.> Please use L<Lingua::IND::Num2Word> instead.

This module is a thin wrapper that delegates to L<Lingua::IND::Num2Word>
for backward compatibility with code using the old C<Lingua::IND::Nums2Words>
API.

=head1 SYNOPSIS

 # Old API (deprecated):
 use Lingua::IND::Nums2Words;
 my $obj = Lingua::IND::Nums2Words->new();
 my $text = $obj->parse(42);

 # New API (preferred):
 use Lingua::IND::Num2Word qw(num2ind_cardinal);
 my $text = num2ind_cardinal(42);

=head1 FUNCTIONS

=over 2

=item B<new> (deprecated)

Constructor. Emits a deprecation warning. Delegates to
L<Lingua::IND::Num2Word>.

=item B<parse> (positional, deprecated)

  1   num    number to convert
  =>  str    Indonesian cardinal text

Delegates to C<num2ind_cardinal()>.

=back

=head1 SEE ALSO

L<Lingua::IND::Num2Word> — the replacement module.

=head1 AUTHORS

 initial coding:
   Steven Haryanto E<lt>sh@hhh.indoglobal.comE<gt>
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
