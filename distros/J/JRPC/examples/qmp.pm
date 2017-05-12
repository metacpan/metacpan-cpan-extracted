# 
# 
package qmp;

our $VERSION = '0.03';

use strict;
use warnings;
# Create direct func-alias w/o @ISA inheritance

#use JRPC::Apache2;
#*handler = \&JRPC::Apache2::handler;

#*handler = \&JRPC::Nginx::handler;

# A PerlPostConfigHandler  handler.
# PerlPostConfigHandler qmp::post_config
# Params:
# - 3X APR::Pool
# - Apache2::ServerRec
#use Apache2::ServerRec;
sub post_config {
   my ($conf_pool, $log_pool, $temp_pool, $s) = @_;
   # Method not avail in Ubuntu 12.10 (!?)
   #my $modc = $s->module_config();
   print(STDERR "Running post_config with $s  Version $Apache2::ServerRec::VERSION\n");
   return 0; # Apache2::Const::OK;
}

use StoredHash;
# Need to differentiate autoid / non-autoid
sub store {
   my ($p) = @_;
   # Derive "class" / "table" by _class
   my $clmem = '_class';
   my $cl = $p->{$clmem};
   delete($p->{$clmem}); # Erase
   #my $dbh = getconnection();
   my $shp = StoredHash->new('table' => "$cl", 'pkey' => ['id'], ); # 'dbh' => $dbh
   my $ok = $shp->insert($p);
   return({'err' => 0, 'sql' => "$ok"});
}

1;
