package IO::All::LWP;
require 5.008;
use strict;
use warnings;
our $VERSION = '0.14';
use IO::All 0.30 '-base';
use LWP::UserAgent;
use IO::Handle;

my $DEFAULT_UA = LWP::UserAgent->new(env_proxy => 1);

field 'response';
field 'content';
field 'put_content';

sub lwp_init {
    my $self = shift;
    bless $self, shift;
    $self->name(shift) if @_;
    return $self->_init;
}

sub ua {
    my $self = shift;
    if (@_) {
        *$self->{ua} = ref($_[0]) ? shift :
            LWP::UserAgent->new(@_);
        return $self;
    } else {
        *$self->{ua} ||= $DEFAULT_UA;
    }
}

sub uri {
    my $self = shift;
    *$self->{uri} = ref($_[0]) ? shift : URI->new(shift)
      if @_;
    return *$self->{uri}
      if defined *$self->{uri};
    *$self->{uri} = URI->new($self->name);
}
    
sub user {
    my $self = shift;
    $self->uri->user(@_);
    return $self;
}

sub password {
    my $self = shift;
    $self->uri->password(@_);
    return $self;
}

sub get {
    my $self = shift;
    my $request = shift || HTTP::Request->new('GET', $self->uri);
    $self->request($request);
}

sub put {
    my $self = shift;
    my $request = (@_ and ref $_[0])
    ? $_[0]
    : do {
        my $content = @_ ? shift : $self->content;
        HTTP::Request->new(PUT => $self->uri, undef, $content);
    };
    $self->request($request);
    $self->is_open(0);
}

sub request {
    my $self = shift;
    $self->response($self->ua->request(shift));
}

sub open {
    my $self = shift;
    $self->is_open(1);
    my $mode = @_ ? shift : $self->mode ? $self->mode : '<';
    $self->mode($mode);
    my $fh;
    if ($mode eq '<') {
        $self->content($self->get->content);
        CORE::open $fh, "<", \ $self->content;
    } 
    elsif ($mode eq '>') {
        $self->put_content(\ do{ my $x = ''});
        CORE::open $fh, ">", $self->put_content;
    } 
    $self->io_handle($fh);
    return $self;
}

sub close {
    my $self = shift;
    if ($self->is_open and defined $self->mode and $self->mode eq '>') {
        $self->content(${$self->put_content});
        $self->put;
    }
    $self->SUPER::close;
}

1;
__END__

=head1 NAME

IO::All::LWP - IO::All interface to LWP

=head1 SYNOPSIS

    use IO::All;

    "hello world\n" > io('ftp://localhost/test/x');   # save to FTP
    $content < io('http://example.org');              # GET webpage

    io('http://example.org') > io('index.html');      # save webpage

=head1 DESCRIPTION

This module acts as glue between L<IO::All> and L<LWP>, so that files can be
read and written through the network using the convenient L<IO:All> interface.
Note that this module is not C<use>d directly: you just use L<IO::All>, which
knows when to autoload L<IO::All::HTTP>, L<IO::All::HTTPS>, L<IO::All::FTP>, or
L<IO::All::Gopher>, which implement the specific protocols based on
L<IO::All::LWP>.

=head1 EXECUTION MODEL

B<GET requests>. When the IO::All object is opened, the URI is fetched and
stored by the object in an internal file handle. It can then be accessed like
any other file via the IO::All methods and operators, it can be tied, etc.

B<PUT requests>. When the IO::All object is opened, an internal file handle is
created. It is possible to that file handle using the various IO::All methods
and operators, it can be tied, etc. If $io->put is not called explicitly, when
the IO::All object is closed, either explicitly via $io->close or automatically
upon destruction, the actual PUT request is made.

The bad news is that the whole file is stored in memory after getting it or
before putting it. This may cause problems if you are dealing with
multi-gigabyte files!

=head1 METHODS

The simplest way of doing things is via the overloaded operators > and <, as
shown in the SYNOPSIS. These take care of automatically opening and closing the
files and connections as needed. However, various methods are available to
provide a finer degree of control. 

This is a subclass of L<IO::All>. In addition to the inherited methods, the 
following methods are available:

=over

=item * ua

Set or get the user agent object (L<LWP::UserAgent> or a subclass). If called
with a list, the list is passed to LWP::UserAgent->new. If called with an
object, the object is used directly as the user agent. Note that there is a 
default user agent if no user agent is specified.

=item * uri

Set or get the URI. It can take either a L<URI> object or a string, and 
it returns an L<URI> object. Note that calling this method overrides the user
and password fields, because URIs can contain authentication information.

=item * user

Set or get the user name for authentication. Note that the user name (and the
password) can also be set as part of the URL, as in
"http://me:secret@example.com/".

=item * password

Set or get the password for authentication. Note that the password can also
be set as part of the URL, as discussed above.

=item * get

GET the current URI using LWP. Or, if called with an L<HTTP::Request> object as
a parameter, it does that request instead. It returns the L<HTTP::Response>
object.

=item * put

PUT to the current URI using LWP. If called with an L<HTTP::Request> object, it
does that request instead. If called with a scalar, it PUTs that as the
content to the current URI, instead of the current accumulated content.

=item * response

Return the L<HTTP::Response> object.

=item * request

Does an LWP request. It requires an L<HTTP::Request> object as a parameter.
Returns an L<HTTP::Response> object.

=item * open

Overrides the C<open> method from L<IO::All>. It takes care of GETting the 
content, or of setting up the internal buffer for PUTting. Just like the
C<open> method from L<IO::All>, it can take a mode: '<' for GET and 
'>' for PUT.

=item * close

Overrides the C<close> method from L<IO::All>. It takes care of PUTting
the content.

=back

=head1 DEPENDENCIES

This module uses L<LWP> for all the heavy lifting. It also requires perl-5.8.0
or a more recent version.

=head1 SEE ALSO

L<IO::All>, L<LWP>, L<IO::All::HTTP>, L<IO::All::FTP>.

=head1 AUTHORS

Ivan Tubert-Brohman <itub@cpan.org> and 
Brian Ingerson <ingy@cpan.org>

Thanks to Sergey Gleizer for the ua method.

=head1 COPYRIGHT

Copyright (c) 2007. Ivan Tubert-Brohman and Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

