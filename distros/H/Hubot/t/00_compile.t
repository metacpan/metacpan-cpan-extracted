use strict;
use Test::More tests => 16;

BEGIN { use_ok 'Hubot::Message' }
BEGIN { use_ok 'Hubot::User' }
BEGIN { use_ok 'Hubot::Brain' }
BEGIN { use_ok 'Hubot::Scripts::ascii' }
BEGIN { use_ok 'Hubot::Scripts::help' }
BEGIN { use_ok 'Hubot::Scripts::shorten' }
BEGIN { use_ok 'Hubot::Scripts::tweet' }
BEGIN { use_ok 'Hubot::Adapter' }
BEGIN { use_ok 'Hubot::Listener' }
BEGIN { use_ok 'Hubot::EventEmitter' }
BEGIN { use_ok 'Hubot::Robot' }
BEGIN { use_ok 'Hubot::Adapter::Campfire' }
BEGIN { use_ok 'Hubot::Adapter::Shell' }
BEGIN { use_ok 'Hubot::Adapter::Irc' }
BEGIN { use_ok 'Hubot::TextListener' }
BEGIN { use_ok 'Hubot::Response' }
