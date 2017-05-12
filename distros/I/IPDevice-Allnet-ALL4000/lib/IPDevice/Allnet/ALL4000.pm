package IPDevice::Allnet::ALL4000;
use 5.010000;
our $VERSION = '0.13';

use strict;
use warnings;
use LWP::UserAgent;
use XML::Parser;

sub new
{
    my ($class, %args) = @_;
    my $self = {}; 

    # Some Defaults
    $self->{USERNAME} = undef;
    $self->{PASSWORD} = undef;
    $self->{PORT}     = 80;

    foreach my $arg (keys %args)
    {
        $self->{$arg} = $args{$arg};
    }

    unless( $self->{USERNAME} && $self->{USERNAME} =~ m/\w*/ )
    {
        die( "Username not given or in correct format\n" );
    }
    unless( $self->{PASSWORD} && $self->{PASSWORD} =~ m/\w*/ )
    {
        die( "Password not given or in correct format\n" );
    }

    unless( $self->{HOST} )
    {
        die( "Host must be defined\n" );
    }
    
    unless( $self->{PORT} && $self->{PORT} =~ m/^\d*$/ )
    {
        die( "Port must be defined, and must be an integer\n" );
    }

    $self->{URL} = "http://$self->{HOST}:$self->{PORT}/xml";

    my $ua = LWP::UserAgent->new;
    $ua->credentials("$self->{HOST}:$self->{PORT}", "ALL4000", $self->{USERNAME}, $self->{PASSWORD} );
    $self->{UA} = $ua;

    my $parser = new XML::Parser(Style => 'Tree');
    $parser->setHandlers( Start => \&_start_handler,
                          Final => \&_final_handler,
                          );
    $self->{PARSER} = $parser;

    bless($self);
    return($self);
}

sub getData
{
    my $self = shift;

    my $response = $self->{UA}->get( $self->{URL} );
    unless ($response->is_success)
    {
        die( "Error connecting to server: " . $response->status_line . "\n" );
    }
    my $page = $response->content;
    unless( $page =~ m/(<xml>.*<\/xml>)/s )
    {
        die( "Could not find the XML element in the page\n" );
    }
    $self->{DATA} = $self->{PARSER}->parse( $1 );
    return $self->{DATA};
}


sub lastData
{
    my $self = shift;
    return $self->{DATA};
}

# Handler for start of XML element
sub _start_handler
{
    my( $expat, $element ) = @_;
    if( $element eq 'data' )
    {
        $expat->setHandlers( Char => \&_char_handler );
    }
}

# Handler for end of XML element
sub _final_handler
{
    my( $expat, $element ) = @_;
    delete( $expat->{ALL4000_DATA}->{data} );
    return $expat->{ALL4000_DATA};
}

# gets the actual data from the XML
sub _char_handler
{
    my ($p, $data ) = @_;
    if( $data )
    {
        $p->{ALL4000_DATA}->{$p->current_element} = $data;
    }
}

1;

__END__

=pod

=head1 NAME

IPDevice::Allnet::ALL4000 - provides an interface to ALL4000 ethernet sensormeter

=head1 SYNOPSIS

  use IPDevice::Allnet::ALL4000
  my $all4000 = new IPDevice::Allnet::ALL4000(
                        HOST     => $host,
                        USERNAME => $username,
                        PASSWORD => $password,
                        PORT     => '80' );

All variables are necessary.

=head1 DESCRIPTION

This package provides an interface to ALL4000 ethernet sensormeter device

=head1 METHODS

=head2 new
 
  my $all4000 = new IPDevice::Allnet::ALL4000(
                        HOST     => $host,
                        USERNAME => $username,
                        PASSWORD => $password,
                        PORT     => '80' );

Makes a new object ready to make requests from the ALL4000 ethernet sensormeter

=head2 getData
 
  $data = $all4000->getData();

Makes a new request to the server and returns an anonymous hash of all the data points.

=head2 lastData
 
  $data = $all4000->lastData();

If a getData request was made before, this will return the last data set, otherwise undef will be returned.

=head1 AUTHOR

Robin Clarke C<rcl@cpan.org>

=head1 LASTMOD

28.01.2009

=head1 CREATED

23.01.2009

=cut
