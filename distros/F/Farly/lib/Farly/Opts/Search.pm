package Farly::Opts::Search;

use 5.008008;
use strict;
use warnings;
use Carp;
use Socket;
use Log::Any qw($log);
use Farly::ASA::PortFormatter;
use Farly::ASA::ProtocolFormatter;

our $VERSION = '0.26';

sub new {
    my ( $class, $opts ) = @_;

    defined($opts)
      or confess "options hash object required";

    confess "invalid options type ", ref($opts)
      unless ( ref($opts) eq 'HASH' );

    my $self = {
        SEARCH => Farly::Object->new(),
        FILTER => Farly::Object::List->new(),
    };

    bless( $self, $class );
    
    $log->info("$self new");

    $self->_check_opts($opts);

    return $self;
}

sub search { return $_[0]->{SEARCH} }
sub filter { return $_[0]->{FILTER} }

sub _check_opts {
    my ( $self, $opts ) = @_;

    $self->_id($opts);
    $self->_action($opts);
    $self->_protocol($opts);
    $self->_src_ip($opts);
    $self->_dst_ip($opts);
    $self->_src_port($opts);
    $self->_dst_port($opts);
    $self->_exclude_src($opts);
    $self->_exclude_dst($opts);

}

sub _id {
    my ( $self, $opts ) = @_;

    if ( defined $opts->{'id'} ) {
        $self->search->set( 'ID', Farly::Value::String->new( $opts->{'id'} ) );
    }
}

sub _action {
    my ( $self, $opts ) = @_;

    if ( defined $opts->{'action'} ) {
        my $action = $opts->{'action'};
        if ( $action !~ /permit|deny/ ) {
            die "action must be 'permit' or 'deny'";
        }
        $self->search->set( 'ACTION', Farly::Value::String->new($action) );
    }
}

sub _protocol {
    my ( $self, $opts ) = @_;

    if ( defined $opts->{'p'} ) {
        my $protocol = $opts->{'p'};
        $protocol =~ s/^\s+|\s+$//g;
        my $protocol_formatter = Farly::ASA::ProtocolFormatter->new();
        if ( $protocol =~ /^\d+$/ ) {
            $self->search->set( 'PROTOCOL', Farly::Transport::Protocol->new($protocol) );
        }
        elsif ( $protocol =~ /^\S+$/ ) {
            my $protocol_number = $protocol_formatter->as_integer($protocol);
            die "unknown protocol '$protocol'\n"
              if ( !defined $protocol_number );
            $self->search->set( 'PROTOCOL', Farly::Transport::Protocol->new($protocol_number) );
        }

    }
}

sub _set_ip {
    my ( $self, $property, $ip ) = @_;

    if ( $ip =~ /((\d{1,3})((\.)(\d{1,3})){3})\s+((\d{1,3})((\.)(\d{1,3})){3})/ )
    {
        $self->search->set( $property, Farly::IPv4::Network->new($ip) );
    }
    elsif ( $ip =~ /(\d{1,3}(\.\d{1,3}){3})(\/)(\d+)/ ) {
        $self->search->set( $property, Farly::IPv4::Network->new($ip) );
    }
    elsif ( $ip =~ /((\d{1,3})((\.)(\d{1,3})){3})/ ) {
        $self->search->set( $property, Farly::IPv4::Address->new($ip) );
    }
    elsif ( $ip =~ /\S+/ ) {
        my @addresses = gethostbyname($ip);
        if (@addresses) {
            @addresses = map { inet_ntoa($_) } @addresses[ 4 .. $#addresses ];
            $self->search->set( $property, Farly::IPv4::Address->new( $addresses[0] ) );
            print "$ip [", $addresses[0], "]\n";
        }
        else {
            die "Unable to resolve host '$ip'\n";
        }
    }
    else {
        die "Invalid IP '$ip'\n";
    }
}

sub _src_ip {
    my ( $self, $opts ) = @_;

    if ( defined $opts->{'s'} ) {
        my $ip = $opts->{'s'};
        $self->_set_ip( 'SRC_IP', $ip );
    }
}

sub _dst_ip {
    my ( $self, $opts ) = @_;

    if ( defined $opts->{'d'} ) {
        my $ip = $opts->{'d'};
        $self->_set_ip( 'DST_IP', $ip );
    }
}

sub _set_port {
    my ( $self, $property, $port ) = @_;

    my $port_formatter = Farly::ASA::PortFormatter->new();

    $port =~ s/^\s+|\s+$//g;
    
    if ( $port =~ /^\d+$/ ) {
        $self->search->set( $property, Farly::Transport::Port->new($port) );
    }
    elsif ( $port =~ /^\S+$/ ) {
        my $port_number = $port_formatter->as_integer($port)
          or die "unknown port '$port'\n";
        $self->search->set( $property, Farly::Transport::Port->new($port_number) );
    }
    else {
        die "$port is not a port number\n";
    }    
}

sub _src_port {
    my ( $self, $opts ) = @_;

    if ( defined $opts->{'sport'} ) {
        my $port = $opts->{'sport'};
        $self->_set_port( 'SRC_PORT', $port );
    }
}

sub _dst_port {
    my ( $self, $opts ) = @_;

    if ( defined $opts->{'dport'} ) {
        my $port = $opts->{'dport'};
        $self->_set_port( 'DST_PORT', $port );
    }
}

sub _set_exclude {
    my ( $self, $property, $file_name ) = @_;

    my $file = IO::File->new($file_name)
      or croak "Please specify a valid file for exclusion\n";

    while ( my $line = $file->getline() ) {
        next if ( $line !~ /\S+/ );
        my $exlude = Farly::Object->new();
        $exlude->set( $property, Farly::IPv4::Network->new($line) );
        $self->filter->add($exlude);
    }

}

sub _exclude_src {
    my ( $self, $opts ) = @_;

    if ( defined $opts->{'exclude-src'} ) {
        my $file_name = $opts->{'exclude-src'};
        croak "$file_name is not a valid file" unless ( -f $file_name );
        $self->_set_exclude( 'SRC_IP', $file_name );
    }
}

sub _exclude_dst {
    my ( $self, $opts ) = @_;

    if ( defined $opts->{'exclude-dst'} ) {
        my $file_name = $opts->{'exclude-dst'};
        croak "$file_name is not a valid file" unless ( -f $file_name );
        $self->_set_exclude( 'DST_IP', $file_name );
    }
}

1;
__END__

=head1 NAME

Farly::Opts::Search - Create a Farly::Object from a Getopts hash

=head1 DESCRIPTION

Farly::Opts::Search converts a Getopt::Long options hash to an Farly::Object
which can be used to search a Farly::Object::List<Farly::Object> firewall
model.  

Farly::Opts::Search can also create a Farly::Object::List<Farly::Object>
container object from a configuration file. The container is used as a filter
to exclude firewall rules from the search results of the current Farly firewall
model.

=head1 METHODS

=head2 new( \%opts )

The constructor. The Getopt::Long GetOptions hash is provided.

  $search_parser = Farly::Opts::Search->new( \%opts );

=head2 search()

Returns a Farly::Object search object used to search for firewall
rules in the current Farly firewall model.

  $search_object = $search_parser->search();

=head2 filter()

Returns a Farly::Object::List<Farly::Object> container used to exclude 
firewall rules from the search results of the current Farly firewall
model.

  $filter_set = $search_parser->filter();

=head1 COPYRIGHT AND LICENCE

Farly::Opts::Search
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
