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

package Fedora::Bugzilla::Bug;

use Moose;

use MooseX::AttributeHelpers;
use MooseX::CascadeClearing;
use Moose::Util::TypeConstraints;
use MooseX::Types::DateTimeX qw{ DateTime };
use MooseX::Types::Path::Class;
use MooseX::Types::URI;

use Path::Class;
use URI::Fetch;
use URI::Find;
use XML::Twig;

use Fedora::Bugzilla::Types ':all'; 
use Fedora::Bugzilla::Bug::Flag;
use Fedora::Bugzilla::Bug::Comment;
use Fedora::Bugzilla::Bug::Attachment;
use Fedora::Bugzilla::Bug::NewAttachment;

# debugging
#use Smart::Comments '###', '####';

use namespace::clean -except => 'meta';

use overload '""' => sub { shift->id }, fallback => 1;

our $VERSION = '0.13';

########################################################################
# parent Fedora::Bugzilla 

has bz => (is => 'ro', isa => 'Fedora::Bugzilla', required => 1);

########################################################################
# Handle the alias on construction correctly 

around BUILDARGS => sub {
    my $orig  = shift @_;
    my $class = shift @_; 
    
    ### in BUILDARGS...
    ##### @_

    if (@_ > 1 || ref $_[0] eq 'HASH') {

        my $args = @_ > 1 ? { @_ } : $_[0];

        if (exists $args->{alias}) {
            
            $args->{_aliases} = { $args->{alias} => 1 };
            delete $args->{alias};
            ##### $args
            return $class->$orig($args);
        }
    } 

    return $class->$orig(@_); 
}; 

########################################################################
# data: the meat of it 

# The data attibute contains the raw hashref returned by Bugs.get_bugs. Note
# that if any updates are made, this is NOT the place to do it; update() pulls
# the new values from the attributes themselves, NOT this hash.

has data =>
    (is => 'ro', isa => 'HashRef', lazy_build => 1, is_clear_master => 1);

sub _build_data {
    my $self = shift @_;

    # prefer id over alias
    my $emsg = 'Neither bug id nor alias has been provided';
    my $bug_id = $self->has_id       ? $self->id 
               : $self->_has_aliases ? $self->alias
               :                       confess $emsg
               ;

    my $ret_hash = $self->bz->rpc->simple_request(
        'Bug.get_bugs',
        { ids => [ $bug_id ] }
    );

    return $ret_hash->{bugs}->[0];
}
    
# force a reload from bugzilla by clearing data
sub refresh { shift->clear_data }

# set true when we need to do an update
has dirty => (
    clear_master => 'data',
    clearer  => 'clear_dirty',
    is       => 'rw', 
    isa      => 'Bool', 
    default  => 0,
);

# tag an attribute to update; mark the object as changed but not updated.
# this sub is the trigger used by all rw attributes
sub _dirty_trigger  {
    my ($self, $new_value, $meta) = @_;

    ### $new_value
    ### $meta

    # FIXME not exactly sure...
    return unless $meta;

    $self->dirty(1);
    $self->_to_update($meta->name);
}

# update the dirty values in bugzilla; mark clean and purge old data
sub update {
    my $self = shift @_;

    # only if we have something to update...
    return if not $self->dirty;

    # force stringification
    my %updates = 
        #map { my $x = $self->$_ || q{}; $_ => "$x" } $self->_update_these;
        map { my $x = $self->$_ || q{}; $_ => blessed $x ? "$x" : $x } $self->_update_these;
    
    ### %updates

    my $ret = $self->bz->rpc->simple_request(
        'Bug.update',
        {
            ids     => [ $self->id ],
            updates => \%updates,
        }
    );

    # clear our old data (force a reload), etc.
    $self->clear_data;
    $self->clear_dirty;

    # FIXME should probably figure out something better to return
    return $ret;
}

########################################################################
# some defaults to help make things a little easier :) 

# default attribute attributes :-)
my @defaults = (
    clear_master   => 'data',
    is         => 'ro', 
    isa        => 'Str', 
    lazy_build => 1,
);

