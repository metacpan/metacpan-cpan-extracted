package LongSearch;
use File::Find;
use File::Basename;
use File::Spec;
use Data::Dumper;
use strict;
use warnings;
# This package without SSL and proper authentication would be a living
# security nightmare.
# It is used ONLY for demonstarte a potentially long running operation.
# If you paln to use it for real purposes, protect
# your service with authentication.

my $client;
my $inited = 0;
sub init {
   $client = JRPC::Client->new();
   $inited++;
}

sub searchpath {
   my ($p) = @_;
   my $path = $p->{'path'};
   if (!$path) {die("No path: '$p->{'path'}'");}
   if (!-d $p->{'path'}) {die("Path '$p->{'path'}' does not exist");}
   # Not mandatory ?
   if (!$p->{'cburl'}) {die("Callback URL ('cburl') not passed");}
   my $rid = $p->{'rid'} = int(rand(1000));
   if (!$inited) {init();} # Delayed init if not explicitly called at service startup.
   my $cpid = fork();
   if (!defined($cpid)) {die("Not forked for async processing");}
   if (!$cpid) {
      # Close any handles, sharing of which (betw. parent and child) would cause problems.
      close(STDOUT);
      close(STDERR);
      DEBUG:open(my $fh, ">>", "/tmp/longsearch.$$.out");
      DEBUG:select($fh);
      # Faults in async part (w/o eval, after closing STDERR,STDOUT):
      # print() on closed filehandle GEN2 at ../JRPC/CGI.pm line 110,
      # Permission denied Errors during file search (going to STDERR ?)
      eval {
         local $p->{'fh'} = $fh;
         my $rp = searchpath_async($p);
      };
      if ($@) {
         print($fh "Exception in async processing: $@\n");
      }
      DEBUG:close($fh);
      exit(1);
   }
   return({'reqid' => $rid, 'ppid' => $$});
}
# The async part of searchpath creating results for the callback.
sub searchpath_async {
   my ($p) = @_;
   my $path = $p->{'path'};
   my $fh = $p->{'fh'}; # Hack ?
   my @files;
   # Use File::Find
   my $cb = sub {
      my $an = $File::Find::name;
      #my $bn = File::Basename::basename($an);
      if ($an =~ /\.txt$/) {
        my $rp = File::Spec->abs2rel($an, $path ) ;
        push(@files, $rp);
      }
   };
   # We are running a server - do NOT allow chdir()
   File::Find::find({'wanted' => $cb, 'no_chdir' => 1, }, $path);
   # Call Back
   my $rp;
   $rp = {'cpid' => $$, 'rid' => $p->{'rid'}, };
   $rp->{'path'} = $path;
   $rp->{'files'} = \@files;
   $rp->{'STATUS'} = 'alive';
   if (my $url = $p->{'cburl'}) {
     #my $req = $client->new_request($url);
     #DEBUG:print($fh "Client ack to '$url': ".Dumper($rp));
     #my $resp = $req->call('onsearchcomplete', $rp, 'notify' => 1);
     #DEBUG:print($fh "Resp from '$url': ".$resp->content()."\n");
     JRPC::respond_async($client, $url, 'onsearchcomplete', $rp);
   }
   # TODO: If email ?
   if (my $email = $p->{'email'}) {
      # Load lazy to not form a strict dependency.
      #eval("use ");
   }
   return($rp);
}

1;
