#!/usr/bin/perl
use warnings;
use strict;
use Gtk2::TestHelper tests => 6;

# Gtk2::Widget's size-request
{
  package TestSizeRequestChain::Base;
  use strict;
  use warnings;
  use Gtk2;
  use Glib::Object::Subclass
    'Gtk2::Widget',
      signals => { size_request => \&_do_size_request };

  our $size_request_runs = 0;
  sub _do_size_request {
    my ($self, $req) = @_;
    $size_request_runs = 1;
    $req->width (123);
    $req->height (456);
  }

  package TestSizeRequestChain::Sub;
  use strict;
  use warnings;
  use Gtk2;

  use Glib::Object::Subclass
    'TestSizeRequestChain::Base',
      signals => { size_request => \&_do_size_request };

  our $size_request_runs = 0;
  sub _do_size_request {
    my ($self, $req) = @_;
    $size_request_runs = 1;

    $self->signal_chain_from_overridden ($req);
  }

  package main;
  my $widget = TestSizeRequestChain::Sub->new;
  my $req = $widget->size_request;
  ok ($TestSizeRequestChain::Sub::size_request_runs,
      'TestSizeRequestChain::Sub size_request() runs');
  ok ($TestSizeRequestChain::Base::size_request_runs,
      'TestSizeRequestChain::Base size_request() runs');
  is ($req->width, 123,
      'TestSizeRequestChain width');
  is ($req->height, 456,
      'TestSizeRequestChain width');
}

# Gtk2::TextBuffer's insert-text
{
  package TestInsertTextChain;
  use strict;
  use warnings;
  use Gtk2;
  use Glib::Object::Subclass
    'Gtk2::TextBuffer',
      signals => { insert_text => \&_do_insert_text };

  our $insert_text_runs = 0;
  sub _do_insert_text {
    my ($self, $iter, $text, $length) = @_;
    $insert_text_runs++;
    $text =~ s/bla/blub/g;
    $self->signal_chain_from_overridden ($iter, $text, length($text));
  }

  package main;

  my $tb = TestInsertTextChain->new;
  my $iter = $tb->get_start_iter;
  for (my $i = 0; $i < 10; $i++) {
    # reuse $iter here to test whether it is correctly updated by the custom
    # insert-text handler
    $tb->insert ($iter, 'bla');
  }
  is ($TestInsertTextChain::insert_text_runs, 10,
      'TestInsertTextChain insert_text() runs');
  is ($tb->get_text ($tb->get_start_iter, $tb->get_end_iter, TRUE),
      'blub' x 10,
      'TestInsertTextChain buffer contents');
}
