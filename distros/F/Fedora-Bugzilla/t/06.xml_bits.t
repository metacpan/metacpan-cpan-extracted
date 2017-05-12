#!/usr/bin/perl
#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/06/2009 06:48:05 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

=head1 NAME

06.xml_bits.t - Test the bits we get via the XML bug representation 

=head1 DESCRIPTION 

This test exercises various bits of functionality we derive by going through
the XML representation of a bug.

=head1 TESTS

This module defines the following tests.

Note that for some tests, we defined a lower bound, with any value higher than
that being acceptable.  E.g., we oftern test against, say, 'perl-Mouse', 
which, as an actual review bug, may at some point have additional comments
added to it (say to branch to some new EPEL level or somesuch).

=cut

use strict;
use warnings;

use English qw{ -no_match_vars };  # Avoids regex performance penalty

use Test::More;

BEGIN {

    plan skip_all => 'Must set FB_TEST_USERID & _PASSWD for live tests.'
        unless exists $ENV{FB_TEST_USERID} && exists $ENV{FB_TEST_PASSWD};

    plan tests => 27;
}

use Fedora::Bugzilla;

my $bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

is  $bz->login > 0,  1, 'Login worked';

my $bug = $bz->bug('perl-Mouse');

isa_ok $bug => 'Fedora::Bugzilla::Bug';

=head2 Flags

Try to pull and check some flags.

=cut

is $bug->flag_count                =>   2, 'flags found';
is $bug->get_flag('fedora-review') => '+', 'flag setting found';
is $bug->has_flag('fedora-cvs')    =>   1, 'found flag correctly';

=head2 Comments

Check out some comments bits.

=cut

is $bug->comment_count > 8 => 1, 'found at least 9 comments';

my $c = $bug->get_comment(7);

is $c->title => 'Bug #461388 Comment #8', 'titled correctly';
is "$c"      => 'cvs done', 'comment stringified correctly';
is $c->text  => 'cvs done', 'comment fetched correctly';
is $c->who   => '"Huzaifa S. Sidhpurwala" <huzaifas@redhat.com>', 'who ok';

=head2 CC List

Try to see who is on CC.

=cut

my @list = $bug->cc_list;

is @list >= 2 => 1, 'Found at least 2 ppl on CC';

TODO: {
    local $TODO = 'known not working ATM';
    
    #is $bug->has_email_on_cc(sub { $_ eq 'fedora-package-review@redhat.com'})
    #    => 1, 'f-p-r@rh.com found in cc list';
}

=head2 Depends and Blocks

Always good to test.  But let's use perl-Moose as well; it's more interesting 
in these regards.

=cut

my $moose = $bz->bug('perl-Moose');
my $mouse = $bug;
my $curl  = $bz->bug('perl-WWW-Curl');

isa_ok $moose => 'Fedora::Bugzilla::Bug';
isa_ok $curl  => 'Fedora::Bugzilla::Bug';

is $moose->blocks_anything     => 1, 'moose blocks';
is $moose->num_blocked         => 1, 'blocked count correct';
is $moose->blocks_bug(163779)  => 1, 'correct bug blocked';
is $moose->blocks_bug(123456)  => 0, 'no block 123456';
is $moose->depends_on_anything => 1, 'finds deps';
is $moose->num_deps            => 5, 'deps count correct';

is $mouse->blocks_anything     => 1, q{mouse does block 1 bug, hmm};
is $mouse->blocks_bug(123456)  => 0, 'no block 123456';
is $mouse->depends_on_anything => 1, 'finds deps';
is $mouse->num_deps            => 1, 'deps count correct';

# ok, this one doesn't actually either block or depend on anything
is $curl->blocks_anything     => 0, 'curl no blocks';
is $curl->blocks_bug(123456)  => 0, 'curl no block 123456';
is $curl->depends_on_anything => 0, 'curl no deps';
is $curl->num_deps            => 0, 'curl deps count correct';


__END__

=head1 CONFIGURATION AND ENVIRONMENT

The env. variables FB_TEST_USERID and FB_TEST_PASSWD must be set.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut



