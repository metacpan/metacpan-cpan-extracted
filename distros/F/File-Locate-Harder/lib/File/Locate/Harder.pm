package File::Locate::Harder;
use base qw( Class::Base );

=head1 NAME

File::Locate::Harder - when you're determined to use a locate db

=head1 SYNOPSIS

   use File::Locate::Harder;

   my $flh = File::Locate::Harder->new();
   my $results_aref = $flh->locate( $search_term );

   # using a defined db location, plus some locate options
   my $flh = File::Locate::Harder->new( db => $db_file );
   my $results_aref = $flh->locate( $search_pattern,
                                    { case_insensitive => 1,
                                      regexp           => 1,
                                    } );

   # creating your own locate db, (in this example for doing tests)
   use Test::More;
   SKIP:
    {
      my $flh = File::Locate::Harder->new( db => undef );
      $flh->create_database( $path_to_tree_to_index, $db_file );

      if( $flh->check_locate ) {
         my $reason = "Can't get File::Locate::Harder to work";
         skip "Can't run 'locate'", $test_count;
      }
      my $results_aref = $flh->locate( $search_term );
      is_deeply( $results_aref, $expected_aref, "Found expected files");
    }

   # introspection (is it reading db directly, or shelling out to locate?)
   my $report = $flh->how_works;
   print "This is how File::Locate::Harder is doing locates: $report\n";



=head1 DESCRIPTION

File::Locate::Harder provides a generalized "locate" method to access
the file system indexes used by the "locate" command-line utility.
It is intended to be a relatively portable way for perl code to
quickly ascertain what files are present on the current system.

This code is essentially a wrapper around multiple different techniques
of accessing a locate database: it makes an effort to use the fastest
method it can find that works.

The "locate" command is a well-established utility to find files
quickly by using a special index database (typically updated via a
cron-job).  This module is an attempt at providing a perl front-end
to "locate" which should be portable across most unix-like systems.

Behind the scenes, File::Locate::Harder silently tries many ways
of doing the requested "locate" operation.  If it can't establish
contact with the file system's locate database, it will error
out, otherwise you can be reasonably sure that a "locate" will
return a valid result (including an empty set if the search matches
nothing).

If possible, File::Locate::Harder will use the perl/XS module
L<File::Locate> to access the locate db directly, otherwise, it
will attempt to shell out to a command line version of "locate".

If not told explicitly what locate db file to use, this module will
try to find the file system's standard locate db using a number of
reasonable guesses.  If those all fail -- and it's possible for it to
fail simply because file permissions make the db file effectively
invisible -- as a last ditch effort, it will try shelling out to the
command line "locate" without specifying a db for it (because it
usually knows where to look).

Efficiency may be improved in some circumstances if you help
File::Locate::Harder find the locate database, either by explicitly
saying where it is (using the "db" attribute), or by setting the
LOCATE_PATH environment variable.  Also see the L</"introspection_results">
method.

=head2 METHODS

=over

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );
use File::Path     qw(mkpath);
use File::Basename qw(fileparse basename dirname);

# Note: File::Locate is now "require"ed during init instead of "use"ed.

our $VERSION = '0.06';

# for autoload generated accessors
our $AUTOLOAD;
my %ATTRIBUTES = ();

=item new

Creates a new File::Locate::Harder object.

With no arguments, the newly created object (largely) has
attributes that are undefined.  All may be set later using
accessors named according to the "set_*" convention.

Inputs:

An optional hashref, with named fields identical to the names of
the object attributes.  The attributes, in order of likely utility:

=over

=item  Settings for ways to run "locate"

=over

=item case_insensitive

Like the usual command-line "-i".

=item regexp

The search term will be interpeted as a POSIX regexp

=item posix_extended

The search term is a regexp with the standard POSIX extensions.

=back

=item Overall settings (for "locate", "create_database", etc)

=over

=item db

Locate database file, with full path.  Use this to work with a
non-standard location, or set it to "undef" if you don't want this
module to waste time looking for it (e.g. you might be planning to
generate your own db via L</create_database>).

=back

=item For internal use, testing, and so on:

The following items are lists used in the probing process which
determines what works on the current system.  These lists are
defined with hardcoded defaults that will normally remain
untouched, though are sometimes over-ridden for testing
purposes.

=over

=item locate_db_location_candidates

Likely places for a locate db.  See L</define_probe_parameters>.

=item test_search_terms

Common terms in unix file paths. See L</define_probe_parameters>.

=back

The following are status fields where the results of system probing
are stored.  The user not will normally be uninterested in these,
though see L</"introspection_results"> for a hint about performance
improvements in repeated runs.

=over

=item system_db_not_found

Could not find where the standard locate db is.

=item use_shell_locate

Shell out to locate and forget about using File::Locate

=item shell_locate_failed

So don't try probe_db_via_shell_locate again

=item shell_locate_cmd_idx

Integer: controls the choice of syntax of the locate shell cmd

=back

=back

=cut

