# Copyright (C) 1999-2002, 2011 Matevz Tadel.
# Released under Perl License.

# Parses a configuration file defining command line options and
# default values for global variables.
#
# Default values are evaled ... so be careful.
# Legal to return \@ or \% ... but read Getopt::Long for what it means and
# how such cases are treated.

package Getopt::FileConfig;

use strict;

our $VERSION = "1.0001";

use Getopt::Long qw(GetOptionsFromArray);

sub new
{
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $S = {@_};
  bless($S, $class);

  # -defcfg, -cfgbase, -useenv, -verbose, -hash
  # pass defcfg as string or arr-ref ... it *WILL* become aref
  if (defined $S->{-defcfg})
  {
    $S->{-defcfg} = [ $S->{-defcfg} ] unless ref $S->{-defcfg} eq "ARRAY";
  }
  else
  {
    $S->{-defcfg} = [];
  }
  my $cfgbase;
  if (defined $S->{-cfgbase})
  {
    $cfgbase = $S->{-cfgbase};
  }
  else
  {
    $0 =~ m!([^/]+?)(?:\.[^.]*)?$!;
    $cfgbase = $1;
  }
  $S->{ProgName} = $cfgbase;
  push @{$S->{-defcfg}}, "$ENV{PWD}/${cfgbase}.rc",
                         "$ENV{PWD}/.${cfgbase}.rc",
	                 "$ENV{HOME}/cfg/${cfgbase}.rc",
                         "$ENV{HOME}/.${cfgbase}.rc";
  $S->{PostFoos} = [];

  return $S;
}

sub add_post_foo
{
  my ($S, $foo) = @_;
  push @{$S->{PostFoos}}, $foo;
}

