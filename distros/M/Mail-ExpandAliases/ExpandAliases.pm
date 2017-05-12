package Mail::ExpandAliases;

# -------------------------------------------------------------------
# Mail::ExpandAliases - Expand aliases from /etc/aliases files
# Copyright (C) 2002 darren chamberlain <darren@cpan.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
# -------------------------------------------------------------------
# Design of this class:
#
#   - Read aliases file
#
#   - Parse aliases file
#
#       o Read file, normalize
#
#           + Skip malformed lines
#
#           + Join multi-line entries
#
#           + Discard comments
#
#       o Create internal structure
#
#   - On call to expand
#
#       o Start with first alias, and expand
#
#       o Expand each alias, unless:
#
#           + It is non-local
#
#           + It has already been seen
#
#   - Return list of responses
# -------------------------------------------------------------------

use strict;
use vars qw($VERSION $DEBUG @POSSIBLE_ALIAS_FILES);

$VERSION = 0.49;
$DEBUG = 0 unless defined $DEBUG;
@POSSIBLE_ALIAS_FILES = qw(/etc/aliases
                           /etc/mail/aliases
                           /etc/postfix/aliases
                           /etc/exim/aliases);

use constant PARSED  => 0;  # Parsed aliases
use constant CACHED  => 1;  # Caches lookups
use constant FILE    => 2;  # "Main" aliases file

# ----------------------------------------------------------------------
# import(@files)
#
# Allow for compile-time additions to @POSSIBLE_ALIAS_FILES
# ----------------------------------------------------------------------
sub import {
    my $class = shift;

    for my $x (@_) {
        if ($x =~ /^debug$/i) {
            $DEBUG = 1;
        }
        elsif (-f "$x") {
            unshift @POSSIBLE_ALIAS_FILES, $x;
        }
    }
}

sub new {
    my ($class, $file) = @_;
    my $self = bless [ { }, { }, "" ] => $class;

    $self->[ FILE ] = (grep { -e $_ && -r _ }
                       ($file, @POSSIBLE_ALIAS_FILES))[0];
    $self->debug("Using alias file " . $self->[ FILE ]);
    $self->init();

    return $self;
}

sub debug {
    my $class = shift;
    $class = ref $class || $class;
    if ($DEBUG) {
        warn "[ $class ] $_\n"
            for (@_);
    }
}

