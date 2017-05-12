#############################################################################
## This file was generated automatically by Class::HPLOO/0.12
##
## Original file:    ./lib/Mail/SendEasy/SMTP.hploo
## Generation date:  2004-04-09 04:49:29
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        SMTP.pm
## Purpose:     Mail::SendEasy::SMTP
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-23
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package Mail::SendEasy::SMTP ;

  use strict qw(vars) ; no warnings ;

  my (%CLASS_HPLOO) ;
 
  sub new { 
    my $class = shift ;
    my $this = bless({} , $class) ;
    no warnings ;
    my $undef = \'' ;
    sub UNDEF {$undef} ;
    if ( $CLASS_HPLOO{ATTR} ) {
    foreach my $Key ( keys %{$CLASS_HPLOO{ATTR}} ) {
    tie( $this->{$Key} => 'Class::HPLOO::TIESCALAR' , $CLASS_HPLOO{ATTR}{$Key}{tp} , $CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} ) if !exists $this->{$Key} ;
    } }  my $ret_this = defined &SMTP ? $this->SMTP(@_) : undef ;
    if ( ref($ret_this) && UNIVERSAL::isa($ret_this,$class) ) {
    $this = $ret_this ;
    if ( $CLASS_HPLOO{ATTR} && UNIVERSAL::isa($this,'HASH') ) {
    foreach my $Key ( keys %{$CLASS_HPLOO{ATTR}} ) {
    tie( $this->{$Key} => 'Class::HPLOO::TIESCALAR' , $CLASS_HPLOO{ATTR}{$Key}{tp} , $CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} ) if !exists $this->{$Key} ;
    } } } elsif ( $ret_this == $undef ) {
    $this = undef ;
    }  return $this ;
  }


  use IO::Socket ;
  use IO::Select ;
  
  use Mail::SendEasy::AUTH ;
  use Mail::SendEasy::Base64 ;
  
  no warnings ;

  use vars qw($VERSION) ;
  $VERSION = '0.01' ;
  
  sub SMTP { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    my  $host = shift(@_) ;
    my $port = shift(@_) ;
    my $timeout = shift(@_) ;
    my $user = shift(@_) ;
    my $pass = shift(@_) ;
    my $from_sendeasy = shift(@_) ;
    
    $this->{HOST} = $host ;
    $this->{PORT} = $port || 25 ;
    $this->{TIMEOUT} = $timeout || 120 ;
    $this->{USER} = $user ;
    $this->{PASS} = $pass ;

    $this->{SENDEASY} = 1 if $from_sendeasy ;
    
    for (1..2) { last if $this->connect($_) ;}
    
    return UNDEF if !$this->{SOCKET} ;
  }

  sub connect { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    my $n = shift(@_) ;
    
    my $sock = new IO::Socket::INET(
    PeerAddr => $this->{HOST} ,
    PeerPort => $this->{PORT} ,
    Proto    => 'tcp' ,
    Timeout  => $this->{TIMEOUT} ,
    ) ;
  
    if (!$sock) {
      $this->warn("ERROR: Can't connect to $this->{HOST}:$this->{PORT}\n") if (!$n || $n > 1) ;
      return ;
    }
    
    $sock->autoflush(1) ;
    $this->{SOCKET} = $sock ;
    
    if ( $this->response !~ /^2/ ) {
      $this->close("ERROR: Connection error on host $this->{HOST}:$this->{PORT}\n") if (!$n || $n > 1) ;
      return ;
    }
    
    if ( $this->EHLO('main') !~ /^2/ ) {
      $this->close("ERROR: Error on EHLO") ;
      return ;
    }
    else {
      my @response = $this->last_response ;    
      foreach my $response_i ( @response ) {
        next if $$response_i[0] !~ /^2/ ;
        my ($key , $val) = ( $$response_i[1] =~ /^(\S+)\s*(.*)/s );
        $this->{INF}{$key} = $val ;
      }
    }
    
    return 1 ;
  }
  
  sub is_connected { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    
    return 1 if $this->{SOCKET} && $this->{SOCKET}->connected  ;
    return undef ;
  }
  
  sub auth_types { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    
    my @types = split(/\s+/s , $this->{INF}{AUTH}) ;
    return @types ;
  }
  
  sub auth { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    my $user = shift(@_) ;
    my $pass = shift(@_) ;
    my @types = @_ ;
    @_ = () ;
    
    $user = $this->{USER} if $user eq '' ;
    $pass = $this->{PASS} if $pass eq '' ;
    @types = $this->auth_types if !@types ;
    
    my $auth = Mail::SendEasy::AUTH->new($user , $pass , @types) ;
    
    if ( $auth && $this->AUTH( $auth->type ) =~ /^3/ ) {
      if ( my $init = $auth->start ) {
        $this->cmd(encode_base64($init, '')) ;
        return 1 if $this->response == 235 ;
      }
      
      my @response = $this->last_response ;
      
      while ( $response[0][0] == 334 ) {
        my $message = decode_base64( $response[0][1] ) ;
        my $return = $auth->step($message) ;
        $this->cmd(encode_base64($return, '')) ;
        @response = $this->response ;
        return 1 if $response[0][0] == 235 ;
        last if $response[0][0] == 535 ;
      }
    }
    
    $this->warn("Authentication error!\n") ;
    
    return undef ;
  }
  
  sub EHLO { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; $this->cmd("EHLO",@_) ; $this->response ;}
  sub AUTH { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; $this->cmd("AUTH",@_) ; $this->response ;}
  
  sub MAIL { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; $this->cmd("MAIL",@_) ; $this->response ;}
  sub RCPT { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; $this->cmd("RCPT",@_) ; $this->response ;}

  sub DATA { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; $this->cmd("DATA") ; $this->response ;}
  sub DATAEND { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; $this->cmd(".") ; $this->response ;}
  
  sub QUIT { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; $this->cmd("QUIT") ; return wantarray ? [200,''] : 200 ;}
  
  sub close { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    my $error = shift(@_) ;
    
    $this->warn($error) if $error ;
    return if !$this->{SOCKET} ;
    $this->QUIT ;
    close( delete $this->{SOCKET} ) ;
  }
  
  sub warn { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    my $error = shift(@_) ;
    
    return if !$error ;
    if ( $this->{SENDEASY} ) { Mail::SendEasy::warn($error) ;}
    else { warn($error) ;}
  }
  
  sub print { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    my $data = shift(@_) ;
    
    $this->connect if !$this->is_connected ;
    return if !$this->{SOCKET} ;
    my $sock = $this->{SOCKET} ;
    print $sock $data ;
  }

  sub cmd { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    my @cmds = @_ ;
    @_ = () ;
    
    $this->connect if !$this->is_connected ;
    return if !$this->{SOCKET} ;
    my $sock = $this->{SOCKET} ;
    my $cmd = join(" ", @cmds) ;
    $cmd =~ s/[\r\n]+$//s ;
    $cmd =~ s/(?:\r\n?|\n)/ /gs ;
    $cmd .= "\015\012" ;
    print $sock $cmd ;
  }
  
  sub response { 
    my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ;
    
    $this->connect if !$this->is_connected ;
    return if !$this->{SOCKET} ;
    local($/) ; $/ = "\n" ;
    my $sock = $this->{SOCKET} ;
    
    my $sel = IO::Select->new($sock) ;


    my ($line , @lines) ;
    
    if ( $sel->can_read( $this->{TIMEOUT} ) ) {
      while(1) {
        chomp($line = <$sock>) ;
        my ($code , $more , $msg) = ( $line =~ /^(\d+)(.?)(.*)/s ) ;
        $msg =~ s/\s+$//s ;
        push(@lines , [$code , $msg]) ;
        last if $more ne '-' ;
      }
    }
    
    $this->{LAST_RESPONSE} = \@lines ;

    return( @lines ) if wantarray ;
    return $lines[0][0] ;
    
    return ;
  }
  
  sub last_response { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; return wantarray ? @{$this->{LAST_RESPONSE}} : @{$this->{LAST_RESPONSE}}[0]->[0] } ;
  
  sub last_response_msg { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; @{$this->{LAST_RESPONSE}}[0]->[1] } ;
  
  sub last_response_line { my $this = ref($_[0]) && UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : undef ; @{$this->{LAST_RESPONSE}}[0]->[0] . " " . @{$this->{LAST_RESPONSE}}[0]->[1] } ;
  

}



