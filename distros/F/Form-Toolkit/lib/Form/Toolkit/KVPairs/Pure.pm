package Form::Toolkit::KVPairs::Pure;
{
  $Form::Toolkit::KVPairs::Pure::VERSION = '0.008';
}
use Moose;
extends qw/Form::Toolkit::KVPairs/;

=head1 NAME

Form::Toolkit::KVPairs::Pure - A pure Perl structure based KVPairs Set.

=head2 SYNOPSYS

 my $set = Form::Toolkit::KVPairs::Pure
             ->new({ array => [ { 1 => 'One'},
                                { 2 => 'Two'},
                                 ...
                              ]});


=cut

has 'array' => ( is => 'ro' , isa => 'ArrayRef[HashRef]' , required => 1);

## Internal stuff
has '_index' => ( is => 'ro' , isa => 'HashRef[Defined]' , lazy_build => 1 );
has '_it' => ( is => 'rw' , isa => 'Int' , clearer => '_clear_it' );

sub _build__index{
  my ($self) = @_;

  my $idx = {};
  foreach my $kv ( @{$self->array()} ){
    my @kv = %$kv;
    if( $idx->{$kv[0]}){
      confess("Key ".$kv[0]." is repeated in your key value pairs");
    }
    $idx->{$kv[0]} = $kv[1];
  }
  return $idx;
}

=head2 size

See superclass L<Form::Toolkit::KVPairs>

=cut

sub size{
  my ($self) = @_;
  return scalar(@{$self->array()});
}

=head2 lookup

See superclass L<Form::Toolkit::KVPairs>

=cut

sub lookup{
  my ($self , $key) = @_;
  return $self->_index()->{$key};
}

=head2 next_kvpair

See superclass L<Form::Toolkit::KVPairs>

=cut

sub next_kvpair{
  my ($self) = @_;
  unless( defined $self->_it() ){
    $self->_it(0);
  }

  if( my $kv = $self->array->[$self->_it()] ){
    $self->_it($self->_it() + 1 );
    return %{$kv};
  }

  ## We reached the end.
  $self->_clear_it();
  return ();
}

1;
