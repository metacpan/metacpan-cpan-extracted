#!perl

use strict;
use warnings;

use Test::More; 
use Test::Mojo;
use Test::BDD::Cucumber::StepFile;
use Method::Signatures;
use Data::Dumper;
use Lingua::EN::Inflect::Phrase qw/to_S/;
  
When qr/I log in with username "(.+?)" and password "(.+?)"/, func($c) {
  my ($username, $password) = ( $1, $2 );  
  
  $c->stash->{'feature'}->{'tm'}->post_form_ok(
  $c->stash->{'feature'}->{'tm'}->app->url_for('authenticate_html'),
  {
    username => $username,
    password => $password,
  }  
  );
};

Given qr/the following ([^\s]+)/, func($c){
  my $resource_name = $1;
  
  $c->stash->{scenario}->{resource_name} = $resource_name;
  $c->stash->{scenario}->{resource_data} = $c->data;
  $c->stash->{scenario}->{resource_api_url} = sprintf('%s/%s',
      $c->stash->{'feature'}->{'tm'}->app->{config}->{api}->{base_url},
      $c->stash->{scenario}->{resource_name},
  );;
  
};

When qr/I create them through the REST API/, func($c){
  
  foreach my $resource_data ( @{ $c->stash->{scenario}->{resource_data} } ) {  
    $c->stash->{'feature'}->{'tm'}->post_json_ok( $c->stash->{scenario}->{resource_api_url}, $resource_data )->status_is(200);
  };  
  
};

Then qr/I should be able to list their ([^\s]+)/, func($c){
  my $col_name = Lingua::EN::Inflect::Phrase::to_S( $1 ) || 'name';
  
  my $list_of_resources = $c->stash->{'feature'}->{'tm'}->ua->get( $c->stash->{scenario}->{resource_api_url} )->res->json;
  ok($list_of_resources, sprintf('Received a list of %s from %s', $c->stash->{scenario}->{resource_name}, $c->stash->{scenario}->{resource_api_url}));
  
  
  my $received_column_values = [];
  @{ $received_column_values } = map { $_->{$col_name} } @{ $list_of_resources };
  
  my @wanted_column_data = map { $_->{ $col_name } } @{ $c->stash->{scenario}->{resource_data} };  
  
  foreach my $wanted_to_be_created ( @wanted_column_data ){
    cmp_ok( $wanted_to_be_created, '~~', $received_column_values, "$wanted_to_be_created was created");
  }
  
  #keep only the resources that were created by us
  @{ $c->stash->{scenario}->{list_of_resources} } = grep { $_->{ $col_name } ~~ [ @wanted_column_data ] } @$list_of_resources;
};

Then qr/I should be able to get their ([^\s]+)/, func($c){
  my $col_name = Lingua::EN::Inflect::Phrase::to_S( $1 ) || 'id';

  foreach my $created_resource ( @{ $c->stash->{scenario}->{list_of_resources} } ){  
    my $resource_url = sprintf('%s/%s', $c->stash->{scenario}->{resource_api_url}, $created_resource->{id} );
    
    #GET /api/currency/23
    my $received_from_api = $c->stash->{'feature'}->{'tm'}->ua->get( $resource_url )->res->json;
    
    cmp_ok( ref( $received_from_api ), 'eq', 'HASH', "Got a valid hashref from $received_from_api" );    
    cmp_ok( $received_from_api->{ $col_name }, '>', 0, sprintf("%s has %s > 0", $c->stash->{scenario}->{resource_name}, $col_name ) );
  }
};

Then qr/I should be able to delete them/, func($c){
  
  foreach my $created_resource ( @{ $c->stash->{scenario}->{list_of_resources} } ){
    my $delete_url = sprintf( '%s/%s', $c->stash->{scenario}->{resource_api_url}, $created_resource->{id} );
    
    $c->stash->{feature}->{tm}->delete_ok( $delete_url )->status_is( 200 );
  }
};