# ----------------------------------------------------------------------
# init($file)
#
# Parse file, extracting aliases.  Note that this is a (more or less)
# literal representation of the file; expansion of aliases happens at
# run time, as aliases are requested.
# # ----------------------------------------------------------------------
sub init {
    my $self = shift;
    my $file = shift || $self->[ FILE ];
    return $self unless defined $file;

    # Chapter 24 of the sendmail book
    # (www.oreilly.com/catalog/sendmail/) describes the process of
    # looking for aliases thusly:
    #
    # "The aliases(5) file is composed of lines of text.  Any line that
    # begins with a # is a comment and is ignored.  Empty lines (those
    # that contain only a newline character) are also ignored.  Any
    # lines that begins with a space or tab is joined (appended) to the
    # line above it.  All other lines are text are viewed as alias
    # lines.  The format for an alias line is:
    #
    #   local: alias
    #
    # "The local must begin a line. It is an address in the form of a
    # local recipient address...  The colon follows the local on
    # the same line and may be preceded with spaces or tabs.  If the
    # colon is missing, sendmail prints and syslog(3)'s the following
    # error message and skips that alias line:
    #
    #   missing colon
    #
    # "The alias (to the right of the colon) is one or more addresses on
    # the same line.  Indented continuation lines are permitted.  Each
    # address should be separated from the next by a comma and optional
    # space characters. A typical alias looks like this:
    #
    #   root: jim, sysadmin@server, gunther ^ | indenting whitespace
    #
    # "Here, root is hte local address to be aliases.  When mail is to
    # be locally delivered to root, it is looked up in the aliases(5)
    # file.  If found, root is replaced with the three addresses show
    # earlier, and mail is instead delivered to those other three
    # addresses.
    #
    # "This process of looking up and possibly aliases local recipients
    # is repeated for each recipient until no more aliases are found in
    # the aliases(5) file.  That is, for example, if one of the aliases
    # for root is jim, and if jim also exists to the left of a colon in
    # the aliases file, he too is replaced with his alias:
    #
    #   jim: jim@otherhost
    #
    # "The list of addresses to the right of the colon may be mail
    # addresses (such as gunther or jim@otherhost), the name of a
    # program to run (such as /etc/relocated), the name of a file onto
    # which to append (such as /usr/share/archive), or the name of a
    # file to read for additional addresses (using :include:)."

    $self->debug("Opening alias file '$file'");
    my $fh = File::Aliases->new($file)
        or die "Can't open $file: $!";

    while (my $line = $fh->next) {
        chomp($line);
        next if $line =~ /^#/;
        next if $line =~ /^\s*$/;

        $line =~ s/\s+/ /g;
        my ($orig, $alias, @expandos);

        $orig = $line;
        if ($line =~ s/^([^:]+)\s*:\s*//) {
            $alias = lc $1;
            $self->debug("$. => '$alias'");
        }
        else {
            local $DEBUG = 1;
            $self->debug("$file line $.: missing colon");
            next;
        }

        @expandos =
            #grep !/^$alias$/,
            map { s/^\s*//; s/\s*$//; $_ }
            split /,/, $line;

        $self->debug($alias, map "\t$_", @expandos);
        $self->[ PARSED ]->{ $alias } = \@expandos;
    }

    return $self;
}

# ----------------------------------------------------------------------
# expand($name)
#
# Expands $name to @addresses.  If @addresses is empty, return $name.
# In list context, returns a list of the matching expansions; in
# scalar context, returns a reference to an array of expansions.
# ----------------------------------------------------------------------
sub expand {
    my ($self, $name, $original, $lcname, %answers, @answers, @names, $n);
    $self = shift;
    $name = shift || return $name;
    $original = shift;
    $lcname = lc $name;

    return $name if (defined $original && $name eq $original);

    return @{ $self->[ CACHED ]->{ $lcname } }
        if (defined $self->[ CACHED ]->{ $lcname });

    if (@names = @{ $self->[ PARSED ]->{ $lcname } || [ ] }) {
        my $c = $self->[ CACHED ]->{ $lcname } = [ ];

        for $n (@names) {
            $n =~ s/^[\s'"]*//g;
            $n =~ s/['"\s]*$//g;
            my $type = substr $n, 0, 1;

            if ($type eq '|' or $type eq '/') {
                # |/path/to/program
                # /path/to/mbox
                $answers{ $n }++;
                push @$c, $n;
            }

            elsif ($type eq ':') {
                # :include:
                #$n =~ s/:include:\s*//ig;
                #$self->parse($n);
                warn "Skipping include file $n\n";
            }

            elsif ($type eq '\\') {
                # \foo
                # literal, non-escaped value, useful for
                # aliases like:
                #   foo: \foo, bar
                # where mail to foo, a local user, should also
                # go to bar.
                $n =~ s/^\\//;
                $answers{ $n }++;
                push @$c, $n;
            }

            else {
                for ($self->expand($n, $original || $name)) {
                    $answers{ $_ }++
                }
            }
        }

        # Add to the cache
        @answers = sort keys %answers;
        $self->[ CACHED ]->{ $lcname } = \@answers;
        return wantarray ? @answers : \@answers;
    }

    return $name;
}

# ----------------------------------------------------------------------
# reload()
#
# Reset the instance.  Clears out parsed aliases and empties the cache.
# ----------------------------------------------------------------------
sub reload {
    my ($self, $file) = @_;

    %{ $self->[ PARSED ] } = ();
    %{ $self->[ CACHED ] } = ();
    $self->[ FILE ] = $file if defined $file;

    $self->parse;

    return $self;
}

# ----------------------------------------------------------------------
# aliases()
#
# Lists the aliases.
# In list context, returns an array;
# in scalar context, returns a reference to an array.
#
# From a patch submitted by Thomas Kishel <tom@kishel.net>
# ----------------------------------------------------------------------
sub aliases {
    my ($self, @answers);
    $self = shift;
    @answers = sort keys %{ $self->[ PARSED ] };
    return wantarray ? @answers : \@answers;
}

# ----------------------------------------------------------------------
# exists($alias)
#
# Determine if an alias exists not not
# ----------------------------------------------------------------------
sub exists {
    my ($self, $alias) = @_;
    return CORE::exists($self->[ PARSED ]->{ $alias });
}

# ----------------------------------------------------------------------
# check($alias)
#
# Returns the unexpanded form an an alias.  I.e., exactly what is in the
# file, without expansion.
#
# Unlike expand, if $alias does not exist in the file, check() returns
# the empty array.  Otherwise, $alias returns an array (in list context)
# or a reference to an array (in scalar context) to the items in the
# aliases file.
#
# You can emulate expand() by calling check recusrively.
# ----------------------------------------------------------------------
sub check {
    my $self = shift;
    my $ret;

    if (my $name = shift) {
        $ret = $self->[ PARSED ]->{ $name }
    }

    $ret ||= [];

    return wantarray ? @$ret : [ @$ret ];
}

package File::Aliases;
use constant FH     => 0;
use constant BUFFER => 1;

use IO::File;

# This package ensures that each read (i.e., calls to next() --
# I'm too lazy to implement this as a tied file handle so it can
# be used in <>) returns a single alias entry, which may span
# multiple lines.
#
# XXX I suppose I could simply subclass IO::File, and rename next
# to readline.

sub new {
    my $class = shift;
    my $file = shift;
    my $fh = IO::File->new($file);

    my $self = bless [ $fh, '' ] => $class;
    $self->[ BUFFER ] = <$fh>
        if $fh;

    return $self;
}

sub next {
    my $self = shift;
    my $buffer = $self->[ BUFFER ];
    my $fh = $self->[ FH ];

    return ""
        unless defined $fh;

    $self->[ BUFFER ] = "";
    while (<$fh>) {
        if (/^\S/) {
            $self->[ BUFFER ] = $_;
            last;
        } else {
            $buffer .= $_;
        }
    }

    return $buffer;
}

1;

__END__

=head1 NAME

Mail::ExpandAliases - Expand aliases from /etc/aliases files

=head1 SYNOPSIS

  use Mail::ExpandAliases;

  my $ma = Mail::ExpandAliases->new("/etc/aliases");
  my @list = $ma->expand("listname");

=head1 DESCRIPTION

I've looked for software to expand aliases from an alias file for a
while, but have never found anything adequate.  In this day and age,
few public SMTP servers support EXPN, which makes alias expansion
problematic.  This module, and the accompanying C<expand-alias>
script, attempts to address that deficiency.

=head1 USAGE

Mail::ExpandAliases is an object oriented module, with a constructor
named C<new>:

  my $ma = Mail::ExpandAliases->new("/etc/mail/aliases");

C<new> takes the filename of an aliases file; if not supplied, or if
the file specified does not exist or is not readable,
Mail::ExpandAliases will look in a predetermined set of default
locations and use the first one found.  See L<"ALIAS FILE LOCATIONS">,
below, for details on this search path and how to modify it.

Lookups are made using the C<expand> method:

  @aliases = $ma->expand("listname");

C<expand> returns a list of expanded addresses, sorted alphabetically.
These expanded addresses are also expanded, whenever possible.

A non-expandible alias (no entry in the aliases file) expands to
itself, i.e., does not expand.

In scalar context, C<expand> returns a reference to a list.  Note 
that this list may have 1 item in it.

Note that Mail::ExpandAliases provides read-only access to the alias
file.  If you are looking for read access, see Mail::Alias, which is a
more general interface to alias files.

Mail::ExpandAliases make a resonable attempt to handle aliases the way
C<sendmail> does, including loop detection and support for escaped
named.  See chapter 24, "Aliases", in I<Sendmail>
(E<lt>http://www.oreilly.com/catalog/sendmail/E<gt>) for full details
about this process.

As of version 0.48, support exists for non-recursive alias expansions,
i.e., returning what's listed in the alias file.  This is done with the
C<check> method:

  @aliases = $ma->check($alias);

In list context, C<check> returns a list of matches, and in scalar
context, C<check> returns a reference to a list.

There is also an C<exists> method, which will indicate if a particular
alias is defined in the file:

  if ($ma->exists($alias)) {
      ....

=head1 ALIAS FILE LOCATIONS

Paths to the aliases file can be added globally at compile time:

  use Mail::ExpandAliases qw(/etc/exim/aliases);

Alias file locations can also be specified to instances when they
are constructed:

  my $ma = Mail::ExpandAliases->new("/etc/exim/aliases");

Alias file locations are stored in the package global @POSSIBLE_ALIAS_FILES,
which can be assigned to directly if you're not impressed with encapsulation:

  @Mail::ExpandAliases::POSSIBLE_ALIAS_FILES = ("/etc/aliases");

By default, @POSSIBLE_ALIAS_FILES contains F</etc/aliases>,
F</etc/mail/aliases>, F</etc/postfix/aliases>, and
F</etc/exim/aliases>.  If your alias file is ones of these, the
filename can be omitted from the constructor; Mail::ExpandAliases will
look in @POSSIBLE_ALIAS_FILES until it finds a file that exists.

Note that it is not (necessarily) an error if none of these files
exists.  An alias file can be added by passing a filename to the
init() method:

  my $ma = Mail::ExpandAliases->new();

  # Write a temporary aliases file in /tmp/aliases-$<
  $ma->init("/tmp/aliases-$<");

Calling expand before setting an alias file will, of course, produce
no useful expansions.

If the constructor is called with the name of a file that exists but
cannot be opened, Mail::ExpandAliases will die with an error detailing
the problem.

=head1 BUGS / SHORTCOMINGS

If you were telnet mailhost 25, and the server had EXPN turned on,
then sendmail would read a user's .forward file.  This software cannot
do that, and makes no attempt to.  Only the invoking user's .forward
file should be readable (if any other user's .forward file was
readable, sendmail would not read it, making this feature useless),
and the invoking user should not need this module to read their own
.forward file.

Any other shortcomings, bugs, errors, or generally related complaints
and requests should be reported via the appropriate queue at
<http://rt.cpan.org/>.

=head1 AUTHOR

darren chamberlain E<lt>darren@cpan.orgE<gt>
