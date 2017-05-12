BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Cwd;
use Mail::Box::MH::Resource;
$loaded = 1;
print "ok 1 # Loaded\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $prof = Mail::Box::MH::Resource->new('./t/1.mh_profile');
{
  my $path = $prof->get('Path');
  print 'not ' unless $path eq 'Mail';
  print "ok 2 # '$path' eq 'Mail'\n";
}
{
  my $components = "@{[sort $prof->enum()]}";
  print 'not ' unless $components eq 'Milk Path';
  print "ok 3 # 'Milk Path' eq '$components'\n";
}

{
  my $aleph = Mail::Box::MH::Resource->new('./t/1.test_profile');
  $aleph->set('Foo'=>'Bar');
  $aleph->close();
  my $null = Mail::Box::MH::Resource->new('./t/1.test_profile');
  my $foo = $null->get('Foo');
  print 'not ' unless $foo eq 'Bar';
  $null->close();
  unlink('t/1.test_profile');
  print "ok 4 # '$foo' eq 'Bar'\n";
}

{
  unless( chdir 't' ){
    print "ok 5 # Skipped: Could not chdir('t'); $!\n";
  }
  else{
    local @ENV{HOME, MH} = (cwd(), '1.mh_profile');
    my $aleph = Mail::Box::MH::Resource->new('sequence');
    my $foo = $aleph->get('cows_with_guns');
    print 'not ' unless $foo eq 'Dana Lyons';
    print "ok 5 # '$foo' eq 'Dana Lyons'\n";
  }
}
