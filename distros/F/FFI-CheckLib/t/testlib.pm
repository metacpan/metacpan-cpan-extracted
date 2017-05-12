package
  MyDynaLoader;

use strict;
use warnings;

$INC{'MyDynaLoader.pm'} = __FILE__;

do {
  my @libref = ('null');

  sub dl_load_file
  {
    my($filename, $flags) = @_;
    return undef unless -e $filename;
    my $libref = scalar @libref;
    $libref[$libref] = TestDLL->new($filename);
    $libref;
  }

  sub dl_unload_file
  {
    my($libref) = @_;
    delete $libref[$libref];
  }

  sub dl_find_symbol
  {
    my($libref, $symbol) = @_;
    my $lib = $libref[$libref];
    $lib->has_symbol($symbol);
  }
};

package
  TestDLL;

sub new
{
  my($class, $filename) = @_;
  
  my @list = do {
    my $fh;
    open $fh, '<', $filename;
    my @list = <$fh>;
    close $fh;
    @list;
  };
  
  chomp @list;
  
  my $name = shift @list;
  my $version = shift @list;
  my %symbols = map { $_ => 1 } @list;
  
  bless {
    filename => $filename,
    name     => $name,
    version  => $version,
    symbols  => \%symbols,
  }, $class;
}

sub filename { shift->{filename} }
sub name { shift->{name} }
sub version { shift->{version} }
sub has_symbol { $_[0]->{symbols}->{$_[1]} }


package
  main;

*CORE::GLOBAL::exit = sub { die "::exit::" };

1;
