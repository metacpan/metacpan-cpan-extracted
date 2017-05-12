package Flea;
BEGIN {
  $Flea::VERSION = '0.04';
}

use strict;
use warnings;

use Carp qw(croak);
use Exception::Class ('Flea::Pass' => { alias => 'pass' });
use Exporter::Declare '-magic';
use JSON;
use HTTP::Exception;
use Try::Tiny;
use Plack::Request;
use URI;
use List::Util qw(first);

default_exports qw(handle http route);
our $_add = sub { croak 'Trying to add handler outside bite' };

sub route {
    my ($methods, $regex, $code) = @_;
    $_add->([map {lc} @$methods], $regex, $code);
}

default_export get    Flea::Parser::Route  { route(['get'],  @_) }
default_export put    Flea::Parser::Route  { route(['put'],  @_) }
default_export del    Flea::Parser::Route  { route(['del'],  @_) }
default_export any    Flea::Parser::Route  { route(['any'],  @_) }
default_export post   Flea::Parser::Route  { route(['post'], @_) }
default_export method Flea::Parser::Method { 
    my $code    = pop;
    my $re      = pop;
    my $methods = [@_];
    route($methods, $re, $code);
}

default_export uri {
    my ($req, $path) = @_;
    my $base  = $req->base->as_string;
    $base =~ s|/$||;
    $path =~ s|^/||;
    URI->new("$base/$path")->canonical;
}

default_export json {
    return [
        200,
        ['Content-Type' => 'application/json; charset=UTF-8'],
        [ JSON::encode_json(shift) ]
    ];
}

default_export html {
    return [
        200,
        ['Content-Type' => 'text/html; charset=UTF-8'],
        [ shift ]
    ];
}

default_export text {
    return [
        200,
        ['Content-Type' => 'text/plain; charset=UTF-8'],
        [ shift ]
    ];
}

sub http {
    HTTP::Exception->throw(@_);
}

sub handle {
    my ($fh, $type) = @_;
    return [
        200,
        ['Content-Type' => $type || 'text/html; charset=UTF-8'],
        $fh
    ];
}

default_export file {
    open my $fh, '<', shift;
    handle($fh, @_);
}

default_export request  { Plack::Request->new(shift) }
default_export response { shift->new_response(200) }

sub _rethrow {
    my $e = shift;
    $e->rethrow if ref $e && $e->can('rethrow');
    die $e || 'unknown error';
}

sub _find_and_run {
    my ($handlers, $env) = @_;
    my $method = lc $env->{REQUEST_METHOD};
    my $found  = 0;
    for my $h (@$handlers) {
        my @matches = $env->{PATH_INFO} =~ $h->{pattern};
        if (@matches) {
            $found = 1;
            next unless first { $_ eq $method || $_ eq 'any' }
                        @{ $h->{methods} };

            my $result = try {
                $h->{handler}->($env, @matches);
            }
            catch {
                my $e = $_;
                _rethrow($e) unless Flea::Pass->caught;
                undef;
            };
            next unless $result;
            return try { $result->finalize } || $result;
        }
    }
    http ($found ? 405 : 404);
}

default_export bite codeblock {
    my $block = shift;
    my @handlers;
    local $_add = sub {
        my ($m, $r, $c) = @_;
        push(@handlers, { methods => $m, pattern => $r, handler => $c });
    };
    $block->();

    return sub { _find_and_run(\@handlers, shift) };
}

1;

=head1 NAME

Flea - Minimalistic sugar for your Plack

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    # app.psgi, perhaps?
    use Flea;

    my $app = bite {
        get '^/$' {
            file 'index.html';
        }
        get '^/api$' {
            json { foo => 'bar' };
        }
        post '^/resource/(\d+)$' {
            my $request  = request(shift);
            my $id       = shift;
            http 400 unless valid_id($id);
            my $response = response($request)
            $response;
        }
    };

=head1 DESCRIPTION

L<PSGI>/L<Plack> is where it's at. L<Dancer>'s routing syntax is really cool,
but it does a lot of things I don't usually want. What I really want is
Dancer-like sugar as an extremely thin layer over my teeth^H^H^H^H^H PSGI
apps.

