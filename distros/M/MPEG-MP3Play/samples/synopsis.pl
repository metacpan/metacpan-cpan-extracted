use MPEG::MP3Play;
my $mp3 = new MPEG::MP3Play;
  
$mp3->open ("test.mp3");
$mp3->play;
$mp3->message_handler;
