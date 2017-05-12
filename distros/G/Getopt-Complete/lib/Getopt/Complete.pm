package Getopt::Complete;

use strict;
use warnings;

our $VERSION = '0.26';

use Getopt::Complete::Options;
use Getopt::Complete::Args;
use Getopt::Complete::Compgen;

our $ARGS;
our %ARGS;

our $EXIT_ON_ERRORS = 1;
our $LONE_DASH_SUPPORT = 0;

sub import {    
    my $class = shift;
    unless (@_) {
        # re-using this module after options processing, with no arguments,
        # will just re-export (alias, actually) %ARGS and $ARGS.
        if ($ARGS) {
            $class->export_aliases();
        }
        return;
    }

    if ($ARGS) {
        # Turn on fatal warnings, and this will safely be a die().
        warn "Overriding default command-line %ARGS with a second call to Getopt::Complete!";
    }

    # The safe way to use this module is to specify args at compile time.  
    # This allows 'perl -c' to handle shell-completion requests.
    # Direct creation of objects is mostly for testing, and wrapper modules.
    
    # Make a single default Getopt::Complete::Options object,
    
    my $options = Getopt::Complete::Options->new(@_);
    
    # See if we are really just being run to respond to a shell completion request.
    # (in this case, the app will exit inside this call)

    $options->handle_shell_completion();

    # and then a single default Getopt::Complete::Args object.
    
    my $args = Getopt::Complete::Args->new(
        options => $options,
        argv => [@ARGV]
    );
   
    # Then make it and its underlying hash available globally in this namespace
    $args->__install_as_default__();

    # Alias the above into the caller's namespace
    my $caller = caller();
    $class->export_aliases($caller);
    
    # This is overridable externally.
    if ($EXIT_ON_ERRORS) {
        if (my @errors = $ARGS->errors) {
            for my $error ($ARGS->errors) {
                chomp $error;
                warn __PACKAGE__ . ' ERROR: ' . $error . "\n";
            }
            exit 1;
        }
    }
}

sub export_aliases {
    my ($class,$pkg) = @_;
    no strict 'refs';
    $pkg ||= caller();
    my $v;
    $v = ${ $pkg . "::ARGS" };
    unless (defined $v) {
        *{ $pkg . "::ARGS" } = \$ARGS;
    }
    $v = \%{ $pkg . "::ARGS" };
    unless (keys %$v) {
        *{ $pkg . "::ARGS" } = \%ARGS;
    }
}

1;

=pod 

=head1 NAME

Getopt::Complete - programmable shell completion for Perl apps

=head1 VERSION

This document describes Getopt::Complete 0.26.

=head1 SYNOPSIS

In the Perl program "myprogram":

  use Getopt::Complete (
      'frog'        => ['ribbit','urp','ugh'],
      'fraggle'     => sub { return ['rock','roll'] },
      'quiet!'      => undef,
      'name'        => undef,
      'age=n'       => undef,
      'outfile=s@'  => 'files', 
      'outdir'      => 'directories'
      'runthis'     => 'commands',
      'username'    => 'users',
      '<>'          => 'directories', 
  );

  print "the frog says " . $ARGS{frog} . "\n";

In ~/.bashrc or ~/.bash_profile, or directly in bash:

  function _getopt_complete () {
    COMPREPLY=($( COMP_CWORD=$COMP_CWORD perl `which ${COMP_WORDS[0]}` ${COMP_WORDS[@]:0} ));
  }
  complete -F _getopt_complete myprogram

Thereafter in the terminal (after next login, or sourcing the updated .bashrc):

  $ myprogram --f<TAB>
  $ myprogram --fr

  $ myprogram --fr<TAB><TAB>
  frog fraggle

  $ myprogram --fro<TAB>
  $ myprogram --frog 

  $ myprogram --frog <TAB>
  ribbit urp ugh

  $ myprogram --frog r<TAB>
  $ myprogram --frog ribbit

=head1 DESCRIPTION

