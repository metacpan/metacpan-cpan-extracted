package Gtk3::SourceView;

use strict;
use warnings;
use Glib::Object::Introspection;

our $VERSION = "0.12";


# customization ------------------------------------------------------- #

my %_NAME_CORRECTIONS = (
);
my @_CLASS_STATIC_METHODS = qw/
	Gtk3::SourceView::LanguageManager::get_default
	Gtk3::SourceView::StyleSchemeManager::get_default

	Gtk3::SourceView::Encoding::get_utf8
	Gtk3::SourceView::Encoding::get_current
	Gtk3::SourceView::Encoding::get_from_charset
/;
my @_FLATTEN_ARRAY_REF_RETURN_FOR = qw/	
	Gtk3::SourceView::Buffer::get_context_classes_at_iter
	Gtk3::SourceView::Buffer::get_source_marks_at_line
	Gtk3::SourceView::Buffer::get_source_marks_at_iter
	Gtk3::SourceView::Language::get_mime_types
	Gtk3::SourceView::Language::get_globs
	Gtk3::SourceView::Language::get_style_ids
	Gtk3::SourceView::LanguageManager::get_search_path
	Gtk3::SourceView::LanguageManager::get_language_ids
	Gtk3::SourceView::StyleScheme::get_authors
	Gtk3::SourceView::StyleSchemeManager::get_search_path
	Gtk3::SourceView::StyleSchemeManager::get_scheme_ids
	Gtk3::SourceView::Completion::get_providers

	Gtk3::SourceView::Encoding::get_all
	Gtk3::SourceView::Encoding::get_default_candidates
/;
# unsicher bin ich mir bei folgenden funktionen (noch zu testen!!!! ich glaub eher nicht):
# Gtk3::SourceView::Completion::add_provider
# Gtk3::SourceView::Completion::remove_provider
# nach test: Es klappt sowohl mit als auch ohne. Ich lass die Funktionen daher raus :-)
#
# Ich glaube auch diese gehören hier nicht rein: 
# 	Gtk3::SourceView::GutterRenderer::get_background
#	Gtk3::SourceView::MarkAttributes::get_background
my @_HANDLE_SENTINEL_BOOLEAN_FOR = qw/
	Gtk3::SourceView::SearchContext::forward
	Gtk3::SourceView::SearchContext::backward
/;
my @_USE_GENERIC_SIGNAL_MARSHALLER_FOR = (
);


