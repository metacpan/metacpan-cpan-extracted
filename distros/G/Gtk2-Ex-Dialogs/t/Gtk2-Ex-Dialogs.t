# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gtk2-Extras.t'

use Test::More ( tests => 8 );

#########################

BEGIN { use_ok( 'Gtk2::Ex::Dialogs' ); }

#########################
# are all the known methods accounted for?

# my @methods = qw( set_title
#                   set_text
#                   set_icon
#                   set_modal
#                   set_parent_window
#                   set_destroy_with_parent
#                   set_default_yes
#                   set_must_exist );
# can_ok( 'Gtk2::Ex::Dialogs', @methods );
can_ok( 'Gtk2::Ex::Dialogs', qw( import AUTOLOAD ) );

#########################
# and what of the modules?

my @errormsg_methods = qw( new new_and_run new_and_show );
can_ok( 'Gtk2::Ex::Dialogs::ErrorMsg', @errormsg_methods );

my @message_methods = qw( new new_and_run new_and_show );
can_ok( 'Gtk2::Ex::Dialogs::Message', @message_methods );

my @question_methods = qw( new new_and_run ask );
can_ok( 'Gtk2::Ex::Dialogs::Question', @question_methods );

my @choosedirectory_methods = qw( new ask_to_select ask_to_create );
can_ok( 'Gtk2::Ex::Dialogs::ChooseDirectory', @choosedirectory_methods );

my @choosefile_methods = qw( new ask_to_open ask_to_save );
can_ok( 'Gtk2::Ex::Dialogs::ChooseFile', @choosefile_methods );

my @choosepreviewfile_methods = qw( new ask_to_open ask_to_save );
can_ok( 'Gtk2::Ex::Dialogs::ChoosePreviewFile', @choosepreviewfile_methods );
