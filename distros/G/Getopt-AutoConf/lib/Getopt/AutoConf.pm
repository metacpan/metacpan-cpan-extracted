package Getopt::AutoConf;

# -------------------------------------------------------------------
#
# $Id: AutoConf.pm,v 1.6 2001/10/01 12:35:23 dlc Exp $
#
# -------------------------------------------------------------------
#   Getopt::AutoConf -- use autoconf(1)-style options
#
#   Copyright (C) 2001 darren chamberlain <darren@cpan.org>
#
#   This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# 
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this software. If not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
# -------------------------------------------------------------------

use strict;
use vars qw($VERSION @EXPORT $DEBUG $ERROR);

=head1 NAME

Getopt::AutoConf -- use autoconf(1)-style options

=head1 SYNOPSIS

Getopt::AutoConf provides command-line parameter parsing similar to that
provided by GNU autoconf(1).  Getopt::AutoConf simplifies parsing of
arguments in the form --with, --without, --enable, and --disable.

=head1 SYNOPSIS

 ./configure.pl --with-foo=/usr/local/lib/libfoo.a --disable-bar \
        --enable-baz --without-quux

called as:

  use Getopt::AutoConf;

  GetOptions(
        'foo'  => \@foo,
        'bar'  => \$bar,
        'baz'  => \$baz,
        'quux' => \&quux,
  ) or die $Getopt::AutoConf::ERROR;

  print @foo, $bar, $baz;
  # Prints: /usr/local/lib/libfoo.a 0 1

=cut

require Exporter;

use base qw(Exporter);
@EXPORT  = qw(GetOptions);
$VERSION = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;

=head1 DESCRIPTION

Getopt::AutoConf allows for autoconf-style parameters with no extra
parsing on the part of the script writer.

The module exports a single function, called GetOptions, which takes a
hash describing what options should be parsed. Each key in this hash
is a variable name, and each value is a reference to a variable into
which the value should be placed, similar to Getopt::Long.  GetOptions
returns 1 on success or undef on failure. The variables referenced
should already be defined, although in the absence of 'use strict'
this is not required.

Getopt::AutoConf::GetOptions is written in such a way that arguments not
beginning with '--enable-', '--disable-', '--with-', or '--without-'
are passed through unmodified; another option processing module can
then process the remaining arguments.  For example:

  use Getopt::Long ();
  use Getopt::AutoConf ();

  my ($foo, $bar, $baz, $quux);
  Getopt::AutoConf::GetOptions('foo' => \$foo, 'bar' => \$bar);
  Getopt::Long::GetOptions('baz' => \$baz, 'quux' => \$quux);

See t/03golngoa.t for another (working) example. Note that in this
case, modules should be used with () as their argument list, and the
functions' full name should be typed, to avoid the name clash.

The keys to the hash passed into GetOptions can be references of one
of three types: references to scalar variables, references to arrays,
or code references.  How each reference type is dereferenced depends
on whether they were preceded by enable, disable, with, or without
(each is detailed below).

Options can be passed in the any of the following forms:

=over 4

=cut

