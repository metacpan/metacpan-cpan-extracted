package Mendoza;

use McBain;

get '/' => (
	description => 'Returns the name of the API',
	cb => sub {
		return 'MEN-DO-ZAAAAAAAAAAAAA!!!!!!!!!!!';
	}
);

get '/status' => (
	description => 'Returns the status of the API',
	cb => sub { shift->status }
);

sub new { bless { status => 'ALL IS WELL' }, shift };

sub status { shift->{status} }

1;
__END__
