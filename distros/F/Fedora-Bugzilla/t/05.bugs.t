#!/usr/bin/perl
#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/05/2009 06:33:52 PM PST
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

05.bugs.t - test various functionality returning multiple bugs 

=head1 DESCRIPTION 

This test exercises functionality that returns multiple bugs via a
L<Fedora::Bugzilla::Bugs> object.

=head1 TESTS

This module defines the following tests.

=cut

use strict;
use warnings;

use English qw{ -no_match_vars };  # Avoids regex performance penalty

use Test::More;

BEGIN {

    plan skip_all => 'Must set FB_TEST_USERID & _PASSWD for live tests.'
        unless exists $ENV{FB_TEST_USERID} && exists $ENV{FB_TEST_PASSWD};

    plan tests => 13;
}

use Fedora::Bugzilla;

my $bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

is  $bz->login > 0,  1, 'Login worked';

=head2 Fetch multiple bugs by name

Test fetching multiple bugs at the same time, both by name and by alias.

FIXME these test assuming $bz->aggressive_fetch == 1.  We should probably
check it with it being 1 and 0.

=cut

my @BUGS = qw{ 478571 perl-Mouse perl-Moose };

my $bugs = $bz->get_bugs(@BUGS);

isa_ok $bugs => 'Fedora::Bugzilla::Bugs';

is $bugs->num_bugs => 3, 'bugs counted correctly';

# check out perl-Moose, make sure it looks right

my $bug = $bugs->get_bug(1);

isa_ok $bug => 'Fedora::Bugzilla::Bug';

is $bug->alias    => 'perl-Mouse', q{yep, it's perl-Mouse};
is $bug->has_xml  => 1,            'have xml';
is $bug->has_twig => 1,            'have our twig';

# some xml-derived attributes
#$bug->all_flags; 
is $bug->has_flag('fedora-review') => 1,   'have fedora-review set';
is $bug->get_flag('fedora-review') => '+', 'fedora-review set OK';

# and make sure it's not overlapping

=head2 Run saved searches

Checks out with running a saved search, 'perl review requests'. Doesn't do
much more than run the query and make sure we have a resultset with at least
one bug in it. 

=cut

$bugs = $bz->run_named_query('perl review requests');

isa_ok $bugs => 'Fedora::Bugzilla::Bugs';
diag $bugs->num_bugs;
is $bugs->num_bugs > 0, 1, 'found more than one review req';

=head2 Run something simple with quicksearch

=cut

$bugs = $bz->run_quicksearch('Moose', 'review');

diag 'this one may take awhile';
isa_ok $bugs => 'Fedora::Bugzilla::Bugs';
diag $bugs->num_bugs;
is $bugs->num_bugs > 0, 1, 'found more than one review req';

# FIXME TODO!

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



