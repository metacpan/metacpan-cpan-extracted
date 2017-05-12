package TestOOCallbacks;
use strict;
use base qw(Params::Callback);
use constant CLASS_KEY => 'OOCBTester';
__PACKAGE__->register_subclass;

sub simple : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = 'Success';
}

sub priority : Callback {
    my $self = shift;
    my $params = $self->params;
    my $val = $self->value;
    $val = '5' if $val eq 'def';
    $params->{result} .= " $val";
}

sub multi : Callback {
    my $self = shift;
    my $params = $self->params;
    my $val = $self->value;
    $params->{result} = scalar @$val;
}

sub count : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{result}++;
}

sub upperit : PreCallback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = uc $params->{result} if $params->{do_upper};
}

sub lowerit : PostCallback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = lc $params->{result} if $params->{do_lower};
}

sub add_note : Callback {
    my $self = shift;
    $self->notes($self->value, $self->params->{note});
}

sub get_note : Callback {
    my $self = shift;
    $self->params->{result} = $self->notes($self->value);
}

sub list_notes : Callback {
    my $self = shift;
    my $params = $self->params;
    my $notes = $self->notes;
    for my $k (sort keys %$notes) {
        $params->{result} .= "$k => $notes->{$k}\n";
    }
}

sub clear : Callback {
    my $self = shift;
    $self->cb_request->clear_notes;
}

sub mason_note : Callback {
    my $self = shift;
    $self->params->{result} = sub { shift->notes($self->value ) };
}

sub cbr_note : Callback {
    my $self = shift;
    $self->params->{result} = sub { shift->interp->cb_request->notes($self->value ) };
}

package TestCallbacks;

use strict;
use HTML::Mason::ApacheHandler;
use HTML::Mason::Exceptions;
use constant HTTP_OK => 200;
use constant KEY => 'myCallbackTester';

my $server;
if ($ENV{MOD_PERL_API_VERSION}) {
    require Apache2::ServerUtil;
    $server = Apache2::ServerUtil->server;
} else {
    require Apache;
    $server = Apache->server;
}

my $cfg = $server->dir_config;
my %params = (
    comp_root    => $cfg->{MasonCompRoot},
    interp_class => 'MasonX::Interp::WithCallbacks',
);

sub simple {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result} = 'Success';
}

sub priority {
    my $cb = shift;
    my $params = $cb->params;
    my $val = $cb->value;
    $val = '5' if $val eq 'def';
    $params->{result} .= " $val";
}

sub multi {
    my $cb = shift;
    my $params = $cb->params;
    my $val = $cb->value;
    $params->{result} = scalar @$val;
}

sub count {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result}++;
}

my $url = 'http://example.com/';
sub redir {
    my $cb = shift;
    my $wait = $cb->value;
    $cb->redirect($url, $wait);
}

sub add_header {
    my $cb = shift;
    my $params = $cb->params;
    $cb->apache_req->err_headers_out->set(@{$params}{qw(header value)});
}

sub test_abort {
    my $cb = shift;
    $cb->abort($cb->value);
}

sub exception {
    my $cb = shift;
    my $params = $cb->params;
    if ($cb->value) {
        # Throw an exception object.
        HTML::Mason::Exception->throw( error => "He's dead, Jim" );
    } else {
        # Just die.
        die "He's dead, Jim";
    }
}

sub add_note {
    my $cb = shift;
    $cb->notes($cb->value, $cb->params->{note});
}

sub get_note {
    my $cb = shift;
    $cb->params->{result} = $cb->notes($cb->value);
}

sub list_notes {
    my $cb = shift;
    my $params = $cb->params;
    my $notes = $cb->notes;
    for my $k (sort keys %$notes) {
        $params->{result} .= "$k => $notes->{$k}\n";
    }
}

sub clear {
    my $cb = shift;
    $cb->cb_request->clear_notes;
}

sub mason_note {
    my $cb = shift;
    $cb->params->{result} = sub { shift->notes($cb->value ) };
}

sub cbr_note {
    my $cb = shift;
    $cb->params->{result} = sub { shift->interp->cb_request->notes($cb->value ) };
}

sub upperit {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result} = uc $params->{result} if $params->{do_upper};
}

sub lowerit {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result} = lc $params->{result} if $params->{do_lower};
}

my $ah = HTML::Mason::ApacheHandler->new
  ( %params,
    callbacks => [{ pkg_key => KEY,
                    cb_key  => 'simple',
                    cb      => \&simple
                  },
                  { pkg_key => KEY,
                    cb_key  => 'priority',
                    cb      => \&priority
                  },
                  { pkg_key => KEY,
                    cb_key  => 'multi',
                    cb      => \&multi
                  },
                  { pkg_key => KEY,
                    cb_key  => 'count',
                    cb      => \&count
                  },
                  { pkg_key => KEY,
                    cb_key  => 'redir',
                    cb      => \&redir
                  },
                  { pkg_key => KEY,
                    cb_key  => 'add_header',
                    cb      => \&add_header
                  },
                  { pkg_key => KEY,
                    cb_key  => 'test_abort',
                    cb      => \&test_abort
                  },
                  { pkg_key => KEY,
                    cb_key  => 'exception',
                    cb      => \&exception
                  },
                  { pkg_key => KEY,
                    cb_key  => 'add_note',
                    cb      => \&add_note
                  },
                  { pkg_key => KEY,
                    cb_key  => 'get_note',
                    cb      => \&get_note
                  },
                  { pkg_key => KEY,
                    cb_key  => 'list_notes',
                    cb      => \&list_notes
                  },
                  { pkg_key => KEY,
                    cb_key  => 'clear',
                    cb      => \&clear
                  },
                  { pkg_key => KEY,
                    cb_key  => 'mason_note',
                    cb      => \&mason_note
                  },
                  { pkg_key => KEY,
                    cb_key  => 'cbr_note',
                    cb      => \&cbr_note
                  },
                 ],
    pre_callbacks => [\&upperit],
    post_callbacks => [\&lowerit],
  );

my %tests =
  ( '/exception_handler' => sub {
        my $ahwc = HTML::Mason::ApacheHandler->new
          ( %params,
            cb_exception_handler => sub {
                # Just log the exception.
                print STDERR 'Got "', shift->error, "\"\n"
            },
            callbacks => [{ pkg_key => KEY,
                            cb_key  => 'exception',
                            cb      => \&exception }]
          );
        $ahwc->handle_request(@_);
    },
    '/no_null' => sub {
        my $ahwc = HTML::Mason::ApacheHandler->new
          ( %params,
            ignore_nulls => 1,
            callbacks => [{ pkg_key => KEY,
                            cb_key  => 'simple',
                            cb      => \&simple }]
          );
        $ahwc->handle_request(@_);
    },
    '/oop' => sub {
        my $ahwc = HTML::Mason::ApacheHandler->new
          ( %params,
            cb_classes => 'ALL'
          );
        $ahwc->handle_request(@_);
    },
  );

sub handler {
    if (my $code = $tests{$_[0]->uri}) {
        return $code->(@_)
    }
    return $ah->handle_request(@_);
}


1;
__END__