sub import {

	Glib::Object::Introspection->setup(
		basename => 'GtkSource',
		version => '3.0',
		package => 'Gtk3::SourceView',

		class_static_methods =>\@_CLASS_STATIC_METHODS,
		flatten_array_ref_return_for =>\@_FLATTEN_ARRAY_REF_RETURN_FOR,
		handle_sentinel_boolean_for => \@_HANDLE_SENTINEL_BOOLEAN_FOR);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Gtk3::SourceView - Perl binding for the Gtk3::SourceView widget

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;
	use Gtk3 -init;
	use Glib ('TRUE','FALSE');
	use Gtk3::SourceView;

	# a window
	my $window = Gtk3::Window->new('toplevel');
	$window->set_title ('SourceView Example');
	$window->set_default_size(700, 450);
	$window->set_border_width(5);
	$window->signal_connect('delete_event' => sub {Gtk3->main_quit()});

	# SYNTAX HIGHLIGHTING (for example perl)
	# Create a Language Manager
	my $lm = Gtk3::SourceView::LanguageManager->get_default();
	my $lang = $lm->get_language('perl');

	# a text buffer (stores text)
	my $buffer1 = Gtk3::SourceView::Buffer->new_with_language($lang);
	$buffer1->set_highlight_syntax(TRUE);

	# a textview
	my $textview = Gtk3::SourceView::View->new();
	# displays the buffer
	$textview->set_buffer($buffer1);
	$textview->set_show_line_numbers(TRUE);
	$textview->set_wrap_mode("word");
	$textview->set_highlight_current_line(TRUE);
	$textview->set_highlight_current_line(TRUE);
	$textview->set_auto_indent(TRUE);

	# A SIMPLE WORD COMPLETION MODULE
	# get a completion widget
	my $completion = $textview->get_completion();

	# Gtk3::SourceView::CompletionWords is a simple implementation
	# of a Gtk3::SourceView::CompletionProvider
	my $provider = Gtk3::SourceView::CompletionWords->new('main');

	# in a new Buffer you can define the words that shall be displayed
	# by the Provider
	# Note: Gtk3::SourceView::CompletionWords doesn't support special
	# characters because he is written in Pango
	my $provider_buffer = Gtk3::SourceView::Buffer->new();
	$provider_buffer->set_text("print substr push pop shift index rindex");
	$provider->register($provider_buffer);

	# Last add the provider to the completion widget from the textview
	$completion->add_provider($provider);

	# add the textwidget, show the window and run the Application
	$window->add($textview);
	$window->show_all();
	Gtk3->main();

=head1 INSTALLATION

You need to install the typelib file for GtkSource. For example on Debian/Ubuntu it should be necessary to install the following package:

	sudo apt-get install gir1.2-gtksource-3.0
	
On Mageia for example the following should be preinstalled already:

	urpmi lib64gtksourceview-gir3.0

=head1 DESCRIPTION

Gtk3::SourceView is a simple binding for the Gtk3 SourceView 3.x widget using Gobject::Introspection. The Gtk SourceView widget is for example used by gedit, Anjuta and several other projects.

GtkSourceView extends the standard GTK+ framework for multiline text editing with support for configurable syntax highlighting, unlimited undo/redo, search and replace, a completion framework, printing and other features typical of a source code editor.

For more informations see  L<https://wiki.gnome.org/Projects/GtkSourceView>

=head2 Classes, methods and functions

The Gtk3::SourceView module provides the following classes and methods. For a more detailled and complete list of classes and functions see the API reference at L<https://developer.gnome.org/gtksourceview/stable/>

=head3 Gtk3::SourceView::Buffer

The Gtk3::SourceView::Buffer stores the text for display in a Gtk3::SourceView::View widget. It extends the GtkTextBuffer class by adding features useful to display and edit source code such as syntax highlighting and bracket matching. It also implements support for the undo/redo. Useful methods are:

=over

=item * C<< my $buffer = Gtk3::SourceView::Buffer->new() >>

This creates a new source buffer.

=item * C<< $buffer->set_language($lang) >>

With this method you can associate the Gtk3::SourceView::Language widget $lang with the created Gtk3::SourceView::Buffer widget $buffer. Note that $lang must not be interpolated!

=item * C<< Gtk3::SourceView::Buffer->new_with_language($lang) >>

This is the short form of C<< Gtk3::SourceView::Buffer->new() >> and C<< $buffer->set_language($lang) >>.

=item * C<< $buffer->set_highlight_syntax(TRUE) >>

To highlight the text according to the syntax patterns specified in the language set with C<< $buffer->set_language($lang) >> you have to set_highlight_syntax to TRUE. If highlight is FALSE, syntax highlighting is disabled.

=item * C<< $buffer->set_highlight_matching_brackets(TRUE) >>

Controls the bracket match highlighting function in the buffer. If activated, when you position your cursor over a bracket character (a parenthesis, a square bracket, etc.) the matching opening or closing bracket character will be highlighted.

=item * C<< $buffer->undo() >>

Undoes the last user action which modified the buffer. To avoid warnings you should combine this command with a if loop: C<< $buffer[$n]->undo() if ($buffer[$n]->can_undo); >>

=item * C<< $buffer->redo() >>

Redoes the last user action which modified the buffer. To avoid warnings you should combine this command with a if loop: C<< $buffer[$n]->redo() if ($buffer[$n]->can_redo); >>

=back

=head3 Gtk3::SourceView::View

Gtk3::SourceView::View is the main class of the Gtk3::SourceView::View library. This class provides showing the line numbers, highlighting the current line, indentation settings and much more. Useful methods are:

=over

=item * C<< my $view = Gtk3::SourceView:View->new(); >>

Creates a new Gtk3::SourceView::View widget. By default an empty Gtk3::SourceView::Buffer will be created, which can be retrieved with C<< $view->get_buffer(); >>. Alternatively you can set a created buffer with C<< $view->set_buffer($buffer) >>.

=item * C<< my $view = Gtk3::SourceView:View->new_with_buffer($buffer); >>

The same as C<< my $view = Gtk3::SourceView:View->new(); >> and C<< $view->set_buffer($buffer); >>

=item * C<< $view->set_show_line_numbers(TRUE); >>

If TRUE line numbers will be displayed beside the text.

=item * C<< $view->set_highlight_current_line(TRUE); >>

If TRUE the current line will be highlighted.

=item * C<< $view->set_auto_indent(TRUE); >>

If TRUE auto-indentation of text is enabled, i.e. that the auto-indentation inserts the same indentation as the previous line, when Enter is pressed to create a new line.

=item * C<< $view->get_completion(); >>

Gets the Gtk3::SourceView::Completion associated with $view . This is necessary to add a Completion Provider (see below)

=back

=head3 Syntax Highlighting

For Syntax Highlighting you first have to create a Gtk3::SourceView::LanguageManager. From the LanguageManager you can obtain a Gtk3::SourceView::Language, which represents a syntax highlighted language and which can applied to a Gtk3::SourceView::Buffer with C<< $buffer->set_language($lang) >> (see above and the exemplary code at synopsis). Useful methods are:
sudo apt-get install gir1.2-gtksource-3.0
=over

=item * C<< my $lm = Gtk3::SourceView::LanguageManager->new() >>

Creates a new language manager. If you do not need more than one language manager or a private language manager instance then use C<< my $lm = Gtk3::SourceView::LanguageManager->get_default() >>, which returns the default Gtk3::SourceView::LanguageManager instance, instead.

=item * C<< $lm->set_search_path(\@search_path); >>

Sets the list of directories where the LanguageManager looks for language files. Note that this function can called only before the language files are loaded for the first time, that means that you have to call this function right after creating the LanguageManager. The given argument (here \@search_path) must be a array reference to an array which contains the list of the directories.

=item * C<< my @ids = $lm->get_language_ids(); >>

Returns the ids of the avaible languages.

=item * C<< my $lang = $lm->get_language('id'); >>

Gets the Gtk3::SourceView::Language identified by the given id in the LanguageManager.

=item * C<< my $lang = $lm->guess_language('filename', 'content_type') >>

Picks a Gtk3::SourceView::Language for given 'filename' and 'content type', according to the information in lang files. Either filename or content_type may be undef.

=back

=head3 Completion

The completion system helps the user when he writes some text, such as words, command names, functions, and suchlike. Proposals can be shown, to complete the text the user is writing. Each proposal can contain an additional piece of information, that is displayed when the "Details" button is active.

Proposals are created via a Gtk3::SourceView::CompletionProvider. An provider to complete words is Gtk3::SourceView::CompletionWords. To create a custom provider you must implement a class which contains a Gtk3::SourceView::Provider interface using C<< use Glib::Object::Subclass 'Glib::Object', interfaces => [ 'Gtk3::SourceView::CompletionProvider' ]; >> and then create in the main program an provider object from this class with C<< my $provider = ProviderClass->new(); >>

To add a provider, call C<< $completion->add_provider($provider) >> whereby $completion is a Gtk3::SourceView::Completion object which can be obtained with C<< $view->get_completion() >> (see above).

When the completion is activated, a Gtk3::SourceView::CompletionContext object is created. The providers are asked whether they match the context, with Gtk3::SourceView::CompletionProvider->match(). If a provider doesn't match the context, it will not be visible in the completion window. On the other hand, if the provider matches the context, its proposals will be displayed.

The Gtk3::SourceView::CompletionProposal interface represents a proposal. The Gtk3::SourceView::CompletionItem class is a simple implementation of this interface.

Each Gtk3::SourceView::View object is associated with a Gtk3::SourceView::Completion instance. This instance can be obtained with C<< $view->get_completion(); >>. The Gtk3::SourceView::View class contains also the "show-completion" signal.

A same Gtk3::SourceView::CompletionProvider object can be used for several Gtk3::SourceView::Completion.

=head4 example with Gtk3::SourceView::CompletionWords

The Gtk3::SourceView::CompletionWords is an example of an implementation of the Gtk3::SourceView::CompletionProvider interface. The proposals are words appearing in the registered Gtk3::TextBuffers. Note that Gtk3::SourceView::CompletionWords is driven by Pango and therefore as Pango does not recognize special characters. 

See the following example:

	# first of all get the Gtk3::SourceView::Completion object
	#associated with the current TextView
	my $completion = $textview->get_completion();
	
	# Create a new Gtk3::SourceView::CompletionWords provider
	# with the name 'main'
	my $provider = Gtk3::SourceView::CompletionWords->new('main');
	
	# create a buffer with the proposals which shall be provided 
	# by the provider
	# Note that the built-in Words-Provider does not 
	# recognize special characters!
	my $provider_buffer = Gtk3::SourceView::Buffer->new();
	$provider_buffer->set_text("Proposal1 Proposal2 Proposal3");
	
	# Register the $provider_buffer in the Words-Provider
	# Note: You can also register the Buffer 
	# which is associated with the textview
	# In this case all words you have written 
	# some times will be provided as proposals
	$provider->register($provider_buffer);
	
	# Add the provider to the completion 
	# associated with the current textview
	$completion->add_provider($provider);

=head4 example with a custom provider

Creating a custom provider is very tricky because you cannot create the provider directly. Instead you must implement a class which contains a Gtk3::SourceView::Provider and then create in the main program an provider object from this class. The following example creates a custom provider with the default values. For a more detailled instruction about the functions of the Provider Interface you have to set up in the ProviderClass see L<https://developer.gnome.org/gtksourceview/stable/GtkSourceCompletionProvider.html> and especially the chapter "struct GtkSourceCompletionProviderIface" there.
 
Note that for creating the necessary functions in the ProviderClass they have to be written in upper-case letters, i.e. that for example C<< sub get_name {} >> must be written as C<< sub GET_NAME {} >>. Further informations cann be found at the documentation of the perl modul L<Glib::Object::Subclass>.

For starting the following simple example is hopefully helpful:

	#!/usr/bin/env perl

	[...]
	
	# First of all create the Provider class
	package ProviderClass;
	
	use Glib ("TRUE","FALSE");
	use Gtk3::SourceView;

	# to create a class with a Gtk3::Completion::Provider
	# interface we can use the Glib::Object::Subclass
	# module
	# note that when you use Glib::Object::Subclass you
	# usually don't have to define a new() method yourself - 
	# it's automatically created for you.
	use Glib::Object::Subclass
		'Glib::Object',
		interfaces => [ 'Gtk3::SourceView::CompletionProvider' ];

	# below we create all necessary virtual functions for 
	# the Provider interface (here with the default options)
	# see details https://developer.gnome.org/gtksourceview/stable
	# /GtkSourceCompletionProvider.html#GtkSourceCompletionProviderIface>
	
	sub GET_NAME {
		return 'Custom'
	}
	
	sub GET_ICON {

	}

	sub POPULATE {
		my $proposal = Gtk3::SourceView::CompletionItem->new('Proposal1','Proposal1');
		my @proposals = ($proposal);
		$context->add_proposals($self, \@proposals, TRUE);
	}

	sub MATCH {
		return TRUE;
	}

	sub GET_ACTIVATION {
		return 'interactive';
	}

	sub GET_INFO_WIDGET {
	
	}

	sub GET_START_ITER {
		return FALSE;
	}

	sub ACTIVATE_PROPOSAL {
		return FALSE;
	}

	sub GET_INTERACTIVE_DELAY {
		return '-1';
	}

	sub GET_PRIORITY {
		return 0;
	}

	# After creating the Provider class we have to
	# create a provider object as follows
	# and associate it with the current textview/completion
	package main;
	[...]
	my $completion = $textview->get_completion();
	my $custom_provider = ProviderClass->new();
	$completion->add_provider($custom_provider);

=head3 Search and Replace

B<PLEASE NOTE:> The following example describes not the way you should go!!! It is better to use a Gtk3::TextMark to save the start and end position of the current search result. You can find a wonderful example in C on L<http://www.bravegnu.org/gtktext/x276.html> which can be a good basis for your perl script. I hope to fix the manual accordingly in latter releases!

A GtkSourceSearchContext is used for the search and replace in a GtkSourceBuffer. The search settings are represented by a GtkSourceSearchSettings object.

Hopefully the following example is helpful for starting. The program search for "searchstring", if you click on the button "Suchen", and replaces the current search result with "replaced", if you click on the button "Ersetzen":

	#!/usr/bin/perl

	use strict;
	use Gtk3 -init;
	use Glib ('TRUE','FALSE');
	use Gtk3::SourceView;

	# Variables to save a Gtk3::TextIter for the start and end position
	# of the current search result
	my $start;
	my $end;
	
	# a window
	my $window = Gtk3::Window->new('toplevel');
	$window->set_title ('SourceView Example');
	$window->set_default_size(700, 450);
	$window->set_border_width(5);
	$window->signal_connect('delete_event' => sub {Gtk3->main_quit()});
	
	# two buttons for the search and replace functions
	my $button_search = Gtk3::Button->new();
	$button_search->set_label("Suchen");
	$button_search->signal_connect("clicked" => \&search_cb);
	
	my $button_replace = Gtk3::Button->new();
	$button_replace->set_label("Ersetzen");
	$button_replace->signal_connect("clicked" => \&replace_cb);
	
	# a text buffer (stores text)
	my $buffer = Gtk3::SourceView::Buffer->new();
	$buffer->set_text("searchstring \n searchstring \n searchstring \n searchstring \n searchstring \n");
	
	# For the search and replace function we need first a search context
	# associated with the buffer $buffer
	my $search_context = Gtk3::SourceView::SearchContext->new($buffer);
	
	# a textview
	my $textview = Gtk3::SourceView::View->new();
	# displays the buffer
	$textview->set_buffer($buffer);
	$textview->set_wrap_mode("word");
	$textview->set_hexpand(TRUE);
	$textview->set_vexpand(TRUE);
	
	# a grid to attach the widgets
	my $grid = Gtk3::Grid->new();
	$grid->set_column_spacing(20);
	$grid->set_row_spacing(20);
	$grid->attach($button_search, 0, 0, 1, 1);
	$grid->attach($button_replace, 1, 0, 1, 1);
	$grid->attach($textview, 0, 1, 2, 1);
	
	# add the grid to the window, 
	# show the window and run the Application
	$window->add($grid);
	$window -> show_all();
	Gtk3->main();
	
	sub search_cb {
		# First we need a Gtk3::SourceView::SearchSettings object
		# This element represents the settings of a search and can be associated
		# with one or several Gtk3::SourceView::SearchContexts
		my $search_settings = Gtk3::SourceView::SearchSettings->new();
		# here we just want to set the text to search as 'searchstring'
		# Usually (if the search text is given by an entry or the like)
		# you may be interested to call Gtk3::SourceView::Utils::unescape_search_text
		# before this function. Here this is not necessary.
		$search_settings->set_search_text('searchstring');
		# Last we associate the $search_settings with the $search_context
		$search_context->set_settings($search_settings);

		# The single search run
		# We need a Gtk3::TextIter for the first search run,
		# because there $end is not defined
		my $startiter = $buffer->get_start_iter();
		# The Gtk3::SourceView::SearchContext::forward
		# function returns an array with one Gtk3::Textiter
		# each start and end position of the search result
		my @treffer;
		# If one search run is already passed, wen want to start the 
		# current search run after the previous search result
		if ($end) {
			# Note: To avoid warning, we first check,
			# whether there is a further result
			if ($search_context->forward($end)) {
				# perform the search and save 
				# the Gtk3::Iters to @treffer
				@treffer = $search_context->forward($end);
				# Save the Gtk3::TextIter for 
				# the start position of the result
				# in the variable $start
				$start = @treffer[0];
				# Save the Gtk3::TextIter for 
				# the end position of the result
				# in the variable $end
				$end = @treffer[1];
				# Note: The concept of "current match" 
				# doesn't exist yet. 
				# A way to highlight differently 
				# the current match is to select it.
				$buffer->select_range($start, $end);
			}
			# If no further result exists, we start searching 
			# from the beginning
			else {
				$end = $buffer->get_start_iter();
				@treffer = $search_context->forward($end);
				$start = @treffer[0];
				$end = @treffer[1];
				$buffer->select_range($start, $end);
			}
		}
		# In the first search run $end is not defined
		# Therefore we start the first run at the Gtk3::TextIter
		# $startiter which points to the beginning of the buffer
		else {
			if ($search_context->forward($startiter)) {
			@treffer = $search_context->forward($startiter);
			$start = @treffer[0];
			$end = @treffer[1];
			$buffer->select_range($start, $end);
		}
	}
	}

	sub replace_cb {
	# Replacement is only possible, if there is a current search
	# result. This is the case, if $end is defined (see above)
	if ($end) {
		# Before replacement we need the offset of the 
		# $start Iterator to create a new Gtk3::TextIter after
		# Replacement
		my $offset_start = $start->get_offset();

		# Replace the current search result
		my $replace=$search_context->replace($start, $end, "replaced", -1);
	
		# IMPORTANT: Because the TextBuffer is changed, we need a 
		# new Gtk3::TextIter! otherwise we would get an error!
		# Therefore initialize the TextIter $end at position $offset_start!
		$end = $buffer->get_iter_at_offset($offset_start);
		
		# After the replacement it will be usually jumped to the
		# next search result
		search_cb();
		}
	}

=head2 Development status and informations

=head3 To-Do

=over

=item *

Gtk3::SourceView::File, Gtk3::SourceView::FileLoader and Gtk3::SourceView::FileSaver is not tested, because they require in many places the Perl Module Glib::IO. Although you can find a very early and unready implementation of Glib::IO on L<https://git.gnome.org/browse/perl-Glib-IO> (not yet published on CPAN!) we don't want to use it here because of the early development status of the Glib::IO module. Perhaps the classes Gtk3::SourceView::File, Gtk3::SourceView::FileLoader and Gtk3::SourceView::FileSaver work with this module, but I cannot guarantee it! I advise to use the normal Gtk3::FileChooserDialog, get the filename with C<< my $filename = $filechooserdialog->get_filename >> and use the standard perl functions for read and write to files (e.g. C<< open my $fh, ">:encoding(utf8)>, $filename; print $fh "$content"; close $fh; >>

=item *

The same problem could occur if you try an asynchronous search with Gtk3::SourceView::SearchContext->forward_async or the like. There are Glib::IO objects necessary, too. Therefore I cannot guarantee whether it works!

=item *

Also untested are the classes Gtk3::SourceView::PrintCompositor, Gtk3::SourceView::Map, Gtk3::SourceView::Tag, Gtk3::SourceView::UndoManager, Gtk3::SourceView::Gutter*, Gtk3::SourceView::Mark* and Gtk3::SourceView::Style. Although these classes should mostly work without problems, I cannot guarantee it (but I am thankful for every feedback!)

=back

=head3 Customizations and overrides

In order to make things more Perlish, Poppler customizes the API generated by L<Glib::Object::Introspection> in a few spots:

=over

=item * The array ref normally returned by the following functions is flattened into a list:

=over

=item Gtk3::SourceView::Buffer::get_context_classes_at_iter

=item Gtk3::SourceView::Buffer::get_source_marks_at_line

=item Gtk3::SourceView::Buffer::get_source_marks_at_iter
	
=item Gtk3::SourceView::Language::get_mime_types
	
=item Gtk3::SourceView::Language::get_globs
	
=item Gtk3::SourceView::Language::get_style_ids
	
=item Gtk3::SourceView::LanguageManager::get_search_path
	
=item Gtk3::SourceView::LanguageManager::get_language_ids
	
=item Gtk3::SourceView::StyleScheme::get_authors
	
=item Gtk3::SourceView::StyleSchemeManager::get_search_path
	
=item Gtk3::SourceView::StyleSchemeManager::get_scheme_ids
	
=item Gtk3::SourceView::Completion::get_providers

=item Gtk3::SourceView::Encoding::get_all
	
=item Gtk3::SourceView::Encoding::get_default_candidates

=back

=item * The following functions normally return a boolean and additional out
arguments, where the boolean indicates whether the out arguments are valid.
They are altered such that when the boolean is true, only the additional out
arguments are returned, and when the boolean is false, an empty list is
returned.

=over

=item Gtk3::SourceView::SearchContext::forward
	
=item Gtk3::SourceView::SearchContext::backward

=back

=item * The following functions are treated as class-static methods.

=over

=item Gtk3::SourceView::LanguageManager::get_default
	
=item Gtk3::SourceView::StyleSchemeManager::get_default

=item Gtk3::SourceView::Encoding::get_utf8
	
=item Gtk3::SourceView::Encoding::get_current
	
=item Gtk3::SourceView::Encoding::get_from_charset

=back

=back

=head1 SEE ALSO

=over

=item * GtkSourceView Homepage at L<https://wiki.gnome.org/Projects/GtkSourceView>

=item * GtkSourceView API Reference L<https://developer.gnome.org/gtksourceview/stable/>

=item * L<Glib>

=item * L<Glib::Object::Introspection>

=item * L<Glib::Object::Subclass>

=item * L<Gtk3>

=back

=head1 AUTHOR

Maximilian Lika, E<lt>Maximilian-Lika@gmx.de<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
