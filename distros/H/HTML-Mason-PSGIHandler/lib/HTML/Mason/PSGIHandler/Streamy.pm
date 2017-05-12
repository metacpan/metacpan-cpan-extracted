package HTML::Mason::PSGIHandler::Streamy;
{
  $HTML::Mason::PSGIHandler::Streamy::VERSION = '0.53';
}
use strict;
use 5.008_001;

require HTML::Mason::PSGIHandler; # XXX: this is fucked
use base qw( HTML::Mason::PSGIHandler );

sub handle_psgi {
    my $self = shift;
    my $env  = shift;

    my $p = {
        comp => $env->{PATH_INFO},
        cgi  => CGI::PSGI->new($env),
    };

    my $r = $self->create_delayed_object('cgi_request', cgi => $p->{cgi});
    $self->interp->set_global('$r', $r);

    my $headers_sent;
    my $responder;
    my $writer;

    $self->interp->out_method(
        sub {
            # XXX: the original code from HTTP::Server::Simple::Mason
            # has the following comment. need to verify memory usage
            # without the following hack.

            # We use instance here because if we store $request we get a
            # circular reference and a big memory leak.
            my $m = HTML::Mason::Request->instance;
            my $r = $m->cgi_request;
            unless ($headers_sent) {
                die "PANIC: responder not configured yet" unless $responder;
                $writer = $responder->([$r->psgi_header()]);
                $headers_sent = 1;
            }

            $writer->write($_) for @_;
        });

    $self->interp->delayed_object_params('request', cgi_request => $r);

    my %args = $self->request_args($r);

    return sub {
        $responder = shift;
        my @result = $self->invoke_mason(\%args, $p);
        die if $@; # XXX: format 500?
        unless ($writer) {
            return $responder->([$r->psgi_header(-Status => $result[0]), []]);
        }
        undef $responder;
        $writer->close();
        undef $writer;
    }

}

1;