sub GetOptions {
    if (@_ % 2) {
        $ERROR = "Must call GetOptions with a hash";
        return;
    }
    my %options = @_;
    my @argv;
    debug("+-> Looking at \@ARGV\n");

    #
    # Big foreach loop.
    #
    for (@ARGV) {
        debug("  +-> Looking at `$_'\n");
        if (/^--(?:enable|with)-([a-zA-Z][a-zA-Z0-9_-]*)(?:=(.*))?$/) {

=item B<--with-$var=$value>, B<--enable-$var=$value>

This sets $var to $value.  If a reference to a scalar is passed to
GetOptions, then $value will be assigned to $var.  If a reference to
an array is passed, the $value will be pushed onto @{$var}.  If a code
ref is passed, then the code is executed, with ($var, $value) as
parameters.

If $val is attached to a scalar reference, and there are multiple
occurances of $var on the command line, the last one passed overrides
all earlier occurances.

=cut
            debug("  | `-> Got 'enable' option: `$1' => `$2'\n");
            next unless defined $options{$1};
            my $reftype = ref $options{$1};
            if ($reftype eq 'SCALAR') {
                if ($2) {
                    ${$options{$1}} = $2;
                } else {
                    ${$options{$1}} = 1;
                }
            } elsif ($reftype eq 'ARRAY') {
                push @{$options{$1}}, ($2 or 1);
            } elsif ($reftype eq 'CODE') {
                $options{$1}->($1, $2);
            } else {
                return error($2, $reftype, $1);
            }
        } elsif (/^--(?:without|disable)-([a-zA-Z][-a-zA-Z0-9_]*)(?:=(.*))?$/) {

=item B<--without-$var(=$value)?>, B<--disable-$var(=$value)?>

Both --without- and --disable- act identically.  If a reference to a
scalar variable is passed to GetOptions, the this value is set to 0
(regardless of what, if anything, comes after the "=" on the command
line). If a reference to an array is passed in, and there is nothing
after the "=" (or no "="), the referent is set to the empty list. If
there is data after the "=", then this data is spliced from the
referenced array.  Code references are invoked with ($var, $value) as
paramters, or ($var, "") if $value is not present (in this way,
enabled and disabled variables which are attached to code refs
function identically).

=back

=cut
            debug("  | `-> Got negative option `$1'\n");
            next unless defined $options{$1};
            my $reftype = ref $options{$1};
            if ($reftype eq 'SCALAR') {
                ${$options{$1}} = 0;
            } elsif ($reftype eq 'ARRAY') {
                if ($2) {
                    @{$options{$1}} = grep !/^$2$/, @{$options{$1}};
                } else {
                    debug("  |   `-> Clearing `$1'\n");
                    undef @{$options{$1}};
                }
            } elsif ($reftype eq 'CODE') {
                $options{$1}->($1, ($2 || ""));
            } else {
                error($2, $reftype, $1);
            }
        } else {
            debug("  +-> Skipping `$_'\n");
            push @argv, $_;
        }
    }
    @ARGV = @argv;

    return 1;
}

sub error { $ERROR= "Can't assign '$_[0]' to $_[1] '$_[2]'"; return; }
sub debug { if ($DEBUG) { warn @_; } }

1;
__END__

=head1 EXAMPLES

Here is some code with will upload the English and Spanish versions of
the index page, along with the respective flag icons.

  # The code:
  GetOptions(
      "html"  => \@html,
      "image" => \@images,
  );

  for (@html, @images) {
      enqueue($_);
  }

  # The command line invocation:
  $ upload.pl --with-html=htdocs/index.en.html \
              --with-html=htdocs/index.es.html \
              --with-image=htdocs/images/flags/en.gif \
              --with-image=htdocs/images/flags/es.gif

A real(ish) example.  A script designed to be invoked from a CVS commit
might be invoked something like this (from the CVSROOT/loginfo file):

  # in CVSROOT/loginfo:
  DEFAULT /usr/local/bin/commit-fu \
              --cvs=/usr/bin/cvs --cvsspec=%{sVv}  \
              --cvsroot=/cvsroot --diffoptions="-uw" \
              --recipient=commit-fu-users@lists.sf.net \
              --recipient=cvs-dev@cvshome.com

  # And, in the body of /usr/local/bin/commit-fu:
  my ($cvs, $cvsroot, $cvsoptions, $cvsspec, @recipients);
  GetOptions("cvs"         => \$cvs,
             "cvsspec"     => \$cvsspec,
             "cvsroot"     => \$cvsroot,
             "diffoptions" => \$diffoptions,
             "recipient"   => \@recipients);

A final example: the configure script for the sevenmail webmail
software.

  # in configure.pl:
  my ($VERBOSE, $ap_src, %mysql, $defaultdomain);
  my @options = ('aliases', 'forwarding');
  GetOptions(
    "verbose"       => \$VERBOSE,
    "apache_src"    => \$ap_src,
    "mysql-user"    => \$mysql{'user'},
    "mysql-passwd"  => \$mysql{'passwd'},
    "mysql-host"    => \$mysql{'host'},
    "option"        => \@options,
    "defaultdomain" => \$defaultdomain,
  );

  # invocation:
  ./configure.pl --with-apache_src=/usr/local/src/apache_1.3.20/src \
                 --with-defaultdomain=sevenroot.org
                 --with-mysql-user=nobody   \
                 --with-mysql-passwd=l33t&s3kr3t   \
                 --wtih-mysql-host=dbhost     \
                 --enable-option=masquerading   \
                 --enable-option=mbox-limits \
                 --disable-option=aliases   \
                 --verbose

This configuration has the effect of, along with setting all of the
various scalars, removing the default "aliases" option defined in the
script (because of the "--disable-option=aliases") but leaving the
default "forwarding" option alone.

=head1 AUTHOR

darren chamberlain <darren@cpan.org>

=head1 VERSION

$Revision: 1.6 $

Copyright 2001 darren chamberlain <darren@cpan.org>
