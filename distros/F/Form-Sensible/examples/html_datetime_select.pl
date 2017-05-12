#!/opt/local/bin/perl
use strict;
use warnings;
use lib "lib";
use Form::Sensible::Form;
use Form::Sensible::Field::DateTime;
use Form::Sensible::Renderer::HTML;

my $form = Form::Sensible::Form->new(name=>'test');
my $start = DateTime->new( year => 2011, month => 6, day => 10, hour => 7, minute => 2, second => 5 );
my $end = DateTime->new( year => 2013, month => 2, day => 25, hour => 10, minute => 59, second => 38 );
my $span = DateTime::Span->from_datetimes( start=> $start, end => $end );

my $datetime = Form::Sensible::Field::DateTime->new(
    name=>'monthly_field',
    default_value => 'last month',
    span => $span,
    recurrence => sub {
        return $_[0] if $_[0]->is_infinite;
        return $_[0]->truncate( to => 'month' )->add( months => 1 );
    },
    field_type => 'select',

);
$form->add_field($datetime);
my $renderer = Form::Sensible::Renderer::HTML->new( additional_include_paths => ['/home/david/src/ionzero/Form-Sensible/share/templates/default'] );
print $renderer->render($form)->complete;
