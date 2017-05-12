use strict;
use warnings;

package Getopt::Easy;
our $VERSION = 0.1;

use Exporter;
our @ISA = qw/Exporter/;
our %O;
our @EXPORT = qw/get_options %O/;

sub get_options {
    my ($optstr, $usage, $helpchars) = @_;

    $helpchars ||= "";
    $optstr =~ s/^\s*//;
    my $err = 0;
    my (%options, %valid);
    my ($l, $word);
    for (split(/\s+/, $optstr)) {
        ($l, $word) = /^(.)-(.*)$/
            or die "$_: syntax error - must be like this: l-length\n";
        #
        # check for the = sign.
        # there are two different uses of it
        #
        if ($word =~ s/=$//) {
            $l .= '=';
        } elsif ($word =~ s/=(.+)//) {
            $l .= '=';
            $valid{$word} = $1;
        }
        $options{$l} = $word;
        $O{$word} = ($l =~ /=/)? "": 0 unless exists $O{$word};
    }
    exit if $err;
    #
    # with %options and %valid and %O and $helpchars initialized properly
    # we are now ready to examine @ARGV
    #
    my ($arg, $let, $val);
    $err = "";
    ARGV: while (@ARGV and $ARGV[0] =~ s/^-//) {
        $arg = shift @ARGV;
        last if $arg eq "-";    # stop processing options
        while ($arg =~ s/^(.)//) {
            $let = $1;
            if (index($helpchars, $let) >= 0) {      # help
                require "Pod/Text.pm";
                Pod::Text->new->parse_from_file($0);
                exit;
            } elsif (exists $options{$let}) {        # boolean
                $O{$options{$let}} = 1;
            } elsif (exists $options{"$let="}) {     # with value
                if ($arg eq "" and not $arg = shift @ARGV) {
                    $err .= "missing argument for -$let\n";
                    next ARGV;
				} elsif ($arg =~ /^-/) {
                    $err .= "value $arg for -$let begins with a dash\n";
                    next ARGV;
                } else {
                    $O{$options{"$let="}} = $arg;
                    $arg = "";
                }
                if (my $v = $valid{$options{"$let="}}) {    # debugging style
                    #
                    # $v now contains the only valid options for -$let
                    #
                    my $opts = $O{$options{"$let="}};
                    $opts =~ s/[$v]//g;     # remove the good ones
                    if ($opts) {
                        my $plural = (length($opts) > 1)? "s": "";
                        $err .= "for -$let: illegal option$plural: ".
                                "$opts, valid ones are: $v\n";
                    }
                }
            } else {
                $err .= "unknown option: -$let\n";
            }
        }
    }
    if ($err) {
        if ($usage) {
            #
            # make sure there is a newline
            # else we'll get "at line ..."
            #
            chomp $usage;
            $err .= "$usage\n";
        }
        die $err;
    }
}

1;

=head1 NAME

Getopt::Easy - parses command line options in a simple but capable way.

=head1 SYNOPSIS

  use Getopt::Easy;

  get_options "v-verbose  f-fname=  D-debug=uSX",
              "usage => "usage: prog [-v] [-f fname] [-D [uSX]] [-H]",
              "H";

  print "reading $O{fname}\n" if $O{verbose};
  print "SQL: $sql\n" if $O{debug} =~ /S/;

=head1 DESCRIPTION

Perl puts the command line parameters in the array @ARGV
allowing the user to examine and manipulate it like any
other array.  There is a long tradition of putting optional
single character flags (preceded by a dash) in front of 
other parameters like so:

  % ls -ltr *.h *.c
  % tar -tvf all.tar
  % ps -ax -U jsmith

Many Getopt::* modules exist to help with the
parsing of these flags out of @ARGV.
For the author, Getopt::Std was visually too cryptic and
Getopt::Long was too large and complex for most normal applications.
Getopt::Easy is small, easy to understand, and provides a visual clarity.

