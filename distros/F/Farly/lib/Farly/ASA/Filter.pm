package Farly::ASA::Filter;

use 5.008008;
use strict;
use warnings;
use Carp;
use Log::Any qw($log);

our $VERSION = '0.26';

sub new {
    my ($class) = @_;

    my $self = {
        FILE     => undef,
        PREPARSE => [],
        OG_INDEX => {},      #object-group to type mapping
        ACL_ID   => {},      #for inserting line numbers
    };
    bless $self, $class;
    
    $log->info("$self NEW");

    return $self;
}

sub set_file {
    my ( $self, $file ) = @_;
    $self->{FILE} = $file;  
    $log->info( "$self set FILE to " . $self->{FILE} );
}

sub append {
    my ( $self, $string ) = @_;
    defined($string)
      or confess " $self attempted to append undefined string to PREPARSE";
    push @{ $self->{PREPARSE} }, $string;
}

sub run {
    my ($self) = @_;

    my $file = $self->{FILE};

    my $interface_options = "nameif|security-level|ip address"; #shutdown
    my $object_options    = "host|range|subnet|service";
    my $group_options     = "network-object|port-object|group-object|protocol-object|description|icmp-object|service-object";
    my $unsupported_acl_type = "ethertype|standard|webtype";

    while ( my $line = $file->getline() ) {

        $log->trace("$self SCAN $line");

        if ( $line =~ /^hostname (\S+)/ ) {
            $self->append($line);
            next;
        }
        if ( $line =~ /^name (\S+) (\S+)/ ) {
            $self->append($line);
            next;
        }
        if ( $line =~ /^interface/ ) {
            $self->_process_section( $line, $interface_options, 1 );
            next;
        }
        if ( $line =~ /^object\s/ ) {
            $self->_process_section( $line, $object_options );
            next;
        }
        if ( $line =~ /^object-group (\S+) (\S+)/ ) {
            my $type = $1;
            my $id   = $2;
            $self->{OG_INDEX}->{$id} = $type;
            $log->debug("added OG_INDEX $id $type");
            $self->_process_section( $line, $group_options );
            next;
        }
        if ( $line =~ /^access-list (.*) $unsupported_acl_type/ ) {
            $log->info("$self SKIPPED access-list '$line'");
            next;
        }

        #access-list outside-in line 3 extended permit tcp OG_NETWORK internal OG_SERVICE highports host 192.168.2.1 eq 80
        if ( $line =~ /^access-list/ ) {
            my $p_line = $self->_process_acl($line);
            $log->debug("$self pre-processed line '$p_line'");
            $self->append($p_line);
            next;
        }
        if ( $line =~ /^access-group/ ) {
            $self->append($line);
            next;
        }
        if ( $line =~ /^route/ ) {
            $self->append($line);
        }
    }

    return @{ $self->{PREPARSE} };
}

sub _process_section {
    my ( $self, $header, $options, $full_sect ) = @_;

    my $file = $self->{FILE};
    my $pos  = $file->getpos();
    my $line = $file->getline();

    $log->debug("$header");
    my $header_pos = $pos;

    while ( $line &&  $line =~ /^\s/ ) {

        if ( $line =~ /^\s(?=$options)/ ) {
            $log->debug("$line");
            if ( defined($full_sect) ) {
                $header .= $line;
            }
            else {
                $self->append( $header . $line );
            }
        }
        else {
            chomp($line);
            $log->warn("unknown option in line '$line'");
        }

        $pos  = $file->getpos();
        $line = $file->getline();
    }

    if ( defined($full_sect) ) {
        $self->append($header);
    }

    if ( $pos eq $header_pos ) {
        $log->warn("empty section : '$header'");
    }

    $file->setpos($pos);
}

sub _process_acl {
    my ( $self, $line ) = @_;

    # add line number to configuration access-list
    if ( $line =~ /^access-list (\S+)/ ) {
        my $acl_id = $1;
        if ( !$self->{ACL_ID}->{$acl_id} ) {
            $self->{ACL_ID}->{$acl_id} = 1;
        }
        else {
            $self->{ACL_ID}->{$acl_id}++;
        }
        my $line_count = $self->{ACL_ID}->{$acl_id};
        $line =~ s/access-list $acl_id/access-list $acl_id line $line_count/;
    }

    # translate "object-group" to OG_<TYPE> format
    if ( $line =~ /object-group/ ) {

        my @lineArr = split( /\s+/, $line );

        while (@lineArr) {
            my $string = shift @lineArr;
            if ( $string =~ /object-group/ ) {
                my $og_ID = shift @lineArr;

                my $og_type = $self->{OG_INDEX}->{$og_ID}
                  or confess "no object-group type for $og_ID";

                my $new_og_type = "OG_" . uc($og_type);
                $line =~ s/object-group $og_ID/$new_og_type $og_ID/;
            }
        }
    }

    return $line;
}

1;
__END__

=head1 NAME

Farly::ASA::Filter - Firewall configuration filter and pre-processor

=head1 DESCRIPTION

Farly::ASA::Filter filters out unneeded configuration and pre-formats
the configuration in a manner as needed by the parser. It accepts
the configuration in an IO::File object, and stores the pre formatted
configuration, line by line, into an array.

Unrecognized configuration options are logged but the filter
does not die.

Farly::ASA::Filter is used by the Farly::ASA::Builder only.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::Filter
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
