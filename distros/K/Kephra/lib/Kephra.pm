# See end of file for docs
package Kephra;

use 5.006;
use strict;
use warnings;

our $NAME        = __PACKAGE__;    # name of entire application
our $VERSION     = '0.4.3.34';        # version of entire app
our $PATCHLEVEL;                   # has just stable versions
our $STANDALONE;                   # starter flag for moveable installations
our $LOGLEVEL;                     # flag for benchmark loggings
our $BENCHMARK;

# Configuration Phase
sub load_modules { # -NI = not implemented or used, -DEP = depreciated
	require Cwd;
	require Encode;
	require Encode::Guess;
	require File::Find;
	require File::Spec::Functions;
	require File::UserConfig;
	require Config::General;               # 
	require YAML::Tiny;

	require Wx;                            # Core wxWidgets Framework
	#Wx->import( ':everything' );          # handy while debugging
	require Wx::AUI;                       # movable Panel controler
	require Wx::STC;                       # Scintilla editor component
	require Wx::DND;                       # Drag'n Drop & Clipboard support (only K::File)
	require Wx::Locale;                    # not yet in use
	require Wx::Perl::ProcessStream;       # 
	#require Wx::Print;                    # Printing Support (used only in Kephra::File )
	#require Text::Wrap                    # for text formating

	# these will used in near future
	#require Perl::Tidy;                   # -NI perl formating
	#require PPI ();                       # For refactoring support
	#require Params::Util ();              # Parameter checking
	#require Class::Inspector ();          # Class checking

	# used internal modules, parts of kephra
	require Kephra::API;                   # API for most inter modul communication
	require Kephra::App;                   # App start & shut down sequence
	require Kephra::App::ContextMenu;      # contextmenu manager
	require Kephra::App::EditPanel;        # Events, marker, visual settings of the EP
	require Kephra::App::EditPanel::Indicator; # visual marker inside the edit panel
	require Kephra::App::EditPanel::Fold;  # events and visual stuff of 4 EP marigins
	require Kephra::App::EditPanel::Margin;# events and visual stuff of 4 EP marigins
	require Kephra::App::MainToolBar;      # toolbar below the main menu
	require Kephra::App::MenuBar;          # main menu
	require Kephra::App::Panel::CommandLine;#
	require Kephra::App::Panel::TreeTool;  #
	require Kephra::App::Panel::Notepad;   #
	require Kephra::App::Panel::Output;    #
	require Kephra::App::SearchBar;        # Toolbar for searching and navigation
	require Kephra::App::StatusBar;        #
	require Kephra::App::TabBar;           # API 2 Wx::Notebook
	require Kephra::App::Window;           # API 2 Wx::Frame and more
	require Kephra::CommandList;           # 
	require Kephra::Config;                # low level config manipulation
	require Kephra::Config::Default;       # build in emergency settings
	#require Kephra::Config::Default::CommandList;
	#require Kephra::Config::Default::ContextMenus;
	#require Kephra::Config::Default::GlobalSettings;
	#require Kephra::Config::Default::Localisation;
	#require Kephra::Config::Default::MainMenu;
	#require Kephra::Config::Default::ToolBars;
	require Kephra::Config::File;          # API 2 ConfigParser: Config::General, YAML
	require Kephra::Config::Global;        # API 4 config, general content level
	require Kephra::Config::Localisation;  # load store change localisation
	require Kephra::Config::Interface;     # loading Interface data menus, bars etc
	require Kephra::Config::Tree;          # data tree manipulation
	require Kephra::Dialog;                # API 2 dialogs, fileselectors, msgboxes
	#require Kephra::Dialog::Color;         # color browsing tool
	#require Kephra::Dialog::Config;        # config dialog
	#require Kephra::Dialog::Exit;          # select files to be saved while exit program
	#require Kephra::Dialog::Info;          # info box
	#require Kephra::Dialog::Keymap;        # -NI
	#require Kephra::Dialog::Notify         # inform about filechanges from outside
	#require Kephra::Dialog::Search;        # find and replace dialog
	require Kephra::Document;              # internal doc handling: create, destroy, etc
	require Kephra::Document::Change;      # calls for changing current doc
	require Kephra::Document::Data;        # manage data structure for all docs
	require Kephra::Document::Property;    # user alterable document settings
	require Kephra::Document::SyntaxMode;  # language specific settings
	require Kephra::Edit;                  # basic edit menu funktions
	require Kephra::Edit::Comment;         # comment functions
	require Kephra::Edit::Convert;         # convert functions
	require Kephra::Edit::Format;          # formating functions
	require Kephra::Edit::History;         # undo redo etc.
	require Kephra::Edit::Goto;            # editpanel textcursor navigation
	require Kephra::Edit::Marker;          # doc spanning bookmarks
	require Kephra::Edit::Search;          # search menu functions
	require Kephra::Edit::Search::InputTarget; # enables darg n drob for comboboxes
	require Kephra::Edit::Select;          # text selection
	require Kephra::Edit::Special;         # collector of unsorted 
	require Kephra::EventTable;            # internal app API
	require Kephra::File;                  # file menu functions
	require Kephra::File::History;         # list of recent used Files
	require Kephra::File::IO;              # API 2 FS, read write files
	require Kephra::File::Session;         # file session handling
	require Kephra::Help;                  # help docs system
	require Kephra::Macro;                 # macro recorder, creation, replay
	require Kephra::Menu;                  # base menu builder
	require Kephra::Plugin;                # plugin manager
	require Kephra::Plugin::Demo;          # cookbook for plugin authors
	require Kephra::ToolBar;               # toolbar builder base
}

