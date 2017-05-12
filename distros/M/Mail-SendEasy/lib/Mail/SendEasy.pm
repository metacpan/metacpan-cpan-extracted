#############################################################################
## Name:        SendEasy.pm
## Purpose:     Mail::SendEasy
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-23
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Mail::SendEasy ;
use 5.006 ;

use strict qw(vars);
no warnings ;

use vars qw($VERSION @ISA) ;

$VERSION = '1.2' ;

###########
# REQUIRE #
###########

  use Time::Local ;

  use Mail::SendEasy::SMTP ;
  use Mail::SendEasy::Base64 ;
  use Mail::SendEasy::IOScalar ;
  
  my $ARCHZIP_PM ;
  
  eval("use Archive::Zip ()") ;
  if ( defined &Archive::Zip::new ) { $ARCHZIP_PM = 1 ;}

########
# VARS #
########

  my $RN = "\015\012" ;
  my $ER ;

#######
# NEW #
#######

sub new {
  my $this = shift ;
  return( $this ) if ref($this) ;
  my $class = $this || __PACKAGE__ ;
  $this = bless({} , $class) ;
  
  my ( %args ) = @_ ;
  
  if ( !defined $args{smtp} ) { $args{smtp} = 'localhost' ;}
  if ( $args{port} !~ /^\d+$/ ) { $args{port} = 25 ;}
  if ( $args{timeout} !~ /^\d+$/ ) { $args{timeout} = 30 ;}
  
  $this->{SMTP} = Mail::SendEasy::SMTP->new( $args{smtp} , $args{port} , $args{timeout} , $args{user} , $args{pass} , 1 ) ;

  return $this ;
}

########
# SEND #
########

