package Local::Twix;

use Log4Perl::ImportHandle;


sub new {
  return bless {}, shift;  
};



sub test {
  my $this=shift;

  return LOG->debug('default handle');

}





1;
