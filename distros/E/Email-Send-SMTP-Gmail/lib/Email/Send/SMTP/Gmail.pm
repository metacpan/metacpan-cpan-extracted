package Email::Send::SMTP::Gmail;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION='1.06';
require Net::SMTPS;
require Net::SMTP;
use MIME::Base64;
use File::Spec;
use LWP::MediaTypes;
use Email::Date::Format qw(email_date);

sub new{
  my $class=shift;
  my $self={@_};
  bless($self, $class);
  my %properties=@_;
  my $smtp='smtp.gmail.com'; # Default value
  my $port='default'; # Default value
  my $layer='tls'; # Default value
  my $auth='LOGIN'; # Default
  my $ssl_verify_mode=''; #Default - Warning SSL_VERIFY_NONE
  my $ssl_version='';
  my $timeout=60;

  $smtp=$properties{'-smtp'} if defined $properties{'-smtp'};
  $port=$properties{'-port'} if defined $properties{'-port'};
  $layer=$properties{'-layer'} if defined $properties{'-layer'};
  $auth=$properties{'-auth'} if defined $properties{'-auth'};
  $ssl_verify_mode=$properties{'-ssl_verify_mode'} if defined $properties{'-ssl_verify_mode'};
  $ssl_version=$properties{'-ssl_version'} if defined $properties{'-ssl_version'};
  $timeout=$properties{'-timeout'} if defined $properties{'-timeout'};

  if(defined $properties{'-from'}){
    $self->{from}=$properties{'-from'};
  }
  else{
    $self->{from}=$properties{'-login'};
  }

  my $connect=$self->_initsmtp($smtp,$port,$properties{'-login'},$properties{'-pass'},$layer,$auth,$properties{'-debug'},$ssl_verify_mode,$ssl_version,$properties{'-ssl_verify_path'},$properties{'-$ssl_verify_ca'},$timeout);

  return -1,$self->{error} if(defined $self->{error});
#  return $connect if($connect==-1);
#
  return $self;
}

sub _initsmtp{
  my $self=shift;
  my $smtp=shift;
  my $port=shift;
  my $login=shift;
  my $pass=shift;
  my $layer=shift;
  my $auth=shift;
  my $debug=shift;
  my $ssl_mode=shift;
  my $ssl_version=shift;
  my $ssl_path=shift;
  my $ssl_ca=shift;
  my $timeout=shift;

  # The module sets the SMTP google but could use another!
  # Set port if default
  if($port eq 'default'){
      if($layer eq 'ssl'){
          $port=465;
      }
      else{
          $port=25;
      }
  }
 print "Connecting to $smtp using $layer with $auth on port $port and timeout of $timeout\n" if $debug;
  # Set security layer from $layer
  if($layer eq 'none')
  {
    if (not $self->{sender} = Net::SMTP->new($smtp, Port =>$port, Debug=>$debug, Timeout=>$timeout)){
      my $error_string=$self->{sender}->message();
      chomp $error_string;
      $self->{error}=$error_string;
      print "Could not connect to SMTP server ($smtp $port)\n" if $debug;
      return $self;
      #return -1;
    }
  }
  else{
    my $sec=undef;
    if($layer eq 'tls'){$sec='starttls';}
    elsif($layer eq 'ssl'){$sec='ssl';}
    if (not $self->{sender} = Net::SMTPS->new($smtp, Port =>$port, doSSL=>$sec, Debug=>$debug, SSL_verify_mode=>$ssl_mode, SSL_version=>$ssl_version,SSL_ca_file=>$ssl_ca,SSL_ca_path=>$ssl_path, Timeout=>$timeout)){
      #my $error_string=$self->{sender}->message();
      #chomp $error_string;
      # $self->{error}=$error_string;
      $self->{error}=$@;
      print "Could not connect to SMTP server\n" if $debug;
      return $self;
      #return -1;
    }
  }
  if($auth ne 'none'){
     unless($self->{sender}->auth($login,$pass,$auth)){
         my $error_string=$self->{sender}->message();
         chomp $error_string;
         $self->{error}=$error_string;
         print "Authentication (SMTP) failed\n" if $debug;
         #return -1;
     }
  }
  return $self;
}

sub bye{
  my $self=shift;
  $self->{sender}->quit();
  return $self;
}

sub banner{
  my $self=shift;
  my $banner=$self->{sender}->banner();
  chomp $banner;
  return $banner;
}

