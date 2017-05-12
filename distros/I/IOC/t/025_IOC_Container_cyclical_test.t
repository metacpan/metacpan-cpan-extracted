#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 65;
use Test::Exception;

BEGIN {
    use_ok('IOC::Container');
    use_ok('IOC::Service::SetterInjection');
}

# Cyclical dependencies:
#     +---+
#  +--| A |<-+
#  |  +---+  |
#  |  +---+  |
#  +->| B |--+
#     +---+

{
    {
        package A;        
        sub new { bless { b => $_[1] }, $_[0] }
        sub testA { 'testA' }
        
        package B;
        sub new { bless { a => $_[1] }, $_[0] }
        sub testB { 'testB' }        
    }

    my $container = IOC::Container->new();
    $container->register(IOC::Service->new('a' => sub { A->new((shift)->get('b')) }));
    $container->register(IOC::Service->new('b' => sub { B->new((shift)->get('a')) }));

    my $a; 
    lives_ok {
        $a = $container->get('a');
    } '... we got our A object ok';
    isa_ok($a, 'A');
    
    isa_ok($a->{b}, 'B');
    is(ref($a->{b}), 'B', '... and it is actually a B object too');    
    is($a->{b}->testB(), 'testB', '... make sure our B object works as expected');
    
    isa_ok($a->{b}->{a}, 'A');
    is(ref($a->{b}->{a}), 'IOC::Service::Deferred', '... but this it is actually a IOC::Service::Deferred object');    

    is($a->{b}->{a}->testA(), 'testA', '... this should inflate our deferred A object');
    is(ref($a->{b}->{a}), 'A', '... now this should be an A object');  
    
    is($a, $a->{b}->{a}, '... and our A instances are both the same since they are singletons');
}

# Graph Dependecies
#       +---+
#    +--| C |<-+
#    |  +---+  |
#  +-V-+     +---+
#  | D |     | F |
#  +---+     +-^-+
#    |  +---+  |
#    +->| E |--+
#       +---+
 
{

    {
        package C;        
        sub new { bless { d => $_[1] }, $_[0] }
        
        package D;
        sub new { bless { e => $_[1] }, $_[0] }
        
        package E;
        sub new { bless { f => $_[1] }, $_[0] }
                
        package F;
        sub new { bless { c => $_[1] }, $_[0] }        
    }

    my $container = IOC::Container->new();
    $container->register(IOC::Service->new('c' => sub { C->new((shift)->get('d')) }));
    $container->register(IOC::Service->new('d' => sub { D->new((shift)->get('e')) }));
    $container->register(IOC::Service->new('e' => sub { E->new((shift)->get('f')) }));
    $container->register(IOC::Service->new('f' => sub { F->new((shift)->get('c')) }));
    
    my $c; 
    lives_ok {
        $c = $container->get('c');
    } '... we got our C object ok';
    isa_ok($c, 'C'); 
    
    isa_ok($c->{d}, 'D');
    is(ref($c->{d}), 'D', '... and it is actually a D object too');    
    
    isa_ok($c->{d}->{e}, 'E');
    is(ref($c->{d}->{e}), 'E', '... and it is actually a E object too');                        

    isa_ok($c->{d}->{e}->{f}, 'F');
    is(ref($c->{d}->{e}->{f}), 'F', '... and it is actually a F object too');                        
    
    isa_ok($c->{d}->{e}->{f}->{c}, 'C');
    is(ref($c->{d}->{e}->{f}->{c}), 'IOC::Service::Deferred', '... however this is actually an IOC::Service::Deferred object');                              

    isa_ok($c->{d}->{e}->{f}->{c}->{d}, 'D');
    is(ref($c->{d}->{e}->{f}->{c}), 'C', '... but now we have been infalted into a proper C object');                                  
}
 
# Graph Dependecies
#       +---+
#    +--| G |<-+
#    |  +---+  |
#  +-V-+     +---+  +---+  +---+
#  | H |     | J |  | K |->| L |
#  +---+     +-^-+  +-^-+  +---+
#   | |  +---+ |      |
#   | +->| I |-+      |
#   |    +---+        |
#   +-----------------+

{
    {
        package G;        
        sub new { bless [ $_[1] ], $_[0] }
        
        package H;
        sub new { bless { i => $_[1], k => $_[2] }, $_[0] }
        
        package I;
        sub new { bless { j => $_[1] }, $_[0] }
                
        package J;
        sub new { bless { g => $_[1] }, $_[0] }        
        
        package K;
        sub new { bless { l => $_[1] }, $_[0] }                
    }

    my $container = IOC::Container->new();
    $container->register(IOC::Service->new('g' => sub { G->new((shift)->get('h')) }));              
    $container->register(IOC::Service->new('h' => sub { H->new($_[0]->get('i'), $_[0]->get('k')) }));                  
    $container->register(IOC::Service->new('i' => sub { I->new((shift)->get('j')) }));                  
    $container->register(IOC::Service->new('j' => sub { J->new((shift)->get('g')) }));                       
    $container->register(IOC::Service->new('k' => sub { K->new((shift)->get('l')) }));   
    $container->register(IOC::Service->new('l' => sub { '... this is the end' }));       
        
    my $g; 
    lives_ok {
        $g = $container->get('g');
    } '... we got our G object ok';
    isa_ok($g, 'G');         
    
    isa_ok($g->[0], 'H');
    is(ref($g->[0]), 'H', '... and it is actually a H object too');  
      
    isa_ok($g->[0]->{i}, 'I');
    is(ref($g->[0]->{i}), 'I', '... and it is actually a I object too');  
       
    isa_ok($g->[0]->{i}->{j}, 'J');
    is(ref($g->[0]->{i}->{j}), 'J', '... and it is actually a J object too'); 
    
    isa_ok($g->[0]->{i}->{j}->{g}, 'G');
    is(ref($g->[0]->{i}->{j}->{g}), 'IOC::Service::Deferred', '... and it is actually an IOC::Service::Deferred object');     

    isa_ok($g->[0]->{i}->{j}->{g}->[0], 'H');
    is(ref($g->[0]->{i}->{j}->{g}), 'G', '... and it is actually the inflated G object now');     

    isa_ok($g->[0]->{k}, 'K');
    is(ref($g->[0]->{k}), 'K', '... and it is actually a K object too');  
    
    is($g->[0]->{k}->{l}, '... this is the end', '... and this is our L string');

          
} 

