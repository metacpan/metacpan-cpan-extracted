
package MMM::Text::Search;
use File::Copy;

#$Id: Search.pm,v 1.50 2004/12/13 18:45:15 maxim Exp $
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $verbose_flag  );
require Exporter;
require AutoLoader;
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(
);
$VERSION = '0.07';

#
# Perl module for indexing and searching text files and web pages.
# 		(Max Muzi, Apr-Sep 1999)
# 
#
# Note on implementation:
# The technique used for indexing is substantially derived from that
# exposed by Tim Kientzle on Dr. Dobbs magazine. (Actually IndexWords() 
# has been cut'n'pasted from his scripts.) 
#
# 

use DB_File;    
use Fcntl;   
require 5.005;

$verbose_flag = 0;

my $debug_flag = 0;

my $errstr = undef;
my $syntax_error = undef;

sub errstr { $errstr };

sub new { 			 # constructor!  (see the docs for usage [sorry, there're no docs ])
	my $pkg = shift;
	my $arg = shift;
	my $opt = undef;
	if (ref($arg) ne "HASH") { 
		if (-f $arg) {
			$opt->{IndexDB} = $arg;
			$opt->{Verbose} = shift;
		}
		else {	
			die "usage:   \$obj = new MMM::Text::Search ( '/index/path' or \$hashref)\n"    
		}
	} else {
		$opt = $arg;
	};

	$verbose_flag = $opt->{Debug} || $opt->{Verbose} ; 
	
	my $indexdbpath = $opt->{IndexDB} || $opt->{IndexPath} ;
	my $filemask 	= $opt->{FileMask} ;
	my $dirs 	= ( ref($opt->{Dirs}) eq "ARRAY" ) ? $opt->{Dirs} : [ ];
	my $followsymlinks = defined $opt->{FollowSymLinks};
	
	my $opturls =  $opt->{Urls} ||  $opt->{URLs};
	my $urls 	= ( ref($opturls) eq "ARRAY" ) ? $opturls : [ ];
	my $level	= int $opt->{Level};
	
	my $locationsdbpath = $indexdbpath;
	$locationsdbpath =~ s/(\.db)*$/\-locations.db/;
	my $titlesdbpath = $indexdbpath;
	$titlesdbpath =~ s/(\.db)*$/\-titles.db/;
	
	my $minwordsize = $opt->{MinWordSize} || 1;


	my $self = {
		indexdbpath 	=> $indexdbpath,
		locationsdbpath 	=> $locationsdbpath,
		titlesdbpath	=> $titlesdbpath,
		filemask 	=> length($filemask) ? qr/$filemask/ : undef,
		dirs 		=> $dirs,
		followsymlinks  => $followsymlinks,
		minwordsize	=> $minwordsize,
		ignorelimit	=> $opt->{IgnoreLimit} || (2/3),
		urls		=> $urls,
		level		=> $level,
		url_exclude	=> $opt->{UrlExludeMask} || "(?i).*\.(zip|exe|gz|arj|bin|hqx)", 
		file_reader     => $opt->{FileReader},
		use_inode       => $opt->{UseInodeAsKey},
		no_reset        => $opt->{UseInodeAsKey} && $opt->{NoReset}
		
	};
	DEBUG("filemask=$filemask, indexfile=$indexdbpath, ignorelimit=$self->{ignorelimit}\n");
	DEBUG("dirs = [", join(",", @$dirs),"], ");
	DEBUG("urls = [", join(",", @$urls),"] \n");
	bless($self, $pkg);
	return $self;
}

sub _add_keys_to_match_hash {  
# extract file-codes from $keys and update corresponding $hash elements (score)
	my ($keys, $hash) = @_;
	my $key;
	foreach $key ( unpack("N*",$keys) ) { 
#		DEBUG($key, " ");
		# ignored words (stop-words) only include file-id 0 (see FlushCache() below)
		return 0 if  $key == 0 ; 
		$hash->{$key}++
	}
	return 1;
}
	
sub _push_words_from_hash {
	my ($hash,$array, $regexp) = @_;
	my $w;
	for $w(keys %$hash) {
		push @$array,$w if $w =~ $regexp;
	}
}



