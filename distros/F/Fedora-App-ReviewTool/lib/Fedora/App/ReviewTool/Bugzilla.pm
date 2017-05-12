#############################################################################
#
# Role to provide Bugzilla functionality to our command classes.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/06/2009 11:09:28 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Bugzilla;

use Moose::Role;

use Fedora::Bugzilla;
use Fedora::Bugzilla::PackageReviewBug;

use IO::Prompt;
use Term::ProgressBar;
use Term::Size;
use Text::SimpleTable;

# debugging
#use Smart::Comments '###', '####';

use namespace::clean -except => 'meta';

our $VERSION = '0.10';

has userid => (
    is            => 'rw',
    isa           => 'Str',
    #cmd_aliases  => 'u',
    documentation => 'bugzilla userid',
    lazy_build    => 1,
);

sub _build_userid { 
    my $self = shift @_;
    
    #my $def  = $self->app->has_email ? $self->app->email : q{};
    my $userid = prompt 
        "What's your bugzilla login email addy? ",
        -default => $self->app->email ? $self->app->email : q{}
        ;

    print "Thanks, $userid. You can set this permanently by running setup.\n";

    # force stringification
    return "$userid";
}

has passwd => (
    is            => 'rw',
    isa           => 'Str',
    lazy_build    => 1,
    documentation => 'bugzilla password',
);

sub _build_passwd { 
    my $self = shift @_;

    # if we're here, no password anywhere!
    my $pw = prompt 'Please enter your bugzilla password: ', -echo => '*';

    # force stringification
    return "$pw";
}

has _bz => (is => 'ro', isa => 'Fedora::Bugzilla', lazy_build => 1);

has _bz => (
    is => 'ro',
    isa => 'Fedora::Bugzilla',
    lazy_build => 1,
);

sub _build__bz {
    my $self = shift @_;

    my $bz;
    
    if ($Fedora::Bugzilla::VERSION <= 0.04) {

        # 0.04 and prior don't handle *_cb correctly
        $bz = Fedora::Bugzilla->new(
           userid => $self->userid, 
           passwd => $self->passwd,

           default_bug_class => 'Fedora::Bugzilla::PackageReviewBug',
        );
    }
    else {

        # note the use of _cb()'s
        $bz = Fedora::Bugzilla->new(
            userid_cb => sub { $self->userid }, 
            passwd_cb => sub { $self->passwd },

            default_bug_class => 'Fedora::Bugzilla::PackageReviewBug',
        );
    }

    # FIXME -- force a login until F::Bz deals with unauth. queries
    $bz->login;

    return $bz;
}

sub find_my_submissions {
    my $self = shift @_;

    my $bugs = $self->_bz->search(
        product    => 'Fedora', 
        component  => 'Package Review',
        version    => 'rawhide',
        bug_status => 'NEW,ASSIGNED',
        reporter   => $self->userid,
    );

    return $bugs;
}

sub find_all_my_submissions {
    my $self = shift @_;

    my $bugs = $self->_bz->search(
        product    => 'Fedora', 
        component  => 'Package Review',
        #version    => 'rawhide',
        #bug_status => 'NEW,ASSIGNED',
        reporter   => $self->userid,
    );

    return $bugs;
}

sub find_all_submissions {
    my $self = shift @_;

    my $bugs = $self->_bz->search(
        product    => 'Fedora', 
        component  => 'Package Review',
        #version    => 'rawhide',
        #bug_status => 'NEW,ASSIGNED',
        #reporter   => $self->userid,
    );

    return $bugs;
}

sub find_my_active_reviews {
    my $self = shift @_;

    my $bugs = $self->_bz->search(
        product    => 'Fedora', 
        component  => 'Package Review',
        version    => 'rawhide',
        bug_status => 'NEW,ASSIGNED',
        assigned_to   => $self->userid,

        'field0-0-0' => 'flagtypes.name',
        'type0-0-0'  => 'equals',
        'value0-0-0' => 'fedora-review?',
        'field0-0-1' => 'flagtypes.name',
        'type0-0-1'  => 'equals',
        'value0-0-1' => 'fedora-review+',
    );

    return $bugs;
}

