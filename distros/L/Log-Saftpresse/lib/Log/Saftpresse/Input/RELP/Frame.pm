package Log::Saftpresse::Input::RELP::Frame;

use Moose;

our $VERSION = '1.6'; # VERSION
# ABSTRACT: class for parsing and generating RELP frames

has 'txnr' => ( is => 'rw', isa => 'Int', required => 1 );
has 'command' => ( is => 'rw', isa => 'Str', required => 1 );
has 'data' => ( is => 'rw', isa => 'Str', default => '',
	traits => [ 'String' ],
	handles => {
		data_len => 'length',
	},
);

sub as_string {
	my $self = shift;
	return join(' ', $self->txnr, $self->command, $self->data_len,
		$self->data_len ? $self->data : () )."\n";
}

sub new_next_frame {
	my ( $class, $prev ) = ( shift, shift );
	my $obj = $class->new(
                'txnr' => $prev->txnr,
                @_
        );
        return $obj;
}

sub new_from_fh {
	my ( $class, $fh ) = ( shift, shift );

	local $/ = ' ';

	my $txnr = $fh->getline;
	if( ! defined $txnr ) {
		return; # no more data?
	}
	if( $txnr !~ /^\d+ $/) {
		die('invalid txnr in RELP frame: '.$txnr);
	}
	chomp( $txnr );

	my $command = $fh->getline;
	if( ! defined $command || $command !~ /^[a-zA-Z]+ $/) {
		die('invalid command in RELP frame: '.$command);
	}
	chomp( $command );

	my $digit;
	my $data;
	if( !  $fh->read( $digit, 1 ) ) {
		die('error reading data_len');
	}
	if( $digit !~ /\d/ ) {
		die('data_len in RELP is not numeric!');
	}
	if( $digit eq '0' ) {
		$data = '';
	} else {
		my $left_data_len = $fh->getline;
		if( ! defined $left_data_len ) {
			die('error reading more digits of data_len');
		}
		chomp( $left_data_len );
		my $data_len = int( $digit . $left_data_len );
		if( ! $data_len || $data_len > 131072 ) { # 128k
			die('invalid data_len in RELP frame');
		}
		$fh->read( $data, $data_len );
	}
	my $trailer;
	$fh->read( $trailer, 1 );
	if( ! defined $trailer || $trailer ne "\n" ) {
		die('no trailer (LF) present. possible framing error.');
	}

	my $obj = $class->new(
    'txnr' => $txnr,
    'command' => $command,
    'data' => $data,
    @_
  );
  return $obj;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Input::RELP::Frame - class for parsing and generating RELP frames

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