#notes on advanced_query();
# - queries containing stop-words may yields bizzare results..
# - score is not always correct
# - error handling should be improved... :-)
sub advanced_query {
# perform queries such as  "( a and ( b or c ) ) and ( d and e) "
	my $self = shift;
	my $expr = shift;
	my $indexdbpath= $self->{indexdbpath};
	my $locationsdbpath = $self->{locationsdbpath};
	my $titlesdbpath = $self->{titlesdbpath};
	my %indexdb;
	my %locationsdb;
	my %titlesdb;
	return undef unless (-f $indexdbpath && -r _);
	return undef unless (-f $locationsdbpath && -r _);
	return undef unless (-f $titlesdbpath && -r _);
	return undef unless	
		tie_hash(\%indexdb,$indexdbpath, O_RDONLY ) &&
		 tie_hash(\%locationsdb,$locationsdbpath, O_RDONLY ) &&
		  tie_hash(\%titlesdb,$titlesdbpath, O_RDONLY );
	my @ignored = ();
	my @words = ();
	my $verbose_flag_tmp = $verbose_flag;
	$verbose_flag = shift; # undocumented debug switch
	chomp $expr;	
	undef $syntax_error; #reset error
	DEBUG("********** _match_expression() debug **********\n");	
	my $match = _match_expression($expr, \%indexdb, \@ignored);
	DEBUG("**********         end debug         **********\n");	
	if ($syntax_error) {
		$errstr = $syntax_error;
		$verbose_flag = $verbose_flag_tmp;
		return undef;
	}
	my $result =  _make_result_hash($match,\%locationsdb, \%titlesdb, \@words, \@ignored);
	
	untie(%indexdb);
	untie(%locationsdb);
	untie(%titlesdb);
	$verbose_flag = $verbose_flag_tmp;
	return $result;
}

sub _match_expression { 	 # recursively apply a keyword-search expression to indexdb
				 # $expr may be either a string or a ref to an array of tokens
				 # a ref to a "score" hash is returned (or undef sometimes)
	my ($expr, $index, $ignored) = @_;
	my $parsed = _parse_expression($expr);
		 # _parse_expression() returns a reference to an array of three elements:
		 # 			[ operator, left_expr, right_expr]
		 #  if right_expr is not defined then expr was atomic and left_expr is a string,
		 #  otherwise both right_expr and left_expr are references to arrays of tokens
	if ( not $parsed) {
		DEBUG("Syntax error :-( \n");
		return undef;
	}
	my ( $op, $left,$right) = @$parsed;
	
	if ($left && not $right) {  
		$left =~ s/^\s*\(?\s*|\s*\)?\s*$//g;
		DEBUG("Looking up >$left<\n");
		my %matches = ();
		my $word = $left;
		my $rc = 0;
    		my $keys = $index->{lc $word}; # get file-id's from indexdb
		$rc = _add_keys_to_match_hash($keys,\%matches);
		# if $rc is false then $word  is a stop-word, see _add_keys_to_match_hash() for more info		
		if (not $rc) {
			DEBUG("$word ignored\n");
			push @$ignored, $word;
			return undef;
			# what should we do now? gotta think it over...
		}
		return \%matches;
	}
	
	DEBUG("Evaluating >$left< --$op-- >$right<\n");
	my $left_match  = _match_expression($left, $index, $ignored);		
	my $right_match = _match_expression($right, $index, $ignored);		
	
	return undef if ($syntax_error); 
	my %matches = ();
	my $file = undef;
	
	if ($op eq 'AND' ) {
		%matches = ( %$left_match );
		for $file( keys %matches) {
			delete $matches{$file} unless $right_match->{$file}
		}
		return \%matches;
	}
	if ($op eq 'AND NOT') {
		%matches = ( %$left_match );
		for $file( keys %matches) {
			delete $matches{$file} if $right_match->{$file}
		}
		return \%matches;
	}
	if ($op eq 'OR')  {
		%matches = (  %$left_match );
		for $file( keys	%$right_match) {
			if ($matches{$file}) {
				$matches{$file} +=$right_match->{$file};
			} else {
				$matches{$file} =$right_match->{$file};
			}
		}
		return \%matches;
	}	
	return undef;
}	

