package MySAX;
use base qw (XML::SAX::Base);

sub start_element {
    my $self = shift;
    my $data = shift;

    $self->SUPER::start_element($data);

    if ($data->{Name} eq "body") {
       $self->SUPER::start_element({Name=>"h1"});
       $self->SUPER::characters({Data=>"hello world"});
       $self->SUPER::end_element({Name=>"h1"});
    }
}

package main;
use strict;

BEGIN { $| = 1; print "1..1\n"; }

use Cwd;
use Image::Shoehorn::Gallery;

{
  &main();
  exit;
}

sub main {
  my $directory = &Cwd::getcwd()."/example";

  if (! -d $directory) {
    print 
      "Eh what? '$directory' is not a directory!\n",
      "not ok 1\n";

    return 0;
  }

  Image::Shoehorn::Gallery->create({
				    directory => $directory,
				    url       => "http://mysite.com/example",
				    static    => 1,
				    verbose   => 1,
				    set_index_images => {default => 1},
				    scales    => [
						  [ "thumb" , "75x50" ],
						  [ "small" , "25%"   ],
						  [ "medium", "50%"   ],
						 ],
				    iptc => [
					     "headline",
					     "city",
					     "caption/abstract",
					    ],
				    exif => [
					     "FNumber",
					     "ShutterSpeedValue",
					     "ExposureTime",
					     "DateTimeOriginal",
					    ],
				    set_encoding => "ISO-8859-1",
				    set_filters => { image => [ MySAX->new() ] },
				   });

  print 
    "ok 1\n",
    "Passed all tests.\n";

  return 1;
}
