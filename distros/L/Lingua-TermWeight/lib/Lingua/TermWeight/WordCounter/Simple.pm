# SPDX-FileCopyrightText: 2014 Koichi SATOH <r.sekia@gmail.com>
# SPDX-FileCopyrightText: 2026 Wesley Schwengle <waterkip@cpan.org>
#
# SPDX-License-Identifier: MIT

package Lingua::TermWeight::WordCounter::Simple;
our $VERSION = '0.01';
# ABSTRACT: Simple word counter

use v5.26;
use Object::Pad;
use Carp qw(croak);

class Lingua::TermWeight::WordCounter::Simple {

  field %frequencies;

  method add_count ($word) {
    croak "Word must be defined" unless defined $word;
    ++$frequencies{$word};
  }

  method clear {
    %frequencies = ();
  }

  method frequencies {
    return {%frequencies};
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TermWeight::WordCounter::Simple - Simple word counter

=head1 VERSION

version 0.01

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Wesley Schwengle.

This is free software, licensed under:

  The MIT (X11) License

=cut
