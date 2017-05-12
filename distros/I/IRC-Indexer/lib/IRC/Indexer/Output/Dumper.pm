package IRC::Indexer::Output::Dumper;

use strict;
use warnings;

use Data::Dumper;

require IRC::Indexer::Output;
our @ISA = qw/IRC::Indexer::Output/;

sub dump {
  my ($self) = @_;
  my $input = $self->{Input};
  $self->{Output} = Dumper($input);
  $self->SUPER::dump();
}

sub write {
  my ($self, $path) = @_;  
  my $input = $self->{Input};
  $self->{Output} = Dumper($input);
  $self->SUPER::write($path);
}

1;
__END__

=pod

=head1 NAME

IRC::Indexer::Output::Dumper - Data::Dumper output subclass

=head1 DESCRIPTION

L<IRC::Indexer::Output> subclass serializing via Data::Dumper.

See L<IRC::Indexer::Output> for usage details.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
