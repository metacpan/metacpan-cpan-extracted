#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# Test slots shared across many packages
subtest 'many packages one slot' => sub {
    package MultiA;
    use Legba qw/shared_global/;
    
    package MultiB;
    use Legba qw/shared_global/;
    
    package MultiC;
    use Legba qw/shared_global/;
    
    package MultiD;
    use Legba qw/shared_global/;
    
    package main;
    
    MultiA::shared_global('A wrote');
    is(MultiB::shared_global(), 'A wrote', 'B sees A');
    is(MultiC::shared_global(), 'A wrote', 'C sees A');
    is(MultiD::shared_global(), 'A wrote', 'D sees A');
    
    MultiC::shared_global('C wrote');
    is(MultiA::shared_global(), 'C wrote', 'A sees C');
    is(MultiB::shared_global(), 'C wrote', 'B sees C');
    is(MultiD::shared_global(), 'C wrote', 'D sees C');
};

# Test packages with overlapping slot names
subtest 'overlapping names' => sub {
    package OverlapA;
    use Legba qw/name config data/;
    
    package OverlapB;
    use Legba qw/name config other/;
    
    package main;
    
    OverlapA::name('name_a');
    OverlapA::config('config_a');
    OverlapA::data('data_a');
    
    # B shares name and config
    is(OverlapB::name(), 'name_a', 'B shares name with A');
    is(OverlapB::config(), 'config_a', 'B shares config with A');
    
    OverlapB::name('name_b');
    is(OverlapA::name(), 'name_b', 'A sees B update');
    
    # data and other are separate
    OverlapB::other('other_b');
    is(OverlapA::data(), 'data_a', 'data unaffected by other');
};

# Test package with no slots exported elsewhere
subtest 'isolated package' => sub {
    package Isolated;
    use Legba qw/isolated_slot/;
    
    package main;
    
    Isolated::isolated_slot('isolated value');
    is(Isolated::isolated_slot(), 'isolated value', 'isolated slot works');
    
    # But it's still global via _get/_set
    is(Legba::_get('isolated_slot'), 'isolated value', 
       '_get can access isolated slot');
};

# Test re-importing same slot
subtest 'reimport' => sub {
    package Reimport1;
    use Legba qw/reimp_slot/;
    reimp_slot('first');
    
    package Reimport2;
    use Legba qw/reimp_slot/;
    
    package Reimport1;
    use Legba qw/reimp_slot/;  # reimport
    
    package main;
    is(Reimport1::reimp_slot(), 'first', 'value preserved after reimport');
    is(Reimport2::reimp_slot(), 'first', 'other package sees value');
};

# Test hierarchical package names
subtest 'hierarchical packages' => sub {
    package App::Model::User;
    use Legba qw/current_user/;
    
    package App::View::Template;
    use Legba qw/current_user/;
    
    package App::Controller::Main;
    use Legba qw/current_user/;
    
    package main;
    
    App::Model::User::current_user({ id => 1, name => 'Test' });
    
    is(App::View::Template::current_user()->{name}, 'Test', 
       'View sees Model user');
    is(App::Controller::Main::current_user()->{id}, 1,
       'Controller sees Model user');
};

# Test main:: package
subtest 'main package' => sub {
    package main;
    use Legba qw/main_slot/;
    
    main_slot('in main');
    is(main_slot(), 'in main', 'main package slot works');
    is(main::main_slot(), 'in main', 'explicit main:: works');
};

done_testing();