my @rw_defaults = ( 
    clear_master   => 'data',

    is         => 'rw', 
    isa        => 'Str', 
    lazy_build => 1, 
    trigger    => \&_dirty_trigger,
);

my @dt_defaults = (
    clear_master   => 'data',

    is         => 'ro', 
    # FIXME hm.
    #isa        => BugzillaDateTime, 
    isa        => DateTime, 
    lazy_build => 1,
    coerce     => 1,
);

########################################################################
# actual bug attributes 

has id => ( 
    # seems to fail at mixing in existing metaclass traits??
    #traits    => [ 'MooseX::MultiInitArg::Trait' ],
    traits    => [ 
        'MooseX::MultiInitArg::Trait',
        'MooseX::CascadeClearing::Role::Meta::Attribute',
        #'MooseX::AttributeHelpers::Trait::Collection::List',
    ],
    init_args => [ 'bug_id' ],
    clear_master  => 'data',
    is        => 'ro', 
    isa       => 'Int', 
    lazy      => 1, 
    builder   => '_build_id',
    predicate => 'has_id',
);

# if this gets called, we're betting alias has been set
sub _build_id {
    my $self = shift @_;

    confess 'Must set either id or alias!'
        if not $self->_has_aliases;

    return $self->data->{id};
}

has _aliases => (
    traits     => [ 
        'MooseX::AttributeHelpers::Trait::Collection::Hash',
    ],
    is         => 'rw',
    #isa        => 'ArrayRef[Str20]',
    isa        => 'HashRef',
    lazy_build => 1,
    trigger    => \&_dirty_trigger,

    provides => {
        count  => 'num_aliases',
        keys   => 'aliases',
        #add    => 'add_alias',
        set    => 'add_alias',
        delete => 'delete_alias',
        exists => 'has_alias',
        empty  => 'has_aliases',
    },
);

# we should warn, but I haven't actually seen any multi-alias bugs yet
#sub alias { ($_[0]->aliases)[0] if $_[0]->has_aliases }
sub alias { 
    my ($self, $value) = @_;

    $self->_aliases({ $value => 1 }) if defined $value;
    return ($_[0]->aliases)[0] if $_[0]->has_aliases; 
}

#sub _build__aliases { { map { $_ => 1 } @{shift->data->{alias}} } }
sub _build__aliases { 

    my $self = shift @_;
    my $data = $self->data->{alias};

    ### $data
    return { map { $_ => 1 } @{$self->data->{alias}} };
}

#sub __builder { shift->data->{shift} }
#sub __internals_builder { shift->data->{internals}->{shift} }

########################################################################
# our "non-internals" values

has summary => (
    @rw_defaults, 

    # seems to fail at mixing in existing metaclass traits??
    #traits    => [ 'MooseX::MultiInitArg::Trait' ],
    traits    => [ 
        'MooseX::MultiInitArg::Trait',
        'MooseX::CascadeClearing::Role::Meta::Attribute',
        #'MooseX::AttributeHelpers::Trait::Collection::List',
    ],
    init_args => [ 'bug_id' ],
    init_args => [ 'short_desc' ],
    clear_master  => 'data',

    is         => 'rw', 
    isa        => 'Str', 
    lazy_build => 1, 
    trigger    => \&_dirty_trigger,
);

sub _build_summary { shift->data->{summary} }

has creation_time    => (@dt_defaults);
has last_change_time => (@dt_defaults);

sub _build_creation_time    { shift->data->{creation_time}    }
sub _build_last_change_time { shift->data->{last_change_time} }

########################################################################
# internals values... most of them

has reporter    => (@defaults, isa => EmailAddress, coerce => 1);
has reporter_id => (@defaults);  

sub _build_reporter    { shift->data->{internals}->{reporter}    }
sub _build_reporter_id { shift->data->{internals}->{reporter_id} }

has bug_status   => (@rw_defaults);
has resolution   => (@rw_defaults);
has bug_file_loc => (@rw_defaults);
has version      => (@rw_defaults);
has assigned_to  => (@rw_defaults, isa => EmailAddress, coerce => 1);
has qa_contact   => (@rw_defaults, isa => EmailAddress, coerce => 1);
has full_status  => (@defaults);