sub configdir {
	$_[0] and $_[0] eq $NAME and shift;
	File::UserConfig->configdir(@_);
}

sub import { #@_;
}

sub start {
	load_modules();

	my $basedir;
	# $ENV{HOME};
	# set locations of boot files
	my $config_sub_dir = 'config';
	my $help_sub_dir = 'help';
	my $start_file = 'autosaved.conf';
	my $boot_file = File::Spec->catfile
		(Kephra::Config::Global::_sub_dir(), $start_file);
	my $splashscreen = 'interface/icon/splash/start_kephra.jpg';

	if ($Kephra::STANDALONE) {
		$basedir = Cwd::cwd();
		$basedir = File::Spec->catdir($basedir, 'share')
			if $Kephra::STANDALONE eq 'dev';
	} else {
		my $copy_defaults;
		$basedir = Kephra::configdir();
		if (not -d File::Spec->catdir($basedir, $config_sub_dir)) {
			$copy_defaults = 1 
		}
		else {
			my $boot_file = File::Spec->catfile( $basedir, $boot_file );
			if (-r $boot_file) {
				my $config_tree = Kephra::Config::File::load($boot_file);
				$copy_defaults = 1 if not defined $config_tree->{about}{version}
				                   or $config_tree->{about}{version} ne $Kephra::VERSION;
			}
		}

		#if ($copy_defaults) {
			#my $dir = File::UserConfig->new();
			#if ($^O =~ /(?:linux|darwin)/i) {
				#for (@INC) {
					#if (!-d File::Spec->catdir($_, $dir->dist())) { next; }
					#$dir->{sharedir_} = $_;
					#last;
				#}
				#File::Find::find( sub { 
						#$dir->{sharedir} = $File::Find::dir 
						#if ($File::Find::dir =~ /$dir->{dist}.+$config_sub_dir$/)
					#}, $dir->{sharedir_}
				#);
				#$dir->{sharedir} =~ s/$config_sub_dir$//;
				#if (!-d $dir->{configdir}) { mkdir($dir->{configdir}); }
				#File::Copy::Recursive::dircopy
					#("$dir->{sharedir}*", $dir->{configdir}) || warn("$!");
				#File::Find::find(sub{
						#if    (-d $_) { chmod(0750,$_) }
						#elsif (-f $_) { chmod(0640,$_) }
					#},$dir->{configdir}
				#);
				#foreach (sort keys %$dir) {print "$_ : $dir->{$_}\n";} exit;
			#}
		#}
	}
	my $config_dir = File::Spec->catdir($basedir, $config_sub_dir);
	Kephra::Config::_dir( $config_dir );
	#Kephra::App::splashscreen($splashscreen);
	#use Wx::Perl::SplashFast ( File::Spec->catfile($config_dir, $splashscreen), 150);
	Kephra::Config::Global::auto_file( File::Spec->catdir($config_dir, $boot_file) );
	Kephra::Help::_dir( File::Spec->catdir($basedir, $help_sub_dir) );
	#$Kephra::temp{path}{logger} = File::Spec->catdir($basedir, 'log');

	# make .pm config files acessable - absolete when real syntax modes work
	push @INC, $config_dir;

	Kephra::App->new->MainLoop;         # starter for the main app
}
1;

