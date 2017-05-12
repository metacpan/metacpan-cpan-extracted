package HTML::JQuery;

=head1 NAME

HTML::JQuery - Generate jQuery/Javascript code in Perl

=head1 DESCRIPTION

This module is used to generate jQuery/Javascript code in Perl. What you do with it is up to you. I designed it for a work project where I needed to 
display certain Perl variables to the page using Javascript, so, instead of ajax calls I designed C<HTML::JQuery>, which obviously took longer. Go figure.
You can quite easily use it in a Perl Web Framework of your choice and display the Javascript it generates into a template, meaning you don't have to code 
any Javascript (Unless you need something extra).

=head1 SYNOPSIS

An example from a Catalyst point of view.

    ## Inside the Controller

    my $j = jquery sub {
        function 'testfunc' => sub {
            my $name = shift;
            alert "Test func called: $name";
        };

        function 'init' => sub {
            my $name = shift;
            alert "Document Loaded. Inside $name";
        };

        onclick '#heading' => sub { fadeout shift; };

        dialog '#test' => (
            title => 'Click Box!',
            body  => 'Thanks for clicking :-)',
            modal => 1,
            autoOpen => 0,
            buttons => {
                "OK" => function(sub {
                    dialog '#test', 'close';
                    alert 'closed!';
                }),
                "Nah" => function(sub {
                    alert "Fine. I won't close";
                }),
                q{'Test Func'} => function(sub {
                    func 'testfunc';
                }),
            },
        );

        onclick '.button' => sub {
            dialog '#test', 'open';
        };

        onclick '.slidey' => sub {
            fadein ('#slide_text', 1000,
                function(sub {
                    fadeout '#slide_text', 1000;
                })
            );
        };

        keystrokes '*' => ( keys => [qw( alt+ctrl+a )], event => function(sub { alert 'ALT+CTRL+A pressed' }) );
    };

    $c->stash->{jquery} = $j;

    ## Inside the template (.tt)
    [% jquery %] 

=cut

use Sub::Mage ':Class';
extends 'HTML::JQuery::Data';

$HTML::JQuery::VERSION = '0.005';
$HTML::JQuery::Inline = 0;
my $CLASS = __PACKAGE__;

sub import {
    my ($class, @args) = @_;

    $CLASS->_import_defs (qw/
        jquery
        jquery_inline
        onclick
        alert
        fadeout
        fadein
        dialog
        function
        func
        keystrokes
        slidetoggle
        rel
        hide
        show
        dom_remove
        datepicker
        appendhtml
        code
    /);
}

sub _import_defs {
    my ($self, @defs) = @_;
    my $pkg = caller(1);
    for (@defs) {
        exports $_ => ( into => $pkg );
    }
}

sub code {
    my $self = shift;
    return join '', @{$HTML::JQuery::Data::JQuery};
}

=head2 jquery

All your HTML::JQuery must be wrapped between the jquery subroutine, like so

    my $j = jquery sub {
        ...
    };

Then you can pass the C<$j> variable to whatever output you need. For example, in Catalyst you might do:

    my $j = jquery sub {
        function 'init' => sub { alert 'Loaded!'; };
    };

    $c->stash->{jquery} = $j;

    # then in the template
    [% jquery %]

=cut

sub jquery {
    my $sub = shift;
    $CLASS->jquery_add("<script type=\"text/javascript\">");
    $CLASS->jquery_add("\$(document).ready(function() {");
    $CLASS->jquery_add("if (typeof init == 'function') { init(); }");
    $sub->(@_);
    $CLASS->jquery_add("});");
    $CLASS->jquery_add("</script>\n");
    return join '', @{$HTML::JQuery::Data::JQuery};
}

=head2 jquery_inline

This is emulates an anonymous Javascript function. Like, C<function() { ... }>
Normally you would use these in callbacks.

    onclick '#test' => sub {
        my $this = shift;
        hide $this, 2000, jquery_inline(sub { alert '#test is now hidden'; });
    };

=cut

sub jquery_inline {
    my $sub = shift;
    $HTML::JQuery::Inline = 1;
    $HTML::JQuery::Data::Inline = [];
    $sub->(@_);
    $HTML::JQuery::Inline = 0;
    return join '', @{$HTML::JQuery::Data::Inline};
}

=head2 onclick

As the name states, this event will be triggered when a given element is clicked.
The name of the element is passed in the first argument, if you need it.

    onclick '.myclass' => sub {
        my $this = shift;
        alert "$this was called";
    };

=cut

sub onclick {
    my ($sel, $code) = @_;
    $CLASS->jquery_add($CLASS->jquery_onclick($sel));
    $code->($sel);
    $CLASS->jquery_add($CLASS->jquery_end);
}

=head2 alert

A very basic Javascript alert box.

    alert 'Huzzah!';

=cut

sub alert {
    my $message = shift;

    $message =~ s/"/\\"/g;
    $CLASS->js_alert($message);
}

=head2 function

Creates a standard Javascript function. Currently arguments are not supported, but will be in the future. 
The first argument in the subroutine is the name of the function.

    function 'boo' => sub {
        my $name = shift;
        alert "$name was called!";
    };

Also, if we create a function called C<init>, then HTML::JQuery will run it once the document has loaded.

    function 'init' => sub {
        alert "The page has successfully loaded";
        alert "We can now do stuff";
    };

As of 0.005, calling C<function> with no name and just a code reference results in a Javascript callback (like jquery_inline, but with a more relevant name).

=cut

