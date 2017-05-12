#############################################################################
#
# Provides a 'close' command to Fedora::App::ReviewTool.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/07/2009 11:02:10 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::close;

use Moose;

use IO::Prompt;

# debugging...
#use Smart::Comments;

use namespace::clean -except => 'meta';

extends qw{ MooseX::App::Cmd::Command }; 

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Submitter';

our $VERSION = '0.10';

sub _sections { qw{ bugzilla branch close } }

sub run {
    my ($self, $opts, $args) = @_;
   
    $self->enable_logging;
    $self->app->startup_checks;

    my $bugs;
    
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

        do { print "$bug not ready to close.\n\n"; next BUG_LOOP }
            unless $bug->ready_for_closing;

        print "$bug has been approved, branched, and is ready to close.\n";

        if ($self->yes || prompt "Close $bug? ", -YyNn1) {

            $bug->close_nextrelease(comment => 'Thanks for the review! :-)');
            print "$bug closed.\n\n";
        }
        else { print "$bug NOT closed.\n\n" }
    }

    return;
}

sub _usage_format {
    return 'usage: %c close %o';
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Command::close - [submitter] close review tix

=head1 DESCRIPTION

Close a review tix you've submitted and had approved.

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