__END__

=head1 NAME

Kephra - crossplatform GUI-Texteditor along Perl alike Paradigms 

=head1 SYNOPSIS

	> kephra [<files>]   # start with files already open

=head1 DESCRIPTION

This module install's a complete editor application with all its configs
and documentation for your programming, web and text authoring. 

=head2 Philosophy

=over 3

=item Main Goals

A visually harmonic and beautiful, sparing and elegantly programed Editor,
that helpes you with all your daily tasks. It should be also able to operate
in the way you prefer and be not afraid to try new things.

=item In Depth

I know, I know, there are plenty text editors out there, even some really
mighty IDE, but still no perfect solution for many programmers. So lets

=over 2

learn from Perl what it takes to build a tool thats powerful and fun to
play with for hours and months.


=item * make a low entry barrier (usable like notepad)

=item * copy what people like and are used to and whats not inherently broken

=item * give choices (TimTowtdi) 

=over 2

=item * (e.g. deliver vi and emacs input style)

=item * usable with menu, contextmenu, bars, mouse combo, key combos, commands ...

=item * configure via dialog and yaml/conf files ...

=back

=item * highly configurable / adaptable to personal preferences

=item * beauty / good integration on GUI, code and config level

=item * solve things with minimal effort (no bloat / minimal dependencies)

=item * still everything extendable by easy to write plugins

=back

    I believe strongly that there is much more possible with GUI editors
    and text editors in general than we are used today. So I try to weave
    fresh ideas wherever I can and design Kephra in a way, that every 
    programmer can alter and extend it easily. That can speed up progress
    or at least makes Kephra more comfortable for you.

    That is the plan, but we are currently not nearly that far.

=item Name

Especially from the last item derives the name, which is old egyptian and means
something like heart. Because true beauty and a harmonic synchronisation of all
parts of the consciousness begins when your heart awakens. Some call that true
love. In egypt tradition this was symbolized with a rising sun (ra) and the
principle of this was pictured as a scarab beatle with wings. Thats also a 
nice metaphor for an editor through which we give birth to programs, before
they rise on their own.

=item Details

I believe that Kephra's agenda is very similar to Perl's. Its common wisdom
that freedom means not only happiness but also life works most effective in
freedom. So there should not only be more than one way to write a program,
but also more than one way use an editor. You could:

=over 3

=item * select menu items

=item * make kombinations of keystrokes

=item * point and click your way with the mouse

=item * type short edit commands

=back

=back

So the question should not be vi or emacs, but how to combine the different
strengths (command input field and optional emacs-like keymap possibilities).
Perl was also a combination of popular tools and concepts into a single
powerful language.

Though I don't want to just adopt what has proven to be mighty. There are a lot
of tools (especially in the graphical realm) that are still waiting to be
discovered or aren't widely known. In Perl we write and rewrite them faster
and much more dense than in C or Java. Some function that help me every day
a lot, I written were in very few lines.