sub _parse_expression {
	my $arg = shift;
	my $tokens = undef;  # this is an arry ref
	if (ref($arg) ne 'ARRAY') {
		$tokens = [ 
		 $arg =~  m/( \( | \)| \bAND\s+NOT\b | \bAND\b | \bOR\b | \"[^\"]+\" | \b\w+\b) /xig 
			];
	}
	 # important!!	"AND NOT" is treated as a single logical operator... 
	 # 		this means that things like "not a and b" aren't well-formed,
	 #		while "b and not a" is
	else { $tokens = $arg;
	}
	my $left =  undef; # array ref  (oppure stringa se è un espressione atomica)
	my $right = undef; # array ref !
	my $op =    'OR';
	my $depth = 0;
	my $pos = 0;
	my $tok;
	my $len = int @$tokens;
	DEBUG("expr = ", join(" + ", @$tokens),"\n"); 	
	while (1) {
		if ($len == 1) {
			return [ undef, $tokens->[0], undef ];
		}
		DEBUG("$tok : depth=$depth pos=$pos len=$len\n");
		if ($depth == 0 && ($pos == $len) ) {
			if ($tokens->[0] eq '(' && $tokens->[$len-1] eq ')') {
			 # take off outer parentheses...
				shift @$tokens;
				pop @$tokens;
				$len  -= 2;
				$pos   = 0;
				$depth = 0;
				DEBUG("expr = ", join(" + ", @$tokens),"\n"); 	
			} else { # ahhhh... this expression won't be parsed... 
				$syntax_error = "Ill-formed expression (\"".join(' ', @$tokens)."\")";
				DEBUG("atom not atomic\n");			
				return undef;
			}
	
		} elsif ( $pos == $len ) {
			$syntax_error = "Non-matching parentheses (\"".join(' ', @$tokens)."\")"; 
			DEBUG("non matching parentheses\n");
			return undef;
		}
		$tok = $tokens->[$pos++];
		if ($tok eq '(') { $depth++; next; }
		if ($tok eq ')') { $depth--; next; }
		next if $depth;
		if ($tok  =~ /\b(AND\s+NOT|AND|OR)\b/i) {
			if ($pos == 1 || $pos == $len)  {
				$syntax_error = "Ill-formed expression (\"".join(' ', @$tokens)."\")";
				return undef 
			} 
			$op = uc $1; $op =~ s/\s+/ /g;
			$left = [ @$tokens[0..$pos-2]    ];
			$right =  [ @$tokens[$pos..$len-1] ];
			DEBUG("right = ", join(" + ", @$right),"\n"); 	
			DEBUG("left  = ", join(" + ", @$left),"\n"); 	
			return [ $op, $left, $right ];
		}
	}
}
	
	

sub query { 	 # simple query....  	altavista +/- prefixes are recognized...
		 #			*/? globbing also works but 
		 #			slows query down significantly
		 #			globbing implicitly discards +/- prefix (it's a BUG!!!)
	my $self = shift;
	my $indexdbpath= $self->{indexdbpath};
	my $locationsdbpath = $self->{locationsdbpath};
	my $titlesdbpath = $self->{titlesdbpath};
	my %indexdb;
	my %locationsdb;
	my %titlesdb;
	return undef unless (-f $indexdbpath && -r _);
	return undef unless (-f $locationsdbpath && -r _);
	return undef unless (-f $titlesdbpath && -r _);
	return undef unless	
		tie_hash(\%indexdb,$indexdbpath, O_RDONLY ) &&
		tie_hash(\%locationsdb,$locationsdbpath, O_RDONLY ) &&
		tie_hash(\%titlesdb,$titlesdbpath, O_RDONLY );
	my %matches;
	my %limit;
	my %exclude;
	my @ignored;
	my $key;
	my $word;
	my $mustbe_words = 0;
	my @words = ();
	my $glob_regexp = undef;
	for (@_) {		# globbing feature... e.g. uni* passw?
		if ( /\*|\?/) {
			s/\*/\.\*/g;
			s/\?/\./g;
			$glob_regexp = $glob_regexp ? $glob_regexp."|^$_\$" : "^$_\$" ;
		}
		else {
			push @words, $_;
		}
	}
	if ($glob_regexp) {
		my $regexp = qr/$glob_regexp/;
		# collect  all words in db matching $glob_regexp and append them to the query
		_push_words_from_hash(\%indexdb, \@words, $regexp);
	}

	DEBUG("looking up ", join(", ", @words ), "\n");
	foreach $word (@words) {
		my $rc = 0;
#		DEBUG($word);
		if ($word =~ /^-(.*)/) {
    			my $keys = $indexdb{lc $1};
			$rc = _add_keys_to_match_hash($keys,\%exclude);
		} elsif ($word =~ /^\+(.*)/) {
			$mustbe_words++;
    			my $keys = $indexdb{lc $1};
			$rc = _add_keys_to_match_hash($keys,\%limit);
		} else {
    			my $keys = $indexdb{lc $word};
			$rc = _add_keys_to_match_hash($keys,\%matches);
		}
#		DEBUG("\n");
		if (not $rc) { push @ignored, $word }
	}
	
	if ($mustbe_words) {
		for $key(keys %limit) {
			next unless $limit{$key} >= $mustbe_words;
			$matches{$key}  += $limit{$key} ;
		}
		for $key(keys %matches) {
			delete $matches{$key} unless $limit{$key};
		}
	}
	for $key(keys %exclude) {
		delete $matches{$key};
	}
	my $result =  _make_result_hash(\%matches,\%locationsdb, \%titlesdb, \@words, \@ignored);
	untie(%indexdb);
	untie(%locationsdb);
	untie(%titlesdb);
	return $result;
}
	

sub _make_result_hash {
#            hash-ref  hash-ref   hash-ref    array-ref   array-ref
	my ( $match,   $locationsdb,  $titlesdb,  $words,     $ignored  ) = @_; 
	my $result = {
		searched =>  $words,
		ignored  =>  $ignored,
		entries	 =>  []
	};
	my $key;
	foreach $key (keys %$match) {
		my $ckey = pack("xN",$key);
  		my $name = $locationsdb->{$ckey};
		my $title = $titlesdb->{$ckey};
		
		push @{ $result->{entries} }, { 
			location => $name,
			score 	 => $match->{$key},
			title	 => $title
		};
  		DEBUG("$name:  $match->{$key}\n");
	}
	return $result;
}


	
	
	


sub DEBUG (@) { $verbose_flag && print STDERR @_ };

sub tie_hash {
	my ($hashref, $file ,$perm) = @_;
	$perm = (O_RDWR|O_CREAT) unless defined $perm;
	my $rc = tied(%$hashref);
	return $rc if $rc;
	$rc = tie(%$hashref,'DB_File',$file, $perm, 0644, $DB_File::DB_BTREE) ;
	if ($debug_flag) {
			my $count = int keys %$hashref;
			DEBUG("tie $hashref ($rc) ($count keys)\n");
	} elsif ($verbose_flag) {
			DEBUG("tie $hashref ($rc)\n");
	}

		
	return $rc;
}

sub untie_hash {
	my ($hashref, $file ) = @_;
	if ($debug_flag) {
		my $count = int keys %$hashref;
		DEBUG("untie $hashref ($count keys)\n")
	}
	untie(%$hashref);
}


1;
#__END__

=head1 NAME

MMM::Text::Search - Perl module for indexing and searching text files and web objects

=head1 SYNOPSIS

  use MMM::Text::Search;
	  
  my $srch = new MMM::Text::Search {	#for indexing...
	#index main file location...  
		IndexPath => "/tmp/myindex.db",
	#local files... (optional)
		FileMask  => '(?i)(\.txt|\.htm.?)$',
		Dirs	  => [ "/usr/doc", "/tmp" ] ,
		FollowSymLinks => 0|1, (default = 0)
	#web objects... (optional)
		URLs	  => [ "http://localhost/", ... ],
		Level	  => recursion-level (0=unlimited)		
	#common options...		
		IgnoreLimit =>	0.3,   (default = 2/3)
		Verbose => 0|1				
  	};
  
  $srch->start_indexing_session();
	
  $srch->commit_indexing_session();
  
  $srch->index_default_locations();
        
  $srch->index_content( { title =>   '...', 
		    	  content=>  '...', 
		    	  id =>      '...'  } );
	 
  $srch->makeindex;
       (Obsolete.) 


	
	

  my $srch = new MMM::Text::Search (  #for searching....
		  "/tmp/myindex.db", verbose_flag );
  
  my $hashref = $srch->query("pizza","ciao", "-pasta" );  
  my $hashref = $srch->advanced_query("(pizza OR ciao) AND NOT pasta");  

  $srch->errstr()	# returns last error 
			# (only query syntax-errors for the moment being)

  
  $srch->dump_word_stats(\*FH)	

=head1 DESCRIPTION


=item	*
Indexing

When a session is closed the following files will have been created 
(assuming IndexPath = /path/myindex.db, see constructor):
 

	/path/myindex.db	     word index database
	/path/myindex-locations.db   filename/URL database
	/path/myindex-titles.db	     html title database
	/path/myindex.stopwords	     stop-words list
	/path/myindex.filelist	     readable list of indexed files/URLs
	/path/myindex.deadlinks	     broken http links

	[... lots of important things missing ... ]

start_indexing_session() starts session.
	
commit_indexing_session() commits and closes current session.
  
index_default_locations() indexes all files and URLs specified on construction.

index_content() pushes content into indexing engine. 
Argument must have the following structure
		
 { title =>   '...', content=>  '...', id =>      '...'  }


makeindex() is obsolete.
        Equivalent to:
          $srch->start_indexing_session();
          $srch->index_default_locations();
          $srch->commit_indexing_session();




dump_word_stats(\*FH) dumps all words sorted by occurence frequency using
FH file handle (or STDOUT if no parameter is specified). Stop-words get a 
frequency value of 1.

=item *
Searching

Both query() and advanced_query() return a reference to a hash with 
the following structure:

	(
	 ignored  => [ string, string, ... ], # ignored words
	 searched => [ string, string, ... ], # words searched for
	 entries    => [  hashref, hashref, ... ] # list of records 
						# found
	 )
	
The 'entries' element is a reference to an array of hashes, each having 
the following structure:

	(
 	 location => string,  # file path or URL or anything
	 score    => number,  # score 
	 title    => string   # HTML title		 
	)

=head1 NOTES

Note on implementation:
The technique used for indexing is substantially derived from that
exposed by Tim Kientzle on Dr. Dobbs magazine. 

=head1 BUGS

Many, I guess. 

=head1 AUTHOR

Max Muzi <maxim@comm2000.it>

=head1 SEE ALSO

perl(1).

=cut



#
#-------------------- the following code is only used when indexing ----------------
#

sub dump_word_stats {
	my $self = shift;
	my $fh = shift || \*STDOUT;
	my $indexdbpath= $self->{indexdbpath};
	my %indexdb;
	die unless (-f $indexdbpath && -r _);
	tie_hash(\%indexdb,$indexdbpath, O_RDONLY );
	my %index = ( %indexdb );
	my $w;
	for $w( sort { length($index{$b}) <=> length($index{$a}) }
				keys %index ) {
		print $fh $w, "\t", length($index{$w}) / 2, "\n"; 
	}
	untie_hash(\%indexdb);
}


sub start_indexing_session 
{
	my $self = shift;
	$self->rollback_indexing_session;
	my $key = 0;
	my $indexdbpath = $self->{indexdbpath};
	my $locationsdbpath = $self->{locationsdbpath};
	my $titlesdbpath = $self->{titlesdbpath};

	my $filemask 	= $self->{filemask};
	my $keyref = \$key;
	my $filelistfile = $indexdbpath;
	$filelistfile =~  s/(\.db)?$/\.filelist/;
	open FILELIST, ">".$filelistfile;
	
	my $session = {
		indexdbpath 	=> $indexdbpath,
		locationsdbpath 	=> $locationsdbpath,
		titlesdbpath 	=> $titlesdbpath,
		indexdb 	=> { },
		locationsdb 	=> { },
		titlesdb 	=> { },
		cachedb 	=> { },
		filemask 	=> $filemask,
		current_key	=> 16, # first 16 values are reserved (0 = word is ignored)
		bytes		=> 0,
		count 		=> 0,
		filecount	=> 0,
		listfh		=> \*FILELIST,	
		status_THE 	=> 0,
		followsymlinks	=> $self->{followsymlinks},
		minwordsize	=> $self->{minwordsize},
		ignoreword	=> {},
		autoignore	=> 1,
		ignorelimit	=> $self->{ignorelimit} || (2/3),
		level		=> $self->{level},	
		url_exclude 	=> $self->{url_exclude},
		file_reader  => $self->{file_reader},
		use_inode    => $self->{use_inode},
		no_reset     => $self->{no_reset},
	};
	
	unlink $indexdbpath."~"; 
	unlink $locationsdbpath."~"; 
	unlink $titlesdbpath."~";
	if( $self->{no_reset} )
	{
		copy( $indexdbpath, $indexdbpath."~" );
		copy( $locationsdbpath, $locationsdbpath."~" );
		copy( $titlesdbpath, $titlesdbpath."~" );
	}
	tie_hash($session->{indexdb}, $indexdbpath."~" )   or die "$indexdbpath: $!\n";
	tie_hash($session->{locationsdb}, $locationsdbpath."~" )   or die $!;
	tie_hash($session->{titlesdb},$titlesdbpath."~" ) or die $!;

	my $ignorefile = $indexdbpath;
	$ignorefile =~ s/(\.db)?$/\.stopwords/;
	if (-r $ignorefile) {  # read *-stopwords.dat file
		open F, $ignorefile;
		while (<F>) {
			chomp;
			s/^\s+|\s+$//g;
			$session->{ignoreword}->{$_} = 1;
		}
		close F;
		my $count = int keys %{ $session->{ignoreword} };
		DEBUG("using stop-words from $ignorefile ($count words)\n");
		$session->{autoignore} = 0;
	}
	$session->{ignorefile} = $ignorefile;
	
	my $time = time();
	
	$session->{start_time} = $time;
	
	$self->{session} = $session;
}

sub index_default_locations
{
	my $self = shift;
	my $session = $self->{session};
	return unless $session; 

	my $dirs 	= $self->{dirs};
	my $urls	= $self->{urls};
	my $filecount = 0;
	DEBUG("Counting files...\n") if int @$dirs;
	my $dir;
       	for $dir( sort  @$dirs) { $filecount += IndexDir($session, $dir, 1); }
	$session->{filecount} = $filecount;

	for $dir( sort  @$dirs) { IndexDir($session, $dir); }
	for my $url( sort  @$urls) { IndexWeb($session, $url); }
}

sub index_content
{
	my $self = shift;
	my $session = $self->{session};
	return unless $session; 
	my $info = shift;
	if( ref($info) ne 'HASH'  )
	{	warn("usage: \$src->index_content( { content=>'...', id=>'...', title=>'...' } )\n");
		return undef;
	}
	IndexFile( $session, $info->{id}, $info->{content}, $info->{title} );	
	return 1;
}

sub rollback_indexing_session
{
	my $self = shift;
	my $session = $self->{session};
	return unless $session; 
	untie_hash($session->{indexdb});
	untie_hash($session->{locationsdb});
	untie_hash($session->{titlesdb});
	my $indexdbpath = $self->{indexdbpath};
	my $locationsdbpath = $self->{locationsdbpath};
	my $titlesdbpath = $self->{titlesdbpath};
	
	unlink $indexdbpath."~"; 
	unlink $locationsdbpath."~";
	unlink $titlesdbpath."~"; 
	$self->{session} = undef;
}

sub DESTROY
{
	my $self = shift;
	$self->rollback_indexing_session;
}

sub commit_indexing_session
{
	my $self = shift;
	my $session = $self->{session};
	return unless $session; 
	FlushCache($session->{cachedb}, $session->{indexdb}, $session);
	my $time = time()-$session->{start_time};
	DEBUG("$session->{bytes} bytes read, $session->{count} files processed in $time seconds\n");
	untie_hash($session->{indexdb});
	untie_hash($session->{locationsdb});
	untie_hash($session->{titlesdb});
	
	my $indexdbpath = $self->{indexdbpath};
	my $locationsdbpath = $self->{locationsdbpath};
	my $titlesdbpath = $self->{titlesdbpath};
	
	rename $indexdbpath."~", $indexdbpath; 
	rename $locationsdbpath."~", $locationsdbpath ;
	rename $titlesdbpath."~", $titlesdbpath;
	close $session->{listfh};
	if ( $session->{autoignore} ) {
		my $ignorefile = $session->{ignorefile};
		open  F, ">".$ignorefile; #write *-stopwords.dat file
		print F join( "\n", sort keys %{ $session->{ignoreword} } );
		close F;
	}
	
	$self->{session} = undef;
 }

 
 
sub makeindex
{
	my $self = shift;
	$self->start_indexing_session();
	$self->index_default_locations();
	$self->commit_indexing_session();
}
 

sub IndexDir {
	my ($session, $dir, $only_recurse) = @_;
	my $followsymlinks = $session->{followsymlinks};
	my $file_reader = $session->{file_reader};
	opendir D, $dir;
#	DEBUG "D $dir\n";
	my @files = readdir D;
	close D;
	my $e;
	my $count = 0;
	my $text;
	for $e(@files) {
		next if $e =~ /^\.\.?/;
		my $path = $dir."/".$e;
		if (-d $path) {
			unless ($followsymlinks) {
				next if -l $path ;
			}
			$count += IndexDir($session,$path, $only_recurse);
		}
		elsif (-f _ ) {
			my $filemask = $session->{filemask};
			if ($filemask) {
				next unless $e =~ $filemask;
			}
			unless ($only_recurse) 
			{
				if( $file_reader )
				{
					$text = $file_reader->read( $path );
					IndexFile($session,$path,$text);
				} else
				{
					IndexFile($session,$path);
				}
			}
			$count ++;
		}
	}
	return $count;
}



sub IndexFile {
	my ($session, $file, $text, $title ) = @_;
	my $cachedb = $session->{cachedb};
	my $locationsdb = $session->{locationsdb};
	my $key = $session->{current_key};
	if( $session->{use_inode} )
	{
		$key = (stat($file))[1];
	}
	my $no_of_files = $session->{filecount};
	if(  $session->{no_reset} )
	{
		if( exists $locationsdb->{pack"xN",$key} )
		{
			warn("key $key already in locationsdb. Skipping\n");
			return;
		}
	}
	DEBUG $session->{count}+1, "/$no_of_files $file (id=$key)\n";
	my $fh = $session->{listfh};
	print $fh "$key\t$file\n";
	local $/;
	unless (defined $text) {
		undef $/;
		open(FILE, $file);
		($text) = <FILE>; 		# Read entire file
		close FILE;
	}
	my $filesize =  length($text);
	if ($file =~ /\.s?htm.?/i ) {
		$text =~ /<title[^>]*>([^<]+)<\/title/i ;
		$title = $1;
		$title =~ s/\s+/ /g;
		$text =~ s/<[^>]*>//g; 		# strip all HTML tags
	}
	if( defined $title )
	{
		$session->{titlesdb}->{pack"xN",$key} = $title;  # put title in db
		DEBUG("* \"$title\"\n");
	}
	# index all the words under the current file-id
	my($wordsIndexed) = &IndexWords($cachedb, $text,$key, $session);
	$session->{current_key}++;
	DEBUG "* $wordsIndexed words\n";
	
	# map file-id (key) to this filename
	$locationsdb->{pack"xN",$key} = $file;   	# leading null is here for 
						# historical reasons :-)
	$session->{bytes} += $filesize;
	$session->{count}++;
	$session->{_temp_size} += $filesize;
	if ($session->{_temp_size} > 2000000 ) {
		my $rc = 0;
		$rc = FlushCache($cachedb, $session->{indexdb}, $session);
		
		if (! $rc ) {
			tie_hash($session->{indexdb}, $session->{indexdbpath}) or die $!;
			untie_hash($session->{indexdb});
			$rc = FlushCache($cachedb, $session->{indexdb}, $session);
			die $! if not $rc;
		}
		
		$session->{_temp_size} = 0;
		$session->{cachedb} = {};
	}
}

sub IndexWords {
    my ($db, $words, $fileKey, $session) = @_;
#      hash  content  file-id   options	
    my (%worduniq); # for unique-ifying word list
    my $minwordsize = $session->{minwordsize};	    
    my (@words) = split( /[^a-zA-Z0-9\xc0-\xff\+\/\_]+/, lc $words); # split into an array of words
    @words = grep { $worduniq{$_}++ == 0 } 		# remove duplicates
             grep { length  > $minwordsize } 		# must be longer than one character
	     grep { s/^[^a-zA-Z0-9\xc0-\xff]+//; $_ }	# strip leading punct
             grep { /[a-zA-Z0-9\xc0-\xff]/ } 		# must have an alphanumeric
             @words;
					#   "  foreach (sort @words) { "
    for (@words) {     			# no need to sort here, 
	my $a = $db->{$_};		# we will sort when cache is flushed 
	$a .= pack "N",$fileKey;	# appending packed file-id's
        $db->{$_} = $a;
    }
    return int @words;
}



sub FlushCache { 
	my ($source, $dest, $session) = @_;
		# flush source hashe into dest....  
		# %$dest is supposed to be tied, otherwise the whole
       		# thing doens't make much sense... :-)	
	my $scount = int  keys %$source ;
	my $ucount = 0;
	my $acount = 0;
	if ($scount == 0) {
		die "error: 0 words in cache\n";
	}
#	my $wordcount = int keys %$dest;
#	if ($wordcount < $session->{wordcount}) {
#		warn "indexdb has lost entries (now $wordcount, were $session->{wordcount}) \n";
#		return undef;
#	}
#	$session->{wordcount} = $wordcount;
	
#	DEBUG("$wordcount words in database\n");
	my $objref = tied %$dest ;
	DEBUG("flushing $scount words into $dest ($objref)\n");
	
	my $filecount = $session->{count};
	my $autoignore = $session->{autoignore};
	my $ignorethreshold = int ( $filecount * $session->{ignorelimit} );
		
	my $w;
	
	WORD:
	for $w(sort keys %$source) {
		my $data = $source->{$w};
		if ($session->{ignoreword}->{$w} ) {
			DEBUG("ignoring '$w' \n");
			$data = pack("N*", ( 0 ) ); # id = 0 means $w is a stop-word
		}
		elsif (defined $dest->{$w}) {
			my %uniq = ();
			my $keys =  $dest->{$w} . $data ;
			my $keycount = length($keys)/2; # dividing by 2
			
			$ucount++;
##			my @keys = unpack("n*", $keys) ;
##			my $keycount = @keys;
##					
##			if ($keys[0] == 0 ) {  # skip ignored word 
##				DEBUG("skipping '$w' \n");
##				next WORD;
##			} els
			
			if ($autoignore && ($filecount > 100) 
			   && ($keycount > $ignorethreshold ) ) {
				DEBUG("word '$w' will be ignored (found in $keycount of $filecount files)\n");
				# ignored words are associated to file-id 0
##				@keys = ( 0 );
				$keys = pack("N*", 0);
				$session->{ignoreword}->{$w} = 1;
			}
##			@keys = grep { $uniq{$_}++ == 0} @keys;
##			$data = pack("n*", @keys);
			
			$data = $keys;
			
##			if ($verbose_flag && ( $w eq "the" ) )  {
##				my $len = int(@keys);
##				if ($len < $session->{status_THE} ) {
##						die "panic: problem with word 'the'";
##				}
##				$session->{status_THE} = $len;
##				DEBUG("word 'the' found in $len files \n");
##			}

		} else {
			$acount++;
		}
		$dest->{$w} = $data;
		
#		if ($dest->{$w} ne $data) {
#			warn "unexpected error: \$w=$w\n";
#			return undef;
#		}
	}
	DEBUG("$ucount words updated, $acount new words added\n");
	if ($debug_flag) {
		my $wordcount = int keys %$dest;
		if ($wordcount < $session->{wordcount}) {
			warn "indexdb has lost entries (now $wordcount, were $session->{wordcount}) \n";
			return undef;
		}
		$session->{wordcount} = $wordcount;
		DEBUG("$wordcount words in database\n");
	}
	return 1;
}





sub IndexWeb {
	my ($session, $url) = @_;
	require MMM::Text::Search::Inet;
	my $req = new HTTPRequest { AutoRedirect => 1 };
	my %fetched = ();
	$req->set_url($url);
	my $host = $req->host();
	$session->{req} = $req;
	$session->{fetched} = \%fetched;
	$session->{host} = $host;
	my $deadlinksfile = $session->{indexdbpath};
	$deadlinksfile =~ s/(\.db)?$/\.deadlinks/;
	open DL, ">".$deadlinksfile;
	$session->{deadlinksfh} = \*DL;
	recursive_fetch($session, $url, "", 0);
}



sub recursive_fetch {
	my ($session, $URL, $parent, $level) = @_;
	my $req = $session->{req};
	$req->reset();
	$req->set_url($URL);
	my $url =  $req->url();
	return unless $req->host() eq $session->{host};
	return if $session->{fetched}->{$url};
	$session->{fetched}->{$url} = 1;
	return unless $req->get_page();
	my $status =  $req->status();
	DEBUG( ">>> $url ($status)\n");
	if ( $status != 200 ) {
		my $fh = $session->{deadlinksfh};
		my $url = $req->url();
		print $fh $status, "\t",
			$url, "(", $req->{_URL},")",
			"\t", $parent, "\n";
		return;	
	};
	my $base =  $req->base_url();
	my $content_ref = $req->content_ref();
	my $header  = $req->header();
	IndexFile($session, $url, $$content_ref);
	return if ($session->{level} && $level >= $session->{level});
	$$content_ref =~ s/<!--.*?-->//gs;	#remove comments
	my @links = $$content_ref =~/href=([^>\s]+)/ig; #extract hyperlinks
	my $count = 0;
	my $exclude_re = $session->{url_exclude};
	for(@links) {
		s/\"|\'//g;
		next if m/^(ftp|mailto|gopher|news):/;	
		next if m/^$exclude_re$/o;
		my $link = /^http/ ? $_ : join("/",$base,$_);
		$link =~ s/#.*//;
		$count++;
		recursive_fetch($session,$link, $url, $level +  1); 
	}
}


1;
__END__
