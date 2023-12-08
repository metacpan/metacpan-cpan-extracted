package Mail::STS::STSRecord;

use Moose;

our $VERSION = '0.05'; # VERSION
# ABSTRACT: a STS DNS TXT record string

has 'fields' => (
  is => 'ro',
  default => sub { [ 'v', 'id' ] },
);

with 'Mail::STS::SSKV';

has 'v' => (
  is => 'rw',
  isa => 'Str',
  default => 'STSv1',
);

has 'id' => (
  is => 'rw',
  isa => 'Str',
  required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::STS::STSRecord - a STS DNS TXT record string

=head1 VERSION

version 0.05

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
