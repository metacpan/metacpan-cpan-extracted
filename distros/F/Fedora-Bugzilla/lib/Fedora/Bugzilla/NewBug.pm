#############################################################################
#
# An interface to Fedora's Bugzilla. 
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 12/29/2008 11:06:54 AM PST
#
# Copyright (c) 2008 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::NewBug;

use Moose;
use MooseX::StrictConstructor;
use MooseX::AttributeHelpers;

use Moose::Util::TypeConstraints;
use MooseX::Types::URI qw{ Uri };
use MooseX::Types::DateTime qw{ DateTime };

use namespace::clean -except => 'meta';

our $VERSION = '0.13';

########################################################################
# our types / coercions

########################################################################
# required attributes 

# we define our attributes here, 1) so we can to type checking and coercion,
# 2) so we can define different types of newbugs :)

has product => (
    is         => 'rw',
    isa        => 'Str',   # FIXME do we want to validate too?
    required   => 1,
    predicate  => 'has_product',
);

has component => (
    is         => 'rw',
    isa        => 'Str',   # FIXME do we want to validate too?
    required   => 1,
    predicate  => 'has_component',
);

has summary => (
    is         => 'rw',
    isa        => 'Str',   # FIXME do we want to validate too?
    required   => 1,
    predicate  => 'has_summary',
);

has version => (
    is         => 'rw',
    isa        => 'Str',   # FIXME do we want to validate too?
    required   => 1,
    predicate  => 'has_version',
);

########################################################################
# optional attributes 


########################################################################
# actual bug attributes 

# note we provide builders here, even when we're just returning them as
# 'undef', as this will make it easier to subclass and override them.

my @defaults = (is => 'rw', lazy_build => 1, isa => 'Maybe[Str]');

has alias => (
    is   => 'rw',
    isa  => 'Maybe[Str]',
    lazy_build => 1,
);
sub _build_alias { undef }

my @attrs = qw{ 
        dependson assigned_to comment version op_sys platform 
        severity priority blocked 
    };

has [ @attrs ] => (is => 'rw', lazy_build => 1, isa => 'Maybe[Str]');

has bug_file_loc => (
    is => 'rw', 
    isa => Uri, 
    coerce => 1, 
    lazy_build => 1,
);

# some sensible defaults, too
sub _build_version      { undef }
sub _build_op_sys       { undef }
sub _build_platform     { undef }
sub _build_severity     { undef }
sub _build_priority     { undef }
sub _build_blocked      { undef }
sub _build_dependson    { undef }
sub _build_bug_file_loc { undef }

sub url { shift->bug_file_loc(@_) }

########################################################################
# create a hashref capable of being passed to Bugzilla.create_bug() 

sub bughash {
    my $self = shift @_;

    # get all our attributes (including parent classes if we're subclassed)
    my @all_attrs = $self->meta->get_all_attributes;
    my @atts;

    for my $att (@all_attrs) {

        my $has = 'has_' . $att->name;
        push @atts, $att->name
            if $self->$has;
    }

    #my %data = map { $_ => $self->$_ } @atts;
    my %data = map { my $v = $self->$_; $_ => $v } @atts;

    ### %data

    return \%data;
}

########################################################################
# magic end bits 

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::Bugzilla::NewBug - New bug class


=head1 SYNOPSIS

    use Fedora::Bugzilla;

    my $bz = Fedora::Bugzilla->new(...);

    # fetch a bug
    my $bug1 = $bz->get_bug('123456');
    my $bug2 = $bz->get_bug('perl-Moose');

    # etc


=head1 DESCRIPTION

This is a class representing the required elements of a new bug in the 
Bugzilla system.

It can be subclassed to provide default values for different "types" of
classes, e.g. package review bugs are always going to have certain values
defaulted in certain ways.

=head1 INTERFACE

"Release Early, Release Often"

I've tried to get at least the methods I use in here.  I know I'm missing
some, and I bet there are others I don't even know about... I'll try not to,
but I won't guarantee that I won't change the api in some incompatable way.
If you'd like to see something here, please either drop me a line (see AUTHOR) 
or better yet, open a rt ticket with a patch ;)

=head2 METHODS

=over 4

=item B<new()>

=back

=head3 REQUIRED ATTRIBUTES

=over 4

=item I<product>

=item I<component>

=item I<summary>

=item I<version>

=back

=head3 OPTIONAL ATTRIBUTES

=over 4 

=item I<status>

=item I<version>

=item I<op_sys>

=item I<platform>

=item I<severity>

=item I<priority>

=item I<blocked>

=item I<bug_file_loc>

Aka the "URL".

=back

=head1 BUGS AND LIMITATIONS

There are still many common attributes we do not handle yet. 
If you'd like to see something specific in here, please make a feature
request.

Please report any bugs or feature requests to
C<bug-fedora-bugzilla@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<http://www.bugzilla.org>, L<http://bugzilla.redhat.com>,
L<http://python-bugzilla.fedorahosted.org>, the L<WWW::Bugzilla3> module.

=head1 AUTHOR

Chris Weyl  C<< <cweyl@alumni.drew.edu> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Chris Weyl C<< <cweyl@alumni.drew.edu> >>.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free 
Software Foundation; either version 2.1 of the License, or (at your option) 
any later version.

This library is distributed in the hope that it will be useful, but WITHOUT 
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
OR A PARTICULAR PURPOSE.

See the GNU Lesser General Public License for more details.  

You should have received a copy of the GNU Lesser General Public License 
along with this library; if not, write to the 

    Free Software Foundation, Inc., 
    59 Temple Place, Suite 330, 
    Boston, MA  02111-1307 USA

