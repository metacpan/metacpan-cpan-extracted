# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::JPN::Number;
# ABSTRACT: This module is deprecated. Please use Lingua::JPN::Num2Word instead.

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Lingua::JPN::Num2Word qw(num2jpn_cardinal to_string);

# }}}
# {{{ var block

our $VERSION = '0.2603270';

# }}}

# {{{ re-export from Num2Word

sub num2jpn_cardinal :Export { goto &Lingua::JPN::Num2Word::num2jpn_cardinal }
sub to_string        :Export { goto &Lingua::JPN::Num2Word::to_string }

# }}}
# {{{ new                              constructor (deprecated)

sub new {
    my $class = shift;
    carp "Lingua::JPN::Number is deprecated, use Lingua::JPN::Num2Word instead";
    return Lingua::JPN::Num2Word->new(@_);
}

# }}}
# {{{ parse                            delegate to Num2Word (deprecated)

sub parse :Export {
    my $self   = ref($_[0]) ? shift : __PACKAGE__->new();
    my $number = shift // return '';

    return num2jpn_cardinal($number) // '';
}

# }}}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::JPN::Number - Number to word conversion in Japanese (DEPRECATED)

=head1 VERSION

version 0.2603270

=head1 DESCRIPTION

B<This module is deprecated.> Please use L<Lingua::JPN::Num2Word> instead.

This module is a thin wrapper that delegates to L<Lingua::JPN::Num2Word>
for backward compatibility with code using the old C<Lingua::JPN::Number>
API.

=head1 SYNOPSIS

 # Old API (deprecated):
 use Lingua::JPN::Number;
 my $obj = Lingua::JPN::Number->new();
 my $text = $obj->parse(42);

 # New API (preferred):
 use Lingua::JPN::Num2Word qw(num2jpn_cardinal);
 my $text = num2jpn_cardinal(42);

=head1 FUNCTIONS

=over 2

=item B<new> (deprecated)

Constructor. Emits a deprecation warning. Delegates to
L<Lingua::JPN::Num2Word>.

=item B<parse> (positional, deprecated)

  1   num    number to convert
  =>  str    Japanese cardinal text

Delegates to C<num2jpn_cardinal()>.

=back

=head1 SEE ALSO

L<Lingua::JPN::Num2Word> — the replacement module.

=head1 AUTHORS

 initial coding:
   Mike Schilli E<lt>m@perlmeister.comE<gt>
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
