package HTML::Mason::PSGIHandler;
{
  $HTML::Mason::PSGIHandler::VERSION = '0.53';
}
use strict;
use 5.008_001;

use base qw( HTML::Mason::CGIHandler );
use CGI::PSGI;
use HTML::Mason::Exceptions;

sub new {
    my $class = shift;
    $class->SUPER::new(
        request_class => 'HTML::Mason::Request::PSGI',
        @_,
    );
}

sub as_psgi {
    my $self = shift;
    return sub { $self->handle_psgi( $_[0] ) };
}

sub new_psgi {
    my $class = shift;
    $class->new(@_)->as_psgi;
}

sub handle_psgi {
    my $self = shift;
    my $env  = shift;

    my $p = {
        comp => $env->{PATH_INFO},
        cgi  => CGI::PSGI->new($env),
    };

    my $r = $self->create_delayed_object('cgi_request', cgi => $p->{cgi});
    $self->interp->set_global('$r', $r);

    my $output;
    $self->interp->out_method( \$output );
    $self->interp->delayed_object_params('request', cgi_request => $r);

    my %args = $self->request_args($r);

    my @result = $self->invoke_mason(\%args, $p);
    die if $@;

    return [ $r->psgi_header(-Status => $result[0]), [ defined $output ? $output : () ] ];
}

sub invoke_mason {
    my ($self, $args, $p) = @_;

    my @result;
    if (wantarray) {
        @result = eval { $self->interp->exec($p->{comp}, %$args) };
    } elsif ( defined wantarray ) {
        $result[0] = eval { $self->interp->exec($p->{comp}, %$args) };
    } else {
        eval { $self->interp->exec($p->{comp}, %$args) };
    }

    return @result;
}

sub HTML::Mason::FakeApache::psgi_header {
    my $self = shift;
    my $h = $self->headers_out;
    my $e = $self->err_headers_out;

    my %args = (tied(%$h)->cgi_headers, tied(%$e)->cgi_headers, @_);
    if (exists $h->{Location}) {
        %args = (%args, -Status => 302);
    }

    return $self->query->psgi_header(%args);
}

package HTML::Mason::Request::PSGI;
{
  $HTML::Mason::Request::PSGI::VERSION = '0.53';
}
use strict;
use base qw(HTML::Mason::Request::CGI);

use HTML::Mason::Exceptions;

sub exec {
    my $self = shift;
    my $r = $self->cgi_request;
    my $retval;

    eval { $retval = $self->HTML::Mason::Request::exec(@_) };

    if (my $err = $@) {
        $retval = isa_mason_exception($err, 'Abort')   ? $err->aborted_value
                : isa_mason_exception($err, 'Decline') ? $err->declined_value
                :                                        rethrow_exception $err;
    }

    return $retval;
}

package HTML::Mason::PSGIHandler;

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

HTML::Mason::PSGIHandler - PSGI handler for HTML::Mason

=head1 SYNOPSIS

  # app.psgi
  use HTML::Mason::PSGIHandler;

  my $h = HTML::Mason::PSGIHandler->new(
      comp_root => "/path/to/doc_root", # required
  );

  my $handler = sub {
      my $env = shift;
      $h->handle_psgi($env);
  };

=head1 DESCRIPTION

HTML::Mason::PSGIHandler is a PSGI handler for HTML::Mason. It's based
on HTML::Mason::CGIHandler and allows you to process Mason templates on
any web servers that support PSGI.

=head1 METHODS

=head1 as_psgi

This method returns a subroutine to be used as a PSGI application.

In other words, these are equivalent:

  my $app = sub {
    my $env = shift;
    $h->handle_psgi($env);
  };

  my $app = $h->as_psgi;

=head2 new_psgi

  mount '/foo' => HTML::Mason::PSGIHandler->new_psgi( ... );

This method combines C<new> and C<as_psgi> to immediately return a subroutine
that can be used as a PSGI application.  It's useful for using inline with
L<Plack::Builder>.

=head1 SUPPORT

=over 4

=item * Git Repository

The latest code is available from the git repository at
L<http://github.com/abh/HTML-Mason-PSGIHandler>.

To send patches, make a fork on github and send a pull request.

=item * Bugs

Please report bugs at L<http://github.com/abh/HTML-Mason-PSGIHandler/issues>.

=back

=head1 AUTHORS

Ask Bjørn Hansen E<lt>miyagawa@bulknews.netE<gt>, Ricardo Signes E<lt>rjbs@cpan.orgE<gt>,
Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>, Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::PSGI> L<Plack> L<PSGI> L<HTML::Mason::CGIHandler>

=cut