This module makes it easy to add custom command-line completion to Perl
applications.  It also does additional validation of arguments, when the
program is actually executed, based on completion lists.  

Support is also present for apps which are an entry point for a hierarchy of
sub-commands (in the style of cvs and git).

Getopt::Complete also wraps the standard options processing and exports
it as a %ARGS hash at compile time, making using the arguments hassle-free.

The completion features currently work with the bash shell, which is 
the default on most Linux and Mac systems.  Patches for other shells 
are welcome.  

=head1 OPTIONS PROCESSING

Getopt::Complete processes the command-line options at compile time.

The results are avaialble in the %ARGS hash, which is intended as a companion
to the @ARGV array generated natively by Perl.

  use Getopt::Complete (
    'mydir'     => 'd',
    'myfile'    => 'f',
    '<>'        =  ['monkey', 'taco', 'banana']
  );

  for $opt (keys %ARGS) {
    $val = $ARGS{$opt};
    print "$opt has value $val\n";
  }

Errors in shell argumentes result in messages to STDERR via warn(), and cause the 
program to exit during "use" call.  Getopt::Complete verifies that the option values 
specified match their own completion list, and will otherwise add additional errors
explaining the problem.

The %ARGS hash is an alias for %Getopt::Complete::ARGS.  The alias is not created 
in the caller's namespaces if a hash named %ARGS already exists with data, but
the results are always available from %Getopt::Complete::ARGS.

They keys of the hash are the option names, minus any specifiers like "=s" or "!".
The key is only present if the option was specified on the command-line.

The values of the hash are the values from the command-line.  For multi-value
options the hash value is an arrayref.

=head1 OBJECT API

An object $ARGS is also created in the caller's namespace (class L<Getopt::Complete::Args>)
with a more detailed API for argument interrogation.  See the documentation for that 
module, and also for the underlying L<Getopt::Complete::Options> module.

It is possible to override any part of the default process, including doing custom 
parsing, doing processing at run-time, and and preventing exit when there are errors.

See OVERRIDING COMPILE-TIME OPTION PARSING for more information. 

=head1 PROGRAMMABLE COMPLETION BACKGROUND

The bash shell supports smart completion of words when the <TAB> key is pressed.
By default, after the program name is specified, bash will presume the word the user 
is typing a is a file name, and will attempt to complete the word accordingly.  Where
completion is ambiguous, the shell will go as far as it can and beep.  Subsequent
completion attempts at that position result in a list being shown of possible completions.

Bash can be configured to run a specific program to handle the completion task, allowing
custom completions to be done for different appliations. The "complete" built-in bash 
command instructs the shell as-to how to handle tab-completion for a given command.  

This module allows a program to be its own word-completer.  It detects that the 
COMP_LINE and COMP_POINT environment variables are set, indicating that it is being
used as a completion program, and responds by returning completion values suitable 
for the shell _instead_ of really running the application.

See the manual page for "bash", the heading "Programmable Completion" for full 
details on the general topic.

=head1 HOW TO CONFIGURE PROGRAMMABLE COMPLETION

=over 4

=item 1

Put a "use Getopt::Complete" statement into your app as shown in the synopsis.  
The key-value pairs describe the command-line options available,
and their completions.

This should be at the TOP of the app, before any real processing is done.
The only modules used before it should be those needed for custom callbacks,
if there are any.  No code should print to standard output during compile
time, or it will confuse bash.

Subsequent code can use %ARGS or the $ARGS object to check on command-line
option values.

Existing apps using Getopt::Long should use their option spec in the use declaration 
instead. If they bind variables directly the code should to be updated to get 
values from the %ARGS hash instead.

=item 2

Put the following in your .bashrc or .bash_profile:

  function _getopt_complete () {
    COMPREPLY=($( COMP_CWORD=$COMP_CWORD perl `which ${COMP_WORDS[0]}` ${COMP_WORDS[@]:0} ));
  }
  complete -F _getopt_complete myprogram

=item 3

New logins will automatically run the above and become aware that your
program has programmable completion.  For shells you already
have open, run this to alert bash to your that your program has
custom tab-completion.

  source ~/.bashrc 

