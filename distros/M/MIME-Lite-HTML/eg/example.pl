#!/usr/bin/env perl

  use MIME::Lite;
  use MIME::Lite::HTML;

  my $mailHTML = new MIME::Lite::HTML
     From     => 'alian@saturne.alianet',
     To       => 'alian@jupiter.alianet',
     Subject  => 'Mail in HTML with images',
     Debug    => 1,
     IncludeType => 'cid';

  $MIMEmail = $mailHTML->parse('http://alianwebserver.alianet',"et alors ?");
  print "Taille:",$mailHTML->size(),"\n"; 
  $MIMEmail->send; # or for win user : $mail->send_by_smtp('smtp.fai.com');
  # print $MIMEmail->as_string;
