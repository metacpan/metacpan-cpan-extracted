#!/usr/bin/env perl

use v5.10;
use warnings;

use blib;

use Data::Dumper;

use Hobocamp;

my $c = Hobocamp->new;
$c->init();

my %items;
my @f;
my @t = (
    'Calendar',   'calendar',            'CheckList', 'multiple select',    'DirectorySelect', 'directory selector',
    'EditBox',    'edit multiple lines', 'Form',      'TODO',               'FileSelect',      'file selector',
    'Gauge',      'TODO',                'InputBox',  'edit a single line', 'Menu',            'select 1 item from a list',
    'MessageBox', 'message box',         'MixedForm', 'TODO',               'Pause',           'display a message for a period of time',
    'RadioList',  'radio list',          'TailBox',   'TODO',               'TextBox',         'show text from a file',
    'TimeBox',    'Choose a time',       'YesNo',     'yes or no?',         'Quit',            'Exit application'
);

for (my $i = 0; $i < scalar(@t); $i += 2) {
    push(@f, {name => $t[$i], text => $t[ $i + 1 ]});
}

my $menu = Hobocamp::Menu->new(
    items       => \@f,
    menu_height => 10,
    title       => "Supported Widgets",
    prompt      => "Choose a widget to fiddle with",
);

my @o;

while (1) {
    $menu->run;

    my $widget;

    my $v = $menu->value;

    given ($v->{name}) {
        when ('Calendar') {
            $widget = Hobocamp::Calendar->new(title => "Calendar", "prompt" => "check out this awesome calendar!");
        }
        when ('CheckList') {
            $widget = Hobocamp::CheckList->new(
                items => [
                    {
                        name => 'item 1', 'text' => "thing 1"
                    },
                    {
                        name => 'item 2', "text" => "thing 2", "on" => 1
                    }
                ],
                list_height => 10,
                title       => "CheckList",
                prompt      => "Choose one or more"
            );
        }
        when ('DirectorySelect') {
            $widget = Hobocamp::DirectorySelect->new(title => "DirectorySelect", "path" => "/tmp");
        }
        when ('EditBox') {
            $widget = Hobocamp::EditBox->new(title => "EditBox", "file" => "/etc/motd");
        }
        when ('FileSelect') {
            $widget = Hobocamp::FileSelect->new(title => "FileSelect", path => "/tmp");
        }
        when ('InputBox') {
            $widget = Hobocamp::InputBox->new(title => "InputBox", "prompt" => "How old are you?");
        }
        when ('Menu') {
            $widget = Hobocamp::Menu->new(
                items => [
                    {
                        name => 'item 1', 'text' => "thing 1"
                    },
                    {
                        name => 'item 2', "text" => "thing 2"
                    }
                ],
                list_height => 10,
                title       => "Menu",
                prompt      => "Choose one"
            );
        }
        when ('MessageBox') {
            $widget = Hobocamp::MessageBox->new(title => "MessageBox", "prompt" => "Important stuff!");
        }
        when ('Pause') {
            $widget = Hobocamp::Pause->new(title => "Pause", "prompt" => "Now wait 10 seconds", seconds => 10);
        }
        when ('RadioList') {
            $widget = Hobocamp::RadioList->new(
                items => [
                    {
                        name => 'item 1', 'text' => "thing 1"
                    },
                    {
                        name => 'item 2', "text" => "thing 2", "on" => 1
                    }
                ],
                list_height => 10,
                title       => "RadioList",
                prompt      => "Choose one"
            );
        }
        when ('TextBox') {
            $widget = Hobocamp::TextBox->new(title => "TextBox", "file" => "/etc/motd");
        }
        when ('TimeBox') {
            $widget = Hobocamp::TimeBox->new(title => "TimeBox", "prompt" => "Choose a time");
        }
        when ('YesNo') {
            $widget = Hobocamp::YesNo->new(title => "YesNo", "prompt" => "Do you agree?");
        }
        when ('Quit') {
            last;
        }
        default {
            last;
        }
    }

    $menu->hide;
    $widget->run;

    if ($widget->value) {
        my $w = Hobocamp::MessageBox->new(title => "response", prompt => "the widget returned\n" . Dumper($widget->value));
        $w->run;
        $w->hide;
    }

    $widget->hide;
}

$c->destroy;
