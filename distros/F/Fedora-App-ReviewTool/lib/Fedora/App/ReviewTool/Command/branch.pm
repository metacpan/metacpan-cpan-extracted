#############################################################################
#
# Command class to look for and branch review tix that are ready for it!
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/06/2009 11:01:11 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::branch;

use Moose;

use IO::Prompt;
use Text::SimpleTable;

# debugging...
#use Smart::Comments;

use namespace::clean -except => 'meta';

extends qw{ MooseX::App::Cmd::Command }; 

with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Submitter';

our $VERSION = '0.10';

# regexps that if the rpm name matches, an initial_cc entry is added
my %INITIAL_CC = (
     qr/^perl-/ => 'perl-sig',
);

has branches => (
    is            => 'rw',
    isa           => 'Str',
    default       => 'F-9 F-10 F-11 devel',
    documentation => 'initial branches to request',
);

has owners => (
    is            => 'rw',
    isa           => 'Str',
    lazy_build    => 1,
    documentation => 'package owners (for pkgdb)',
);

# default from our cert
sub _build_owners { shift->app->cn }

# FIXME please clean this up.  :-)

#has cc => (
#    is            => 'rw', 
#    isa           => 'Str',
#    lazy_build    => 1,
#    documentation => 'initial CC list',
#);

#sub _build_cc {
sub build_cc {
    my ($self, $name) = @_;

    my $cc   = q{};
    #my $name = $self->_name;

    for my $regexp (keys %INITIAL_CC) {

        # if name matches regexp, add the initial cc given
        $cc .= $INITIAL_CC{$regexp} if $name =~ $regexp
    }

    return $cc;
}

sub run {
    my ($self, $opts, $args) = @_;
    my $bugs;

    $self->app->startup_checks;
    
    if (@$args == 0) {

        print "Finding our submitted bugs...\n";
        $bugs = $self->find_my_submissions;
    }
    else {

        # go after the ones on the command line...
        $bugs = $self->_bz->bugs($args);
    }

    print "Found bugs $bugs.\n\n";

    BUG_LOOP:
    for my $bug ($bugs->bugs) {

        my $pkg = $bug->package_name;

        print "Checking $bug ($pkg)...\n";

        if (!$bug->ready_for_branching) {

            print "$bug not ready for branching.\n\n";
            next BUG_LOOP;
        }

        # build from template
        my $branch_req = $self->app->branch(
            name     => $pkg,
            summary  => $bug->package_desc, # $bug->summary,
            owners   => $self->owners,
            #cc       => $self->cc,
            cc       => $self->build_cc($pkg),
            branches => $self->branches,
        );

        print "\n";

        print $self->app->verbose_description(
            bug        => $bug, 
            branch_req => $branch_req,
        );

        if ($self->yes || prompt "Post branch request? ", -YyNn) {

            print "\nPosting...\n";

            $bug->add_comment($branch_req);
            $bug->set_flags('fedora-cvs' => '?');

            print "Posted initial branch request to review bug (BZ#$bug).\n";
        }
        else { print "Not posting branch request.\n" }
    }

    return;
}

sub _sections { qw{ bugzilla submit } }

sub _usage_format {
    return 'usage: %c branch <name|bug#> [<name|bug#> ...] %o';
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Command::branch - [submitter] branch request

=head1 SYNOPSIS

    ./reviewtool branch


=head1 DESCRIPTION

This provides a "branch" command to the L<Fedora::App::ReviewTool>
application.  It can take either bug ids / aliases on the command line or
search for your open review tix, determine which ones are ready to branch,
and ask you if you want to post a branch request.


=head1 SUBROUTINES/METHODS

FIXME/TODO!

=head1 SEE ALSO

L<Fedora::App::ReviewTool>

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


