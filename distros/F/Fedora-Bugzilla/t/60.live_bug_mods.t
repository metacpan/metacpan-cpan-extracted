#!/usr/bin/perl
#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/07/2009 05:58:45 AM PST
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

60.live_bug_create.t - test bug creation / manipulation

=head1 DESCRIPTION 

This test exercises bug creation and modification functionality.

=head1 TESTS

This module defines the following tests.

=cut

use Test::More; 

BEGIN {

    plan skip_all => 'Must set FB_TEST_USERID & _PASSWD for live tests.'
        unless exists $ENV{FB_TEST_USERID} && exists $ENV{FB_TEST_PASSWD};

    #plan skip_all => 'Must set FB_TEST_CREATE for bug creation tests'
    #    unless exists $ENV{FB_TEST_CREATE};

    plan tests => 16;
}

use Fedora::Bugzilla;

#use ok 'Fedora::Bugzilla::NewBug';
use Fedora::Bugzilla::NewBug;

my $bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

is  $bz->login > 0,  1, 'Login worked';

# scratch bug
my $BUG = '465913';

=head2 Create a bug

Test creating a bug under the 'Bugzilla/Test' component. (Note: FB_TEST_CREATE
must be set; otherwise we test against an existing scratch bug.)

=cut

# initial fetch against scratch bug
my $bug = $bz->bug($BUG);

SKIP: {
    skip 'Must set FB_TEST_CREATE to test bug creation', 0
        unless $ENV{FB_TEST_CREATE};

        
    my $bug = $bz->create_bug(
        product => 'Bugzilla', 
        component => 'test',
        summary => 'testing Fedora::Bugzilla',
        version => 'devel',

        # new
        #comment => 'Initial long description',
        bug_file_loc => 'http://camelus.fedorahosted.org/',

        assigned_to => 'nobody@fedoraproject.org',

        # note this comment contains a utf-8 char...
        comment =>
        'Spec URL:
    http://fedorapeople.org/~cweyl/review/perl-Directory-Scratch.spec
    SRPM URL:
    http://fedorapeople.org/~cweyl/review/perl-Directory-Scratch-0.14-2.fc9.src.rpm

    Description:
    When writing test suites for modules that operate on files, its often
    inconvenient to correctly create a platform-independent temporary storage
    space, manipulate files inside it, then clean it up when the test exits.
    The inconvenience usually results in tests that don’t work everwhere, or
    worse, no tests at all.

    This module aims to eliminate that problem by making it easy to do things
    right.


    ',

    );
 
    diag 'Test bug created at ' . $bug->id;
}

isa_ok $bug => 'Fedora::Bugzilla::Bug';

=head2 Test assigning / reassigning

=cut

diag 'originally assigned to ' . $bug->assigned_to;

$bug->assigned_to('bugbot@landfill.bugzilla.org');
$bug->update;

is $bug->assigned_to => 'bugbot@landfill.bugzilla.org', 'reassigned correctly';

$bug->assigned_to('nobody@fedoraproject.org');
$bug->update;

is $bug->assigned_to => 'nobody@fedoraproject.org', 'reassigned correctly';

=head2 Test updating / alias

=cut

# test updating
$bug->alias('Frobnip!');

is $bug->dirty, 1, 'dirty marked correctly';

$bug->update;

is $bug->alias, 'Frobnip!', 'Alias updated correctly';
is $bug->dirty, undef, 'clean now';

$bug->alias(undef);
$bug->update;

is $bug->dirty, undef, 'clean now';

#is((not defined $bug->alias ? 1 : 0), 1, 'Alias removed correctly');
#diag $bug->alias;
#ok !(defined $bug->alias), 'Alias removed correctly';
is $bug->alias, q{}, 'Alias removed correctly';

=head2 Test version changes

=cut

# play with changing version, too
is $bug->version, 'devel', 'version is devel';

$bug->version('2.1r');
$bug->update;

is $bug->version, '2.1r', 'version changed OK';

# reset 
$bug->version('devel');
$bug->update;

is $bug->version, 'devel', 'version changed back OK';

=head2 Status bits

Give the closing / resolution code a quick workout.

=cut

SKIP: {
    skip 'bug already closed', 1 if $bug->status eq 'CLOSED';

    $bug->close_notabug;
    
    is $bug->status => 'CLOSED', 'closed OK';
}

#$bug->set_status('NEW');
#is $bug->status => 'NEW',      'status to NEW';

$bug->set_status('ASSIGNED');
is $bug->status => 'ASSIGNED', 'status to ASSIGNED';
$bug->set_status('ON_DEV');
is $bug->status => 'ON_DEV',   'status to ON_DEV';

#$bug->close('NOTABUG', comment => 'closure comment');
$bug->close_notabug(comment => 'closure comment');

is  $bz->logout > 1, 1, 'Logged out ok';

__END__

=head1 CONFIGURATION AND ENVIRONMENT

The env. variables FB_TEST_CREATE, FB_TEST_USERID and FB_TEST_PASSWD
must be set.


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