But many good tools are already on CPAN and Kephra should just be the glue
and graphical layer to give you the possibilities of these module to your 
fingertips in that form you prefer. This helpes also to improve these modules,
when they have more users that can give the authors feedback. It motivates
the community, when we can use our own tools and the perl ecosystem does not
depend on outer software like eclipse, even if it's sometimes useful.

Perl's second slogan is "Keep easy things easy and make hard things possible".
To me it reads "Don't scare away the beginners and grow as you go". And like
Perl I want to handle the complex things with as least effort as possible.
From the beginning Kephra was a useful program and will continue so.


=head2 Features

Beside all the basic stuff that you would expect I listed here some features
by category in main menu:

=over 2

=item File

file sessions, history, simple templates, open all of a dir, insert,
autosave by timer, save copy as, rename, close all other, detection if
file where changed elsewhere

=item Editing

unlimited undo with fast modes, replace (clipboard and selection),
line edit functions, move line/selection, indenting, block formating,
delete trailing space, comment, convert (case, space or indention)
rectangular selection with mouse and keyboard, auto- and braceindention

=item Navigation

bracenav, blocknav, doc spanning bookmarks, goto last edit, last doc, 
rich search, incremental search, searchbar and search dialog

=item Tools

run script (integrated output panel), notepad panel, color picker

=item Doc Property

syntax mode, codepage, tab use, tab width, EOL, write protection

=item View

all app parts and margins can be switched on and off, syntaxhighlighting
bracelight, ight margin, indention guide, caret line, line wrap, EOL marker,
visible whitespace, changeable font

=item Configs

config files to be opened through a menu: 
settings, all menus, commandID's, event binding, icon binding, key binding, 
localisation (translate just one file to transelate the app), syntaxmodes

and some help texts to be opened as normal files

=back

=head1 ROADMAP

=head2 Overview

Enduser Release 0.1

    a very simple editor
    
Enduser Release 0.2

    multiple documents, file session
    
Enduser Release 0.3

    searchbar and more comfort

Enduser Release 0.4

    This release was about getting the editor liquid or highly configurable.
    Its also about improvements in the user interface and of course the little
    things we missed. It also contains interpreter output panel and a notepad.

Enduser Release 0.5

    This release is about getting Kephra into the 'real' world out there
    and adding feature that are most needed and removing most hindering barriers.
    Folding, encodings, printing, .... and lot of minor tools and more help.

Enduser Release 0.6

    This release will be about extending Kephra internal extensions like a 
    file brwoser, command line and tree lib as Plugin API.

Enduser Release 0.7

     Introducing Syntaxmodes, for language sensitive data and functionions.

Enduser Release 0.8

    more heavier stuff like debugger

=head2 This Cycle

=over 2

=item Testing 0.4.1 - code folding

=item Testing 0.4.2 - folding and GUI refined, movable tabs, 2 more tools, doc data

=item Testing 0.4.3 - utf, marker, folding finished, 3 more tools, help links

=item Testing 0.4.4 - new mouse control, 2 more tools, updated docs

=item Testing 0.4.5 - more encodings, local notepad

=item Testing 0.4.6 - config dialog

=item Stable 0.5 - about dialog

=back

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kephra>

For other issues, contact the author.

More info and resources you find on our sourceforge web page under:

L<http://kephra.sourceforge.net>

=head1 ACKNOWLEDGMENTS

=over

=item * Herbert Breunung E<lt>lichtkind@cpan.orgE<gt> (main author)

=item * Jens Neuwerk (author of icons, GUI advisor)

=item * Andreas Kaschner (linux and mac ports)

=item * Adam Kennedy E<lt>adamk@cpan.orgE<gt> (cpanification)

=item * Renee Bäcker E<lt>module@renee-baecker.deE<gt> (color picker)

=item * Fabrizio Regalli E<lt>fabreg@fabreg.it<gt> (typos)

=item * many more since we study other editors a lot and also the padre sources


=back

=head1 COPYRIGHT AND LICENSE

This Copyright applies only to the "Kephra" Perl software distribution,
not the icons bundled within.

Copyright 2004 - 2010 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU GPL.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