sub function {
    my ($name, $function) = @_;
    if ($function) {
        $CLASS->jquery_add("function $name() {");
        $function->(@_);
        $CLASS->jquery_add("}");
    }
    else {
        $HTML::JQuery::Inline = 1;
        $HTML::JQuery::Data::Inline = [];
        $name->(@_);
        $HTML::JQuery::Inline = 0;
        return join '', @{$HTML::JQuery::Data::Inline};
    }
}

=head2 func

Simply calls a Javascript function.

    function 'myfunc' => sub { alert "Help! I've been ran!"; };
    onclick '#runIt' => sub { func 'myfunc'; };

=cut

sub func {
    my $func = shift;
    $CLASS->js_callfunc($func);
}

=head2 fadeout

Hides the specified element with a "fade" effect. You can set the speed and even provide a callback 
for when the command has completed. The last two options are completely optional, though.

    function 'fadeText' => sub {
        fadeout '#text';
        fadeout '#text2', 1000;
        fadeout '#text3', 'slow';
        fadeout '#text4', 2000, function(sub { alert '#text4 is now hidden' });
    };

=cut

sub fadeout {
    my ($sel, $duration, $after) = @_;
    
    $CLASS->jquery_fade('Out', $sel, $duration, $after);
}

=head2 fadein

fadein is the exact same as C<fadeout>, except it makes an element "re-appear". I won't repeat myself with example code.

=cut

sub fadein {
    my ($sel, $duration, $after) = @_;
    
    $CLASS->jquery_fade('In', $sel, $duration, $after);
}

=head2 slidetoggle

Binds itself to an element so when you click said element it appears by sliding out, then, when clicked again will disappear by sliding in.

    onclick '#paragraph' => sub {  
        slidetoggle '.text', 1000;
    };

C<slidetoggle> also has a duration and callback feature, much the same as C<fadein> and C<fadeout>.

=cut

sub slidetoggle {
    my ($sel, $duration, $after) = @_;
    $CLASS->jquery_slidetoggle($sel, $duration, $after);
}

=head2 keystrokes

JQuery keybindings - a truly fun extension to JQuery. This requires a Javascript file that is included with this module.
An example event to make an alert box appear after typing the word alert into your browser..

    keystrokes '*' => ( keys => [qw( a l e r t )], event => function(sub { alert 'You typed a l e r t' }) );

Not only can it be triggered by keys pressed one after another, but you can make it work with multiple keys pressed at the same time.

    keystrokes '*' => ( keys => [ 'alt+m' ], event => function(sub { alert 'Alt+M was pressed' }) );

It's also possible to mix multiple key presses with single ones if you wish.

=cut

sub keystrokes {
    my ($sel, %args) = @_;
    $CLASS->jquery_keystrokes($sel, \%args);
}

=head2 dialog

Runs a jQuery dialog box. Let's take a look.

    dialog '#test' => (
        title    => 'My dialog title',
        autoOpen => 1, # run when the document has loaded?
        modal    => 1, # focuses on the window and blocks out everything else until its closed
        body     => '<p>This is the content within the dialog</p>',
        buttons  => {
            OK   => function(sub {
                dialog '#test', 'close';
            }),
            Fade => function(sub {
                fadeout 'p', 1000;
                alert 'Text faded';
            }),
        },
    );

=cut

sub dialog {
    my ($sel, %opts) = @_;
    $CLASS->jquery_dialog($sel, \%opts);
}

=head2 rel

Just retrieves the C<rel> attribute from an element.

    rel '.somelink';

=cut

sub rel {
    my $sel = shift;
    $CLASS->jquery_rel($sel);
}

=head2 hide

Similar to C<fadeout>, but without the actual "fade" effect. It simply hides an element, but doesn't permanently remove it. 
It will do a CSS equivalent to C<display:none>.
Like most of these types of functions the second argument is the duration and the third is a callback. Both are optional.

    hide '#test', 1000, function(sub{ alert 'Hidden #test' });

=cut

sub hide {
    my ($sel, $duration, $after) = @_;
    $CLASS->jquery_hide($sel, $duration);
}

=head2 show

The same as C<hide>, only shows the element instead if it's hidden

=cut

sub show {
    my ($sel, $duration, $after) = @_;
    $CLASS->jquery_show($sel);
}

=head2 dom_remove

Completely removes the given element from the DOM. This means it won't be able to be used again once it has been removed, unless you 
reload the page, of course.

    onclick 'div' => sub {
        hide 'this', 2000, function(sub {
            dom_remove 'this'
        });
    };

=cut

sub dom_remove {
    my $sel = shift;
    $CLASS->jquery_remove($sel);
}

=head2 datepicker

Binds a fancy calendar to a specific element (Usually an input field).
If you pass C<<auto =>>> 1 in the hash then it will append C<dateFormat: 'dd/mm/yy', changeMonth: true, changeYear: true> to 
the datepicker options plus anything you specify.

    datepicker '.datefield' => ( dateFormat => 'mm-dd-yy', currentText => 'Now' );

You can see a list of options on jQuery UI's website for datepicker.

=cut

sub datepicker {
    my ($sel, %args) = @_;
    $CLASS->jquery_datepicker($sel, \%args);
}

=head2 appendhtml

Dynamically appends html to a div. 

    innerhtml '#mydiv', 'Hello, World!';

=cut

sub appendhtml {
    my ($sel, $text) = @_;
    $CLASS->jquery_innerhtml($sel, $text);
}

=head1 BUGS

Please e-mail brad@geeksware.net

=head1 AUTHOR

Brad Haywood <brad@geeksware.net>

=head1 COPYRIGHT & LICENSE

Copyright 2011 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

1;

