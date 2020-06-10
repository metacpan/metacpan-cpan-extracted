#########################################################################################
# Package        HiPi::RF::OpenThings::Message
# Description  : Handle OpenThings protocol message
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::RF::OpenThings::Message;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use HiPi qw( :openthings :energenie );
use HiPi::RF::OpenThings;
use Try::Tiny;
use JSON;

our $VERSION ='0.81';

__PACKAGE__->create_accessors( qw(
    cryptseed
    errorbuffer
    databuffer
    epoch
    length
    ok
    configured_name
    records
    _mid
    _pid
    _sid
    _pip
    is_decoded
    is_encoded
    has_join_cmd
    has_join_ack
    switch_state
    switch_command
    has_command
));

sub new {
    my( $class, %params ) = @_;
    
    my( $sk_mid, $sk_pid, $sk_sid ) = ( 0, 0, 0 );
    
    if($params{sensor_key}) {
        ( $sk_mid, $sk_pid, $sk_sid ) = split(/-/, $params{sensor_key} );
        for ( $sk_mid, $sk_pid, $sk_sid ) {
            $_ = hex($_);
        }
    }
    
    $params{epoch} = time();
    $params{errorbuffer}  = [];
    $params{databuffer} //= [];
    $params{cryptseed} //= 1;
    $params{records} = [];
    $params{_mid} = $sk_mid || $params{mid} || $params{manufacturer_id} || 0;
    $params{_pid} = $sk_pid || $params{pid} || $params{product_id} || 0;
    $params{_sid} = $sk_sid || $params{sid} || $params{sensor_id} || 0;
    $params{_pip} = $params{pip} || $params{encrypt_pip} || 0;
    my $self = $class->SUPER::new( %params );
    return $self;
}

sub manufacturer_id { return $_[0]->_mid; }

sub product_id { return $_[0]->_pid; }

sub sensor_id { return $_[0]->_sid; }

sub encrypt_pip { return $_[0]->_pip; }

sub has_switch_state {
    my $self = shift;
    return ( defined($self->switch_state) ) ? 1 : 0;
}

sub sensor_key {
    my $self = shift;
    return HiPi::RF::OpenThings->format_sensor_key($self->manufacturer_id, $self->product_id, $self->sensor_id);  
}

sub product_name {
    my( $self  ) = @_;
    return HiPi::RF::OpenThings->product_name($self->manufacturer_id, $self->product_id );
}

sub manufacturer_name {
    my( $self  ) = @_;
    return HiPi::RF::OpenThings->manufacturer_name($self->manufacturer_id );
}

sub value_hash {
    my $self = shift;
    $self->decode_buffer unless $self->is_decoded;
    
    my $data = {
        timestamp       => $self->timestamp,
        manufacturer_id => $self->manufacturer_id,
        product_id      => $self->product_id,
        product_name    => $self->product_name,
        sensor_id       => $self->sensor_id,
        sensor_key      => $self->sensor_key,
        records         => [],
        manufacturer_name => $self->manufacturer_name,
        configured_name => $self->configured_name || '',
    };
    
    for my $record ( @{ $self->records } ) {
        push(  @{ $data->{records} },
             {
                name    => $record->name,
                value   => $record->value,
                units   => $record->units,
                command => $record->command,
                id      => $record->id,
                value_type => $record->typeid,
             }
        );
        
        if( $record->id == OPENTHINGS_PARAM_JOIN ) {
            if( $record->command ) {
                $data->{join_command} = 1;
            } else {
                $data->{join_ack} = 1;
            }
        }
        
        if( $record->id == OPENTHINGS_PARAM_SWITCH_STATE ) {
            $data->{switch_state} = $record->value;
            if( $record->command ) {
                $data->{switch_command} = 1;
            }
        }
    }
    return $data;
}

