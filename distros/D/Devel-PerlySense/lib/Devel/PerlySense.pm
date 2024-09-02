
=head1 NAME

Devel::PerlySense - Perl IDE backend with Emacs frontend


=head1 DESCRIPTION

PerlySense is a Perl IDE backend that integrates with editor
frontends, currently Emacs.

(While no one has written a Vim frontend, PerlySense can emit Vim
style data structures.)

Conveniently navigate and browse the code and documentation of your
project and Perl installation. Navigate between tests and source, and
between related files.

Search through the project for method declarations, invocants or free
text using Ack.

Run tests and scripts with easy navigation to errors/warnings/failing
tests. Tests can be run under Devel::Cover to collect (and display)
test coverage information.

Automate common editing tasks related to source code, tests, regular
expressions, etc.

Highlight syntax errors, warnings, Perl::Critic complaints, and
Devel::Cover test coverage in the source while editing.

PerlySense has a plugin system for understanding custom syntax,
e.g. Moose.



=head1 SYNOPSIS


=head2 From Emacs

B<Overview> -- C<C-o C-o> -- Show information about the Class at point
or the current Class. There are also shortcuts to show a single
section:

=over 4

=item * C-o o i -- Inheritance

=item * C-o o a -- API

=item * C-o o b -- Bookmarks

=item * C-o o u -- Uses

=item * C-o o h -- NeighbourHood

=back

B<Docs> -- C<C-o C-d> -- Show docs (POD/signature/etc) for the symbol
(module/method/sub) at point. A doc hint is displayed in the echo area
(for methods and subs), or a new POD buffer is created (for modules).

B<Document Inheritance> -- C<C-o d i> -- Show the Inheritance hierarchy
for the current Class in the echo area.

C<C-o d u> -- Document 'use Module' statements in the echo area.

B<Go To> -- C<C-o C-g> -- Open file at proper location for module,
method/sub declaration for the symbol (module/method/sub) at point. If
no sub declaration is available (like for generated getters/setters),
any appropriate POD is used instead.

B<Go To Use> -- C<C-o g u> -- Go to the 'use Module' section of the current buffer.

B<Go To 'new'> -- C<C-o g n> -- Go to the 'new' method of the current
class.

B<Go To Base Class> -- C<C-o g b> -- Open the file of the base class
of the current class. This will take you up one level in the
inheritance hierarchy.

B<Go To Module> -- C<C-o g m> -- Open the source file of the module at
point.

B<Go To Version Control> -- C<C-o g v> -- Go to the Project view of
the current Version Control system.

B<Go To Tests - Other Files> -- C<C-o g t o> -- Go to any related test
or source files given a L<Devel::CoverX::Covered> covered db.

B<Go To Project's Other Files> -- C<C-o g p o> -- Go to
I<corresponding> files given a C<.corresponding_file> config file (see
L<File::Corresponding>).

B<Find with Ack> -- C<C-o f a> -- Search for the selected text, or
word at point, or whatever, using Ack.

B<Find sub declarations> -- C<C-o f s> -- Search for sub declarations
of the method name, or word at point.

B<Find method calls> -- C<C-o f c> -- Search for method calls of the
method name, or word at point.

B<Go To Find Buffer> -- C<C-o g f> to go to the B<*grep*> buffer.

B<Run file> -- C<C-o C-r> -- Run the current file using the
Compilation mode and the settings appropriate for the source type
(Test, Module, etc.). Highlight errors and jump to source with C-c
C-c.

B<Run file under Devel::CoverX::Covered> -- C<C-o r c> -- Run the
current file, collecting Devel::CoverX::Covered information.

B<Edit - Copy Package Name> -- C<C-o e c p> -- Copy the current package name.

B<Edit - Copy Package Name From File> -- C<C-o e c P> -- Copy the
current package name from file name.

B<Edit - Copy Sub Name> -- C<C-o e c s> -- Copy the current sub name.

B<Edit - Copy Method Name> -- C<C-o e c m> -- Copy the current method
name (i.e. package->sub).

B<Edit - Copy File Name> -- C<C-o e c f> -- Copy the current file name.

B<Edit - Add Use Statement> -- C<C-o e a u> -- Add a 'use Module'
statement to the 'use Module' section at the top. Default Module name
is module at point.

B<Edit - Move Use Statement> -- C<C-o e m u> -- Move the 'use Module'
statement at point to the 'use Module' section at the top.

B<Extract Variable> - C<C-o e e v> -- Do the refactoring Extract
Variable of the active region.

B<Find Callers> - C<C-o e f c> -- Find callers of a method in the
project and insert the call tree as a comment in the source.

B<Visualize Callers> - C<C-o e v c> -- Visualize the callers comment
created by "Find Callers" using GrapViz.

B<Visualize Callers> - C<C-o e v c> -- Visualize callers in a call
tree (found by Find Callers) by drawing the call tree using GraphViz.

B<Edit Test Count> -- C<C-o e t c> -- Increase the test count
(e.g. "tests => 43")

B<Assist With Test Count> -- C<C-o a t> -- Synchronize invalid test
count in .t file with the B<*compilation*> buffer.

Flymake may be used to highlight syntax errors, warnings, and
Perl::Critic violations in the source while editing (continously or at
every save).



=head2 From Vim

There is no integraton with Vim available. Well, not properly
anyway. If you pass the option

 --io_type=editor_vim

to perly_sense, the output will be serialized to Vim L<Dictionary data
structures|http://vimdoc.sourceforge.net/htmldoc/eval.html#Dictionaries>.



=head2 From other editors

Any editor that is programmable and that can call a shell script could
take advantage of at least some parts of PerlySense to implement
something similar to the Emacs functionality. And most editors are
programmable by the authors, if not by the users.



=head2 From the command line

=over 4

=item * Create Project

  perly_sense create_project [--dir=DIR]

Create a PerlySense project in DIR (default is current dir).

If there is already a project.yml file, back it up with a datestamp
first.

(Note that you don't need to create a project before start using
PerlySense. Read more below).


=item * Process Project Source Files

  perly_sense process_project [--dir=.]

Cache all modules in the project that --dir belongs to.


=item * Process Source Files in @INC

  perly_sense process_inc

Cache all the modules in @INC.

This is a useful thing to do after installation (and after each
upgrade), but it will take a while so put it in the background and let
it churn away at those modules.

=over 4

=item * Unix

  perly_sense process_inc &        # (well, you knew that already)

=item * Windows

  start /MIN perly_sense process_inc

=back


=item * Get Info

  perly_sense info

Display useful information about what the current project directory,
user home directory, etc. is.

=back



=head1 INSTALLATION

=head2 Module Installation

Install the Devel::PerlySense module and accompanying elisp by using a
configured CPAN shell, like this:

  cpan Devel::PerlySense

When everything is installed, verify by running

  perly_sense info

The elisp is installed next to the Perl source (so it works to install
as an unpriviliged user, and you don't I<have> to have Emacs
installed, and the elisp and Perl source are always in sync).


=head2 Supporting modules

These aren't needed to begin with, but may be very useful.

=over 4

=item * L<Devel::CoverX::Covered>

If you have a lot of tests to navigate and run a nightly build with
Devel::Cover to generate test coverage. You can also run individual
files under Devel::CoverX::Covered with C<C-o r c>.

=item * L<File::Corresponding>

If you have an MVC style class structure with the same entity
represented in different directories (e.g. Controller::Aeroplane,
Model::Aeroplane, etc.).

=back



=head2 Emacs installation

