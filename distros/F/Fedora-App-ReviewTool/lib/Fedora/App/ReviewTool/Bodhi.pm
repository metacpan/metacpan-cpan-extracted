#############################################################################
#
# Simplistic "update submit" interface to Bodhi, until Fedora::Bodhi exists
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 04/12/2009 01:37:28 PM PDT
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Bodhi;

use Moose::Role;

use MooseX::Types::URI ':all';
use MooseX::AttributeHelpers;

use HTTP::Cookies;
use IO::Prompt;
use JSON::XS;
use LWP::UserAgent;
use URI;

use namespace::clean -except => 'meta';

# debug
#use Smart::Comments '###', '####';

our $VERSION = '0.01';

has _bodhi_uri => (is => 'rw', isa => Uri, lazy_build => 1, coerce => 1);
has _lwp       => (is => 'rw', isa => 'LWP::UserAgent', lazy_build => 1);
has _json      => (is => 'ro', isa => 'JSON::XS',       lazy_build => 1);

sub _build__bodhi_uri  { 'https://admin.fedoraproject.org/updates' }
sub _build__lwp  { LWP::UserAgent->new(cookie_jar => { })    }
sub _build__json { JSON::XS->new->pretty                     }

has fas_userid => (
    is => 'ro', isa => 'Str', lazy_build => 1, 
    documentation => 'FAS userid',
);

has fas_passwd => (
    is => 'ro', isa => 'Str', lazy_build => 1,
    documentation => 'FAS password',
);

sub _build_fas_userid {
    my $self = shift @_;

    # go with the default if we're instructed to not prompt
    return $self->app->cn if $self->yes;

    my $uid = prompt 
        'Please enter your FAS userid:   ', 
        -default => $self->app->cn
        ;

    return "$uid";
}

sub _build_fas_passwd {
    my $self = shift @_;

    # if we're here, no password anywhere!
    my $pw = prompt 'Please enter your FAS password: ', -echo => '*';
    return "$pw";
}

sub submit_bodhi {
    my $self = shift @_;
    my $path = shift @_;
    
    my $uri = $self->_bodhi_uri->clone;
    $uri->path($uri->path . "/$path");
    $uri->query_form(
        user_name => $self->fas_userid, 
        password  => $self->fas_passwd, 
        login     => 'Login',
        @_,
    );

    return $self->_get($uri);
}

sub submit_bodhi_newpackage {
    my ($self, $build) = @_;

    # NOTE no support for multiple builds, but then, this is a new package
    # release.

    $self->submit_bodhi(
        'save',
        builds          => $build,
        request         => 'stable',
        notes           => 'New package for this release',
        suggest_reboot  => 0,
        close_bugs      => 0,
        unstable_karma  => -3,
        stable_karma    => 3,
        inheritance     => 0,
        bugs            => q{},
        type_           => 'newpackage',
    );
    
    return;
}

sub _get {
    my $self = shift @_;
    my $uri  = shift @_;

    my $r = $self->_lwp->get($uri, Accept => 'text/javascript', @_);
    confess 'Error: ' . $r->as_string if $r->is_error;

    # FIXME might not be exactly what we want to do...
    my $content = $r->content;
    eval { $content = $self->_json->decode($r->content); };
    ### $content
    return $content;
}


# FIXME just to make things easier for a second...
has _packagers => (
    metaclass => 'Collection::Hash',
    isa        => 'HashRef',
    is         => 'ro', 
    lazy_build => 1,

    provides => {
        'empty'  => 'has_packagers',
        'exists' => 'has_packager',
        'count'  => 'num_packagers',
        'get'    => 'packager_info',
        # more!
    },
);

sub _build__packagers {
    my $self = shift @_;

    ### building _packagers...

    my $uri = URI->new('https://admin.fedoraproject.org/accounts/group/dump/packager');

    $uri->query_form(
        user_name => $self->fas_userid, 
        password  => $self->fas_passwd, 
        login     => 'Login',
    );

    ### hrm: "$uri"

    my $raw_data = $self->_get($uri);
    my %byemail = map { $_->[1] => $_ } @{ $raw_data->{people} };
    return \%byemail;
    #return $self->_get($uri);
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Bodhi - primitive bodhi update submit for reviewtool

=head1 SYNOPSIS

    with 'Fedora::App::ReviewTool::Bodhi';

    # ...
    $self->submit_bodhi_newpackage('perl-Foo-1.2.3-1.fc11');


=head1 DESCRIPTION

This is a L<MooseX::Role> for L<reviewtool>'s command classes that provides a
very simplistic and limited subset of Bodhi functionality...  Just enough to
create a new package update.

It is anticipated that this will be replaced at some point in the
not-too-distant future by L<Fedora::Bodhi>.

=head1 METHODS

=over 4

=item <fas_userid>

=item <fas_passwd>

=item <submit_bodhi_newpackage>

=item <submit_bodhi>

=back

=head1 CONFIGURATION AND ENVIRONMENT

We attempt to load our FAS userid/passwd from the config file (typically
~/.reviewtool.ini).  Failing this, we prompt the user.

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



