use v5.36;

package HTTP::State::Cookie;
no warnings "experimental";

# Logging
#
use Log::ger; 
use Log::OK;



use builtin qw<trim>;


my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my $i=0;
my %months= map {$_,$i++} @months;

$i=0;
my @days= qw(Sun Mon Tue Wed Thu Fri Sat);
my %days= map {$_,$i++} @days;

my @names;
my @same_site_names;
#my @values;
my %const_names;
my @pairs;
my @same_site_pairs;

my %reverse; 
my %same_site_reverse;
my @forward;

BEGIN {
	 @names=qw<
		Undef
		Name
		Value
		Expires
		Max-Age
		Domain
		Path
		Secure
		HttpOnly
		SameSite
    Partitioned
    
    Creation_Time
    Last_Access_Time
    Persistent
    HostOnly
    Key
	>;

  #@values= 0 .. @names-1;

  @same_site_names = qw<Undef Lax Strict None Default>;

  for my ($i)(0..$#names){
		$const_names{("COOKIE_".uc $names[$i])=~tr/-/_/r}= $i;
    $reverse{lc $names[$i]}=$i;
  }
  $reverse{undef}=0;			#catching

  #Additional keys in hash for HTTP::CookieJar support


  for my ($i)(0..$#same_site_names){
    $const_names{"SAME_SITE_".uc $same_site_names[$i]}=$i;
    $same_site_reverse{lc $same_site_names[$i]}=$i;
  }
  $same_site_reverse{undef}=0;			#catching
}

use constant::more \%const_names;


use Export::These 
  "cookie_struct",
  constants=>["cookie_struct", keys %const_names],
  encode=>[qw<cookie_struct encode_set_cookie encode_cookies hash_set_cookie>],
  decode=>[qw<cookie_struct decode_set_cookie decode_cookies>],
  export_ok=>["hash_set_cookie"],
  all=>
  [keys(%const_names),qw<encode_cookies encode_set_cookie decode_set_cookie decode_cookies cookie_struct hash_set_cookie>];


use Time::Local qw<timelocal_modern>;

my $tz_offset;


BEGIN {
  # Low memory timezone offset calculation.
  # Removes the need to load Time::Piece just for timezone offset
  my $now=time;
  my @g=gmtime $now;
  my @l=localtime $now;
  my $gs=$g[0]+ $g[1]*60 + $g[2]*3600 + $g[3]*86400;
  my $ls=$l[0]+ $l[1]*60 + $l[2]*3600 + $l[3]*86400; 
  $tz_offset=$ls-$gs;
}

use constant::more TZ_OFFSET=>$tz_offset;


# Expects the name and value as the first pair of arguments
sub cookie_struct {

  no warnings "experimental";
  my @c=(1, shift, shift);  # Reuse the first field as string/int marker


  die "Cookie must have a name" unless $c[COOKIE_NAME];

  if(@_){
    no warnings "uninitialized";
    no warnings "numeric";
    if($c[$_[0]]){
      # anticipate keys provided as string.
      #
      # If the first remaining argument is numeric (field constant) will be an undef value
      # which when used in numeric constant will be 0. The $c[0] is set to one which is true
      # which means we anticipate string names
      for my ($k, $v)(@_){
        $c[$reverse{lc $k}]=$v;
      }
    }
    else{
      # keys assumed to be integer constants
      # 
      for my ($k, $v)(@_){
        $c[$k]=$v;
      }
    }


    $c[COOKIE_EXPIRES]-=TZ_OFFSET if defined $c[COOKIE_EXPIRES];
    $c[COOKIE_DOMAIN]=scalar reverse lc $c[COOKIE_DOMAIN] if $c[COOKIE_DOMAIN];

    $c[COOKIE_SAMESITE]=$same_site_reverse{lc$c[COOKIE_SAMESITE]};
    $c[COOKIE_HOSTONLY]//=0;

  }

  $c[COOKIE_NAME]//="";
  $c[COOKIE_VALUE]//="";

  # Remove any extra fields added in haste
  #
  #splice @c, COOKIE_KEY+1;

  \@c;
}


