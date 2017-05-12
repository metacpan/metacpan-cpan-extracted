package Logfile::EPrints::Filter::RobotsTxt;

=head1 NAME

Logfile::EPrints::Filter::RobotsTxt - Filter Web log hits using a database of robot's IPs

=head1 OPTIONS

=over 4

=item file

Specify the robots DBM file to use.

=back

=cut

require bytes;
use Fcntl;
use SDBM_File;

use constant BOT_CACHE => '/usr/local/share/Logfile/botcache.db';
use constant CACHE_TIMEOUT => 60*60*24*30; # 30 days
use vars qw( $AUTOLOAD );

sub new
{
	my ($class,%args) = @_;
	my $self = bless \%args, ref($class) || $class;
	my $filename = $args{'file'} || BOT_CACHE;
	tie %{$self->{cache}}, 'SDBM_File', $filename, O_CREAT|O_RDWR, 0644
		or die "Unable to open robots cache database at $filename: $!";
	my @KEYS;
	while( my ($key, $value) = each %{$self->{cache}} )
	{
		my ($utime,$agent) = unpack("la*", $value);
		push @KEYS, $key if( $utime < time - CACHE_TIMEOUT );
	}
	delete $self->{cache}->{$_} for @KEYS;
	$self;
}

sub DESTROY
{
	my $self = shift;
	untie %{$self->{cache}};
}

sub AUTOLOAD
{
	$AUTOLOAD =~ s/^.*:://;
	return if $AUTOLOAD =~ /[A-Z]$/;
	my ($self,$hit) = @_;
	if( defined($hit->page) && $hit->page =~ /robots\.txt$/ )
	{
		$self->robotstxt($hit);
		return undef;
	}
	if( defined(my $value = $self->{cache}->{$hit->address}) )
	{
		#warn "Ignoring hit from " . $hit->address . " (" . $self->{cache}->{$hit->address} . ")";
		my( $utime ) = unpack("l",$value);
		if( $utime > CACHE_TIMEOUT )
		{
			delete $self->{cache}->{$hit->address};
		}
		else
		{
			return undef;
		}
	}

	return $self->{handler}->$AUTOLOAD($hit);
}

sub robotstxt
{
	my ($self,$hit) = @_;
	#warn "Got new robot: " . join(',',$hit->address,$hit->utime,$hit->agent) . "\n";
	# SDBM_File format only supports upto 1008 bytes
	$self->{cache}->{$hit->address} = bytes::substr(pack("la*",$hit->utime,$hit->agent||''),0,1008);
}

1;