# Note: "new" is inherited from Class::Base, and
# calls the following "init" routine automatically.

=item init

Method that initializes object attributes and then locks them
down to prevent accidental creation of new ones.

Not of interest to client coders, though inheriting code should have
an init of it's own that calls this one.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  # all object attributes, including arguments that become attributes
  my @attributes =
    (
        'db',  # locate database file, with full path

        # results of system introspection on how 'locate' works here
        'system_db_not_found',
        'use_shell_locate',      # shell out to locate, forget File::Locate
        'shell_locate_failed',   # so don't try probe_db_via_shell_locate again
        'shell_locate_cmd_idx',  # integer, controls syntax of locate shell cmd

        # lists to try in sequence until one works
        'test_search_terms',     # common terms on perl/unix systems
        'locate_db_location_candidates',  # likely places for a locate db

        # options settings for different styles of "locate"
        'case_insensitive',
        'regexp',
        'posix_extended',
     );

  # transform args into attributes, if on the approved list
  foreach my $field (@attributes) {
    $ATTRIBUTES{ $field } = 1;
    $self->{ $field } = $args->{ $field };
  }
  # (all accessors are now fair game to use here)

  $self->define_probe_parameters;
     # that is, the test_search_terms and locate_db_location_candidates

  # Try to load module "File::Locate", if it fails we'll try shell locate
  eval { require File::Locate };
  if ($@) {
    $self->set_use_shell_locate( 1 );
  }

  my $probe_db = 1;
  # check for defined db field, but undef value
  if ( grep{ m/^db$/ } (keys %{ $args } )  ||
       ( not( defined( $args->{db} ) ) ) ) {
    # if found we should *not* probe for a file-system db
    $probe_db = 0;
  }

  # two issues: determining which db to use
  # and how to use it db (i.e. via module or shell)
  my $db;
  if ( $probe_db ) {
    if ( $db = $args->{ db } || $ENV{ LOCATE_PATH } ) {
      $self->set_db( $db );

      # even if we're told which db to use, must still determine how
      # But: we can't probe it if it's not created yet,
      # And: there's no point if we already know we're going via shell
      if ( -e $db  &&
           ( not ( $self->use_shell_locate ) ) ) {

        # will we use db fast way (module) or slow but sure (shell)
        $self->probe_db( $db ); # note: sets use_shell_locate
          # TODO check return for failure?

      }
    } elsif ( $db = $self->determine_system_db( ) ) {
      # using the standard file system locate db
    } elsif ( $self->probe_db_via_shell_locate ) {
             # the db is unknown to us, but locate may still know
      $self->set_use_shell_locate( 1 );
    } else {
      croak "File::Locate::Harder is not working. " .
        "Problem with 'locate' installation?";
    }
  } # end if don't probe db

  lock_keys( %{ $self } );
  return $self;
}

=item locate

Simple interface to performs the actual "locate" operation
in a robust, reliable way.  Uses the locate db file indicated
by the object's "db" attribute (which is set automatically if
not manually overridden).

Input:

A term to search for in the file name or path.

Return:

An array reference of matching files with full paths.

=cut

sub locate {
  my $self           = shift;
  my $search_term    = shift;
  my $locate_options = shift;

  # apply the current locate options but preserve object settings
  my $original_settings = {
        case_insensitive => $self->case_insensitive,
        regexp           => $self->regexp,
        posix_extended   => $self->posix_extended,
     };

  foreach my $field (keys (%{ $locate_options })){
    my $setter = "set_$field";
    $self->$setter( $locate_options->{ $field } );
  }

  # farm out the locate operation to "via_shell" or "via_module"
  my $result = [];
  if ( $self->use_shell_locate ) {
    $result = $self->locate_via_shell(  $search_term );
  } else {
    $result = $self->locate_via_module( $search_term );
  }

  # restore the original object settings of locate options
  foreach my $field (keys (%{ $original_settings })){
    my $setter = "set_$field";
    $self->$setter( $original_settings->{ $field } );
  }

  return $result;
}

=item create_database

Tries to create the locate database file indicated in the object
data, indexing the tree indicated by a path given as an argument.  A
required second argument specifys the db file: the "db" field in the
object is ignored by this method, though if the database is
successfully created, the object's "db" field will be set to the
newly created database.

Inputs:

(1) full path of tree of files to index
(2) full path of db file to create

Return:
false (undef) on failure.

=cut

sub create_database {
  my $self     = shift;
  my $location = shift;
  my $db       = shift;

  mkpath( dirname( $db ));

  my @cmd = ( "slocate -U $location -o $db",
              "updatedb --require-visibility 0 --output=$db --database-root='$location'",
              "updatedb --output=$db --localpaths='$location'",
            );

  my $status = undef;
  TRY_AGAIN:
  foreach my $cmd (@cmd) {
    $self->debug("Trying cmd:\n$cmd\n");
    my $ret;
    $ret = system( "$cmd 2>/dev/null" );
    if ( $ret != 0  ) {
      $self->debug( "Failed locate db create command:\n  $cmd\n" );
      $self->debug( "\$\?: $?\n" ) if $?;
      next TRY_AGAIN;
    } else {
      $status = 1;
      $self->set_db( $db );
      last;
    }
  }
  if ( not( $status ) ) {
    carp "Could not create db: $db to index $location";
  }
  if ( -e $db ) {
    my $mtime = (stat $db)[9];
    my $timestamp = ( localtime($mtime) );
    $self->debug("Looks like database has been created: $db at $timestamp\n");
  }

  return $status;
}

