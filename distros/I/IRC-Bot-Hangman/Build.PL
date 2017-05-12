#!/usr/bin/perl
use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    (
    module_name     => 'IRC::Bot::Hangman',
    license         => 'perl',
    requires        => {
                        perl => '5.6.0',
                        'Bot::BasicBot' => 0,
                        'Games::GuessWord' => 0,
                        'Module::Find' => 0,
                        'Chatbot::Eliza' => 0,
                        'Regexp::Common' => 0,
                       },
    build_requires => {
                        'Test::Pod'    => 0,
                        'Test::Simple' => 0,
                        'Test::More'   => 0,
                      },
      dynamic_config => 0,
      sign => 0,
    )->create_build_script;