=back

Type the name of your app ("myprogram" in the example), and experiment
with using the <TAB> key to get various completions to test it.  Every time
you hit <TAB>, bash sets certain environment variables, and then runs your
program.  The Getopt::Complete module detects these variables, responds to the
completion request, and then forces the program to exit before really running 
your regular application code. 

IMPORTANT: Do not do steps #2 and #3 w/o doing step #1, or your application
will actually run "normally" every time you press <TAB> with it on the command-line!  
The module will not be present to detect that this is not a "real" execution 
of the program, and you may find your program is running when it should not.


=head1 KEYS IN THE OPTIONS SPECIFICATION

Each key in the list decribes an option which can be completed.  Any 
key usable in a Getopt:::Long GetOptions specification works here, 
(except as noted in BUGS below):

=over 4

=item an option name

A normal word is interpreted as an option name. The '=s' specifier is
presumed if no specifier is present.

  'p1' => [...]

=item a complete option specifier

Any specification usable by L<Getopt::Long> is valid as the key.
For example:

  'p1=s' => [...]       # the same as just 'p1'
  'p2=s@' => [...]      # expect multiple values

=item the '<>' symbol for "bare arguments"

This special key specifies how to complete non-option (bare) arguments.
It presumes multiple values are possible (like '=s@'):

Have an explicit list:
 '<>' = ['value1','value2','value3']

Do normal file completion:
 '<>' = 'files'

Take arbitrary values with no expectations:
 '<>' = undef

If there is no '<>' key specified, bare arguments will be treated as an error.

=item a sub-command specifier, starting with '>'

When a key in the options specification starts with '>', it indicates
a that word maps to a distinct sub-command with its own options.  The
array to the right is itself a full options specification, following
the same format as the one above it, including possible further
sub-commands.

See SUB-COMMAND TREES for more details.

=back

=head1 VALUES IN THE OPTIONS SPECIFICATION

Each value describes how the option in question should be completed.

=over 4

=item array reference 

An array reference expliciitly lists the valid values for the option.

  In the app:

    use Getopt::Complete (
        'color'    => ['red','green','blue'],
    );

  In the shell:

    $ myprogram --color <TAB>
    red green blue

    $ myprogram --color blue
    (runs with no errors)

The list of value is also used to validate the user's choice after options
are processed:

    myprogram --color purple
    ERROR: color has invalid value purple: select from red green blue

See below for details on how to permit values which aren't shown in completions to
be used and not generate errors.

=item undef 

An undefined value indicates that the option is not completable.  No completions
will be offered by the application, though any value provided by the user will be
considered valid.

Note that this is distinct from returning an empty arrayref from a callback, which 
implies that there ARE known completions but the user has failed to match any of them.

Also note: this is the only valid completion for boolean parameters, since there is no 
value to specify on the command-line.

  use Getopt::Complete (
    'name'      => undef,   # take --name "anyting" 
    'perky!'    => undef,   # take --perky or --no-perky
  );

=item subroutine callback 

When the list of valid values must be determined dynamically, a subroutine reference or
name can be specified.  If a name is specified, it should be fully qualified.  (If
it is not, it will be presumed to refer to one of the bash builtin completions types.
See BUILTIN COMPLETION TYPES below.)

The subroutine will be called, and is expected to return an arrayref of possiible matches.  
The arrayref will be treated as though it were specified directly in the specification.

As with explicit values, an empty arrayref indicated that there are no valid matches 
for this option, given the other params on the command-line, and the text already typed.
An undef value indicates that any value is valid for this parameter.

Parameters to the callback are described below.

=back

=head1 WRITING SUBROUTINE CALLBACKS

A subroutine callback is useful when the list of options to match must be dynamically generated.

It is also useful when knowing what the user has already typed helps narrow the search for
valid completions, or when iterative completion needs to occur (see PARTIAL COMPLETIONS below). 

