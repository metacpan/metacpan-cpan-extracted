package LWP::Protocol::PSGI;

use strict;
use 5.008_001;
our $VERSION = '0.10';

use parent qw(LWP::Protocol);
use HTTP::Message::PSGI qw( req_to_psgi res_from_psgi );
use Carp;

my @protocols = qw( http https );
my %orig;

my @apps;

sub register {
    my $class = shift;

    my $app = LWP::Protocol::PSGI::App->new(@_);
    unshift @apps, $app;

    # register this guy (as well as saving original code) once
    if (! scalar keys %orig) {
        for my $proto (@protocols) {
            if (my $orig = LWP::Protocol::implementor($proto)) {
                $orig{$proto} = $orig;
                LWP::Protocol::implementor($proto, $class);
            } else {
                Carp::carp("LWP::Protocol::$proto is unavailable. Skip registering overrides for it.") if $^W;
            }
        }
    }

    if (defined wantarray) {
        return LWP::Protocol::PSGI::Guard->new(sub {
            $class->unregister_app($app);
        });
    }
}

sub unregister_app {
    my ($class, $app) = @_;

    my $i = 0;
    foreach my $stored_app (@apps) {
        if ($app == $stored_app) {
            splice @apps, $i, 1;
            return;
        }
        $i++;
    }
}
            

sub unregister {
    my $class = shift;
    for my $proto (@protocols) {
        if ($orig{$proto}) {
            LWP::Protocol::implementor($proto, $orig{$proto});
        }
    }
    @apps = ();
}

sub request {
    my($self, $request, $proxy, $arg, @rest) = @_;

    if (my $app = $self->handles($request)) {
        my $env = req_to_psgi $request;
        my $response = res_from_psgi $app->app->($env);
        my $content = $response->content;
        $response->content('');
        $self->collect_once($arg, $response, $content);
    } else {
        $orig{$self->{scheme}}->new($self->{scheme}, $self->{ua})->request($request, $proxy, $arg, @rest);
    }
}

# for testing
sub create {
    my $class = shift;
    push @apps, LWP::Protocol::PSGI::App->new(@_);
    $class->new;
}

sub handles {
    my($self, $request) = @_;

    foreach my $app (@apps) {
        if ($app->match($request)) {
            return $app;
        }
    }
}

package
  LWP::Protocol::PSGI::Guard;
use strict;

sub new {
    my($class, $code) = @_;
    bless $code, $class;
}

sub DESTROY {
    my $self = shift;
    $self->();
}

package
    LWP::Protocol::PSGI::App;
use strict;

sub new {
    my ($class, $app, %options) = @_;
    bless { app => $app, options => \%options }, $class;
}

sub app { $_[0]->{app} }
sub options { $_[0]->{options} }
sub match {
    my ($self, $request) = @_;
    my $options = $self->options;

    if ($options->{host}) {
        my $matcher = $self->_matcher($options->{host});
        $matcher->($request->uri->host) || $matcher->($request->uri->host_port);
    } elsif ($options->{uri}) {
        $self->_matcher($options->{uri})->($request->uri);
    } else {
        1;
    }
}

