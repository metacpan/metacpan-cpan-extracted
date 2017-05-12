package MyCustomEngine;

use base qw(HTTP::Request::FromLog::Engine::Base);
use strict;
use warnings;
use Text::CSV_XS;

sub new {
    my $class = shift;
    my %args  = @_;
    $args{parser} = Text::CSV_XS->new( { sep_char => $args{sep_char} } );
    return $class->SUPER::new(%args);
}

sub parse {
    my $self = shift;
    my $rec  = shift;

    $self->{parser}->parse($rec);
    my @field = $self->{parser}->fields();

    my $uri = "http://" . $self->{host} . [ split( / /, $field[5] ) ]->[1];
    my $header = HTTP::Headers->new();
    $header->header( 'host'       => $self->{host} );
    $header->header( 'user-agent' => $field[9] );
    $header->header( 'referer'    => $field[8] );

    return ( { method => "GET", uri => $uri, header => $header } );
}

1;