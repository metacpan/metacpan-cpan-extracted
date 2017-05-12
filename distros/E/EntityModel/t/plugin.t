use strict;
use warnings;
package EntityModel::TestPlugin;
use EntityModel::Class {
	_isa => [qw(EntityModel::Plugin)],
};
use Test::More;
use Test::Deep;

sub register {
	my $self = shift;
	my $model = shift;
	$model->provide_handler_for(
		thing	=> sub {
			my $self = shift;
			my %args = @_;
			is($args{item}, 'thing', 'have expected key');
			cmp_deeply($args{data}, bag({name => 'something', information => 'here'}), 'have expected data');
		}
	);
	return $self;
}

package main;
use Test::More tests => 6;
use EntityModel;

my $plugin = new_ok('EntityModel::TestPlugin');
my $model = new_ok('EntityModel');
ok($model->add_plugin($plugin), 'add plugin');
ok($model->load_from(
	Perl	=> {
 "name" => "mymodel",
 "thing" => [ { "name" => "something", "information" => "here" } ],
 "entity" => [ {
  "name" => "thing",
  "field" => [
   { "name" => "id", "type" => "int" },
   { "name" => "name", "type" => "varchar" }
  ] }, {
  "name" => "other",
  "field" => [
   { "name" => "id", "type" => "int" },
   { "name" => "extra", "type" => "varchar" }
  ] } ]
}), 'load model');

