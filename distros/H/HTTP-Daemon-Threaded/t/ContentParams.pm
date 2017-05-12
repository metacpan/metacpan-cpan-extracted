package ContentParams;

use threads;
use threads::shared;
use HTTP::Daemon::Threaded::ContentParams;
use base qw(HTTP::Daemon::Threaded::ContentParams);

sub new {
	my ($class, %args) = @_;

	my %self : shared = ( DocRoot => $args{DocRoot} );
	return bless \%self, $class;
}

sub docroot { return $_[0]->{DocRoot}; }

1;

