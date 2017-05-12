package CGIUtils;

BEGIN{
  push @INC, '.', '../../lib';
  eval{
   require DefEnv;
   DefEnv::read();
  };
  if($@){
    warn "could not open DefEnv.pm";
  }
}

END{
}

our $isCGI;
use CGI qw(:standard);
if($isCGI){
  use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
}

BEGIN{
  $isCGI=$ENV{GATEWAY_INTERFACE}=~/CGI/;
  sub carp_error{
    my $msg=shift;
    if ($isCGI){
      my $q=new CGI;
      error($q, $msg);
    }else{
      print STDERR $msg;
    }
  }
  CGI::Carp::set_message(\&carp_error) if $isCGI;

  sub error(){
    my($q, $msg)=@_;
    $q->header;
    print $q->start_html(-title=>"$0",
			 -BGCOLOR=>'white');
    print "<center><h1>$0</h1></center>\n";
    print  "<pre>$msg</pre>\n";
    $q->end_html;
    exit;
  }
}





return 1;

