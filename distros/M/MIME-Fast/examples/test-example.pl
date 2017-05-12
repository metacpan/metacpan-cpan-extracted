
  use MIME::Fast;
  use strict;

  open (FH,"<test.eml") || die "Can not open test.eml: $!";
  
  # create a stream
  my $str = new MIME::Fast::Stream (\*FH);
  # do not use/close FH now
  # with gmime 2.0.8 close(FH) would even fail
  # after $str destruction
  
  # construct message object
  my $msg = MIME::Fast::Parser::construct_message ($str);

  $msg->set_subject ( 'Re: ' . $msg->get_subject () );

  print 'Content-Type of message is ' .
    $msg->get_mime_part->get_content_type->to_string . "\n";

  my $part = $msg->get_mime_part;
  print "Part=$part\n";
  
  if (ref $part eq 'MIME::Fast::MultiPart') {
    $part = $part->get_part(0,0);
    print "Subpart=$part\n";
  }

  my %header;
  tie %header, 'MIME::Fast::Hash::Header', $msg;
  $header{'From'} = 'John Doe <john@domain>';
  $header{'X-Info'} = 'Normal one arbitrary header';
  $header{'X-Info'} = ['This is','Multiline X-Info header'];
  print "X-Info: " . $header{'X-Info'};
  print "\n";
  print "X-Info header array: (" . join("; ", @{$header{'X-Info'}}) . ")\n";
  my $old_header = $header{'X-Info'};
  $header{'X-Info'} = [ 'First header', @{$old_header}, 'Last header'];
  print "X-Info header array: (" . join("; ", @{$header{'X-Info'}}) . ")\n";
  print "\n";
  print "-- NEW HEADERS:\n";
  print $msg->get_headers();


