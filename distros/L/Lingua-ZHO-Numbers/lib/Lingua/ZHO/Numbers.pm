# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::ZHO::Numbers;
# ABSTRACT: This module is deprecated. Please use Lingua::ZHO::Num2Word instead.

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Lingua::ZHO::Num2Word;

# }}}
# {{{ var block

our $VERSION = '0.2603270';

our $Charset;

# }}}

# {{{ import                           delegate charset selection to Num2Word

sub import {
    my $class = shift;
    # pass charset args to the real module
    Lingua::ZHO::Num2Word->charset($_[0]) if @_;
}

# }}}
# {{{ re-export from Num2Word

sub num2zho_cardinal :Export { goto &Lingua::ZHO::Num2Word::num2zho_cardinal }
sub number_to_zh     :Export { goto &Lingua::ZHO::Num2Word::number_to_zh }

# }}}
# {{{ charset                          delegate to Num2Word

sub charset { return Lingua::ZHO::Num2Word->charset($_[1]) }

# }}}
# {{{ new                              constructor (deprecated)

sub new {
    my $class = shift;
    carp "Lingua::ZHO::Numbers is deprecated, use Lingua::ZHO::Num2Word instead";
    return Lingua::ZHO::Num2Word->new(@_);
}

# }}}
# {{{ parse                            delegate to Num2Word (deprecated)

sub parse       { return Lingua::ZHO::Num2Word::parse(@_) }
sub get_string  { return Lingua::ZHO::Num2Word::get_string(@_) }

# }}}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lingua::ZHO::Numbers - Number to word conversion in Chinese (DEPRECATED)

=head1 VERSION

version 0.2603270

=head1 DESCRIPTION

B<This module is deprecated.> Please use L<Lingua::ZHO::Num2Word> instead.

This module is a thin wrapper that delegates to L<Lingua::ZHO::Num2Word>
for backward compatibility with code using the old C<Lingua::ZHO::Numbers>
API. Charset selection via C<use Lingua::ZHO::Numbers 'big5'> is preserved
and delegated to the new module.

=head1 SYNOPSIS

 # Old API (deprecated):
 use Lingua::ZHO::Numbers 'traditional';
 my $obj = Lingua::ZHO::Numbers->new(42);
 my $text = $obj->get_string;

 # New API (preferred):
 use Lingua::ZHO::Num2Word 'traditional';
 my $text = num2zho_cardinal(42);

=head1 FUNCTIONS

=over 2

=item B<new> (deprecated)

Constructor. Emits a deprecation warning. Delegates to
L<Lingua::ZHO::Num2Word>.

=item B<charset>

Sets or gets the active charset. Delegates to
C<Lingua::ZHO::Num2Word-E<gt>charset()>.

=item B<parse>

Delegates to C<Lingua::ZHO::Num2Word::parse()>.

=item B<get_string>

Delegates to C<Lingua::ZHO::Num2Word::get_string()>.

=back

=head1 SEE ALSO

L<Lingua::ZHO::Num2Word> — the replacement module.

=head1 AUTHORS

 initial coding:
   Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>
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
