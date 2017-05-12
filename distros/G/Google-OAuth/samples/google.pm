use Google::OAuth ;
use XML::Parser::Nodes ;
use NoSQL::PL2SQL::Simple ;
use NoSQL::PL2SQL::DBI::MySQL ;
use dates ;
use multihash ;

package dates ;

sub asgoogle {
	my $package = $_[0] eq __PACKAGE__? shift @_: undef ;
	my $googledate = shift ;
	my @gd = split /\D/, $googledate ;
	my $midnight = dates->dateinput( 
			$dates::months[ $gd[1] -1 ], $gd[2], $gd[0] 
			)->tomorrow ;
	
	my $when = $midnight -$dates::day +$gd[3] *$dates::hour 
			+$gd[4] *$dates::minute +$gd[5] ;
	return $package? dates->new( $when ): $when ;
	}

sub google {
	my $d = shift ;
	my @d = @$d{ qw( year monthno monthday ) } ;
	$d[1] +=1 ;
	my $out = join '-', map { sprintf '%02d', $_ } @d ;
	$out .= 'T' .$d->{time} ;
	my @tz = $d->timezone ;
	$out .= sprintf '%03d:%02d', @tz[1,2] ;
#	$out .= sprintf '%03d:%02dZ', @tz[1,2] ;
	return $out ;
	}


package Google::Client ;

sub new {
	my $package = shift ;
	my $token = shift ;
	my @args = $package->url( $token ) ;
	unshift @args, 'GET' if @args < 2 ;
	return bless $token->content( @args ), $package ;
	}


package Google::Contacts ;
@Google::Contacts::ISA = qw( Google::OAuth::Request ) ;

sub new {					## returns xml
	my $package = shift ;
	my $token = shift ;
	my $self = bless { token => $token }, $package ;
	return new XML::Parser::Nodes 
			$self->response( GET => $self->url )->content ;
	}

sub url {
	my $self = shift ;

	my $url = join '/', 'https://www.google.com',
			'm8/feeds/contacts', 
			Google::OAuth::CGI->encode( 
			  $self->{token}->{emailkey} ),
			'full' ;
	return $url ;
	}

sub headers {
	my $self = shift ;

	my @headers = ( 'Content-Type' 
			=> 'application/atom+xml; charset=UTF-8; type=feed',
			'GData-Version' => '3.0',
			) ;
	my $token = sprintf 'AuthSub token="%s"', 
			$self->{token}->{access_token} ;
	return ( @headers, Authorization => $token ) ;
	}


package Google::Calendar ;
@Google::Calendar::ISA = qw( Google::Client ) ;

use Date::Parse qw( str2time ) ;

sub items {
	my $self = shift ;
	my @items = map { [ dates->new( 
			  str2time( $_->{start}->{dateTime} ) ) => $_ ]
			} @{ $self->{items} } ;
	my %items = () ;

	foreach ( @items ) {
		my $k = $_->[0]->{midnight} ;
		$items{$k} ||= [] ;
		push @{ $items{$k} }, $_ ;
		}

	return map { $items{$_} } sort { $a <=> $b } keys %items ;
	}

sub url {
	my $package = shift ;
	my $token = shift ;
	my @args = @_ ;
	my @parms = () ;
	push @parms, [ singleEvents => 'true' ] ;
	push @parms, [ orderBy => 'startTime' ] ;

	## for bucc calendar
	push @parms, [ timeMin => &sunday ] ;
	
	push @parms, [ splice @args, 0, 2 ] while @args ;

	my $url = join '/', 'https://www.googleapis.com',
			'calendar/v3/calendars',
			Google::OAuth::CGI->encode( $token->{emailkey} ), 
			'events' ;
	return $url unless @parms ;

	return join '?', $url, join '&', map { join '=', 
			$_->[0] => Google::OAuth::CGI->encode( $_->[1] ) 
			} @parms ;
	} 

sub sunday {
	return dates->sunday( dates->new )->google ;
	return dates->tomorrow( 
			dates->sunday( dates->new )
			)->google ;
	}


package Google::Drive ;
@Google::Drive::ISA = qw( 
		NoSQL::PL2SQL::Simple 
		Google::Client 
		) ;

my @dsn = () ;                                ## Do not change this line
our $foldertype = 'application/vnd.google-apps.folder' ;

