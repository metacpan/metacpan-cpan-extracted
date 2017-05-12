package Mock::NatwestWebServer::Tests;

use strict;
use base qw/ Exporter /;

use Test::More;

use constant SESSION_EXPIRED => 'SESSION_EXPIRED';
use constant UNAVAILABLE =>     'UNAVAILABLE'; 
use constant ERROR       =>     'ERROR'; 
use constant ERROR_NOREDIR =>   'ERROR_NOREDIR';
use constant UNKNOWN_PAGE =>    'UNKNOWN_PAGE'; 
use constant PINPASS_REQUEST => 'PINPASS_REQUEST';
use constant LOGIN_MSG =>       'LOGIN_MSG';
use constant LOGIN_OK =>        'LOGIN_OK';
use constant BALANCES =>        'BALANCES';

use constant CONTENT_REGEX => {
 SESSION_EXPIRED => qr|Session expired|,
 UNAVAILABLE =>     qr|Service Temporarily Unavailable|,
 ERROR       =>     qr|<div class=ErrorMsg>Error</div>|,
 ERROR_NOREDIR =>   qr|<div class=ErrorMsg>Error</div>|,
 UNKNOWN_PAGE =>    qr|An unknown page|,
 PINPASS_REQUEST => qr#
                                   Please \s enter \s the \s ([a-z]{5,6}), \s
                                   ([a-z]{5,6}) \s and \s ([a-z]{5,6}) \s
                                   digits \s from \s your \s (?:Security \s Number|PIN): 
                                   .*
                                   Please \s enter \s the \s ([a-z]{5,11}), \s
                                   ([a-z]{5,11}) \s and \s ([a-z]{5,11}) \s
                                   characters \s from \s your \s Password:
                                  #x,
 LOGIN_MSG =>       qr|
                       <form \s action="LogonMessage \. asp" \s method="post">
		       Some \s important \s logon \s message </form>
		      |x,
 LOGIN_OK =>        qr|
                                   Our \s records \s indicate \s the \s last \s
                                   time \s you \s used \s the \s service \s
				   was:
				  |x,
 BALANCES =>        qr|<form.*?>(.*?)<\/form>(.*?)<div class="smftr">|s,
};

use constant CONTENT_MESSAGES => {
   SESSION_EXPIRED => 'session expired as expected',
   UNAVAILABLE     => 'service unavailable as expected',
   ERROR           => 'unknown error as expected',
   ERROR_NOREDIR   => 'unknown error as expected',
   UNKNOWN_PAGE    => 'unknown page as expected',
   PINPASS_REQUEST => 'pinpass request as expected',
   LOGIN_MSG       => 'login message presented',
   LOGIN_OK        => 'login successful',
   BALANCES        => 'balances page as expected',
};


use vars qw/ @EXPORT /;
#@EXPORT = qw/ post_ok is_content is_unknown is_unavailable is_error
#              is_expired is_pprequest is_loginok is_success isnt_success
#              was_called were_called request_ok request_fail
#              SESSION_EXPIRED UNAVAILABLE ERROR UNKNOWN_PAGE PINPASS_REQUEST
#              LOGIN_OK ERROR_NOREDIR
#            /;

@EXPORT = qw/ request_ok request_fail was_called were_called
              SESSION_EXPIRED UNAVAILABLE ERROR UNKNOWN_PAGE PINPASS_REQUEST
	      LOGIN_MSG LOGIN_OK ERROR_NOREDIR BALANCES
	    /;



sub post_ok {
   my $ua = shift;
   my $url = shift;
   my $args = shift;
   my $message = shift || "got response object successfully ($url)";
   local $Test::Builder::Level = $Test::Builder::Level + 1;

   ok( my $resp = $ua->post($url, $args), $message );

   return $resp;
}

sub is_content {
   my $resp = shift;
   my $content = shift;
   my $message = shift || CONTENT_MESSAGES->{$content};
   local $Test::Builder::Level = $Test::Builder::Level + 1;

   like( $resp->content, CONTENT_REGEX->{$content}, $message );
   return $resp;
}

sub is_unknown {
   my $resp = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;
   is_content( $resp, UNKNOWN_PAGE, 
               'unknown page as expected' );
}

sub is_unavailable {
   my $resp = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;
   is_content( $resp, UNAVAILABLE, 
               'service unavailable as expected' );
}

sub is_error {
   my $resp = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;
   is_content( $resp, ERROR,
               'unknown error as expected' );
}

sub is_expired {
   my $resp = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;
   is_content( $resp, SESSION_EXPIRED, 
               'session expired as expected' );
}

sub is_pprequest {
   my $resp = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;
   is_content( $resp, PINPASS_REQUEST,
               'pinpass request as expected' );
}

sub is_loginok {
   my $resp = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;
   is_content( $resp, LOGIN_OK,
               'login successful' );
}

sub is_success {
   my $resp = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;

   ok( $resp->is_success, 'should have returned success response' );

   return $resp;
}

sub isnt_success {
  my $resp = shift;
  my $reason = shift;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  ok( !$resp->is_success, 
      'should have returned error response as was invalid url ' .
      '(' . $reason . ')' );
}

sub was_called {
   my $mock = shift;
   my $method = shift;
   my $args = shift;
   my $message = shift ||
      "'$method' called as expected, and with expected params";
   local $Test::Builder::Level = $Test::Builder::Level + 1;

   ok( eq_array( [ $mock->next_call() ], 
                 [ $method, [ $mock, @{$args} ] ] ), $message );
}

sub were_called {
   my $mock = shift;
   my $call_list = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;

   for my $call (@{$call_list}) {
      was_called( $mock, @{$call} );
   }
}

sub request_ok {
   my $ua = shift;
   my $result_type = shift;
   my $url = shift;
   my $args = shift;
   local $Test::Builder::Level = $Test::Builder::Level + 1;

   $ua->clear();
   my $in_session = defined $ua->session_id;

   my $resp = is_content(
      is_success( post_ok( $ua, $url, $args ) ),
      $result_type,
   );

   were_called( $ua, [ [ 'post', [ $url, $args ] ],
                       [ 'is_success', [] ],
                       [ 'content', [] ],
                     ]);

   $url = lc($url);

   if ($result_type eq ERROR or $result_type eq PINPASS_REQUEST) {
      isnt( lc($resp->base->as_string), $url, 'should have been redirected' );
   } elsif ($in_session) {
      is( lc($resp->base->as_string), $url, 'should not have been redirected' );
   } elsif ($result_type eq UNKNOWN_PAGE) {
      is( lc($resp->base->as_string), $url, 'should not have been redirected' );
   } else {
      isnt( lc($resp->base->as_string), $url, 'should have been redirected' );
   }
  

   were_called( $ua, [ [ 'base', [] ],
                       [ 'as_string', [] ],
		     ]);
 
   return $resp;

}

sub request_fail {
   my $ua = shift;
   my $url = shift;
   my $args = shift;
   my $fail_reason = shift; 
   local $Test::Builder::Level = $Test::Builder::Level + 1;

   $ua->clear();
   
   my $resp = isnt_success( post_ok( $ua, $url, $args ), $fail_reason ); 

   were_called( $ua, [ [ 'post', [ $url, $args ] ],
                     [ 'is_success', [] ],
		   ]);

   return $resp;
}
