our $DEBUG = 1;
our $VERBOSE = 0;
our $VERSION = '0.1';
our $HELP = '';
our $MAN = '';

our $dict =
{
	debug           => { type => 'integer', default => \$DEBUG },
	help		    => { type => 'code', code => sub{ $HELP = pod2usage(1); }, alias => '?', action => 1 },
	man			    => { type => 'code', code => sub{ $MAN = pod2usage(2); }, action => 1 },
	quiet		    => { type => 'boolean', default => 0, alias => 'silent' },
	verbose		    => { type => 'boolean', default => \$VERBOSE, alias => 'v' },
	version         => { type => 'code', code => sub{ sprintf( "v%.2f", $VERSION ); }, action => 1 },
	
	api_server	    => { type => 'string', default => 'api.example.com' },
	api_version	    => { type => 'string', default => 1 },
	as_admin	    => { type => 'boolean' },
	dry_run		    => { type => 'boolean', default => 0 },
	without_zlib    => { type => 'boolean', default => 1 },
	enable_compress => { type => 'boolean', default => 1 },
	disable_logging => { type => 'boolean', default => 1 },
	
	name            => { type => 'string', class => [qw( person product )] },
	created         => { type => 'datetime', class => [qw( person product )] },
	define		    => { type => 'string-hash', default => {} },
	langs	        => { type => 'array', class => [qw( person product )], re => qr/^[a-z]{2}([_|-][A-Z]{2})?/, min => 1, default => [] },
	currency		=> { type => 'string', class => [qw(product)], name => 'currency', re => qr/^[a-z]{3}$/, error => "must be a three-letter iso 4217 value" },
	age             => { type => 'integer', class => [qw(person)], name => 'age', },
};

sub pod2usage
{
    my $flag = shift( @_ );
    if( $flag == 1 )
    {
        return( "pod2usage help" );
    }
    elsif( $flag == 2 )
    {
        return( "pod2usage man" );
    }
}

1;

