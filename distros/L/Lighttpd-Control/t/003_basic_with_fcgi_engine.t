#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use File::Spec::Functions;

use Test::More;
use Test::Exception;
use Test::WWW::Mechanize;

BEGIN {
    eval "use FCGI::Engine::Manager";
    plan skip_all => "FCGI::Engine::Manager required for this test" if $@;    
    plan tests => 12;    
    use_ok('Lighttpd::Control');
}

{
    package My::Lighttpd::Control;
    use Moose;
    
    extends 'Lighttpd::Control';
    
    has 'fcgi_manager' => (
        is      => 'ro',
        isa     => 'FCGI::Engine::Manager',   
        default => sub {
            FCGI::Engine::Manager->new(
                conf => ::catfile($FindBin::Bin, 'conf', 'fcgi.engine.yml')
            )            
        },
    );
    
    augment post_startup => sub {
        my $self = shift;
        $self->log('Starting the FCGI Engine Manager ...');
        $self->fcgi_manager->start;        
    };
    
    augment post_shutdown => sub {
        my $self = shift;
        $self->log('Stopping the FCGI Engine Manager ...');
        $self->fcgi_manager->stop; 
    };    
}

my $ctl = My::Lighttpd::Control->new(
    config_file => [qw[ t conf lighttpd.fcgi.conf ]],
);
isa_ok($ctl, 'Lighttpd::Control');

SKIP: {
    
skip "No lighttpd installed (or at least none found), why are you testing this anyway?", 6 
    unless eval { $ctl->binary_path };

ok(!$ctl->is_server_running, '... the server process is not yet running');

$ctl->start;

diag "Wait a moment for lighttpd to start";
sleep(2);

ok($ctl->is_server_running, '... the server process is now running');

my $mech = Test::WWW::Mechanize->new;

for (1 .. 3) {
    $mech->get_ok('http://localhost:3333/count', '... got the page okay');
    $mech->content_is($_, '... got the content we expected');   
}

$ctl->stop;

diag "Wait a moment for Lighttpd to stop";
sleep(2);

ok(!-e $ctl->pid_file, '... PID file has been removed by Lighttpd');
ok(!$ctl->is_server_running, '... the server process is no longer running');

}