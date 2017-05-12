package Local::Foo;

use Log4Perl::ImportHandle LOG => 'area1', LOG2 => 'area2';

sub new {
  return bless {}, shift;  
};


sub test {
  my $this=shift;

  return LOG->debug('inside Local::Foo');

}


sub test2 {
  my $this=shift;

  return LOG2->debug('inside Local::Foo 2');

}


1;
