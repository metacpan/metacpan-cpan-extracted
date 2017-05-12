########################
# SIMPLE COMPRESS:ZLIB #
########################

##package Compress'Zlib;
package LibZip::MyZlib ;

no warnings ;

BEGIN { $INC{'LibZip/MyZlib.pm'} = 1 if !$INC{'LibZip/MyZlib.pm'} ;}

#require DynaLoader;
@ISA = qw(DynaLoader);

$VERSION = "1.33" ;

## NO BOOT: Zlib will be inside executable (LibZipBin binary).
#DynaLoader::bootstrap LibZip::MyZlib $VERSION if !$NO_BOOT ;


sub ZLIB_VERSION { 1.1.4 }
sub DEF_WBITS { '' }
sub OS_CODE { '' }
sub MAX_MEM_LEVEL { 9 }
sub MAX_WBITS { 15 }
sub Z_ASCII { 1 }
sub Z_BEST_COMPRESSION { 9 }
sub Z_BEST_SPEED { 1 }
sub Z_BINARY { 0 }
sub Z_BUF_ERROR { -5 }
sub Z_DATA_ERROR { -3 }
sub Z_DEFAULT_COMPRESSION { -1 }
sub Z_DEFAULT_STRATEGY { 0 }
sub Z_DEFLATED { 8 }
sub Z_ERRNO { -1 }
sub Z_FILTERED { 1 }
sub Z_FINISH { 4 }
sub Z_FULL_FLUSH { 3 }
sub Z_HUFFMAN_ONLY { 2 }
sub Z_MEM_ERROR { -4 }
sub Z_NEED_DICT { 2 }
sub Z_NO_COMPRESSION { 0 }
sub Z_NO_FLUSH { 0 }
sub Z_NULL { 0 }
sub Z_OK { 0 }
sub Z_PARTIAL_FLUSH { 1 }
sub Z_STREAM_END { 1 }
sub Z_STREAM_ERROR { -2 }
sub Z_SYNC_FLUSH { 2 }
sub Z_UNKNOWN { 2 }
sub Z_VERSION_ERROR { -6 }


sub ParseParameters($@) {
    my ($default, @rest) = @_ ;
    my (%got) = %$default ;
    my (@Bad) ;
    my ($key, $value) ;
    my $sub = (caller(1))[3] ;
    my %options = () ;

    # allow the options to be passed as a hash reference or
    # as the complete hash.
    if (@rest == 1) {
        %options = %{ $rest[0] } ;
    }
    elsif (@rest >= 2) {
        %options = @rest ;
    }

    while (($key, $value) = each %options)
    {
	$key =~ s/^-// ;

        if (exists $default->{$key})
          { $got{$key} = $value }
        else
	  { push (@Bad, $key) }
    }
    
    if (@Bad) {
        my ($bad) = join(", ", @Bad) ;
    }

    return \%got ;
}

$deflateDefault = {
	'Level'	     =>	Z_DEFAULT_COMPRESSION(),
	'Method'     =>	Z_DEFLATED(),
	'WindowBits' =>	MAX_WBITS(),
	'MemLevel'   =>	MAX_MEM_LEVEL(),
	'Strategy'   =>	Z_DEFAULT_STRATEGY(),
	'Bufsize'    =>	4096,
	'Dictionary' =>	"",
	} ;
 
$deflateParamsDefault = {
	'Level'	     =>	Z_DEFAULT_COMPRESSION(),
	'Strategy'   =>	Z_DEFAULT_STRATEGY(),
	} ;
 
$inflateDefault = {
	'WindowBits' =>	MAX_WBITS(),
	'Bufsize'    =>	4096,
	'Dictionary' =>	"",
	} ;

sub inflateInit {
  my ($got) = ParseParameters($inflateDefault, @_) ;
  _inflateInit($got->{WindowBits}, $got->{Bufsize}, $got->{Dictionary}) ;
}

#############################
# LIBZIP::MYZLIB::TOOLS #
#############################

package LibZip::MyZlib::tools ;

use LibZip::CORE ;

############
# MY_UNTAR #
############

