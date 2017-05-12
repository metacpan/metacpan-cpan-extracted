use JPEG::Comment;
open FILE, "1pix.jpg";
binmode FILE;
my $buf;
read FILE, $buf, -s FILE;

my $comment="He did not wear his scarlet coat";

open OFILE, ">ofile.jpg";
binmode OFILE;
print OFILE jpgcomment($buf, $comment);
