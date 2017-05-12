#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;
use Test::Exception;

BEGIN {
    use_ok('IOC::Proxy');
}

{
    package Base::Autoload;
    
    sub new { bless \( my $var ), $_[0] }
    our $AUTOLOAD;
    sub AUTOLOAD { 
        return $AUTOLOAD;
    }
}

{
    my $object = Base::Autoload->new();
    isa_ok($object, 'Base::Autoload');
    
    my @method_calls;
    my $proxy_server = IOC::Proxy->new({
                            on_method_call => sub { push @method_calls, \@_ }
                        });
    isa_ok($proxy_server, 'IOC::Proxy');
    
    my $proxied_object = $proxy_server->wrap($object);
    isa_ok($proxied_object, 'Base::Autoload::_::Proxy');
    isa_ok($proxied_object, 'Base::Autoload');
    
    is($proxied_object->HelloWorld(), 'Base::Autoload::HelloWorld', '... got what we expected'); 
    
    $proxied_object->DESTROY();
    
    is_deeply(\@method_calls, [
            [ $proxy_server, 'AUTOLOAD', 'Base::Autoload::AUTOLOAD', [ $proxied_object ]],
            [ $proxy_server, 'AUTOLOAD', 'Base::Autoload::AUTOLOAD', []]
            ], '... got the method calls we exected');
}

{
    package Base::Destroy;
    
    sub new { bless [], $_[0] }
    sub DESTROY {}
}

{
    my @method_calls;
    my $proxy_server = IOC::Proxy->new({
                            on_method_call => sub { push @method_calls, \@_ }
                        });    
    isa_ok($proxy_server, 'IOC::Proxy');
                            
    {
        my $object = Base::Destroy->new();
        isa_ok($object, 'Base::Destroy');
        
        {
            my $proxied_object = $proxy_server->wrap($object);
            isa_ok($proxied_object, 'Base::Destroy::_::Proxy');
            isa_ok($proxied_object, 'Base::Destroy');
            
            is_deeply(\@method_calls, [], '... got no method calls as we exected');                            
        }
        
        is_deeply(\@method_calls, [], '... got no method calls as we exected');  
    }
    
    is_deeply(\@method_calls,
            [[ $proxy_server, 'DESTROY', 'Base::Destroy::DESTROY', []]],
           '... got the method calls we exected');
}

{
    package Base::Overload;
    
    use overload '""' => sub { return "hello world " . overload::StrVal($_[0]) },
                 fallback => 1;
    
    sub new { bless sub {}, $_[0] }
}

{
    my $object = Base::Overload->new();
    isa_ok($object, 'Base::Overload');
    
    my @method_calls;
    my $proxy_server = IOC::Proxy->new({
                            on_method_call => sub { push @method_calls, \@_ }
                        });
    isa_ok($proxy_server, 'IOC::Proxy');                        
    
    my $proxied_object = $proxy_server->wrap($object);
    isa_ok($proxied_object, 'Base::Overload::_::Proxy');
    isa_ok($proxied_object, 'Base::Overload');
    
    like($proxied_object, 
         qr/hello world Base\:\:Overload\:\:_\:\:Proxy=CODE\(0x[a-f0-9]+\)/, 
         '... got the thing we expected');
    
    is_deeply(\@method_calls,
              [[ $proxy_server, '(""', 'Base::Overload::(""', [ $object, undef, '' ]]],
              '... got the method calls we exected');    

    cmp_ok(scalar(@method_calls), '>=', 1, '... we know at least one method has been registered');
}

# and some misc. stuff
{
    package Base::Nothing;
    sub new { bless {} }
    sub test { 'test' }
}

{
    my $proxy_server = IOC::Proxy->new();
    isa_ok($proxy_server, 'IOC::Proxy'); 
    
    my $object = Base::Nothing->new();
    isa_ok($object, 'Base::Nothing');
    
    my $proxied_object = $proxy_server->wrap($object); 
    isa_ok($proxied_object, 'Base::Nothing::_::Proxy');
    isa_ok($proxied_object, 'Base::Nothing');       
          
    is($proxied_object->test(), 'test', '... got the stuff we expected');
}

# lets also check some errors while we are at it

throws_ok {
    IOC::Proxy->wrap();
} 'IOC::InsufficientArguments', '... got the error we expected';

throws_ok {
    IOC::Proxy->wrap("Fail");
} 'IOC::InsufficientArguments', '... got the error we expected';

throws_ok {
    IOC::Proxy->wrap([]);
} 'IOC::InsufficientArguments', '... got the error we expected';

throws_ok {
    IOC::Proxy->wrap(bless({}, 'Nothing'));
} 'IOC::OperationFailed', '... got the error we expected';
