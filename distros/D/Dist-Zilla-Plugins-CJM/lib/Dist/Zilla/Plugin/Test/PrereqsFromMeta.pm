#---------------------------------------------------------------------
package Dist::Zilla::Plugin::Test::PrereqsFromMeta;
#
# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  22 Nov 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Check the prereqs from our META.json
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '4.23';
# This file is part of Dist-Zilla-Plugins-CJM 4.27 (August 29, 2015)


use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::FilePruner';

#---------------------------------------------------------------------
# Make sure we've included a META.json:

sub prune_files
{
  my $self = shift;

  my $files = $self->zilla->files;

  unless (grep { $_->name eq 'META.json' } @$files) {
    $self->log("WARNING: META.json not found, removing t/00-all_prereqs.t");
    @$files = grep { $_->name ne 't/00-all_prereqs.t' } @$files;
  } # end unless META.json

  return;
} # end prune_files

#---------------------------------------------------------------------
no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Dist::Zilla::Plugin::Test::PrereqsFromMeta - Check the prereqs from our META.json

=head1 VERSION

This document describes version 4.23 of
Dist::Zilla::Plugin::Test::PrereqsFromMeta, released August 29, 2015
as part of Dist-Zilla-Plugins-CJM version 4.27.

=head1 SYNOPSIS

In your F<dist.ini>:

  [Test::PrereqsFromMeta]

=head1 DESCRIPTION

This plugin will inject F<t/00-all_prereqs.t> into your dist.  This
test reads your F<META.json> file and attempts to load all runtime
prerequisites.  It fails if any required runtime prerequisites fail to
load.  (If the loaded version is less than the required version, it
prints a warning message but the test does not fail.)

In addition, if C<AUTOMATED_TESTING> is set, it dumps out every module
in C<%INC> along with its version.  This can help you determine the
cause of failures reported by CPAN Testers.

You can also get the version dump by running F<t/00-all_prereqs.t> with
the C<-v> or C<--verbose> option.  (This is not the same as passing
the C<-v> option to C<prove>.)


=for Pod::Coverage
prune_files

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Dist-Zilla-Plugins-CJM AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugins-CJM >>.

You can follow or contribute to Dist-Zilla-Plugins-CJM's development at
L<< https://github.com/madsen/dist-zilla-plugins-cjm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__DATA__
___[ t/00-all_prereqs.t ]___
#!perl

use strict;
use warnings;

# This doesn't use Test::More because I don't want to clutter %INC
# with modules that aren't prerequisites.

my $test = 0;
my $tests_completed;

sub ok ($$)
{
  my ($ok, $name) = @_;

  printf "%sok %d - %s\n", ($ok ? '' : 'not '), ++$test, $name;

  return $ok;
} # end ok

END {
  ok(0, 'unknown failure') unless defined $tests_completed;
  print "1..$tests_completed\n";
}

sub get_version
{
  my ($package) = @_;

  local $@;
  my $version = eval { $package->VERSION };

  defined $version ? $version : 'undef';
} # end get_version

TEST: {
  ok(open(META, '<META.json'), 'opened META.json') or last TEST;

  while (<META>) {
     last if /^\s*"prereqs" : \{\s*\z/;
  } # end while <META>

  ok(defined $_, 'found prereqs') or last TEST;

  while (<META>) {
    last if /^\s*\},?\s*\z/;
    ok(/^\s*"(.+)" : \{\s*\z/, "found phase $1") or last TEST;
    my $phase = $1;

    while (<META>) {
      last if /^\s*\},?\s*\z/;
      next if /^\s*"[^"]+"\s*:\s*\{\s*\},?\s*\z/;
      ok(/^\s*"(.+)" : \{\s*\z/, "found relationship $phase $1") or last TEST;
      my $rel = $1;

      while (<META>) {
        last if /^\s*\},?\s*\z/;
        ok(/^\s*"([^"]+)"\s*:\s*(\S+?),?\s*\z/, "found prereq $1")
            or last TEST;
        my ($prereq, $version) = ($1, $2);

        next if $phase ne 'runtime' or $prereq eq 'perl';

        # Need a special case for if.pm, because "require if;" is a syntax error.
        my $loaded = ($prereq eq 'if')
            ? eval "require '$prereq.pm'; 1"
            : eval "require $prereq; 1";
        if ($rel eq 'requires') {
          ok($loaded, "loaded $prereq") or
              print STDERR "\n# ERROR: Wanted: $prereq $version\n";
        } else {
          ok(1, ($loaded ? 'loaded' : 'failed to load') . " $prereq");
        }
        if ($loaded and not ($version eq '"0"' or
                             eval "'$prereq'->VERSION($version); 1")) {
          printf STDERR "\n# WARNING: Got: %s %s\n#       Wanted: %s %s\n",
                        $prereq, get_version($prereq), $prereq, $version;
        }
      } # end while <META> in prerequisites
    } # end while <META> in relationship
  } # end while <META> in phase

  close META;

  # Print version of all loaded modules:
  if ($ENV{AUTOMATED_TESTING} or
      (@ARGV and ($ARGV[0] eq '-v' or $ARGV[0] eq '--verbose'))) {
    print STDERR "# Listing %INC\n";

    my @packages = grep { s/\.pm\Z// and do { s![\\/]!::!g; 1 } } sort keys %INC;

    my $len = 0;
    for (@packages) { $len = length if length > $len }
    $len = 68 if $len > 68;

    for my $package (@packages) {
      printf STDERR "# %${len}s %s\n", $package, get_version($package);
    }
  } # end if AUTOMATED_TESTING
} # end TEST

$tests_completed = $test;

__END__
