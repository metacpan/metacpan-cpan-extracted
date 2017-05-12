#!/usr/bin/perl
#$Id: cgi_search.pl,v 1.5 1999/04/26 12:14:31 maxim Exp $
# Quick and dirty cgi-script to search a website.
# (Root dir must have been indexed using html_indexer.pl)

my $dbname = '.search.db';
BEGIN { print "content-type: text/html\n\n"; }

my $query_string = $ENV{QUERY_STRING};

if ( $query_string !~ /\S/ ) {
	print_search_page();
} else {
	require MMM::Text::Search;	
	$query_string =~ s/.*?=//;
	$query_string =~ s/\+/ /g;	
	$query_string =~ s/%(..)/pack("c",hex($1))/ge;
 	my $document_root = $ENV{DOCUMENT_ROOT};
	my $dbpath = $document_root."/".$dbname; 
	print <<EOH;
<PRE>	
	DOCUMENT_ROOT = $document_root	
        query		$query_string
	dbpath = 	$dbpath
</PRE>
EOH
	print_search_page($query_string);
	if ( -f $dbpath ) {
		my $srch = new MMM::Text::Search $dbpath ;
		my $result = undef;
		if ($query_string =~ /\band\b|\bor\b/i) {
			$result = $srch->advanced_query($query_string);
		}
		else {
			my @words = split ' ', $query_string;
			$result = $srch->query(@words);
		}
		if ($result) {
			my $e;
			my $files   = $result->{files};
			my $ignored = $result->{ignored};
			my $count  = int @$files;
			
			if (int @$ignored) {
				print "ignored: <B>", join("</B>, <B>", @$ignored),"</B><P>\n";
			}
			print "files found: <B>", $count,"</B><P>\n";
			
			for $e(sort { $b->{score} <=>  $a->{score} } @$files) {
				my $url = $e->{filename};
				$url =~ s/^$document_root\/+/\//;
				print_link($url, $e->{title}||$url, $e->{score} );
				print "<P>\n"
			}
		}
		else {
			print "error: <B>", $srch->errstr,"</B><P>\n";
		}

	}
}	


sub print_link {
	my ($url,$title,$score) = @_;
	print "<A HREF=$url>$title</A> ($score)";
}


sub print_search_page {
	my $query = shift;
	print <<EOH;
<form action='$ENV{SCRIPT_NAME}' >
<input name='q' value='$query' size='80'>
<input type=submit value='Search'>
</form>

EOH
	
	
}	
	
	
	




