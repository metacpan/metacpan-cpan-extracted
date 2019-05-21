package MPM::Waldo;
use strict;
use utf8;

=encoding utf8

=head1 NAME

MPM::Waldo - REST controller

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

  # Apache2 config section
  <IfModule mod_perl.c>
    PerlOptions +GlobalRequest
    PerlModule MPM::Waldo
    <Location /waldo>
      PerlInitHandler MPM::Waldo
      PerlSetVar Location waldo
      PerlSetVar Debug on
      PerlSetVar TestValue Blah-Blah-Blah
    </Location>
  </IfModule>

=head1 DESCRIPTION

REST controller

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use base qw/MPMinus::REST/;

use Apache2::Util;
use Apache2::Const -compile => qw/ :common :http /;

use Encode;

use MPMinus::Util qw/ getHiTime /;

=head1 METHODS

Base methods

=head2 handler

See L<MPMinus::REST/handler>

=head2 hInit

See L<MPMinus::REST/hInit>

=cut

sub handler : method {
    my $class = (@_ >= 2) ? shift : __PACKAGE__;
    my $r = shift;
    #
    # ... preinit statements ...
    #
    return $class->init($r);
}

sub hInit {
    my $self = shift;
    my $r = shift;

    # Dir config variables
    $self->set_dvar(testvalue => $r->dir_config("testvalue") // "");

    # Session variables
    $self->set_svar(init_label => __PACKAGE__);

    return $self->SUPER::hInit($r);
}

=head1 RAMST METHODS

RAMST methods

=head2 GET /waldo

    curl -v --raw -H "Accept: application/json" http://localhost/waldo?bar=123

    > GET /waldo?bar=123 HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: application/json
    >
    < HTTP/1.1 200 OK
    < Date: Thu, 25 Apr 2019 12:30:55 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Content-Length: 528
    < Content-Type: application/json
    <
    {
       "key" : "GET#/#default",
       "uri" : "/waldo",
       "dvars" : {
          "debug" : "on",
          "testvalue" : "Blah-Blah-Blah",
          "location" : "waldo"
       },
       "remote_addr" : "127.0.0.1",
       "name" : "getIndex",
       "usr" : {
          "bar" : "123"
       },
       "stamp" : "[26264] MPM::Foo at Thu Apr 25 15:30:55 2019",
       "code" : 200,
       "error" : "",
       "foo_attr" : "My foo attribute value",
       "servers" : [
          "MPM-Foo#waldo"
       ],
       "path" : "/",
       "server_status" : 1,
       "debug_time" : "0.003",
       "location" : "waldo"
    }

Examples:

    curl -v --raw http://localhost/waldo
    curl -v --raw -H "Accept: application/json" http://localhost/waldo
    curl -v --raw -H "Accept: application/xml" http://localhost/waldo
    curl -v --raw -H "Accept: application/x-yaml" http://localhost/waldo

=cut

__PACKAGE__->register_handler( # GET /
    handler => "getIndex",
    method  => "GET",
    path    => "/",
    query   => undef,
    attrs   => {
            foo             => 'My foo attribute value',
            #debug           => 'on',
            #content_type    => 'application/json',
            #deserialize     => 1,
            serialize       => 1,
        },
    description => "Index",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;
    my $q = $self->get("q");
    my $usr = $self->get("usr");
    #my $req_data = $self->get("req_data");
    #my $res_data = $self->get("res_data");

    # Output
    my $uri = $r->uri || ""; $uri =~ s/\/+$//;
    $self->set( res_data => {
        foo_attr        => $self->get_attr("foo"),
        name            => $name,
        server_status   => $self->status,
        code            => $self->code,
        error           => $self->error,
        key             => $self->get_svar("key"),
        path            => $self->get_svar("path"),
        remote_addr     => $self->get_svar("remote_addr"),
        location        => $self->{location},
        stamp           => $self->{stamp},
        dvars           => $self->{dvars},
        uri             => $uri,
        debug_time      => sprintf("%.3f", (getHiTime() - $self->get_svar('hitime'))),
        usr             => $usr,
        servers         => [$self->registered_servers],
    });

    return 1; # Or 0 only!!
});

1;

=head1 DEPENDENCIES

C<mod_perl2>, L<MPMinus>, L<MPMinus::REST>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<MPMinus>, L<MPMinus::REST>, Examples on L<MPMinus>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

__END__