The callback is expected to return an arrayref of valid completions.  If it is empty, no
completions are considered valid.  If an undefined value is returned, no completions are 
specified, but ANY arbitrary value entered is considered valid as far as error checking is
concerned.

The callback registerd in the completion specification will receive the following parameters:

=over 4

=item command name

Contains the name of the command for which options are being parsed.  This is $0 in most
cases, though hierarchical commands may have a name "svn commit" or "foo bar baz" etc.

=item current word

This is the word the user is trying to complete.  It may be an empty string, if the user hits <Tab>
without typing anything first.

=item option name 

This is the name of the option for which we are resolving a value.  It is typically ignored unless
you use the same subroutine to service multiple options.

A value of '<>' indicates an unnamed argument (a.k.a "bare argument" or "non-option" argument).

=item other opts 

It is the hashref resulting from Getopt::Long processing of all of the OTHER arguments.
This is useful when one option limits the valid values for another option. 

In some cases, the options which should be available change depending on what other
options are present, or the values available change depending on other options or their
values.

=back

The environment variables COMP_LINE and COMP_POINT have the exact text
of the command-line and also the exact character position, if more detail is 
needed in raw form than the parameters provide.

The return value is a list of possible matches.  The callback is free to narrow its results
by examining the current word, but is not required to do so.  The module will always return
only the appropriate matches.

=head2 EXAMPLE 

This app takes 2 parameters, one of which is dependent on the other:  

  use Getopt::Complete (
    type => ['names','places','things'],
    instance => sub {
            my ($command, $value, $option, $other_opts) = @_;
            if ($other_opts{type} eq 'names') {
                return [qw/larry moe curly/],
            }
            elsif ($other_opts{type} eq 'places') {
                return [qw/here there everywhere/],
            }
            elsif ($other_opts{type} eq 'things') {
                return [ query_database_matching("${value}%") ]
            }
            elsif ($otper_opts{type} eq 'surprsing') {
                # no defined list: take anything typed
                return undef;
            }
            else {
                # invalid type: no matches
                return []
            }
        }
   );

   $ myprogram --type people --instance <TAB>
   larry moe curly

   $ myprogram --type places --instance <TAB>
   here there everywhere

   $ myprogram --type surprising --instance <TAB>
   (no completions appear)   


=head1 BUILTIN COMPLETIONS

Bash has a list of built-in value types which it knows how to complete.  Any of the 
default shell completions supported by bash's "compgen" are supported by this module.

The list of builtin types supported as-of this writing are:

    files
    directories
    commands
    users
    groups
    environment
    services
    aliases
    builtins

To indicate that an argument's valid values are one of the above, use the exact string
after Getopt::Complete:: as the completion callback.  For example:

  use Getopt::Complete (
    infile  => 'Getopt::Complete::files',       
    outdir  => 'Getopt::Complete::directories', 
    myuser  => 'Getopt::Complete::users',
  );

The full name is alissed as the single-character compgen parameter name for convenience.
Further, because Getopt::Complete is the default namespace during processing, it can
be ommitted from callback function names.

The following are all equivalent.  They effectively produce the same list as 'compgen -f':

   file1 => \&Getopt::Complete::files
   file1 => \&Getopt::Complete::f
   file1 => 'Getopt::Complete::files'
   file1 => 'Getopt::Complete::f'
   file1 => 'files'
   file1 => 'f'

See L<Getopt::Complete::Compgen> for specifics on using builtin completions.

See "man bash", in the Programmable Complete secion, and the "compgen" builtin command for more details.

=head1 UNLISTED VALID VALUES

If there are options which should not be part of completion lists, but still count
as valid if passed-into the app, they can be in a final sub-array at the end.  This
list doesn't affect the completion system at all, just prevents errors in the
ERRORS array described above.

    use Getopt::Complete (
        'color'    => ['red','green','blue', ['yellow','orange']],
    );

    myprogram --color <TAB>
    red green blue

    myprogram --color orange
    # no errors

    myprogram --color purple
    # error
    
=head1 PARTIAL COMPLETIONS

=head2 BASICS