sub _checkfiles
{
# Checks that all the attachments exist
  my $attachs=shift;
  my $verbose=shift;

  my $result=''; # list of valid attachments

  my @attachments=split(/,/,$attachs);
  foreach my $attach(@attachments)
  {
     $attach=~s/\A[\s,\0,\t,\n,\r]*//;
     $attach=~s/[\s,\0,\t,\n,\r]*\Z//;

     unless (-f $attach) {
       print "Unable to find the attachment file: $attach (removed from list)\n" if $verbose;
     }
     else{
       my $opened=open(my $file,'<',$attach);
       if( not $opened){
         print "Unable to open the attachment file: $attach (removed from list)\n" if $verbose;
       }
       else{
         close $file;
         $result.=','.$attach;
         print "Attachment file: $attach added\n" if $verbose;
       }
     }
  }
  $result=~s/\A\,//;
  return $result;
}

sub _checkfilelist
{
# Checks that all the attachments exist
  my $attachs=shift;
  my $verbose=shift;

  my $result=undef; # list of valid attachments
  my $i=0;

  foreach my $attach(@$attachs)
  {
     $attach->{file}=~s/\A[\s,\0,\t,\n,\r]*//;
     $attach->{file}=~s/[\s,\0,\t,\n,\r]*\Z//;

     unless (-f $attach->{file}) {
       print "Unable to find the attachment file: $attach->{file} (removed from list)\n" if $verbose;
     }
     else{
       my $opened=open(my $file,'<',$attach->{file});
       if( not $opened){
          print "Unable to open the attachment file: $attach->{file} (removed from list)\n" if $verbose;
       }
       else{
         close $file;
         $result->[$i]->{file}=$attach->{file};
         $i++;
         print "Attachment file: $attach->{file} added\n" if $verbose;
       }
     }
  }
  return $result;
}

sub _createboundary
{
# Create arbitrary frontier text used to separate different parts of the message
  return "This-is-a-mail-boundary-8217539";
}

