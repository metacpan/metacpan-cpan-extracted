package IO::Callback::HTTP;

use 5.008008;
use constant { false => !1, true => !0 };
use strict;
use warnings;
use utf8;

BEGIN {
	$IO::Callback::HTTP::AUTHORITY = 'cpan:TOBYINK';
	$IO::Callback::HTTP::VERSION   = '0.003';
}

use Carp                     qw();
use Encode                   qw( encode_utf8 );
use Errno                    qw( EIO );
use HTTP::Request::Common    qw( GET PUT );
use LWP::UserAgent           qw();
use Scalar::Util             qw( blessed );
use URI                      qw();

use namespace::clean;
use base 'IO::Callback';

our $_LAST_CODE;

sub USER_AGENT ()
{
	our $USER_AGENT ||= LWP::UserAgent::->new(
		agent => sprintf('%s/%s ', __PACKAGE__, __PACKAGE__->VERSION),
	);
}

sub open
{
	my ($self, $mode, $code, @args) = @_;
	
	unless (ref $code eq 'CODE')
	{
		$_LAST_CODE =
		$code = ($mode eq '<')
			? $self->_mk_reader($code, @args)
			: $self->_mk_writer($code, @args)
	}
	
	$self->SUPER::open($mode, $code);
}


sub _process_arg
{
	my ($self, $arg) = @_;
	
	if (defined $arg->{failure} and not ref $arg->{failure})
	{
		my $carpage = Carp::->can($arg->{failure})
			or Carp::croak("Unknown failure mode: '$arg->{failure}'");
		$arg->{failure} = sub
		{
			my $res = shift;
			$carpage->(sprintf(
				'HTTP %s request for <%s> failed: %s',
				$res->request->method,
				$res->request->uri,
				$res->status_line,
			));
		}
	}
}

sub _mk_reader
{
	my ($self, $code, %args) = @_;
	$self->_process_arg(\%args);
	
	if ((not ref $code)
	or  (blessed $code and $code->isa('URI')))
	{
		$code = GET($code);
	}
	
	if (blessed $code and $code->isa('HTTP::Request'))
	{
		my $ua    = $args{agent} || USER_AGENT;
		my $bytes = exists $args{bytes} ? $args{bytes} : true;
		my $req   = $code;
		my $done  = false;
		
		return sub
		{
			return undef if $done;
			my $res = $ua->request($req);
			$done = true;
			
			if ($res->is_success)
			{
				return encode_utf8($res->decoded_content) if $bytes;
				return $res->decoded_content;
			}
			
			$! = EIO;
			$args{failure}->($res) if $args{failure};
			return IO::Callback::Error;
		}
	}
	
	return;
}

sub _mk_writer
{
	my ($self, $code, %args) = @_;
	$self->_process_arg(\%args);
	
	if ((not ref $code)
	or  (blessed $code and $code->isa('URI')))
	{
		$code = PUT($code, Content => '');
	}
	
	if (blessed $code and $code->isa('HTTP::Request'))
	{
		my $ua    = $args{agent} || USER_AGENT;
		my $bytes = exists $args{bytes} ? $args{bytes} : true;
		my $req   = $code;
		my $done  = false;
		my $body  = '';
		return sub
		{
			my $str = shift;
			if (length $str)
			{
				$body .= $bytes ? $str : encode_utf8($str);
				return;
			}
			
			$req->content($body);
			$req->header(Content_length => length $req->content);
			my $res = $ua->request($req);
			
			if ($res->is_success)
			{
				$args{success}->($res) if $args{success};
				return;
			}
			
			$! = EIO;
			$args{failure}->($res) if $args{failure};
			return IO::Callback::Error;
		}
	}
	
	return;
}

# Your code goes here

true;

__END__

=head1 NAME

IO::Callback::HTTP - read/write from HTTP URIs as if they were filehandles

=head1 SYNOPSIS

 use IO::Callback::HTTP;
 
 my $fh = IO::Callback::HTTP->new("<", "http://www.example.com/");
 
 while (my $line = <$fh>)
 {
    print $line;
 }

=head1 DESCRIPTION

This module allows you to read from and write to HTTP resources
as if they were normal file handles (in fact, any non-HTTP
resources supported by L<LWP::UserAgent> ought to be OK too,
including FTP, Gopher, etc).

Why would you do this? Not for efficiency reasons, that's for
sure. However, certain APIs expect to be passed filehandles; this
module gives you those filehandles.

Files can be opened in either read mode, using:

 my $fh = IO::Callback::HTTP->new('<', $request, %options);

or write mode:

 my $fh = IO::Callback::HTTP->new('>', $request, %options);

The C<< $fh >> variable will then act like a normal Perl filehandle,
but instead of interacting with a local file on disk, you'll be
interacting with an HTTP resource on a remote server.

C<< $request >> can be a URI (either a string, or a blessed L<URI>
object), or it can be an L<HTTP::Request> object. A URI is
obviously simpler, but using an HTTP::Request object offers you
more flexibility, such as the ability to change the HTTP method
(defaults to GET for filehandles opened in read mode, and PUT for
filehandles opened in write mode) or include particular HTTP
headers (some of which are very useful: Accept, Content-Type,
User-Agent, etc).

Note that for a single filehandle, only one HTTP request is
actually made. In the case of read mode, this happens on the first
read. If no characters are read from the handle, then no request is
made. In the case of write mode, the request happens once the file
is B<closed>.

There are also a few options which can be passed to the constructor:

=over

=item C<< agent >>

An L<LWP::UserAgent> object (or a subclass, such as
L<WWW::Mechanize> or L<LWPx::ParanoidAgent>) that will actually
make the request.

This is optional; IO::Callback::HTTP does have its own pet UA that
it can use if you don't provide one.

=item C<< bytes >>

In read mode, if true, will make sure the data read from the handle
is returned encoded as a UTF-8 byte string. If false, then the data
read will be returned as a utf8 character string.

In write mode, if true, will assume that you're writing bytes to the
filehandle. If false, will assume that you're writing utf8 character
strings to the filehandle, so will deal with encoding them to UTF-8
octets.

Defaults to true.

=item C<< failure >>

Set this to a coderef to trigger when the HTTP request fails (i.e.
times out or non-2XX HTTP response code). It is passed a single
parameter, which is the L<HTTP::Response> object. 

As a shortcut, the strings 'croak', 'confess', 'carp' and 'cluck' are
also accepted, with the same meanings as defined in L<Carp>.

Either way, IO::Callback::HTTP should do the correct thing, setting
C<< $! >> and so on.

=item C<< success >>

Set this to a coderef to trigger when the HTTP request succeeds
(i.e. 2XX HTTP response code). It is passed a single parameter, which
is the L<HTTP::Response> object. 

For filehandles in read mode, this is probably not especially useful,
the fact that you can read from the file handle at all indicates that
the request was successful. In write mode, it's more interesting as
you may be interested in the result of a POST or PUT request.

=back

=begin private

=item open

=item USER_AGENT

=end private

=head1 CAVEATS

Most of the test suite is skipped on MSWin32 because L<Test::HTTP::Server>
does not currently support that platform. IO::Callback::HTTP is I<believed>
to function correctly on Windows, but it's had no meaningful testing.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=IO-Callback-HTTP>.

=head1 SEE ALSO

L<IO::Callback>, L<LWP::UserAgent>.

L<IO::All::LWP> does something similar, though it's less flexible.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

