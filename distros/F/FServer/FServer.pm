package FServer;
use strict;

sub new {
  my ($text, $font) = @_;
  if (!$font) { $font = "standard"; }
  my $self = {
	"text"	=> $text,
	"font"	=> $font
  };
  bless $self, 'FServer';
  return $self;
}

sub display {
  my ($object) = shift;
  open (FileIN, "fonts/".$object->{'font'}.".flf") || die $!;
  my @FileTable = <FileIN>;
  close(FileIN);
  my $FontHeight = substr($FileTable[0], 7,1);
  my %FontData = ();
  for (my $i=0; $i<@FileTable; $i++) {
    chomp($FileTable[$i]);
    if (index($FileTable[$i], "@@") != -1) {
      my $temp = $FontHeight-1;
      for (my $j=0;$j<=$FontHeight-2;$j++) {
        $FontData{substr($FileTable[$i], -1,1)}->[$j] = substr($FileTable[$i-$temp], 0, length($FileTable[$i-$temp])-1);
        $temp--;
      }
      $FontData{substr($FileTable[$i], -1,1)}->[$FontHeight-1] = substr($FileTable[$i], 0, length($FileTable[$i])-3);
    }
  }
  my $Result = "";
  for (my $k=0; $k<$FontHeight; $k++) {
    for (my $l=0;$l<=length($object->{'text'})-1;$l++){
      $FontData{substr($object->{'text'}, $l, 1)}->[$k] =~ tr/\$/ /;
      $Result .= $FontData{substr($object->{'text'}, $l, 1)}->[$k];
    }
    $Result .= "\n";
  }
  return $Result;
}
1;
