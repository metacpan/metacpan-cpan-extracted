package t::lib::Test::HT;
use strict;
use warnings;

use HTTP::Throwable::Factory;
use Scalar::Util qw(blessed reftype);
use Test::Deep qw(cmp_deeply bag);
use Test::Fatal;
use Test::More;

use Sub::Exporter -setup => {
    exports => [ qw(ht_test) ],
    groups  => [ default => [ '-all' ] ],
};

{
  package MyFactory;
  use base 'HTTP::Throwable::Factory';

  sub extra_roles {
    return qw(
        HTTP::Throwable::Role::NoBody
    );
  }
}

sub ht_test {
    my ($identifier, $arg);

    ($identifier, $arg) = ref $_[0] ? (undef, shift) : (shift, shift || {});

    my $comment    = (defined $_[0] and ! ref $_[0])
                   ? shift(@_)
                   : sprintf("ht_test at %s, line %s", (caller)[1, 2]);

    my $extra      = (! defined $_[0])         ? {}
                   : (! reftype $_[0])         ? confess("bogus extra value")
                   : (reftype $_[0] eq 'CODE') ? { assert => $_[0] }
                   : (reftype $_[0] eq 'HASH') ? $_[0]
                   :                             confess("bogus extra value");

    subtest $comment => sub {
        for my $factory_class (
            'HTTP::Throwable::Factory',
            'MyFactory',
        ) {
            subtest "...using $factory_class" => sub {
                local $Test::Builder::Level = $Test::Builder::Level + 1;

                my $err = exception {
                    $factory_class->throw($identifier, $arg);
                };

                if (ok( blessed($err), "thrown exception is an object")) {
                  ok( $err->does('HTTP::Throwable') );
                  ok( $err->does('Throwable') );
                } else {
                  diag "want: a blessed exception object";
                  diag "have: $err";

                  die "further testing would be useless";
                }

                if (my $code = $extra->{code}) {
                    is($err->status_code, $code, "got expected status code");

                    $code =~ /^3/
                    ? ok(   $err->is_redirect, "it's a redirect" )
                    : ok( ! $err->is_redirect, "it's not a redirect" );

                    $code =~ /^4/
                    ? ok(   $err->is_client_error, "it's a client error")
                    : ok( ! $err->is_client_error, "it's a not client error");

                    $code =~ /^5/
                    ? ok(   $err->is_server_error, "it's a server error")
                    : ok( ! $err->is_server_error, "it's not a server error");
                }

                if (defined $extra->{reason}) {
                    is($err->reason, $extra->{reason}, "got expected reason");
                }

                my $status_line;
                if (defined $extra->{code} and defined $extra->{reason}) {
                    $status_line = join q{ }, @$extra{ qw(code reason) };

                    is(
                        $err->status_line,
                        $status_line,
                        "expected status line",
                    );
                }

                # XXX: Gross, sorry.  -- rjbs, 2011-02-21
                my $as_string = exists $extra->{as_string}
                              ? $extra->{as_string}
                              : $factory_class eq 'MyFactory'
                                ? $status_line
                                : exists $extra->{body}
                                  ? $extra->{body}
                                  : $status_line;

                cmp_deeply($err->as_string, $as_string, "expected as_string")
                  if defined $as_string;

                {
                    my $body = exists $extra->{body}
                              ? $extra->{body}
                              : $status_line;

                    # XXX: Another gross conditional -- rjbs, 2011-02-21
                    $body = undef if $factory_class eq 'MyFactory';

                    my $length = defined $extra->{length} ? $extra->{length}
                               : defined length $body     ? length $body
                               :                            0;

                    my $psgi = $err->as_psgi;

                    my $expect = [
                        $extra->{code},
                        bag(
                            (defined $body ? ('Content-Type'   => 'text/plain')
                                           : ()),
                            'Content-Length' => $length,
                            @{ $extra->{headers} || [] },
                        ),
                        [ defined $body ? $body : () ]
                    ];

                    cmp_deeply(
                        $psgi,
                        $expect,
                        '... got the right PSGI transformation'
                    );
                }

                if ($extra->{assert}) {
                    local $_ = $err;
                    $extra->{assert}->($err);
                }
            }
        }
    };
}

1;
