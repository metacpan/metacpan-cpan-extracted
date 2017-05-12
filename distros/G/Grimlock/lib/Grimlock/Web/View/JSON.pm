package Grimlock::Web::View::JSON;
{
  $Grimlock::Web::View::JSON::VERSION = '0.11';
}

use strict;
use base 'Catalyst::View::JSON';
use JSON::XS ();
use Try::Tiny;

sub encode_json {
    my($self, $c, $data) = @_;
    my $encoder = JSON::XS->new->ascii->allow_nonref->convert_blessed->allow_blessed;
    $encoder->pretty if $c->debug;
    my $d = $encoder->encode($data);
    return $d;
}
 
sub process {
    my ( $self, $c, $stash_key ) = @_;
 
    my $output;
    try {
      $output = $self->serialize( $c, $c->stash->{$stash_key} );
      $c->response->body( $output );
       return 1; 
     } catch {                                            
       $c->log->error("Couldn't serialize: $_");
       return $_;
     };
}
 
sub serialize {
    my ( $self, $c, $data ) = @_;
 
    my $serialized = $self->encode_json($c, $data); 
    return $serialized;
}


=head1 NAME

Grimlock::Web::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<Grimlock::Web>

=head1 DESCRIPTION

Catalyst JSON View.

=head1 AUTHOR

Devin Austin

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