sub new {
	return Google::Client::new( @_ ) ;
	}

sub build {
	my $package = shift ;
	my $db = $package->db ;
	$db->addTextIndex( qw( etag parent id title about ) ) ;
	}

## data source subclasses override this dsn() method
sub dsn {
	return @dsn if @dsn ;                   ## Do not change this line

	push @dsn, new NoSQL::PL2SQL::DBI::MySQL 'DriveData' ;
	$dsn[0]->mysql ;

	push @dsn, $dsn[0]->table('DriveQueryData') ;
	return @dsn ;                           ## Do not change this line
	}

sub root {
	my $package = shift ;
	my $token = shift ;

	return join '/', 'https://www.googleapis.com/drive/v2', @_ ;
	}

sub url {
	my $package = shift ;
	my $token = shift ;

	my @args = @_ ;
	push @args, '?maxResults=200' unless @args ;
	return join '/', 'https://www.googleapis.com/drive/v2/files', @args ;
	}

## an alternative URL
sub upload {
	my $package = shift ;
	my $token = shift ;

	return join '/', 'https://www.googleapis.com/upload/drive/v2/files', 
			@_ ;
	}

## same as new() with one argument
sub download {
	my $package = shift ;
	my $token = shift ;

	my $o = $token->content( GET => $package->url( $token, @_ ) ) ;
	return $o->{downloadUrl}?
			$token->content( GET => $o->{downloadUrl} ): $o ;
	}

sub about {
	## See CAVEATS in NoSQL::PL2SQL::Simple

	my $self = shift ;
	$self = $self->db unless ref $self ;
	my $token = shift or return warn 'requires token' ;

	my @out = () ;
	my $o = $token->content( GET => root( '', '', 'about' ) ) ;
	map { delete $o->{$_} } qw( additionalRoleInfo
			user importFormats exportFormats maxUploadSizes ) ;

	my $ekey = $token->{emailkey} ;
	my @r = $self->query( about => $ekey )->records ;

	if ( @r ) {
		my $r = $self->record( $r[0]{record} ) ;
		@out = ( $r->{largestChangeId} .. $o->{largestChangeId} ) ;
		$r->save( $o ) ;
		}
	else {
		my $r = $self->save( $o ) ;
		$self->save( {
				about => $ekey,
				record => $r->SQLObjectID
				} ) ;
		}

	return @out ;
	}

sub update {
	my $self = shift ;
	$self = $self->db unless ref $self ;
	my $token = shift or return warn 'requires token' ;

	my @changes = $self->about( $token ) ;
	shift @changes ;		##rerun
	push @changes, @_ ;

	my @updates = grep $_->{file},
			map { $token->content( GET => $_ ) }
			map { $self->root( $token, changes => $_ ) } 
			@changes ;

	foreach my $o ( @updates ) {
		$o->{file}->{parent} = $o->{file}->{parents}->[0]->{id} ;

		my @ok = $self->id( $o->{file}->{id} )->records ;

		if ( $o->{deleted} ) {
			$ok[0]->delete if @ok ;
			}
		elsif ( @ok == 0 ) {
			$self->save( $o->{file} ) ;
			}
		else {
			$ok[0]->save( $o->{file} ) ;
			}
		}

	return scalar @updates ;
	}

## Deprecated in favor of update()
##
sub reload {
	my $self = shift ;
	my $token = shift or return warn 'requires token' ;
	$self = $self->db unless ref $self ;

	my $m = new multihash ;
	my %etag = reverse $self->etag ;
	my @items = @{ Google::Drive->new( $token )->{items} } ;
	my %ok = map { $_->{etag} => 1 } @items ;

	map { $ok{$_}-- } keys %etag ;
	map { $m->{ $ok{$_} } = $_ } ## +1 new ; 0 existing ; -1 deleted
			keys %ok ;	

	map { $self->delete( $_ ) }
			map { $self->etag( $_ ) }
			@{ $m->{-1} || [] } ;			## delete
	map { $self->save( $_ ) } 
			map { $_->{parent} = $_->{parents}->[0]->{id} ; $_ }
			grep $ok{ $_->{etag} } == 1, @items ;	## insert

	return $m ;
	}

package Google::TQIS ;

sub token {
	return Google::OAuth->token('tqisjim@gmail.com') ;
	}


