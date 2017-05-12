package GSM::SMS::Transport::File;

=head1 NAME

GSM::SMS::Transport::File - Dump PDU strings to files

=head1 DESCRIPTION

Dump PDU strings to a file. Can be used as a debugging means, to catch PDU
messages or used with a pickup daemon that reads outgoing messages from
a directory.

All outgoing SMS messages are dumped in a unique file in a specified directory.

=cut

use strict;
use vars qw( $VERSION $AUTOLOAD );

use base qw( GSM::SMS::Transport::Transport );

use Carp;
use Log::Agent;
use File::Temp qw( tempfile );

$VERSION = '0.2';

{
	my %_attrs = (
		_name				=> 'read',
		_match				=> 'read/write',
		_out_directory		=> 'read/write'
	);

	sub _accessible
	{
		my ($self, $attr, $mode) = @_;
		$_attrs{$attr} =~ /$mode/
	}
}

=head1 METHODS

=over 4

=item B<new> - Constructor

  my $tfile = GSMS::SMS::Transport::File->new(
    -name => $name_of_transport,
    -match => $matching_regex_for_allowed_msisdn,
    -out_directory => $file_to_dump_PDU_to
  );

=cut  

sub new {
	my ($proto, %args) = @_;
	my $class = ref($proto) || $proto;

	logdbg "debug", "$class constructor called";

	my $self = $class->SUPER::new(%args);

	$self->{_out_directory} = $args{-out_directory} 
		|| croak( "missing out_directory");

	bless $self, $class;
	
	logdbg "debug", "GSM::SMS::Transport::File started";
	
	return $self;
} 

=item B<send> - Send a PDU message
    
	
=cut

sub send {
	my($self, $msisdn, $p) = @_;

	chomp($p);
	
	my ($fh, $filename) = tempfile( DIR => $self->get_out_directory() );

	logdbg "debug", "Saving message in $filename";
	
	print $fh "$msisdn|$p\n";
	close $fh;

	return 0;
}

=item B<receive> - Receive a PDU encoded message
    
	
=cut

sub receive {
	my ($self, $pduref) = @_;

	return -1;
}

=item B<init> - Initialise transport
    
	
=cut

sub init {
	my ($self, $config) = @_;

	return 0;
}

=item B<close> - Close the transport 
    
	
=cut

sub close {
	my ($self) =@_;
}

=item B<ping > -  A ping command ... just return an informative string 
    
	
=cut

sub ping {
	my ($self) = @_;

	return "OK";
}

=item B<get_info> - Give some info about this transport
    
	
=cut

sub get_info {
	my ($self) = @_;

	my $revision = '$Revision: 1.1.1.1 $';
	my $date = '$Date: 2002/10/15 20:53:38 $';

print <<EOT;
File transport $VERSION

Revision: $revision

Date: $date

EOT
}

=back

=cut
1;

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