sub send {
  my $this = UNIVERSAL::isa($_[0] , 'Mail::SendEasy') ? shift : undef ;
  
  my $SMTP = $this->{SMTP} ;
  
  $ER = undef ;
  
  my %mail ;
  
  while (@_) {
    my $k = lc(shift @_) ;
    $k =~ s/_//gs ;
    $k =~ s/\W//gs ;
    $k =~ s/s$// if $k !~ /^(?:pass)$/ ;
    my $v = shift @_ ;
    if ( !ref($v) && $k !~ /^(?:msg|message|html|msghtml)$/ ) {
      $v =~ s/^\s+//gs ;
      $v =~ s/\s+$//gs ;    
    }
    $mail{$k} = $v ;
  }
  
  if ( !defined $mail{msg} && defined $mail{message} ) { $mail{msg} = delete $mail{message} ;}
  if ( !defined $mail{html} && defined $mail{msghtml} ) { $mail{html} = delete $mail{msghtml} ;}
  if ( !defined $mail{anex} && defined $mail{attach} ) { $mail{anex} = delete $mail{attach} ;}
  
  if ( !defined $mail{from} ) { $ER = "Blank From adress!" ; return( undef ) ;}
  if ( !defined $mail{to} ) { $ER = "Blank recipient (to)!" ; return( undef ) ;}
  
  if ( !$SMTP ) {
    if ( !defined $mail{smtp} ) { $mail{smtp} = 'localhost' ;}
    if ( $mail{port} !~ /^\d+$/ ) { $mail{port} = 25 ;}
    if ( $mail{timeout} !~ /^\d+$/ ) { $mail{timeout} = 30 ;}
  
    $SMTP = Mail::SendEasy::SMTP->new($mail{smtp} , $mail{port} , $mail{timeout} , $mail{user} , $mail{pass} , 1) if !$SMTP ;
  }
  
  if (!$SMTP) { return ;}
  
  ## Check mails ################
  {
    my @from = &_check_emails( $mail{from} ) ; return( undef ) if $ER ;
    if ($#from > 0) { $ER = "More than one From: " . join(" ; ", @from) ; return( undef ) ;}
    $mail{from} = @from[0] ;
        
    my @to = &_check_emails( $mail{to} ) ; return( undef ) if $ER ;
    $mail{to} = \@to ;
        
    if ( defined $mail{cc} ) {
      my @cc = &_check_emails( $mail{cc} ) ; return( undef ) if $ER ;
      $mail{cc} = \@cc ;
    }

    if ( defined $mail{reply} ) {    
      my @reply = &_check_emails( $mail{reply} ) ; return( undef ) if $ER ;
      $mail{reply} = @reply[0] ; delete $mail{reply} if $mail{reply} eq '' ;
    }
    
    if ( defined $mail{error} ) {    
      my @error = &_check_emails( $mail{error} ) ; return( undef ) if $ER ;
      $mail{error} = @error[0] ; delete $mail{error} if $mail{error} eq '' ;
    }
  }
  
  ## ANEXS ######################
  
  if ( defined $mail{anex} ) {
    my @anex = $mail{anex} ;
    @anex = @{$mail{anex}} if ref($mail{anex}) eq 'ARRAY' ;
    
    foreach my $anex_i ( @anex ) {
      &_to_one_line($anex_i) ;
      if ($anex_i eq '') { next ;}
      $anex_i =~ s/[\/\\]+/\//gs ;
      if (!-e $anex_i) { $ER = "Invalid Anex: $anex_i" ; return( undef ) ;}
      if (-d $anex_i) { $ER = "Anex is a directory: $anex_i" ; return( undef ) ;}
      $anex_i =~ s/\/$// ;
    }
    
    my @anex_part ;
    
    if ( $ARCHZIP_PM && $mail{zipanex} ) {
      my ($filename , $zip_content) = &_zip_anexs($mail{zipanex},@anex) ;
      
      my %part = (
      'Content-Type' => "application/octet-stream; name=\"$filename\"" ,
      'Content-Transfer-Encoding' => 'base64' ,
      'Content-Disposition' => "attachment; filename=\"$filename\"" ,
      'content' => &encode_base64( $zip_content ) ,
      );

      push(@anex_part , \%part) ;
    }
    else {
      foreach my $anex_i ( @anex ) {
        my ($filename) = ( $anex_i =~ /\/*([^\/]+)$/ );
        
        my %part = (
        'Content-Type' => "application/octet-stream; name=\"$filename\"" ,
        'Content-Transfer-Encoding' => 'base64' ,
        'Content-Disposition' => "attachment; filename=\"$filename\"" ,
        'content' => &encode_base64( &cat($anex_i) ) ,
        );
  
        push(@anex_part , \%part) ;
      }
    }
    
    delete $mail{anex} ;
    $mail{anex} = \@anex_part if @anex_part ;
  }
  
  ## MIME #######################
  
  delete $mail{MIME} ;
  
  $mail{MIME}{Date} = &time_to_date() ;
  
  $mail{MIME}{From} = $mail{from} ;
  
  if ( $mail{fromtitle} =~ /\S/s ) {
    my $title = delete $mail{fromtitle} ;
    $title =~ s/[\r\n]+/ /gs ;
    $title =~ s/<.*?>//gs ;
    $title =~ s/^\s+//gs ;
    $title =~ s/\s+$//gs ;
    $title =~ s/"/'/gs ;
    $mail{MIME}{From} = qq`"$title" <$mail{from}>` if $title ne '' ;
  }
  
  $mail{MIME}{To} = join(" , ", @{$mail{to}} ) ;
  $mail{MIME}{Cc} = join(" , ", @{$mail{cc}} ) if $mail{cc} ;

  $mail{MIME}{'Reply-To'} = $mail{reply} if $mail{reply} ;
  $mail{MIME}{'Errors-To'} = $mail{error} if $mail{error} ;
  
  $mail{MIME}{'Subject'} = $mail{subject} if $mail{subject} ;
  
  $mail{MIME}{'Mime-version'} = '1.0' ;
  $mail{MIME}{'X-Mailer'} = "Mail::SendEasy/$VERSION Perl/$]-$^O" ;
  $mail{MIME}{'Msg-ID'} = $mail{msgid} ;
  

  if ( defined $mail{msg} ) {
    $mail{msg} =~ s/\r\n?/\n/gs ;
    if ( $mail{msg} !~ /\n\n$/s) { $mail{msg} =~ s/\n?$/\n\n/s ;}
  
    my %part = (
    'Content-Type' => 'text/plain; charset=ISO-8859-1' ,
    'Content-Transfer-Encoding' => 'quoted-printable' ,
    'content' => &_encode_qp( $mail{msg} ) ,
    );
    
    push(@{$mail{MIME}{part}} , \%part ) ;
  }
  
  if ( defined $mail{html} ) {
    $mail{msg} =~ s/\r\n?/\n/gs ;
    
    my %part = (
    'Content-Type' => 'text/html; charset=ISO-8859-1' ,
    'Content-Transfer-Encoding' => 'quoted-printable' ,
    'content' => &_encode_qp( $mail{html} ) ,
    );
    
    push(@{$mail{MIME}{part}} , \%part ) ;
  }

  ## Content
  { 
    my $msg_part ;
    
    ## Alternative
    if ( $#{ $mail{MIME}{part} } == 1 ) {
      my $boudary = &_new_boundary() ;
      $msg_part .= qq`Content-Type: multipart/alternative; boundary="$boudary"\n\n`;
      
      $msg_part .= "This is a multi-part message in MIME format.\n" ;
      $msg_part .= "This message is in 2 versions: TXT and HTML\n" ;
      $msg_part .= "You need a reader with MIME to read this message!\n\n" ;
      
      $msg_part .= &_new_part($boudary , @{$mail{MIME}{part}}[0]) ;
      $msg_part .= &_new_part($boudary , @{$mail{MIME}{part}}[1]) ;
      $msg_part .= qq`--$boudary--\n` ;
      delete $mail{MIME}{part} ;
    }
    else { $msg_part .= &_new_part('' , @{$mail{MIME}{part}}[0]) ;}
    
    ## Mixed
    if ( $mail{anex} ) {
      my @anex = @{$mail{anex}} ;

      my $boudary = &_new_boundary() ;
      $mail{MIME}{content} .= qq`Content-Type: multipart/mixed; boundary="$boudary"\n\n`;
      $mail{MIME}{content} .= &_new_part($boudary , $msg_part) ;
      foreach my $anex_i ( @anex ) {
        $mail{MIME}{content} .= &_new_part($boudary , $anex_i) ;
        $anex_i = undef ;
      }
      $mail{MIME}{content} .= qq`--$boudary--\n` ;
      
      delete $mail{anex} ;
    }
    else { $mail{MIME}{content} = $msg_part ;}
  }
  
  $mail{MIME}{content} =~ s/\r\n?/\n/gs ;
  
  ## SEND #####################
  
  if ( ($SMTP->{USER} ne '' || $SMTP->{PASS} ne '') && $SMTP->auth_types ) {
    if ( !$SMTP->auth ) { return ;}
  }
  
  if ( $SMTP->MAIL("FROM:<$mail{from}>") !~ /^2/ ) { $ER = "MAIL FROM error (". $SMTP->last_response_line .")!" ; $SMTP->close ; return ;}
  
  foreach my $to ( @{$mail{to}} ) {
    if ( $SMTP->RCPT("TO:<$to>") !~ /^2/ ) { $ER = "RCPT error (". $SMTP->last_response_line .")!" ; $SMTP->close ; return ;}
  }
  

  foreach my $to ( @{$mail{cc}} ) {
    if ( $SMTP->RCPT("TO:<$to>") !~ /^2/ ) { $ER = "RCPT error (". $SMTP->last_response_line .")!" ; $SMTP->close ; return ;}
  }
  
  if ( $SMTP->DATA =~ /^3/ ) {
    &_send_MIME($SMTP , %mail) ;
    if ( $SMTP->DATAEND !~ /^2/ ) { $ER = "Message transmission failed (". $SMTP->last_response_line .")!" ; $SMTP->close ; return ;}
  }  
  else { $ER = "Can't send data (". $SMTP->last_response_line .")!" ; $SMTP->close ; return ;}
  
  $SMTP->close ;
  return 1 ;
}

##############
# _SEND_MIME #
##############

sub _send_MIME {
  my ( $SMTP , %mail ) = @_ ;
  
  my @order = qw(
  Date
  From
  To
  Cc
  Reply-To
  Errors-To
  Subject
  Msg-ID
  X-Mailer
  Mime-version
  );
  
  foreach my $order_i ( @order ) {
    if ( !defined $mail{MIME}{$order_i} ) { next ;}
    $SMTP->print("$order_i: " . $mail{MIME}{$order_i} . $RN) ;
  }
  
  $mail{MIME}{content} =~ s/\n/$RN/gs ;
  $SMTP->print($mail{MIME}{content}) ;
}

#############
# _NEW_PART #
#############

sub _new_part {
  my ( $boudary , $part ) = @_ ;
  my $new_part ;
      
  if ( !ref($part) ) {
    $new_part .= "--$boudary\n" if $boudary ;
    $new_part .= $part ;
    $new_part .= "\n" if $boudary ;
    return( $new_part ) ;
  }
  
  my @order = qw(
  Content-Type
  Content-Transfer-Encoding
  Content-Disposition
  );
  
  $new_part .= "--$boudary\n" if $boudary ;
  
  foreach my $order_i ( @order ) {
    if ( !defined $$part{$order_i} ) { next ;}
    my $val = $$part{$order_i} ;
    $new_part .= "$order_i: $val\n" ;
  }
  
  $new_part .= "\n" ;
  $new_part .= $$part{content} ;
  $new_part .= "\n" if $boudary ;
  
  return( $new_part ) ;
}

#################
# _NEW_BOUNDARY #
#################

sub _new_boundary {
  push my @lyb1,(qw(0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) ) ;
  push my @lyb2,(qw(0 1 2 3 4 5 6 7 8 9) ) ;
  
  my $boudary = "--=_Mail_SendEasy_" ;
  while( length($boudary) < 25 ) { $boudary .= @lyb1[rand(@lyb1)] ;}
  $boudary .= '_' ;
  while( length($boudary) < 31 ) { $boudary .= @lyb2[rand(@lyb2)] ;}
  $boudary .= '_' ;  
  $boudary .= time() ;
  
  return( $boudary ) ;
}

##############
# _ENCODE_QP # From MIME::QuotedPrint
##############

sub _encode_qp {
  my $res = shift;
  
  $res =~ s/^\./\.\./gom ;
  $res =~ s/\r\n?/\n/gs ;

  $res =~ s/([^ \t\n!<>~-])/sprintf("=%02X", ord($1))/eg ;

  $res =~ s/([ \t]+)$/ join('', map { sprintf("=%02X", ord($_)) } split('', $1) )/egm ;

  my $brokenlines = "" ;
  $brokenlines .= "$1=\n" while $res =~ s/(.*?^[^\n]{73} (?:
  [^=\n]{2} (?! [^=\n]{0,1} $) # 75 not followed by .?\n
  |[^=\n]    (?! [^=\n]{0,2} $) # 74 not followed by .?.?\n
  |          (?! [^=\n]{0,3} $) # 73 not followed by .?.?.?\n
  ))//xsm ;

  return "$brokenlines$res" ;
}

################
# _TO_ONE_LINE #
################

sub _to_one_line {
  $_[0] =~ s/[\r\n]+/ /gs ;
  $_[0] =~ s/^\s+//gs ;
  $_[0] =~ s/\s+$//gs ;
}

#################
# _CHECK_EMAILS #
#################

sub _check_emails {
  my @mails = split(/\s*(?:[;:,]+|\s+)\s*/s , $_[0]) ;
  @mails = @{$_[0]} if ref($_[0]) eq 'ARRAY' ;
  
  foreach my $mails_i ( @mails ) {
    &_to_one_line($mails_i) ;
    if ($mails_i eq '') { next ;}
    if (! &_format($mails_i) ) { $ER = "Invalid recipient: $mails_i" ; return( undef ) ;}
  }
  return( @mails ) ;
}

###########
# _FORMAT #
###########

sub _format {
  if ( $_[0] eq '' ) { return( undef ) ;}
  
  my ( $mail ) = @_ ;
  
  my $stat = 1 ;
  
  if ($mail !~ /^[\w\.-]+\@localhost$/gsi) {
    if ($mail !~ /^[\w\.-]+\@(?:[\w-]+\.)*?(?:\w+(?:-\w+)*)(?:\.\w+)+$/ ) { $stat = undef ;}
  }
  elsif ($mail !~ /^[\w\.-]+\@[\w-]+$/ ) { $stat = undef ;}
  
  return 1 if $stat ;
  return undef ;
}

################
# TIME_TO_DATE #
################

sub time_to_date {
  # convert a time() value to a date-time string according to RFC 822
  my $time = $_[0] || time();

  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my @wdays  = qw(Sun Mon Tue Wed Thu Fri Sat);

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time) ;

  my $TZ ;

  if ( $TZ eq "" ) {
    # offset in hours
    my $offset  = sprintf "%.1f", (timegm(localtime) - time) / 3600;
    my $minutes = sprintf "%02d", ( $offset - int($offset) ) * 60;
    $TZ  = sprintf("%+03d", int($offset)) . $minutes;
  }
  
  return join(" ",
  ($wdays[$wday] . ','),
  $mday,
  $months[$mon],
  $year+1900,
  sprintf("%02d", $hour) . ":" . sprintf("%02d", $min),
  $TZ
  );
}

#######
# CAT #
#######

sub cat {
  my ( $file ) = @_ ;
  if (ref($file) eq 'SCALAR') { $file = ${$file} ;}
  
  my $fh = $file ;
  if (ref($fh) ne 'GLOB') { open($fh,$file) ; binmode($fh) ;}
  
  if ( *{$fh}->{DATA} && *{$fh}->{content} ne '' ) { return( *{$fh}->{content} ) ;}
  
  my $data ;
  seek($fh,0,1) if ! *{$fh}->{DATA} ;
  1 while( read($fh, $data , 1024*8*2 , length($data) ) ) ;
  close($fh) ;

  return( $data ) ;
}

#########
# ERROR #
#########

sub error { return( $ER ) ;}

########
# WARN #
########

sub warn {
  my $this = UNIVERSAL::isa($_[0] , 'Mail::SendEasy') ? shift : undef ;
  $ER = $_[0] ;
}

##############
# _ZIP_ANEXS #
##############

sub _zip_anexs {
  my $zip_name = shift ;
  my $def_name ;
  if ($zip_name !~ /\.zip$/i) { $zip_name = 'anex.zip' ; $def_name = 1 ;}
  
  my $zip_content ;
  my $IO = Mail::SendEasy::IOScalar->new(\$zip_content) ;
  
  my $zip = Archive::Zip->new() ;
  
  my $anex1 ;
  foreach my $anex_i ( @_ ) {
    my ($filename) = ( $anex_i =~ /\/*([^\/]+)$/ ) ;
    $anex1 = $filename ;
    $zip->addFile($anex_i , $filename) ;
  }
  
  my $status = $zip->writeToFileHandle($IO) ;
  
  if ($def_name && $#_ == 0) { $zip_name = $anex1 ;}
  
  $zip_name =~ s/\s+/_/gs ;
  $zip_name =~ s/^\.+// ;
  $zip_name =~ s/\.\.+/\./ ;
  $zip_name =~ s/\.[^\.]+$// ;
  $zip_name .= ".zip" ;
  
  return( $zip_name , $zip_content ) ;
}

#######
# END #
#######

1;


__END__

=head1 NAME

Mail::SendEasy - Send plain/html e-mails through SMTP servers (platform independent). Supports SMTP authentication and attachments.

=head1 DESCRIPTION

This modules will send in a easy way e-mails, and doesn't have dependencies. Soo, you don't need to install I<libnet>.

It supports SMTP authentication and attachments.

=head1 USAGE

=head2 OO

  use Mail::SendEasy ;

  my $mail = new Mail::SendEasy(
  smtp => 'localhost' ,
  user => 'foo' ,
  pass => 123 ,
  ) ;
  
  my $status = $mail->send(
  from    => 'sender@foo.com' ,
  from_title => 'Foo Name' ,
  reply   => 're@foo.com' ,
  error   => 'error@foo.com' ,
  to      => 'recp@domain.foo' ,
  cc      => 'recpcopy@domain.foo' ,
  subject => "MAIL Test" ,
  msg     => "The Plain Msg..." ,
  html    => "<b>The HTML Msg...</b>" ,
  msgid   => "0101" ,
  ) ;
  
  if (!$status) { print $mail->error ;}

=head2 STRUCTURED

  use Mail::SendEasy ;

  my $status = Mail::SendEasy::send(
  smtp => 'localhost' ,
  user => 'foo' ,
  pass => 123 ,
  from    => 'sender@foo.com' ,
  from_title => 'Foo Name' ,
  reply   => 're@foo.com' ,
  error   => 'error@foo.com' ,
  to      => 'recp@domain.foo' ,
  cc      => 'recpcopy@domain.foo' ,
  subject => "MAIL Test" ,
  msg     => "The Plain Msg..." ,
  html    => "<b>The HTML Msg...</b>" ,
  msgid   => "0101" ,
  ) ;
  
  if (!$status) { Mail::SendEasy::error ;}

=head1 METHODS

=head2 new (%OPTIONS)

B<%OPTIONS:>

=over 4

=item smtp

The SMTP server. (Default: I<localhost>)

=item port

The SMTP port. (Default: I<25>)

=item timeout

The time to wait for the connection and data. (Default: I<120>)

=item user

The username for authentication.

=item pass

The password for authentication.

=back

=head2 send (%OPTIONS)

B<%OPTIONS:>

=over 4

=item from

The e-mail adress of the sender. (Only accept one adress).

=item from_title

The name or title of the sender.

=item reply

E-mail used to reply to your e-mail.

=item error

E-mail to send error messages.

=item to

Recipient e-mail adresses.

=item cc

Adresses to receive a copy.

=item subject

The subject of your e-mail.

=item msg

The plain message.

=item html

The HTML message. If used with MSG (plain), the format "multipart/alternative" will be used.
Readers that can read HTML messages will use the HTML argument, and readers with only plain messages will use MSG.

=item msgid

An ID to insert in the e-mail Headers. The header will be:
Msg-ID: xxxxx

=item anex

Send file(s) attached. Just put the right path in the machine for the file. For more than one file use ARRAY ref: ['file1','file2']

** Will load all the files in the memory.

=item zipanex

Compress with zip the ANEX (attached) file(s). All the files will be inside the same zip file.

If the argument has the extension .zip, will be used for the name of the zip file. If not, the file will be "anex.zip",
and if exist only one ANEX, the name will be the same of the ANEX, but with the extension .zip.

** Need the module Archive::Zip installed or the argument will be skipped.

** This will generate the zip file in the memory.

=back

=head1 SEE ALSO

L<Mail::SendEasy::SMTP>, L<Mail::SendEasy::AUTH>, L<HPL>.

B<This module was created to handle the e-mail system of L<HPL>.>

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

