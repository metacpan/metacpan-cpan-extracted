#############################################################################
#
# An interface to Fedora's Bugzilla instance.
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

package Fedora::Bugzilla;

# moose core
use Moose;
use Moose::Util::TypeConstraints;

# moose extensions
use MooseX::Types::Path::Class qw{ File Dir };
use MooseX::Types::URI qw{ Uri };
use MooseX::AttributeHelpers;

# other fedora bits
use Fedora::Bugzilla::Bug;
use Fedora::Bugzilla::NewBug;
use Fedora::Bugzilla::Bugs;
use Fedora::Bugzilla::QueriedBugs;
use Fedora::Bugzilla::Types ':all';
use Fedora::Bugzilla::XMLRPC;

# cpan bits
use Path::Class qw{ file dir };
use Regexp::Common;
use HTTP::Cookies; 

# debugging
#use Smart::Comments '###';

use namespace::clean -except => 'meta';

our $VERSION = '0.13';

## not needed ATM
#subtype 'HTTP::Cookies'
#    => as Object
#    => where { $_->isa('HTTP::Cookies') }
#    ;
#
#coerce 'HTTP::Cookies'
#    => from 'Path::Class::File'
#    => via { HTTP::Cookies->new(file => "$_") }
#    ;

# we could require one or the other be set, but there are many operations we
# can do against bugzilla that don't actually require we be logged in

has site => (is => 'ro', lazy => 1, isa => Uri, coerce => 1, lazy_build => 1);

has userid    => (is => 'ro', isa => 'Str',     lazy_build => 1);
has userid_cb => (is => 'ro', isa => 'CodeRef', lazy_build => 1);
has passwd    => (is => 'ro', isa => 'Str',     lazy_build => 1);
has passwd_cb => (is => 'ro', isa => 'CodeRef', lazy_build => 1);

sub _build_site { 'https://bugzilla.redhat.com/xmlrpc.cgi' }

sub _build_userid    { shift->userid_cb->()  }
sub _build_userid_cb { sub { die 'neither userid nor userid_cb set' } }
sub _build_passwd    { shift->passwd_cb->()  }
sub _build_passwd_cb { sub { die 'neither passwd nor userid_cb set' } }

has new_bug_class     => (is => 'rw', isa => 'Str', lazy_build => 1);
has default_bug_class => (is => 'rw', isa => 'Str', lazy_build => 1);

sub _build_new_bug_class     { 'Fedora::Bugzilla::NewBug' }
sub _build_default_bug_class { 'Fedora::Bugzilla::Bug'    }

has aggressive_fetch => (is => 'rw', isa => 'Bool', lazy_build => 1);
sub _build_aggressive_fetch { 1 }

# hold our RPC::XML::Client instance
has rpc => (is => 'ro', isa => 'Fedora::Bugzilla::XMLRPC', lazy_build => 1);

# create our RPC::XML::Client appropriately
sub _build_rpc { 
    my $self = shift @_;

    # twice to keep warnings from complaining...
    #local $RPC::XML::ENCODING;
    $RPC::XML::ENCODING = 'UTF-8';

    my $rpc = Fedora::Bugzilla::XMLRPC->new($self->site, sub { $self->login });

    # error bits 
    $rpc->error_handler($self->rpc_error_handler);
    $rpc->fault_handler($self->rpc_fault_handler);
    $rpc->useragent->cookie_jar($self->cookie_jar);
    $rpc->useragent->agent($self->ua_agent);

    return $rpc;
}

has ua_agent => (is => 'ro', isa => 'Str', lazy_build => 1);
has ua       => (is => 'ro', isa => 'LWP::UserAgent', lazy_build => 1);

sub _build_ua_agent { "Fedora::Bugzilla $VERSION" }

sub _build_ua { 
    my $self = shift @_;

    return LWP::UserAgent->new(
        cookie_jar => $self->cookie_jar,
        agent      => $self->ua_agent,
    );
}

has rpc_error_handler => (is => 'ro', isa => 'CodeRef', lazy_build => 1);
has rpc_fault_handler => (is => 'ro', isa => 'CodeRef', lazy_build => 1);

sub _build_rpc_error_handler { sub { confess shift                       } }
sub _build_rpc_fault_handler { sub { confess shift->{faultString}->value } }
    
