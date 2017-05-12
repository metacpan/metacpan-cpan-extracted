package Form::Toolkit::KVPairs::DBICRs;
{
  $Form::Toolkit::KVPairs::DBICRs::VERSION = '0.008';
}
use Moose;
extends qw/Form::Toolkit::KVPairs/;

=head1 NAME

Form::Toolkit::KVPairs::DBICRs - A DBIx::Class::ResultSet adapter.

=head1 SYNOPSIS

 my $set = Form::Toolkit::KVPairs::DBICRs->new({ rs => $a_dbic_resultset,
                                        key => 'the_id_column',
                                        value => 'the_value_column' });

Note that key defaults to 'id'

Then use as a L<Form::Toolkit::KVPairs>.

=head1 CAVEATS

Doesn't manage composed keys for now.

=cut

has 'rs' => ( isa => 'DBIx::Class::ResultSet', is => 'ro' , required => 1 );
has 'key' => ( isa => 'Str' , is => 'ro' , required => 1 , default => 'id' );
has 'value' => ( isa => 'Str' , is => 'ro', required => 1 );

has '_search_rs' => ( isa => 'DBIx::Class::ResultSet', is => 'rw' , clearer => 'clear_search_rs' );

=head2 size

See superclass L<Form::Toolkit::KVPairs>

=cut

sub size{
  my ($self) = @_;
  return $self->rs->count();
}

=head2 next_kvpair

See superclass L<Form::Toolkit::KVPairs>

=cut

sub next_kvpair{
  my ($self) = @_;

  my $srs = $self->_search_rs();
  unless( $srs ){
    $srs = $self->_search_rs($self->rs->search_rs());
  }

  my $next_row = $srs->next();
  unless( $next_row ){
    $self->clear_search_rs();
    return ();
  }

  my ( $key , $value ) = ( $self->key() , $self->value() );
  return ( $next_row->$key() , $next_row->$value() );
}

=head2 lookup

See superclass L<JCON::KVPairs>

=cut

sub lookup{
  my ($self, $lookup_key) = @_;
  my ($key , $value ) = ( $self->key() , $self->value() );
  if( my $row = $self->rs->find({ $key => $lookup_key }) ){
    return ( $row->$key() , $row->$value() );
  }
  return undef;
}

1;
