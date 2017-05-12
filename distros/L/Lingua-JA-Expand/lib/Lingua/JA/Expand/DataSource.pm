package Lingua::JA::Expand::DataSource;
use strict;
use warnings;
use base qw(Lingua::JA::Expand::Base);

__PACKAGE__->mk_virtual_methods($_) for qw(extract_text);



1;

__END__

=head1 NAME

Lingua::JA::Expand::DataSource - Base Class of Lingua::JA::Expand::DataSource::XXX

=head1 SYNOPSYS

  package My::DataSource;
  use base qw(Lingua::JA::Expand::DataSource);


=cut