has cookie_file => (is => 'ro', isa => File, coerce => 1, lazy_build => 1);
has cookie_jar  => (is => 'ro', isa => 'HTTP::Cookies',   lazy_build => 1);

sub _build_cookie_file { file "$ENV{HOME}/.fedora.bz.cookies.txt" }

sub _build_cookie_jar {
    my $self = shift @_;
    my $file = $self->cookie_file;

    # if set to undef, we don't want the cookies to be saved anywhere
    return HTTP::Cookies->new if not defined $file;

    # if file exists and is writeable, or dir exists and is writeable, use it
    return HTTP::Cookies->new(file => $file, autosave => 1)
        if (-f $file && -w _) || (-d $file->dir && -w _);

    # otherwise, we have a file defined but we can't write to it / dir
    warn "cookie_file ($file) is not usable (write errors)";
    return HTTP::Cookies->new; 
}

# this seems a little magical, but really, makes sense to me :)
has login => (
    is => 'ro',
    lazy => 1,

    predicate => 'logged_in',

    clearer => 'logout',
    trigger => sub { shift->_logout },

    default => sub {
        my $self = shift @_;

        ### logging in...
        my $ret = $self->rpc->simple_request(
            'User.login',
            {
                login    => $self->userid,
                password => $self->passwd,
            }
        #)->{id};
        );

        ### $ret
        #die;

        return $ret->{id} if $ret;

        die 'Could not log in to bugzilla! (password problem?)';
    },
);

sub _logout { shift->rpc->simple_request('User.logout') }

# Product.get_accessible_products
has accessible_products => (
    is         => 'ro',
    isa        => 'ArrayRef[Int]',
    auto_deref => 1,
    lazy_build => 1,
);

########################################################################
# misc bugzilla functionality 

# Bugzilla.version
has version => (is => 'ro', isa => 'Str', lazy_build => 1);
sub _build_version { shift->rpc->simple_request('Bugzilla.version')->{version} }

# Bugzilla.timezone
has timezone => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_timezone {
    shift->rpc->simple_request('Bugzilla.timezone')->{timezone}
}

# User.offer_account_by_email
sub offer_account_by_email {
    my $self  = shift @_;
    my $email = shift @_ || confess 'Must pass email address';

    my $r = $self->rpc->simple_request(
        'User.offer_account_by_email',
        { email => $email},
    );
    ### $r

    return;
}

# User.create
sub create_user {
    my $self = shift @_;
    my %info = @_;

    # FIXME need checking for parameters here...
    return $self->rpc->simple_request('User.create', \%info)->{id};
}

########################################################################
# products 

#has _products => ( ... );

# a little sugar to get us to the same name as WWW::Bugzilla3/Bugzilla
# internals
sub get_accessible_products { shift->accesible_products }

sub _build_get_accessible_products {
    my $self = shift @_;

    $self->rpc->simple_request('Product.get_accessible_products')->{ids};
}

########################################################################
# fetch/create/etc bugs 

sub create_bug {
    my $self = shift @_;
    my $nb;

    if ( ! (blessed $_[0] && $_[0]->isa('Fedora::Bugzilla::NewBug')) ) {

        # we wern't passed a new bug object, so let's create one.
        $nb = $self->new_bug_class->new(@_);
    }
    else {
        
        $nb = shift @_;
    }

    # actually create the bug on the server
    my $id = $self->_create_bug($nb->bughash);

    return Fedora::Bugzilla::Bug->new(bz => $self, id => $id);
}


# Bug.create
sub _create_bug {
    my $self    = shift @_;
    my $bughash = shift @_;

    # FIXME this needs work

    #my $req = RPC::XML::request->new('Bug.create', $bughash);

    # no validation!
    return $self->rpc->simple_request('Bug.create', $bughash)->{id};
}

sub get_bug { shift->bug(@_) }

sub bug { 
    my $self  = shift @_;
    my $bug   = shift @_ || confess 'Must pass bug id or alias';
    my $class = shift @_ || $self->default_bug_class; 
    
    # invoke accordingly
    return $class->new(bz => $self, id => $bug) if $bug =~ $RE{num}{int};
    return $class->new(bz => $self, alias => $bug);
}

sub get_bugs { shift->bugs(@_) }

# Bug.get_bugs
sub bugs { Fedora::Bugzilla::Bugs->new(bz => shift, ids => [ @_ ]) };
    
