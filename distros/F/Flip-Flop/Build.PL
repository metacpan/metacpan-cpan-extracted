use 5.8.0;
use Module::Build;

my $b = Module::Build->new(
  configure_requires => {'Module::Build'=>0.4224},
  create_readme      =>  0,
  dist_abstract      => 'Set a switch in your script to zero after a run with the switch set to one.',
  dist_author        => 'philiprbrenan@gmail.com',
  license            => 'perl',
  module_name        => 'Flip::Flop',
  perl               => '5.8.0',
  requires           => {
    Carp=>0,
    'Data::Table::Text'=>20180924,
    'Test::More'=>0,
   },
 );

$b->create_build_script();