sub my_untar {
  my ( $tar_file ) = @_ ;

  my $tar = (length($tar_file) < 1000 && -e $tar_file) ? cat($tar_file) : $tar_file ;
  my $lng = length($tar) ;

  my %files ;
  my ( $sz , $name ) ;
  for(my $i = 0 ; $i < $lng ;) {
    $sz = unpack("V", substr($tar , $i , 4) ) ; $i += 4 ;
    $name = substr($tar , $i , $sz) ; $i += $sz ;
    $sz = unpack("V", substr($tar , $i , 4) ) ; $i += 4 ;
    $files{$name} = my_uncompress( split_bloks( substr($tar , $i , $sz) ) ) ; $i += $sz ;
  }
  
  return \%files ;
}

################
# MY_SAVE_TREE #
################

sub my_save_tree {
  my $dir = shift ;
  my $tree = shift ;
  
  mkpath($dir) if ( !-d $dir );
  
  foreach my $Key (sort keys %$tree ) {
    my $name = "$dir/$Key" ;
    my ($dirName) = ( $name =~ /^(.*?)[\\\/]*[^\\\/]+$/s );
    mkpath($dirName) if ( !-d $dirName ) ;
    save($name , $$tree{$Key}) ;
  }
}

##########
# MKPATH #
##########

sub mkpath {
  my($paths) = @_;
  $paths = [$paths] unless ref $paths ;
  my $mode = 0775 ;
  
  local($")=$Is_MacOS ? ":" : "/";

  my(@created,$path);
  foreach $path (@$paths) {
    $path .= '/' if $^O eq 'os2' and $path =~ /^\w:\z/s ;
    next if -d $path ;
    my ($parent) = ( $path =~ /^(.*?)[\\\/]*[^\\\/]+$/s );
    unless (-d $parent or $path eq $parent) { push(@created,mkpath($parent)) ;}
    unless (mkdir($path,$mode)) { my $e = $! ;}
    push(@created, $path) ;
  }
  @created ;
}

###############
# SPLIT_BLOKS #
###############

sub split_bloks {
  my $sz_blk_size = unpack("V", substr($_[0] , 0 , 4) ) ;
  my $blk_size = substr($_[0] , 4 , $sz_blk_size) ;
  
  my $total = 4 + $sz_blk_size ;
  
  $blk_size = my_uncompress($blk_size) ;
  
  my (@sizes) = ( $blk_size =~ /(....)/gs );

  my $i = $sz_blk_size + 4 ;
  
  my @blks ;
  foreach my $sizes_i ( @sizes ) {
    $sizes_i = unpack("V", $sizes_i ) ;
    push(@blks , substr($_[0] , $i , $sizes_i) ) ;
    $i += $sizes_i ;
  }

  return @blks ;
}


###################
# PURE_UNCOMPRESS #
###################

sub my_uncompress {
  my ( @blks ) = @_ ;
  package LibZip::MyZlib ;

  my $uncompressed ;
  
  foreach my $blks_i ( @blks ) {
    my ($d, $status) = inflateInit( -WindowBits => - MAX_WBITS ) ;
    my ($out, $status) = $d->inflate( $blks_i ) ;
    $uncompressed .= $out ;
  }
  
  return $uncompressed ;
}

##########
# BASE64 #
##########

sub my_uncompress_base64 { return my_uncompress( split_bloks( _decode_base64_pure_perl($_[0]) ) ) ;}

sub my_untar_base64 { return my_untar( _decode_base64_pure_perl($_[0]) ) ;}

############################
# _DECODE_BASE64_PURE_PERL #
############################

sub _decode_base64_pure_perl {
  local($^W) = 0 ;
  my $str = shift ;
  my $res = "";
  $str =~ tr|A-Za-z0-9+=/||cd ;
  if (length($str) % 4) {
    #require Carp;
    #Carp::carp("Length of base64 data not a multiple of 4")
  }
  $str =~ s/=+$//;
  $str =~ tr|A-Za-z0-9+/| -_|;
  while ($str =~ /(.{1,60})/gs) {
    my $len = chr(32 + length($1)*3/4);
    $res .= unpack("u", $len . $1 );
  }
  $res;
}

#######
# END #
#######

1;

