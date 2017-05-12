#############################################################################
#
# Super-simple representation of a Koji task
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 05/02/2009 08:59:28 PM PDT
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::KojiTask;

use Moose;

use MooseX::AttributeHelpers;
use MooseX::Types::URI ':all';

use English qw{ -no_match_vars };  # Avoids regex performance penalty

#use URI::Fetch;
use LWP::Simple;
use URI::Find;

use namespace::clean except => 'meta';

use overload '""' => sub { shift->uri }, fallback => 1;

our $VERSION = '0.10';

# for debugging
#use Smart::Comments '###', '####';

has uri => (is => 'ro', isa => Uri, required => 1, coerce => 1);

has task_id => (is => 'ro', isa => 'Int', lazy_build => 1);
sub _build_task_id { (my $x = shift->uri) =~ s/^.*taskID=//; return $x }

has _contents => (
    metaclass => 'Collection::List',
    
    is => 'ro', 
    isa => 'ArrayRef[Str]',
    lazy_build => 1,

    provides => {
        'empty'    => 'has_contents',
        'map'      => 'map_contents',
        'grep'     => 'grep_contents',
        'join'     => 'join_contents',
        'elements' => 'contents',
    },
);

sub _build__contents { [ split /\n/, LWP::Simple::get(shift->uri) ] }

has _uris => (
    metaclass => 'Collection::List',

    is  => 'ro',
    isa => 'ArrayRef[URI]',
    #coerce => 1,# FIXME subtype coercion needed for Uri to work?

    lazy_build => 1,

    provides => {
        'grep'     => 'grep_uris',
        'map'      => 'map_uris',
        'count'    => 'uri_count',
        'elements' => 'uris',
        'empty'    => 'has_uris',
        'first'    => 'first_uri',
        'last'     => 'last_uri',
        'get'      => 'get_uri',
    },
);

sub _build__uris { 
    my $self = shift @_;

    # creating our find object...
    #my @uris;
    #my $finder = URI::Find->new(sub { push @uris, URI->new($_[1]) });
    #my $content = $self->join_content(q{});
    #my $count = $finder->find(\$content);

    # bah. stupid relative links...
    my $base    = 'http://koji.fedoraproject.org/koji/';
    my $self_id = $self->task_id;
    my @uris =
        map  { URI->new("$base$_")          }
        map  { s/^.*href="//; s/".*$//; $_ }
        $self->grep_contents(sub { /<a href=/ })
        #$self->grep_contents(sub { /taskinfo\?taskID/ })
        #$self->grep_contents(sub { /taskinfo/ })
        ;

    ### @uris
    return \@uris;
}

has for_srpm => (is => 'ro', isa => 'Str', lazy_build => 1); 

sub _build_for_srpm {
    my $self = shift @_;

    my @title = 
        map  { $_ =~ s/^.*\(\s*//; $_ =~ s/\).*$//; $_ }
        $self->grep_contents(sub { /^\s*<title>/      })
        ;

    ### @title
    warn "More than one title?!" if @title != 1;

    my @parts = split /,\s+/, $title[0];
    return $parts[0] =~ /\.src\.rpm$/ ? $parts[0] : $parts[1];
}

has _child_tasks => (
    metaclass => 'Collection::List',

    is         => 'ro',
    isa        => 'ArrayRef[Fedora::App::ReviewTool::KojiTask]',
    lazy_build => 1,

    provides => {
        #'grep'     => 'grep_tasks',
        'elements' => 'tasks',
        'empty'    => 'has_tasks',
        'first'    => 'first_task',
    },
);

sub _build__child_tasks { 
    my $self = shift @_;
    
    my $self_id = $self->task_id;

    my @tasks = 
        map  { Fedora::App::ReviewTool::KojiTask->new(uri => $_) }
        grep { $_ !~ /$self_id$/                                 }
        $self->grep_uris(sub { /taskinfo\?taskID=/ }             )
        ;

    ### @tasks
    return \@tasks;
}

has build_log => (is => 'ro', isa => Uri, lazy_build => 1);
has root_log  => (is => 'ro', isa => Uri, lazy_build => 1);
has state_log => (is => 'ro', isa => Uri, lazy_build => 1);

sub _build_build_log { shift->_find_link(sub { /build\.log/ }) }
sub _build_root_log  { shift->_find_link(sub { /root\.log/  }) }
sub _build_state_log { shift->_find_link(sub { /state\.log/ }) }

has rpms => 
    (is => 'ro', isa => 'ArrayRef[URI]', lazy_build => 1, auto_deref => 1);
sub _build_rpms { [ shift->_find_links(sub { /\.rpm$/ }) ] }

sub _find_link { (shift->_find_links(@_))[0] }

sub _find_links {
    my ($self, $cref) = @_;

    my @uris = $self->grep_uris($cref); 
    @uris = $self->first_task->grep_uris($cref) if @uris == 0;

    ### @uris
    #return $uris[0];
    return @uris;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::KojiTask - Simple (temporary) koji task representation

=head1 DESCRIPTION

This is a very temporary, small class intended to make it a touch easier to
work with koji tasks, until such time as L<Fedora::Koji> is available.

=head1 SUBROUTINES/METHODS

TODO

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



