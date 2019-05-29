#!/usr/bin/perl

=head1 NAME

wsutil - a GRNOC webservice testing utility.

=head1 SYNOPSIS

  This is a handy little script to help diagnose a webservice and provide 
  timing of the various stages between initiating a request and actually 
  getting the results back. It offers support for customizing everything 
  that the GRNOC::WebService::Client does.

  Usage:

  wsutil  -U <url> [options]
    or
  wsutil  -S <service_name> 
             [-c <service_cache_file> | -n <name_services>] [options]

  Options:

  -m              which method to run on the remote service. This defaults to 
  --method        "help" if not given.  This will be given as 
                  "method=<input>" when actually calling the remote service.


  -a              what args to pass to the remote service. This should be 
  --args          in the form "foo=1&bar=2&biz=3"


  -u              username to authenticate to the service with. If this is 
  --username      given you will be prompted for a password.
 

  -P              password for service authentication. If a username is 
  --password      provided but no password, the user will be interactively 
                  prompted for a password.


  -r              realm to use. This is required for basic auth and ignored for 
  --realm         CoSign auth.


  -t              timeout in seconds to use for the request.
  --timeout


  -p              use POST instead of GET
  --post          This is a boolean field and does not require an argument.


  -k              enable keepalives
  --keepalive     This is a boolean field and does not require an argument.


  -o              pass raw output from the service instead of trying to 
  --raw           decode it as json This is a boolean field and does not 
                  require an argument. 


  -l              path to cookie file location. If given this will use any 
                  cookies in the file when authenticating to a service and 
                  also save them to this file when done. If not given 
                  cookies are maintained only for the current run.

                  It is probably prudent to make sure that the cookies that 
                  are generated using your own credentials are cleaned up 
                  afterwards or at least not made publicly available.


  -c              service cache file (in case of specifying -S Service Name)
  --servicecache  This file should be in the same format as the grnoc proxy 
                  cronjob creates from the name service.


  -n              name service lookup URL (in case of specifying -S 
  --nameservice   Service Name)    


  -X              do not print the results of the webservice call
  --noresult      This is a boolean field and does not require an argument.


  -b              Takes a numerical argument. Do a batch of requests 
  --batch         instead of a single request. The numerical argument
                  is the number of requests sent. When doing a batch,
                  the individual responses are not displayed (see -X).
                  Instead call turn-around information is printed 
                  and a summary is printed after all the requests
                  have been sent.


  -s              Silent. Do not print responses (see -X) when doing a 
  --silent        single request timing information and summary when 
                  doing a batch of requests.
 

  -d              Takes a numerical argument. When sending a batch of 
  --delay         requests (see -b), pause for that many microseconds
                  between each request. Without delay options, batch
                  requests are sent as fast as possible


  -h              show this message
  --help

=cut







use strict;
use Data::Dumper;
use GRNOC::WebService::Client;
use Getopt::Long qw( :config bundling no_ignore_case );
use Term::ReadKey;
use Pod::Text;
use Time::HiRes qw( gettimeofday tv_interval usleep );


FUNCTIONS: {

  sub usage {
    my $parser = Pod::Text->new(
                                  'sentence'  => 0,
                                  'loose'     => 1,
                                  'width'     => 78,
                                  'indent'    => 0,
                );
    $parser->parse_from_file( $0 );
  }

  sub errorExit {
    my $msg = shift;
    usage();
    print "\n\n  Error:\n  ".$msg."\n\n";
    exit(0);
  }

}


