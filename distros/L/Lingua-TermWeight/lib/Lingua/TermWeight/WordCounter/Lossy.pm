# SPDX-FileCopyrightText: 2014 Koichi SATOH <r.sekia@gmail.com>
# SPDX-FileCopyrightText: 2026 Wesley Schwengle <waterkip@cpan.org>
#
# SPDX-License-Identifier: MIT

package Lingua::TermWeight::WordCounter::Lossy;
our $VERSION = '0.01';
# ABSTRACT: Lossy word counter

use v5.26;
use Object::Pad;
use Algorithm::LossyCount;
use Carp qw(croak);

class Lingua::TermWeight::WordCounter::Lossy {

  field $max_error_ratio : param;
  field $counter;

  ADJUST {
    $counter = Algorithm::LossyCount->new(max_error_ratio => $max_error_ratio);
  }

  method add_count ($word) {
    croak "word must be defined" unless defined $word;
    $counter->add_sample($word);
  }

  method clear {
    $counter = Algorithm::LossyCount->new(max_error_ratio => $max_error_ratio);
  }

  method counter { $counter }

  method frequencies {
    return $counter->frequencies;
  }

  method max_error_ratio {
    return $max_error_ratio;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TermWeight::WordCounter::Lossy - Lossy word counter

=head1 VERSION

version 0.01

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Wesley Schwengle.

This is free software, licensed under:

  The MIT (X11) License

=cut