sub json {
    my ($self, $pretty) = @_;
    my $data = $self->value_hash;
    my $output = try {
        my $j = JSON->new;
        my $return = ( $pretty ) ? $j->pretty->canonical->encode( $data ) : $j->encode( $data );
        return $return;
    } catch {
        my $error = $_;
        $error =~ s/[\n"']+/ /g;
        return qq({"ok":0,"error":"$error"});
    };
}

sub encode_buffer {
    my $self = shift;
    my $result = try {
        my $payload = [ 0 ]; # len we will assign later
        push @$payload, $self->manufacturer_id;
        push @$payload, $self->product_id;
        push @$payload, ( $self->encrypt_pip >> 8 ) & 0xFF;
        push @$payload, $self->encrypt_pip & 0xFF;
        push @$payload, ( $self->sensor_id >> 16 ) & 0xFF;
        push @$payload, ( $self->sensor_id >> 8 ) & 0xFF;
        push @$payload, $self->sensor_id  & 0xFF;
        
        for my $record ( @{ $self->records } ) {
            # get some convenience values
            
            $self->has_command(1) if $record->command;
            
            if( $record->id == OPENTHINGS_PARAM_JOIN  ) {    
                if( $record->command ) {
                    $self->has_join_cmd(1);
                } else {
                    $self->has_join_ack(1);
                }
                
            } elsif($record->id == OPENTHINGS_PARAM_SWITCH_STATE  ) {
                $self->switch_state( $record->value );
                if( $record->command ) {
                    $self->switch_command(1);
                }
            }
                        
            my $writemask = ( $record->command ) ? OPENTHINGS_WRITE_MASK : 0x0;
            # ID and R/W
            push @$payload, $record->id | $writemask;
            # Type (will or/| length later)
            push @$payload, $record->typeid & 0xF0;
            
            # record position of type/length byte
            my $lenpos = ( scalar @$payload ) -1;
            
            my $val = $record->value;
            if(defined($val) && $val ne '') {
                my @valbytes = $self->encode_value( $record->typeid, $val );
                my $vallen = scalar( @valbytes );
                # max record length is 15 bytes;
                $vallen = 15 if $vallen > 15;
                $payload->[$lenpos] = ( $record->typeid & 0xF0 ) | ( $vallen & 0xF );
                for (my $vindex = 0; $vindex < $vallen; $vindex ++ ) {
                    push @$payload, $valbytes[$vindex];
                }
            }
        }
        
        # FOOTER
        push @$payload, 0; #NUL
        
        $self->databuffer( $payload );
        my $crc = $self->calculate_crc( 1 );
        
        push @$payload, ( $crc >> 8 ) & 0xFF;
        push @$payload, $crc & 0xFF;
        
        $payload->[0] = ( scalar @$payload ) -1;
        
        $self->crypt_buffer;
        
        return 1;
    } catch {
        die $_;
        $self->push_error(q(unexpected error in message encode ) . $_);
        return 0;
    };
    $self->is_encoded(1);
    $self->ok( $result );
}


sub inspect_buffer {
    my $self = shift;
    my $result = try {
        
        # check basic message length
        {
            my $bytelength = $self->buffer_length;
            
            if ( ( $bytelength < 11 )
                || ( $self->databuffer->[0] + 1 != $bytelength ) ) {
                $self->push_error(q(invalid message length ) . $bytelength);
                return 0;
            }
        }
        
        $self->_mid( $self->databuffer->[1] );
        $self->_pid( $self->databuffer->[2] );
        $self->_pip( ( $self->databuffer->[3] << 8 ) + $self->databuffer->[4] );
        
        return 1;
        
    } catch {
        return 0;
    };
    
    return $result;
}

sub decode_buffer {
    my $self = shift;
    my $result = try {
        
        # clear records
        $self->records([]);
        
        # check basic message length
        {
            my $bytelength = $self->buffer_length;
            
            if ( ( $bytelength < 11 )
                || ( $self->databuffer->[0] + 1 != $bytelength ) ) {
                $self->push_error(q(invalid message length ) . $bytelength);
                return 0;
            }
        }
        
        my $payload = $self->databuffer;
        
        $self->_mid( $payload->[1] );
        $self->_pid( $payload->[2] );
        $self->_pip( ( $payload->[3] << 8 ) + $payload->[4] );
        
        # new we have the manufacturer and product id we can optionally
        # decrypt the message
        
        $self->crypt_buffer;
        
        $self->_sid( ( $payload->[5] << 16 ) + ( $payload->[6] << 8 ) + $payload->[7] );
        
        # check CRC to see if this is good message
        my $crc_sent  = ( $payload->[-2] << 8 ) + $payload->[-1];
        my $crc_calculated= $self->calculate_crc;
        if ( $crc_sent != $crc_calculated ) {
            $self->push_error(qq(invalid CRC - got $crc_sent, expected $crc_calculated));
            return 0;
        }
        
        # decode the records
        
        my $index = 8;
        my @records;
        while ( ( $index  < @$payload -2 ) && $payload->[$index] != 0 ) {
            my $param = $payload->[$index];
            my $command = (( $param & OPENTHINGS_WRITE_MASK ) == OPENTHINGS_WRITE_MASK ) ? 1 : 0;
		    my $paramid = $param & 0x7F;
            my ( $paramname, $paramunit ) = HiPi::RF::OpenThings->parameter_map( $paramid );
            $index ++;
            my $typeid = $payload->[$index] & 0xF0;
            my $paramlen = $payload->[$index] & 0x0F;
            $index ++;
            
            my $record = {
                command => $command,
                id      => $paramid,
                name    => $paramname,
                units   => $paramunit,
                typeid  => $typeid,
                length  => $paramlen,
                value   => '',
                bytes   => [],
            };
            
            if ( $paramlen != 0 ) {
                my @valuebytes = ();
                for (my $i = 0; $i < $paramlen; $i++ ) {
                    push @valuebytes, $payload->[$index];
                    $index ++;
                }
                
                if ( $paramlen != @valuebytes ) {
                    $self->push_error('length of bytes for param incorrect');
                    return 0;
                }
                
                
                my $value = $self->decode_value($typeid, \@valuebytes );
                $record->{value} = $value;
                $record->{bytes} = \@valuebytes;
            }
            
            # get some convenience values
            
            $self->has_command(1) if $record->{command};
            
            if( $record->{id} == OPENTHINGS_PARAM_JOIN  ) {
                if( $record->{command} ) {
                    $self->has_join_cmd(1);
                } else {
                    $self->has_join_ack(1);
                }
            }
            
            if( $record->{id} == OPENTHINGS_PARAM_SWITCH_STATE  ) {
                if(defined($record->{value}) && $record->{value} ne '' ) {
                    $self->switch_state( $record->{value} );
                    if( $record->{command} ) {
                        $self->switch_command(1);
                    }
                }
            }
            
            push @records, $record;   
        }
    
        for my $record ( @records ) {
            $self->add_record(%$record);
        }
        return 1;
    } catch {
        $self->push_error(q(unexpected error in message decode ) . $_);
        return 0;
    };
    
    $self->is_decoded(1);
    $self->ok( $result );
}

sub get_value_type_bits {
    my($self, $typeid) = @_;
    
    my $rval = 1;
    
    if ($typeid == OPENTHINGS_UINT_BP4 ) {
        $rval = 4;
    } elsif($typeid == OPENTHINGS_UINT_BP8 ) {
        $rval = 8;
    } elsif($typeid == OPENTHINGS_UINT_BP12 ) {
        $rval = 12;
    } elsif($typeid == OPENTHINGS_UINT_BP16 ) {
        $rval = 16;
    } elsif($typeid == OPENTHINGS_UINT_BP20 ) {
        $rval = 20;
    } elsif($typeid == OPENTHINGS_UINT_BP24 ) {
        $rval = 24;
    } elsif($typeid == OPENTHINGS_SINT_BP8 ) {
        $rval = 8;
    } elsif($typeid == OPENTHINGS_SINT_BP16 ) {
        $rval = 16;
    } elsif($typeid == OPENTHINGS_SINT_BP24 ) {
        $rval = 24;
    }
    return $rval;    
}

sub get_value_bits {
    my($self, $value) = @_;
    return 2 if $value == -1;
	# Turn into  2's
	my $maxbytes = 15;
	my $maxbits = 1 << ( $maxbytes * 8 );
	$value = $value & $maxbits -1;
	
    my $bits = 2 + $self->get_highest_clear_bit($value, $maxbytes * 8 );
    
    return $bits;
}

sub get_highest_clear_bit {
    my($self, $value, $maxbits) = @_;
    
    my $mask = 1 << ( $maxbits -1 );
	my $bitno = $maxbits - 1;
	while( $mask != 0 ) {
        last if( ($value & $mask) == 0);
        $mask >>= 1;
		$bitno -= 1;
    }
	return $bitno;
}

sub decode_value {
    my($self, $typeid, $bytes) = @_;
    
    my $numbytes = scalar @$bytes;
    return undef unless $numbytes;
    
    if ( $typeid <= OPENTHINGS_UINT_BP24 ) {
		my $result = 0;
		# decode unsigned integer first
		for (my $i = 0; $i < @$bytes; $i++) {
			$result <<= 8;
			$result += $bytes->[$i];
        }
        
		# process any fixed binary points
		if( $typeid == OPENTHINGS_UINT ) {
            return $result; # no BP adjustment
        } else {
            return $result / ( 2 ** $self->get_value_type_bits( $typeid ) );
        }
    } elsif( $typeid == OPENTHINGS_CHAR ) {
        my $format = 'C*';
        my $result = pack($format, @$bytes);
        return $result;
    } elsif( $typeid >= OPENTHINGS_SINT && $typeid <= OPENTHINGS_SINT_BP24 ) {     
        # decode unsigned int first
		
        my $result = 0;
        
		for (my $i = 0; $i < @$bytes; $i++) {
			$result <<= 8;
			$result += $bytes->[$i];
        }
        
		# turn to signed int based on high bit of MSB
		# 2's comp is 1's comp plus 1
		if(($bytes->[0] & 0x80) == 0x80) {
            $result = - HiPi->twos_compliment( $result, $numbytes );
        }
		# adjust for binary point
		if( $typeid == OPENTHINGS_SINT ) {
			return $result; # no BP, return as int
        } else {
            return $result / ( 2 ** $self->get_value_type_bits( $typeid ) );
        }
        
        
    } elsif( $typeid == OPENTHINGS_FLOAT ) {
        return "TODO_FLOAT_IEEE_754-2008";
    }
       
    return 0;
}

sub encode_value {
    my($self, $typeid, $value ) = @_;
    
    my @result = ();
    my @emptyresult = ();
        
    if( $typeid == OPENTHINGS_CHAR ) {
        unless(defined($value) && $value ne '' ) {
            return @emptyresult;
        }
        @result = unpack('C*', $value );

    } elsif( $typeid == OPENTHINGS_FLOAT ) {
        warn "TODO_FLOAT_IEEE_754-2008";
        return @emptyresult;
        
    } elsif ( $typeid <= OPENTHINGS_SINT_BP24 ) {
        # signed and unsigned integers can be packed the same
        if ( ( $typeid != OPENTHINGS_UINT ) && ( $typeid != OPENTHINGS_SINT ) ) {
			# pre-adjust for BP
            $value *= ( 2 ** $self->get_value_type_bits( $typeid ) ); # shifts float into int range using BP
            $value = int($value);   
        }
        
        my $v = $value;
        unshift(@result, $v & 0xFF );
        $v >>= 8;
        
        while( $v != 0.0 ) {
            unshift(@result, $v & 0xFF );
            $v >>= 8;
        }
    }
    
    return @result;
}

sub crypt_buffer {
    my $self = shift;
    return unless $self->cryptseed;
    my $payload = $self->databuffer;
    my $pip = ( $payload->[3] << 8 ) + $payload->[4];
    return unless $pip;
    my $pid = $self->cryptseed;
    my $block = ( ( ($pid & 0xFF ) << 8 ) ^ $pip ) & 0xFFFF;
    
    for ( my $byte = 5; $byte < @$payload; $byte ++ ) {
        for (my $i = 0; $i < 5; $i ++ )	{
            $block = ( $block & 1 ) ? (($block >> 1) ^ 0xF5F5 ) & 0xFFFF : ($block >> 1);
        }
        $payload->[$byte] = ( $block ^  $payload->[$byte] ^ 0x5A ) & 0xFF;
    }   
}

sub calculate_crc {
    my ( $self, $nocrcbytes ) = @_;
    
    my $skipbytes = ( $nocrcbytes ) ? 0 : 2;
    
    my $payload = $self->databuffer;
    
    # calculate from 5th byte (start of encrypt pip excluding the two crc bytes at the end if specified)
    my $crc = 0;
    for ( my $i = 5; $i < @$payload - $skipbytes; $i ++ ) {
        my $byte = $payload->[$i];
		$crc ^= ( $byte << 8 );
        for ( my $bit = 0; $bit < 8; $bit ++ ) {
            if( ( $crc & ( 1 <<15 ) ) != 0 ) {
				# bit is set
				$crc = (( $crc << 1) ^ 0x1021) & 0xFFFF;
            } else {
				# bit is clear
				$crc = ( $crc << 1 ) & 0xFFFF;
            }
        }
    }
    
	return $crc;
}

sub buffer_length {
    my $self = shift;
    my $val = scalar @{ $self->databuffer };
    return $val;
}

sub push_error {
    my( $self, $error) = @_;
    
    if ( $error ) {
       push( @{ $self->errorbuffer }, $error );
    }
    return;
}

sub error {
    my $self = shift;
    return scalar @{ $self->errorbuffer };
}

sub shift_error {
    my $self = shift;
    my $rval = shift @{ $self->errorbuffer };
    return $rval;
}

sub add_record {
    my($self, %params) = @_;
    my $record = HiPi::RF::OpenThings::Message::Record->new( %params );
    push @{ $self->records }, $record;
    return;
}

sub timestamp {
    my($self) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime( $self->epoch );
    my $timestamp = sprintf('%u-%02u-%02u %02u:%02u:%02u',
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec      
    );
    return $timestamp;
}

sub round_value {
    my( $self, $value ) = @_;
    if($value == 0) {
        return 0;
    } elsif( $value == int($value) ) {
        return $value;
    } else {
        return sprintf(qq(%.0f), $value );
    }   
}

#########################################################################################

package HiPi::RF::OpenThings::Message::Record;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Class );

__PACKAGE__->create_accessors( qw( command id name units typeid length value bytes ) );

sub new {
    my ( $class, %params ) = @_;
    
    my $self = $class->SUPER::new( %params );
    
    unless($self->name && $self->units) {
        my ( $name, $units ) = HiPi::RF::OpenThings->parameter_map( $self->id );
        unless( $self->name ) {
            $self->name( $name );
        }
        unless( $self->units ) {
            $self->units( $units );
        }
    }
    
    return $self;
}

1;

__END__