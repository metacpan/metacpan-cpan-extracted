#!/opt/local/bin/perl
use strict;
use warnings;
use lib "lib";
use Form::Sensible::Form;
use Form::Sensible::Field::Text;
use Form::Sensible::Renderer::Dump;
use Data::Dumper;

my $form = Form::Sensible::Form->new(name=>'test');
my $textarea = Form::Sensible::Field::Text->new(name=>'test_field', validation => { regex => qr/^[0-9a-z]*$/  });
$form->add_field($textarea);
my $dumper = Form::Sensible::Renderer::Dump->new(form=>$form);
$dumper->dump_hoh;