sub status              { shift->bug_status(@_)                     }
sub url                 { shift->bug_file_loc(@_)                   }

sub _build_bug_status   { shift->data->{internals}->{bug_status}    }
sub _build_resolution   { shift->data->{internals}->{resolution}    }
sub _build_bug_file_loc { shift->data->{internals}->{bug_file_loc}  }
sub _build_version      { shift->data->{internals}->{version}       }
sub _build_assigned_to  { shift->data->{internals}->{assigned_to}   }
sub _build_qa_contact   { shift->data->{internals}->{qa_contact}    }

sub _build_full_status {
    my $self = shift @_;

    my $status = $self->status;
    return $status if $status ne 'CLOSED';

    return "$status/" . $self->resolution;
}
    
has _update_these => (
    traits => [ 'MooseX::AttributeHelpers::Trait::Collection::Array' ],

    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    clear_master   => 'data',
    lazy       => 1,
    auto_deref => 1,

    clearer => '_clear_update_these',
    default => sub { [] },

    provides => {
        'push'  => '_to_update',
        'count' => '_num_to_update',
        # FIXME map for actual update?
    },
);

########################################################################
# XML-bits

# Alas, some things we can still only get at through the XML "bug dump".
# We try to make life a little easier by on-demand loading and parsing these
# particular bits.

has xml => (
    clear_master    => 'data',
    is_clear_master => 1,
    is              => 'ro', 
    isa             => 'Str', 
    lazy_build      => 1,
);

sub _build_xml {
    my $self = shift @_;

    # FIXME we can probably separate this out a little better...
    my $uri = 
        'https://bugzilla.redhat.com/show_bug.cgi?ctype=xml&id=' .
        $self->id
        ;
   
    # FIXME caching would be nice...
    my $res = URI::Fetch->fetch($uri, UserAgent => $self->bz->ua);

    die 'Cannot fetch XML?! ' . URI::Fetch->errstr
        unless $res;
    
    return $res->content;
}

# parse and build the twig on demand
has twig => (
    clear_master   => 'xml',
    is         => 'ro', 
    isa        => 'XML::Twig', 
    lazy_build => 1,
);

sub _build_twig { XML::Twig->new->parse(shift->xml) }

sub _from_atts {
    my ($self, $tag_name) = @_;

    my @atts = $self->twig->root->find_by_tag_name($tag_name);

    my @vals = ();  # just in case @atts == 0
    for my $att (@atts) { push @vals, $att->text }

    return \@vals;
}

# <flag name="fedora-review" status="+" setter="kwizart@gmail.com" />

has _flags => (
    traits => [ 'MooseX::AttributeHelpers::Trait::Collection::ImmutableHash' ],

    clear_master => 'xml',

    is  => 'ro',
    isa => 'HashRef[Fedora::Bugzilla::Bug::Flag]',

    lazy       => 1,
    auto_deref => 1,
    builder    => '_build__flags',
    clearer    => 'clear_flags',
    predicate  => '_has__flags',

    provides => {
        'empty'  => 'has_flags',
        'get'    => 'get_flag',
        'count'  => 'flag_count',
        'exists' => 'has_flag',
        'keys'   => 'flag_names',
        'values' => 'flags',
        'kv'     => 'flag_pairs',
    },
);

# name:   $flags[0]->att('name') 
# status: $flags[0]->att('status') 
# setter: $flags[0]->att('setter') 

sub _build__flags {
    my $self = shift @_;

    # <flag name="fedora-review" status="+" setter="kwizart@gmail.com" />

    # find our flag elements (if any)
    my @flags = $self->twig->root->find_by_tag_name('flag');

    # construct our hash: flag_name => flag_status
    #my %f = map { $flags[0]->att('name') => $flags[0]->att('status') } @flags;
    
    my %f = 
        map { 
            $_->att('name') => Fedora::Bugzilla::Bug::Flag->new(
                name   => $_->att('name'),
                status => $_->att('status'),
                setter => $_->att('setter'),
                )
            } @flags
        ;

    return \%f;
}

