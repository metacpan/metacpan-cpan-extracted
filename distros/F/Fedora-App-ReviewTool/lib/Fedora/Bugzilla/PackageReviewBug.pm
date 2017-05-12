#############################################################################
#
# ...with some review-specific functionality.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/06/2009 08:03:25 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::PackageReviewBug;

use Moose;

extends 'Fedora::Bugzilla::Bug';

use Fedora::App::ReviewTool::KojiTask;

use namespace::clean -except => 'meta';

our $VERSION = '0.10';

my @defaults = (
    traits     => [ 'CascadeClear' ],
    is         => 'ro',
    clear_on   => 'data',
    lazy_build => 1,
);

# approved, rejected, open
has review_state => (@defaults, isa => 'Str');

has ready_for_branching => (@defaults, isa => 'Bool');
has ready_for_import    => (@defaults, isa => 'Bool');
has ready_for_closing   => (@defaults, isa => 'Bool');
has branched            => (@defaults, isa => 'Bool');
has approved            => (@defaults, isa => 'Bool');
has package_name        => (@defaults, isa => 'Str' );
has package_desc        => (@defaults, isa => 'Str' );

sub _build_review_state {
    my $self = shift @_;

    warn 'not implemented';
}

sub _build_ready_for_branching {
    my $self = shift @_;
    
    return 0 unless $self->approved;
    return 1 unless $self->has_flag('fedora-cvs');
    return 0;
}

# FIXME
sub _build_ready_for_import { shift->ready_for_closing }

sub _build_ready_for_closing {
    my $self = shift @_;

    return 1 if $self->branched && $self->approved;
    return 0;
}

sub _build_ready_for_review {
    my $self = shift @_;

    # FIXME....
}

sub _build_approved {
    my $self = shift @_;

    # FIXME should we implement a "strict" mode, that is, scan the last
    # comment for 'APPROVED'?

    # not ready unless we both have it and it's +
    if ($self->has_flag('fedora-review')) {
        
        return 1 if     $self->get_flag('fedora-review') eq '+';
        return 0;
     }

     # check for old-school style approvals
     return 1 if $self->blocks_bug(163779); # FE-ACCEPT
     return 1 if $self->blocks_bug(188268); # FC-ACCEPT
     return 0;
}

sub _build_branched {
    my $self = shift @_;

    # not ready unless we both have it and it's +
    return 0 unless $self->has_flag('fedora-cvs');
    return 1 if     $self->get_flag('fedora-cvs') eq '+';
    return 0;
}

#sub pkg_name_from_summary {
sub _build_package_name {
    my $self = shift @_;
    
    # Review Request: perl-WWW-Curl - Perl extension interface for libcurl
    # FIXME not happy with this first one, but WFN.
    (my $name = $self->summary) =~ s/^.+equest:\s*//;
    $name                       =~ s/\s+-.*$//;
    # just to make sure there's no whitespace kicking around
    $name                       =~ s/^\s*//;
    $name                       =~ s/\s*$//;

    return $name;
}

sub _build_package_desc {
    my $self = shift @_;

    (my $desc = $self->summary) =~ s/^.*\s-\s*//;
    return $desc;
}

has _koji_tasks => (
    metaclass => 'Collection::List',

    is         => 'ro',
    isa        => 'ArrayRef[Fedora::App::ReviewTool::KojiTask]',
    lazy_build => 1,
    #coerce => 1,# FIXME subtype coercion needed?

    provides => {
        #'grep'     => 'grep_uris',
        'empty'    => 'has_koji_tasks',
        'elements' => 'koji_tasks',
        'map'      => 'map_koji_tasks',
        'count'    => 'num_koji_tasks',
    },
);

# FIXME this'd be even simpler if we'd bother to define types/coercions
#sub _build__koji_tasks { shift->grep_uris(sub { /koji.*taskID=/ }) }
sub _build__koji_tasks { 
    my $self = shift @_;
    
    my @tasks = 
        map { Fedora::App::ReviewTool::KojiTask->new(uri => $_) }
        $self->grep_uris(sub { /koji.*taskID=/ })
        ;

    return \@tasks;
}

1;

__END__
=head1 NAME

Fedora::Bugzilla::PackageReviewBug - bug + some reviewing magic

=head1 SYNOPSIS

    # set as default bug class
    $bz->default_bug_class('Fedora::Bugzilla::PackageReviewBug');

    # get bugs as normal...
    my $bug = $bz->bug('perl-Moose');
    
    # profit!


=head1 DESCRIPTION

This is a small extension to Fedora::Bugzilla::Bug, providing a few
review-bug-specific methods / attributes.

=head1 SUBROUTINES/METHODS

An object of this class represents a package review bug.

=over 4

=item B<ready_for_branching>

Returns true if the flags indicate we're ready to branch.  The logic is pretty
primitive right now; basically just check to see fedora-review == + and
fedora-cvs isn't set (to anything).

=item B<ready_for_closing>

True if both branched() and approved() are true.  We should probably put some
sort of "imported and built" check in here?  Maybe?

=item B<package_name>

Takes the summary and extracts the package name from it.  Note we expect this
to be filled out in the bug correctly, though we do try to be a little
flexible here.

e.g. from:

    Review Request: perl-WWW-Curl - Perl extension...

we return:

    perl-WWW-Curl

=item B<package_desc>

The package description, also from the summary.  From the above example, this
would be "Perl extension...", where hopefully the "..." makes sense :-)

=item B<approved>

Basically just a shortcut to check for the existance of the fedora-review
flag, and then to make sure it's set to '+'.  True if this is the case, false
otherwise.

If fedora-review is not set (+/-/?) on the bug, we check to see if we block
either of the old-school blocker bugs: FE-ACCEPT and FC-ACCEPT.  If we block
either of those, then we're in an approved state.

=item B<branched>

True if we have fedora-cvs and it's '+'; false otherwise.

=back

=head1 SEE ALSO

L<Fedora::Bugzilla::Bug>.

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


