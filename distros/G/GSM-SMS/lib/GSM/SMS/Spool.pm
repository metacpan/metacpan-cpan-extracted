package GSM::SMS::Spool;
use strict;
use vars qw( $VERSION );

use Carp;
use Log::Agent;
use File::Spec;

=head1 NAME

GSM::SMS::Spool

=head1 DESCRIPTION

Implements a simple filesystem spool mechanism to temporarily store incoming and outgoing SMS messages.

=cut

$VERSION = '0.2';

=head1 METHODS

=over 4

=item B<new> - Constructor

=cut

sub new {
	my ($proto, %arg) = @_;

	my $class = ref($proto) || $proto;

	my $self = {
			_spool_dir => $arg{-spool_dir}	|| croak "No spool directory defined"
	};

	bless $self, $class;

	return $self;
}

=item B<get_spool_dir> - get the spool directory

=cut

sub get_spool_dir { return $_[0]->{_spool_dir} }

=item B<add_to_spool> - Add a pdu for a msisdn to the spool.

  $spool->add_to_spool( $msisdn, $pdu );

=cut

sub add_to_spool {
	my ($self, $msisdn, $pdu) = @_;
	local (*F);


	my $dir = $self->get_spool_dir;

	my $filename = $self->create_spoolname($msisdn, $pdu);

	logdbg "debug", "Adding [$msisdn;$pdu] to spool as $filename";

	my $file = File::Spec->catfile( $dir, $filename );
	open F, ">$file";
	print F $pdu;
	close F;

	return $filename;
}

=item B<remove_from_spool> - Delete a file from the spool

  $spool->remove_from_spool( $file );

=cut

sub remove_from_spool {
	my ($self, $file) = @_;

	my $dir = $self->get_spool_dir;

	logdbg "debug", "Removing $file from spool";

	logwarn "Could not delete spoolfile ($file)." unless 
		unlink( File::Spec->catfile($dir, $file) );
}

=item B<read_from_spool> - Read n files from the spool.

  @spool = $spool->read_from_spool( $n );

  $msisdn 	= $spool[0]->{'msisdn'};
  $pdu    	= $spool[0]->{'pdu'};
  $filename   = $spool[0]->{'file'};

=cut

sub read_from_spool {
	my	($self, $n) = @_;
	local (*DIR);
	my ($file, $count, @arr);

	my $dir = $self->get_spool_dir;

	# return array with $n==0:<all>:$n messages from spooldir
	$count = 0;
	opendir(DIR, $dir) or logcroak "Could not read directory $dir ($!)";
	while ( defined($file = readdir(DIR)) && ( ($n && $count<$n) || !$n) ) {
		next if $file =~ /^\.\.?$/;
		$count++;
		if ($file =~ /(.+?)_.+/) {
			my $msisdn = $1;
			# contents of file
			local (*F);
			open F, $dir . "/" . $file;
			undef $/;
			my $contents = <F>;
			close F;
			my $msg = {};
			$msg->{'msisdn'} = $msisdn;
			$msg->{'pdu'} = $contents;
			$msg->{'file'} = $file;
			push(@arr, $msg);
			logdbg "debug", "Read from spool - $file:=[$msisdn;$contents]";
		}
	}
	closedir(DIR);
	return @arr;
}

=item B<create_spoolname> - Create a filename for a spool object.

  my $name = $spool->create_spoolname( $msisdn, $pdu );

=cut

sub create_spoolname {
	my ($self, $msisdn, $pdu) = @_;
	
	$msisdn =~ s/^\+//;
	my $filename = $msisdn . "_" . $$ . time . substr($pdu,-32);

	logdbg "debug", "Created spoolname [$filename]";
	
	return $filename;
}


1;

=back

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