=head1 What's with the name?

With all the bad tooth decay jokes, why not call it Gingivitis or something?
That's too much typing.  And it sounds gross.  Also, fleas are small and they
bite you when you're not paying attention.  You have been warned.

=head1 EXPORTS

Flea is a L<Exporter::Declare>.  Everything from there should work.

=head2 bite

Takes a block as an argument and returns a PSGI app.  Inside the block is
where you define your route handlers.  If you try defining them outside of a
route block, Flea will bite you.  Note that the routing is done via path_info,
so your app will be mountable via L<Plack::Builder>.

=head2 get, post, put, del, any

C<any> will match any request method, and the others will only match the
corresponding method.  If you need to match some other method or combination
of methods, see L</method>.  Aren't you glad you can rename these? (see
L<Exporter::Declare>).

Next come a regex to match path_info against.  You should surround the regex
with single quotes.  B<LISTEN>:  are you listening?  B<SINGLE QUOTES>.  This
isn't a real perl string, it's parsed with Devel::Declare magic (you'll end up
with a compiled regex).  If you try to use C<qr> or something cute like that,
you'll get B<bitten>.  If you need to do something fancy, use L</route> instead
of these sugary things.

Last of all comes a block.  This receives the PSGI env as its first argument
and any matches from the regex as extra arguments.  It can return either a raw
PSGI response or something with a finalize() method that returns a PSGI
response (like Plack::Response).

=head2 method

Just like get/post/etc, except you can tack on method names (separated by
spaces) to say which methods will match.

    method options '^/regex$' {
    }

    method options head '^/regex$' {
    }

=head2 route($methods, $regex, $sub)

This is an honest to goodness real perl subroutine, unlike the magic bits
above.  You call it like:
    
    route ['get', 'head'], qr{^a/real/regex/please$}, sub {
        ...
    };

Yes, $methods has to be an arrayref.  No, $regex doesn't have to be compiled,
you can pass it a string if you want.  But then, why are you using route?
Yes, you need the semicolon at the end.

=head2 request($env)

Short for Plack::Request->new($env)

=head2 response($request)

Short for $request->new_response(200).

=head2 uri($request, $path)

Returns a canonical L<URI> representing the path you passed with
$request->base welded onto the front.  Does the Right Thing if $request->base
or $path have leading/trailing slashes.  Handy for links which are internal to
your app, because it will still behave if you mount your app somewhere other
than C</>.

=head2 json($str)

Returns a full C<200 OK>, C<content-type application/json; charset=UTF-8>
response.  Pass it something that JSON::encode_json can turn into a string.

=head2 text($str)

text/plain; charset=UTF-8.

=head2 html($str)

text/html; charset=UTF-8.  Seeing a pattern?

=head2 file($filename, $mime_type?)

Dump the contents of the file you named.  If you don't give a mime type,
text/html is assumed.

=head2 handle($fh, $mime_type?)

Much like file, except you pass an open filehandle instead of a filename.

=head2 http($code, @args)

Shortcut for HTTP::Exception->throw.  Accepts the same arguments.

=head2 pass

Throws a Flea::Pass exception, which causes Flea to pretend that your
handler didn't match and keep trying other handlers.  By the way, the default
action when no handler is found (or they all passed) is to throw a 404
exception.

=head1 MATURITY

This module is extremely immature as of this writing.  Not only does the
author have the mind of a child, he has never before tinkered with
Devel::Declare magic, although L<Exporter::Declare> sure does help.  The
author hasn't thought very hard about the interface, either, so that could
change.  When Flea breaks or doesn't do what you want, fork it on L</GITHUB>
and/or send the author a patch or something.  Or go use a real web framework
for grownups, like L<Catalyst>.

=head1 GITHUB

Oh yeah, Flea is hosted on Github at L<http://github.com/frodwith/flea>.

=head1 IRC

You can try hopping into #flea on irc.perl.org.  The author might even be
there.  He might even be paying attention to his irc client!

=head1 SEE ALSO

L<PSGI>, L<Plack>, L<Dancer>, L<Exporter::Declare>