sub get_bug_fields { shift->all_legal_bug_fields }

# bugzilla.getBugFields
has all_legal_bug_fields => (
    metaclass => 'Collection::List',

    is  => 'ro',
    isa => 'ArrayRef[Str]',

    auto_deref => 1,
    lazy_build => 1,

    # provides ...
);

sub _build_all_legal_bug_fields {
    my $self = shift @_;

    my $fields = $self
        ->rpc
        ->simple_request('bugzilla.getBugFields')
        ;

    return [ sort @$fields ];
}

########################################################################
# Searching...

# this is still pretty experimental, and seems to be specific to RHBZ at the
# moment.

has queryinfo => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

sub _build_queryinfo {
    my $self = shift @_;

    warn q{This probably won't work; if it does, please email the author};

    my $foo = $self->rpc->simple_request('bugzilla.getQueryInfo');

    return $foo;
}

=begin comment

https://fedorahosted.org/python-bugzilla/browser/bugzilla/rhbugzilla.py

    def _query(self,query):
        '''Query bugzilla and return a list of matching bugs.
        query must be a dict with fields like those in in querydata['fields'].
        You can also pass in keys called 'quicksearch' or 'savedsearch' -
        'quicksearch' will do a quick keyword search like the simple search
        on the Bugzilla home page.
        'savedsearch' should be the name of a previously-saved search to
        execute. You need to be logged in for this to work.
        Returns a dict like this: {'bugs':buglist,
                                   'sql':querystring}
        buglist is a list of dicts describing bugs, and 'sql' contains the SQL
        generated by executing the search.
        '''
        return self._proxy.Bug.search(query)

=end comment 
=cut

# Bug.search
sub search { shift->_query(@_) }
sub query  { shift->_query(@_) }

sub run_named_query { shift->_query(savedsearch => shift)         }
sub run_savedsearch { shift->run_named_query(@_)                  }
sub run_quicksearch { shift->_query(quicksearch => join(' ', @_)) }

sub _query {
    my $self = shift @_;

    my $ret = $self->rpc->simple_request('Bug.search', { @_ });
    
    # FIXME nuke?
    $self->last_sql($ret->{sql});

    return Fedora::Bugzilla::QueriedBugs->new(
        bz              => $self,
        raw             => $ret->{bugs},
        sql             => $ret->{sql},
        display_columns => $ret->{displaycolumns},
    );
}

has last_sql => (
    is  => 'rw',
    isa => 'Str',
    predicate => 'has_last_sql',
    clearer   => 'clear_last_sql',
);

########################################################################
# magic end bits 

1; 

__END__

=head1 NAME

Fedora::Bugzilla - Interact with Fedora's bugzilla instance 

=head1 SYNOPSIS

    use Fedora::Bugzilla;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.

=head1 DESCRIPTION

The XML-RPC interface to bugzilla is a quite useful, and while bugzilla 3.x 
is starting to flesh their interface out a bit more (see, e.g.,
L<WWW::Bugzilla3>), Fedora's bugzilla implementation has a large number of
custom methods.  This module aims to expose them, in a kinder, gentler way.

In addition to the XML-RPC methods Bugzilla makes available, there are also
some things we only seem to be able to access via the web/XML interfaces.
(See, e.g., the flags, attachments and comments functionality.)  This package
works to expose those as well.

Some functionality is more expensive to invoke than others, for a variety of
reasons.  We strive to only access each bit as we need it, to minimize time
and effort while still making available as much as is possible.

(And, yes, I know it's really RedHat's bugzilla.  Some day... oh yes, some
day...)

=head1 INTERFACE

"Release Early, Release Often"

I've tried to get at least the methods I use in here.  I know I'm missing
some, and I bet there are others I don't even know about... I'll try not to,
but I won't guarantee that I won't change the api in some incompatable way.
If you'd like to see something here, please either drop me a line (see AUTHOR) 
or better yet, open a ticket with a patch ;)

Note also, the documentation is woefully incomplete.

=head2 METHODS

=over

=item B<new> 

Standard constructor.  Takes a number of arguments, two of which are
required; note that each of these arguments is also available through an
accessor of the same name once the object instance has been created.

=over

=item I<userid =E<gt> Str> 

B<Required.>  Your bugzilla userid (generally your email address).

