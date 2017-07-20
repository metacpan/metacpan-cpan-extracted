package Evo::Default;
use strict;
use warnings;

sub import {
  $_->import for qw(strict warnings utf8);
  feature::->import(':5.22');

  feature::->import('postderef');
  warnings::->unimport('experimental::postderef');

  feature::->import('signatures');
  warnings::->unimport('experimental::signatures');

  feature::->import('lexical_subs');
  warnings::->unimport('experimental::lexical_subs');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Default

=head1 VERSION

version 0.0405

=head1 DESCRIPTION

Enables default features and disable warnings for them

=head1 SYNOPSYS

  # strict, warnings, utf8, :5.20, postderef
  use Evo;

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
