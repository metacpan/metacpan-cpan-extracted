use strict;
use warnings;
use Test::More;

BEGIN {
  my @modules = qw/
    Games::Sudoku::Component
    Games::Sudoku::Component::Base
    Games::Sudoku::Component::Controller
    Games::Sudoku::Component::Controller::History
    Games::Sudoku::Component::Controller::Status
    Games::Sudoku::Component::Controller::Loader
    Games::Sudoku::Component::Result
    Games::Sudoku::Component::Table
    Games::Sudoku::Component::Table::Cell
    Games::Sudoku::Component::Table::Item
    Games::Sudoku::Component::Table::Permission
  /;

  plan tests => scalar @modules;

  foreach my $module (@modules) {
    use_ok($module);
  }
}