has _uris => (
    traits => [ 'MooseX::AttributeHelpers::Trait::Collection::List' ],
    
    # I think this should "just work"
    clear_master   => 'xml',

    is  => 'ro',
    isa => 'ArrayRef[URI]',
    #coerce => 1,# FIXME subtype coercion needed for Uri to work?

    auto_deref => 1,
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
    my @uris;
    my $finder = URI::Find->new(sub { push @uris, URI->new($_[1]) }); 

    my $raw_xml = $self->xml;
    my $count = $finder->find(\$raw_xml);

    ### $@uris

    return \@uris;
}

has _comments => (
    traits => [ 'MooseX::AttributeHelpers::Trait::Collection::List' ],
    
    clear_master => 'xml',

    is         => 'ro',
    isa        => 'ArrayRef[Fedora::Bugzilla::Bug::Comment]',
    lazy_build => 1,

    provides => {
        'count'    => 'comment_count',
        'get'      => 'get_comment',
        'first'    => 'first_comment',
        'last'     => 'last_comment',
        'grep'     => 'grep_comments',
        'map'      => 'map_comments',
        'elements' => 'comments',
        'empty'    => 'has_comments',
        #...
    },
);

sub _build__comments {
    my $self =  shift @_;

    # get all our elements...
    my @elements = $self->twig->root->find_by_tag_name('long_desc');

    my $i = 1;

    my @comments = 
        map { 
            Fedora::Bugzilla::Bug::Comment
                ->new(
                    bug    => $self,
                    twig   => $_,
                    number => $i++,
                );
            } @elements
        ;
    
    return \@comments;
}

has _attachments => (
    traits => [ 'MooseX::AttributeHelpers::Trait::Collection::List' ],
    
    clear_master => 'xml',

    is         => 'ro',
    isa        => 'ArrayRef[Fedora::Bugzilla::Bug::Attachment]',
    lazy_build => 1,

    provides => {
        'empty'    => 'has_attachments',
        'elements' => 'attachments',
        'count'    => 'attachment_count',
        'get'      => 'get_attachment',
        'first'    => 'first_attachment',
        'last'     => 'last_attachment',
        'grep'     => 'grep_attachments',
        'map'      => 'map_attachments',
        #...
    },
);

sub _build__attachments {
    my $self =  shift @_;

    # get all our elements...
    my @elements = $self->twig->root->find_by_tag_name('attachment');

    my $i = 1;

    my @comments = 
        map { 
            Fedora::Bugzilla::Bug::Attachment
                ->new(
                    bug    => $self,
                    _twig  => $_,
                    number => $i++,
                );
            } @elements
        ;
    
    return \@comments;

}

has _dependson => (
    traits => [ 'MooseX::AttributeHelpers::Trait::Collection::Bag' ],
    clear_master   => 'xml',
    # FIXME trigger on set needed
    is         => 'ro', 
    isa        => 'Bag', 
    auto_deref => 1,
    # right now, use of lazy_build or builder is broken with this metaclass
    #lazy_build => 1,
    default   => sub { shift->_build__dependson },
    clearer   => '_clear__dependson',
    predicate => '_has__dependson',
    lazy      => 1,

    provides => {
        'empty'  => 'depends_on_anything',
        'count'  => 'num_deps',
        'exists' => 'depends_on_bug',
        'keys'   => 'all_dependent_bugs',
    },
);

has _blocked => (
    traits => [ 'MooseX::AttributeHelpers::Trait::Collection::Bag' ],
    clear_master   => 'xml',
    # FIXME trigger on set needed
    is         => 'ro', 
    isa        => 'Bag', 
    auto_deref => 1,
    # right now, use of lazy_build or builder is broken with this metaclass
    #lazy_build => 1,
    default   => sub { shift->_build__blocked },
    clearer   => '_clear__blocked',
    predicate => '_has__blocked',
    lazy      => 1,

    provides => {
        'empty'  => 'blocks_anything',
        'count'  => 'num_blocked',
        'exists' => 'blocks_bug',
        'keys'   => 'all_blocked_bugs',
    },
);

