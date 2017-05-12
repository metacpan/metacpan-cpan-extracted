# json-rpc-simple.psgi

use strict;
use warnings;

use Class::Load qw(try_load_class);
use Config::Tiny;
use File::Spec;
use JSON::RPC::Simple;
use Plack::Request;

# start with empty dispatcher as we'll populate this as we go
my $dispatcher = JSON::RPC::Simple->dispatch_to({});

my $Autoload = 1;

my $conf_path = $ENV{JSON_RPC_SIMPLE_DISPATCHER_CONF} || "etc/json-rpc-simple-psgi.conf";

if (-e $conf_path) {
    my $conf = Config::Tiny->read($conf_path) or die Config::Tiny->errstr();
    
    $Autoload = $conf->{_}->{auto_load} if exists $conf->{_}->{auto_load};
    
    my %mapping = %{$conf->{mappings} || {}};
    for my $path (keys %mapping) {
        my $pkg = $mapping{$path};
        try_load_class($pkg);
        my $target = $pkg->can("new") ? $pkg->new() : $pkg;
        print STDERR "[PID $$]: mapping $path to $target\n";
        $dispatcher->dispatch_to({ $path =>  $target });     
    }
}

my $app = sub {
    my $env = shift;
    my $request = Plack::Request->new($env);
    
    my $path = $request->path_info;
    $path =~ s{::}{/}g;
    
    if ($Autoload && !$dispatcher->target($path)) {
        my $pkg = substr($path, 1);
        $pkg =~ s{/}{::}g;
        
        unless (my @ok = try_load_class($pkg)) {            
            my $response = $request->new_response(500, {}, "Can't load ${pkg} because of $ok[1]");
            return $response->finalize;
        }
        
        my $target = $pkg->can("new") ? $pkg->new() : $pkg;
        $dispatcher->dispatch_to({ $path =>  $target });     
    }
    
    my $r = $dispatcher->handle($path, $request);
    
    my $response = $request->new_response($r->code, $r->headers, $r->content);
    return $response->finalize;
};

