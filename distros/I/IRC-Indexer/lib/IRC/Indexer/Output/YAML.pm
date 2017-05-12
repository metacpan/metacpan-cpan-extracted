package IRC::Indexer::Output::YAML;

use strict;
use warnings;
use YAML::XS ();

require IRC::Indexer::Output;
our @ISA = qw/IRC::Indexer::Output/;

sub dump {
  my ($self, $path) = @_;
  my $input = $self->{Input};
  $self->{Output} = YAML::XS::Dump($input);
  $self->SUPER::dump();
}

sub write {
  my ($self, $path) = @_;
  my $input = $self->{Input};
  $self->{Output} = YAML::XS::Dump($input);
  $self->SUPER::write($path);
}

1;
__END__

=pod

=head1 NAME

IRC::Indexer::Output::YAML - YAML::XS output subclass

=head1 DESCRIPTION

L<IRC::Indexer::Output> subclass serializing via L<YAML::XS>.

See L<IRC::Indexer::Output> for usage details.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