Any returned value ending in a <TAB> character ("\t") will be considered
a "partial" completion.  This means that the shell will be instructed
to leave the cursor at the end of that word even if there is no ambiguity
in the rest of the returned list.

Partial completions are only usable from callbacks.  From a hard-coded
array of values, it would be impossible to ever fuly complete the partial
completion.

=head2 BACKGROUND

Sometimes, the entire list of completions is too big to reasonable resolve and
return.  The most obvious example is filename completion at the root of a 
large filesystem.  In these cases, the completion of is handled in pieces, allowing
the user to gradually "drill down" to the complete value directory by directory.  
It is even possible to hit <TAB> to get one completion, then hit it again and get
more completion, in the case of single-sub-directory directories.

The Getopt::Complete module supports iterative drill-down completions from any
parameter configured with a callback.  It is completely valid to complete 
"a" with "aa" "ab" and "ac", but then to complete "ab" with yet more text.

Unless the shell knows, however that your "aa", "ab", and "ac" completions are 
in fact only partial completions, an inconvenient space will be added 
after the word on the terminal line, as the shell happily moves on to helping
the user enter the next argument.

=head2 DETAILS

Because partial completions are indicated in Getopt::Complete by adding a "\t" 
tab character to the end of the returned string, an application can
return a mix of partial and full completions, and it will respect each 
correctly.  

Note: The "\t" is actually stripped-off before going to the shell
and internal hackery is used to force the shell to not put a space 
where it isn't needed.  This is not part of the bash programmable completion
specification, but is used to simulate features typically only available
with bash for builtin completions like files/directories.

=head1 SUB-COMMAND TREES

It is common for a given appliction to actually be an entry point for several different tools.
Popular exmples are the big version control suites (cvs,svn,svk,git), which use
the form:

 cvs SUBCOMMAND [ARGS]

Each sub-command has its own options specification.  Those may in turn have further sub-commands.

Sub-commands are identified by an initial '>' in the options specification key.  The value
is interpreted as a complete, isolated options spec, using the same general syntax.  This
applies recursively.

=head2 EXAMPLE COMMAND TREE SPEC

    use Getopt::Complete (
        '>animal' => [
            '>dog' => [
                '>bark' => [
                    'ferocity'  => ['yip','wail','ruf','grrrr'], 
                    'count'  => ['1','2','one too many'], 
                ],
                '>drool' => [
                    'buckets=n' => undef, 
                    'lick'      => 'users', 
                ],
                'list!' => undef,
            ],
            '>cat' => [
                '>purr' => [],
                '>meow' => [ 
                    'volume=n' => undef,
                    'bass' => ['low','medium','high'],
                ]
            ],
        ],
        '>plant' => [
            '>taters' => [
                '>fry' => [
                    'greasiness'    => ['crispy','drippy'],
                    'width'         => ['fat','thin','frite'],
                ],
                '>bake' => [
                    'hard!'     => undef,
                    'temp=n'    => undef,
                ],
            ],
            '>dasies' => [
                '>pick' => [
                    '<>'            => ['mine','yours','theirs'],
                ],
                '>plant' => [
                    'season'        => ['winter','spring','summer','fall'],
                    'seeds=n'       => undef,
                    'deep!'         => undef,
                ]
            ]
        ]
    );

    my ($word1,$word2,$word3) = $ARGS->parent_sub_commands; 
    # (the above is also in $ARGS{'>'} for non-OO access)

    # your program probably has something smarter to decide where to go 
    # for a given command
    if ($word1 eq 'animal') {
        if ($word2 eq 'dog') {
            if ($word3 eq 'bark') {
                # work with %ARGS for barking dogs...
                # ....
            }
        }
    }
    elsif ($path[0] eq 'plant') {
        ...
    }

The above example specifies two sub-commands "animal" and "plant, each of which has its own two 
sub-commands, dog/cat and taters/dasies.  Each of those, in turn, have two sub-commands,
for a total of 8 complete commands possible, each with different arguments.  Each of the 
8 has thier own options specification.

