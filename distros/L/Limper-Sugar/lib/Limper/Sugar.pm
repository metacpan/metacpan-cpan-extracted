package Limper::Sugar;
$Limper::Sugar::VERSION = '0.002';
use base 'Limper';
use 5.10.0;
use strict;
use warnings;

use File::Spec;
use File::Basename();

package		# newline because Dist::Zilla::Plugin::PkgVersion and PAUSE indexer
  Limper;

push @Limper::EXPORT, qw/ limper_version load captures dirname halt send_error uri_for redirect content_type path /;

sub limper_version { $Limper::VERSION }

sub load { require $_ for @_ }

sub captures { {%+} }

sub dirname { File::Basename::dirname($_[0]) }

# WARNING: this does not exit the current route
sub halt { @_ }

# WARNING: this does not exit the current route
sub send_error {
    my ($content, $status) = @_;
    status $status // 500;
    $content;
}

my $scheme_rx = qr{^[a-z][a-z0-9+.-]*://}i;	# RFC 2396

sub uri_for {
    return $_[0] unless $_[0] =~ $scheme_rx;
    request->{hheaders}{'x-forwarded-host'} // request->{hheaders}{host}, $_[0];
}

sub redirect {
    my ($uri, $status) = @_;
    status $status // 302;
    headers Location => uri_for $uri;
}

sub content_type {
    headers 'Content-Type' => $_[0];
}

sub path {
    $_ = File::Spec->catfile(@_);
    s|/\./|/|g;
    1 while s|[^/]*/\.\./||g;
    $_;
}

1;

=for Pod::Coverage

=head1 NAME

Limper::Sugar - sugary things like Dancer does

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Limper::Sugar;
  use Limper;   # this must come after all extensions

  # routes

  limp;

=head1 DESCRIPTION

B<Limper::Sugar> extends L<Limper> to have sugary things like in L<Dancer>.

B<NOTE>: this is all as yet untested.

B<USE OF THIS MODULE IS STRONGLY DISCOURAGED IN PUBLIC CODE. DO NOT USE IT
IN A PLUGIN.> It is meant to facilitate switching from Dancer.  Consider
everything in here B<deprecated>.  Some of these may end up in Limper proper
at some point, while others offer no significant benefit.  If you really
feel it should be in L<Limper>, make a request.

=head1 EXPORTS

The following are all additionally exported by default:

  limper_version load captures dirname halt send_error uri_for redirect content_type path

=head1 FUNCTIONS

=head2 limper_version

Returns the version of Limper in use.

=head2 load

Sugar around Perl's B<require>, but can take a list of expressions to require.

=head2 captures

Returns a copy of C<%+> (named capture groups) as a hashref.

=head2 dirname

Exactly the same as L<File::Basename/dirname>.

=head2 uri_for

Prepends the request's B<X-Forwarded-Host> or B<Host> value to the path.

=head2 redirect

  redirect $path, $status;

Sugar for the following, plus it will turn a Limper path into a URI.

  status $status // 302;
  headers Location => uri_for $path;

=head2 content_type

Sugar for C<< headers 'Content-Type' => $type >>.
Note that this does not support abbreviated content types.

=head2 path

Sugar around L<File::Spec/catfile>.

=head2 halt

Merely returns B<@_>.

B<Warning>: In Dancer, this stops execution of the route. In Limper, there
is currently no such mechanism.  This may change in the future.

=head2 send_error

  send_error $content, $status;

Sugar for the following:

  status $status // 500;
  $content;

B<Warning>: In Dancer, this stops execution of the route. In Limper, there
is currently no such mechanism.  This may change in the future.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ashley Willis E<lt>ashley+perl@gitable.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Limper>

=cut
