package Server::Base;

use Moo;
use IO::Handle;

has capabilities => (
   is => 'lazy',
);

sub _build_capabilities { return {} }

has encoding => (
   is => 'rw',
   predicate => 1,
   clearer => 1,
   default => sub { 'utf-8' }
);

sub read {

    my ( $self, $size ) = ( shift, shift );

    my $buf;

    if ( $size ) {

	my $r = STDIN->read( @_ ? $_[-1] : $buf, $size );
	croak( "EOF\n" ) unless defined $r && $size == $r;

    }

    else {

	( @_ ? $_[-1] : $buf ) = '';

    }

    return $buf unless @_;
    return;
}

sub read_chunk {

    my $self = shift;

    my $buf;

    $self->read( 4, $buf );

    my $len = unpack( 'N', $buf );

    return $self->read( $len, @_ );
}

sub write_chunk {

    my $self = shift;

    # my ( $channel, $data ) = @_;

    STDOUT->syswrite( pack( 'A[1] N/A*', @_ ) );
}


sub say_hello {

    my $self = shift;

    my @capabilities = keys %{ $self->capabilities };

    $self->write_chunk( 'o',
			 join( "\n",
			       @capabilities ? (join( ' ', 'capabilities:', @capabilities )) : (),
			       $self->has_encoding ? 'encoding: ' . $self->encoding : (),
			     )
		       );
}

sub serve {

    my $self = shift;

    $self->say_hello;

    while( my $cmd = STDIN->getline ) {

	chomp $cmd;

	my $handler = $self->capabilities->{$cmd};

	if ( $handler ) {

	    $handler->handle( $cmd, $self )

	}
	else {

	    croak( "unknown command: $cmd\n" );

	}

    }

}

sub DEMOLISH { }


package Server::Capability::GetEncoding;

use Moo::Role;

around '_build_capabilities' => sub {

    my ( $orig, $self ) = ( shift, shift );

    my $capabilities = $orig->( $self, @_ );

    $capabilities->{getencoding} = sub { $self->encoding };

    return $capabilities

};


package Server::Capability::RunCommand;

use Moo::Role;

has dispatch => (

   is => 'lazy'

);

sub _build_dispatch { return {} };

around '_build_capabilities' => sub {

    my ( $orig, $self ) = ( shift, shift );

    my $capabilities = $orig->( $self, @_ );

    $capabilities->{runcommand} = sub { $self->runcommand( @_ ) };

    return $capabilities

};

sub runcommand {

    my $self = shift;

    my ( $cmd, @args ) = split( "\0", $self->read_chunk );

    my $mth = $self->dispatch->{ $cmd };

    croak( "unknown command: $cmd\n" )
      if ! defined $mth;

    $mth->( $self, $cmd, @args );
}

package Server;

use Moo;

extends 'Server::Base';

with 'Server::Capability::GetEncoding', 'Server::Capability::RunCommand';

1;