MAIN: {

  #
  # You know, they were just like these variables...
  #
  my  @response_times;
  my  @responses;
  my  $good_requests          = 0;
  my  $error_requests         = 0;
  my  $cur_request_nbr        = 0;


  #
  # Sort out command line options
  #
  my $url;                
  my $service_name;      
  my $method;           
  my $args;            
  my $username;            
  my $realm;         
  my $timeout;      
  my $usePost;     
  my $use_keep_alive;     
  my $raw_output;        
  my $cookies_location; 
  my $service_cache_file; 
  my $name_services;     
  my $suppress_output;  
  my $help;            
  my $password;
  my $batch;
  my $silent;
  my $delay;
  
  my  %opts = (

    'U|url=s'           =>  \$url,
    'S|service=s'       =>  \$service_name,
    'm|method=s'        =>  \$method,
    'a|args=s'          =>  \$args,
    'u|username=s'      =>  \$username,
    'P|password=s'      =>  \$password,
    'r|realm=s'         =>  \$realm,
    't|timeout=i'       =>  \$timeout,
    'p|post'            =>  \$usePost,
    'k|keepalive'       =>  \$use_keep_alive,
    'o|raw'             =>  \$raw_output,
    'l|cookiejar=s'     =>  \$cookies_location,
    'c|servicecache=s'  =>  \$service_cache_file,
    'n|nameservice=s'   =>  \$name_services,
    'X|noresponse'      =>  \$suppress_output,
    'b|batch=i'         =>  \$batch,
    's|silent'          =>  \$silent,
    'd|delay=i'         =>  \$delay,
    'h|help'            =>  \$help,
  
  );

  unless( GetOptions( %opts ) ) {
    errorExit( "Bad command line option [".$!."]" );
  }
 

  #
  # simplest use case
  if( $help ) {
    usage();
    exit(1);
  }

  #
  # Sort out command line options
  #

  #
  # Either URL or Service Name
  unless( $url xor $service_name ) {
    errorExit( "One, and only one of, url or service name must be specified");
  }
  
  #
  # Need a cache file or name service of service_name is specified
  if(
          defined $service_name 
      &&  !defined $service_cache_file 
      &&  !defined $name_services
  ) {
    errorExit( "service_name requires a name_service or a service_cache_file" );
  }
  
  #
  # Verify cache file
  if(
          defined $service_name 
      &&  defined $service_cache_file 
      && !(-e $service_cache_file)
  ) {
    errorExit( "service_cache_file $service_cache_file does not exist" );
  }
  
  #
  # Verify name service
  if(
          defined $service_name 
      &&  defined $name_services 
      && ($name_services !~ /^http/)
  ) {
    errorExit( "name_service must begin with http" );
  }
  
  #
  # handle defaults
  $method   = ( $method || "help" );
  $batch    = ( $batch || 1 );

  #
  # If the user gave us a usename, we will prompt them for a password. 
  # This avoids having to read something off the command or otherwise 
  # expose private data.
  if( $username && !$password ) {
    print "password: ";
    ReadMode('noecho');
    chomp($password = <STDIN>);
    ReadMode('normal');
    print "\n";
  }
  
  #
  # Turn the args string into a perl hash so we can pass it along to the 
  # webservice. Split first based on & then split each subthing by = to 
  # get key/value
  my %argshash = ();
  my @arguments = split /&/, $args;
  foreach my $item (@arguments) {
    my @pair = split /=/, $item;
    my $name  = $pair[0],
    my $value = $pair[1];
    $argshash{$name} = $value;
  }
  
  #
  # In case of using service name, if both cache file and name service are 
  # specified, cache file will be used by default.
  my @name_services_array = ();
  if(
          defined $service_name 
      &&  defined $service_cache_file 
      &&  defined $name_services
  ) {
    $name_services = undef;
    undef @name_services_array;
  }

  if($name_services) {
    push @name_services_array, $name_services;
  }
   
  #print "ARGS HASH ".Dumper( \%argshash );
  #print "URL [".$url."]\n"; #!!!!!

  #
  # Create our client object using all the things we were passed in.
  my $svc = GRNOC::WebService::Client->new(
             'url'                =>  $url,
             'uid'                =>  $username,
             'passwd'             =>  $password,
             'realm'              =>  $realm,
             'timeout'            =>  $timeout,
             'usePost'            =>  $usePost,
             'use_keep_alive'     =>  $use_keep_alive,
             'raw_output'         =>  $raw_output,
             'cookieJar'          =>  HTTP::Cookies->new(
                                        'file'            => $cookies_location,
                                        'autosave'        => 1,
                                        'ignore_discard'  => 1,
                                      ),
            'service_name'        =>  $service_name,
            'service_cache_file'  =>  $service_cache_file,
            'name_services'       =>  \@name_services_array,
            'timing'              =>  1,
  );
  
  #
  # Process the request(s)
 
  my $tmp_response;
  my $tmp_stat;
  while( $cur_request_nbr < $batch ) {

    my $start = [ gettimeofday() ];
    $tmp_response = $svc->$method(%argshash);
    push @response_times, tv_interval( $start, [ gettimeofday() ] );
    

    if( $tmp_response ) {
      push @responses, $tmp_response;
      $tmp_stat = "Good";
      $good_requests++;
    }
    else {
      push @responses, $svc->get_error();
      $tmp_stat = "Error";
      $error_requests++;
    }
    
    if( $batch > 1 && !$silent ) {
      printf(
              "Request [%d] Turn - around (secs) [%3.6f] Stat [%s]\n",
              $cur_request_nbr,
              $response_times[ $#response_times ],
              $tmp_stat,
      );
    }
    if( $delay ) {
      usleep( $delay );
    }

    $cur_request_nbr++;

  }
  
  #
  # Show any summary/final information
  if( $batch == 1 && !$suppress_output ){
    print "\nResponse: ".Dumper(\$responses[ $#responses ])."\n";
  }
  elsif( $batch > 1 && !$silent ) {
    my $min = 99999999999;
    my $max = 0;
    my $total = 0;
    for my $time (@response_times)  {
      $min = ( $time < $min ) ? $time : $min;
      $max = ( $time > $max ) ? $time : $max;
      $total += $time;
    }
    printf( 
            "Total requests sent [%d] Good responses [%d] Errors [%d]\n",
            $cur_request_nbr,
            $good_requests,
            $error_requests,
    );
    printf(
              "Average turn-around time [%3.6f]\n"
            . "Minimum turn-around time [%3.6f]\n"
            . "Maximum turn-around time [%3.6f]\n",
            $total / $cur_request_nbr,
            $min,
            $max
    )
  }
};