sub _build__dependson 
    { return { map { $_ => 1 } @{ shift->_from_atts('dependson') } } }
sub _build__blocked   
    { return { map { $_ => 1 } @{ shift->_from_atts('blocked')   } } }

has cc_list => (
    traits => [ 'MooseX::AttributeHelpers::Trait::Collection::List' ],

    clear_master => 'xml',

    is  => 'ro',
    #isa => 'ArrayRef[EmailAddress]',
    isa => 'ArrayRef[Email::Address]',
    auto_deref => 1,
    #coerce => 1,
    lazy_build => 1,

    provides => {

        'count' => 'num_emails_on_cc',
        'find'  => 'is_email_on_cc',
        'grep'  => 'grep_cc_emails',
        # ...
    },
);

sub _build_cc_list { 
    [ 
        map { my @a = Email::Address->parse($_); pop @a } 
            @{ shift->_from_atts('cc') } 
    ] 
}

########################################################################
# methods getting or setting various non-attribute bits 

# bugzilla.updateFlags
sub set_flags {
    my $self = shift @_;

    my %flags = @_;

    $self->bz->rpc->simple_request(
        'bugzilla.updateFlags',
        $self->id,
        \%flags,
    );

    $self->clear_data;

    return;
}

sub set_flag { shift->set_flags(@_) }

# Bug.add_comment
sub add_comment {
     my ($self, $comment) = @_;

     # FIXME: filter the return value...?
     $self->bz->rpc->simple_request(
         'Bug.add_comment',
         { id => $self->id, comment => $comment }
     );

     $self->clear_data;
}

# bugzilla.closeBug
sub close {
    my $self       = shift @_;
    my $resolution = shift @_ || confess 'Must pass a resolution';

    # everything else is named
    my %args = @_;

    $self->bz->rpc->simple_request(
        'bugzilla.closeBug',
        $self->id,
        uc $resolution,
        $self->bz->userid, q{}, # userid, psw -- not needed
        $args{dupeid},          # only if DUPLICATE 
        $args{fixedin},
        $args{comment},
        $args{isprivate},       # a private comment in a public bug
        $args{private_in_it},   # private in "issue tracker" (?)
        $args{nomail}
    );

    $self->clear_data;
}

sub close_nextrelease { shift->close('NEXTRELEASE', @_)            }
sub close_notabug     { shift->close('NOTABUG', @_)                }
sub close_dupe        { shift->close('DUPLICATE', dupeid => shift) }

sub set_status {
    my $self   = shift @_;
    my $status = shift @_ || confess 'Must pass a status';

    my %args = @_;

    $self->bz->rpc->simple_request(
        'bugzilla.changeStatus',
        $self->id,
        $status,
        $self->bz->userid,
        q{},
        $args{comment},
        $args{private},
        $args{private_in_it},
        $args{nomail}
    );

    $self->clear_data;

    return;
}

sub status_open { shift->set_status('OPEN', @_) }

# bugzilla.addAttachment 
sub add_attachment {
    my $self = shift @_;

    my $na = (blessed $_[0] && $_[0]->isa('Fedora::Bugzilla::NewAttachment'))
           ? shift @_
           : Fedora::Bugzilla::Bug::NewAttachment->new(@_)
           ;

    # make sure it's slurped...
    $na->data unless $na->has_data;

    my $id = $self->_create_attachment($na->to_hash);

    # call our clearers; only return the attachment if we're looking for it
    $self->clear_data;
    return $self->last_attachment if defined wantarray;
}

sub _create_attachment { 
    my ($self, $data_href) = @_;    

    my $foo = $self
        ->bz
        ->rpc
        ->simple_request('bugzilla.addAttachment', $self->id, $data_href)
        ;

    ### $foo
    return shift @$foo;
}

########################################################################
# magic end bits 

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::Bugzilla::Bug - Bug class


=head1 SYNOPSIS

    use Fedora::Bugzilla;

    my $bz = Fedora::Bugzilla->new(...);

    # fetch a bug
    my $bug1 = $bz->get_bug('123456');
    my $bug2 = $bz->get_bug('perl-Moose');

    # etc