1;

__END__

=head1 NAME

Mail::SendEasy::SMTP - Handles the communication with the SMTP server without dependencies.

=head1 DESCRIPTION

This module will handle the communication with the SMTP server.
It hasn't dependencies and supports authentication.

=head1 USAGE

  use Mail::SendEasy ;

  $smtp = Mail::SendEasy::SMTP->new( 'domain.foo' , 25 , 120 ) ;
  
  if ( !$smtp->auth ) { warn($smtp->last_response_line) ;}
  
  if ( $smtp->MAIL("FROM:<$mail{from}>") !~ /^2/ ) { warn($smtp->last_response_line) ;}
  
  if ( $smtp->RCPT("TO:<$to>") !~ /^2/ ) { warn($smtp->last_response_line) ;}
   
  if ( $smtp->RCPT("TO:<$to>") !~ /^2/ ) { warn($smtp->last_response_line) ;}
    
  if ( $smtp->DATA =~ /^3/ ) {
    $smtp->print("To: foo@foo") ;
    $smtp->print("Subject: test") ;
    $smtp->print("\n") ;
    $smtp->print("This is a sample MSG!") ;
    if ( $smtp->DATAEND !~ /^2/ ) { warn($smtp->last_response_line) ;}
  }

  $smtp->close ;

=head1 METHODS

=head2 new ($host , $port , $timeout , $user , $pass)

Create the SMTP object and connects to the server.

=head2 connect

Connect to the server.

=head2 auth_types

The authentication types supported by the SMTP server.

=head2 auth($user , $pass)

Does the authentication.

=head2 print (data)

Send I<data> to the socket connection.

=head2 cmd (CMD , @MORE)

Send a command to the server.

=head2 response

Returns the code response.

If I<wantarray> returns an ARRAY with the response lines.

=head2 last_response

Returns an ARRAY with the response lines.

=head2 last_response_msg

The last response text.

=head2 last_response_line

The last response line (code and text).

=head2 close

B<QUIT> and close the connection.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