=back

=head2 introspection

=over

=item check_locate

Returns true (1) if this module's 'locate' method is capable of working.

This is very similar to the L</probe_db> method, except that with no
arguments *and* an undefined object's db setting, this will
initiate a L</determine_system_db> run to try to find the standard
system locate db.

Example usage:

  my $flh = File::Locate::Harder->new( { db => undef } );
  $flh->create_database( $tree_location, $db_file );
  if ( $flh->probe_db ) {
    my @files = $flh->locate( "want_this" ); # checks the newly created db,
                                             # just indexing $tree_location
    # ...
  }

  # Then later, if you want to search the whole file system...
  $flh->set_db( undef );
  if ( $flh->check_locate ) {
      my @hits = $flh->locate( "search_for_this" );
      * ...
  }

  # But even more convenient would be:
  if ( $flh->determine_system_db ) {
      my @hits = $flh->locate( "search_for_this" );
      * ...
  }

(Thus I suspect that this is a redundant, useless method.)

Rule of thumb: if you want to search the whole system, you can use check_locate
to verify that L</locate> will (most likely) work, but if you're using your own
custom db (e.g. created via L</create_database>), you might as well just use
</probe_db>.

(Another rule of thumb: if this seems confusing, just ignore the issue
for as long as you can.)

=cut

sub check_locate {
  my $self = shift;

  my $db = shift || $self->db || $self->determine_system_db;
  my $ret = $self->probe_db( $db );
  return $ret;
}

=item how_works

Returns a report on how this module has been doing "locate"
operations (e.g. via the shell or the File::Locate module,
and using which db).

=cut

sub how_works {
  my $self = shift;
  my $db = $self->db | 'unknown';
  my $report = '';
  if ( $self->use_shell_locate ) {
    my $version = $self->shell_locate_version || '';
    $report = "We shell out to locate version: $version\n using the locate db: $db\n";
  } else {
    $report = "Using File::Locate with the locate db: $db\n";
  }
  return $report;
}

=item introspection_results

Returns a hashref of the results of File::Locate::Harder's
probing of the system's "locate" setup, so that it can be
easily used again without re-doing that work.

Example:

  my $settings_href = $flh1->introspection_results;

  # save    $settings_href somehow (e.g. dump to yaml file)
  # restore $settings_href somehow

  my $flh2 = File::Locate::Harder->new( $settings_href );

=cut

sub introspection_results {
  my $self     = shift;
  my $settings =
    {
       db                   => $self->db,
       system_db_not_found  => $self->system_db_not_found,
       use_shell_locate     => $self->use_shell_locate,
       shell_locate_failed  => $self->shell_locate_failed,
       shell_locate_cmd_idx => $self->shell_locate_cmd_idx,
    };
  return $settings;
}

=item shell_locate_version

Tries to determine the version of the shell's "locate" command.

This will work only with the GNU locate and Secure Locate
variants, not the Free BSD.

Returns the version string on success, otherwise 0 for failure.

=cut

sub shell_locate_version {
  my $self = shift;

  my @cmd = ( 'locate --version',  # gnu & slocate
              'locate -V',         # slocate
            );                     # note: freebsd has no version option

  my $ret = 0;
  CMD:
  foreach my $cmd (@cmd) {
    $self->debug("Trying cmd:\n$cmd\n");
    chomp(
          $ret = `$cmd`
         );
    if ($ret) {
      last CMD;
    } else {
      $self->debug( "Failed locate version request of form:\n  $cmd\n" );
      $self->debug( "\$\?: $?\n" ) if $?;
      next CMD;
    }
  }

  if ( not( $ret ) ) {
    carp "Could not get version of locate shell command";
  }
  return $ret;
}

=back

=head2 special purpose methods (usually, though not exclusively, for internal use)

=over

=item locate_via_module

Uses the perl/XS module L<File::Locate> to perform a locate
operation on the given search term, using the db file
indicated by the object's db attribute.

An optional second argument allows passing in a coderef,
an anonymous routine that operates on each match (the match
value is set to $_): this makes it possible to work with
a large result without storing the entire set in memory.

Uses the three object attribute toggles
(L</"case_insensitive">, </"regexp">, </"posix_extended">)
to control the way locate is performed.

=cut

