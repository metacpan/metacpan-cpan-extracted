package HTTP::ProxyPAC;

use strict;
our $VERSION = '0.31';

use Carp;
use Scalar::Util qw(blessed);
use URI;

my ($useJE, $usePerlLib);

BEGIN {
    # prevent error message when running standalone
    if   (-e 'blib/HTTP/ProxyPAC/Functions.pm') {use lib 'blib'}
    elsif (-e 'lib/HTTP/ProxyPAC/Functions.pm') {use lib 'lib'}

    require HTTP::ProxyPAC::Functions;
    require HTTP::ProxyPAC::Result;
}
our $UserAgent;

sub new {
    my $class = shift;
    my $stuff = shift;

    my %options = @_;

    if ($options{interp} && $options{interp} =~ /javascript|js/i) {
      eval "use JavaScript";
      if ($@) {
        if (-e "t/00_compile.t") {return}
        die $@;
    } } elsif ($options{interp} && $options{interp} =~ /je/i) {
      require JE;
      $useJE = 1;
    } else {
      eval "use JavaScript";
      if ($@) {
        my $atJS = $@;
        eval "use JE";
        if ($@) {
            die "neither the JavaScript module nor the JS module seems to be available\n"
              . "use JavaScript reports: $atJS\nuse JE reports: $@";
        } else {$useJE = 1}
      }
    }
    $usePerlLib = $options{lib} && $options{lib} =~ /perl/i;

    if (blessed($stuff) && $stuff->isa('URI')) {
        return $class->init( $class->load_uri($stuff) );
    }
    elsif (blessed($stuff) && $stuff->isa('IO::Handle')) {
        return $class->init( $class->load_fh($stuff) );
    }
    elsif (ref($stuff) && ref($stuff) eq 'GLOB') {
        return $class->init( $class->load_fh($stuff) );
    }
    elsif (ref($stuff) && ref($stuff) eq 'SCALAR') {
        return $class->init( $$stuff );
    }
    elsif (!ref($stuff)) {
        return $class->init( $class->load_file($stuff) );
    }
    else {
        Carp::croak("Unknown reference type to HTTP::ProxyPAC->new: ", ref($stuff));
    }
}

sub load_uri {
    my($class, $uri) = @_;

    $UserAgent ||= do {
        require LWP::UserAgent;
        LWP::UserAgent->new(agent => __PACKAGE__ . "/" . $VERSION);
    };

    my $res = $UserAgent->get($uri);

    if ($res->content_type ne "application/x-ns-proxy-autoconfig") {
        Carp::croak("Content-Type should be application/x-ns-proxy-autoconfig, is ",
                    $res->content_type);
    }
    return $res->content;
}

sub load_fh {
    my($class, $fh) = @_;
    read($fh, my($body), -s $fh);
    $body;
}

sub load_file {
    my($class, $file) = @_;

    open my $fh, $file or Carp::croak("$file: $!");
    my $body = $class->load_fh($fh);
    close $fh;

    $body;
}


sub init {
    my ($class, $code) = @_;
    my ($func, $runtime, $context);

    if ($useJE) {
        $runtime = new JE::;
    } else {
        $runtime = JavaScript::Runtime->new;
        $context = $runtime->create_context();
    }
    for $func ($usePerlLib ? @HTTP::ProxyPAC::Functions::PACFunctions
                           : @HTTP::ProxyPAC::Functions::baseFunctions) {
        no strict 'refs';
        if ($useJE) {
            $runtime->new_function($func => sub { &{"HTTP::ProxyPAC::Functions::$func"}(@_) });
        } else {
            $context->bind_function(name => $func,
                                    func => sub { &{"HTTP::ProxyPAC::Functions::$func"}(@_) });
    }   }
    # if we are using the JS library functions from Mozilla, include them before the .pac file
    if (!$usePerlLib) {$code = HTTP::ProxyPAC::Functions::nsProxyAutoConfig . $code}

    if ($useJE) {
        $runtime->eval($code);
        bless { context => $runtime }, $class;
    } else {
        $context->eval($code);
        bless { context => $context }, $class;
}   }

sub find_proxy {
    my($self, $url) = @_;

    Carp::croak("Usage: find_proxy(url)") unless defined $url;

    $url = URI->new($url);

    # there is a PAC file for the interpreter to interpret
     my $res = $self->{context}->eval(sprintf("FindProxyForURL('%s', '%s')",
                                                 $url->as_string, $url->host));

     my @res = HTTP::ProxyPAC::Result->parse($res, $url);
     return wantarray ? @res : $res[0];
}

1;
__END__

=head1 NAME

HTTP::ProxyPAC - use a PAC (Proxy Auto Config) file to get proxy info

=head1 SYNOPSIS

  use HTTP::ProxyPAC;

  my $pac = HTTP::ProxyPAC->new(pacAccessor[, options]);
  
  my $res = $pac->find_proxy($url);
  if ($res->proxy) {
      $ua->proxy('http' => $res->proxy);
  }

