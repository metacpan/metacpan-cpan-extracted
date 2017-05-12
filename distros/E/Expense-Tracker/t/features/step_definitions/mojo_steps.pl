#!perl

 use strict;
 use warnings;

 use Test::More; 
 use Test::Mojo;
 use Test::BDD::Cucumber::StepFile;
 use Method::Signatures;
 use Data::Dumper;
 
 Given qr/a mojo test object for the "(.+)" application/, func ($c) {
  use_ok( $1 );
  my $tm = Test::Mojo->new( $1 );
  
  # Allow redirects
  $tm->ua->max_redirects(5);
  $c->stash->{'feature'}->{'tm'} = $tm;
  ok( $c->stash->{'feature'}->{'tm'}, "Got our Test::Mojo object" );
 };
 
 When qr/I go to "(.+)"/, func ($c) {
    # $1 matches a word - that word is a url name 
    my $url_name = $1;
    
    # we should get a url identified by $url_name
    # urls in Mojo are named when the routes are defined (ie. the startup subroutine)    
    $c->stash->{'feature'}->{'tm'}->get_ok(  $c->stash->{feature}->{tm}->app->url_for( $url_name ) );
 };
 
 Then qr/I should see the "(.+)"\s+([^\s]+).*?$/, func ($c) {
    my $search_term = $1;
    my $object_type = $2;

    use_ok('Mojo::DOM');
    my $dom = Mojo::DOM->new($c->stash->{'feature'}->{'tm'}->tx->res->body());
    
    ok($dom, "Response is valid XHTML");

    if ( $object_type eq 'url' ){
      
      foreach my $link ( $dom->find('a[href]')->each ) {         
        pass("Found URL with text $search_term") and return 1 if $link->text eq $1;        
      }
      fail( "I have not seen $search_term of type $object_type" );
      
    } elsif( $object_type eq 'text'){  
    
      my $regex =  qr/\Q$search_term\E/im;
      ok( $c->stash->{'feature'}->{'tm'}->content_like( $regex ) );
      
    } elsif ( $object_type ~~ [ qw/input button/ ] ) {
        # it seems like the selector "input[type='submit'][value='$search_term']" is not working in Mojo::UA, but is working in chrome      
        my $selector_string = "input#$search_term";
        $c->stash->{'feature'}->{'tm'}->element_exists( $selector_string );        
    
    } else {
    
      pending( "I don't know how to find $object_type" );
    } 
    
 }