sub find_bug_for_pkg {
    my $self = shift @_;
    my $pkg  = shift @_ or die "Must pass package name!";

    ### searching bugzilla for: $pkg

    my $bugs = $self->_bz->search(
        product   => 'Fedora', 
        component => 'Package Review',
        version   => 'rawhide',

        #bug_status =>  [ 'CLOSED' ],
        #bug_status => 'NEW,ASSIGNED,CLOSED',

        # hot dang!  this works!
        short_desc_type => 'substring',
        short_desc      => "$pkg",
    );

    ### found this many bugs: $bugs->num_bugs

    return wantarray ? $bugs->ids : $bugs->first_bug;

    # FIXME this is future... not going to sort it out right now; playing dumb
    
    if ($bugs->num_bugs == 1) {

        my $bug = $bugs->first_bug;

        #if (($bug->status eq 'CLOSED') && ($bug->resolution ne 'NEXTRELEASE')) {
        if ($bug->full_status eq 'CLOSED') {
        
            return $bug if $bug->resolution eq 'NEXTRELEASE';
            warn "A closed bug was found, but not NEXTRELEASE: $bug\n";

            return;
        }
    }

}
 
sub bug_table {
    my ($self, $bugs) = @_;
    
    # refactor to ::Bugs
    $bugs = Fedora::Bugzilla::Bugs->new(bz => $self->_bz, ids => [ "$bugs" ])
        if $bugs->isa('Fedora::Bugzilla::Bug');

    # figure out how much we have to play with
    my ($cols, $rows) = Term::Size::chars *STDOUT{IO};
    my $len = $cols - (6+1+1 + 3*3 + 2*2);

    ### doing submitted...
    my $t = Text::SimpleTable->new(
        [    6, 'Bug'           ],
        [    1, 'R'             ],
        [    1, 'C'             ],
        [ $len, 'Name'          ],
        #[ 20, 'Last Update'     ]
    );

    # Note this is still useful, even though we're gathering all the data
    # available through XML-RPC via one Bug.get() call, as our flags require
    # that we pull the XML representation of the bug as well.
    my $pbar = Term::ProgressBar->new({ 
        #count => $bugs->num_bugs,
        count => $bugs->num_ids,
        name  => 'Fetching bugzilla data',
        ETA   => 'linear',
    });
    my $i = 0;
    $pbar->update($i);

    #my $tz = DateTime::TimeZone->new('local' => 'x');
    my $tz = DateTime::TimeZone::Local->TimeZone();

    BUG_LOOP:
    for my $bug ($bugs->bugs) {

        my $pkg = $bug->package_name;

        my $name = "$pkg\n" 
            . '  ' . $bug->full_status . '; last changed: '
            . $bug->last_change_time->set_time_zone($tz) . "\n"
            . '  R: ' . $bug->reporter    . "\n"
            . '  A: ' . $bug->assigned_to 
            ;

        my $update = $bug->last_change_time . "\n  " . $bug->status;

        # add our table row
        $t->row(
            "$bug",
            $self->flag($bug, 'fedora-review'),
            $self->flag($bug, 'fedora-cvs'),
            $name,
            #$update
        );

        $pbar->update(++$i);
    }

    return $t->draw;
}


sub flag { 
    my ($self, $bug, $flag) = @_;

    return  $bug->has_flag($flag) 
          ? $bug->get_flag($flag) 
          : '*' 
          ;
}
         
=head2 _pick_srpm_uri(...)

Given one or more URI's, pick the newest one.

=cut

sub _pick_srpm_uri {
    my $self = shift @_;
    my @uris = @_;

    # FIXME probably a better way to do this
    my @abc = ('a'..'z');

    my $ret = prompt 'Please pick the correct URI...', -1, 
        -menu    => [ @uris ],
        -default => $abc[$#uris],
        ;

    return URI->new($ret);
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Bugzilla - bugzilla command role

=head1 SYNOPSIS

    package ...

    use Moose;
    extends ...;

    with 'Fedora::App::ReviewTool::Bugzilla;

    # profit!  (there's a lot of that around here)

=head1 DESCRIPTION

Provide a few common attributes / methods for working with Bugzilla.

=head1 ATTRIBUTES

=over 4

=item B<userid>

Bugzilla userid.

=item B<passwd>

Bugzilla passwd.

=item B<_bz>

The actual L<Fedora::Bugzilla> instance.

=back

=head1 SUBROUTINES/METHODS

=over 4

=item B<find_my_submissions>

Search for open tix under 'Fedora/Package Reviews' with b<userid> as the
reporter.

=item B<find_bug_for_pkg (pkg name)>

Given a package name, try to find a corresponding review tix.  Returns the bug
iff one and only one is found; undef if none is found.

If more than one review tix is found, the result is undefined.  This is a
known issue.

=head1 CONFIGURATION AND ENVIRONMENT

FIXME a bit about the config file would be nice

=head1 SEE ALSO

L<Fedora::App::ReviewTool>, L<Fedora::Bugzilla>.


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