sub send
{
  my $self=shift;
  my %properties=@_; # rest of params by hash

  my $verbose=0;
  $verbose=$properties{'-verbose'} if defined $properties{'-verbose'};
  # Load all the email param
  my $mail;

  
  $mail->{to}=$properties{'-to'} if defined $properties{'-to'};

  $mail->{to}=' ' if((not defined $mail->{to}) or ($mail->{to} eq ''));

  $mail->{from}=$self->{from};
  $mail->{from}=$properties{'-from'} if defined $properties{'-from'};

  $mail->{replyto}=$mail->{from};
  $mail->{replyto}=$properties{'-replyto'} if defined $properties{'-replyto'};

  $mail->{cc}='';
  $mail->{cc}=$properties{'-cc'} if defined $properties{'-cc'};

  $mail->{bcc}='';
  $mail->{bcc}=$properties{'-bcc'} if defined $properties{'-bcc'};

  $mail->{charset}='UTF-8';
  $mail->{charset}=$properties{'-charset'} if defined $properties{'-charset'};

  $mail->{contenttype}='text/plain';
  $mail->{contenttype}=$properties{'-contenttype'} if defined $properties{'-contenttype'};

  $mail->{subject}='';
  $mail->{subject}=$properties{'-subject'} if defined $properties{'-subject'};

  $mail->{body}='';
  $mail->{body}=$properties{'-body'} if defined $properties{'-body'};

  $mail->{attachments}='';
  $mail->{attachments}=$properties{'-attachments'} if defined $properties{'-attachments'};

  $mail->{attachmentlist}=$properties{'-attachmentlist'} if defined $properties{'-attachmentlist'};

#  if(($mail->{attachments} ne '')and($self->_checkfiles($mail->{attachments})))
  if($mail->{attachments} ne '')
  {
      $mail->{attachments}=_checkfiles($mail->{attachments},$verbose);
      print "Attachments separated by comma successfully verified\n" if $verbose;
  }
#  if((defined $mail->{attachmentlist})and($self->_checkfilelist($mail->{attachmentlist}))){
  if(defined $mail->{attachmentlist}){
      $mail->{attachmentlist}=_checkfilelist($mail->{attachmentlist},$verbose);
      print "Attachments \@list successfully verified\n" if $verbose;
  }

  # eval{
      my $boundary=_createboundary();

      $self->{sender}->mail($mail->{from} . "\n");

      my @recepients = split(/,/, $mail->{to});
      foreach my $recp (@recepients) {
          $self->{sender}->to($recp . "\n");
      }
      my @ccrecepients = split(/,/, $mail->{cc});
      foreach my $recp (@ccrecepients) {
          $self->{sender}->cc($recp . "\n");
      }
      my @bccrecepients = split(/,/, $mail->{bcc});
      foreach my $recp (@bccrecepients) {
          $self->{sender}->bcc($recp . "\n");
      }

      $self->{sender}->data();

      #Send header
      $self->{sender}->datasend("From: " . $mail->{from} . "\n");
      $self->{sender}->datasend("To: " . $mail->{to} . "\n");
      $self->{sender}->datasend("Cc: " . $mail->{cc} . "\n") if ($mail->{cc} ne '');
      $self->{sender}->datasend("Reply-To: " . $mail->{replyto} . "\n");
      $self->{sender}->datasend("Subject: " . $mail->{subject} . "\n");
      $self->{sender}->datasend("Date: " . email_date(). "\n");

      if($mail->{attachments} ne '')
      {
        print "With Attachments\n" if $verbose;
        $self->{sender}->datasend("MIME-Version: 1.0\n");
        if ((defined $properties{'-disposition'}) and ('inline' eq lc($properties{'-disposition'}))) {
           $self->{sender}->datasend("Content-Type: multipart/related; BOUNDARY=\"$boundary\"\n");
        }
        else {
           $self->{sender}->datasend("Content-Type: multipart/mixed; BOUNDARY=\"$boundary\"\n");
       }

        # Send text body
        $self->{sender}->datasend("\n--$boundary\n");
        $self->{sender}->datasend("Content-Type: ".$mail->{contenttype}."; charset=".$mail->{charset}."\n");

        $self->{sender}->datasend("\n");

        #################################################
        # Chunk body in sections (Gmail SMTP limitations)
        #my @groups_body = split(/(.{76})/,$mail->{body});
        #$self->{sender}->datasend($_) foreach @groups_body;

        # Or better. Encode and split
        #my $str=encode_base64($mail->{body});
        #my @groups_body = split(/(.{76})/,$str);
        #$self->{sender}->datasend($_) foreach @groups_body;

        # Limitation removed
        $self->{sender}->datasend($mail->{body});
        ##################################################

        $self->{sender}->datasend("\n\n");

        my @attachments=split(/,/,$mail->{attachments});

        foreach my $attach(@attachments)
        {
            #my($bytesread, $buffer, $data, $total);

           $attach=~s/\A[\s,\0,\t,\n,\r]*//;
           $attach=~s/[\s,\0,\t,\n,\r]*\Z//;

           # Get the file name without its directory
           my ($volume, $dir, $fileName) = File::Spec->splitpath($attach);
           # Get the MIME type
           my $contentType = guess_media_type($attach);
           print "Composing MIME with attach $attach\n" if $verbose;

           $self->{sender}->datasend("--$boundary\n");
           $self->{sender}->datasend("Content-Type: $contentType; name=\"$fileName\"\n");
           $self->{sender}->datasend("Content-Transfer-Encoding: base64\n");
           if ((defined $properties{'-disposition'}) and ('inline' eq lc($properties{'-disposition'}))) {
              $self->{sender}->datasend("Content-ID: <$fileName>\n");
              $self->{sender}->datasend("Content-Disposition: inline; =filename=\"$fileName\"\n\n");
           }
           else {
             $self->{sender}->datasend("Content-Disposition: attachment; =filename=\"$fileName\"\n\n");
           }

           # Google requires us to divide the attachment
           # First read -> Encode -> Send in chunks of 76
           # Read
           my $opened=open(my $file,'<',$attach);
           binmode($file);
           # Encode
           local $/ = undef;
           my $d=<$file>;
           my $str=encode_base64($d);
           # Chunks by 76
           my @groups = split(/(.{76})/,$str);
           $self->{sender}->datasend($_) foreach @groups;
           close $file;

           #$self->{sender}->datasend("--$boundary\n"); # avoid dummy attachment
         }
         $self->{sender}->datasend("\n--$boundary--\n"); # send endboundary end message
      }
      elsif(defined $mail->{attachmentlist})
      {
        print "With Attachments\n" if $verbose;
        $self->{sender}->datasend("MIME-Version: 1.0\n");
        #  $self->{sender}->datasend("Content-Type: multipart/mixed; BOUNDARY=\"$boundary\"\n");
        if ((defined $properties{'-disposition'}) and ('inline' eq lc($properties{'-disposition'}))) {
            $self->{sender}->datasend("Content-Type: multipart/related; BOUNDARY=\"$boundary\"\n");
        }
        else {
           $self->{sender}->datasend("Content-Type: multipart/mixed; BOUNDARY=\"$boundary\"\n");
       }

        # Send text body
        $self->{sender}->datasend("\n--$boundary\n");
        $self->{sender}->datasend("Content-Type: ".$mail->{contenttype}."; charset=".$mail->{charset}."\n");

        $self->{sender}->datasend("\n");

        # Chunk body in sections (Gmail SMTP limitations)
        #$self->{sender}->datasend($mail->{body} . "\n\n");
        my @groups_body = split(/(.{76})/,$mail->{body});
        $self->{sender}->datasend($_) foreach @groups_body;
        $self->{sender}->datasend("\n\n");

        my $attachments=$mail->{attachmentlist};
        foreach my $attach(@$attachments)
        {
            #my($bytesread, $buffer, $data, $total);

           $attach->{file}=~s/\A[\s,\0,\t,\n,\r]*//;
           $attach->{file}=~s/[\s,\0,\t,\n,\r]*\Z//;

           my ($volume, $dir, $fileName) = File::Spec->splitpath($attach->{file});
           # Get the MIME type
           my $contentType = guess_media_type($attach->{file});
           print "Composing MIME with attach $attach->{file}\n" if $verbose;

           $self->{sender}->datasend("--$boundary\n");
           $self->{sender}->datasend("Content-Type: $contentType; name=\"$fileName\"\n");
           $self->{sender}->datasend("Content-Transfer-Encoding: base64\n");
           if ((defined $properties{'-disposition'}) and ('inline' eq lc($properties{'-disposition'}))) {
              $self->{sender}->datasend("Content-ID: <$fileName>\n");
              $self->{sender}->datasend("Content-Disposition: inline; =filename=\"$fileName\"\n\n");
           }
           else {
             $self->{sender}->datasend("Content-Disposition: attachment; =filename=\"$fileName\"\n\n");
           }
           # $self->{sender}->datasend("Content-Disposition: attachment; =filename=\"$fileName\"\n\n");

           # Google requires us to divide the attachment
           # First read -> Encode -> Send in chunks of 76
           # Read
           my $opened=open(my $file,'<',$attach->{file});
           binmode($file);
           # Encode
           local $/ = undef;
           my $d=<$file>;
           my $str=encode_base64($d);
           # Chunks by 76
           my @groups = split(/(.{76})/,$str);
           $self->{sender}->datasend($_) foreach @groups;
           close $file;

           #$self->{sender}->datasend("--$boundary\n"); # to avoid noname.txt dummy attachment
        }
        $self->{sender}->datasend("\n--$boundary--\n"); # send endboundary end message
      }
      else { # No attachment
        print "With No attachments\n" if $verbose;
        # Send text body
        $self->{sender}->datasend("MIME-Version: 1.0\n");
        $self->{sender}->datasend("Content-Type: ".$mail->{contenttype}."; charset=".$mail->{charset}."\n");

        $self->{sender}->datasend("\n");
        # Chunk body in sections (Gmail SMTP limitations)
        #$self->{sender}->datasend($mail->{body} . "\n\n");
        my @groups_body = split(/(.{76})/,$mail->{body});
        $self->{sender}->datasend($_) foreach @groups_body;
      }

      $self->{sender}->datasend("\n");

      if($self->{sender}->dataend()) {
          print "Email sent\n" if $verbose;
          return 1;
      }
      else{
          my $error_string=$self->{sender}->message();
          chomp $error_string;
          $self->{error}=$error_string;

          print "Sorry, there was an error during sending. Please, retry or use Debug\n" if $verbose;
          return -1,$self->{error};
      }

}

