#############################################################################
#
# Set up our reviewtool.ini
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/18/2009 08:04:57 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::setup;

use Moose;

extends 'MooseX::App::Cmd::Command';

use Config::Tiny;
use IO::Prompt;
use LWP::UserAgent;

use namespace::clean -except => 'meta';

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Submitter';

# debugging
#use Smart::Comments '###', '####';

our $VERSION = '0.10';

sub _sections { }

sub run {
    my ($self, $opts, $args) = @_;

    print 'Setting up config for reviewtool v' .
        $Fedora::App::ReviewTool::VERSION . "\n\n";

    print "Checking our target reviewspace.\n";

    if (! $self->check_reviewspace_push) {
    
        print "We were unable to push to fedorapeople.\n";

        if ($self->yes || prompt 'Try to fix? ', -YyNn) {

            #$self->create_reviewspace_push;

            # build our command...
            (my $dest = $self->remote_loc) =~ s/^.*://;
            my $cmd = "ssh fedorapeople.org mkdir -p $dest";
            print "Attempting: $cmd\n";
            my $out = `$cmd`;

            # if we fail at this point, just die
            die "Error: $out\n" if $?;
            
            print "Success!\n"; 
        }
        else {

            die "No point continuing w/o a working push space.\n";
        }

    }

    print "\nChecking web accessibility of our target reviewspace.\n";

    if (! $self->check_reviewspace_web) {
        
        die 'Error pulling the remote URI. '
          . "We don't know how to fix this ATM.\n";
    }

    if ($self->configfile->stat) {

        #die $self->configfile . 
        #    " exists, and I don't handle that right now.\n";

        print "\nYou appear to have a ~/.reviewtool.ini already, "
            . "so setup is complete.\n\n"
            ;

        return;
    }

    print "Checking our bugzilla information...\n";

    my $c = Config::Tiny->new;

    $c->{bugzilla}->{userid} = prompt 
        "What's your bugzilla login email addy? ",
        -default => $self->app->email;
    
    $c->{bugzilla}->{passwd} = prompt "What's your bugzilla password? "
        if $self->yes || prompt 'Store bugzilla password? ', -YyNn;

    print "Writing out ~/.reviewtool.ini...\n";
    $c->write("$ENV{HOME}/.reviewtool.ini");
    chmod 0600, "$ENV{HOME}/.reviewtool.ini";

    print "\nYour config has been written out under ~/.reviewtool.ini. "
        . "You can edit this file directly if you so desire.\n\n"
        . "Done!\n"
        ;

    return;
}

sub check_reviewspace_web {
    my $self = shift @_;

    my $ua  = LWP::UserAgent->new;
    my $uri = $self->baseuri;

    # first, check to see if we can do a GET on it ok...
    print "Trying to pull $uri...\n";
    my $rsp = $ua->head($uri);

    if ($rsp->is_success) {

        print "Success!\n";
        return 1;
    }

    return;
}

sub check_reviewspace_push {
    my $self = shift @_;

    # try copying a trivial file to remote destination
    my $dest = $self->remote_loc;
    my $cmd = "scp /etc/fedora-release $dest";
    print "Trying: $cmd\n";
    system $cmd;

    # if $? is not undef, then some error occurred
    return if $?;

    print "Success!\n";
    return 1;
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Command::setup - do some initial setup magic

=head1 DESCRIPTION

We provide a "setup" command to do some initial configuration.

=head1 SUBROUTINES/METHODS

=head1 SEE ALSO

L<reviewtool>, L<Fedora::App::ReviewTool>.

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


