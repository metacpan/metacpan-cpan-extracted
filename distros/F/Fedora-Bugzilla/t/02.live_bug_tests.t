#!/usr/bin/perl
#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/06/2009 06:41:07 PM PST
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

02.live_bug_tests.t - test F::B in action!

=head1 DESCRIPTION 

This test exercises various bits of bug functionality.

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

    plan tests => 12;
}

use Fedora::Bugzilla;

my $bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

is  $bz->login > 0,  1, 'Login worked';


my $BUG = '465913';

#my $ret = $bz->add_attachment(
#    $BUG, 
#    filename => '/etc/fedora-release',
#    description => 'the great fedora-release!',
#    contenttype => 'text/plain',
#);

=head2 Get a bug by id

Fetch a bug, and try to determine things about it.

=cut

# play with perl-Moose for testing
my $bug = $bz->bug(205321);

isa_ok $bug, 'Fedora::Bugzilla::Bug';

is $bug->alias, 'perl-Moose', 'alias is correct';

# test an "interesting" one
is $bug->url eq $bug->bug_file_loc, 1, 'url and bug_file_loc are the same';
is $bug->url, 'http://search.cpan.org/dist/Moose/', 'url is correct';

=head2 Get a bug by alias

Pretty much same as above, but by alias this time.

=cut

# test fetching by alias
$bug = $bz->bug('perl-Moose');
isa_ok $bug, 'Fedora::Bugzilla::Bug';

is $bug->alias, 'perl-Moose', 'alias on alias fetched bug is correct';
is $bug->id,    205321,       'id on alias fetched bug is correct';

is  $bz->logout > 1, 1, 'Logged out ok';

=head2 Poke at attachments

Make sure we can check attachments, count them, etc, etc.

=cut

$bug = $bz->bug($BUG);

isa_ok $bug, 'Fedora::Bugzilla::Bug';

is $bug->attachment_count > 6 => 1, 'attachement count > 6, good';

diag 'attachment count == ' . $bug->attachment_count;

my $a = $bug->first_attachment;

isa_ok $a, 'Fedora::Bugzilla::Bug::Attachment';

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