# Supports a simple scalar or an array ref of simple scalars to parse/decode
sub decode_cookies {
  no warnings "experimental";
  my @values= map trim($_),           #trim leading /trailing white space 
              map split("=", $_, 2),  #Split fields into  KV pairs
              split /;\s*/, ref($_[0])
                ? join("; ", $_[0]->@*)
                : $_[0];    #Split input into fields
	@values;
}

# Returns a newly created cookie struct from a Set-Cookie string. Does not
# validate or create default values of attributess. Only processes what is
# given
#
sub decode_set_cookie{
  return undef unless $_[0];
  no warnings "experimental";
  # $string, converter
  my $input=$_[0];
	my $key;
	my $value;
	my @values;
	my $first=1;
  my @fields;

  #Value needs to be the first field 

  my $index=index $input, ";";
  my $name_value;
  if($index>=0){
    # at least one ";"  was found
    $name_value=substr $input,0, $index;
    substr $input, 0, $index+1, "";
    
  }
  else {
    # No ";" found
    $name_value=$input;
    $input="";
  }
 
  Log::OK::TRACE and log_trace " decoding cookie name: name value: $name_value";

  $index=index $name_value, "=";

  #Abort unless has a name
  return unless $index >0;

  $values[1]= substr $name_value, 0, $index;
  $values[2]= substr $name_value, $index+1;
  Log::OK::TRACE and log_trace " decoding cookie name: $values[1] value:$values[2]";


  # trip whitespace
  $values[1]=trim($values[1]);
  $values[2]=trim($values[2]);

  # TODO: test for controll characters
  


  Log::OK::TRACE and log_trace " decoding cookie name: $values[1] value:$values[2]";

  #Process attributes if input remaining;
  return \@values unless $input;

  @fields=split /;\s*/, $input;

	for(@fields){

		($key, $value)=split "=", $_, 2;

    $key=trim($key);
    $value=trim($value) if $value;

    # Attributes are processed with case insensitive names
    #
    $key=lc $key;

    # Look up the value key value pair
    # unkown values are stored in the undef => 0 position
    $values[$reverse{$key}]=$value//1;
	}

  # nuke unkown value
  $values[0]=undef;


  # Fix the date. Date is stored in seconds internally
  #
  for($values[COOKIE_EXPIRES]//()){
    Log::OK::TRACE and log_trace " converting cookie expires from stamp to epoch";
    my ($wday_key, $mday, $mon_key, $year, $hour, $min, $sec, $tz)=
     /([^,]+), (\d+).([^-]{3}).(\d{4}) (\d+):(\d+):(\d+) (\w+)/;
     #TODO support parsing of other deprecated data formats

    if(70<=$year<=99){
      $year+=1900;
    }
    elsif(0<=$year<=69){
      $year+=2000;
    }
    else{
      #year as is
    }
    #NOTE: timelocal_modern DOES NOT add/subtract time offset. Which is what we want
    #as the time is already gmt
    #
    $_ = timelocal_modern($sec, $min, $hour, $mday, $months{$mon_key}, $year);
  }

  # adjust creation and last modified times
  if(defined $_[1]){
    $values[COOKIE_CREATION_TIME]-=$_[1] if $values[COOKIE_CREATION_TIME];
    $values[COOKIE_LAST_ACCESS_TIME]-=$_[1] if $values[COOKIE_LAST_ACCESS_TIME];

  }


  # Fix leading/trailing dot
  for($values[COOKIE_DOMAIN]//()){
    s/\.$//;
    s/^\.//;
    $_ = scalar reverse $_;
  }

  # Fix same site
  
  for($values[COOKIE_SAMESITE]//()){
    $_=$same_site_reverse{lc $_};
  }
  # Ensure host only is defined
  $values[COOKIE_HOSTONLY]//=0;


  

  \@values;
}