=head1 DESCRIPTION

I<HTTP::ProxyPAC> allows use of a Proxy Auto Configuration file to
determine whether a URL needs to be accessed via a proxy server,
and if so the URL of the proxy server.
You can use a I<.pac> file from a web browser, or a I<wpad.dat> file
obtained via the WPAD protocol:
L<http://en.wikipedia.org/wiki/Web_Proxy_Autodiscovery_Protocol>.

=head1 METHODS

=head2 new

  $pac = HTTP::ProxyPAC->new(pacAccessor[, options]);

creates a new HTTP::ProxyPAC object.  I<pacAccessor> leads to a
JavaScript function I<FindProxyForURL>.  It can be

=over 4

=item * a URL like C<http://example.com/proxy.pac>

=item * a file path like C</path/to/proxy.pac>

=item * a reference to a string that contains the Javascript function,
        like C<\$content>, or

=item * an open filehandle from which the Javascript function can be read,
        like C<$fh>

=back

I<options> are by their nature optional.  If included they can be 1 or 2
I<key=E<gt>value> pairs.

The key C<interp> can be followed by a case-independent value C<'js'>
or C<'javascript'> to use the I<JavaScript> module and the
I<SpiderMonkey/libjs> JavaScript interpreter from Mozilla.  Any other
value (nominally C<'je'>) will use the I<JE> module as the interpreter.

If no C<interp> option is provided, I<HTTP::ProxyPAC> will first test
whether I<JavaScript> is installed, and use it if so.  If not it will
test whether I<JE> is installed, and use it if so.  If neither is
installed, the I<new> call will die with an error message.

The key C<lib> can be followed by the case-independent value C<'perl'>
to use the Perl library functions that I<HTTP::ProxyPAC> inherited from
I<HTTP::ProxyAutoConfig>.  They have been improved in version 0.2.
Any other value (nominally C<'js'>), or no C<lib> option at all, will
cause I<HTTP::ProxyPAC> to use the JavaScript library originally
written by NetScape when they originated the Proxy Auto Config scheme.

=head2 find_proxy

  $res = $pac->find_proxy($url);
  @res = $pac->find_proxy($url);

I<find_proxy> executes the I<FindProxyForURL> function provided in
the first operand of I<new>.  It takes a URL as a string or a URI object, and
returns a I<HTTP::ProxyPAC::Result> object that indictaes whether the
URL should be accessed directly, or if not the URL of the proxy server
via which it can be accessed.

I<FindProxyForURL> function can return multiple candidates. In that
case, I<find_proxy> will return all of the Result objects in list
context, or the first Result object in scalar context.

L<http://search.cpan.org/perldoc%3FHTTP::ProxyPAC::Result> describes
how to use the returned object(s).

=head1 WHAT ABOUT HTTP::ProxyAutoConfig?

The I<HTTP::ProxyAutoConfig> module performs a similar function, and
the C<lib=E<gt>'perl'> option uses many functions derived from
I<HTTP::ProxyAutoConfig> (Thanks!).

But the Javascript to Perl translator in I<HTTP::ProxyAutoConfig>
is a pretty hard thing to get right, and can generate bad perl code
if there's any JavaScript in the I<.pac> or I<wpad.dat> file other than
the basic function calls defined for the PAC scheme.

So the original author created this module to use the I<JavaScript> module
(and I<SpiderMonkey/libjs> from mozilla.org) as a JavaScript interpreter.
This might be overkill for this task, but is definitely more robust.

Version 0.2 and higher can use either the I<JavaScript> module or the
I<JE> module which is self-contained and doesn't require you to install
I<SpiderMonkey/libjs> from Mozilla by hand.  Thus CPAN or CPANPLUS can
do the complete installation of version 0.2 or higher.

=head1 AUTHORS

  Tatsuhiko Miyagawa <miyagawa@bulknews.net>
  Craig MacKenna     <craig@animalhead.com> for 0.2

Ryan Eatmon wrote the Perl PAC functions in I<HTTP::ProxyAutoConfig>,
which were used by the original author.  These functions have been
improved in version 0.2 of both modules, and can be replaced by the
original JavaScript functions.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2006, Tatsuhiko Miyagawa
  Copyright (C) 2010, Craig MacKenna

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl 5.10.1.  For more details,
see the full text of the licenses at
L<http://www.perlfoundation.org/artistic_license_1_0> and
L<http://www.gnu.org/licenses/gpl-2.0.html>

This program is distributed in the hope that it will be useful, but
it is provided 'as is' and without any express or implied warranties.
For details, see the full text of the licenses at the above URLs.


=head1 SEE ALSO

L<http://search.cpan.org/perldoc%3FHTTP::ProxyAutoConfig>

L<http://search.cpan.org/perldoc%3FJavaScript>

L<http://search.cpan.org/perldoc%3FJE>

L<http://linuxmafia.com/faq/Web/autoproxy.html>

L<http://en.wikipedia.org/wiki/Proxy_auto-config>

=cut
