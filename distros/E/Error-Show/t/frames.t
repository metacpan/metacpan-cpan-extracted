use strict;
use warnings;
use feature ":all";
use Test::More;

use Error::Show;

use File::Basename qw<dirname>;
my $file=__FILE__;

$@=undef;
my $dir=dirname $file;
my $context;

sub subc{
  my @frames;
  my $i=0;
  while(my @frame=caller($i++)){
    push @frames, \@frame;
  }
  die {message=>"ouch", frames=>\@frames}
}
sub subb{
  subc
}
sub suba {
  subb;
}


eval {
  suba;
};
my $result;
if($@){
  $result=Error::Show::context message=>$@->{message}, frames=>$@->{frames};
}
ok $result =~ /24=>   subc/;
ok $result =~ /27=>   subb/;
ok $result =~ /32=>   suba/;
ok $result =~ /31=> eval \{/;
#ok ($result =~ /(ouch)/g);

my @a= $result =~ /ouch/g;
ok @a==5;

done_testing;