package Google::GPRC ;
push @Google::GPRC::ISA, qw( Google::TQIS ) ;

sub token {
	return Google::OAuth->token('gpannarbor@gmail.com') ;
	}


package Google::BUCC ;
push @Google::BUCC::ISA, qw( Google::TQIS ) ;

sub token {
	return Google::OAuth->token('dmourer@bethlehem-ucc.org') ;
	}


package Google::Test ;
push @Google::Test::ISA, qw( Google::TQIS ) ;

sub token {
	return Google::OAuth->token('tqisjim@gmail.com') ;
	}


package Google::Drive::Coco ;
push @Google::Drive::Coco::ISA, qw( Google::Drive ) ;

1
__END__

## Sample code for updating the files database:

  use google ;
  use multihash ;
  
  $db = Google::Drive::Coco->db ;
  
  %etag = reverse $db->etag ;
  delete $etag{''} ;
  @items = @{ Google::Drive->new( Google::OAuth->token('tqiscoco@gmail.com') 
  		)->{items} } ;
  %ok = map { $_->{etag} => 1 } @items ;
  map { $ok{$_}-- } keys %etag ;
  
  $m = new multihash ;
  map { $m->{ $ok{$_} } = $_ } keys %ok ;
  ## +1 new ; 0 existing ; -1 deleted
  
  map { $db->delete( $_ ) }
		map { $db->etag( $_ ) }
		@{ $m->{-1} } ;					## delete
  map { $db->save( $_ ) } 
		map { $_->{parent} = $_->{parents}->[0]->{id} ; $_ }
		grep $ok{ $_->{etag} } == 1, @items ;		## insert


## Sample code for uploading  files:

use google ;
use MimeTypes ;
use JSON ;
use MIME::Entity ;
use File::Basename ;
use Getopt::Std ;

getopts( 'op:t' ) ;

$token = Google::OAuth->token('tqiscoco@gmail.com') ;
$o = Google::Drive->new( $token ) ;
%items = map { $_->{title} => $_ } @{ $o->{items} } ;

if ( $opt_t ) {
	do 'perlterm.pl' ;
	exit ;
	}

die unless @ARGV ;

if ( -d $ARGV[0] ) {
	my $k = shift @ARGV if @ARGV > 1 ;
	my $parent = $opt_p || $items{ $k || 'Website' }->{id} ;
	my $parents = [ { id => $parent } ] ;
	my $doc = { title => $ARGV[0] } ;
	$doc->{parents} = $parents ;
	$doc->{mimeType} = 'application/vnd.google-apps.folder' ;
	my $content = JSON::to_json( $doc ) ;

	$out = $token->content( POST => Google::Drive->url, 
			'application/json', 
			$content ) ;
	do 'perlterm.pl' ;
	exit ;
	}

@fn = ( $ARGV[0] ) ;
push @fn, fileparse( $fn[0] ) ;
push @fn, split /\./, $fn[1] ;
$path = $fn[2] ;
$path =~ s|/$|| ;

$parent = $opt_p || $items{ $path }->{id} ;
$parents = [ { id => $parent } ] ;

$doc = { title => $fn[1] } ;
$doc->{parents} = $parents ;
$doc->{mimeType} = $MimeTypes::types{ $fn[-1] } 
		or die "Unknown Mime Type" ;

$content = JSON::to_json( $doc ) ;

$m = MIME::Entity->build( Type => 'multipart/mixed' ) ;
$m->attach( Type => 'application/json', 
		Encoding => '7bit',
		Data => $content ) ;
$m->attach( Type => $doc->{mimeType},
		Encoding => 'binary', 
		Path => $fn[0] ) ;

## MIME::Entity is even more limited that MIME::Lite

@headers = split /: /, 
	${ $m->{mail_inet_head}->{mail_hdr_hash}->{'Content-Type'}->[0] },
	2 ;
$header = $headers[1] ;
chomp( $header ) ;

$content = $m->stringify_body ;
$content =~ s/^[^-]*-//s ;
$content =~ s/^[^-]*-/-/s ;
$content =~ s/\bContent-Transfer-Encoding: [^\n]*\n//g ;

$out = $token->content( POST => Google::Drive->upload, 
		$header, $content ) ;

do 'perlterm.pl' if $opt_o ;
print $out, "\n" ;
