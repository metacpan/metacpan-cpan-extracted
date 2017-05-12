package ExpenseTracker::Controllers::Base;
{
  $ExpenseTracker::Controllers::Base::VERSION = '0.008';
}
{
  $ExpenseTracker::Controllers::Base::VERSION = '0.008';
}

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Mojo::Util;
use DateTime;

use DBIx::Class::ResultClass::HashRefInflator;
use Lingua::EN::Inflect qw/PL/;


sub new{
  my $self = shift;
  
  my $obj = $self->SUPER::new(@_);
  
  $obj->_after_init();
  
  return $obj;
}

sub create{
  my $self = shift;
  
  $self->_before_create( @_ );
  
  my $result = $self->app->model
    ->resultset( $self->{resource} )    
    ->create( $self->{_payload} );   

  return $self->render_json( $result->{_column_data} );
}

sub update{
  my $self = shift;
  
  my $result_rs = $self->app->model
    ->resultset( $self->{resource} )
    ->search_rs(
        { id => $self->param('id') },         
    );
  
  return $self->render_not_found if ( scalar( ( $result_rs->all ) ) == 0 );  
  
  $result_rs->update_all( $self->{_payload} );
  
  $result_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  my @result = $result_rs->all();
  return $self->render_json( @result );
}

sub list{
  my $self = shift;  
    
  my $result = $self->app->model
    ->resultset( $self->{resource} )
    ->search_rs;
  
  $result->result_class('DBIx::Class::ResultClass::HashRefInflator');

  #TODO: paging for the records
  return $self->render_json( [ $result->all() ] );
}


sub show{
  my $self = shift;
  
  my $result = $self->app->model
      ->resultset( $self->{resource} )
      ->search_rs(
          { id => $self->param('id') },
          { result_class => 'DBIx::Class::ResultClass::HashRefInflator' },
      )
      ->first;  
  
  return $self->render_not_found if ( ref $result eq 'HASHREF' );
  return $self->render_json( $result );
}

sub remove{
  my $self = shift;  
  
  my $result_rs = $self->app->model
      ->resultset( $self->{resource} )
      ->search_rs(
          { id => $self->param('id') },         
      );

  
  return $self->render_not_found if ( scalar( ( $result_rs->all ) ) == 0 );
  
  $result_rs->delete_all;
  
  my $resource_name = Mojo::Util::decamelize( ( split '::', $self->{resource} )[-1] );
  return $self->redirect_to( $self->url_for( 'list_'.PL( $resource_name ) ) ) ;
}

sub _after_init{
  my $self = shift;
  
  $self->{_payload} ||= ( $self->req->json or '' );

}

sub _before_create{
  my $self = shift;
  
  my $now = DateTime->now ;
  
  $self->{_payload}->{created_at} = ''.$now if ( 'created_at' ~~ [ $self->app->model->resultset( $self->{resource} )->result_source->columns ] );  
  $self->{_payload}->{updated_at} = ''.$now if ( 'updated_at' ~~ [ $self->app->model->resultset( $self->{resource} )->result_source->columns ] );
}

sub _before_update{
my $self = shift;
  
  my $now = DateTime->now ;  
  
  $self->{_payload}->{updated_at} = ''.$now if ( 'updated_at' ~~ [ $self->app->model->resultset( $self->{resource} )->result_source->columns ] );
}

1;

__END__
=pod
 
=head1 NAME
ExpenseTracker::Controllers::Base - base controller that provides the generic RESTful actions for a resource

=head1 VERSION

version 0.008

=cut
