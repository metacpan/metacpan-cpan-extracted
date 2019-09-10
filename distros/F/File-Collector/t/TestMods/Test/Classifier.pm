package Test::Classifier ;

use strict; use warnings;
use t::TestMods::Test::Processor;
use t::TestMods::Test::TestObj;
use Role::Tiny;

sub _init_processors {
  qw ( some other );
}

sub _classify_file {
  my $s   = shift;
  $s->_classify('some');
  my $obj = Test::TestObj->new();
  $s->_add_obj('test', $obj);
  $s->attr_defined('test', 'prop');
  $s->get_obj('test');
  $s->set_obj_prop('test', 'prop', 37);
  $s->get_filename;
  $s->obj_meth('test', 'do_something');
  $s->has_obj('test');
}

1;