sub parse()
{
  # Parses options from an array-ref and populates the appropriate
  # namepsaces or a hash, if it was given with -hash option to ctor.
  # 
  # Args:
  #   $aref  -- array of command-line options; if nothing is passed,
  #             @ARGV is going to be used.

  my $S = shift;
  my $aref = shift;
  $aref = \@ARGV unless defined $aref;

  # First let's find the config file.
  if ($#{$aref} > 0 && $aref->[0] eq "-cfg")
  {
    shift @$aref; $S->{Config} = shift @$aref;
    die "Getopt::FileConfig::parse: config file '$S->{Config}' not readable."
	unless -r $S->{Config};
  }
  else
  {
    for my $c (@{$S->{-defcfg}})
    {
      if (-r $c)
      {
        $S->{Config} = $c;
	last;
      }
    }
    die "Getopt::FileConfig::parse: config file not found."
	unless defined $S->{Config};
  }

  $S->{CmdlOpts} = [];
  $S->{Vars} = [];

  print "Using config $S->{Config} ...\n" if $S->{-verbose};
  print "Using environment overrides of defaults ...\n"
    if $S->{-useenv} and $S->{-verbose};

  open CFG, $S->{Config};
  while (<CFG>)
  {
    next if /^#/ || /^\s/;
    chomp;
    my ($conf, $type, $context, $var, $def) = split(' ',$_,5);
    my ($varref, $symref);
    # Env overrides?
    if($S->{-useenv} && defined $ENV{$var}) {
      $def = $ENV{$var};
    }
    # Set default value
    if ($S->{-hash})
    {
      if ($context eq 'main' or $context eq ".")
      {
	$S->{-hash}{$var} = eval $def;
	$varref = ref ($S->{-hash}{$var}) ?
	  $S->{-hash}{$var} : \$S->{-hash}{$var};
      }
      else
      {
	$S->{-hash}{$context}{$var} = eval $def;
	$varref = ref ($S->{-hash}{$context}{$var}) ?
	  $S->{-hash}{$context}{$var} : \$S->{-hash}{$context}{$var};
      }
      $symref = 0; # not used for hashes
    }
    else
    {
      no strict "refs";

      $context = "main" if $context eq ".";
      $symref = "${context}::$var";
      ${$symref} = eval $def;
      $varref = ref ${$symref} ? ${$symref} : \${$symref};
    }
    # Store some details
    push @{$S->{Vars}}, [$varref, $symref, $context, $var, $def];
    # voodoo for Getopt
    if ($type ne 'x' and $type ne 'exclude')
    {
        $type='' if $type eq 'b' or $type eq 'bool';
        push @{$S->{CmdlOpts}}, "$conf$type", $varref;
    }
  }
  GetOptionsFromArray($aref, @{$S->{CmdlOpts}});
  for my $f (@{$S->{PostFoos}})
  {
    if ($S->{-hash})
    {
      &$f($S->{-hash});
    }
    else
    {
      &$f();
    }
  }
}

sub parse_string()
{
  # Splits string argument into an array, then calls parse with this
  # array.

  my ($S, $str) = @_;
  my @a = split(' ', $str);
  # rejoin what was unjustfully split (' and "). what a pain ... do it stupidly
  # also strips them off after a match is found
  my ($n, $np, $inm) = (0, -1, 0);
  while ($n <= $#a)
  {
    if ($inm and $a[$n]=~m/$inm$/)
    {
      my $subst = join(' ', @a[$np, $n]);
      substr $subst,0,1,''; substr $subst,-1,1,'';
      splice @a, $np, $n-$np+1, $subst;
      $n = $np+1; $np = -1; $inm = 0;
      redo;
    }
    elsif(not $inm and $a[$n]=~m/^([\'\"])/)
    {
      $np = $n; $inm = $1;
    }
    $n++;
  }
  $S->parse(@a);
}


##########################################################################
# Non-OO helper functions.

sub assert_presence_of_keys
{
  # Asserts keys are in hash ... otherwise assign defaults.
  # Args:
  #   hash-ref - to be checked;
  #   defaults in 'key' => 'default-value' format.
  # Default value can be '<required>' -> then the function will die if this
  # key is not existing (it can be undefined).

  my $h = shift;
  die "pook_href: this not a hashref" unless ref $h eq "HASH";
  my $d = {@_};
  for my $k (keys %$d)
  {
    if ($d->{$k} eq '<required>')
    {
      die "required key $k missing from given hash" unless exists $h->{$k};
      next;
    }
    $h->{$k} = $d->{$k} unless exists $h->{$k};
  }
}

1;


################################################################################
#
# DOCUMENTATION
#
################################################################################

=head1 NAME

Getopt::FileConfig - Perl module for parsing configuration files

=head1 SYNOPSIS

  use Getopt::FileConfig;

  # Default processing ... search for cfg file in the following locations:
  #   ./$base.rc ./.$base.rc, ~/cfg/$base.rc and ~/.$base.rc
  # where $base is 'basename $0 .any-suffix'.
  $cfg = new Getopt::FileConfig();

  # Specify default cfg file
  $cfg = new Getopt::FileConfig(-defcfg=>"$ENV{XX_RUN_CONTROL}/globals.rc");

  # To override cfg file defaults from environment
  $cfg = new Getopt::FileConfig(-useenv=>1);

  # To dump values into a hash instead into 'true' vars:
  $config = {};
  $cfg = new Getopt::FileConfig(-hash=>$config);

  # Do the work: set-up vars with defaults, patch with cmdl opts
  $cfg->parse();             # parses @ARGV
  $cfg->parse(\@my_array);   # parses any array


=head1 DESCRIPTION

Getopt::FileConfig is a module for processing of configuration files which
define some variables to be exported into the callers
namespace(s). These variables can be optionally overriden from
environment variables and unconditionally from command line
arguments. C<Getopt::Long> is used for the last part.

NOTE: Defaults are set for all variables first. Only then the command
line options are applied.

The idea is that you don't really want to declare globals inside your
perl scripts and even less to provide them some default values that are
of limited usefulness. Instead you define them in a config file.

The file is line based, each line has the form:

  <command-line-option> <string-for-getopt> <namespace> <varname> <default>

Lines that match C</^#/> or C</^\s*$/> are skipped.
The namespace can be specified as . and it stands for main.

Eg (for my mkmenu script that generates ssh menus for windowmaker):

  # Login name
  name	=s	main	NAME	"matevz"
  group	=s	main	GROUP	"f9base"
  # Terminal to spawn (think `$TERM -e ssh ...`)
  term	=s	main	TERM	"rxvt"

Then you can run it as C<'mkmenu -name root'>.

Read the C<Getopt::Long manual> for explanation of the second
parameter.  For void argument specification (which means bool), use
C<'b'> or C<'bool'>.  To suppress passing of this variable to
C<Getopt::Long> use C<'x'> or C<'exclude'>.


=head1 SYNTAX

=over 4

=item $cfg = new Getopt::FileConfig(<options>)

Will create new Getopt::FileConfig objects. Options can be set on
construction time using the hash syntax C<< -option => value >> or
later by assigning to a data member as in C<< $cfg->{-option = value}
>>. This is the list of options:

=over 4

=item -cfgbase

Changes the prefix used to search for configuration files. By default, the
$cfgbase is extracted from $0:

   $0 =~ m!([^/]+?)(?:\.[^.]*)?$!;
   $cfgbase = $1;

which is good, as you can use symlinks to the same executable to get different
default values. Locations searched by default are:

  $ENV{PWD}/${cfgbase}.rc,
  $ENV{PWD}/.${cfgbase}.rc,
  $ENV{HOME}/cfg/${cfgbase}.rc,
  $ENV{HOME}/.${cfgbase}.rc;

$cfgbase that is used is stored into $cfg->{ProgName}.

=item -defcfg

Specifies the default location of the configuration file. Can be an
array reference to specify several locations to search the file
for. Some are predefined, but the ones given here are considered
first. See L<BUILT-IN CONFIG FILE RULES> for details. The file list is
created on construction time so be careful if you modify the list by
hand.

=item -useenv

If set to non zero values of environment variables will take
precedence over config file defaults. Command line options are still
more potent. See L<ENVIRONMENT OVERRIDES>.

=item -hash

If set to a hash reference the variables will be exported into it. See
L<PARSING INTO A HASHREF>.

=item -verbose

If set to non zero Getopt::FileConfig will dump a moderate amount of info
during C<parse()>.

=back

=item add_post_foo(<sub-ref>)

Adds <sub-ref> to the list of functions that are called after the
setting of the variables and patching from command line. Useful when
you need to create some compound variables. If C<-hash> is set, the
hash reference is passed to these functions as the only argument.

=item parse(<nothing-or-array-ref>)

Does all the job: selects config file to be used, reads it, sets the
default values and the calls GetOptions. After that the post functions
are invoked. If nothing as passes, @ARGV is used.

=item parse_string(<string>)

Splits string into an array and calls C<parse()>, pretending that this
string was the actual command line.

I used this option to recreate certain variables (for job control and
dbase insertion) from list of commands that were submitting jobs into
the queuing system.

=back


=head1 BUILT-IN CONFIG FILE RULES


If you dont specify the default cfg file, Getopt::FileConfig searches for it
in the following locations:

  $base = `basename $0 .pl`; # can be set with -cfgbase=>'foo'
  `pwd`/${base}.rc
  `pwd`/.${base}.rc
  ~/cfg/${base}.rc
  ~/.${base}.rc

If you do specify the C<-defcfg> it is prepended to the above
list. The first found file is used. You can obtain it from
C<< $cfg->{Config} >>. Also, the program name can be obtained from
C<< $cfg->{ProgName} >>.

Will add additional variables enabling a user to fully specify the
format of these locations when typical use-cases are gathered (perhaps
/etc/... ?).

By creating symlinks to a master script you can have several
config files for the same script and get different default behaviour.

If C<$ARGV[0]> of the script using Getopt::FileConfig is C<-cfg>, then
C<$ARGV[1]> is used as a configuration file and no other locations are
scanned.

Getopt::FileConfig::parse() dies if it can't find any of these files. It
should croak.


=head1 DEFAULT VALUES

So far all default values are eval-ed prior to assignment. Which means
you can use C<[]> or C<{}> or C<sub{}> to get array/hash/closure
reference as a default value. Getopt::Long treats such variables
differently ... so read its manual to learn more. But, BEWARE, the
command line option arguments are NOT eval-ed. Bug Johan Vromans for
this option and then I'll do my part. Then would also add the eval
control on per-variable base into the config file.

You can as well instantiate an object ... decide for yourself ... it
doesn't sound like such a great idea to me. C<Getopt::Long> isn't too
keen of the idea either, so make sure to suppress passing an obj ref
to it.

One of the more obscene uses of this feature is to write in the config file:

  remap   =s   main   REMAP   do "$ENV{HOME}/.domain.remaps"

where the file .domain.remaps is, eg:

  {
   "some.domain:other.domain" => {
    "/u/atlas/matevz" => "/home/matevz",
    "/opt/agnes" => "/opt"
   }
   "foo.domain:some.domain" => {
    "/afs/cern.ch/user/m/matevz" => "/u/atlas/matevz"
   }
  }

This will make C<$REMAP> a hash ref to the above struct.

Of course you are not limited to a single statement ... but then use
C<;s> and know your eval. Don't use newlines or you'll confuse the
parser. If you're annoyed by that you/I can fix the parser to grog a
trailing C<\> as a continuation symbol.


=head1 ENVIRONMENT OVERRIDES

If C<< $cfg->{-useenv} >> is true, then the defaults are taken from the
environment. The names of perl and environment variable must be the
same AND the env-var must be set (ie: C<defined $ENV{$VARNAME}> must
be true). The values of env vars are eval-ed, too. So take care.

This means you're asking for trouble if several variables in different
namespaces have the same names. Or maybe not, if you know what you are
doing.

Probably should set some additional flags that would mean do-not-eval
and never-override-from environment. Probably with some prefixes to
the default value or to the type of a command line option (like
C<{xs}=s>).


=head1 MULTIPLE CONFIG FILES

You're free to invoke C<Getopt::FileConfig> several times. As in:

  # db options
  $o = new Getopt::FileConfig(-defcfg=>"$ENV{PRODDIR}/cfg/db.rc", -useenv=>1);
  $o->parse();
  # Tape options
  $to = new Getopt::FileConfig(-defcfg=>"$ENV{PRODDIR}/cfg/tape_${OCEAN}.rc");
  $to->parse();

When invoking the command make sure to use -- between options intended
for different config file parsers.


=head1 PARSING INTO A HASHREF

By setting C<< $cfg->{-hash} = <some-hash-ref> >> you can redirect
parsing into this hash (instead of namespace globals). A non-main
namespace name induces an additional level of hashing.

Example:

Having a config file pcm.rc

  simple	=s	.	SIMPLE		"blak"
  aref		=s	.	AREF		[]
  href		=s	Kazaan	HREF		{}

and perl script pcm.pl

  #!/usr/bin/perl
  use Getopt::FileConfig;
  use Data::Dumper;

  $XX = {};
  my $cfg = new Getopt::FileConfig(-hash=>$XX);
  $cfg->parse();
  print Dumper($XX);

The result of running
C<pcm.pl -aref pepe -aref lojz -href drek=shit -href joska=boob> is:

  $VAR1 = {
            'AREF' => [
                        'pepe',
                        'lojz'
                      ],
            'Kazaan' => {
                          'HREF' => {
                                      'drek' => 'shit',
                                      'joska' => 'boob'
                                    }
                        },
            'SIMPLE' => 'blak'
          };


=head1 AUTHOR

Matevz Tadel <matevz.tadel@ijs.si>