sub _matcher {
    my($self, $stuff) = @_;
    if (ref $stuff eq 'Regexp') {
        sub { $_[0] =~ $stuff };
    } elsif (ref $stuff eq 'CODE') {
        $stuff;
    } elsif (!ref $stuff) {
        sub { $_[0] eq $stuff };
    } else {
        Carp::croak("Don't know how to match: ", ref $stuff);
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

LWP::Protocol::PSGI - Override LWP's HTTP/HTTPS backend with your own PSGI application

=head1 SYNOPSIS

  use LWP::UserAgent;
  use LWP::Protocol::PSGI;

  # $app can be any PSGI application: Mojolicious, Catalyst or your own
  my $app = do {
      use Dancer;
      set apphandler => 'PSGI';
      get '/search' => sub {
          return 'searching for ' . params->{q};
      };
      dance;
  };

  # Register the $app to handle all LWP requests
  LWP::Protocol::PSGI->register($app);

  # can hijack any code or module that uses LWP::UserAgent underneath, with no changes
  my $ua  = LWP::UserAgent->new;
  my $res = $ua->get("http://www.google.com/search?q=bar");
  print $res->content; # "searching for bar"

  # Only hijacks specific host (and port)
  LWP::Protocol::PSGI->register($psgi_app, host => 'localhost:3000');

  my $ua = LWP::UserAgent->new;
  $ua->get("http://localhost:3000/app"); # this routes $app
  $ua->get("http://google.com/api");     # this doesn't - handled with actual HTTP requests

=head1 DESCRIPTION

LWP::Protocol::PSGI is a module to hijack B<any> code that uses
L<LWP::UserAgent> underneath such that any HTTP or HTTPS requests can
be routed to your own PSGI application.

Because it works with any code that uses LWP, you can override various
WWW::*, Net::* or WebService::* modules such as L<WWW::Mechanize>,
without modifying the calling code or its internals.

  use WWW::Mechanize;
  use LWP::Protocol::PSGI;

  LWP::Protocol::PSGI->register($my_psgi_app);

  my $mech = WWW::Mechanize->new;
  $mech->get("http://amazon.com/"); # $my_psgi_app runs

=head1 TESTING

This module is extremely handy if you have tests that run HTTP
requests against your application and want them to work with both
internal and external instances.

  # in your .t file
  use Test::More;
  use LWP::UserAgent;

  unless ($ENV{TEST_LIVE}) {
      require LWP::Protocol::PSGI;
      my $app = Plack::Util::load_psgi("app.psgi");
      LWP::Protocol::PSGI->register($app);
  }

  my $ua = LWP::UserAgent->new;
  my $res = $ua->get("http://myapp.example.com/");
  is $res->code, 200;
  like $res->content, qr/Hello/;

This test script will by default route all HTTP requests to your own
PSGI app defined in C<$app>, but with the environment variable
C<TEST_LIVE> set, runs the requests against the live server.

You can also combine L<Plack::App::Proxy> with L<LWP::Protocol::PSGI>
to route all requests made in your test aginst a specific server.

  use LWP::Protocol::PSGI;
  use Plack::App::Proxy;

  my $app = Plack::App::Proxy->new(remote => "http://testapp.local:3000")->to_app;
  LWP::Protocol::PSGI->register($app);

  my $ua = LWP::UserAgent->new;
  my $res = $ua->request("http://testapp.com"); # this hits testapp.local:3000

=head1 METHODS

=over 4

=item register

  LWP::Protocol::PSGI->register($app, %options);
  my $guard = LWP::Protocol::PSGI->register($app, %options);

Registers an override hook to hijack HTTP requests. If called in a
non-void context, returns a guard object that automatically resets
the override when it goes out of context.

  {
      my $guard = LWP::Protocol::PSGI->register($app);
      # hijack the code using LWP with $app
  }

  # now LWP uses the original HTTP implementations

When C<%options> is specified, the option limits which URL and hosts
this handler overrides. You can either pass C<host> or C<uri> to match
requests, and if it doesn't match, the handler falls back to the
original LWP HTTP protocol implementor.

  LWP::Protocol::PSGI->register($app, host => 'www.google.com');
  LWP::Protocol::PSGI->register($app, host => qr/\.google\.com$/);
  LWP::Protocol::PSGI->register($app, uri => sub { my $uri = shift; ... });

The options can take either a string, where it does a complete match, a
regular expression or a subroutine reference that returns boolean
given the value of C<host> (only the hostname) or C<uri> (the whole
URI, including query parameters).

=item unregister

  LWP::Protocol::PSGI->unregister;

Resets all the overrides for LWP. If you use the guard interface
described above, it will be automatically called for you.

=back

=head1 DIFFERENCES WITH OTHER MODULES

=head2 Mock vs Protocol handlers

There are similar modules on CPAN that allows you to emulate LWP
requests and responses. Most of them are implemented as a mock
library, which means it doesn't go through the LWP guts and just gives
you a wrapper for receiving HTTP::Request and returning HTTP::Response
back.

LWP::Protocol::PSGI is implemented as an LWP protocol handler and it
allows you to use most of the LWP extensions to add capabilities such
as manipulating headers and parsing cookies.

=head2 Test::LWP::UserAgent

L<Test::LWP::UserAgent> has the similar concept of overriding LWP
request method with particular PSGI applications. It has more features
and options such as passing through the requests to the native LWP
handler, while LWP::Protocol::PSGI only allows to map certain hosts
and ports.

Test::LWP::UserAgent requires you to change the instantiation of
UserAgent from C<< LWP::UserAgent->new >> to C<<
Test::LWP::UserAgent->new >> somehow and it's your responsibility to
do so. This mechanism gives you more control which requests should go
through the PSGI app, and it might not be difficult if the creation is
done in one place in your code base. However it might be hard or even
impossible when you are dealing with third party modules that calls
LWP::UserAgent inside.

LWP::Protocol::PSGI affects the LWP calling code more globally, while
having an option to enable it only in a specific block, thus there's
no need to change the UserAgent object manually, whether it is in your
code or CPAN modules.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2011- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Plack::Client> L<LWP::UserAgent>

=cut
