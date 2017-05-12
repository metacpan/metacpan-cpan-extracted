use strict;
use Test::More tests => 10;

BEGIN { use_ok 'MIME::Expander' }
BEGIN { use_ok 'MIME::Expander::Guess' }
BEGIN { use_ok 'MIME::Expander::Guess::FileName' }
BEGIN { use_ok 'MIME::Expander::Guess::MMagic' }
BEGIN { use_ok 'MIME::Expander::Plugin' }
BEGIN { use_ok 'MIME::Expander::Plugin::ApplicationTar' }
BEGIN { use_ok 'MIME::Expander::Plugin::ApplicationBzip2' }
BEGIN { use_ok 'MIME::Expander::Plugin::ApplicationGzip' }
BEGIN { use_ok 'MIME::Expander::Plugin::ApplicationZip' }
BEGIN { use_ok 'MIME::Expander::Plugin::MessageRFC822' }
