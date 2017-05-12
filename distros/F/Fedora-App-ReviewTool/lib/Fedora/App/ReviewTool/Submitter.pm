#############################################################################
#
# Role providing various methods for working with submitted package reviews
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/01/2009 01:56:32 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Submitter;

use Moose::Role;

use MooseX::Types::Path::Class qw{ File };
use MooseX::Types::URI qw{ Uri };

use Archive::RPM;
use Path::Class;
use Regexp::Common;

use namespace::clean -except => 'meta';

our $VERSION = '0.10';

has remote_loc => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Str',
    lazy_build    => 1,
    documentation => 'remote location to push files to',
);

sub _build_remote_loc { 'fedorapeople.org:public_html/review/' }

has baseuri => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => Uri,
    coerce        => 1,
    lazy_build    => 1,
    documentation => 'base uri of where the review files are',
);

sub _build_baseuri { 'http://fedorapeople.org/~' . shift->app->cn . '/review/' }

##
## Base packagename options
##

# given a srpm path, pull the info we need
sub get_pkg_info_from_srpm {
    my ($self, $srpm) = @_;
    
    my $pkg = { 
        name    => $srpm->name,
        srpm    => $srpm->rpm->absolute,  # P::C::File, right? :)
        nvr     => $srpm->nvr,
        summary => $srpm->summary,
        url     => $srpm->url,
        vr      => $srpm->v . '-' . $srpm->r,
    };

    my $desc = join '!%!', map { chomp; $_ } $srpm->description; 
    $pkg->{description} = $desc;

    return $pkg;
}

sub pack   { shift; join '!%!', @_                      }
sub unpack { shift; split /\|/, map { chomp; $_ } @_    }
sub repack { shift; my $l = shift; $l =~ s/!%!/\n/g; $l }

sub build_spec {
    my ($self, $srpm, $info) = @_;

    die "$srpm is not a SRPM!\n" unless $srpm->is_source;

    my ($spec) = $srpm->grep_files(sub { /\.spec$/ });
    return $spec;
}

sub push_to_reviewspace {
    my $self = shift @_;
   
    # push to reviewspace...
    my $cmd = 'scp ' . join(q{ }, @_) . ' ' . $self->remote_loc;
    system $cmd;

    die "Error executing '$cmd'\n\n$?"
        if $?;

    return;
}

sub gen_summary {
    my ($self, $srpm) = @_;

    my $name    = $srpm->name;
    my $summary = $srpm->summary;

    return "Review Request: $name - $summary";
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Submitter - methods to work with submitted reviews

=head1 DESCRIPTION

A L<Moose> role providing certain methods and attributes useful to commands
involving submitting packages for review.


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