1;
__END__

=head1 NAME

Email::Send::SMTP::Gmail - Sends emails with attachments supporting Auth over TLS or SSL (for example: Google's SMTP).

=head1 SYNOPSIS

   use strict;
   use warnings;

   use Email::Send::SMTP::Gmail;

   my ($mail,$error)=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
                                                    -login=>'whateveraddress@gmail.com',
                                                    -pass=>'whatever_pass');

   print "session error: $error" unless ($email!=-1);

   $mail->send(-to=>'target@xxx.com', -subject=>'Hello!', -body=>'Just testing it',
               -attachments=>'full_path_to_file');

   $mail->bye;

=head1 DESCRIPTION

Simple module to send emails through Google's SMTP with or without attachments. Also supports regular Servers (with plain or none auth).
Works with regular Gmail accounts as with Google Apps (your own domains).
It supports basic functions such as CC, BCC, ReplyTo.

=over

=item new(-login=>'', -pass=>'' [,-smtp=>'',layer=>'',-port=>'',-debug=>''])

It creates the object and opens a session with the SMTP.

=over

=item I<smtp>: defines SMTP server. Default value: smtp.gmail.com

=item I<layer>: defines the secure layer to use. It could be 'tls', 'ssl' or 'none'. Default value: tls

=item I<port>: defines the port to use. Default values are 25 for tls and 465 for ssl