There are two things exported: get_options() and %O.

get_options has 1 required parameter and 2 optional ones.
The first is a string describing the kind of options that
are expected.  It is a space separated list of terms like this:

  get_options "v-verbose   f-fname=";

If the -v option is given on the command
line %O{verbose} will be set to 1 (true).
If the -f option is given then another argument is expected
which will be assigned to $O{fname}.

Before parsing @ARGV, $O{verbose} will be initialized to 0 (false) and
$O{fname} to "" (unless they already have a value).

If you give an unknown option get_options() will complain and exit:

  % prog -vX
  unknown option: -X
  %

These conventions are implemented by Getopt::Easy:

=over 4

=item *

The options can come in any order.

=item *

Multiple boolean options can be bundled together.

=item *

A command line argument of '--' will cause argument parsing to stop
so you can parse the rest of the options yourself.

=item *

Parsed arguments are removed from @ARGV.

=back

These invocations are equivalent:

  % prog -v -f infile
  % prog -f infile -v     # different order
  % prog -v -finfile
  % prog -vf infile
  % prog -vfinfile

This shows that the space between -f and infile is optional
and that you I<can> bundle -f with -v but -f must be
the I<last> option in the bundle.

The optional second parameter to get_options() is
a usage message to be printed when an illegal option is given.

  get_options "v-verbose   f-fname=",
              "usage: prog [-v] [-f fname]";

Now if an unknown option is given, the same
error message will be printed, as above, followed
by the usage message.
      
  % prog -vX
  unknown option: -X
  usage: prog [-v] [-f fname]
  %

=head2 HELP

Sometimes the usage message is not enough and the
user needs more detailed and elaborate help.  This is
where the 3rd optional parameter comes in.

  get_options "v-verbose   f-fname=",
              "usage: prog [-v] [-f fname] [-H]",
              "H";

Giving the -H option will cause the POD for the module
to be echoed to STDOUT - as if the user had typed
'perldoc prog'.  See 'perldoc perlpod'.

=head2 DEBUGGING

There are various ways to implement a debugging option:

GOOD:

  get_options "d-debug";

  print "val = $val\n" if $O{debug};

BETTER:

  get_options "d-debug=";

  print "SQL = $sql\n" if $O{debug} >= 2;
  print "val = $val\n" if $O{debug} >= 3;

With this method there are various I<levels> of debugging.
Unfortunately, they often end up ranging from
'not enough' to 'too much' :(.

BEST:

  get_options "d-debug=eSvL";

  print "SQL = $sql\n" if $O{debug} =~ /S/;
  print "val = $val\n" if $O{debug }=~ /v/;
 
With this kind of term the letters after the equal sign '=' are the
debugging options that are valid.  Now the user can choose exactly
what kind of debugging output they wish to see.

  % prog -d SL

Giving an illegal debugging option will
result in an error message:

  % prog -deXSf
  for -d: illegal options: Xf, valid ones are: eSvL
  %

=head1 ACCESS ELSEWHERE

If you want access to the %O hash from other files simply put:

  use Getopt::Easy;

at the top of those files; the %O hash will again be exported into the
current package.  You need to have:

  get_options ...;

only once in the main file before anyone needs to look at the %O hash.

=head1 STRICT

It is easy to misspell a key for the %O hash.  Tie::StrictHash
can help with this:

  use GetOpt::Easy;
  use Tie::StrictHash;

  get_options "v-verbose  f-fname=";
  strict_hash %O;

  print "file name is $O{filename}\n";

This will give a fatal error message:

  key 'filename' does not exist at prog line 6

=head1 SEE ALSO

Config::Easy allows configuration file entries 
to be overidden with command line arguments.

Tie::StrictHash protects against misspelling of key names.

Date::Simple is an elegant way of dealing with dates.

=head1 AUTHOR

Jon Bjornstad <jon@icogitate.com>