# Encodes KV pairs from supplied cookie structs
sub encode_cookies {
  join "; ", map "$_->[COOKIE_NAME]=".($_->[COOKIE_VALUE]//""), @_;
}

sub encode_set_cookie {
  my ($cookie, $store_flag, $partition_key)=@_;
	Log::OK::DEBUG and log_debug "Serializing set cookie";	

  # Start with name and value
  #
	my $string= "$cookie->[COOKIE_NAME]=".($cookie->[COOKIE_VALUE]//"");			



	
  # Format date for expires. Internally the cookie structure stores this value
  # in terms of GMT.
  # Again only add the attribute if value is defined
  #
  #for($cookie->[COOKIE_PERSISTENT] && 
  for($cookie->[COOKIE_EXPIRES]//()){
      #
      #NOTE: localtime doesn't add/subtract offsets. This is what we want as it was manually adjusted.
      #
      my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =localtime $_;
      $string.="; $names[COOKIE_EXPIRES]=$days[$wday], ".sprintf("%02d",$mday)." $months[$mon] ".($year+1900) .sprintf(" %02d:%02d:%02d", $hour,$min,$sec)." GMT";
	}
  # Reverse the cookie domain (stored backwards) if preset. Don't add the attribute
  # if not defined.
  #
  $string.= "; $names[COOKIE_DOMAIN]=".scalar reverse $_ 
    for $cookie->[COOKIE_DOMAIN]//();

  # Do Attributes with needing values.  Only add them if the attribute is
  # defined
  #
	for my $index (COOKIE_MAX_AGE, COOKIE_PATH){
		for($cookie->[$index]//()){
			$string.="; $names[$index]=$_";
		}
	}


  # Do flags (attibutes with no values)
  #
	$string.="; $names[COOKIE_SECURE]" if defined $cookie->[COOKIE_SECURE];				
	$string.="; $names[COOKIE_HTTPONLY]" if defined $cookie->[COOKIE_HTTPONLY];

  if(defined $store_flag){
    # If asked for storage format, give internal values
    #
	  $string.="; Creation_Time=".($cookie->[COOKIE_CREATION_TIME]+$store_flag);
	  $string.="; Last_Access_Time=".($cookie->[COOKIE_LAST_ACCESS_TIME]+$store_flag);
	  $string.="; HostOnly" if $cookie->[COOKIE_HOSTONLY];				
    $string.="; Partitioned=$partition_key" if $cookie->[COOKIE_PARTITIONED] and $partition_key;   #Store the partition key in the partitioned field
    #$string.="; Persistent" if $cookie->[COOKIE_PERSISTENT];
  }
  $string.="; $names[COOKIE_SAMESITE]=".$same_site_names[$cookie->[COOKIE_SAMESITE]] if $cookie->[COOKIE_SAMESITE];

	$string;

}

#mosty for compatibility with HTTP::CookieJar 'cookies_for' method
sub hash_set_cookie{
  my ($cookie, $store_flag)=@_;
	my %hash=(name=>$cookie->[COOKIE_NAME], value=>$cookie->[COOKIE_VALUE]);

  # Reverse the cookie domain (stored backwards) if preset. Don't add the attribute
  # if not defined.
  #
  $hash{domain}=scalar reverse $_ 
    for $cookie->[COOKIE_DOMAIN]//();

  # Do Attributes with needing values.  Only add them if the attribute is
  # defined
  #
  $hash{maxage}=$_ for $cookie->[COOKIE_MAX_AGE]//();
  $hash{path}=$_ for $cookie->[COOKIE_PATH]//();
  $hash{samesite}=$_ for $cookie->[COOKIE_SAMESITE]//();

	
  # Format date for expires. Internally the cookie structure stores this value
  # in terms of GMT.
  # Again only add the attribute if value is defined
  #
	for($cookie->[COOKIE_PERSISTENT] && $cookie->[COOKIE_EXPIRES]//()){
      my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =localtime $_;
      $hash{expires}="$days[$wday], ".sprintf("%02d",$mday)." $months[$mon] ".($year+1900) .sprintf(" %02d:%02d:%02d",$hour,$min,$sec)." GMT";
	}

  # Do flags (attibutes with no values)
  #
	$hash{secure}=1 if defined $cookie->[COOKIE_SECURE];				
	$hash{httponly}=1 if defined $cookie->[COOKIE_HTTPONLY];

  if(defined $store_flag){
    # If asked for storage format, give internal values
    #
	  $hash{hostonly}=1 if $cookie->[COOKIE_HOSTONLY];				
	  $hash{creation_time}=($cookie->[COOKIE_CREATION_TIME]+$store_flag);
	  $hash{access_time}=($cookie->[COOKIE_LAST_ACCESS_TIME]+$store_flag);
  }

	\%hash;
}
1;