=head1 DESCRIPTION

This is a class representing a bug in the Bugzilla system.  You can get bug
information, set info, attach files, add comments, etc...

=head1 INTERFACE

"Release Early, Release Often"

I've tried to get at least the methods I use in here.  I know I'm missing
some, and I bet there are others I don't even know about... I'll try not to,
but I won't guarantee that I won't change the api in some incompatable way.
If you'd like to see something here, please either drop me a line (see AUTHOR) 
or better yet, open a trac ticket with a patch ;)

=head1 BUG CREATION, SEARCHING AND RETRIEVAL

For bug creation, please see L<Fedora::Bugzilla> for the creation methods, and
L<Fedora::Bugzilla::NewBug> for the required attributes.

Fedora::Bugzilla also contains the methods to search for and retrieve bugs.

=head1 METHODS

=over

=item B<new()>

Really, you should never call this.  Let your $bz instance handle this.

=back

=head1 ACCESSORS

For the accessors/attributes listed below marked as [r/w], you can set a new
value and update the bug when ready by calling update().

=over

=item B<id>

The bug id.  This class also stringifies to this value.

=item B<alias> [r/w]

The alias of this bug, if any.

=item B<summary> [r/w]

The bug summary (short_desc).

=item B<creation_time>

=item B<last_change_time>

=item B<reporter>

L<Email::Address> of the person / account that filed the bug.

=item B<reporter_id>

Internal Bugzilla id of the reporter (Int).

=item B<bug_status> [r/w] 

=item B<status> [r/w]

Alias for bug_status().

=item B<resolution> [r/w]

=item B<bug_file_loc> [r/w]

=item B<url> [r/w]

Alias for bug_file_loc().

=item B<version> [r/w]

=item B<assigned_to> [r/w]

L<Email::Address> of the assignee.

=item B<qa_contact> [r/w]

L<Email::Address> of the qa_contact for this bug.

=item B<full_status>

"NEW", "ASSIGNED", "CLOSED/NEXTRELEASE", etc.

=back

=head1 ASSIGNMENT

=head2 Accessors

=over

=item B<>

=back

=head2 Methods

=over

=item B<>

=back

=head1 STATUS

=head2 Accessors

=over

=item B<>

=back

=head2 Methods

=over

=item B<close>

=item B<close_nextrelease([Str])> 

=item B<close_notabug([Str])> 

=item B<close_dupe( ... )>

=item B<set_status( ... )>

=back

=head1 COMMENTS

See also L<Fedora::Bugzilla::Bug::Comment>; comments are ordered as one would
expect.

=head2 Accessors

=over

=item B<comments>

Returns an array of Fedora::Bugzilla::Bug::Comment objects representing the
bug's comments.

=item B<comment_count>

Returns the number of comments.

=item B<get_comment([Int])>

Return the comment; e.g. $bug->get_comment(5) would get comment #5.

=item B<first_comment>

Fetch the first comment.

=item B<last_comment>

Fetch the last comment.

=back

=head2 Methods

=over

=item B<add_comment([Str])>

Adds a comment to the bug.   (This calls the XML-RPC method directly; it is
not necessary to call update().)

=item B<has_comments>

True if we've already generated our list of comments from the bug.  Note 
this should not be used to determine if the bug has any comments; use
comment_count() for that.

=item B<clear_comments>

Clear our comments data and force it to be rebuilt the next time we need it.

=back

=head1 BUGS WE DEPEND ON

=head2 Accessors

=over

=item B<>

=back

=head2 Methods

=over

=item B<>

=back

=head1 BLOCKED BUGS

=head2 Accessors

=over

=item B<>

=back

=head2 Methods

=over

=item B<>

=back

=head1 FLAGS

See also L<Fedora::Bugzilla::Bug::Flag>.  Flag data is currently parsed out of
the XML representation of the bug returned by the web UI.

=head2 Accessors

=over

=item B<flags>

Returns an array of L<Fedora::Bugzilla::Bug::Flag> objects, representing all
the flags this bug has set.

