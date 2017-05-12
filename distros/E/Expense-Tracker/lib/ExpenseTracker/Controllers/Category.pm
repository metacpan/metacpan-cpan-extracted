package ExpenseTracker::Controllers::Category;
{
  $ExpenseTracker::Controllers::Category::VERSION = '0.008';
}
{
  $ExpenseTracker::Controllers::Category::VERSION = '0.008';
}
use Mojo::Base 'ExpenseTracker::Controllers::Base';

sub new{
  my $self = shift;
  
  my $obj = $self->SUPER::new(@_);
  
  $obj->{resource} = 'ExpenseTracker::Models::Result::Category';

  return $obj;
  
}

sub show{
  my $self = shift;

  return $self->render(status => 405,  json => {message => 'You can only see your own categories!!!'} )
    if ( !defined $self->param('id') or !defined $self->app->user or !scalar( $self->app->user->categories( id => $self->param('id') )->all ) );

   my $result_rs = $self->app->model
    ->resultset( $self->{resource} )
    ->search_rs( {
        user_id => $self->app->user->id,
        id      => $self->param('id'),
    } );
  
  my $result = [];  

   while (my $categ = $result_rs->next){
      push @$result, {
        id          => $categ->id,
        parent_id   => $categ->parent_id,
        name        => $categ->name,
        user_id     => $categ->user_id,
        children    => [ $categ->children->get_column('id')->all ],
      };
   }
  return $self->render_not_found() if scalar @$result == 0 ;
  return $self->render_json( $result );
}


=head update
  sample of overriding a default update method
=cut
sub update{
  my $self = shift;
  
  return $self->render(status => 405,  json => {message => 'You can only update your own categories!!!'} )
    if ( !defined $self->param('id') or !defined $self->app->user or !scalar( $self->app->user->categories( id => $self->param('id') )->all ) );
    
  $self->{_payload}->{user_id} = $self->app->user->id;
  
  return $self->SUPER::update(@_);
}

sub list{
  my $self = shift;
  
  my $result_rs = $self->app->model
    ->resultset( $self->{resource} )
    ->search_rs( { user_id => defined $self->app->user ? $self->app->user->id : -1 } );
  
  my $result = [];
  #$result->result_class('DBIx::Class::ResultClass::HashRefInflator');  
   
   while (my $categ = $result_rs->next){
      push @$result, {
        id          => $categ->id,
        parent_id   => $categ->parent_id,
        name        => $categ->name,
        user_id     => $categ->user_id,
        children    => [ $categ->children->get_column('id')->all ],
      };
   }
  return $self->render_not_found() if scalar @$result == 0 ;
  return $self->render_json( $result );
  
}

1;

__END__
=pod
 
=head1 NAME
ExpenseTracker::Controllers::Category - Controller responsible for the Category resource


=head1 VERSION

version 0.008

=cut
