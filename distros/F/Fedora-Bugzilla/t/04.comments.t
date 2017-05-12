#!/usr/bin/perl
#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/01/2009 08:21:34 PM PST
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

04.comments.t - exercise the comments functionality 

=head1 SYNOPSIS

This test exercises the comments functionality; only in getting not setting at
the moment.

=cut

use strict;
use warnings;

use Test::More;

plan skip_all => 'Must set FB_TEST_USERID & _PASSWD for live tests.'
    unless exists $ENV{FB_TEST_USERID} && exists $ENV{FB_TEST_PASSWD};

plan tests => 9;

use Fedora::Bugzilla;

my $bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

is  $bz->login > 0,  1, 'Login worked';

my $BUG = 478571;

my $bug = $bz->bug($BUG);

is $bug->comment_count => 3, 'counted correctly';

my $c = $bug->get_comment(2);

isa_ok $c       => 'Fedora::Bugzilla::Bug::Comment';
is $c           => 'Bug #478571 Comment #3', 'comment stringification'; 
is $c->text     => 'Comment #3!',            'comment #2 text'; 
isa_ok $c->date => 'DateTime',               'date class';
is $c->date     => '2009-01-01T23:25:50',    'comment date looks good';
isa_ok $c->who  => 'Email::Address';
is $c->who      => '"Chris Weyl" <cweyl@alumni.drew.edu>',  'email correct';

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



