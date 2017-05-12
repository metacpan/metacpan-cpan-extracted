package HTML::Pen::Utils ;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Contessa::Demo ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => 
		[ qw( split memstat mymkdir imagefile randomize ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.01';


sub mysplit {
	my $pat = shift ;
	my $t = shift ;
	return ( $t ) if ref $t eq 'SCALAR' ;
	return () if ref $t ;

	my @rv ;
	while ( $t =~ s/^(.*?)($pat)//s ) { ;
		my @o = ( $1, $2 ) ;
		push @rv, $o[0], \( $o[1] ) ;
		} ;
	push @rv, $t ;
	return @rv ;
	}

sub split {
	my $t = shift @_ ;
	my @rv ;

	while ( @_ ) {
		if ( @rv ) {
			my $p = shift @_ ;
			@rv = map { mysplit( $p, $_ ) } @rv ;
			}
		else {
			@rv = mysplit( shift @_, $t ) ;
			}
		}

	return map { ref $_? $$_: $_ } @rv ;
	}

sub memstat { 
	if( ! open( _INFO, "< /proc/$$/statm" ) ) { 
		warn "Couldn't open /proc/$$/statm [$!]" ;
		return {} ;
	 	} 

	my @info = split( /\s+/, <_INFO> ) ;
	close( _INFO ) ;
	return { size => $info[0] * 4, 
			resident => $info[1] * 4, 
			shared => $info[2] * 4 } ;
	}

## utility
sub mymkdir {
	my $dir = shift ;
	mkdir $dir unless -d $dir ;
	return unless scalar @_ ;

	my $next = shift ;
	return mymkdir( join( '/', $dir, $next ), @_ ) ;
	}

sub imagefile {
	my $fn = shift ;
	my $buff = shift ;

	$fn =~ s|^/|| ;
	my @fn = split m|/|, $fn ;
	pop @fn ;
	mymkdir( @fn ) ;

	open $f, "> $fn" ;
	print $f $buff ;
	close $f ;
	}

sub randomize {
#	srand() ;

	my @p = @_ ;
	my @rv = () ;
	push @rv, splice @p, int( rand( scalar @p ) ), 1 while @p ;
	return @rv ;
	}

1
__END__
my best parser yet. (10/2003)

@s = Pen::Utils::split( $t, '\[.*?\]', '".*?"', '\s+' ) ;

The above protects quoted spaces and text enclosed in brackets.  Note, all 
elements are returned.  So filter out separators as follows:

print join "\n", grep /\S/, @s ;

