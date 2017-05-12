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

07.attachments.t - Test attachment functionality

=head1 DESCRIPTION 

This test exercises functionality relating to bug attachments. 

=head1 TESTS

This module defines the following tests.

=cut

use strict;
use warnings;

use English qw{ -no_match_vars };  # Avoids regex performance penalty

use Test::More;

BEGIN {

    # no sense loading Fedora::Bugzilla if we're not actually going to do
    # anything with it.

    plan skip_all => 'Must set FB_TEST_USERID & _PASSWD for live tests.'
        unless exists $ENV{FB_TEST_USERID} && exists $ENV{FB_TEST_PASSWD};

    plan tests => 15;
}

use Fedora::Bugzilla;

my $bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

# use auto-login
#is  $bz->login > 0,  1, 'Login worked';

my $BUG = '465913';

my $bug = $bz->bug($BUG);
isa_ok $bug, 'Fedora::Bugzilla::Bug';

#my $ret = $bz->add_attachment(
#    $BUG, 
#    filename => '/etc/fedora-release',
#    description => 'the great fedora-release!',
#    contenttype => 'text/plain',
#);

=head2 Test attachment functionality w/o bugzilla 

Tests that do not require access to bugzilla. (none ATM)

=cut


=head2 Poke at attachments

Make sure we can check attachments, count them, etc, etc.

=cut

my $orig_count = $bug->attachment_count;

is $orig_count > 6 => 1, 'attachement count > 6, good';

diag 'attachment count == ' . $orig_count;

my $a = $bug->first_attachment;
isa_ok $a, 'Fedora::Bugzilla::Bug::Attachment';

is $a->id => 319831, 'id correct';
is $a->filename => 'fedora-release', 'filename correct';

# check out a different attachment

$a = $bug->get_attachment(5);
isa_ok $a, 'Fedora::Bugzilla::Bug::Attachment';

is $a->id       => 320126,                  'id correct';
is $a->filename => 'fedora-release',        'filename correct';
is $a->attacher => 'cweyl@alumni.drew.edu', 'attacher correct';
is $a->type     => 'text/plain',            'mime type correct';
is $a->size     => 27,                      'size correct';

# we at least know we're correctly decoding if these pass
is $a->encoding => 'base64',                       'encoding is correct';
is $a->data     => "Fedora release 9 (Sulphur)\n", 'data is correct';

=head2 Modify attachments test

Add, etc, an attachment.  Only called if FB_TEST_MAKE_CHANGES set.

=cut

SKIP: {
    skip 'Skipping tests that change the bug', 2 
        unless exists $ENV{FB_TEST_MAKE_CHANGES};

    my $a2 = $bug->add_attachment(
        filename    => '/etc/fedora-release',
        description => 'The increasingly great fedora-release!',
    );

    isa_ok $a2 => 'Fedora::Bugzilla::Bug::Attachment';
    is $bug->attachment_count => $orig_count + 1, 'new count is correct';
    
    # FIXME could use a few more here...
}


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



