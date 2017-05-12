use strict;
use Test::More;

BEGIN
{
    my @modules = qw(
        Gungho::Base
        Gungho::Base::Class
        Gungho::Component::Setup
        Gungho::Component::Core
        Gungho::Engine
        Gungho::Exception
        Gungho::Handler
        Gungho::Handler::FileWriter::Simple
        Gungho::Handler::Null
        Gungho::Inline
        Gungho::Log
        Gungho::Log::Dispatch
        Gungho::Log::Simple
        Gungho::Plugin
        Gungho::Provider
        Gungho::Request
        Gungho::Request::http
        Gungho::Response
        Gungho
    );
    
    plan tests => scalar @modules;
    use_ok($_) for @modules;
}

1;