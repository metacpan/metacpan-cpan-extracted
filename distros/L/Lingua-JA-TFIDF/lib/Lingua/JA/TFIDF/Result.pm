package Lingua::JA::TFIDF::Result;
use strict;
use warnings;
use base qw(Lingua::JA::TFIDF::Base);

sub new {
    my $class = shift;
    my $data  = shift;
    my $self = $class->SUPER::new();
    $self->{data} = $data;
    return $self;
}

sub list {
    my $self = shift;
    my $num  = shift;
    my @list;
    my $data = $self->{data};
    my ( $word, $ref ) = each %$data;
    my $label = 'tf';
    $label = 'tfidf' if $ref->{tfidf};
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

sub dump {
    my $self = shift;
    return $self->{data};
}

1;
__END__

=head1 NAME

Lingua::JA::TFIDF::Result - Result data object class. 

=head1 SYNOPSIS

  use Lingua::JA::TFIDF;
  use Data::Dumper;

  my $calc   = Lingua::JA::TFIDF->new(%config);

  # calculate TFIDF and return a result object.
  my $result = $$calc->tfidf;

=head1 DESCRIPTION

Lingua::JA::TFIDF::Result is result data object class.
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

