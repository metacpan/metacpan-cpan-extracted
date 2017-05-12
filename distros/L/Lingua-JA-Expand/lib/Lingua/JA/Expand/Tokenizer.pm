package Lingua::JA::Expand::Tokenizer;
use strict;
use warnings;
use base qw(Lingua::JA::Expand::Base);

__PACKAGE__->mk_virtual_methods($_) for qw(tokenize);



1;

__END__

=head1 NAME

Lingua::JA::Expand::Tokenizer - Base Class of Lingua::JA::Expand::Tokenizer::XXX

=head1 SYNOPSYS

  package My::Tokenizer;
  use base qw(Lingua::JA::Expand::Tokenizer);


=cut
