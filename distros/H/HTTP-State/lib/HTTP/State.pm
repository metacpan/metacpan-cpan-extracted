use v5.36;
package HTTP::State;


our $VERSION="v0.1.2";

# Logging
#
use Log::ger; 
use Log::OK;

# Object system. Will use feature class asap
#
use Object::Pad;

use HTTP::State::Cookie ":all";



# Fast Binary Search subroutines
#
use List::Insertion {type=>"string", duplicate=>"left", accessor=>"->[".COOKIE_KEY."]"};


# Public suffix list loaded when needed
#
#use Mozilla::PublicSuffix qw<public_suffix>;

# Date 
#use Time::Piece;
#my $tz_offset=Time::Piece->localtime->tzoffset->seconds;

my $tz_offset=HTTP::State::Cookie::TZ_OFFSET;

# Constant flags foor User agent context
#
use constant::more FLAG_SAME_SITE=>0x01;      # Indicate request is same-site/cross-site
use constant::more FLAG_TYPE_HTTP=>0x02;      # Indicate request is HTTP/non-HTTP
use constant::more FLAG_SAFE_METH=>0x04;      # Indicate request is safe method
use constant::more FLAG_TOP_LEVEL=>0x04;      # Indicate top level navigation



use Export::These flags=>[qw<FLAG_SAME_SITE FLAG_TYPE_HTTP FLAG_SAFE_METH FLAG_TOP_LEVEL>];


class HTTP::State;

no warnings "experimental";
field $_get_cookies_sub :reader;  # Main cookie retrieval routine, reference.
field @_cookies; # An array of cookie 'structs', sorted by the COOKIE_KEY field
field %_partitions;
field $_suffix_cache;# :param=undef; #Hash ref used as cache
field $_public_suffix_sub :param=undef;        # Sub used for public suffix lookup.
field $_second_level_domain_sub;
#field $_default_same_site :param="None";

field $_lax_allowing_unsafe :param=undef;
field $_lax_allowing_unsafe_timeout :param=120;
field $_retrieve_sort :param=undef;

field $_max_expiry :param=400*24*3600; 

field $_default_flags :param=FLAG_SAME_SITE|FLAG_TYPE_HTTP|FLAG_SAFE_METH;


field %_sld_cache;

BUILD{
  # Create the main lookup sub
  $self->_make_get_cookies;
  unless($_public_suffix_sub){
    require Mozilla::PublicSuffix;  
    $_public_suffix_sub=\&Mozilla::PublicSuffix::public_suffix;
  }
  $_suffix_cache//={};
  $_second_level_domain_sub=sub {
    my $domain=$_[0];
    my $highest="";
    my $suffix=$_suffix_cache->{$domain}//=&$_public_suffix_sub;


    if($suffix){
      substr($domain, -(length($suffix)+1))="";

      if($domain){
        my @labels=split /\./, $domain;
        $highest=pop(@labels).".$suffix";
      }
    }
    $highest;

  };
}
  
sub _path_match {
  my($path, $cookie)=@_;

  # Process path matching as per section 5.1.4 in RFC 6265
  #
  $path||="/";    #TODO find a reference to a standard or rfc for this
  Log::OK::TRACE and log_trace "PATH: $path";
  Log::OK::TRACE and log_trace "Cookie PATH: $_->[COOKIE_PATH]";
  my $path_ok;
  if($path eq $cookie->[COOKIE_PATH]){
    $path_ok=1;
  }

  elsif (substr($cookie->[COOKIE_PATH], -1, 1) eq "/"){
    # Cookie path ends in a slash?
    $path_ok=index($path, $cookie->[COOKIE_PATH])==0  # Yes, check if cookie path is a prefix
  }
  elsif(substr($path,length($cookie->[COOKIE_PATH]), 1) eq "/"){
    $path_ok= 0==index $path, $cookie->[COOKIE_PATH];
  }
  else {
    # Not a  path match
    $path_ok=undef;
  }
  Log::OK::TRACE and log_trace "Path ok: $path_ok";
  $path_ok;
}

#returns self for chaining


