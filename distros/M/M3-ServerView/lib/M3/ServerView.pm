package M3::ServerView;

use 5.006;
use strict;
use warnings;

use Carp qw(croak carp);
use HTTP::Request;
use LWP::UserAgent;
use Scalar::Util qw(refaddr blessed);
use Time::HiRes qw(time);
use URI;

# Load views
use M3::ServerView::View;
use M3::ServerView::RootView;
use M3::ServerView::ServerView;
use M3::ServerView::FindJobView;

# Module version
our $VERSION = "0.04";

# Inside-out objects
my %Base_uri;
my %Password;
my %User;

sub connect_to {
    my ($pkg, $base_uri, %args) = @_;
    
    my $self = bless \do { my $v; }, $pkg;

    # Transform to URI object if necessary
    if (blessed $base_uri) {
        croak "URL is not an URI-instance" unless $base_uri->isa("URI");
    }
    else {
        $base_uri = URI->new($base_uri);
    }
    
    # Path must end with / because we append to it
    $base_uri->path("/") if $base_uri->path eq "";
    croak "Invalid URL '$base_uri' - must end with /" unless $base_uri->path =~ m|/$|;

    # Store object attributes
    $Base_uri{refaddr $self} = $base_uri;    
    $User{refaddr $self} = $args{user};
    $Password{refaddr $self} = $args{password};
    
    return $self;
}

sub root {
    my ($self) = @_;
    my $view = $self->_load_view("");
    return $view;
}

sub find_jobs {
    my ($self, $in_query) = @_;

    croak "Missing query" unless ref $in_query eq "HASH";

    my %out_query = (
        name    => undef,
        owner   => undef,
        type    => undef,
        bjno    => undef,
        find => "Find",
    );

    if (exists $in_query->{name}) {
        $out_query{name} = $in_query->{name};
    }    
    if (exists $in_query->{user}) {
        $out_query{owner} = $in_query->{user};
    }
    if (exists $in_query->{type}) {
        $out_query{type} = $in_query->{type};
    }
    if (exists $in_query->{batch_job_number}) {
        $out_query{bjno} = $in_query->{batch_job_number};
    }
    if ($in_query->{queued}) {
        $out_query{queued} = "on";
    }

    return $self->_load_view("/findjob", \%out_query);
}

# Loads the contents of an URL and measures the time it takes
sub _get_page_contents {
    my ($self, $uri) = @_;

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $uri);
    
    my $user = $self->user;
    my $password = $self->password;

    if (defined $user && defined $password) {
        $req->authorization_basic($user, $password);
    }
    
    my $t = time;
    
    my $res = $ua->request($req);
    unless ($res->is_success) {
        croak "Failed to get '$uri' because server returned: ", $res->status_line;
    }
    
    return wantarray ? ($res->content, time - $t) : $res->content;
}

# Clean up inside-out attriutes
sub DESTROY {
    my ($self) = @_;
    my $id = refaddr $self;
    delete $Base_uri{$id};
    delete $User{$id};
    delete $Password{$id};
}

sub base_uri {
    my ($self) = @_;
    return $Base_uri{refaddr $self};
}

sub user {
    my ($self) = @_;
    return undef unless ref $self;
    return $User{refaddr $self};
}

sub password {
    my ($self) = @_;
    return undef unless ref $self;
    return $Password{refaddr $self};
}


{
    # This table keeps the mapping between path and view class
    my %View_class = (
        "/"         => "M3::ServerView::RootView",
        "/server"   => "M3::ServerView::ServerView",
        "/findjob"  => "M3::ServerView::FindJobView",
    );
    
    sub _view_class_for_target {
        my $target = shift || "/";
        return $View_class{$target} || "";
    }
}

sub _load_view {
    my ($self, $path, $query) = @_;

    my $target = $path || "/";
    my $view_class = _view_class_for_target($target);
    croak "Can't determinte view class for '${path}'" unless $view_class;
    
    my $uri = $self->base_uri->clone;
    $uri->path($path);

    if (ref $query) {
        $uri->query_form($query);
    }
    else {
        $uri->query($query);
    }

    my $view = $view_class->new($self, $uri);
    return $view;
}

1;
__END__

=head1 NAME

M3::ServerView - Perl extension for communicating with M3 ServerView

=head1 SYNOPSIS

 use M3::ServerView;
 
 my $conn = M3::ServerView->connect_to(
   "http://m3.company.com:6600/", 
   user => "admin", 
   password => "s3kr1t"
 );
  
 my $root = $conn->root();
 my $rs = $root->search({ status => "Down"});
 while (defined (my $system = $rs->next)) {
   print "System '", $system->type, "' is reported to be down\n";
 }

=head1 DESCRIPTION

This module provides a interface to the ServerView web-based monitoring 
service for M3.

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item connect_to ( URL [, user => USER ] [, password => PASSWORD ] )

Connects to the M3 ServerView at I<URL>. Argument I<URL> can be either a string or an 
C<URI>-instance. Optionally a user and password may be defined.

=back

=head2 INSTANCE METHODS

=over 4

=item base_uri

Returns the base URI for the interface.

=item user

Returns the username to connect as or undef if a user wasn't defined.

=item password

Returns the password for the user to connect as or undef if the password wasn't defined.

=item root

Returns the root view - L<M3::ServerView::RootView>.

=item find_jobs (QUERY)

Search for jobs. The argument I<QUERY> must be a hash-reference with zero or more of the 
following keys and values defined.

=over 4

=item I<name>

The name of the job.

=item I<user>

The name of the user owning the jobs.

=item I<type>

The type of job - B, M, I or A

=item I<batch_job_number>

The job number.

=item I<queued>

If the job is queued.

=back

Examples 

  # Find all jobs belonging to user SYSTEM
  my $rs = $conn->find_jobs({ user => "SYSTEM" });
  if ($rs->count) {
      print "User SYSTEM has current jobs";
  }
  
=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-m3-serverview@rt.cpan.org>, 
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Martin Wilderoth, Linserv AB C<< <marwil@cpan.org> >>

Claes Jakobsson, Versed Solutions C<< <claes@versed.se> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 - 2008, Linserv AB C<< <marwil@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
