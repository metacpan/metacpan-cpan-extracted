#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 39;
use Test::Exception;

BEGIN {
    use_ok('IOC::Config::XML');
}

## edge case tests

# test Registry with nothing in it
{
    my $sample_config = q|
    <Registry>   
    </Registry>
    |;

    my $conf = IOC::Config::XML->new();
    isa_ok($conf, 'IOC::Config::XML');
    
    lives_ok {
        $conf->read($sample_config);
    } '... we read the conf okay';

    my $reg = IOC::Registry->new();
    isa_ok($reg, 'IOC::Registry');
    
    is_deeply(
        [ $reg->getRegisteredContainerList() ],
        [],
        '... we got nothing');
    
    $reg->DESTROY();
}

# test Container with nothing in it
{
    my $sample_config = q|
    <Registry> 
        <Container name='nuttin' />
    </Registry>
    |;

    my $conf = IOC::Config::XML->new();
    isa_ok($conf, 'IOC::Config::XML');
    
    lives_ok {
        $conf->read($sample_config);
    } '... we read the conf okay';

    my $reg = IOC::Registry->new();
    isa_ok($reg, 'IOC::Registry');
    
    is_deeply(
        [ $reg->getRegisteredContainerList() ],
        [ 'nuttin' ],
        '... we got our nuttin container');
        
    my $nuttin = $reg->getRegisteredContainer('nuttin');
    isa_ok($nuttin, 'IOC::Container');
    
    is_deeply(
        [ $nuttin->getSubContainerList(), $nuttin->getServiceList() ],
        [],
        '... we got nuttin in our nuttin container');    
    
    $reg->DESTROY();
}

# test prototype with Constructor and Setter Injection
{
    {
        package My::Test1;
        sub new { bless { value => $_[1] } }
        
        package My::Test2;
        sub new { bless {} }        
        sub setValue { $_[0]->{value} = $_[1] }
    }

    my $sample_config = q|
    <Registry>
        <Container name='test'>
            <Service type='Literal' name='two'>2</Service>
            <Service type="ConstructorInjection" name='test_service1' prototype='false'>
                <Class name='My::Test1' constructor='new' />
                <Parameter>1</Parameter>                
            </Service>
            <Service type="SetterInjection" name='test_service2' prototype='false'>
                <Class name='My::Test2' constructor='new' />                
                <Setter name='setValue'>two</Setter>                
            </Service>
            <Service type="ConstructorInjection" name='test_service1a' prototype='true'>
                <Class name='My::Test1' constructor='new' />
                <Parameter>1</Parameter>
            </Service>
            <Service type="SetterInjection" name='test_service2a' prototype='true'>
                <Class name='My::Test2' constructor='new' />                
                <Setter name='setValue'>two</Setter>                
            </Service>            
        </Container>      
    </Registry>
    |;

    my $conf = IOC::Config::XML->new();
    isa_ok($conf, 'IOC::Config::XML');
    
    lives_ok {
        $conf->read($sample_config);
    } '... we read the conf okay';

    my $reg = IOC::Registry->new();
    isa_ok($reg, 'IOC::Registry');

    my $c = $reg->getRegisteredContainer('test');
    isa_ok($c, 'IOC::Container');
    
    is($c->name(), 'test', '... got the right name');
    
    # constructor injection prototype test
    
    my $test_service1 = $c->get('test_service1');
    isa_ok($test_service1, 'My::Test1');
    
    is($test_service1, $c->get('test_service1'), '... and if I get it again, it is the same one');
    
    my $test_service1a = $c->get('test_service1a');
    isa_ok($test_service1a, 'My::Test1');
    
    isnt($test_service1a, $c->get('test_service1a'), '... and if I get it again, it is not the same one');    

    # setter injection prototype test

    my $test_service2 = $c->get('test_service2');
    isa_ok($test_service2, 'My::Test2');
    
    is($test_service2, $c->get('test_service2'), '... and if I get it again, it is the same one');

    my $test_service2a = $c->get('test_service2a');
    isa_ok($test_service2a, 'My::Test2');
    
    isnt($test_service2a, $c->get('test_service2a'), '... and if I get it again, it is not the same one');
    
    $reg->DESTROY();
}

# test Constructor injection without parameter
{
    {
        package My::Test::Constructor;
        sub new { bless { value => undef } }
    }

    my $sample_config = q|
    <Registry>
        <Container name='test'>
            <Service type="ConstructorInjection" name='test_service'>
                <Class name='My::Test::Constructor' constructor='new' />
            </Service>           
        </Container>      
    </Registry>
    |;

    my $conf = IOC::Config::XML->new();
    isa_ok($conf, 'IOC::Config::XML');
    
    lives_ok {
        $conf->read($sample_config);
    } '... we read the conf okay';

    my $reg = IOC::Registry->new();
    isa_ok($reg, 'IOC::Registry');

    my $c = $reg->getRegisteredContainer('test');
    isa_ok($c, 'IOC::Container');
    
    my $test_service = $c->get('test_service');
    isa_ok($test_service, 'My::Test::Constructor');
    
    $reg->DESTROY();
}

# test Setter injection without a setter
{
    {
        package My::Test::Setter;
        sub new { bless { value => undef } }
    }

    my $sample_config = q|
    <Registry>
        <Container name='test'>
            <Service type="SetterInjection" name='test_service'>
                <Class name='My::Test::Setter' constructor='new' />
            </Service>           
        </Container>      
    </Registry>
    |;

    my $conf = IOC::Config::XML->new();
    isa_ok($conf, 'IOC::Config::XML');
    
    lives_ok {
        $conf->read($sample_config);
    } '... we read the conf okay';

    my $reg = IOC::Registry->new();
    isa_ok($reg, 'IOC::Registry');

    my $c = $reg->getRegisteredContainer('test');
    isa_ok($c, 'IOC::Container');
    
    my $test_service = $c->get('test_service');
    isa_ok($test_service, 'My::Test::Setter');
    
    $reg->DESTROY();
}

# test Setter injection without a setter
{

    my $sample_config = q|
    <Registry>
        <Container name='test'>
            <Service type="Parameterized" name='test_service'>
                <![CDATA[          
                    my (undef, %params) = @_;
                    return \%params;
                ]]>                
            </Service>           
        </Container>      
    </Registry>
    |;

    my $conf = IOC::Config::XML->new();
    isa_ok($conf, 'IOC::Config::XML');
    
    lives_ok {
        $conf->read($sample_config);
    } '... we read the conf okay';

    my $reg = IOC::Registry->new();
    isa_ok($reg, 'IOC::Registry');

    my $c = $reg->getRegisteredContainer('test');
    isa_ok($c, 'IOC::Container');
    
    my $test_service = $c->get('test_service', (foo => 1, bar => 2));
    is_deeply($test_service, {foo => 1, bar => 2}, '... got the right service');
    
    $reg->DESTROY();
}



