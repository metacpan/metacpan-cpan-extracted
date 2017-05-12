# JSON-RPC Serice package SoundIt
# In debian install espeak by:
#    sudo apt-get install espeak
package SoundIt;

our $inited = 0;
# Once per service lifetime init().
sub init {
   $client = JRPC::Client->new();
   $inited++;
   # Add your init chores here.
   # ...
}
# Generate request ID. Params (in $p) may participate generating ID.
# Change to be deterministic / sequential and optionally move calling to
# framework level.
sub reqid {
   my ($p) = @_;
   return int(rand(10000));
}
# Class specific shared pre handler for (every) method call.
# Do various tasks like:
# - Validating central / common parameters.
# - bless parts of request ($p or its descendants)
# Throw exceptions on fatal errors, which JRPC will turn to JSON-RPC
# faults.
sub pre {
   my ($p) = @_;
   
}
############# JSON-RPC SERVICE METHODS #########################
# Use "espeak" to speak:
# - whataver was passed in "msg"
# - using "pitch" (number 0...100, default 50)
# - using "speed" (default 160)
# "msg" is required to be shell friendly.
sub say {
  my ($p) = @_;
  if (!$inited) {init();}
  pre($p);
  my $reqid = $p->{'reqid'} = reqid($p);
  `which espeak`;
  if ($?) {die("Cannot find speech synthesizer on this machine (espeak)");}
  if (!$p->{'msg'}) {die("Param 'msg' not passed");}
  #if (!$p->{'synth'}) {die("Param 'synth' not passed");}
  if (!$p->{'pitch'}) {$p->{'pitch'} = 50;}
  if (!$p->{'speed'}) {$p->{'speed'} = 160;}
  $p->{'msg'} =~ s/"//g;
  `espeak -p $p->{'pitch'} "$p->{'msg'}"`;

  return({'reqid' => $reqid, '' => "",});
}


1;
