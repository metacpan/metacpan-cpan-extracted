package TestApp;
use strict;
use warnings;
use TestApp::Builder;

my $builder = TestApp::Builder->new(
    appname => __PACKAGE__,
);

$builder->bootstrap;

TestApp->model('FB11AuthDB')->schema->deploy({add_drop_table => 1});
TestApp->model('FB11AuthDB::User')->create({ 
    username => 'fb11admin',
    password => 'password',
    email => 'support@opusvl.com',
    name => 'Admin',
    tel => '044444'
});

1;