=item I<passwd =E<gt> Str> 

B<Required.> Your bugzilla password.

=item I<site =E<gt> Str|URI>

The URI of the interface you're trying to access.  Note this (correctly) 
defaults to L<https://bugzilla.redhat.com/xmlrpc.cgi>.

=item I<cookie_file =E<gt> Str|Path::Class::File>

Takes a filename to give to the RPC's useragent instance as file to hold the
bugzilla cookies in.  Set to undef to use no actual file, and just cache
cookies in-memory.

Defaults to: "$ENV{HOME}/.fedora.bz.cookies.txt";

=back

=item B<login>

Log in to the bugzilla service.

=item B<logged_in>

True if we're logged in, false otherwise.

=item B<logout>

Log out from the bugzilla service.

=back

=head2 BUG CREATION

=over

=item B<create_bug>

Creates a new bug, passing @_ to the constructor of the default new bug class.
See L<Fedora::Bugzilla::NewBug>.

=item B<new_bug_class>

Gets/sets the class used to create new bugs with.

=back

=head2 FETCHING BUGS

=over

=item B<bug, get_bug (Int|Str)>

Given a bug id/alias, returns a corresponding L<Fedora::Bugzilla::Bug>.

=item B<bugs, get_bugs (Int|Str, ...)>

Given a list of bug id/aliases, return a L<Fedora::Bugzilla::Bugs> object.

=back

=head2 SEARCHING AND QUERYING

These functions return a L<Fedora::Bugzilla::Bugs> object representing the
results of the query.

=over

=item B<run_savedsearch(Str)>

Given the name of a saved search, run it and return the bugs.

=item B<run_named_query(Str)>

Alias to run_savedsearch().

=item B<run_quicksearch(Str, ...)>

Given a number of search terms, submit to Bugzilla for a quicksearch (akin to
entering terms on the web UI).

=back

=head2 MISC SERVER METHODS

=over

=item B<accessible_products>

FIXME. Returns an array of products the user can search or enter bugs against.

=item B<version>

Returns the version of the bugzilla server.

=item B<timezone>

Returns the timezone the bugzilla server is in.

=item B<offer_account_by_email (email address)>

Sends an offer of a Bugzilla account to the given email address.

=back

=head1 SPEED

We've tried to take steps to make sure things are speedy: "non-changing"
values are cached and only pulled when needed, etc.  While we don't
implement a multicall queued approach (yet), we do try to minimize the number
of queries required; e.g. by using Bug.get_bugs when multiple bugs are needed.

Some of the functionality requires that the XML representation of the bug be
pulled (e.g. flags, comments, attachment listings, etc); in these cases we
don't do the actual pull until requested.

For methods that return more than one bug wrapped in a
L<Fedora::Bugzilla::Bugs> object, we fetch all the bug data through one XMLRPC
call once someone tries to access any of the bug data in it (e.g. bugs(),
num_bugs(), etc).  Additionally, if I<aggressive_fetch> is set in the parent
Fedora::Bugzilla object, we'll pull down the XML and any other data we need
for each bug.  Pulling all the data at one time can result in significant time
savings over having each bug object pull their own.

=head2 Updates

Note that performing an action on a bug that changes any value will result in
all data (save the id) being discarded, and reloaded the next time the bug is
accessed.  It's best to pull any information you may need _before_ updating
the bug, if the situation warrants it, to avoid the second call to the
Bugzilla server.

=head1 DIAGNOSTICS

At the moment, we generally die() or confess() any errors.

=head1 BUGS, LIMITATIONS AND VERSION CONTROL

Source, tickets, etc can be all accessed through the Camelus project at
fedorahosted.org.  Please use the 'Fedora-Bugzilla' component when reporting
issues or making feature requests:

    L<http://camelus.fedorahosted.org>

There are still many areas of functionality we do not handle yet.  If you'd
like to see something in here, specific or otherwise, please make a feature
request through the trac ticketing interface.

=head1 SEE ALSO

L<http://www.bugzilla.org>, L<http://bugzilla.redhat.com>,
L<http://python-bugzilla.fedorahosted.org>, the L<WWW::Bugzilla3> module.

=head1 AUTHOR

Chris Weyl  C<< <cweyl@alumni.drew.edu> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Chris Weyl <cweyl@alumni.drew.edu>

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

=cut
