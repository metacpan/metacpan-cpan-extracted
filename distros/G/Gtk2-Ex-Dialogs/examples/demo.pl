#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use lib "./lib";
use File::Basename;

use Gtk2 -init;
use Gtk2::Ex::Dialogs;
use Gtk2::Ex::Utils qw( :main );

# create a dialog packed with a button for each demo test.
my $dialog = new Gtk2::Dialog ( 'test.pl', undef, [ ],
								'gtk-ok' => 'accept' );
$dialog->signal_connect( response =>
                         sub {
                             $_[0]->destroy();
                             process_main_exit();
                         } );

# mark the dialog as the parent window for any Gtk2::Ex::Dialogs
Gtk2::Ex::Dialogs->set_parent_window( $dialog );

my $show_button = new Gtk2::Button ( 'new and show' );
$show_button->signal_connect( clicked => \&Show );
$dialog->vbox->add( $show_button );

my $run_button = new Gtk2::Button ( 'new and run' );
$run_button->signal_connect( clicked => \&Run );
$dialog->vbox->add( $run_button );

my $err_show_button = new Gtk2::Button ( 'err and show' );
$err_show_button->signal_connect( clicked => \&Error_Show );
$dialog->vbox->add( $err_show_button );

my $err_run_button = new Gtk2::Button ( 'err and run' );
$err_run_button->signal_connect( clicked => \&Error_Run );
$dialog->vbox->add( $err_run_button );

my $question_button = new Gtk2::Button ( 'question' );
$question_button->signal_connect( clicked => \&Question );
$dialog->vbox->add( $question_button );

my $choosedirectory_button = new Gtk2::Button ( 'choose directory' );
$choosedirectory_button->signal_connect( clicked => \&ChooseDirectory );
$dialog->vbox->add( $choosedirectory_button );

my $choosefile_button = new Gtk2::Button ( 'choose file' );
$choosefile_button->signal_connect( clicked => \&ChooseFile );
$dialog->vbox->add( $choosefile_button );

my $choosepreviewfile_button = new Gtk2::Button ( 'choose preview file' );
$choosepreviewfile_button->signal_connect( clicked => \&ChoosePreviewFile );
$dialog->vbox->add( $choosepreviewfile_button );

# Main

$dialog->show_all();
main Gtk2;

# subs

sub ChooseDirectory {
    my $dirname =
     ask_to_select Gtk2::Ex::Dialogs::ChooseDirectory ( dirname( $0 ) );
    print STDOUT $dirname . "\n";
}

sub ChooseFile {
    my $filename =
     ask_to_open Gtk2::Ex::Dialogs::ChooseFile ( $0 );
    print STDOUT $filename . "\n";
}

sub ChoosePreviewFile {
    my $filename =
     ask_to_open Gtk2::Ex::Dialogs::ChoosePreviewFile ( $0 );
    print STDOUT $filename . "\n";
}

sub Question {
	my $answer =
     ask Gtk2::Ex::Dialogs::Question ( title => 'new_and_run Gtk2::Ex::Dialogs::Quesiton',
                                       text => 'A boolean question: Yes or No?' );
	if ( $answer ) {
        print STDOUT "yes\n";
    } else {
        print STDOUT "no\n";
    }
}

sub Error_Show {
	new_and_show
     Gtk2::Ex::Dialogs::ErrorMsg ( title => 'new_and_show Gtk2::Ex::Dialogs::ErrorMsg',
                                   text => "This should be a non-blocking error message." );
}

sub Error_Run {
	new_and_run
     Gtk2::Ex::Dialogs::ErrorMsg ( title => 'new_and_run Gtk2::Ex::Dialogs::ErrorMsg',
                                   text => "This should be a blocking error message." );
}

sub Show {
	new_and_show
     Gtk2::Ex::Dialogs::Message ( title => 'new_and_show Gtk2::Ex::Dialogs::Message',
                                  text => "This message box shouldn't block the script." );

}

sub Run {
	new_and_run
     Gtk2::Ex::Dialogs::Message ( title => 'new_and_run Gtk2::Ex::Dialogs::Message',
                                  text => "<b>Pango</b> <i>markup</i> <u>is allowed</u>.",
                                  icon => 'info' );
}

