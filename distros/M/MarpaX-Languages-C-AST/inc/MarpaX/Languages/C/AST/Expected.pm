use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Expected;
use Data::Dumper;
use IO::File;
use File::Basename;
use File::Spec;

sub value {
  my ($class, $got) = @_;

  my ($filename, $directories, $suffix) = fileparse($0, qr/\.[^.]*/);
  my $datafilename = File::Spec->catfile($directories, "$filename.data");
  if ($ENV{RELEASE_TESTING} || 0) {
    #
    # Untaint $datafilename
    #
    ($datafilename) = $datafilename =~ /^(.*)$/;
    my $fh = IO::File->new($datafilename, 'w');
    my $d = Data::Dumper->new([$got]);
    $d->Purity(1)->Terse(1)->Deepcopy(1);
    print $fh $d->Dump;
    undef $fh;
  }
  my $fh = IO::File->new($datafilename, 'r');
  $fh->untaint;
  my $data = do { local $/; <$fh> };
  undef $fh;
  my $expected = eval $data;

  return $expected;
}

1;
