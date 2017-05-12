use Test::Simple 'no_plan';
use strict;
use lib './lib';
use LEOCHARRE::PMSubs qw(subs_defined _subs_defined _subs_used subs_used);

$LEOCHARRE::PMSubs::DEBUG = 1;

# use Smart::Comments '###';

ok(1);



my $_example_code = q/


*DMS::WUI::Runmodes::browse = sub {
   my $self = shift;
   $self->file or return $self->set_redirect('home',"No file selected");

   my $rm = $self->file->is_file ? 'browse_file' : 'browse_dir';
   #return $self->set_redirect($rm);
   return $self->set_redirect($rm);
};

&please = sub {

};

&me::too = sub {};

sub easy {

   # hi look at me

}

sub house : attribute {
   # little diff
}

sub interesting{
   # sue me
}

sub _totally_private {
   # methodology

}

 sub ignore_me {
  # because i am bad
 }




/;




my %subs;
map { $subs{$_}++ } @{ _subs_defined($_example_code) };

### %subs

for my $sub (qw(easy house _totally_private interesting please me::too)){
   
   ok( $subs{$sub}, "found= <$sub>");
      
   
}

for my $sub (qw(ignore_me)){
   ok( ! exists $subs{$sub}, " ignored '$sub'");
}










my $file1  = './t/code1.pm';
my $file2  = './t/code2.pm'; # empty file


my $s1 = subs_defined($file1);
ok($s1,'subs_defined returns');

map { ok($_,"$_") } @$s1;

my $count = scalar @$s1;
ok($count = "count $count");



ok(1,'testing empty file..');
my $s2 = subs_defined($file2);
ok($s2,'subs_defined returns');



my $count2 = scalar @$s2;
ok( !$count2 , "count $count2");





## used...


my $su = subs_used($file1);
ok($su,'subs_used returns');

use Data::Dumper;
print STDERR " \n" . Data::Dumper::Dumper($su) ."\n\n";


for (keys %$su){
   ok($_, "$_: ".$su->{$_});   

}