=item I<timeout>: defined Timeout for the connection. Default is 60 secs

=item I<auth>: defines the authentication method: ANONYMOUS, CRAM-MD5, DIGEST-MD5, EXTERNAL, GSSAPI, LOGIN (default) and PLAIN. It's currently based on SASL::Perl module

=item I<debug>: see the log information

Also supports SSL parameters as:

=item I<ssl_verify_mode>: SSL_VERIFY_NONE | SSL_VERIFY_PEER

=item I<ssl_version>: SSLv23 | ''

=item I<ssl_verify_path>: SSL_ca_path if SSL_VERIFY_PEER

=item I<ssl_verify_file>: SSL_ca_file if SSL_VERIFY_PEER



=back

=item send(-from=>'', -to=>'', [-subject=>'', -cc=>'', -bcc=>'', -replyto=>'', -charset=>'', -body=>'', -attachments=>'', disposition=>'', -verbose=>'1'])

It composes and sends the email in one shot

=over

=item I<to, cc, bcc>: comma separated email addresses

=item I<contenttype>: Content-Type for the body message. Examples are: text/plain (default), text/html, etc.

=item I<disposition>: Set "inline" in sending embeeded attachments. For example using <body><img src="cid:logo.png"><br>Test with Image</body>

=item I<attachments>: comma separated files with full path

=item I<attachmentslist>: hashref $list, in format $list->[x]->{name} of files with full path. Example: $list->[0]->{file}='/full_path/file.pdf'


=back

=item bye

Closes the SMTP session

=back

=over

=item banner

Returns SMTP banner

=back

=head1 Examples

Examples

=over

Send email composed in HTML using Gmail

      use strict;
      use warnings;
      use Email::Send::SMTP::Gmail;
      my ($mail,$error)=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
                                                       -login=>'whateveraddress@gmail.com',
                                                       -pass=>'whatever_pass');

      print "session error: $error" unless ($email!=-1);

      $mail->send(-to=>'target@xxx.com', -subject=>'Hello!',
                  -body=>'Just testing it<br>Bye!',-contenttype=>'text/html');
      $mail->bye;

Send email using a SMTP server without secure layer and authentication

      use strict;
      use warnings;
      use Email::Send::SMTP::Gmail;
      my $mail=Email::Send::SMTP::Gmail->new( -smtp=>'my.smtp.server',-layer=>'none', -auth=>'none');

      $mail->send(-from=>'sender@yyy.com', -to=>'target@xxx.com', -subject=>'Hello!',
                  -body=>'Quick email');
      $mail->bye;

Send email with attachments in comma separated format

      use strict;
      use warnings;
      use Email::Send::SMTP::Gmail;
      my $mail=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
                                              -login=>'whateveraddress@gmail.com',
                                              -pass=>'whatever_pass');

      $mail->send(-to=>'target@xxx.com', -subject=>'Hello!',
                  -body=>'Just testing it<br>Bye!',-contenttype=>'text/html',
                  -attachments=>'/full_path/file1.pdf,/full_path/file2.pdf');
      $mail->bye;

Send email with attachments using hashref

      use strict;
      use warnings;
      use Email::Send::SMTP::Gmail;
      my $mail=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
                                              -login=>'whateveraddress@gmail.com',
                                              -pass=>'whatever_pass');

      my $att;
      $att->[0]->{file}='/full_path/file.pdf';
      $att->[1]->{file}='/full_path/file1.pdf';

      $mail->send(-to=>'target@xxx.com', -subject=>'Hello!',
                  -body=>'Just testing it<br>Bye!',-contenttype=>'text/html',
                  -attachmentlist=>$att);
      $mail->bye;

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-send-smtp-gmail at rt.cpan.org> or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Send-SMTP-Gmail>.
You will automatically be notified of the progress on your bug as we make the changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Send::SMTP::Gmail

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Send-SMTP-Gmail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Send-SMTP-Gmail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Send-SMTP-Gmail>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Send-SMTP-Gmail/>

=item * Repository

L<http://github.com/NoAuth/Bugs.html?Dist=Email-Send-SMTP-Gmail>

=back

=head1 AUTHORS

Juan Jose 'Peco' San Martin, C<< <peco at cpan.org> >>

Martin Vukovic, C<< <mvukovic at microbotica.es> >>

Flaviano Tresoldi, C<< <info at swwork.it> >>

Narcyz Knap, C<< <narcyz at gumed.edu.pl> >>

Devin Ceartas, C<< <devin@nacredata.com> >>

=head1 COPYRIGHT

Copyright 2015 Microbotica

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