=item B<get_flag([flag name (Str)])>

Return the named flag, if it exists for this bug.

=item B<flag_count>

Returns the number of flags this bug has.

=item B<has_flag([flag name (Str)])>

Returns true if this bug has the named flag.

=item B<flag_names>

Returns an array of all flag names this bug has.

=item B<flag_pairs>
 
FIXME

=back

=head2 Methods

=over

=item B<set_flags(flag_name =E<gt> 'value', [...])>

Set one or more flags.  Note that the only valid values for a flag are '+',
'-', '?', or undef (unset entirely).

=item B<set_flag(flag_name =E<gt> 'value')>

An alias for set_flags().

=item B<has_flags>

True if this bug has any flags (any value).

=item B<clear_flags>

Clear our flags data and force it to be rebuilt the next time we need it.

=back

=head1 ATTACHMENTS

These allow us to manipulate the attachments of this bug.  See also
L<Fedora::Bugzilla::Bug::Attachment>.

=head2 Accessors

=over

=item B<attachments>

=item B<has_attachments>

=item B<attachment_count>

=item B<get_attachment([Int])>

=item B<first_attachment>

=item B<last_attachment>

=back

=head2 Methods

=over

=item B<add_attachment(...)>

Adds an attachment to the bug; see L<Fedora::Bugzilla::Bug::NewAttachment> for
the required paramaters.

Note you can also pass a pre-built Fedora::Bugzilla::Bug::NewAttachment as the
only argument.

=back

=head1 URIS

These are convienence methods for searching for and finding all URIs contained
within the body of the bug.  See also L<URI>.

=head2 Accessors

=over

=item B<uri_count>

Return the number of URIs found.

=item B<grep_uris([CodeRef])>

This operates much the way you'd expect the grep() function to:  given a
coderef, iterate over each uri and see if it matches.  e.g., to find all URIs
that match koji.fedoraproject.org:

    @uris = $bug->grep_uris(sub { /koji.fedoraproject.org/ });

=item B<map_uris([CodeRef])>

As with grep_uris(), take a code ref and map() over all URIs with it.

=back

=head2 Methods

=over 4

=item B<has_uris>

True if we've already generated our list of URIs from the bug.  Note this
should not be used to determine if any URIs are present in the bug; use
uri_count() for that.

=item B<clear_uris>

Clear the list of URIs and force it to be rebuilt the next time we need it.

=back

=head1 OTHER ATTRIBUTES

Generally, these reflect this interface rather than anything on bugzilla.

=over

=item B<bz>

Our parent L<Fedora::Bugzilla> object.

=item B<data>

A hashref of the raw bug data provided by bugzilla.  Note that changes here
are not reflected in bugzilla proper; you must use the accessors and call
update() for that to happen.

=over 

=item I<has_data>

True if the data has been fetched.

=item I<clear_data>

Clears data(); also triggers a cascade clear of the bulk of the object
(except bz() and id()).

=back

=item B<dirty>

Boolean.  Indicates if any attributes have been updated, but not written back
to bugzilla yet.

=item B<xml>

The raw XML representation of this bug, as fetched from the Bugzilla web UI.

=over

=item I<has_xml>

True if the XML representation has been pulled.

=item I<clear_xml>

Clears xml() as well as anything that depends on it (twig, comments, etc).

=back

=item B<twig>

An L<XML::Twig> object built from xml().

=over

=item I<has_twig>

True if the twig has been built out from xml().

=item I<clear_twig>

Discard the twig and force it to be rebuilt the next time we access it.

=back

=back

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 BUGS AND LIMITATIONS

There are still many common attributes we do not handle getting/setting yet.
If you'd like to see something specific in here, please make a feature
request.

Please report any bugs or feature requests to
C<bug-fedora-bugzilla@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

=head2 Set support for...

CC list, depends, blocks.

=head1 SEE ALSO

L<Fedora::Bugzilla>, L<http://www.bugzilla.org>, 
L<http://bugzilla.redhat.com>, L<http://python-bugzilla.fedorahosted.org>, 
L<WWW::Bugzilla3>.

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

