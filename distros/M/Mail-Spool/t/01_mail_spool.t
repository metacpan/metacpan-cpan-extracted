package MySpool;

use strict;
use vars qw(@ISA $loaded);
use File::Path qw(rmtree);

BEGIN { $| = 1; print "1..11\n"; }

### load the module
END {print "not ok 1\n" unless $loaded;}
use Mail::Spool;
$loaded = 1;
print "ok 1\n";

@ISA = qw(Mail::Spool);


### set up an object
my $spool = MySpool->new();
if( $spool ){
  print "ok 2\n";
}else{
  print "not ok 2\n";
}


### change the base dequeue dir
my $dequeue_dir = "./test_dequeue";
END{ rmtree($dequeue_dir); }
mkdir $dequeue_dir, 0755;


### try to create dirs
$spool->dequeue_dir($dequeue_dir);
$spool->create_dequeue_dirs;

if( -e "$dequeue_dir/0" ){
  print "ok 3\n";
}else{
  print "not ok 3\n";
}


### try to queue a message
my $test_str = "FOObarBAZ";
my $scalar = "To: anybody\@in.the.world
From: me\@right.here.local
Subject: Whatever

Some sort of body.
$test_str
";

### see if it'll accept
eval{ $spool->send_mail(message => \$scalar) };
if( ! $@ ){
  print "ok 4\n";
}else{
  print "not ok 4\n";
}

### list the handles
my @msh = $spool->list_spool_handles;
if( @msh ){
  print "ok 5\n";
}else{
  print "not ok 5\n";
}

### see if the first handle looks good
my $msh = shift(@msh);
my $dir = $msh->spool_dir;
if( $dir eq "$dequeue_dir/0" ){
  print "ok 6\n";
}else{
  print "not ok 6\n";
}

### open it up for reading
eval{ $msh->open_spool };
if( ! $@ ){
  print "ok 7\n";
}else{ 
  print "not ok 7\n";
}

my $found = 0;
while(defined(my $node = $msh->next_node)){

  $found ++;

  ### get a lock
  my $lock = $node->lock_node;
  if( $lock ){
    print "ok 8\n";
  }else{
    print "not ok 8\n";
  }

  ### get a handle
  my $fh = $node->filehandle;
  if( $fh ){
    print "ok 9\n";
  }else{
    print "not ok 9\n";
  }

  ### see if the node contained the right message
  my $str = join("",<$fh>);
  if( $str =~ /\Q$test_str\E/ ){
    print "ok 10\n";
  }else{
    print "not ok 10\n";
  }

  last;
}

### did we find a node
if( $found ){
  print "ok 11\n";
}else{
  print "not ok 11\n";
}
