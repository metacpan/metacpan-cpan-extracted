use strict;
use warnings;
use feature ":all";
use Test::More;

use Data::Dumper;
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
  Error::Show::throw "ouch";
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
  #say STDERR ref $@;
  $result=Error::Show::context $@;
}
#say STDERR $result;

ok $result =~ /25=>   subc/;
ok $result =~ /28=>   subb/;
ok $result =~ /33=>   suba/;
ok $result =~ /32=> eval \{/;
#ok ($result =~ /(ouch)/g);
my @a= $result =~ /ouch at/g;
ok @a==1;

done_testing;
