package Lingua::JA::OkapiBM25::Result;
use strict;
use warnings;
use base qw(Lingua::JA::TFIDF::Result);


sub list {
	my $self = shift;
    my $num  = shift;
    my @list;
    my $data = $self->{data};
    my ( $word, $ref ) = each %$data;
    my $label = 'bm25';
    my $i = 0;
    for (
        sort { $data->{$b}->{$label} <=> $data->{$a}->{$label} }
        keys %{ $self->{data} }
      )
    {
        push( @list, { $_ => $data->{$_}->{$label} } );
        $i++;
        last if $num and $i == $num;
    }
    return \@list;
}

1;
__END__

=head1 NAME

Lingua::JA::OkapiBM25::Result - Result data object class. 

=head1 SYNOPSIS

  use Lingua::JA::OkapiBM25;
  use Data::Dumper;

  my $calc   = Lingua::JA::OkapiBM25->new(%config);

  # calculate BM25 and return a result object.
  my $result = $calc->bm25;

=head1 DESCRIPTION

Lingua::JA::OkapiBM25::Result is result data object class.
It provides list() and dump() method.

=head1 METHODS

=head2 new(%config)

=head2 list($num); 

If $num was posted, it returns $num items.
(default is undef)

=head2 dump(); 

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO


=cut