sub locate_via_module {
  my $self        = shift;
  my $search_term = shift;
  my $coderef     = shift;

  my $db = $self->db;

  my @opts =  $self->build_opts_for_locate_via_module;

  if( not( $coderef ) ) {
    my @results = File::Locate::locate( $search_term, @opts, $db );
    return \@results;
  } else {
    my $ret = File::Locate::locate( $search_term, @opts, $db, $coderef );
    return $ret;
  }
}

=item locate_via_shell

Given a search term returns an array reference of matches found
from a "locate" search.

An optional second argument containing the locate command's
"options string" (e.g. "-i", "-r", "-re", etc) may be passed
in (otherwise it is generated from object data).

This method uses object data settings:
L</"db">, L</"shell_locate_cmd_idx">

And indirectly (via L</build_opts_for_locate_via_shell>):
L</"case_insensitive">, L</"regexp">, L</"posix_extended">

=cut

sub locate_via_shell {
  my $self              = shift;
  my $search_term       = shift;
  my $opt_str_override  = shift;

  unless( defined( $self->shell_locate_cmd_idx ) ) {
    $self->probe_db_via_shell_locate; # side effect: determine cmd_idx
  }

  my $cmd_idx = $self->shell_locate_cmd_idx;
  my $db      = $self->db;
  my $opt_str = $opt_str_override || $self->build_opts_for_locate_via_shell;

  my ($locate_cmd, @results);

    $locate_cmd =
      $self->generate_locate_cmd( $cmd_idx, $search_term, $db, $opt_str );
    chomp(
          @results = `$locate_cmd`
         );

  return \@results;
}

=back

=head2 methods largely for internal use

=over

=item determine_system_db

Internally used routine: looks for a useable system-wide locate db.

Returns the path to the db if found, and as a side effect sets the
object attribute "db".

=cut

# Note: for efficiency reasons, this trys to access all
# candidates via module before falling back on via shell. That's
# the reason this routine does not use the probe_db method

sub determine_system_db {
  my $self = shift;
  if ( $self->system_db_not_found ) {
    return;  # might as well bail if we've failed before
  }

  my $candidates = $self->locate_db_location_candidates;
  my @exist = grep { -e $_ } @{ $candidates };

  foreach my $db (@exist) {
    if( $self->probe_db_via_module_locate( $db ) ) {
      $self->set_db( $db );
      return $db;
    }
  }
  foreach my $db (@exist) {
    if( $self->probe_db_via_shell_locate( $db ) ) {
      # $self->set_use_shell_locate(1); ### TODO -- why not do this here
      $self->set_db( $db );
      return $db;
    }
  }
  $self->set_system_db_not_found( 1 );
  return;
}


=item probe_db

For when the locate db file you're interested in is known,
and you want to initialize access for it (and as a side-effect,
find out if it works).

