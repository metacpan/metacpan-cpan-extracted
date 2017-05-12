package WWW::Link_Controller::InfoStruc;
$REVISION=q$Revision: 1.10 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

use Carp qw(carp croak cluck);
use strict;
use warnings;
use Search::Binary;

our ($no_warn, $verbose);

$no_warn = 0 unless defined $no_warn;

=head1 NAME

WWW::Link_Controller::InfoStruc - read infostructure config.

=head1 DESCRIPTION

This is a simple module for reading infostructure configuration.

=cut

$verbose=0 unless defined $verbose;

sub default_infostrucs () {
  WWW::Link_Controller::InfoStruc::read_infostruc_file
      ( $::infostrucs, \%::infostrucs, \@::infostrucs,
	\@::infostruc_urls_sorted,\@::infostruc_files_sorted );
}

sub read_infostruc_file ($$$) {
  my $filename=shift;
  my $infostruc_hash=shift;
  my $infostruc_array=shift;
  my $url_array_sorted=shift;
  my $file_array_sorted=shift;

  my @url_array;
  my @file_array;

  die "need an array ref not " . ref $url_array_sorted
    unless ( ref $url_array_sorted ) =~ m/ARRAY/;
  die "need an array ref not " . ref $file_array_sorted
    unless ( ref $url_array_sorted ) =~ m/ARRAY/;

  open(INFOSTRUCS, $filename) or die "couldn't open config file $filename";

  print STDERR "Reading cofig file $filename\n"
    if $verbose & 64;

  while (defined(my $conf_line=<INFOSTRUCS>)) {
    next if $conf_line =~ m/^\s*(?:\#.*)$/; 	#comment lines and empty lines
    print STDERR "conf line $conf_line\n" 
      if $verbose;

    $conf_line =~ m<^\s*(\S+)\s+(\S+)\s.*\%> and
      die '% and " are reserved in infostructure config file ' . $filename;

    my ($mode, $url, $directory, $junk) =
      $conf_line =~ m,^\s*(\S+)\s+(\S+) #non optional mode and url
                      (?:\s+(\S+) #directory
                        (?: \s*(.\s+))? #junk
                      )?,x;


    die "badly formatted line in infostruc conf file\n$conf_line\n"
      . "too many spaces" if $junk;

    my $infostruc;

  CASE: {
      $mode =~ m/^(?:www|directory)$/ and do {
	$infostruc =
	  {
	   mode => $mode,
	   url_base => $url,
	   file_base => $directory
	  };
	$infostruc_hash->{$url} = $infostruc;
	last CASE;
      };
      $mode eq "advanced" and do {
	defined $infostruc_hash->{$url} or do {
	  print STDERR <<EOF;
Found advanced infostructure $url in
$filename without definition.

You have to define the \$::infostrucs{<url>} definition in your 
.link-control.pl file for every advanced infostructure.  See the LinkController
reference manual for details.
EOF
	  die "\$::infostrucs{$url} not defined";
	};

	$infostruc =$infostruc_hash->{$url};

	#this is good since it minimises duplication of data
        #so we won't offer a warning normally
	defined $infostruc->{url_base} or do {
	  warn "url_base defined for $url infostruc; copying hash key"
	    if $verbose;
	  $infostruc->{url_base}=$url;
	};
	#this is not documented yet ... but I think it's
	#sensible..... it may go away though
	defined $infostruc->{mode} or do {
	  warn "mode not defined for $url infostruc"
	    unless $no_warn;
	  $infostruc->{mode}="www";
	  $infostruc->{mode}="directory"
	    if defined $infostruc->{file_base};
	};

	$infostruc->{mode} eq "directory"
	  and not defined $infostruc->{file_base}
	    and die "file_base not defined for $url infostructure";
	last CASE;
      };
      die "unknown mode $mode" ;
    }

    $infostruc->{url_base} eq $url
      or die "base url inconsistency $url / "
	. $infostruc->{url_base} . "\n";


    print STDERR "got data for infostructure at $url\n"
      if $verbose & 64;

    #fixme; maybe we should use BTREEs rather than doing binary
    #searches on arrays.  This is likely to be a performance critical
    #piece of code?

    push @$infostruc_array, $url;
    push @url_array, [ $url, $infostruc ];
    push @file_array, [ $infostruc->{file_base}, $infostruc ]
      if defined $infostruc->{file_base};
  }

  @$url_array_sorted=sort {$b->[0] cmp $a->[0]} @url_array;
  @$file_array_sorted=sort {$b->[0] cmp $a->[0]} @file_array;

}


=head2 url_to_file

C<url_to_file> takes a url as an argument.  It then does a binary
search on a reverse sorted array of url bases.  It uses infostructure
definitions to convert the URL into a filename.

This function should untaint it's result because it should use the
infostructure definitions to ensure that we only do things to files we
are supposed to do things to.

=cut

#  Given any url, get us something we can edit in order to change the
#  resource referenced by that url.  Or not, if we can't.  In the case
#  that we can't, return undef.


#  N.B.  This will accept any filename which is within the infostructure
#  whatsoever.. it is possible that that includes more than you wish to
#  let people edit.


sub _find_best_match ($$) {
  my $array=shift;
  my $key=shift;

  cluck "usage _find_best_match(<array-ref>, <key>)"
     unless ref ($array) =~ m/ARRAY/ and defined $key;

  # we want the longest match.. so we look through the list..  if we
  # are put at something equal to us then we are fine.  If it's not
  # equal to us, then the value we point at will be greater than our
  # url.  Because we use reverse sorting then greater means shorter,
  # so it will be okay to.

  my $old_position;
  my $read=sub {
    my ( $handle, $val, $position ) =@_;
    (ref $handle) =~ m/ARRAY/ or die "need an array reference not $handle";
#    ($position) =~ m/^[0-9]+$/i or die "need whole number, not $position";
    $position=$old_position+1 unless defined $position;
    $old_position=$position;
    return undef if $position > $#$handle;
    my $aval=$handle->[$position];
    print STDERR "comparing ($aval->[0] cmp $val) at position $position of "
      . $#$handle . "\n"
	if $verbose & 128;
    return ($aval->[0] cmp $val) , $position;
  };


  my $pos = binary_search ( 0, $#$array, $key, $read, $array, 1 );

  # we could be pointing off the end..
  return undef unless defined $pos;
  return undef if $pos > $#$array;
  return @{$array->[$pos]};
}

sub _clean_filepath ($) {
  my $path=shift;
  # Now we clean up the filename.  For This we assume unix semantics.
  # These have been around for long enough that any sensible operating
  # system could have simply copied them.

  $path =~ s,/./,,g;

  #now chop away down references..

  # substitute a downchange (dirname/) followed by an upchange ( /../ )
  # for nothing.
  1 while $path =~ s,([^.]|(.[^.])|(..?))/+..($|/),,g ;

  # clean up multiple slashes

  $path =~ s,//,/,g;

  # delete leading slash

  $path =~ s,^/,,g;

  if ($path =~ m,(^|/)..($|/),) {
    croak "upreferences (/../) make ". $path." an unsafe path";
  }

  #what are the properties of the filename we can return..
  #any string which doesn't contain /.. (and refuse /.

  #now we untaint and do a check..

  my ($ret)= $path =~ m,( (?:                # directory name; xxx/ or filename; xxx
	                    (?:              # some filename ....
	                      (?:[^./][^/]+) #a filename with no dot
	                    |(?:.[^./][^/]+) #a filename starting with .
	                    |(?:..[^./][^/]+)#a filename starting with .. why bother?
	         )
	         (?:/|$)      # seperator to next directory name or end of filename
	      ) +
	    ),x;
  return $ret; #can be undef
}


sub url_to_file ($) {
  my $url=shift;
  defined $url or
    croak "usage url_to_file(<url>); missing url argument";
  $url =~ m/[a-z][a-z0-9-]+:/i or
    croak "usage url_to_file(<url>); not url_to_file($url)";
  @_ and croak "usage url_to_file(<url>); extra argument";


  my ($base, $infostruc) = _find_best_match(\@::infostruc_urls_sorted, $url);

  unless (defined $base and ( $url =~ m/^$base/ )) {
    #taint??
    $url=~s/[^A-Za-z\:\&\+\/\.]/\_/g;
    carp "url_to_file; can't convert '$url' not in an infostructure"
      unless $no_warn;
    return undef;
  }

  print STDERR "trying to map $url to editable object\n"
    if $verbose & 64;

  my $file_base=$infostruc->{file_base};

  #FIXME: we should search all possible infostructures for more general
  #candidates.  We are supposed to handle all file access safely, so
  #cases where there isn't supposed to be a file associated with a
  #page and we find a file name which is a script in a dynamic web
  #page should be okay

  #then again, maybe the user should choose so this is better.

  defined $file_base or do {
    warn "url $url is in an infostructure without a filebase";
    return undef;
  };

  #make the url relative to the base.

  $url =~ s/^$base//;

  my $relative=_clean_filepath($url);

  return undef unless defined $relative;
#  print STDERR "base $file_base relative $relative\n";

  $file_base =~ s,/$,,;
  #FIXME: filebase can contain a / so this can end up with //. do we care?
  return $file_base . '/' . $relative; #filebase should be an internal variable
}

=head2 file_to_url

C<filename_to_url> takes a correctly prepared filename as an argument.
It then does a binary search on a reverse sorted array of filebases bases.
It then uses infostructure definitions to convert the filename to a URL.

This function should untaint it's result because it should use the
infostructure definitions to ensure that we only do things to files we
are supposed to do things to.

=cut

#  Given any url, get us something we can edit in order to change the
#  resource referenced by that url.  Or not, if we can't.  In the case
#  that we can't, return undef.


#  N.B.  This will accept any filename which is within the infostructure
#  whatsoever.. it is possible that that includes more than you wish to
#  let people edit.

sub file_to_url ($) {
  my $file=shift;
  defined $file or
    croak "usage file_to_url(<file>); missing file argument";
  @_ and croak "usage file_to_url(<file>); extra argument";

  my ($base, $infostruc) = _find_best_match(\@::infostruc_files_sorted, $file);

  unless (defined $base and $file =~ m/^$base/) {
    #taint??
    $file=~s/[^A-Za-z\:\&\+\/\.]/\_/g;
    carp "file_to_url; can't convert '$file' not in an infostructure"
      unless $no_warn;
    return undef;
  }

  (my $url_base=$infostruc->{url_base} )
    or die "badly defined infostruc for file $base";


  print STDERR "trying to map $file to URL\n"
    if $verbose & 64;

  #make the url relative to the base.

  $file =~ s/^$base//;

  my $relative=_clean_filepath($file);

  return undef unless defined $relative;

  $relative =~ m,^/, and die "\$relative should be a relative url not $relative";
  $url_base =~ s,/$,,;
  return $url_base . '/' . $relative; #filebase should be an internal variable
}



1;
