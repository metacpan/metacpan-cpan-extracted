#!/opt/local/bin/perl
use strict;
use warnings;
use lib "lib";
use Form::Sensible::Form;
use Form::Sensible::Field::DateTime;
use Form::Sensible::Renderer::HTML;

my $form = Form::Sensible::Form->new(name=>'test');
my $datetime = Form::Sensible::Field::DateTime->new( name=>'test_field', default_value => 'yesterday at 5pm' );
$form->add_field($datetime);
my $renderer = Form::Sensible::Renderer::HTML->new( );
print $renderer->render($form)->complete;