Input: db file name with full path (optional, defaults to object's setting).

Return: for success, the db file name, on failure undef.

Side-effect: set's use_shell_locate if the access via module
didn't work.

=cut

sub probe_db {
  my $self = shift;

  my $db = shift || $self->db;

  # will we use db fast way (module) or slow but sure (shell)
  if ( $self->probe_db_via_module_locate ) {
    # File::Locate module works, so use it
    return $db; # success
  } elsif ( $self->probe_db_via_shell_locate ) {
    $self->set_use_shell_locate( 1 );
    return $db; # success
  } else {
    return;     # failed
  }
}



=item probe_db_via_module_locate

Looks to see if it can find anything in the given db by using
the File::Locate module.

=cut

sub probe_db_via_module_locate {
  my $self = shift;
  my $db   = shift || $self->db;

  # bail immediately if we've already know via_module doesn't work
  if ( $self->use_shell_locate ) {
    return;
  }

  my @test_search_terms =
    @{ $self->test_search_terms  };

  foreach my $search_term (@test_search_terms) {
    my $found_one;
    eval {
      # in scalar context, this 'locate' returns a boolean
      $found_one = File::Locate::locate( $search_term, $db );
    };
    if ($@) { # traps errors reported by the File::Locate module
      $self->debug("File::Locate::locate had a problem with $db:\n$@");
      return;
    }
    if ( $found_one ) {
      return $db;
    } else {
       $self->debug("File::Locate::locate found no $search_term via $db:\n$?");
    }
  }
  return;
}

=item probe_db_via_shell_locate

Tries the series of standard test searches by shelling out to
the command-line form of locate to make sure that it can be used.

Tries to use the locate db file indicated by the objects "db"
attribute, but this can be over-ridden with an optional argument.

Under some circumstances, the db may remain undefined, but this
method will return "1" for success if it appears that command-line
locate works in any case.

As a side-effect, saves the L</"shell_locate_cmd_idx"> that
indicates a form of the locate command that has been observed
to work.

Returns: undef for failure, and for success either the db or 1
(because locate can work even if this code can't figure out what
db file it's using).

=cut

sub probe_db_via_shell_locate {
  my $self = shift;

  if ( $self->shell_locate_failed ) {
    return;  # bail now if we've failed before
  }

  my $default_db;
  if ( $self->system_db_not_found ) {
    $default_db = undef;  # locate may find the system db even if we can't
  } else {
    $default_db = $self->db;
  }
  my $db   = shift || $default_db;
  my $true = $db || 1;

  my $opt_str = $self->build_opts_for_locate_via_shell;

  # Nested loops of trials
  # The outer loop: different syntax variations of the locate cmd
  # The inner loop: a series of terms to try searching for.

  my $test_search_terms_aref = $self->test_search_terms;
  my @test_search_terms;
  @test_search_terms =
    @{ $test_search_terms_aref } if $test_search_terms_aref;

  my $lim = $self->generate_locate_cmd;
  for (my $cmd_idx = 0; $cmd_idx <= $lim; $cmd_idx++) {

    foreach my $search_term (@test_search_terms) {

      my $locate_cmd =
        $self->generate_locate_cmd( $cmd_idx, $search_term, $db, $opt_str );
      chomp(
            my @hits = `$locate_cmd 2>/dev/null`
           );

      if ( scalar( @hits )  > 0 ) {
        $self->set_shell_locate_cmd_idx( $cmd_idx );
        return $true;
      }
    }
  }
  $self->set_shell_locate_failed( 1 );
  return;
}

=item generate_locate_cmd

Given an ordered list of four required parameters, returns a form
of the locate command which can (in theory) be fed to the shell.
In practice these different forms are expected to fail (some
harder than others) on various different platforms, so some
experimentation may be needed to find a form that works (which
is the job of L</probe_db_via_shell_locate>).

Inputs:

  $cmd_idx: integer index (beginning with 0) that chooses the
            form of a command to return.

  $search_term: string (or possibly regexp) to search for.

  $db: full path to the locate db to search.

  $opt_str: options string, defaults to values generated by
            build_opts_for_locate_via_shell

Example usage:

  for ($i=0; $i<=$self->generate_locate_cmd; $i++) {
     my $locate_cmd =
       $self->generate_locate_cmd( $cmd_idx, $search_term, $db, $opt_str );
     my @result = `$locate_cmd 2 > /dev/null `;
     if ( scalar(@result) > 0 ) {
       return $i;
     }
  }

Note: the various forms of locate are discussed below in
L</"locate shell command">

Special case:

with no arguments (specifically, with $cmd_idx undefined) returns
the count of avaliable command forms minus 1 ($#cmd_forms);

=cut

sub generate_locate_cmd {
  my $self        = shift;
  my $cmd_idx     = shift;
  my $search_term = shift || '';  # suppressing warnings about subbing undefs
  my $db          = shift || '';
  my $opt_str     = shift || $self->build_opts_for_locate_via_shell || '';

  $self->debug("cmd_idx: $cmd_idx\n") if defined( $cmd_idx );
  $self->debug("generate_locate_cmd: " .
               "db: $db  search_term: $search_term\n");

  my @shell_locate_cmds;
  if( $db ) {
    @shell_locate_cmds =
      (
       "locate -q -d '$db' $opt_str $search_term",
       "locate -d '$db' $opt_str $search_term",
       "locate -q --database='$db' $opt_str $search_term",
       "locate  --database='$db' $opt_str $search_term",
      );
  } else {
    @shell_locate_cmds =
      (
       "locate -q $opt_str $search_term",
       "locate $opt_str $search_term",
       "locate -q $opt_str $search_term",
       "locate $opt_str $search_term",
      );
  }

  my $limit = $#shell_locate_cmds;
  if ( not( defined( $cmd_idx ) ) ) {
    return $limit;
  }

  if ( $cmd_idx > $limit ) {
    return; # undef
  }

  my $cmd = $shell_locate_cmds[ $cmd_idx ];
  $self->debug("generate_locate_cmd: returned cmd:\n$cmd\n");
  return $cmd;
}

=item build_opts_for_locate_via_shell

Converts the three object attribute toggles
(L</"case_insensitive">, </"regexp">, </"posix_extended">)
into the command-line options string for locate.

The "posix_extended" feature is not supported for locates
via the shell, and if used will issue a warning.

=cut

sub build_opts_for_locate_via_shell {
  my $self     = shift;
  my $opt_str  = '';
  if ( $self->case_insensitive ) {
    $opt_str .= 'i';
  };
  if ( $self->regexp ) {
    $opt_str .= 'r';
  }
  if ( $self->posix_extended ) {
    carp("Can't use posix extended regexps with locate via the shell");
  };
  $opt_str = "-$opt_str" if $opt_str;
  return $opt_str;
}

=item build_opts_for_locate_via_module

Converting three object attribute toggles
(L</"case_insensitive">, </"regexp">, </"posix_extended">)
into the form that the File::Locate::locate
requires: returns an array.

=cut

sub build_opts_for_locate_via_module {
  my $self = shift;
  my $rexopt_str = '';
  my @opts = ();
  if ( $self->case_insensitive ) {
    $rexopt_str .= 'i';
  };
  if ( $self->posix_extended ) {
    $rexopt_str .= 'e';
  };
  if ( $self->regexp || $rexopt_str ) { # any -rexopt (even 'i') implies
                                        # a need for -rex
    @opts = (-rex => 1);
  }
  push @opts, (-rexopt => $rexopt_str) if $rexopt_str;
  return @opts;
}

=back

=head2 initialization utilities

=over

=item define_probe_parameters

An internal method, used during the object init process.

Defines two arrays that are used to control the locate db "probe"
process: the test_search_terms and the
locate_db_location_candidates.

The locate_db_location_candidates are likely places for a
system's locate db.  See L</details> below.

The test_search_terms are common terms in unix file paths,
which we can check to see if what looks like the locate
database really is one.  See L</"checking if a form of locate works">
below.

=cut

sub define_probe_parameters {
  my $self = shift;

  # common strings in file paths on perl/unix systems,
  # in roughly increasing likelihood of size of search result
  my @test_search_terms =
    qw(
        MakeMaker
        SelfStubber
        DynaLoader
        README
        tmp
        bin
        the
        htm
        txt
        home
        e
        /
     );
  $self->set_test_search_terms( \@test_search_terms );

  # some places one might look for the system's
  # locate db, in roughly increasing order of likelihood
  my @candidates =
    qw(
        /var/lib/slocate/slocate.db
        /var/cache/locate/locatedb
        /var/db/locate.database
        /usr/var/locatedb
        /var/lib/locatedb
        /usr/local/var/locatedb
        /var/lib/locate/locatedb
        /var/spool/locate/locatedb

        /var/cache/locate/slocate.db
        /var/db/slocate.db
        /usr/var/slocate.db
        /usr/local/var/slocate.db
        /var/lib/locate/slocate.db
        /var/spool/locate/slocate.db

        /var/lib/slocate/locate.database
        /var/cache/locate/locate.database
        /usr/var/locate.database
        /usr/local/var/locate.database
        /var/lib/locate/locate.database
        /var/spool/locate/locate.database

        /var/lib/slocate/locatedb
        /var/db/locatedb
     );
  $self->set_locate_db_location_candidates( \@candidates );
  return $self;
}

=back

=head2 basic setters and getters

=over

=item db

Getter for object attribute system_db

=item set_db

Setter for object attribute set_db

As a side-effect, unsets the shell_locate_failed flag
(what if the last db file was bad, and this current
setting will work?).

=cut

sub set_db {
  my $self = shift;
  my $db = shift;
  $self->{ db } = $db;
  $self->set_shell_locate_failed( undef );
  return $db;
}

=back

=head2 EXPERIMENTAL

Having some trouble straightening out the above code as-written.
Going to work on some experimental routines here, that might
have a use somewhere.

=over

=item work_via

Try the db various ways, make a recommendation on how to access it.
Return string: 'module' or 'shell'.

Q: how to handle the shell-but-undef-db case?
A1: could be a third how-type 'shell_unknown'
A2: could be some sort of meta-field, a "system_db_indeterminate" flag

=cut

sub work_via {
  my $self = shift;
  my $db   = shift    || $self->db;

  my $how;

  if (     $self->probe_db_via_module_locate( $db ) ) {
    $how = 'module';
  } else {
         if( $self->probe_db_via_shell_locate(  $db ) ) {
           $how = 'shell';
         } else {
           $how = 'shell_unknown_db';
         }
  }
  return $how;
}





=back

=head2 automatic accessor generation

=over

=item AUTOLOAD

=cut

sub AUTOLOAD {
  return if $AUTOLOAD =~ /DESTROY$/;  # skip calls to DESTROY ()

  my ($name) = $AUTOLOAD =~ /([^:]+)$/; # extract method name
  (my $field = $name) =~ s/^set_//;

  # check that this is a valid accessor call
  croak("Unknown method '$AUTOLOAD' called")
    unless defined( $ATTRIBUTES{ $field } );

  { no strict 'refs';

    # create the setter and getter and install them in the symbol table

    if ( $name =~ /^set_/ ) {

      *$name = sub {
        my $self = shift;
        $self->{ $field } = shift;
        return $self->{ $field };
      };

      goto &$name;              # jump to the new method.
    } elsif ( $name =~ /^get_/ ) {
      carp("Apparent attempt at using a getter with unneeded 'get_' prefix.");
    }

    *$name = sub {
      my $self = shift;
      return $self->{ $field };
    };

    goto &$name;                # jump to the new method.
  }
}

1;

=back

=head1 Platforms

It's likely that this package will work on any unix-like system
(including cygwin), though on some there might be a need for
additional installation and setup (e.g. a "findutils" package).

Development was done on two varieties of linux (aka GNU/linux):
Knoppix (32bit) on a Turion and Kubuntu on an Opteron machine.
This covered two major varieties of the "locate" command:
GNU locate and Secure Locate.

A serious attempt was made to support BSD locate on Freebsd,
but the testing has not been completed.

Note: at present the File::Locate module appears to fail silently
on 64bit platforms, so there the command-line shell locate will
always be used.


=head1 MOTIVATION

This module uses L<File::Locate>, which is a a perl XS interface
to read locate (or slocate) dbs without shellling out to the
command-line "locate" program.

File::Locate has one great limitation: it must be told which locate
db to use (by explicit parameter, or by environment variable), it
has no notion of a default location.  Further, as of this writing,
it appears to be limited to 32bit systems.

This module then is a wrapper around File::Locate that tries a
number of common locations for the locate database, and instead
of just giving up, it also tries the command-line locate, which
has it's own ways of knowing where the database can be
(configuration file, compiled-in default, or command-line
parameter).

The intention here is to make this module as portable as
possible...  it might, for example, be useful to use in portable
CPAN modules that need to look for things in the filesystem.

(As a case in point: the job of File::Locate::Harder would be a lot
easier if it could use "locate" to find the locate db...).

=head1 Additional Examples

=head2 forcing locate via File::Locate module or via shell command

  my $flh = File::Locate::Harder->new();
  $result_via_module = $flh->locate_via_module( $term );
  $result_via_shell  = $flh->locate_via_shell(  $term );

=head2 using the coderef feature of the File::Locate module

  my $count = 0;
  $flh->locate_via_module( $term, sub { $count++ } );
  print "There are $count matches of $term\n";


  $flh->locate_via_module( $term,
          sub { $count++ if $_ =~ m{ ^ /home }x } );
  print "There are $count matches of $term located in /home\n";

=head2 speeding up multiple searches if you know you're using shell locate

This reduces the number of calls to build_opts_for_locate_via_shell:

  my @searches = qw( .bashrc .bash_profile .emacs default.el );
  my $flh = File::Locate::Harder->new();
  my $opt_str = $self->build_opts_for_locate_via_shell;
  foreach my $term (@searches) {
    $result_via_shell  = $flh->locate_via_shell( $term, $opt_str );
  }

=head1 SEE ALSO

L<File::Locate>

Manual pages: L<locate>, L<slocate>, and/or L<updatedb>.

=head1 NOTES

=head2 architecture

The general philosophy in use here is to just try things that
are likely to work and then just try something else if they
fail.  This is probably better than attempting to guess which
form of locate to use based on the current platform, because (a)
no one (to my knowledge) has a capabilities database that
specifies which locate is found on which platform (b) different
variants may be installed at the whim of a sysadmin (c) there
may after all be variants of locate I've never encountered.

So checking ^O is of limited utility, and similarly, some of the
existing forms of locate lack introspection features (e.g. you
can't get freebsd's locate to tell you what version it is).

=head2 details

The object creation process "new" and "init" determines how to do
system-wide locates, and saves it's conclusions for use by future
calls of the locate method on this object.

Some of this elaborate initialization process can be
short-circuited if it's told which db file to use, or even just
giving it an "db" option with an undefined value.  That's
convenient for cases where you want to use this module to create
a locate db of your own (there's no point in scoping for a
system-wide db if we're going to use a specialized one).

If the db location is not known, the search process begins
with making guesses about likely locations it might be found.
It goes through this list:

 /var/lib/slocate/slocate.db  -- Secure Locate under Kubuntu
 /var/cache/locate/locatedb   -- GNU locate, under Knoppix
 /var/db/locate.database      -- BSD locate, under FreeBSD
 /usr/var/locatedb            -- mentioned: File::Locate docs and cygwin lists
 /var/lib/locatedb            -- mentioned on insecure.org
 /usr/local/var/locatedb      -- Solaris with findutils installed
 /var/lib/locate/locatedb     -- mentioned on a Debian list in 2000
 /var/spool/locate/locatedb   -- speculative mention on a cygwin list

So that's three names, in 8 locations.  It also tries other
permutations on speculation:

 /var/cache/locate/slocate.db
 /var/db/slocate.db
 /usr/var/slocate.db
 /usr/local/var/slocate.db
 /var/lib/locate/slocate.db
 /var/spool/locate/slocate.db

 /var/lib/slocate/locate.database
 /var/cache/locate/locate.database
 /usr/var/locate.database
 /usr/local/var/locate.database
 /var/lib/locate/locate.database
 /var/spool/locate/locate.database

 /var/lib/slocate/locatedb
 /var/db/locatedb

Each of these possibilites is checked for simple file-existance,
and then checked to see if one works. (See
L</"checking if a form of locate works"> below.)

=head2 locate shell command

If attempts at using L<File::Locate> fails, the system falls back
to shelling out to the locate command (which really should already
know how to find the system-wide db, either from a compiled-in
default or a config file setting).

But the locate shell command has it's own problems.  There are at
least three variants, with some slight differences between GNU
locate, slocate and freebsd locate.

The current architecture of locate_via_shell tries all of them
in a certain order, and remembers the one that worked last time.

Briefly, here are the variations we need to account for:

=over

=item -d or --database

-d is essentially more general, because freebsd has it but does
not have --database.  So, we try "-d" first, but also try "--database"
just in case.

=item -q for quiet

As of this writing, with slocate, if you tell it explicitly
which db to use, that works, but you also get an ignorable error
about how you don't have permissions to mess with the system
wide database.  You can get this warning to go away with the
"-q" option, but neither Gnu locate or freebsd has it, and if
you use it with them it's a fatal error.  So here we try to use "-q"
first, and if that dies, we run without it.

=back

And still other variations exist in requesting version information.
The FreeBSD form does not understand "--version", and in fact
doesn't seem to have any sort of version option.

(Ah, Cross-platform programming is such a joy.)

=head2 checking if a form of locate works

In order to check that a system-wide locate is working, we probe for
files we know (or strongly suspect) will be there on the system.
This module tries a series of guesses of decreasing specificity
(there's no point in getting a huge number of hits if they're not
needed), then bails out on the list if a result is recieved.

The list in use here begins with files in the standard perl library
(which should accompany almost any installation of perl, unless they
were removed for some reason):

  MakeMaker
  SelfStubber
  DynaLoader

It then begins looking for strings that should be relatively common
on most systems:

  README
  tmp
  bin
  the
  htm
  txt
  home

The presumption is that if there are no hits on those searchs on a
system-wide database, something is very wrong, and that particular
form of "locate" just isn't working.

=head2 File::Locate

By using File::Locate with () to supress import, we need to call
'locate' like so:

   File::Locate::locate

which makes it easy for us to define a new 'locate' method of
our own.

The proceedural syntax of File::Locate::locate has it's ugly aspects,
but the documentation is usually clear:

  my @mp3s = File::Locate::locate "mp3", "/usr/var/locatedb";

  # do regex search
  @hits = File::Locate::locate "^/usr", -rex => 1, "/usr/var/locatedb";

  @hits = File::Locate::locate "^/usr", -rexopt => 'ie', "/usr/var/locatedb";
  # i - case insensitive
  # e - POSIX extended regexps (say what?)

Note: it isn't abundantly clear from the documentation if
-rexopt has to be used with -rex, but it appears that this is
the case.  (And there is a syntax diagram that indicates this).

Another oddity, though: there doesn't seem to be a way to do a
case-insensitive search without using regexps.
(Note: none of the tests use the "-rexopt" feature.)

A very cool touch is that you can hand it a coderef, and avoid
building up a big result set:

   File::Locate::locate "*.mp3", sub { print "MP3 found: $_n" };

Note: the order of arguments to File::Locate::locate is supposed
to be irrelevant.

=head2 creating a database

Creating your own private locate database isn't done very often,
but this module tries to support it largely for purposes of writing
portable tests (we can't know what files are installed on a remote system,
so it's difficult to know what a locate operation should have found...
*unless* we generate a small locate database of our own that tracks
a known set of files that we ship with the tests).

Unfortunately there are several different invocation forms for doing this,
depending on the variant of locate you have installed.  As usual,
we try everything we can think of, and only give up if none of them work.

  my @cmd = ( "slocate -U $location -o $db",
              "updatedb --require-visibility 0 --output=$db --database-root='$location'",
              "updatedb --output=$db --localpaths='$location'",
            );

It probably comes as no surprise that "slocate" and "updatedb" have
different forms.  I was, uh, *interested* to see that my updatedb
works differently now (2010) than when I wrote this code in 2007.

The man page for the version of updatedb installed on my Ubuntu "jaunty"
box has a version of "update" db written by: "Miloslav Trmac <mitr@redhat.com>"
where the option I need is called "--database-root", I see that the
old option name I was using, "--localpaths", was used by a version
written by "Glenn Fowler <gsf@research.att.com>".

Also, with the RedHat version-- which looks as though it thinks
of itself as "mlocate"-- the "-require-visibility 0" option is
recommended for the creation of a small, private locate db.

=head2 system status fields

The system status fields (the one's that can be saved or inspected
via L<introspection_results>) no doubt seem redundant:

 db
 system_db_not_found
 use_shell_locate
 shell_locate_failed
 shell_locate_cmd_idx

It's possible that they *are* somewhat redundant: they were
invented on-the-fly during development on an ad hoc basis.

However, despite the way it looks, this set is resistant to being
reduced in size.  Two-valued logic has it's limitations: for our
immediate purpose, there has to be ways to distinguish between "I
don't know what this value is, and you should try to find out"
and "I don't know what this value is, and it isn't worth trying
to find it."  For example, the "db" field alone isn't good
enough, it needs to be supplemented with information about what
we've done to try to determine the "db".

As for "use_shell_locate" and "shell_locate_failed":
"shell_locate_failed" is used largely to skip doing a probe via
shell if it's failed before (possibly it's name should be
expanded to "shell_locate_probe_failed").  Even if the system has
been explicitly told to work via the shell, it's still necessary
to do a probe to find out which form of the shell locate command
will work ("shell_locate_cmd_idx").

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
29 May 2007

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, 2010 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