Make sure the Devel::PerlySense CPAN module is installed, it contains
the required elisp files which will be loaded automatically with the
following in your .emacs config file:


    ;; *** PerlySense Config ***

    ;; ** PerlySense **
    ;; The PerlySense prefix key (unset only if needed, like for \C-o)
    (global-unset-key "\C-o")
    (setq ps/key-prefix "\C-o")


    ;; ** Flymake **
    ;; Load flymake if t
    ;; Flymake must be installed.
    ;; It is included in Emacs 22
    ;;     (or http://flymake.sourceforge.net/, put flymake.el in your load-path)
    (setq ps/load-flymake t)
    ;; Note: more flymake config below, after loading PerlySense


    ;; *** PerlySense load (don't touch) ***
    (setq ps/external-dir (shell-command-to-string "perly_sense external_dir"))
    (if (string-match "Devel.PerlySense.external" ps/external-dir)
        (progn
          (message
           "PerlySense elisp files  at (%s) according to perly_sense, loading..."
           ps/external-dir)
          (setq load-path (cons
                           (expand-file-name
                            (format "%s/%s" ps/external-dir "emacs")
                            ) load-path))
          (load "perly-sense")
          )
      (message "Could not identify PerlySense install dir.
    Is Devel::PerlySense installed properly?
    Does 'perly_sense external_dir' give you a proper directory? (%s)" ps/external-dir)
      )


    ;; ** Flymake Config **
    ;; If you only want syntax check whenever you save, not continously
    (setq flymake-no-changes-timeout 9999)
    (setq flymake-start-syntax-check-on-newline nil)

    ;; ** Code Coverage Visualization **
    ;; If you have a Devel::CoverX::Covered database handy and want to
    ;; display the sub coverage in the source, set this to t
    (setq ps/enable-test-coverage-visualization nil)

    ;; ** Color Config **
    ;; Emacs named colors: http://www.geocities.com/kensanata/colors.html
    ;; The following colors work fine with a white X11
    ;; background. They may not look that great on a console with the
    ;; default color scheme.
    (set-face-background 'flymake-errline "antique white")
    (set-face-background 'flymake-warnline "lavender")
    (set-face-background 'dropdown-list-face "lightgrey")
    (set-face-background 'dropdown-list-selection-face "grey")


    ;; ** Misc Config **

    ;; Run calls to perly_sense as a prepared shell command. Experimental
    ;; optimization, please try it out.
    (setq ps/use-prepare-shell-command t)

    ;; *** PerlySense End ***



=head2 Emacs Configuration

The most important config you can change is the prefix key.

The default, \C-o, seemed to have a rater low useful-to-keystroke
ratio and so was a strong candidate for stealing for this much more
important purpose :) Now, the I<proper> way of doing this is of course
to some kind of C-c prefix. You decide.

If you want to use flymake to do background syntax and Perl::Critic
checks, set ps/load-flymake to t (this is a very nifty thing,
so yes you want to do this) and configure the colors to your liking.

Note: This also needs to be enabled on a per-project basis (see
below).

Once you have restarted Emacs, you might want to browse around the
customizations by doing

  M-x customize-group perly-sense



=head1 GETTING STARTED WITH EMACS

This is quite a handfull of new features, and you're not likely to be
able to use them efficiently from day one. Remember, Emacs is all
about acquiring finger memory, one feature at a time.

These are the ones I use every day so they may be a good start:

=over 4

=item * Go to Module

=item * Go to base class

=item * Document Class Hierarchy

=back

=over 4

=item * Go to Version Control

=back

=over 4

=item * Find with Ack

=item * Find sub declarations

=back

=over 4

=item * Run tests, Re-run tests

=item * Assist with Test count

=back


=head2 Reading Docs

=head3 Smart docs


=for html <p>[ <a href="http://search.cpan.org/src/JOHANL/Devel-PerlySense-0.0217/doc/smart_docs_method.html">Screenshot</a> ]<p>


C<C-o C-d> is the "Smart docs" command. It brings up POD documentation
for what's at point.

Put the cursor on the C<method> word of a C<$self-E<gt>method> call
and press C<C-o C-d> and wait until a documentation hint for the
method call is displayed briefly in the echo area. PerlySense will
look in base classes if the method can't be found in the current
class.

Put the cursor on the C<method> word of an $object-E<gt>method call
and press C<C-o C-d> to see the docs hint. PerlySense will look
through all your C<use>d modules (and their base classes) for the
method call and try to identify the best match.

Note! The first time each module is parsed this will take a second or
two, and the very first time you run the command with lots of "use"
modules it's bound to take a lot longer than that.

Put the cursor on a module name and press C<C-o C-d> to bring up a new
buffer with the POD for that module (this is similar to the cperl-mode
feature, only a) not as good, but b) it works on Windows).

Press C<C-o C-d> with nothing under the cursor brings up a POD buffer
for the current file.


=head3 Document Inheritance

C<C-o d i> will briefly display the Inheritance hierarchy for the
current Class in the echo area. Example:

    [ DBIx::Class::Componentised        ]
    [ DBIx::Class                       ] --> [ Class::Data::Accessor ]
    [<CatalystX::FeedMe::DBIC::FeedItem>]


=head3 Document Used Modules

C<C-o d u> will briefly display the list of modules used from the
current buffer in the echo area. Example:

    [ Carp               ] [ File::Spec ] [ Win32::OLE::Const          ]
    [ Class::MethodMaker ] [ File::Temp ] [ Win32::Word::Writer::Table ]
    [ Data::Dumper       ] [ Win32::OLE ]



=head2 Browsing Code

=head3 Smart go to

C<C-o C-g> is the "Smart go to" command. It's similar to Smart Docs,
but instead of bringing the docs to you, it brings you to the
definition of what's at point.

The definition can be either the sub declaration, or if the
declaration can't be found (like for auto-generated getters/setters,
autoloaded subs etc), the POD documentation for the sub.

Before you go anywhere the mark is set. Go back to earlier marks
globally with C-x C-SPC, or locally with C-u C-SPC.


=head3 Go to Module

C<C-o g m> -- Go to Module at point. Useful if "Smart go to" can't
identify exactly what's at point.

Default is the selected text, or the
Module at point.


=head3 Go to Base Class

C<C-o g b> takes you up one level in the inheritance hierarchy. If the
current class has many base classes, you'll have to choose which one
to go to.

If the current method is implemented in that base class, go to the sub
definition.

After going to the Base Class, the Inheritance tree of that class is
displayed in the echo area so you can see where you ended up.


=head3 Go to the 'new' method

C<C-o g n> takes you to the definition of the 'new' method of the
current class (in this class, or a parent class). But if you're
unlucky, it might take you to your OO helper module's default new.


=head3 Go To 'use Module' section

C<C-o g u> takes you to the line below the last 'use Module' statement
in the the current buffer.


=head3 Go to Version Control

C<C-o g v> -- Go to the Project view for the current Version Control
system. This typically displays the change status of the files in the
project. A dired of the Project dir is used in lieu of a VCS.

First, try to go to any existing VC project buffer.

If there is no VC buffer open, find out what VCS is used, and display
the Project view.

Supported VC systems:

=over 4

=item * Subversion -- Quick intro to *svn-status*

_ (underscore) - display only the changed files (toggle)

n, p, m, u -- next, previous, mark, unmark

E -- diff the changes in the current file

c -- commit file(s)

r -- revert file(s)

X v -- resolve conflict (or X X, I'm not sure what the difference is)

etc, etc, etc, do a C-h m to see all the goodies.

See also:

=over 4

=item * L<http://www.credmp.org/index.php/2007/12/08/emacs-hidden-gems-version-control/>,

=item * L<http://www.emacsblog.org/2007/05/17/package-faves-psvn/>


=back


=item * Git -- Magit

This requires you to have Magit installed. Install using ELPA (C<M-x
packages-list-packages>). Docs at L<https://magit.vc/>.

When you switch to an existing Magit status buffer the status is
refreshed automatically to display the current status.

If there are many *magit: NAME* buffers open, the first existing one
will be used (whichever that might be).


=back


=head3 Go to Project's Other Files

C<C-o g p o> -- Navigate to I<other> source files in the project that
correspond to the current file.

This is useful if you have similarly named files in different parts of
the source tree that belong to each other, as is common in projects
with an MVC structure (e.g. those based on L<Catalyst>).

This requires that you have a C<.corresponding_file> config file in
the C<.PerlySenseProject> or project root directory (or your home
directory).

See L<File::Corresponding> for details.



=head2 Finding Code


=head3 Find with Ack


=for html <p>[ <a href="http://search.cpan.org/src/JOHANL/Devel-PerlySense-0.0217/doc/find_with_ack.html">Screenshot</a> ]<p>


C<C-o f a> -- Ack through the source and display the hits in a
B<*grep*> buffer. L<ack> is like grep, but more suitable for
development.

The search takes place from the Project directory. Before running ack
you'll get to edit the command line with a sensible default chosen from:

=over 4

=item * the active region

=item * the word at point (with the C<-w> whole word option)

=back

When editing the ack command you can use the following keys to set options

 |---------+--------+---------------+------------------------------------------|
 | "C-o w" | toggle | -w            | Whole word                               |
 | "C-o q" | toggle | -Q            | Quote metacharacters, pattern is literal |
 | "C-o i" | toggle | -i            | Ignore case                              |
 | "C-o p" | use    | --perl        |                                          |
 | "C-o a" | use    | --all         | Ack version <  2.0                       |
 | "C-o k" | use    | --known-types |                                          |
 | "C-o s" | use    | --sql         |                                          |
 |---------+--------+---------------+------------------------------------------|

To search for all files, toggle the current file type off (typically
--perl, so type C<C-o p> to toggle it off).

For details, refer to the L<ack> documentation (the program was
installed as a dependency of PerlySense).

Remember that earlier searches are available in the command history,
just like with grep.

Tip: You can jump from a source file to the next hit with C<C-c C-c>
(type C<C-h m> in the B<*grep*> buffer to see the mode documentation).

Tip: if you need to find something else while browsing the B<*grep*>
buffer, you can easily rename the current B<*grep*> buffer to
something else using C<M-x rename-buffer>.


=head3 Find sub declarations


=for html <p>[ <a href="http://search.cpan.org/src/JOHANL/Devel-PerlySense-0.0217/doc/find_sub_declaration.html">Screenshot</a> ]<p>


C<C-o f s> -- Ack the Project for I<sub declarations> of the method,
or word at point.

I.e. look for lines with C<sub NAME>.

The point can be either on the method (C<$self-E<gt>st|ore>), or on
the object (C<$us|er_agent-E<gt>get()>).


=head3 Find method calls


=for html <p>[ <a href="http://search.cpan.org/src/JOHANL/Devel-PerlySense-0.0217/doc/find_method_calls.html">Screenshot</a> ]<p>


C<C-o f c> -- Ack the Project for I<method calls> to the method, or
word at point.

I.e. look for lines with C<-E<gt>NAME>.


=head3 Go to Find-buffer

Invoke C<C-o g f> to go to the B<*grep*> buffer.



=head2 Class Overview

Pressing C<C-o C-o> will bring up the Class Overview of the Class name
at point (not yet implemented), or otherwise the current Class (the
active Package).

Example class CatalystX::FeedMe::Controller::Feed

  * Inheritance *
       [ Class::Accessor                     ]
    +> [ Class::Accessor::Fast               ] <-----+
    |  [ Catalyst::AttrContainer             ] ------+---------------------------+
    |    |                                           |                           v
    +- [ Catalyst::Base                      ] --> [ Catalyst::Component ] --> [ Class::Data::Inheritable ]
       [ Catalyst::Controller                ]
       [<CatalystX::FeedMe::Controller::Feed>]

  * Uses *
  [ Data::Dumper      ] [ XML::Atom::Syndication::Content ] [ XML::Atom::Syndication::Feed ]
  [ Template::Filters ] [ XML::Atom::Syndication::Entry   ] [ XML::Atom::Syndication::Link ]

  * NeighbourHood *
  [ CatalystX::FeedMe::DBIC ] [<CatalystX::FeedMe::Controller::Feed    >] -none-
                              [ CatalystX::FeedMe::Controller::FeedItem ]
                              [ CatalystX::FeedMe::Controller::Homepage ]
                              [ CatalystX::FeedMe::Controller::Root     ]

  * Bookmarks *
  - Todo
  Feed.pm:83: remove duplication

  * API *
  \>mutator_name_for
  ->new
  ->path_prefix
  ...


=head3 Overview sections

In addition to the full Overview, each section may be displayed
individually:

=over 4

=item * C-o o i -- Inheritance

=item * C-o o a -- API

=item * C-o o b -- Bookmarks

=item * C-o o u -- Uses

=item * C-o o h -- NeighbourHood

=back


The B<Inheritance> section shows all Base classes of the
Class. Inheriting from something like Catalyst is hopefully the
hairiest you'll see. Classes inherit from their parents upwards in the
diagram unless there is an arrow pointing elsewhere.

The B<Uses> section shows all used modules in the Class.

The B<NeighbourHood> section shows three columns (1: parent dir, 2:
current dir, 3: subdir for the current class) with Classes located
nearby (this can be bizarrely huge (and take a long time) if you
browse your site_lib or similar).

(This was disabled for having a bad time/useful ratio. Use C-o o h to
bring up only the NeighbourHood).

The B<Bookmarks> section shows matches for bookmark definitions you
have defined in the Project config (see below).

the B<API> section shows things that look like methods and properties
of the class (sub declarations, $self method calls,
$self-E<gt>{hash_ref_keys}):

  ->method_in_this_class
  \>method_in_base_class  (note the arrow coming from above)

Private methods (named with a leading _) are displayed as regular
methods. Same goes for private methods in base classes, except when
the base class is outside of your Project (like for CPAN modules).

Why is this?

If it's your code base you're interested in everything, but if you
inherit from a CPAN module, you don't care (you even shouldn't care)
about the implementation of that module.

Note that you can still see the private methods of those modules by
doing a Class Overview on them, or any of the modules outside your
current Project (thereby changing the current Project to the directory
where those modules are installed).


=head3 Key bindings

When in the Class Overview buffer:

g -- Go to the file of the thing at point (Module/Method/Bookmark)

d -- Documentation for the thing at point (Module/Method)

c -- Class Overview for the thing at point. RET does the same.

I -- Move point to the Inheritance heading in the buffer.

U -- Move point to the Uses heading in the buffer.

H -- Move point to the NeighbourHood heading (mnemonic: 'Hood).

B -- Move point to the Bookmarks heading.

A -- Move point to the API heading.

N -- Move point to the '-E<gt>new' method in the buffer (if any).

q -- Quit the Class Overview buffer.



=head2 Testing


=for html <p>[ <a href="http://search.cpan.org/src/JOHANL/Devel-PerlySense-0.0217/doc/testing.html">Screenshot</a> ]<p>


=head3 Run File

C<C-o C-r> -- Run the file of the current buffer using the Compilation
mode.

Files are run according to the source type, which is determined by the
file name (see the config file). The default for .t files is to run
"prove -v", for .pm files "perl -c", etc. This can be configured per
Project (see below).

Files can also be run using an Alternate Command using C<C-u C-o C-r>
if you have specified one in the config file. This might be useful if
you want to re-generate or restart something before running the file,
but only sometimes. Or, maybe you want to run some tests without the
-v flag or something.

The file is run from the Project root directory or from the file
directory depending on the file type, and the @INC is set
appropriately. You can also specify additional @INC directories in the
Project config.

Note that you can configure whatever type of run profile you like,
not just Perl source files.

As a taste of what's possible, imagine that you have a test framework
with .yml acceptance test data files and a corresponding yml-runner.pl
script. You can set up the config so you can type C<C-o C-r> while
editing the .yaml file to run that test. And if you need to regenerate
some fixtures or something before running the yml test, you can
configure the Alternate Command to do that (run with C<C-u C-o
C-r>). Refer to the L<Devel::PerlySense::Cookbook> for details.

If any warnings, errors or test failures are encountered, they are
highlighted in the B<*compilation*> buffer. Press RET on a highlighted
line to go to the source. Jump between errors with Tab.

Use C-c C-c to move from one error to the next while editing.

If you wish to start many runs at the same time, rename the
compilation buffer with C<M-x rename-buffer>.


=head3 Re-run File

Invoke C<C-o C-r> from within the B<*compilation*> buffer to re-run
(C<M-x recompile>) the file. Useful when you have skipped around the
source fixing errors and the .t file isn't visible.

C<C-o r r> -- If not even the B<*compilation*> buffer is visible,
issue Re-Run File from anywhere to bring it up and re-run.

Note: this will re-run whatever is displayed in the B<*compilation*>
buffer.


=head3 Run File under Devel::CoverX::Covered

C<C-o r c> -- This is the same as Run File, but collect test coverage
information using Devel::CoverX::Covered.

Note: Currently this only works with Unix like shells.



=head3 Go to Run-buffer

Invoke C<C-o g r> to go to the B<*compilation*> buffer.


=head3 Edit Test Count

C<C-o e t c> -- Increase the test count number in the line resembling

  use Test::More tests => 43;

without moving point. The current and new test count is reported in
the echo area.

Increase with the numeric argument (e.g. C<C-u -2 C-o e t c>), or
default 1.


=head3 Assist With Test Count

C<C-o a t> -- If the test count in a .t file is out of sync with
what's correctly reported when running the test in the
B<*compilation*> buffer (see Run File), use this command to update the
.t file.

This updates the

  use Test::More tests => 43;

line in the current buffer, so be sure to only run this when the
B<*compilation*> buffer contains the run result of this buffer.


=head3 Run Single Test::Class Method

If you use L<Test::Class> to write your tests, you may sometimes want
to run L<just a single test method|Test::Clas/RUNNING_INDIVIDUAL_TESTS>.

Hit C<C-o r m> to mark the current sub as the current test method, and
C<C-o r m> again to unmark it. This will set the $TEST_METHOD
environment variable during program runs, so when you run this test
class, only the marked method will be run.

The current test method is indicated with a "Test::Class -->" next to
it.


=head3 Go to Tests - Other Files


=for html <p>[ <a href="http://search.cpan.org/src/JOHANL/Devel-PerlySense-0.0217/doc/goto_tests.html">Screenshot</a> ]<p>


C<C-o g t o> -- In a test file, navigate to the source files that are
covered by that test file.

In a source file, navigate to test files covering the file. If the
point is on a line with a sub declaration, the list of test files is
limited to those that cover that particular sub.

This requires that L<Devel::CoverX::Covered> is installed and a
L<Devel::Cover> cover_db in the project root directory.

You can build the coverage database either as a (very slow) separate
test run, or by running individual files with C<C-o r c>.

See L<Devel::CoverX::Covered> for details.


=head3 Go to Error line

If you run tests in a regular shell (inside Emacs or in a terminal
window), this may be handy.

C<C-o g e> -- If point is located on an error line from a syntax
error, or a stack trace from the debugger or similar, go to that
file+line.

If no file name can be found, prompt for a piece of text that contains
the file+line spec. The kill ring or clipboard text is used as default
if available (so it's easy to just copy the error line from the
terminal, run this command and hit return to accept the default text).



=head2 Debugging Code

=head3 Run File in Debugger

C<C-o r d> -- Run the file of the current buffer using the Emacs
integrated Perl debugger. This the same as the excellent C<M-x
perldb>, except a few annoyances are fixed, like the include
directories, the working directory, the default command line etc.

Note that if you have spaces in your file names, this might not work
(it's a perldb thing).

The debugger is started according to the file source type, which is
determined by the file name (see the config file).

You can also use C<C-u C-o r d> to Debug with an Alternate Command,
just like with Run File.

This can all be configured similar to how files are run (see above).

Most files are run from the Project root directory by default.


=head3 Commands and key bindings

Commonly used commands:

    |-------------+------+-------------------------|
    | Source      | DB   | Command                 |
    |-------------+------+-------------------------|
    | C-x C-a C-n | n    | Next line (step over)   |
    | C-x C-a C-s | s    | Step into               |
    |             | RET  | Repeat last n or s      |
    | C-x C-a C-r | r    | Return from sub         |
    | C-x C-a C-u |      | Run to (Until) point    |
    |             | x $v | Dump variable $v        |
    |             | T    | Stack trace             |
    |             | y    | Dump lexicals (mY vars) |
    |             | R    | Restart                 |
    |             | m $o | List methods of $o      |
    |-------------+------+-------------------------|


=head3 Dumping objects

  x $VAR

to print/dump objects.

See L<http://use.perl.org/~jplindstrom/journal/34427> for how to deal
with large objects (put the C<.perldb> file in $HOME or the project
root dir).


=head3 Breakpoints

Create a programmatic breakpoint like this

  $DB::single = 1;


=head3 More Documentation

Once the debugger is started, refer to the Gud menu for a few useful
commands and key bindings (gud = Grand Unified Debugger). See also:
L<http://www.gnu.org/software/emacs/manual/html_node/emacs/Debuggers.html>

Since the Perl debugger command line is available, make sure you read
up on that too: L<http://perldoc.perl.org/perldebug.html> (especially
the E<lt>E<lt>, {{, etc. are more useful than they might seem at
first).



=head2 Displaying Code

=head3 Flymake Introduction


=for html <p>[ <a href="http://search.cpan.org/src/JOHANL/Devel-PerlySense-0.0217/doc/flymake.html">Screenshot</a> ]<p>


"Flymake performs on-the-fly syntax checks of the files being edited
using the external syntax check tool (usually the compiler).
Highlights erroneous lines and displays associated error messages."

Flymake is included in Emacs 22 (or available from
http://flymake.sourceforge.net/, put flymake.el somewhere in your
load-path. [[[explain how to fix brokenness?]]] ).

PerlySense uses flymake to check syntax, Perl Critic, etc.

Having Perl::Critic enabled will also speed up other operations by
caching information.

Three inconveniences with vanilla Flymake are fixed:


=over 4

=item * no proper @INC

=item * only .pl files

=item * "perl -c" warns about redefined subs for
recursively used modules (which is perfectly fine Perl)

=back


Syntax errors and warnings both use the error face.

L<Perl::Critic> violations use the warning face.



=head3 Enabling Flymake

First off, flymake itself needs to be enabled. Refer to the Emacs
Installation description above.

This will enable Flymake for all cperl-mode buffers, causing Emacs to
call perly_sense for each check.

I<PerlySense won't do anything at this point though>. You still need
to configure what should happen during a flymake.

Create a PerlySense Project directory (see below) and look in the
project.yml file for instructions on how to configure Flymake
activities.

Set "syntax" and/or "critic" to 1 to enable them.

B<The primary reason "syntax" is turned off by default is that it's a
potential security hole>; running C<perl -c> on a file will not only
check the syntax; C<BEGIN> and C<CHECK> blocks are also
executed. Doing that on random code may be considered... baaad.

This way you can have Flymake enabled globally and still not run
C<perl -c> on everything that happens to be in a buffer.



=head3 Using Flymake

In the Project config file there are some hints on how to customize
Flymake, when it should run, etc. You can also customize it with C<M-x
customize-group flymake>.

(Personally I find the nagging while I type very distracting, but I
welcome the immediate feedback whenever I save the file. YMMV.)

Look in the mode line for hints on whether there are any errors or
warnings.

C<C-o s n> -- Go to the next Source error/warning.

Display the error in the minibuffer. If the warning is from a
Perl::Critic module, copy the module name into the kill-ring, so you
easily can yank it into the .perlcritic config file to disable
it. (not implemented)

C<C-o s p> -- Go to the previous Source error/warning.

C<C-o s s> -- Display the error/warning text of the current line in a
popup. Or display the error in the minibuffer if the display isn't
graphical, or if the ps/flymake-prefer-errors-in-minibuffer variable
is customized to a true value.



=head3 Code Coverage Visualization Introduction


=for html <p>[ <a href="http://search.cpan.org/src/JOHANL/Devel-PerlySense-0.0217/doc/code_coverage.html">Screenshot</a> ]<p>


If you have a test suite, you might like this. You should have tests.

If you run Devel::Cover, you'll be happy. You should know your code
coverage.

PerlySense can display the code coverage in the source buffer.

Currently supported is subroutine coverage, i.e. whether a sub is
covered by tests or not.

Covered subs are displayed with a discreet green underline, uncovered
subs get a red underline.




=head3 Coverage Visualization Setup

PerlySense uses L<Devel::CoverX::Covered> to manage the coverage
data. Refer to that documentation for how to run your test suite with
L<Devel::Cover> and generate a "covered" database.

The "covered" database should reside in your project root dir and
contain files with file names relative to the project root dir (that's
ordinarily the case).

Note: Running the test suite with Devel::Cover can be very, very
slow. A nightly build is usually a good idea.

You can also collect / undate coverage information for indivual test
files with C<C-o r c>. This is the easiest way to just try it out.

You might want to add the following to be ignored by your VCS
(e.g. .gitignore):

    /cover_db/*
    /covered/*



=head3 Using Coverage Visualization

You can toggle Visualization with C<C-o C-v> at any time when editing.

You can also enable Visualization by default in the install script
(see above), or via C<M-x customize-variable
ps/enable-test-coverage-visualization>.

Whenever Visualization is enabled, PerlySense will try to fetch
coverage information just after a file is opened and highlight the
word "sub" for each subroutine in the buffer.

=over 4

=item * A green underline means that the sub was entered at least
once. This does not mean all lines in the sub was covered.

=item * A red underline means the sub wasn't covered at all. Time to write
more tests!

=item * No underline means that the sub isn't in the coverage
database. Maybe the sub was added after the test run, maybe
Devel::Cover didn't manage to capture any coverage information for the
sub.

If you really think the sub should be covered, generate a HTML report
with L<Devel::Cover> and investigate further.

=back

The point of the visualization is to provide an ambient feeling of
what's covered or not. Too much detail and color all over the place
and the source turns into a christmas tree! But if you browse past a
complex method and see that it isn't tested, that should ring a bell.

To increase this effect you may want to only highlight subs with bad
coverage (customize the variable
C<ps/only-highlight-bad-sub-coverage>)

Note that you can hit C<C-o g t o> -- "Go To Tests - Other Files" to
see what test files are covering I<this file>. If you run the command
with the cursor on a "sub" line, you'll get only the tests that cover
I<that particular subroutine>.



=head2 Editing Code

Editing code includes both smaller editing tasks and refactorings to
restucture the code.


=head3 Edit - Copy Package Name

C<C-o e c p> -- Copy the current package statement name to the
clipboard (kill-ring) and display it in the echo area. If there is no
package statement, try to get the package name from the file name.



=head3 Edit - Copy Package Name From File Name

C<C-o e c P> -- Assuming the file is a Perl module in a lib directory,
copy the corrsponding package name to the clipboard (kill-ring) and
display it in the echo area.

Useful when you've just created an empty new Perl module .pm file.



=head3 Edit - Copy Sub Name

C<C-o e c s> -- Copy the current sub name to the clipboard (kill-ring)
and display it in the echo area.



=head3 Edit - Copy Method Name

C<C-o e c m> -- Copy the current method name to the clipboard
(kill-ring) and display it in the echo area. Method name in this case
means "package->sub".



=head3 Edit - Copy File Name

C<C-o e c f> -- Copy the current file name to the clipboard
(kill-ring) and display it in the echo area.



=head3 Edit - Add 'use Module' Statement

C<C-o e a u> -- Set mark and add a 'use My::Module;' statement to the
end of the 'use Module' section at the top of the file.

The default module is the selected text, or the module at point (point
may be on a method call of the module).

This is typically useful when you realize you're using a module
already, but without a use-statement. But you don't want to leave
where you are just to fiddle with adding it.

So hit C<C-o e a u> to add it, see that it got added at a good place
and hit C-u C-SPC to return to where you were, and continue doing what
you where doing.



=head3 Edit - Move 'use Module' Statement

C<C-o e m u> -- If point is on a line with a single 'use Module'
statement, set mark and move that statement to the end of the 'use
Module' section at the top of the file.

This is typically useful for when you encounter a stray 'use Module'
in the middle of the file.

So type the 'use Module' statement, hit C<C-o e m u> to move it, see
that it got moved to a good place and hit C-u C-SPC to return to where
you were, and continue doing what you where doing.


=head3 Edit/Refactor - Extract Variable

C<C-o e e v> -- Do the refactoring Extract Variable of the active region.

For example, in this piece of code:

    my $syntax = $self->perlysense->config->{external}->{editor}->{emacs}->{flymake}->{syntax};
    my $critic = $self->perlysense->config->{external}->{editor}->{emacs}->{flymake}->{critic};

Select a piece of code (on either of the lines) that is duplicated a
lot and hit C<C-o e e v>. In this case this seems to be the common
part:

    $self->perlysense->config->{external}->{editor}->{emacs}->{flymake}

You will be asked for a variable name to put this in. The default is
the last word in the selected code ($flymake).

All occurrences of the selection will now be replaced with $flymake,
and the new variable $flymake will be declared just before the
earliest usage.

    my $flymake = $self->perlysense->config->{external}->{editor}->{emacs}->{flymake};
    my $syntax = $flymake->{syntax};
    my $critic = $flymake->{critic};

Before the edit, the C<mark> was pushed at the location where you
started, so you can hit C<C-u C-SPC> to jump back.

After the edit, the point is left at the new variable declaration so
you can ensure that it is in a reasonable location. It's not unusual
to need to move it to an outer scope in order for all the usages to be
covered by the declaration.

Now you need to ensure this edit makes sense. Both replacements and
the declaration are highlighted, so it's easy to see what was
changed.

Once you've eye-balled the edits, hit C<C-o e h> to remove the
Highlights.

Note that the replacement is syntax unaware, so you'll have to ensure
it's syntactically correct yourself (althugh most of the time it works
just fine).

In this particular example, had there been no arrows between the hash
keys, the final code would have looked like this:

    my $flymake = $self->perlysense->config->{external}{editor}{emacs}{flymake};
    my $syntax = $flymake{syntax};
    my $critic = $flymake{critic};

and that clearly isn't equivalent Perl code, the flymake hashref
having been converted to a hash. This is probably the most common
failure mode though, and shouldn't happen that often. Now you know.

By default, only the current subroutine is changed. Invoke with the
prefix arg to change the entire buffer: C<C-u C-o e e v>.

Cool usages for Extract Variable:

=over 4

=item * Remove duplicated code (duh), beause duplication is just shoddy.

=item * Rename variable - Extract Varable, then just delete the declaration.

=item * C<print "So, you want to make a $object-E<gt>method_call inside a string\n";>

But that doesn't work obviously. So you mark C<$object-E<gt>method_call>
and extract it, and end up with this:

    my $method_call = $object->method_call;
    print "So, you want to make a $method_call inside a string\n";

Nice!

=back



=head3 Edit -- Find Callers

C<C-o e f c> -- Find callers of a method in the current project, and
insert the package->sub as a call tree in a comment.

This is for understanding where in the code base method calls
originate.

If point is in a comment on something that looks like a method call,
look for that method. This can be in source code, or in a comment with
callers. Insert the comment with callers above the current line.

Otherwise, look for callers to the current sub. Insert the comment
with callers above the sub declaration.

Example: Point is in the sub C<price>:

    package MyApp::Book;

    sub price {
    |

Hit C<C-o e f c> and PerlySense will insert the three places where the
price method is called:

    package MyApp::Book;

    #     MyApp::Book->discount_price
    #     MyApp::User->total_book_cost
    #    |MyApp::Author->daily_total_income
    # MyApp::Book->price
    sub price {

Let's assume the method call chain for total_book_cost is interesting,
so put the cursor on that line and again hit C<C-o e f c>. The callers
for that method is now inserted on the line above.

    package MyApp::Book;

    #     MyApp::Book->discount_price
    #         MyApp::Controller::User->user_details
    #        |MyApp::User->total_cost
    #     MyApp::User->total_book_cost
    #     MyApp::Author->daily_total_income
    # MyApp::Book->price
    sub price {

You can go on like this and add more callers to investigate the code
structure.

The cursor is placed conveniently to make it easy to add subsequent
callers to the call tree.

If the same caller is already present in the comment, it is marked
with a * to indicate that there's no point following them.

Caveat: The method of identifying callers works by method names alone,
so there might be false positives, or uninteresting callers added to
the list. Delete those lines to avoid clutter.



=head3 Edit -- Visualize Callers

C<C-o e v c> -- Visualize callers in a call tree comment (collected
using Find Callers above) by drawing it using GraphViz.

Put the cursor in a comment with the call tree and hit C<C-o e v
c>. PerlySense will create a temporary .dot file and let GraphViz
render it into a nice .png image, which will be opened.

If you're running a graphical Emacs it might even look pretty.

This requires GraphViz' C<dot> binary to be installed:

    sudo apt-get install graphviz  # Debian / Ubuntu
    sudo yum install graphviz      # Redhat / CentOS

on OSX, try brew something.


=head3 Assist With -- Regex


=for html <p>[ <a href="http://search.cpan.org/src/JOHANL/Devel-PerlySense-0.0217/doc/regex_tool.html">Screenshot</a> ]<p>


Hit C<C-o a r> to bring up the Regex Tool which will let you compose a
Perl regular expression interactively with matching text highlighed.

The Regex Tool appears in a new frame with three buffers: B<*Regex*>,
B<*Text*> and B<*Groups*>.

If point is on a regular expression in the source code, that regex
will be used to pre-populate the B<*Regex*> buffer. (Not yet
implemented)

If there is a comment block just above the regex, it will be used to
pre-populate the B<*Text*> buffer. Note that it is very handy to
document the regex with some sample input, so this is a good idea in
general. (Not yet implemented)

The contents of the B<*Regex*> buffer should look e.g. like this:

  / part \s (\w+) \s no:(\d) /xgm

=over 4

=item *

You can use all the usual delimiters, such as / | {} () ", etc.

=item *

You can put Perl comments below the regex to temporarily store chunks
of regex code during prototyping.

=item *

The modifiers work as expected, including /x and /g .

=back

The results in the B<*Groups*> buffer are updated as you type in
either the B<*Regex*> or B<*Text*> buffer.

Use C-c C-c to force an update.

Use C-c C-k to quit all the regex-tool buffers and remove the frame.



=head1 THE PERLYSENSE USER DIRECTORY

PerlySense keeps a per-user directory to store cache files, logs,
etc. The C<.PerlySense> user directory is located under the first
available of these environment variables:

  $APPDATA
  $ALLUSERSPROFILE
  $USERPROFILE
  $HOME
  $TEMP
  $TMP


Run

  perly_sense info

to see which directory is actually being used.



=head1 PROJECTS

PerlySense has the concept of a Project root directory.

Basically, this is where all the source lives, and where your program
can go to find modules that are used. This is from where tests are run
and files are found.

You can specify the Project root dir explicitly for your
applications. But if you don't, PerlySense will try and figure out
what the Project root directory is from the context of the surrounding
code.

This means you can browse source code anywhere on your hard drive
(e.g. @INC) without any special setup or configuration. Most things
will just work, without any hassle.

If you follow the standard directory structure for CPAN modules, the
Project directory is typically the one which contains the Makefile.PL,
the lib, bin, and t directory, etc.



=head2 Identifying a Project root directory

The fastest and most solid way for PerlySense to know which is the
Project directory is to create a C<.PerlySenseProject> directory with
a config file in it. This is highly recommended for all of your own
projects.

The complete project identification strategy is as follows:


=over 4

=item *

First, if there is any directory upwards in the dirctory path with a
C<.PerlySenseProject> dir in it, that is the Project directory.


=item *

Second, PerlySense will try figure out from where the current file (if
any) was being required/used given the contained package names or used
modules.


=item *

Third, if that doesn't work, PerlySense will look for C<lib> and C<t>
directories.

=back

If that doesn't work, PerlySense is lost and you really do need to
create an explicit Project directory by running the following command
in your intended Project root directory (that would typically be the
directory which has a C<lib> directory in it):

  perly_sense create_project

Any existing C<.PerlySenseProject/project.yml> config file will be
renamed.

Note that this all means that the current Project depends on which
file you are looking at. If it's a file within the directory tree
under a C<.PerlySenseProject> directory, that's what the current
Project is. But if you from that file do a Class Overview on an
installed CPAN module, the current Project is deduced from that .pm
file, typically making the current Project be the C<lib> or
C<site_lib> of your local CPAN installation.



=head2 Project Configuration

The Project has a .PerlySenseProject/project.yml config file. Here you
can change the name of the Project, add extra @INC directories, etc.

There is a yaml-mode for Emacs, but I haven't got it to work properly
(unless an infinite loop counts as "properly" these days). The
shell-script-mode is good enough.

The config file documentation is where it belongs, in the config file,
so just take a look at it.



=head2 perly_sense Project commands


  perly_sense create_project [--dir=DIR]

Create a PerlySense project in DIR (default is current dir).



  perly_sense process_project

Cache all modules in the project. (not implemented)



=head1 BOOKMARKS

Bookmarks are regexes that may match against a single line. Each
bookmark definition has a name/moniker under which the matches are
grouped in the Class Overview display.

The primary point of Bookmarks is to highlight unusual things in the
source. The secondary to make it easy for you go navigate to them.

This can be anything you like, but things that come to mind are:

=over 4

=item * TODO comments

=item * FIXME/XXX/HACK comments

=item * Things you don't want left in the code, like

Breakpoints ($DB::single = 1)

Debugging warn/print statements

=back


=head2 Configuration

Bookmarks are defined in the Project Config file (technical details
are documented there).



=head1 KEY BINDING CONVENTIONS

There is a system behind the chosen key bindings in
PerlySense. Knowing the conventions will make it easier to remember
everything.

=head2 Convention: Action based

The first level after the prefix key (C<C-o> by default) is always an
Action, e.g. Run, or Document.

(In the case of C<C-o C-d> for Document you can either think of it as
"Document this for me!"  or "Give me Documentation!".)

With a verb at the first level rather than a noun, the Action can be
context sensitive, "smart", or DWIMy.


=over 4

=item Smart Goto goes to whatever is under the cursor, be it a module
name, a method call, a file name, or an error message.

=item Run runs the file differently depending on what kind of file is
open (tests are "proved", modules are syntax checked, scripts are run,
etc).

=back


=head2 Convention: The Action as a Gateway

The first level indicates the Action to perform, and has the Ctrl
modifier as a "Smart" / DWIMy modifier. This is both so it's easy to
type C<C-o C-r> without releasing the Ctrl key, and to provide a
gateway to more specific actions when typing the key without Ctrl.

E.g. C<C-o C-r> means "Run file", C<C-o r r> means "Run - Re-run".

E.g. C<C-o C-g> means "Smart Goto", C<C-o g b> means "Goto - Base
Class", C-o g s means "Goto - SUPER Method".



=head2 The Main Actions Areas

(some of the main areas have no implementations yet)

=over 4

=item * r -- Run

Run files in various ways.


=item * g -- Go to

Navigate to various locations in the source.


=item * d -- Document

Bring up documentation.


=item * f -- Find

Find/search and display things in the source.


=item * o -- Overview

Bring up an overview of things.


=item * m -- forMat

Reformat source.


=item * e -- Edit & Refactor

Perform smaller convenience editing task, as well as refactorings --
restructuring edits that don't impact functionality/behaviour.

=item * A -- Assist

Solve very context sensitive problems.

=back


=head2 Explore Emacs key bindings

Remember that you can use the usual Emacs feature to display possible
key stroke completions by hitting C-h whenever in the key stroke
sequence.

E.g. Hitting C<C-o g C-h> will list all available key strokes starting
wiht C<C-o g>.



=head2 Changing key bindings

Some key bindings may change over time as I figure out what works and
what doesn't. Some key bindings may be reorganized to make more sense
or to just work better.



=head1 IN CLOSING -- ON PARSING PERL

Since Perl is so dynamic, a perfect static analysis of the source is
impossible. But not unusably so. Well, hopefully. Most of the time.

Because of this PerlySense is not about exact rules, but about
heuristics and a 90% solution that isn't perfect, but good-enough.

PerlySense tries to take advantage of the fact that Perl code is more
than the plain source file. The source lives in a context of POD and a
directory structure and common Perl idioms.

Sometimes when PerlySense can't make a decision, you're expected to
chip in and tell it what you meant.

Sometimes it won't work at all.

Such is the way of dynamic languages.

If it works for you, brilliant, use it to be more productive. If
not...  well, there's always Java >:)



=head2 Syntax Parsing Modules

PerlySense provides a plugin architecture for supporting custom syntax
provided by OO modules such as L<Moose>, or L<Class::Accessor>.

Currently Moose is supported via the
L<Devel::PerlySense::Plugin::Syntax::Moose> module.



=head1 MORE DOCUMENTATION

L<Devel::PerlySense::Cookbook>



=head1 SEE ALSO

L<sepia> - similar effort

L<PPI> - excellent for parsing Perl

L<CPANXR> - also uses PPI for cross referencing the CPAN

L<http://www.DarSerMan.com/Perl/Oasis/> - Win32 class
browser/IDE. Earlier (a lot) work by me.

L<http://www.perl.com/lpt/a/955> - Article "Perl Needs Better Tools"

L<http://media.pragprog.com/articles/mar_02_archeology.pdf> - Article "Software Archeology"

L<http://www.newartisans.com/downloads_files/regex-tool.el> - Regex Tool

L<http://vimdoc.sourceforge.net/htmldoc/eval.html#Dictionaries> - Vim native data structure



=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl buzzwordninja.com> >>

=head1 CONTRIBUTIONS, BUGS, AND CAVEATS

=head2 CONTRIBUTIONS

If you want to hack on PerlySense, fork the project at GitHub:
L<https://github.com/jplindstrom/p5-Devel-PerlySense>


=head2 BUG REPORTS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head2 CAVEATS

Tab/space isn't supported by PPI yet, but it's supposed to be. So
using Tab instead of spaces won't work properly.



=head2 KNOWN BUGS

PPI is kinda slow for large documents. Lots of objects being created etc.

There are certainly edge cases. Bug reports with failing tests
appreciated :)

There is one known infinite loop.



=head1 ACKNOWLEDGEMENTS

Peter Liljenberg and Phil Jackson for their elisp fu.

Jonathan Rockway for cool ideas:
L<http://blog.jrock.us/articles/Increment%20test%20counter.pod>

John Wiegley for the regex-tool L<http://www.newartisans.com/downloads_files/regex-tool.el>

Jaeyoun Chung for dropdown-list L<http://www.emacswiki.org/cgi-bin/wiki/dropdown-list.el>



=head1 COPYRIGHT & LICENSE

Copyright 2007 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense;
$Devel::PerlySense::VERSION = '0.0223';


use Spiffy -Base;
use Carp;
use Data::Dumper;
use File::Basename;
use File::Path;
use File::Find::Rule;
use Path::Class qw/dir file/;
use Path::Tiny;
use Pod::Text;
use IO::String;
use Cache::Cache;
use Storable qw/freeze thaw/;
use List::Util qw/ first /;
use List::MoreUtils qw/ uniq /;

use Devel::TimeThis;

use Devel::PerlySense::Util;
use Devel::PerlySense::Util::Log;
use Devel::PerlySense::Project;
use Devel::PerlySense::Project::Unknown;
use Devel::PerlySense::Config::Project;
use Devel::PerlySense::Home;
use Devel::PerlySense::Class;
use Devel::PerlySense::Document;
use Devel::PerlySense::Document::Location;
use Devel::PerlySense::BookmarkConfig;
use Devel::PerlySense::CallTree;
use Devel::PerlySense::CallTree::Graph;




=head1 *** THE FOLLOWING IS DEVELOPER DOCUMENTATION ***





=head1 PROPERTIES

=head2 oCache

Cache::Cache object, or undef if no cache is active.

Default: undef

=cut
field "oCache" => undef;





=head2 oProject

Devel::PerlySense::Project object.

Default: A Devel::PerlySense::Project::Unknown object.

=cut
field "oProject" => undef;




=head2 oHome

Devel::PerlySense::Home object.

Default: A newly created Home object.

=cut
field "oHome" => Devel::PerlySense::Home->new();





=head2 rhConfig

Hash ref with the current config.

If there is a known Project, it reflects the Project's config,
otherwise it's the default config.

Readonly. Note that the _entire_ data structure is readonly. Each time
you change/add/remove a value from it, a kitten is slain. So, dude,
just don't go there!

=cut
sub rhConfig {
    return $self->oProject->rhConfig;
}





=head2 VERSION

The $VERSION of this module.

=cut
sub VERSION {
    # This variable is created by Dist::Zilla during release
    return $Devel::PerlySense::VERSION || "0.0001DEV";
}





=head2 oBookmarkConfig

Devel::PerlySense::BookmarkConfig object.

=cut
field "oBookmarkConfig" => undef;





=head2 rhFileDocumentCache

Hash ref with (keys: absolute file names; keys: Document objects).

=cut
field "rhFileDocumentCache" => {};





=head1 API METHODS

=head2 new()

Create new PerlySense object.

=cut
sub new() {
    my $self = bless {}, shift;
    $self->oBookmarkConfig(Devel::PerlySense::BookmarkConfig->new( oPerlySense => $self ));
    $self->oProject(Devel::PerlySense::Project::Unknown->new( oPerlySense => $self ));
    return($self);
}





=head2 setFindProject([file => $file], [dir => $dir])

Identify a project given the $file or $dir, and set the oProject
property.

If there is already a project defined, don't change it.

If no project was found, don't change oProject.

Return 1 if there is a valid project, else 0.

Die on errors.

=cut
sub setFindProject {
    if( ! $self->oProject->isa("Devel::PerlySense::Project::Unknown")) {
        return 1;
    }

    my $oProject = Devel::PerlySense::Project->newFromLocation(
        @_,
        oPerlySense => $self,
    ) or return 0;
    $self->oProject($oProject);

    return(1);
}





=head2 oDocumentParseFile($file)

Parse $file into a new PerlySense::Document object.

Return the new object.

If $file was already parsed by this PerlySense object, cache that
instance of the Document and return that instead of parsing it again.

Die on errors (like if the file wasn't found).

=cut
sub oDocumentParseFile {
	my ($file) = @_;

    # Stop recursive lookups
    if( exists $self->rhFileDocumentCache->{$file}) {
        if(! defined $self->rhFileDocumentCache->{$file}) {
            die("Tried to parse ($file) recursively\n");
        }
    }
    $self->rhFileDocumentCache->{$file} = undef;

    my $oDocument = $self->rhFileDocumentCache->{$file} ||= do {
        my $oDocumentNew = Devel::PerlySense::Document->new(oPerlySense => $self);
        $oDocumentNew->parse(file => $file);
        $oDocumentNew;
    };

    return($oDocument);
}





=head2 clearInMemoryDocumentCache()

Clear the rhFileDocumentCache property.

Return 1.

=cut
sub clearInMemoryDocumentCache {
    $self->rhFileDocumentCache( {} );
    return 1;
}





=head2 podFromFile(file => $file)

Return the pod in $file as text, or die on errors.

Die if $file doesn't exist.

=cut
sub podFromFile {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    open(my $fhIn, "<", $file) or die("Could not open file ($file): $!\n");

    my $textPod = "";
    my $fhOut = IO::String->new($textPod);
    Pod::Text->new()->parse_from_filehandle($fhIn, $fhOut);

    return($textPod);
}





=head2 oLocationSmartGoTo(file => $fileOrigin, row => $row, col => $row)

Look in $file at location $row/$col and determine what is
there. Depending on what's there, find the source
declaration/whatever, find it and return an
Devel::PerlySense::Document::Location object.

Currently supported:

  $self->method, look in current file and base classes. If no sub can
  be found, look for POD.

  shift->method for subs that don't have a $self. Same as
  $self->method.

  $object->method, look in current file and used modules. If no sub
  can be found, look for POD.

  Module::Name (bareword)

  Module::Name (as the only contents of a string literal)

If there's nothing at $row/col, or if the source can't be found,
return undef.

Die if $file doesn't exist, or on other errors.

=cut
sub oLocationSmartGoTo {
    my ($file, $row, $col) = Devel::PerlySense::Util::aNamedArg(["file", "row", "col"], @_);
    debug("oLocationSmartGoTo file($file) row($row) col($col)");

    my $oDocument = $self->oDocumentParseFile($file);

    {
        if(my $method = $oDocument->selfMethodCallAt(row => $row, col => $col)) {
            my $oLocation = $oDocument->oLocationSubDefinition(row => $row, name => $method);
            $oLocation and return($oLocation);
        }
    }

    my ($module, $method) = $oDocument->moduleMethodCallAt(row => $row, col => $col);
    if($module && $method) {
        if(my $oDocumentDest = $self->oDocumentFindModule(nameModule => $module, dirOrigin => dirname($file))) {
            my $oLocation = $oDocumentDest->oLocationSubDefinition(row => $row, name => $method);
            $oLocation and return($oLocation);
        }
    }


    my ($oObject, $oMethod, $oLocationSub) = $oDocument->aObjectMethodCallAt(row => $row, col => $col);
    if($oObject && $oMethod && $oLocationSub) {
        debug("Looking for $oObject->$oMethod");
        my @aMethodCall = $oDocument->aMethodCallOf(
            nameObject => "$oObject",
            oLocationWithin => $oLocationSub,
        );
        my @aNameModuleUse = $oDocument->aNameModuleUse();  #Add all known modules, not just the ones explicitly stated
        my @aDocumentDest = $self->aDocumentFindModuleWithInterface(
            raNameModule => \@aNameModuleUse,
            raMethodRequired => [ "$oMethod" ] ,
            raMethodNice => \@aMethodCall,
            dirOrigin => dirname($file),
        );
        if(@aDocumentDest) {
            debug("Possible matching modules:\n" . join("\n", map { "  * $_" } map { @{$_->oMeta->raPackage} } @aDocumentDest));
            my $oLocation = $aDocumentDest[0]->oLocationSubDefinition(
                row => $row,
                name => "$oMethod",
            );
            $oLocation and return($oLocation);
        }
    }


    if(my $module = $oDocument->moduleAt(row => $row, col => $col)) {
        my $file = $self->fileFindModule(nameModule => $module, dirOrigin => dirname($file))
                or return(undef);

        my $oLocation = Devel::PerlySense::Document::Location->new(file => $file, row => 1, col => 1);
        return($oLocation);
    }

    return(undef);
}





=head2 oLocationSmartDoc(file => $fileOrigin, row => $row, col => $row)

Look in $file at location $row/$col and determine what is
there. Depending on what's there, find the documentation for it and
return a Document::Location object with the following rhProperty keys set:

  text - the docs text
  found - "method" | "module"
  docType - "hint" | "document"
  name - the name of the thing found


Currently supported:

  Same as for oLocationSmartGoTo

If there's nothing at $row/col, use the current document.

Die if $file doesn't exist, or on other errors.

=cut
#Rework this so it can deal with HTML output as well
sub oLocationSmartDoc {
    my ($file, $row, $col) = Devel::PerlySense::Util::aNamedArg(["file", "row", "col"], @_);

    my $oDocument = $self->oDocumentParseFile($file);

    #$self->method
    if(my $method = $oDocument->selfMethodCallAt(row => $row, col => $col)) {
        return( $self->oLocationMethodDocFromDocument($oDocument, $method) );
    }

    #Module::Name->method
    my ($module, $method) = $oDocument->moduleMethodCallAt(row => $row, col => $col);
    if($module && $method) {
        if(my $oDocumentDest = $self->oDocumentFindModule(nameModule => $module, dirOrigin => dirname($file))) {
            return( $self->oLocationMethodDocFromDocument($oDocumentDest, $method) );
        }
    }

    #$object->method
    my ($oObject, $oMethod, $oLocationSub) = $oDocument->aObjectMethodCallAt(row => $row, col => $col);
    if($oObject && $oMethod && $oLocationSub) {
        my @aMethodCall = $oDocument->aMethodCallOf(nameObject => "$oObject", oLocationWithin => $oLocationSub);
        my @aNameModuleUse = $oDocument->aNameModuleUse();
        my @aDocumentDest = $self->aDocumentFindModuleWithInterface(raNameModule => \@aNameModuleUse, raMethodRequired => [ "$oMethod" ] , raMethodNice => \@aMethodCall, dirOrigin => dirname($file));
        if(@aDocumentDest) {
            ###TODO: report all possible methods, and let the user chose from them in the editor
            return( $self->oLocationMethodDocFromDocument($aDocumentDest[0], "$oMethod") );
        }
    }

    #Module::Name
    if(my $module = $oDocument->moduleAt(row => $row, col => $col)) {
        my $file = $self->fileFindModule(nameModule => $module, dirOrigin => dirname($file))
                or return(undef);

        my $oLocation = Devel::PerlySense::Document::Location->new(file => $file, row => 1, col => 1);
        $oLocation->rhProperty->{found} = "module";
        $oLocation->rhProperty->{docType} = "document";
        $oLocation->rhProperty->{name} = "$module";
        $oLocation->rhProperty->{text} = $self->podFromFile(file => $file) or return(undef);
        return($oLocation);
    }

    #Fail to docs about this current file
    if($oDocument->isEmptyAt(row => $row, col => $col)) {
        my $oLocation = Devel::PerlySense::Document::Location->new(file => $file, row => 1, col => 1);
        $oLocation->rhProperty->{found} = "module";
        $oLocation->rhProperty->{docType} = "document";
        $oLocation->rhProperty->{name} = $oDocument->packageAt(row => $row);
        $oLocation->rhProperty->{text} = $self->podFromFile(file => $file) or return(undef);
        return($oLocation);
    }

    return(undef);
}





=head2 oLocationMethodDocFromDocument($oDocument, $method)

Look in $oDocument and find the documentation for it and
return a Document::Location object with the following rhProperty keys set:

  text - the docs text
  found - "method" | "module"
  docType - "hint" | "document"
  name - the name of the thing found

If possible, also set "pod" and "podHeading".

Return undef if no doc could be found.

Currently, only POD is regarded as documentation. Todo: fail to
listing an example/abstracted invocation of the method.

Die on errors.

=cut
sub oLocationMethodDocFromDocument {
    my ($oDocument, $method) = @_;
    my $oLocation = $oDocument->oLocationPod(name => $method, lookFor => "method");
    return( $self->oLocationRenderPodToText($oLocation) );
}





=head2 oLocationMethodDefinitionFromDocument(oDocument => $oDocument, nameClass => $nameClass, nameMethod => $method)

Look in $oDocument and find the declaration for $nameMmethod and
return a Document::Location object.

Return undef if no declaration could be found.

Die on errors.

=cut
sub oLocationMethodDefinitionFromDocument {
    my ($oDocument, $nameClass, $nameMethod) = Devel::PerlySense::Util::aNamedArg(["oDocument", "nameClass", "nameMethod"], @_);
    my $oLocation = $oDocument->oLocationSubDefinition(
        package => $nameClass,
        name => $nameMethod,
    );
}





=head2 rhRegexExample(file => $fileOrigin, row => $row, col => $row)

Look in $file at location $row/$col and find the regex located there,
and possibly the example comment preceeding it.

Return hash ref with (keys: regex, example; values: source
string). The source string is an empty string if nothing found.

If there is an example string in a comment, return the example without
the comment #

Die if $file doesn't exist, or on other errors.

=cut
sub rhRegexExample {
    my ($file, $row, $col) = Devel::PerlySense::Util::aNamedArg(["file", "row", "col"], @_);

    my $oDocument = $self->oDocumentParseFile($file);

    return $oDocument->rhRegexExampleAt(row => $row, col => $col);
}





=head2 raFileTestOther(file => $fileSource, [sub => $sub])

Return array ref with file names of files related to $file and
possibly $sub, i.e. the "other" files related to $file.

If $file is a source file, return test files, and vice verca.

$sub is only ever active when $fileSource is a source file.

Die if Devel::CoverX::Covered isn't installed.

=cut
sub raFileTestOther {
    my ($file, $sub) = Devel::PerlySense::Util::aNamedArg(["file", "sub"], @_);
    $self->setFindProject(file => $file) or die("Could not identify any PerlySense Project\n");
    return $self->oProject->raFileTestOther(file => $file, sub => $sub);
}





=head2 raFileProjectOther(file => $fileSource)

Return array ref with file names of files related to $file, i.e. the
files corresponding to $file according to the .corresponding_files
config file..

Die if there is no config file.

=cut
sub raFileProjectOther {
    my ($file, $sub) = Devel::PerlySense::Util::aNamedArg(["file"], @_);
    $self->setFindProject(file => $file) or die("Could not identify any PerlySense Project\n");
    return $self->oProject->raFileProjectOther(file => $file);
}





=head2 rhRunFile(file => $fileSource, [ keyConfigCommand => "command" ])

Figure out what type of source file $fileSource is, and how it should
be run.

The settings in the Project's config->{run_file} is used to determine
the details.

Return hash ref with (keys: "dir_run_from", "command_run",
"type_source_file"), or die on errors (like if no Project could be
found).

dir_run_from is an absolute file name which should be the cwd when
command_run is executed.

type_source_file is something like "Test", "Module".

=cut
sub rhRunFile {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    $self->setFindProject(file => $file)
            or die("Could not identify any PerlySense Project\n");

    return $self->oProject->rhRunFile(@_);
}





=head2 rhDebugFile(file => $fileSource, [ keyConfigCommand => "command" ])

Figure out what type of source file $fileSource is, and how it should
be debugged.

The settings in the Project's config->{debug_file} is used to determine
the details.

Return hash ref with (keys: "dir_debug_from", "command_debug",
"type_source_file"), or die on errors (like if no Project could be
found).

dir_debug_from is an absolute file name which should be the cwd when
command_debug is executed.

type_source_file is something like "Test", "Module".

=cut
sub rhDebugFile {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    $self->setFindProject(file => $file)
            or die("Could not identify any PerlySense Project\n");

    return $self->oProject->rhDebugFile(@_);
}





=head2 flymakeFile(file => $fileSource)

Do a flymake run with $fileSource according to the flymake config and
output the result to STDOUT and STDERR.

=cut
sub flymakeFile {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    $self->setFindProject(file => $file)
            or die("Could not identify any PerlySense Project\n");

    return $self->oProject->flymakeFile(file => $file);
}





=head2 rhSubCovered(file => $fileSource)

Do a "covered subs" call with $fileSource in the current project.

Return hash ref with (keys: sub name; keys: quality).

=cut
sub rhSubCovered {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    $self->setFindProject(file => $file)
            or die("Could not identify any PerlySense Project\n");

    return $self->oProject->rhSubCovered(file => $file);
}





=head2 createProject(dir => $dir)

Create a new PerlySense Project in $dir.

Return 1 on success, or die on errors.

=cut
sub createProject {
    my ($dir) = Devel::PerlySense::Util::aNamedArg(["dir"], @_);

    my $oConfig = Devel::PerlySense::Config::Project->new();
    $oConfig->createFileConfigDefault(dirRoot => $dir);
    $oConfig->createFileCriticDefault(dirRoot => $dir);

    ###TODO: assign the config to $self->oConfigProject

    return(1);
}





=head2 classNameAt(file => $fileOrigin, row => $row, col => $row)

Look in $file at location $row/$col and determine what class name that is.

Return the class name or "" if it's package main.

Die if $file doesn't exist, or on other errors.

=cut
sub classNameAt {
    my ($file, $row, $col) = Devel::PerlySense::Util::aNamedArg(["file", "row", "col"], @_);

    my $oDocument = $self->oDocumentParseFile($file);

    my $package = $oDocument->packageAt(row => $row);

    $package eq "main" and return "";
    return($package);
}





=head2 classAt(file => $fileOrigin, row => $row, col => $row)

Look in $file at location $row/$col and determine what
PerlySelse::Class that is.

Return the Class object or undef if it's package main.

Die if $file doesn't exist, or on other errors.

=cut
sub classAt {
    my ($file, $row, $col) = Devel::PerlySense::Util::aNamedArg(["file", "row", "col"], @_);

    return(Devel::PerlySense::Class->newFromFileAt(
        oPerlySense => $self,
        file => $file,
        row => $row,
        col => $col,
    ));
}





=head2 classByName(name => $name, dirOrigin => $dirOrigin)

Find the file that contains the Class $name, starting at $dirOrigin.

Return the Class object or undef if it couldn't be found.

Die on errors.

=cut
sub classByName {
    my ($name, $dirOrigin) = Devel::PerlySense::Util::aNamedArg(["name", "dirOrigin"], @_);

    my $oDocument = $self->oDocumentFindModule(
        nameModule => $name,
        dirOrigin => $dirOrigin,
    ) or return undef;

    return( Devel::PerlySense::Class->new(
        oPerlySense => $self,
        name => $name,
        raDocument => [ $oDocument ],
    ) );
}





=head2 fileFindModule(nameModule => $nameModule, dirOrigin => $dirOrigin)

Find the file containing the $nameModule given the $dirOrigin.

Return the absolute file name, or undef if none could be found. Die on
errors.

=cut
sub fileFindModule {
    my ($nameModule, $dirOrigin) = Devel::PerlySense::Util::aNamedArg(["nameModule", "dirOrigin"], @_);

    # TODO: Move this into fileFindLookingInInc and pass in the dir
    $self->setFindProject(dir => $dirOrigin);

#my $tt = Devel::TimeThis->new("fileFindModule");
    my $fileModuleBase = $self->fileFromModule($nameModule);
    $dirOrigin = dir($dirOrigin)->absolute;

    return(
        $self->fileFindLookingAround($fileModuleBase, $dirOrigin, $nameModule) ||
        $self->fileFindLookingInInc($fileModuleBase) ||
        undef
    );
}





=head2 oDocumentFindModule(nameModule => $nameModule, dirOrigin => $dirOrigin)

Find the file containing the $nameModule given the $dirOrigin.

Return a parsed PerlySense::Document, or undef if none could be
found. Die on errors.

=cut
sub oDocumentFindModule {
    my ($nameModule, $dirOrigin) = Devel::PerlySense::Util::aNamedArg(["nameModule", "dirOrigin"], @_);

    my $fileModule = $self->fileFindModule(
        nameModule => $nameModule,
        dirOrigin => $dirOrigin,
    ) or return(undef);

    my $oDocument = $self->oDocumentParseFile($fileModule) or return(undef);

    return($oDocument);
}





=head2 isFileInProject(file => $fileSource, fileProjectOf => $fileProjectOf)

Determine whether $fileSource is located within the current Project.

If there is no current Project, figure it out using $fileProjectOf
(that file should be located in the current project).

Return true if $fileSource is in the project, else false. Die on
errors.

=cut
sub isFileInProject {
    my ($file, $fileProjectOf) = Devel::PerlySense::Util::aNamedArg(["file", "fileProjectOf"], @_);

    $self->setFindProject(file => $fileProjectOf)
            or die("Could not identify any PerlySense Project\n");

    return $self->oProject->isFileInProject(file => $file);
}





=head2 raCallSiteForMethod(method => $nameMethod, dirOrigin => $dirOrigin)

Find callers of $nameMethod in $dirOrigin.

Return array ref of call sites.

=cut
sub raCallSiteForMethod {
    my ($nameMethod, $dirOrigin) = Devel::PerlySense::Util::aNamedArg(["nameMethod", "dirOrigin"], @_);

    $self->setFindProject(dir => $dirOrigin);

    my @aMatch;
    my %hSeen;
    for my $file ( $self->oProject->aFileSourceCode ) {
        my $source = slurp($file);

        my $row = 0;
        my $oDocument;
        for my $line (split("\n", $source)) {
            $row++;
            $line =~ m/ -> \s* $nameMethod \b /x or next;
            $line =~ m/ ^ \s* \# /x and next; # No comments
            $oDocument ||= $self->oDocumentParseFile($file) or last;

            my $oLocationSub = $oDocument->oLocationSubAt(
                row => $row,
                col => 1,
            ) or next;

            my $rhPropertySub = $oLocationSub->rhProperty;
            my $namePackage = $rhPropertySub->{namePackage};
            my $nameSub = $rhPropertySub->{nameSub};

            $hSeen{ "$namePackage->$nameSub" }++ and next;

            push(
                @aMatch,
                {
                    file    => $file,
                    package => $namePackage,
                    method  => $nameSub,
                },
            );
        }
    }

    ###JPL: make any file names relative to project

    return \@aMatch;
}





=head2 rhFileCallerVisualized(source => $source)

Extract call tree from $source and render it into a .dot and .png
file.

Return hash ref with (keys: "dot", "image"; values: file names).

Die if there is no "dot" binary to run.

=cut
sub rhFileCallerVisualized {
    my ($source) = Devel::PerlySense::Util::aNamedArg(["source"], @_);

    # TODO: extract
    my $dirTemp = path("~/.PerlySense/temp");
    my $dirTempCallTree = path($dirTemp, "call_tree");

    my $treeCallers = Devel::PerlySense::CallTree->new(source => $source);
    my $graph = Devel::PerlySense::CallTree::Graph->new({
        call_tree  => $treeCallers,
        output_dir => $dirTempCallTree,
    });
    $graph->create_graph();

    return {
        dot   => $graph->dot_file . "",
        image => $graph->output_file . "",
    };
}




=head1 IMPLEMENTATION METHODS

=head2 fileFindLookingAround($fileModuleBase, $dirOrigin, $nameModule?)

Find the file containing the $fileModuleBase given the $dirOrigin. If
$nameModule is specified, the file must either be in the inc_dir, or
contain a package declaration for $nameModule.

Return the file name relative to $dirOrigin, or undef if none could be
found. Die on errors.

=cut
sub fileFindLookingAround {
	my ($fileModuleBase, $dirOrigin, $nameModule) = @_;

    my @aDirIncProject = map { dir($_)->absolute . "" }
        $self->oProject->aDirIncProject(
            dirRelativeTo => $self->oProject->dirProject,
        );

    my $dir = dir($dirOrigin);
    while(1) {
        for my $dirCur (map { dir($dir, $_) } qw/. bin lib/) {
            if(my $fileFound = $self->fileFoundInDir($dirCur, $fileModuleBase)) {
                # is it in a local inc_dir?
                if( first { $_ eq $dir } @aDirIncProject) {
                    return(file($fileFound)->absolute . "");
                }

                # Are we expecting a module name? If not, it's a match.
                $nameModule or return(file($fileFound)->absolute . "");


                # Check for the dir above the file, is there a package
                # name like that in the file? If so, this one isn't
                # it.
                # If I do this, the next one might not even be needed


                # Does the file contain a Package declaration for the
                # module name? This is a manual and cheap workaround
                # to avoid recursive and slow parse
                my $textFile = file($fileFound)->slurp();
                if($textFile =~ m|
                    package          # package declaration
                    \s+
                    [^;]*?           # up until until the next
                                     # statement separator (fragile,
                                     # could well be in comments or a
                                     # block)
                    (?<!::)          # Not preceeded by a module
                                     # separator, i.e. it's not a
                                     # module shadowing the shorter
                                     # name
                    $nameModule
                    \b
                    (?!::)           # Not followed by a module
                                     # separator, i.e. it's not a
                                     # longer, other module
                |xsm) {
                    ###TODO: possibly check using parse here, now that
                    ###we know the package name is in there.
                    return(file($fileFound)->absolute . "");
                }
            }
        }

        $dir = $dir->parent;
        $dir =~ m{^( / | \\ | \w: \\ )$}x and last;  #At the root? Unix/Win32. What filesystems are missing?
    }

    return(undef);
}





=head2 dirFindLookingAround($fileModuleBase, $dirOrigin, [$raDirSub = [".", "lib", "bin"]])

Find the dir containing the $fileModuleBase (relative file path) given
the $dirOrigin. For all directories, also look in subdirectories in
$raDirSub.

Return the absolute dir name, or undef if none could be found. Die on
errors.

=cut
###TODO: remove duplication
sub dirFindLookingAround {
	my ($fileModuleBase, $dirOrigin, $raDirSub) = @_;
    $raDirSub ||= [".", "lib", "bin"];

    my $dir = dir($dirOrigin);
    while(1) {
        for my $dirCur (map { dir($dir, $_) } @$raDirSub) {
            if($self->fileFoundInDir($dirCur, $fileModuleBase)) {
                return($dirCur->absolute . "");
            }
        }

        $dir = $dir->parent;

        #At the root? Unix/Win32. What filesystems are missing?
        $dir =~ m{^( / | \\ | \w: \\ )$}x and last;
    }

    return(undef);
}





=head2 fileFindLookingInInc($fileModuleBase)

Find the file containing the $nameModule in config:project/extra_inc,
and @INC.

Return the absolute file name, or undef if none could be found. Die on
errors.

=cut

sub fileFindLookingInInc {
	my ($fileModuleBase) = @_;

    my @aDirInc = uniq( $self->oProject->aDirIncAbsolute(), @INC );
    for my $dirCur (@aDirInc) {
        if(my $fileFound = $self->fileFoundInDir($dirCur, $fileModuleBase)) {
            return($fileFound);
        }
    }

    return(undef);
}





=head2 fileFromModule($nameModule)

Return the $nameModule converted to a file name (i.e. with dirs and
.pm extension).

=cut
sub fileFromModule {
	my ($nameModule) = @_;
    return( file( split(/::/, $nameModule) ) . ".pm" );
}





=head2 fileFoundInDir($dir, $fileModuleBase)

Check if $fileModuleBase is located in $dir.

Return the absolute file name, or "" if not found at $dir.

=cut
sub fileFoundInDir {
	my ($dir, $fileModuleBase) = @_;

    my $file = file($dir, $fileModuleBase);
    -e $file and return( $file->absolute . "" );

    return("");
}





=head2 textFromPod($pod)

Return $pod rendered as text, or die on errors.

=cut
sub textFromPod {
	my ($pod) = @_;

    my $text = "";
    my $fhIn = IO::String->new($pod);
    my $fhOut = IO::String->new($text);
    Pod::Text->new()->parse_from_filehandle($fhIn, $fhOut);

    $text =~ s/\s+$//s;

    return($text);
}





=head2 oLocationRenderPodToText($oLocation)

Render the $oLocation->rhProperty->{pod} and put it in
rhProperty->{text}.

Return the same (modified) $oLocation object, or undef if no
rhProperty->{pod} property ended up as text (after this operation,
there is content in rhProperty->{text}).

Return undef if $oLocation is undef.

Die on errors.

=cut
sub oLocationRenderPodToText {
	my ($oLocation) = @_;
    $oLocation or return(undef);

    my $pod = $oLocation->rhProperty->{pod} or return(undef);
    $oLocation->rhProperty->{text} = $self->textFromPod($pod) or return(undef);

    return($oLocation);
}





=head2 aDocumentFindModuleWithInterface(raNameModule => $raNameModule, raMethodRequired => $raMethodRequired, raMethodNice => $raMethodNice, dirOrigin => $dirOrigin)

Return a list with Devel::PerlySense::Document objects that support
all of the methods in $raMethodRequired and possibly the methods in
$raMethodNice. Look in modules in $raNameModule.

The list is sorted with the best match first.

If the document APIs have one or more base classes, look in the @ISA
(depth-first, just like Perl (see perldoc perltoot)).

Warn on some failures to find the location. Die on errors.

=cut
sub aDocumentFindModuleWithInterface {
    my ($raNameModule, $raMethodRequired, $raMethodNice, $dirOrigin) = Devel::PerlySense::Util::aNamedArg(["raNameModule", "raMethodRequired", "raMethodNice", "dirOrigin"], @_);
#my $tt = Devel::TimeThis->new("aDocumentFindModuleWithInterface");

    my @aDocument;
    for my $nameModule (@$raNameModule) {
#print "module: $nameModule\n";
        my $oDocument = $self->oDocumentFindModule(
            nameModule => $nameModule,
            dirOrigin => $dirOrigin,
        ) or next;
        $oDocument->determineLikelyApi(nameModule => $nameModule) or next;
        my $score = $oDocument->scoreInterfaceMatch(nameModule => $nameModule, raMethodRequired => $raMethodRequired, raMethodNice => $raMethodNice) or next;

        push(@aDocument, { oDocument => $oDocument, score => $score });
    }

    my @aDocumentWithInterface =
            map { $_->{oDocument} }
            sort { $a->{score} <=> $b->{score} }
            @aDocument;

    return(@aDocumentWithInterface);
}





=head2 aApiOfClass(file => $fileOrigin, row => $row, col => $row)

Look in $file at location $row/$col and determine what package is
there.

Return a two item array with (Package name,
Devel::PerlySense::Document::Api object with the likely API of that
class), or () if none was found.

Die if $file doesn't exist, or on other errors.

=cut
sub aApiOfClass {
    my ($file, $row, $col) = Devel::PerlySense::Util::aNamedArg(["file", "row", "col"], @_);

    my $oDocument = $self->oDocumentParseFile($file);
    my $packageName = $oDocument->packageAt(row => $row) or return(undef);

    $oDocument->determineLikelyApi(nameModule => $packageName) or return(undef);

    return($packageName, $oDocument->rhPackageApiLikely->{$packageName});
}





=head2 aDocumentGrepInDir(dir => $dir, rsGrepFile => $rsGrepFile, rsGrepDocument => $rsGrepDocument)

Return a list with Devel::PerlySense::Document objects found under the
$dir, and that return true for the grep sub $rsGrepFile and $rsGrepDocument.

If any found file couldn't be parsed, skip it silently from the list.

=cut
sub aDocumentGrepInDir {
    my ($dir, $rsGrepFile, $rsGrepDocument) = Devel::PerlySense::Util::aNamedArg(["dir", "rsGrepFile", "rsGrepDocument"], @_);

    my @aDocument =
            map {
                my $oDocument = Devel::PerlySense::Document->new(oPerlySense => $self);
                eval { $oDocument->parse(file => $_) };
                $@ ?
                    () :
                    $rsGrepDocument->($oDocument) ?
                        $oDocument :
                        ();
            }
            grep { $rsGrepFile->($_) }
            File::Find::Rule->file->name("*.pm")->in($dir);

    return(@aDocument);
}





=head1 CACHE METHODS


=head2 cacheSet(file => $file, key => $key, value => $valuex)

If the oCache isn't undef, store the $value in the cache under the
total key of ($file, $file's timestamp, $key, and the PerlySense
VERSION).

$value should be a scalar or reference which can be freezed.

$file must be an existing file.

Return 1 if the $value was stored, else 0. Die on errors.

=cut
#Move these to Devel::PerlySense::Util::Cache ?
sub cacheSet {
    my ($file, $key, $value) = Devel::PerlySense::Util::aNamedArg(["file", "key", "value"], @_);

    my $keyTotal = $self->cacheKeyTotal($file, $key) or return(0);

    my $data = freeze($value) or return(0);
    $self->oCache->set($keyTotal, $data);

    return(1);
}





=head2 cacheGet(file => $file, key => $key)

If the oCache isn't undef, get the value in the cache under the total
key of ($file, $file's timestamp, $key) and return it.

$file must be an existing file.

Return the value, or undef if the value could not be fetched. Die on errors.

=cut
sub cacheGet {
    my ($file, $key) = Devel::PerlySense::Util::aNamedArg(["file", "key"], @_);

    my $keyTotal = $self->cacheKeyTotal($file, $key) or
#            warn("Could not get key for ($file) ($key)\n"),
                    return(undef);

    my $data = $self->oCache->get($keyTotal) or
#            warn("?\n"),
                    return(undef);
#warn("!\n");

    my $rValue = thaw($data) or warn("Could not thaw\n"), return(undef);
    return( $rValue );
}





=head2 cacheKeyTotal($file, $key)

If oCache is undef, return undef.

Otherwise, return the total key of ($file, $file's timestamp, $key,
and the PerlySense VERSION).

$file must be an existing file.

Die on errors.

=cut
sub cacheKeyTotal {
    my ($file, $key) = @_;
    $self->oCache or return(undef);

    my $timestamp = (stat($file))[9] or die("Could not read timestamp for file ($file)\n");
    my $keyTotal = join("\t", $file, $timestamp, $key, $self->VERSION);

    return($keyTotal);
}

1;





__END__