When the program executes, the %ARGS hash contains option/value pairs for the specific command
chosen.  The the series of sub-command choices in $ARGS{'>'}, separate from the regular bare
arguments in '<>'. (The method name on an $ARGS object for this is "parent_sub_commands", a 
companion to the "bare_args" method.

The method to determine the next available sub-commands is just "sub_commands".)

Note that, since the user can hit <ENTER> at any time, it is possible that the parent_sub_commands
will be a partial drill-down.  It isn't uncommon to have something like this in place:

 if (my @next = $ARGS->sub_commands) {
    print STDERR "Please select a sub-command:\n";
    print STDERR join("\n", @sub_commands),"\n";
    exit 1;
 }

The above checking is not done automatically, since a sub-command may have further sub-commands, but 
still also be used directly, possibly with other option and bare arguments.

=head1 THE LONE DASH

A lone dash is often used to represent using STDIN instead of a file for applications which otherwise take filenames.

This is supported by all options which complete with the "files" builtin, though it does not appear in completion hint displays.

To disable this, set $Getopt::Complete::LONE_DASH = 0.

=head1 OVERRIDING COMPILE-TIME OPTION PARSING 

Getopt::Complete makes a lot of assumptions in order to be easy to use in the
default case.  Here is how to override that behavior if it's not what you want.

=head2 OPTION 1: DOING CUSTOM ERROR HANDLING

To prevent Getopt::Complete from exiting at compile time if there are errors,
the EXIT_ON_ERRORS flag should be set to 0 first, at compile time, before using
the Getopt::Complete module as follows:

 BEGIN { $Getopt:Complete::EXIT_ON_ERRORS = 0; }

This should not affect completions in any way (it will still exit if it realizes
it is talking to bash, to prevent accidentally running your program).

Errors are retained in:
 
 $Getopt::Complete::ARGS->errors;

It is then up to the application to not run with invalid parameters.

=head2 OPTION 2: RE-PROCESS @ARGV

This module restores @ARGV to its original state after processing, so 
independent option processing can be done if necessary.  The full
spec imported by Getopt::Complete is stored as:

 $Getopt::Complete::ARGS->option_specs;

This is an easy option when upgrading old applications.

Combined with disabling the EXIT_ON_ERROS flag  above, set, you can completely ignore, 
or partially ignore, the options processing which happens automatically.

=head2 OPTION 3: CHANGING COMPILE-TIME PROCESSING

You can also adjust how option processing happens inside of Getopt::Complete.
Getopt::Complete wraps Getopt::Long to do the underlying option parsing.  It uses
GetOptions(\%h, @specification) to produce the %ARGS hash.  Customization of
Getopt::Long should occur in a BEGIN block before using Getopt::Complete.  

=head2 OPTION 4: USE THE OBJECTS AND WRITE YOUR OWN LOGIC

The logic in import() is very short, and is simple to modify.  It is best
to do it in a BEGIN {} block so that bash can use 'perl -c myprogram'
to get completions at compile time.

    BEGIN {

        my $options = Getopt::Complete::Options->new(
            'myfile' => 'f',
            'mychoice' => ['small','medium','huge']
        );

        $options->handle_shell_completion();

        my $args = Getopt::Complete::Args->new(
            options => $options,
            argv => [@ARGV]
        );
        
        if (my @errors = $ARGS->errors) {
            for my $error ($ARGS->errors) {
                chomp $error;
                warn __PACKAGE__ . ' ERROR:' . $error . "\n";
            }
            exit 1;
        }
    
        # make the %ARGS available to all of the app
        $args->__install_as_default__;

        # if you also want %ARGS and $ARGS here when you're finished...
        Getopt:Complete->export_aliases(__PACKAGE__);
    };

=head1 EXTENSIVE USAGE EXAMPLE

Cut-and-paste this into a script called "myprogram" in your path, make it executable, 
and then run this in the shell:

  function _getopt_complete () {
    COMPREPLY=($( COMP_CWORD=$COMP_CWORD perl `which ${COMP_WORDS[0]}` ${COMP_WORDS[@]:0} ));
  }
  complete -F _getopt_complete myprogram