method store_cookies{
  my ($request_uri, $partition_key, $flags, @cookies)=@_;
  #TODO: fix this
  $flags//=$_default_flags;
  Log::OK::TRACE and log_trace __PACKAGE__. " store_cookies";
  Log::OK::TRACE and log_trace __PACKAGE__. " ".join ", ", caller;
  Log::OK::TRACE and log_trace __PACKAGE__. " $request_uri, $flags, @cookies";

  return $self unless @cookies;
  # Parse the request_uri
  #
  #
 
    my $index;
    my $host;
    my $path;
    my $authority;
    my $scheme;

    $index=index $request_uri, "://";
    $scheme=substr $request_uri, 0, $index, "";
    substr($request_uri,0, 3)="";
   
    $index=index $request_uri, "/", $index;
    if($index>0){
      #have path
      $authority=substr $request_uri, 0, $index, "";
      $path=$request_uri;
    }
    else {
      #no path
      $authority=$request_uri;
      $path="";
    }

    # Parse out authority if username/password is provided
    $index=index($authority, "@");
    $authority= $index>0 
      ?substr $authority, $index+1
      :$authority;

    # Find the host
    $index=index $authority, ":";
    $host=$index>0 
      ?  substr $authority, 0, $index
      : $authority;

    die "URI format error" unless $scheme and $host;



  my $time=time-$tz_offset; #Cache time. Translate  to GMT

  # Iterate over the cookies supplied
  SET_COOKIE_LOOP:
  for my $c_ (@cookies){
    # Parse or copy the input
    my $c;
    my $ref=ref $c_;
    if($ref eq "ARRAY"){
      # Assume a struct 
      $c=[@$c_];  #Copy
    }
    else {
      # Assume a string
      $c=decode_set_cookie($c_);
    }
    next unless $c;




    #1.
    # A user agent MAY ignore a received cookie in its entirety. See Section 5.3.

    #2.
    # If cookie-name is empty and cookie-value is empty, abort these steps
    # and ignore the cookie entirely.
    
    #3.
    # If the cookie-name or the cookie-value contains a %x00-08 / %x0A-1F /
    # %x7F character (CTL characters excluding HTAB), abort these steps and
    # ignore the cookie entirely.


    #4. If the sum of the lengths of cookie-name and cookie-value is more than
    #4096 octets, abort these steps and ignore the cookie entirely
    next if (length($c->[COOKIE_NAME])+ length($c->[COOKIE_VALUE]))>4096;
    Log::OK::TRACE and log_trace __PACKAGE__. " Step 1, 2, 3, 4 OK";

    # 5. Create a new cookie with name cookie-name, value cookie-value. Set the
    #creation-time and the last-access-time to the current date and time.
    $c->[COOKIE_LAST_ACCESS_TIME]=$c->[COOKIE_CREATION_TIME]=$time;
    Log::OK::TRACE and log_trace __PACKAGE__. " Step 5 OK";

    # 6.
    # If the cookie-attribute-list contains an attribute with an attribute-name
    # of "Max-Age":
      # 1.
      # Set the cookie's persistent-flag to true
      #
      # 2. 
      # Set the cookie's expiry-time
      # to attribute-value of the last attribute in the cookie-attribute-list
      # with an attribute-name of "Max-Age".
    #
    # Otherwise, if the cookie-attribute-list contains an attribute with an
    # attribute-name of "Expires" (and does not contain an attribute with an
    # attribute-name of "Max-Age"):
      # 1.
      # Set the cookie's persistent-flag to true.
      #
      # 2.
      # Set the cookie's expiry-time to attribute-value of the last attribute
      # in the cookie-attribute-list with an attribute-name of "Expires".
      #
    #Otherwise:
      # 1.
      # Set the cookie's persistent-flag to false.
      # 
      # 2.
      # Set the cookie's expiry-time to the latest representable date.

    if(defined $c->[COOKIE_MAX_AGE]){
      $c->[COOKIE_PERSISTENT]=1;
      $c->[COOKIE_EXPIRES]=$time+$c->[COOKIE_MAX_AGE]; 
      Log::OK::TRACE and log_trace "max age set: $c->[COOKIE_MAX_AGE]";
    }
    elsif(defined $c->[COOKIE_EXPIRES]){
      $c->[COOKIE_PERSISTENT]=1;
      # expires already in required format 
    }
    else{
      $c->[COOKIE_PERSISTENT]=undef;
      $c->[COOKIE_EXPIRES]=$time+$_max_expiry;
      #400*24*3600; #Mimic chrome for maximum date

    }

    Log::OK::TRACE and log_trace "Expiry set to: $c->[COOKIE_EXPIRES]";
    Log::OK::TRACE and log_trace __PACKAGE__. " Step 6 OK";

    #7.
    #If the cookie-attribute-list contains an attribute with an attribute-name of "Domain":
      #1.
      #Let the domain-attribute be the attribute-value of the last attribute in
      #the cookie-attribute-list with both an attribute-name of "Domain" and an
      #attribute-value whose length is no more than 1024 octets. (Note that a
      #leading %x2E ("."), if present, is ignored even though that character is
      #not permitted.)
      #
    #Otherwise:
      #1.
      #Let the domain-attribute be the empty string.

    #8.
    #If the domain-attribute contains a character that is not in the range of
    #[USASCII] characters, abort these steps and ignore the cookie entirely.
    #

    #9.
    #If the user agent is configured to reject "public suffixes" and the
    #domain-attribute is a public suffix:
      #1.
      #If the domain-attribute is identical to the canonicalized request-host:
        #1. 
        #Let the domain-attribute be the empty string.
      #Otherwise:
        #1.
        #Abort these steps and ignore the cookie entirely.

      #NOTE: This step prevents attacker.example from disrupting the integrity
      #of site.example by setting a cookie with a Domain attribute of
      #"example".








    # Use the host as domain if none specified

    # Process the domain of the cookie. set to default if no explicitly set
    #
    my $rhost=scalar reverse $host;
    my $sld;
    my $suffix;
    # DO a public suffix check on cookies. Need to ensure the domain for the cookie is NOT a suffix.
    # This means we want a 'second level domain'
    #
    if($c->[COOKIE_DOMAIN]){
      $suffix=$_suffix_cache->{$c->[COOKIE_DOMAIN]}//=scalar reverse 
        $_public_suffix_sub->(scalar reverse $c->[COOKIE_DOMAIN]);

      Log::OK::TRACE and log_trace "Looking up $c->[COOKIE_DOMAIN]=>$suffix";
      if($suffix and $suffix eq $c->[COOKIE_DOMAIN]){
        if($rhost eq $c->[COOKIE_DOMAIN]){

          Log::OK::TRACE and log_trace " Domain is equal to host, which is a suffix";
          $c->[COOKIE_DOMAIN]="";
        }
        else {
          Log::OK::TRACE and log_trace "Domain is public suffix. reject";
          next;
        }
      }
    }
    Log::OK::TRACE and log_trace __PACKAGE__. " Step 7, 8, 9 OK";

    #10
    #If the domain-attribute is non-empty:
      #If the canonicalized request-host does not domain-match the domain-attribute:
        #1.
        #Abort these steps and ignore the cookie entirely.
      #Otherwise:
        #1
        #Set the cookie's host-only-flag to false.
        #2
        #Set the cookie's domain to the domain-attribute.
    #Otherwise:
      #1
      #Set the cookie's host-only-flag to true.
      #2
      #Set the cookie's domain to the canonicalized request-host.


    if($c->[COOKIE_DOMAIN]){
      if(0==index($rhost, $c->[COOKIE_DOMAIN])){ 
        # Domain must be at least substring (parent domain).
        $c->[COOKIE_HOSTONLY]=0;
      }
      else{
        # Reject. no domain match
        Log::OK::TRACE and log_trace __PACKAGE__."::store_cookie domain invalid";
        next;
      }
    }
    else{
      Log::OK::TRACE and log_trace __PACKAGE__. " No domain set for cookie";
      $c->[COOKIE_HOSTONLY]=1;
      $c->[COOKIE_DOMAIN]=$rhost;
    }

    Log::OK::TRACE and log_trace __PACKAGE__. " Step 10 OK";

    #11.
    #If the cookie-attribute-list contains an attribute with an attribute-name
    #of "Path", set the cookie's path to attribute-value of the last attribute
    #in the cookie-attribute-list with both an attribute-name of "Path" and an
    #attribute-value whose length is no more than 1024 octets. Otherwise, set
    #the cookie's path to the default-path of the request-uri.

    $c->[COOKIE_PATH]//="";
    next if length($c->[COOKIE_PATH])>1024;

    if( length($c->[COOKIE_PATH])==0 or  substr($c->[COOKIE_PATH], 0, 1) ne "/"){
      # Calculate default
      if(length($path)==0 or substr($path, 0, 1 ) ne "/"){
        $path="/";
      }
      
      # Remove right / if present
      if(length($path) >1){
        my @parts=split "/", $path;
        pop @parts;
        $c->[COOKIE_PATH]=join "/", @parts;
      }
      else {
        $c->[COOKIE_PATH]=$path;
      }
    }
    Log::OK::TRACE and log_trace __PACKAGE__. " Step 11 OK";
    #12
    #If the cookie-attribute-list contains an attribute with an attribute-name
    #of "Secure", set the cookie's secure-only-flag to true. Otherwise, set the
    #cookie's secure-only-flag to false.

    #13
    #If the scheme component of the request-uri does not denote a "secure"
    #protocol (as defined by the user agent), and the cookie's secure-only-flag
    #is true, then abort these steps and ignore the cookie entirely.


    next if $c->[COOKIE_SECURE] and ($scheme ne "https");
    Log::OK::TRACE and log_trace __PACKAGE__. " Step 12, 13 OK";

    #14
    #If the cookie-attribute-list contains an attribute with an attribute-name
    #of "HttpOnly", set the cookie's http-only-flag to true. Otherwise, set the
    #cookie's http-only-flag to false.

    #15
    #If the cookie was received from a "non-HTTP" API and the cookie's
    #http-only-flag is true, abort these steps and ignore the cookie entirely.

    next if ($c->[COOKIE_HTTPONLY] and !($flags & FLAG_TYPE_HTTP));


    Log::OK::TRACE and log_trace __PACKAGE__. " Step 14, 15 OK";

    #16
    #If the cookie's secure-only-flag is false, and the scheme component of
    #request-uri does not denote a "secure" protocol, then abort these steps
    #and ignore the cookie entirely if the cookie store contains one or more
    #cookies that meet all of the following criteria:
    #
      #1
      #Their name matches the name of the newly-created cookie.
      #2
      #Their secure-only-flag is true.
      #3
      #Their domain domain-matches the domain of the newly-created cookie, or vice-versa.
      #4
      #The path of the newly-created cookie path-matches the path of the existing cookie.
      #
    #Note: The path comparison is not symmetric, ensuring only that a
    #newly-created, non-secure cookie does not overlay an existing secure
    #cookie, providing some mitigation against cookie-fixing attacks. That is,
    #given an existing secure cookie named 'a' with a path of '/login', a
    #non-secure cookie named 'a' could be set for a path of '/' or '/foo', but
    #not for a path of '/login' or '/login/en'.


    my $part;
    if(!$c->[COOKIE_SECURE] and $scheme ne "https"){
      
      # get the second level domain to act as base to start search
      $sld//=$_sld_cache{$c->[COOKIE_DOMAIN]}//=scalar reverse $_second_level_domain_sub->(scalar reverse $c->[COOKIE_DOMAIN]);
      next unless defined $sld;


      # IF partitions are enabled and the cookie is partitioned then lookup partition
      # otherwise use normal cookies array
      #
      my @parts=(($partition_key and $c->[COOKIE_PARTITIONED])?$_partitions{$partition_key}//=[]: \@_cookies);
      for my $part (@parts){
        my $index=search_string_left $sld, $part;

        $index=@$part if $index<@$part and (index($part->[$index][COOKIE_KEY], $sld)==0);
        my $found;
        local $_;
        while(!$found and $index<@$part){
          $_=$part->[$index];
          #exit the inner loop if the SLD is not a prefix of the current cookie key
          last if index $_->[COOKIE_KEY], $sld;

          next SET_COOKIE_LOOP if $_->[COOKIE_SECURE]
          and $_->[COOKIE_NAME] eq $c->[COOKIE_NAME]    #name match
          and (index($_->[COOKIE_DOMAIN], $sld)==0 or index($sld, $_->[COOKIE_DOMAIN])==0)        # symmetric match
          and _path_match $c->[COOKIE_PATH], $_;    #path match

          $index++;
        }
      }
    }
    Log::OK::TRACE and log_trace __PACKAGE__. " Step 16 OK";

    #17
    #If the cookie-attribute-list contains an attribute with an attribute-name
    #of "SameSite", and an attribute-value of "Strict", "Lax", or "None", set
    #the cookie's same-site-flag to the attribute-value of the last attribute
    #in the cookie-attribute-list with an attribute-name of "SameSite".
    #Otherwise, set the cookie's same-site-flag to "Default".

    $c->[COOKIE_SAMESITE]//=SAME_SITE_DEFAULT;#"Default";#$_default_same_site;

    Log::OK::TRACE and log_trace __PACKAGE__. " Step 17 OK";

    #18
    #If the cookie's same-site-flag is not "None":
      #1
      #If the cookie was received from a "non-HTTP" API, and the API was called
      #from a navigable's active document whose "site for cookies" is not
      #same-site with the top-level origin, then abort these steps and ignore
      #the newly created cookie entirely.
      #2
      #If the cookie was received from a "same-site" request (as defined in
      #Section 5.2), skip the remaining substeps and continue processing the
      #cookie.
      #3
      #If the cookie was received from a request which is navigating a
      #top-level traversable [HTML] (e.g. if the request's "reserved client" is
      #either null or an environment whose "target browsing context"'s
      #navigable is a top-level traversable), skip the remaining substeps and
      #continue processing the cookie.
      #
      #Note: Top-level navigations can create a cookie with any SameSite value,
      #even if the new cookie wouldn't have been sent along with the request
      #had it already existed prior to the navigation.
      #4
      #Abort these steps and ignore the newly created cookie entirely.

    if($c->[COOKIE_SAMESITE] != SAME_SITE_NONE){
      if (not $flags & FLAG_TYPE_HTTP and not $flags & FLAG_SAME_SITE){
        next;
      }
      elsif($flags & FLAG_SAME_SITE){
        # continue
      }
      elsif($flags & FLAG_TOP_LEVEL){
        # continue
      }
      else {
        next;
      }
    }

    Log::OK::TRACE and log_trace __PACKAGE__. " Step 18 OK";

    #19
    #If the cookie's "same-site-flag" is "None", abort these steps and ignore
    #the cookie entirely unless the cookie's secure-only-flag is true.
    next if $c->[COOKIE_SAMESITE] == SAME_SITE_NONE and !$c->[COOKIE_SECURE];

    Log::OK::TRACE and log_trace __PACKAGE__. " Step 19 OK";

    #20
    #If the cookie-name begins with a case-insensitive match for the string
    #"__Secure-", abort these steps and ignore the cookie entirely unless the
    #cookie's secure-only-flag is true.
    #
    next if $c->[COOKIE_NAME]=~/^__Secure-/aai and !$c->[COOKIE_SECURE];

    Log::OK::TRACE and log_trace __PACKAGE__. " Step 20 OK";

    #21
    #If the cookie-name begins with a case-insensitive match for the string
    #"__Host-", abort these steps and ignore the cookie entirely unless the
    #cookie meets all the following criteria:
      #1
      #The cookie's secure-only-flag is true.
      #2
      #The cookie's host-only-flag is true.
      #3
      #The cookie-attribute-list contains an attribute with an attribute-name
      #of "Path", and the cookie's path is /.

    next if $c->[COOKIE_NAME]=~/^__Host-/aai and !($c->[COOKIE_SECURE] and
      ($c->[COOKIE_PATH] eq "/") and $c->[COOKIE_HOSTONLY]);

    Log::OK::TRACE and log_trace __PACKAGE__. " Step 21 OK";

    #22
    #If the cookie-name is empty and either of the following conditions are
    #true, abort these steps and ignore the cookie:
      #1
      #the cookie-value begins with a case-insensitive match for the string
      #"__Secure-"
      #2
      #the cookie-value begins with a case-insensitive match for the string
      #"__Host-"
    next if !$c->[COOKIE_NAME] and ($c->[COOKIE_VALUE]=~/^__Host-/i or $c->[COOKIE_VALUE]=~/^__Secure-/i);

    Log::OK::TRACE and log_trace __PACKAGE__. " Step 22 OK";
 
    #23
    #If the cookie store contains a cookie with the same name, domain,
    #host-only-flag, and path as the newly-created cookie:
      #1
      #Let old-cookie be the existing cookie with the same name, domain,
      #host-only-flag, and path as the newly-created cookie. (Notice that this
      #algorithm maintains the invariant that there is at most one such
      #cookie.)
      #2
      #If the newly-created cookie was received from a "non-HTTP" API and the
      #old-cookie's http-only-flag is true, abort these steps and ignore the
      #newly created cookie entirely.
      #3
      #Update the creation-time of the newly-created cookie to match the creation-time of the old-cookie.
      #4
      #Remove the old-cookie from the cookie store.

    #24
    #Insert the newly-created cookie into the cookie store.
    #A cookie is "expired" if the cookie has an expiry date in the past.

    #The user agent MUST evict all expired cookies from the cookie store if, at
    #any time, an expired cookie exists in the cookie store.
    
    #At any time, the user agent MAY "remove excess cookies" from the cookie
    #store if the number of cookies sharing a domain field exceeds some
    #implementation-defined upper bound (such as 50 cookies).

    #At any time, the user agent MAY "remove excess cookies" from the cookie
    #store if the cookie store exceeds some predetermined upper bound (such as
    #3000 cookies).

    #When the user agent removes excess cookies from the cookie store, the user
    #agent MUST evict cookies in the following priority order:

      #1
      #Expired cookies.
      #2
      #Cookies whose secure-only-flag is false, and which share a domain field
      #with more than a predetermined number of other cookies.
      #3
      #Cookies that share a domain field with more than a predetermined number
      #of other cookies.
      #4
      #All cookies.
      #
    #If two cookies have the same removal priority, the user agent MUST evict
    #the cookie with the earliest last-access-time first.

  #When "the current session is over" (as defined by the user agent), the user
  #agent MUST remove from the cookie store all cookies with the persistent-flag
  #set to false.




    # Build key to perform binary search in database. This key is unique in the database
    #
    $c->[COOKIE_KEY]="$c->[COOKIE_DOMAIN] $c->[COOKIE_PATH] $c->[COOKIE_NAME] $c->[COOKIE_HOSTONLY]";
    $c->[COOKIE_MAX_AGE]=undef; # No longer need this, so 
    Log::OK::TRACE and log_trace __PACKAGE__."::store_cookie key: $c->[COOKIE_KEY]";

    # Locate the parition

    my @parts=(($partition_key and $c->[COOKIE_PARTITIONED])?$_partitions{$partition_key}//=[]: \@_cookies);

    for my $part (@parts){
      # Lookup in database
      #Index of left side insertion
      my $index=search_string_left $c->[COOKIE_KEY], $part;
      #say "insertion index: ", $index;
      #say "Looking for  cookie key: ".$c->[COOKIE_KEY];
      #say " against cookie key:     ".$part->[$index][COOKIE_KEY];

      #Test if actually found or just insertion point
      my $found=($index<@$part and ($part->[$index][COOKIE_KEY] eq $c->[COOKIE_KEY]));

      if($found){
          #reject if api call http only cookie currently exists
          next if $part->[$index][COOKIE_HTTPONLY] and !($flags & FLAG_TYPE_HTTP);
          $c->[COOKIE_CREATION_TIME]=$part->[$index][COOKIE_CREATION_TIME];
          if($c->[COOKIE_EXPIRES]<=$time){
            # Found but expired by new cookie. Delete the cookie
            Log::OK::TRACE and log_trace __PACKAGE__. " found cookie and expired. purging";
            splice @$part , $index, 1;
          }
          else {
            # replace existing cookie
            Log::OK::TRACE and log_trace __PACKAGE__. " found cookie. Updating";
            $part->[$index]=$c;
          }
      }

      elsif($c->[COOKIE_EXPIRES]<$time){
        Log::OK::TRACE and log_trace __PACKAGE__. " new cookie  already expired. rejecting";
        next; # new cookie already expired.
      }
      else {
            # insert new cookie
            Log::OK::TRACE and log_trace __PACKAGE__. " new cookie name. adding";
            unless(@$part ){
              push @$part , $c;
            }
            else{
              #Log::OK::TRACE and log_trace __PACKAGE__. " new cookie name. adding";
              splice @$part , $index, 0, $c;
            }
      }
    }
    Log::OK::TRACE and log_trace __PACKAGE__. " Step 23, 24 OK";
  }
  return $self;
}


method _make_get_cookies{
 $_get_cookies_sub=sub {
    my ($request_uri, $partition_key, $flags)=@_;
    $flags//=$_default_flags;

    my $index;
    my $host;
    my $path;
    my $authority;
    my $scheme;

    $index=index $request_uri, "://";
    $scheme=substr $request_uri, 0, $index, "";
    substr($request_uri,0, 3)="";
   
    $index=index $request_uri, "/", $index;
    if($index>0){
      #have path
      $authority=substr $request_uri, 0, $index, "";
      $path=$request_uri;
    }
    else {
      #no path
      $authority=$request_uri;
      $path="";
    }

    # Parse out authority if username/password is provided
    $index=index($authority, "@");
    $authority= $index>0 
      ?substr $authority, $index+1
      :$authority;

    # Find the host
    $index=index $authority, ":";
    $host=$index>0 
      ?  substr $authority, 0, $index
      : $authority;

    die "URI format error" unless $scheme and $host;


    #:($host, undef)=split ":", $authority, 2;

    # Look up the second level domain. This will be the root for our domain search
    #
    my $sld=$_sld_cache{$host}//=scalar reverse $_second_level_domain_sub->($host);
    my $rhost=scalar reverse $host;


    # Iterate through all cookies until the domain no longer matches
    #
    my $time=time-$tz_offset;
    my @output;

    # Search default cookies and also an existing parition. Don't create a new partition
    my @parts=(\@_cookies, ($partition_key and $_partitions{$partition_key})||());
      #########################################
      # #my $part=                            #
      # $partition_key                        #
      #   ? $_partitions{$partition_key}//=[] #
      #   : ()                                #
      # );                                    #
      #########################################
      #use Data::Dumper; 
    #say Dumper \@_cookies;
    for my $part (@parts){ 

      $index=search_string_left $sld, $part;

      Log::OK::TRACE and log_trace __PACKAGE__. " index is: $index"; 
      Log::OK::TRACE and log_trace  "looking for host: $sld";

      local $_;

      $index++ unless @$part;  # Force skip the test loop if no cookies in the jar

      while($index<@$part){
        $_=$part->[$index];

        # End the search when the $sld of request is no longer a prefix for the
        # cookie domain being tested
        last if index $_->[COOKIE_DOMAIN], $sld;

        # Process expire. Do not update $index
        if($_->[COOKIE_EXPIRES] <= $time){
          Log::OK::TRACE and log_trace "cookie under test expired. removing";
          splice @$part, $index, 1;
          next;
        }




        ## At this point we have a domain match ##

        # Test for other restrictions...
        $index++ and next if 
             (!_path_match($path, $_))
             or ($_->[COOKIE_HOSTONLY] and $rhost ne $_->[COOKIE_DOMAIN])
             or ($_->[COOKIE_SECURE] and $scheme ne "https")
             or ($_->[COOKIE_HTTPONLY] and not $flags & FLAG_TYPE_HTTP);

        if((not ($flags & FLAG_SAME_SITE)) and ($_->[COOKIE_SAMESITE] != SAME_SITE_NONE)){



          
          my $f=(($flags & FLAG_TYPE_HTTP) 
              and (($_->[COOKIE_SAMESITE] == SAME_SITE_LAX) 
                  or  ($_->[COOKIE_SAMESITE] == SAME_SITE_DEFAULT)
                  )
          );
          $f&&=(($flags & FLAG_SAFE_METH) or (
            $_lax_allowing_unsafe and $_->[COOKIE_SAMESITE] == SAME_SITE_DEFAULT
            and ($time-$_->[COOKIE_CREATION_TIME]) < $_lax_allowing_unsafe_timeout 
          ));

          $f&&=($flags & FLAG_TOP_LEVEL);
        }

        #
        # If we get here, cookie should be included!
        #Update last access time
        #
        $_->[COOKIE_LAST_ACCESS_TIME]=$time;
        Log::OK::TRACE and log_trace "Pushing cookie";
        push @output, $_;   
        $index++;
      }
    }
     
    # TODO:
    # Sort the output as recommended by RFC 6525
    #  The user agent SHOULD sort the cookie-list in the following
    #     order:
    #
    #     *  Cookies with longer paths are listed before cookies with
    #        shorter paths.
    #
    #     *  Among cookies that have equal-length path fields, cookies with
    #        earlier creation-times are listed before cookies with later
    #        creation-times.

    if($_retrieve_sort ){
      @output= sort {
            length($b->[COOKIE_PATH]) <=> length($a->[COOKIE_PATH])
              || $a->[COOKIE_CREATION_TIME] <=> $b->[COOKIE_CREATION_TIME]
        } @output;
    }
    \@output;
  };
}

method get_cookies{
  # Do a copy of the matching entries
  #
  map [@$_], $_get_cookies_sub->&*->@*;
}


#TODO rename to retrieve_cookies?
method retrieve_cookies{
  my $cookies=&$_get_cookies_sub;
  join "; ", map  "$_->[COOKIE_NAME]=$_->[COOKIE_VALUE]", @$cookies;
}
#*retrieve_cookies=\&encode_request_cookies;

method get_kv_cookies{#
  my $cookies=&$_get_cookies_sub;
  map(($_->[COOKIE_NAME], $_->[COOKIE_VALUE]), @$cookies);
}


method db {
  \@_cookies;
}





# Compatibility matrix
# HTTP::CookieJar
#   Additional api
#   new
#     create a new jar
#   clear
#     empty the jar
#   dump_cookies
#     
#
# Used by:
#   HTTP::Tiny
#   FURL
#  Expected API
#   $jar->add($url, $set_cookie_string)
#     Parse set cookie string and add cookie to jar
#
#   #jar->cookie_header($url)
#     Retrieve cookies from jar and serialize for header
#
#
# Returns self for chaining
method clear{
  @_cookies=(); #Clear the db
  %_partitions=();
  $self;
}
method add {
  $self->store_cookies(shift, undef, $_default_flags, @_);
}

method cookie_header {
  splice @_, 1, 0, undef, $_default_flags;
  my $cookies=&$_get_cookies_sub;
}

method dump_cookies {
  my $all=$_[0]?!$_[0]{persistent}:1;
  my @out=map  encode_set_cookie($_, $tz_offset) , grep $_->[COOKIE_PERSISTENT]||$all, @_cookies;
  for my ($k)(sort keys %_partitions){
    my $v=$_partitions{$k};
    push @out, map  encode_set_cookie($_, $tz_offset, $k) , grep $_->[COOKIE_PERSISTENT]||$all, @$v;
  }
  @out;
}

method cookies_for{
  my $cookies=&$_get_cookies_sub;
  map hash_set_cookie($_,1), @$cookies;
}

#TODO: add test for bulk adding of strings and structs
method load_cookies{
  my $index;
  my $time=time-$tz_offset;
  my $c;
  for my $s (@_){

    Log::OK::TRACE and log_trace "+++";
    Log::OK::TRACE and log_trace "loading cookie from string";
    Log::OK::TRACE and log_trace $s;
    next unless $c=decode_set_cookie($s, $tz_offset);
    # Don't load if cookie is expired
    #
    next if $c->[COOKIE_EXPIRES]<=$time;

    # Build key for search
    $c->[COOKIE_KEY]="$c->[COOKIE_DOMAIN] $c->[COOKIE_PATH] $c->[COOKIE_NAME] $c->[COOKIE_HOSTONLY]";


    # Adjust the partitioned flag
    my $partition_key=$c->[COOKIE_PARTITIONED];

    my $part=\@_cookies;  #default is the unparitioned jar

    if($partition_key){
      $c->[COOKIE_PARTITIONED]=1;
      $part=$_partitions{$partition_key}//=[];
    }

    # update the list
    unless(@$part){
      Log::OK::TRACE and log_trace "Pushing cookie in to empty jar/parition";
      push @$part, $c;
    }
    else{
      # Do binary search
      #
      $index=search_string_left $c->[COOKIE_KEY], $part;#\@_cookies;
      # If the key is identical, then we prefer the latest cookie,
      # TODO: Fix key with scheme?
      if($index<@$part and ($part->[$index][COOKIE_KEY] eq $c->[COOKIE_KEY])){
        Log::OK::TRACE and log_trace "replace cookie in jar/parition";
        $part->[$index]=$c;
      }
      else {
        Log::OK::TRACE and log_trace "splicing cookie in to jar/parition";
        splice @$part, $index,1,$c;
      }


      #splice @$part, $index, $replace, $c;
    }
  }
}

1;
