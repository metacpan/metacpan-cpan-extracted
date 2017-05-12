#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 39;
use Test::Exception;

BEGIN {
    use_ok('IOC::Config::XML');
}

can_ok("IOC::Config::XML", 'new');

{
    my $conf = IOC::Config::XML->new();
    isa_ok($conf, 'IOC::Config::XML');
    
    can_ok($conf, 'read');  
}

# real world test ...
{
    {
        package My::DBI;
        
        sub connect { bless {} }
    
        package My::DB::Logger;
        
        sub new { bless {} }
        sub setDBIConnection { 
            my ($self, $dbi) = @_;
            $self->{dbi} = $dbi;
        }
        sub setDBTableName { 
            my ($self, $db_table_name) = @_;
            $self->{db_table_name} = $db_table_name;
        }    
        
        package My::Application;
        
        sub new { bless {} }
        sub setLogger {
            my ($self, $logger) = @_;
            $self->{logger} = $logger;
        }
        
        package My::Template::Factory;
        sub new { bless { array => $_[1], hash  => $_[2], string => $_[3] } }
    }

    my $sample_config = q|
    <Registry>
        <Container name='Application'>
            <Container name='Database'>      
                <Service name='dsn'      type='Literal'>dbi:NullP:</Service>            
                <Service name='username' type='Literal'>user</Service>            
                <Service name='password' type='Literal'><![CDATA[****]]></Service>                                    
                <Service name='connection' type='ConstructorInjection'>
                    <Class name='My::DBI' constructor='connect' />
                    <Parameter type='component'>dsn</Parameter>                
                    <Parameter type='component'>username</Parameter>
                    <Parameter type='component'>password</Parameter>                            
                </Service>
            </Container>     
            <Service name='logger_table' type='Literal'>tbl_log</Service>               
            <Service name='logger' type='SetterInjection'>
                <Class name='My::DB::Logger' constructor='new' />
                <Setter name='setDBIConnection'><![CDATA[/Database/connection]]></Setter>
                <Setter name='setDBTableName'>logger_table</Setter>            
            </Service>  
            <Service name='template_factory' type='ConstructorInjection'>
                <Class name='My::Template::Factory' constructor='new' />
                <Parameter type='perl'>[ 1, 2, 3 ]</Parameter>  
                <Parameter type='perl'><![CDATA[{ path => 'test' }]]></Parameter>    
                <Parameter><![CDATA[Testing CDATA here]]></Parameter>                                                          
            </Service>             
            <Service name='app'>
                <![CDATA[
                    my $c = shift;
                    my $app = My::Application->new();
                    $app->setLogger($c->get('logger'));
                    return $app;
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
    
    is_deeply(
        [ $reg->getRegisteredContainerList() ],
        [ 'Application' ],
        '... got the list of registered containers');
        
    my $app = $reg->getRegisteredContainer('Application');
    isa_ok($app, 'IOC::Container');
    
    is($app->name(), 'Application', '... got the right name');
    
    is_deeply(
        [ $app->getSubContainerList() ], 
        [ 'Database' ],
        '... the right sub container list');
        
    my $db = $app->getSubContainer('Database');
    isa_ok($db, 'IOC::Container');
    
    is($db->name(), 'Database', '... got the right name');
        
    is_deeply(
        [ sort $db->getServiceList() ],
        [ 'connection', 'dsn', 'password', 'username' ],
        '... got the right service list');
        
    is($db->get('dsn'),      'dbi:NullP:', '... got the right value');
    is($db->get('username'), 'user',      '... got the right value');
    is($db->get('password'), '****',      '... got the right value');        
    
    my $dbh = $db->get('connection');
    isa_ok($dbh, 'My::DBI');
    
    is_deeply(
        [ sort $app->getServiceList() ], 
        [ 'app', 'logger', 'logger_table', 'template_factory' ],
        '... the right service list');    
    
    is($app->get('logger_table'), 'tbl_log', '... got the right logger table');
    
    my $logger = $app->get('logger');
    isa_ok($logger, 'My::DB::Logger');
    
    isa_ok($logger->{dbi}, 'My::DBI');
    is($logger->{dbi}, $dbh, '... and it is the same database handle too');
    
    is($logger->{db_table_name}, 'tbl_log', '... got the right logger table');    
    
    {
        my $app = $reg->locateService('/Application/app');
        isa_ok($app, 'My::Application');
            
        is($app->{logger}, $logger, '... got the same logger');
    }
    
    my $template_factory = $app->get('template_factory');
    isa_ok($template_factory, 'My::Template::Factory');
    
    is_deeply(
        $template_factory->{array},
        [ 1, 2, 3 ],
        '... got the right array value');
        
    is_deeply(
        $template_factory->{hash},
        { path => 'test' },
        '... got the right hash value');     
        
    is($template_factory->{string}, 'Testing CDATA here', '... got the right string value');
    
    $reg->DESTROY();
}

# testing prototypes
{
    my $sample_config = q|
    <Registry>
        <Container name='test'>
            <Service name='test_service' prototype='false'>
            <![CDATA[
                return bless({}, 'My::Test');
            ]]>
            </Service>
            <Service name='test_service2' prototype='true'>
            <![CDATA[
                return bless({}, 'My::Test2');
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
    
    is($c->name(), 'test', '... got the right name');
    
    my $test_service = $c->get('test_service');
    isa_ok($test_service, 'My::Test');
    
    is($test_service, $c->get('test_service'), '... and if I get it again, it is the same one');

    my $test_service2 = $c->get('test_service2');
    isa_ok($test_service2, 'My::Test2');
    
    isnt($test_service2, $c->get('test_service2'), '... and if I get it again, it is not the same one');
    
    $reg->DESTROY();
}