Then try it out.
It does one of everything, besides command trees.

    #!/usr/bin/env perl
    use strict;
    use warnings;

    use Getopt::Complete (
        # list the explicit values which are valid for this option
        'frog'    => ['ribbit','urp','ugh'],

        # you can add any valid Getopt::Long specification to the key on the left
        # ...if you put nothing: "=s" is assumed
        'names=s@' => ['eenie','meanie','miney'],

        # support for Bash "compgen" builtins is present with some pre-made callbacks
        'myfile'    => 'Getopt::Complete::Compgen::files',
        'mydir'     => 'Getopt::Complete::Compgen::directories',
        
        # the plain name or first letter of the compgen builtins also work
        'myfile2'   => 'files',
        'myfile3'   => 'f',

        # handle unnamed arguments from the command-line ("non-option" arguments) with a special key:
        '<>'      => ['some','raw','words'],

        # CODE callbacks allow a the completion list to be dynamically resolved 
        'fraggle' => sub { return ['rock','roll','fried fish','fried taters','fries and squid'] },

        # callbacks get extra info to help them, including the part of the
        # word already typed, and the remainder of the options already processed for context
        'type'    => ['people','places'],
        'instance'=> sub {
                            my ($command, $partial_word, $option_name, $other_opts_hashref) = @_;
                            # be lazy and ignore the partial word: bash will compensate
                            if (my $type = $other_opts_hashref->{type}) {
                                if ($type eq 'people') {
                                    return [qw/larry moe curly/]
                                }
                                elsif ($type eq 'places') {
                                    return [qw/here there everywhere/],
                                }
                            }
                            return [];
                        },
        
        # undef means we don't know how to complete the value: any value specified will do
        # this will result in no shell ompletions, but will still expect a value to be entered
        'name=s'  => undef,

        # boolean values never have a completion list, and will yell if you are that foolish
        # this will give you --no-fast for free as well
        'fast!'     => undef,

    );

    use Data::Dumper;
    print "The arguments are: " . Dumper(\%ARGS);

=head1 DEVELOPMENT

Patches are welcome.
 
 http://github.com/sakoht/Getopt--Complete-for-Perl/

 git clone git://github.com/sakoht/Getopt--Complete-for-Perl.git

As are complaints.  Help us find bugs by sending an email to the address below, or using CPAN's bug tracking system:
 
 https://rt.cpan.org/

The latest version of this module is always availabe on CPAN:

 http://search.cpan.org/search?query=Getopt%3A%3AComplete&mode=all

And is readily installable with the CPAN shell on Mac, Linux, and other Unix-like systems:

 sudo cpan Getopt::Complete

=head1 BUGS

Completions with whitespace work, but they do so by escaping whitespace characters instead of quoting.  
Support should be present for completing quoted text.  It should also be the default, since it is
more attractive.

The logic to "shorten" the completion options shown in some cases is still in development. 
This means that filename completion shows full paths as options instead of just the last word in the file path.

Some uses of Getopt::Long will not work currently: multi-name options (though standard shortening works), +, :, %.

Currently this module only supports bash, though other shells could be added easily.

There is logic in development to have the tool possibly auto-update the user's .bashrc / .bash_profile, but this
is incomplete.

=head1 SEE ALSO

=over 4

=item L<Getopt::Complete::Args> 

the object API for the option/value argument set

=item L<Getopt::Complete::Options> 

the object API for the options specification

=item L<Getopt::Complete::Compgen> 

supplies builtin completions like file lists

=item L<Getopt::Long> 

the definitive options parser, wrapped by this module

=item L<bash> 

the manual page for bash has lots of info on how tab-completion works

=back

=head1 COPYRIGHT

Copyright 2010, 2011 Washington University School of Medicine

=head1 AUTHORS

Scott Smith (sakoht at cpan .org)
Nathan Nutter
Andrei Benea

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this
module.

=cut