## EDGE CASES

# Cyclical dependencies:
#     +---+
#  +--| M |<-+
#  |  +---+  |
#  |         > $m->test()
#  |  +---+  |
#  +->| N |--+
#     +---+
#
# in this test we call a method on the deferred M instance
# before we are finished creating N, this results in M 
# being intialized before N is finished initializing.
# 
# +---+    +---+   +-------+  /   N->new calls  \   +-------+        
# | M |--->| N |-->| <<M>> |-| $m->testM() which |->| <<N>> |     
# +---+    +---+   +-------+  \  inflates <<M>> /   +-------+     .   
#   \        \          \              V                 \........|
#    \        \          \.............|__________________________| 
#     \        \__________________________________________________|
#      \__________________________________________________________|
#                    <<scope of call to instance()>>
#
# basically what is happening is that when the first deferred <<M>>
# is inflated, the first real M has not yet been fully created. Thus
# the IOC::Service object M occupies first stores the deferred <<M>>
# then returns, which satisfies the N and returns, which then satisfies
# the first M which is then stored in the IOC::Service instance that
# the first <<M>> is stored in, thus overwriting it.
#
# We solve this by checking to see if the IOC::Service object in question
# already has an instance, in which case, we use that one and discard the
# extra instance. It is not the best solution (since we create an instace
# only to discard it), but it allows for this to work.

{
    {
        package M;        
        sub new { bless { n => $_[1] }, $_[0] }
        sub testM { 'testM' } 
        ## uncomment this line to see the
        ## recursive spiral of death happen.
        # sub testM { (shift)->{n}->testN() }
        
        package N;
        sub new { 
            my ($class, $m) = @_;
            Test::More::is(ref($m), 'IOC::Service::Deferred', '... we got a deferred M');
            Test::More::is($m->testM(), 'testM', '... and we got the right output');
            bless { m => $m }, $class
        }
        sub testN { 'testN' }        
    }

    my $container = IOC::Container->new();
    $container->register(IOC::Service->new('m' => sub { M->new((shift)->get('n')) }));
    $container->register(IOC::Service->new('n' => sub { N->new((shift)->get('m')) }));

    my $m; 
    lives_ok {
        $m = $container->get('m');
    } '... we got our M object ok';
    isa_ok($m, 'M');
    
    isa_ok($m->{n}, 'N');
    is(ref($m->{n}), 'IOC::Service::Deferred', '... this an IOC::Service::Deferred instance');    
    is($m->{n}->testN(), 'testN', '... make sure our N object works as expected');
    is(ref($m->{n}), 'N', '... this now an N instance');
    
    isa_ok($m->{n}->{m}, 'M');
    is(ref($m->{n}->{m}), 'M', '... but this it is actually an M object since it was resolved earlier');    
    
    is($m, $m->{n}->{m}, '... and our M instances are both the same since they are singletons');
}
 
# test some of the errors for this

{
    throws_ok {
        IOC::Service::Deferred->new();
    } 'IOC::InsufficientArguments', '... got the error we expected';

    throws_ok {
        IOC::Service::Deferred->new([]);
    } 'IOC::InsufficientArguments', '... got the error we expected';
    
    throws_ok {
        IOC::Service::Deferred->new(bless({}, 'Fail'));
    } 'IOC::InsufficientArguments', '... got the error we expected';
    
} 

{
    my $container = IOC::Container->new();
    $container->register(IOC::Service->new('a' => sub { A->new((shift)->get('b')) }));
    $container->register(IOC::Service->new('b' => sub { B->new((shift)->get('a')) }));

    my $a; 
    lives_ok {
        $a = $container->get('a');
    } '... we got our A object ok';
    isa_ok($a, 'A');

    isa_ok($a->{b}->{a}, 'A');
    is(ref($a->{b}->{a}), 'IOC::Service::Deferred', '... but this it is actually a IOC::Service::Deferred object');   

    ok(!defined($a->{b}->{a}->can('Fail')), '... we dont have this method');

    is(ref($a->{b}->{a}), 'A', '... now this it is actually a A object');   
}

{
    my $container = IOC::Container->new();
    $container->register(IOC::Service->new('a' => sub { A->new((shift)->get('b')) }));
    $container->register(IOC::Service->new('b' => sub { B->new((shift)->get('a')) }));

    my $a; 
    lives_ok {
        $a = $container->get('a');
    } '... we got our A object ok';
    isa_ok($a, 'A');

    isa_ok($a->{b}->{a}, 'A');
    is(ref($a->{b}->{a}), 'IOC::Service::Deferred', '... but this it is actually a IOC::Service::Deferred object');   

    throws_ok {
        $a->{b}->{a}->Fail()
    } 'IOC::MethodNotFound', '... got the error we expected';    
    
    is(ref($a->{b}->{a}), 'A', '... now this it is actually a A object');       
}
