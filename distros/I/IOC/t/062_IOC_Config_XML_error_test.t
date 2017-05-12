#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;
use Test::Exception;

BEGIN {
    use_ok('IOC::Config::XML');
}

## error tests

{
    my $conf = IOC::Config::XML->new();
    isa_ok($conf, 'IOC::Config::XML');
    
    # read errors
    
	throws_ok {
        $conf->read();
    } 'IOC::InsufficientArguments', '... got the error we expected';  
    
	throws_ok {
        $conf->read('');
    } 'IOC::InsufficientArguments', '... got the error we expected';    
    
	throws_ok {
        $conf->read(0);
    } 'IOC::InsufficientArguments', '... got the error we expected';    

    # parsing errors
    
	throws_ok {
        $conf->read('<Container name="root"></Container>');        
    } 'IOC::ConfigurationError', '... got the error we expected';  
    
	throws_ok {
        $conf->read('<Registry><Service name="test"></Service></Registry>');        
    } 'IOC::ConfigurationError', '... got the error we expected';  
    
    IOC::Registry->new()->DESTROY();    
    
	throws_ok {
        $conf->read('<Registry><Container type="ConstructorInjection"></Container></Registry>');        
    } 'IOC::ConfigurationError', '... got the error we expected';   
    
    IOC::Registry->new()->DESTROY();    

	throws_ok {
        $conf->read('<Registry><Container name="test"><Service type="Literal">25</Service></Container></Registry>');        
    } 'IOC::ConfigurationError', '... got the error we expected';   
    
    IOC::Registry->new()->DESTROY();    
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service type="Literal">25</Service>
                    <Service type="Literal">28</Service>                    
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';    
    
    IOC::Registry->new()->DESTROY();    
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test"><CDATA test="1" /></Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';      
                                        
    IOC::Registry->new()->DESTROY();                                                                                                                 
                                                                                                                                                                                                                                                       
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test"><![CDATA[1 + ;s]]></Service>         
                </Container>
            </Registry>});        
    } 'IOC::OperationFailed', '... got the error we expected';         
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="Something">25</Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';   
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="Literal"></Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';  
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="Literal"><CDATA type="nuttin"></CDATA></Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';     
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="ConstructorInjection">
                        <Class name="My::Class" constructor="new" />
                        <Parameter type="junk" />
                    </Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';   
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="ConstructorInjection">
                        <Class name="My::Class" constructor="new" />
                        <Parameter type="perl">[ test</Parameter>
                    </Service>         
                </Container>
            </Registry>});        
    } 'IOC::OperationFailed', '... got the error we expected';              
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="ConstructorInjection">
                        <Class name="My::Class" constructor="new" />
                        <Parameter name="hello"></Parameter>
                    </Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';     
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="ConstructorInjection">
                    </Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';          
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="ConstructorInjection">
                        <Class name="My::Class" />                    
                    </Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';          
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="ConstructorInjection">
                        <Class constructor="new" />                    
                    </Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected'; 
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="SetterInjection">
                    </Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';          
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="SetterInjection">
                        <Class name="My::Class" />                    
                    </Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';          
    
    IOC::Registry->new()->DESTROY();        
    
	throws_ok {
        $conf->read(q{
            <Registry>
                <Container name="test">
                    <Service name="test" type="SetterInjection">
                        <Class constructor="new" />                    
                    </Service>         
                </Container>
            </Registry>});        
    } 'IOC::ConfigurationError', '... got the error we expected';                           
    
    IOC::Registry->new()->DESTROY();        
}
