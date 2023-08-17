#ABSTRACT: Subroutines for FR24-Bot
package FR24::Bot;
use v5.12;
use warnings;
use JSON::PP;
use Data::Dumper;
use Exporter qw(import);
use HTTP::Tiny;
use File::Which;
use FR24::Utils;
use Carp qw(confess);
our $VERSION = "0.0.3";
my $UPDATE_MS = 10 * 1000;
# Export version
our @EXPORT = qw($VERSION);
our @EXPORT_OK = qw(new get);
 

sub new {
    my $class = shift @_;

    my $name = undef;
    my $config = undef;
    my $refresh = $UPDATE_MS;
    my $test_mode = 0;
    # Descriptive instantiation with parameters -param => value
    if (substr($_[0], 0, 1) eq '-') {
        my %data = @_;
        # Try parsing
        for my $i (keys %data) {
            if ($i =~ /^-conf/i) {
                #Can be -conf, -config and other crazy stuff, hope not -confused
                $config = $data{$i};
                if (ref($config) ne "HASH") { 
                    $config = FR24::Utils::loadconfig($config);
                }
            } elsif ($i =~ /^-(name|id)$/i) {
                $name = $data{$i};
            } elsif ($i =~ /^-refresh$/i) {
                # Receive seconds, convert to milliseconds
                $refresh = 1000 * $data{$i};
            } elsif ($i =~ /^-test$/i) {
                # Receive seconds, convert to milliseconds
                $test_mode = 1 if $data{$i};
            } else {
                confess "ERROR FR24::Bot: Unknown parameter $i\n";
            }
        }
    } 
  
   
 
 
    my $self = bless {}, $class;
     
    if (not defined $config->{telegram}->{apikey}) {
        confess "ERROR FR24::Bot: No config provided or no apikey found\n";
    }
    $self->{apikey} = $config->{telegram}->{apikey};
    $self->{name} = $name;
    $self->{config} = $config;
    $self->{ip} = $config->{server}->{ip};
    $self->{port} = $config->{server}->{port};
    $self->{localip} = undef;
    $self->{refresh} = $refresh;
    $self->{total} = 0;
    $self->{uploaded} = 0;
    $self->{flights} = {};
    $self->{callsigns} = {};
    $self->{flights_url} = "http://" . $self->{ip} . ":" . $self->{port} . "/flights.json";

    $self->{users} = {};
    $self->{last_updated} = 0;
    $self->{last_url} = undef;
    $self->{test_mode} = $test_mode;
    $self->update();
    return $self;
  
}

sub _timestamp_milliseconds {
    return int(time * 1000);
}
sub update {
    my $self = shift;
    
    my $timestamp = _timestamp_milliseconds();
    if ($timestamp - $self->{last_updated} < $self->{refresh}) {
        # Update only once per second
        return;
    }
    $self->{last_updated} = $timestamp;
    my $url = $self->{flights_url} . "?time=" . _timestamp_milliseconds();
    $self->{last_url} = $url;
    confess "No URL specified for update\n" unless defined $url;

    my $content = _curl($url);
    $self->{content} = $content;
    my $data = FR24::Utils::parse_flights($content, $self->{test_mode});
    # Parse the content here
    # Example: extracting flight information
    #my @flights = extract_flights($content);

    # Update the object properties
    $self->{flights} = $data->{data};
    $self->{callsigns} = $data->{callsigns};
    $self->{total} = $data->{total};
    $self->{uploaded} = $data->{uploaded};

    return;
}



# Write a $self->update() method to update the object
sub getflight {
    my ($self, $callsign) = @_; 
    if (not defined $self->{'callsigns'}->{$callsign}) {
        return 0;
    }
   
    return $self->{'flights'}->{ $self->{'callsigns'}->{$callsign} };
}

sub _curl {
    my $url = shift;
    my $response = "";
    eval {
        my $http = HTTP::Tiny->new();
        my $response = $http->get($url);

        if ($response->{success}) {
            return $response->{content};
        } else {
            return "Failed to retrieve URL: $response->{status} $response->{reason}\n";
        }
    };
}

__END__

=pod

=encoding UTF-8

=head1 NAME

FR24::Bot - Subroutines for FR24-Bot

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

  use FR24::Bot;
  my $bot = FR24::Bot->new(
        -conf => "config.json", 
        -name => "bot_1"
  );
  $bot->update();

=head1 DESCRIPTION

The FR24::Bot module provides an interface for managing and updating a FR24 Bot, 
which is designed to interact with flight data from the FR24 API. 

=head1 CLASS METHODS

=head2 new

The new method is the constructor for the FR24::Bot object. 
It expects a hash with C<-conf> and C<-name> keys, or it will throw an exception.

  my $bot = FR24::Bot->new(
    -conf => "config.json", 
    -name => "bot_1"
  );

Here, the C<-conf> key is a configuration file or a hashref with configuration information. 

The C<-name> key is a string with the name of the bot.

=head1 INSTANCE METHODS

=head2 update

The update method fetches the latest flight data from the FR24 API and updates the L<FR24::Bot> object. 

This method should be called periodically to keep the bot's data up to date.

  $bot->update();

This method does not take any arguments, and does not return any value. 

Will not execute if the last update was less than 10 seconds ago.

=cut

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
