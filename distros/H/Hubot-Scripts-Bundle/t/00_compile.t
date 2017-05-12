use strict;
use Test::More tests => 17;

BEGIN { use_ok 'Hubot::Scripts::Bundle' }
BEGIN { use_ok 'Hubot::Scripts::ping' }
BEGIN { use_ok 'Hubot::Scripts::redisBrain' }
BEGIN { use_ok 'Hubot::Scripts::uptime' }
BEGIN { use_ok 'Hubot::Scripts::eval' }
BEGIN { use_ok 'Hubot::Scripts::tell' }
BEGIN { use_ok 'Hubot::Scripts::bugzilla' }
BEGIN { use_ok 'Hubot::Scripts::googleImage' }
BEGIN { use_ok 'Hubot::Scripts::macboogi' }
BEGIN { use_ok 'Hubot::Scripts::blacklist' }
BEGIN { use_ok 'Hubot::Scripts::backup' }
BEGIN { use_ok 'Hubot::Scripts::op' }
BEGIN { use_ok 'Hubot::Scripts::storable' }
BEGIN { use_ok 'Hubot::Scripts::print' }
BEGIN { use_ok 'Hubot::Scripts::rules' }
BEGIN { use_ok 'Hubot::Scripts::sayhttpd' }
BEGIN { use_ok 'Hubot::Scripts::githubIssue' }
