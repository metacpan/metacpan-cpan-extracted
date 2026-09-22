package Linode::API;
$Linode::API::VERSION = '0.001';
#ABSTRACT: A client for the Linode API, generated from Linode's own OpenAPI specification

use 5.016;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use parent qw{OpenAPI::Client};

use Carp             qw{croak};
use Cpanel::JSON::XS qw{decode_json};
use File::ShareDir   qw{dist_file};
use File::Slurper    qw{read_binary};
use Mojo::Util       qw{monkey_patch};


sub new {
    my ( $class, %options ) = @_;

    my $token         = delete $options{token};
    my $api_version   = delete $options{api_version}   // 'v4';
    my $specification = delete $options{specification} // dist_file( 'Linode-API', 'openapi.json' );

    my $self = $class->SUPER::new( _specification( $specification, $api_version ), %options );
    _alias_operations( ref $self, $self->validator->routes );
    if ( defined $token ) {
        $self->on( after_build_tx => sub { $_[1]->req->headers->authorization("Bearer $token") } );
    }

    return $self;
}

# OpenAPI::Client names the class it generates after the hashref's address, so
# handing it the same hashref every time is what stops each client leaking a class.
sub _specification {
    my ( $file, $api_version ) = @_;

    state %specifications;
    return $specifications{"$api_version\0$file"} //= do {
        my $spec = decode_json( read_binary($file) );
        _fix_api_version( $spec, $api_version );
        _fix_json_headers($spec);
        _fix_closed_all_of($spec);
        $spec;
    };
}

# Write the version into each path, because OpenAPI::Client fills a path in
# before it validates, so a schema default for {apiVersion} never reaches the URL.
# A path that does not offer the version asked for gets the first one it does.
sub _fix_api_version {
    my ( $spec, $api_version ) = @_;

    my ( $paths, %offered ) = ( $spec->{paths} );
    foreach my $path ( keys %$paths ) {
        my $item = delete $paths->{$path};

        my ($parameter) = grep { ( $_->{name} // q{} ) eq 'apiVersion' } @{ $item->{parameters} // [] };
        my @versions    = @{ $parameter->{schema}{enum} // [] };
        $offered{$_} = 1 for @versions;

        if (@versions) {
            my $version = ( grep { $_ eq $api_version } @versions ) ? $api_version : $versions[0];
            $item->{parameters} = [ grep { $_ != $parameter } @{ $item->{parameters} } ];
            $path =~ s{\{apiVersion\}}{$version}g;
        }
        $paths->{$path} = $item;
    }

    croak "api_version '$api_version' is not in the specification, which offers [" . join( ', ', sort keys %offered ) . ']' unless $offered{$api_version};

    return $spec;
}

# The specification describes X-Filter as the object its JSON encodes, and
# OpenAPI::Client would send that object as HASH(0x...), so a header is a string.
sub _fix_json_headers {
    my ($spec) = @_;

    foreach my $item ( values %{ $spec->{paths} } ) {
        my @operations = grep { ref $_ eq 'HASH' } values %$item;
        foreach my $parameter ( map { @{ $_->{parameters} // [] } } $item, @operations ) {
            next unless ( $parameter->{in} // q{} ) eq 'header';
            next if ( $parameter->{schema}{type} // q{} ) eq 'string';
            $parameter->{schema} = { type => 'string', description => 'JSON' };
        }
    }

    return $spec;
}

# A member of an allOf that says additionalProperties: false forbids what its
# siblings declare, so Linode's check of the body is the one that has to do.
sub _fix_closed_all_of {
    my ($node) = @_;

    if ( ref $node eq 'ARRAY' ) {
        _fix_closed_all_of($_) foreach @$node;
    }
    elsif ( ref $node eq 'HASH' ) {
        if ( ref $node->{allOf} eq 'ARRAY' && @{ $node->{allOf} } > 1 ) {
            foreach my $member ( grep { ref $_ eq 'HASH' && _is_closed($_) } @{ $node->{allOf} } ) {
                delete $member->{additionalProperties};
            }
        }
        _fix_closed_all_of($_) foreach values %$node;
    }

    return $node;
}

# A JSON false is an object, so ask it what it is rather than whether it is a ref.
sub _is_closed {
    my ($schema) = @_;
    my $additional = $schema->{additionalProperties};
    return defined $additional && ref $additional ne 'HASH' && !$additional;
}

# Give each kebab-case operation a snake_case name a caller can write as a
# bareword, never replacing a method the class already has.
sub _alias_operations {
    my ( $class, $routes ) = @_;

    state %aliased;
    return if $aliased{$class}++;

    foreach my $operation ( grep { defined && index( $_, q{-} ) >= 0 } map { $_->{operation_id} } $routes->each ) {
        foreach my $method ( $operation, "${operation}_p" ) {
            ( my $alias = $method ) =~ tr/-/_/;
            monkey_patch( $class, $alias => $class->can($method) ) unless $class->can($alias);
        }
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linode::API - A client for the Linode API, generated from Linode's own OpenAPI specification

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Linode::API();

    my $linode = Linode::API->new( token => $personal_access_token );

    my $tx = $linode->get_linode_instances( { page_size => 500 } );
    die $tx->error->{message} if $tx->error;

    say $_->{label} for @{ $tx->res->json->{data} };

    # Every operation also has a _p form that returns a Mojo::Promise.
    $linode->get_linode_instance_p( { linodeId => $id } )->then(
        sub {
            my ($tx) = @_;
            say $tx->res->json->{status};
        }
    )->wait;

=head1 DESCRIPTION

This is L<OpenAPI::Client> pointed at the specification Linode publishes for its
API, with the two things every caller would otherwise repeat done once: the
bearer token goes on every request, and the API version is fixed when the
client is built rather than passed to every call.

There is one method per operation in the specification, named by its
C<operationId> with the hyphens made underscores -- C<get_linode_instances>,
C<post_linode_instance>, C<delete_domain_record> and so on.  Linode's API
reference lists the operationIds, and so does the specification in this
distribution's share directory.  The hyphenated names work too, through
C<call>:

    my $tx = $linode->call( 'get-linode-instances' => { page_size => 500 } );

Each takes a hashref
of the operation's path, query and header parameters, and a request body as
C<< json => {...} >>:

    my $tx = $linode->post_linode_instance(
        {},
        json => {
            region => 'us-east',
            type   => 'g6-nanode-1',
            image  => 'linode/debian12',
            label  => $label,
        },
    );

What comes back is a L<Mojo::Transaction::HTTP>.  Its C<res> is the response,
and C<< $tx->res->json >> is the decoded body.

=head2 What is changed in the specification

The specification is changed in memory as it is loaded, where following it to
the letter would send the wrong thing or refuse the right one:

=over 4

=item * The API version is written into each path, as L</new> describes.

=item * A header parameter is always a string.  Linode describes C<X-Filter> as
the object its JSON encodes, and that object would be sent as C<HASH(0x...)>.

=item * A member of an C<allOf> never forbids additional properties.  Linode
closes one member of several, which forbids everything the other members
declare: C<post_linode_instance> would refuse C<region> and C<type>, which it
also requires.  Linode still checks the body when it gets it.

=back

=head2 Telling the failures apart

C<< $tx->error >> is set for three different things, and it is worth knowing
which you have before acting on it:

=over 4

=item * The request did not match the specification.

Nothing was sent.  The response is a C<400> that this module made up, and its
body lists what was wrong under C<errors>.  C<< $tx->req->url >> still shows
where it would have gone.

=item * The request never got an answer.

DNS, a refused connection, TLS, or a timeout.  C<< $tx->error->{code} >> is
undefined, and C<< $tx->error->{message} >> says which.

=item * Linode said no.

C<< $tx->error->{code} >> is the status, and the body is Linode's own
C<< { errors => [ { reason => ..., field => ... } ] } >>.

=back

=head2 Paging

A list operation returns one page, 100 items long unless you ask for up to 500
with C<page_size>.  The body says C<page> and C<pages>; ask for the next page
until they are equal.  The operations that take an C<X-Filter> header can narrow
the list on Linode's side instead.  Its value is JSON, which you encode
yourself; a hashref is refused rather than sent:

    $linode->get_linode_instances( { 'X-Filter' => encode_json( { label => $label } ) } );

=head2 Timeouts

The requests go through a L<Mojo::UserAgent>, whose defaults are a 10 second
connect timeout and a 40 second inactivity timeout, with no limit on the request
as a whole.  To change them, pass a C<ua> of your own.

=head2 The specification's license

The specification in this distribution's share directory, C<openapi.json>, is
Linode's, distributed unedited from L<https://github.com/linode/linode-api-docs>
under the Apache License 2.0.  That license is beside it, as
C<openapi.LICENSE.txt>.  Everything else in the distribution is under the MIT
license below.

=head1 METHODS

=head2 new

    my $linode = Linode::API->new(%options);

Loads the specification and returns a client for it.  Takes a list of
key-value pairs:

=over 4

=item token

A Linode personal access token, sent as a bearer token on every request.
Without one, only the handful of operations that need no authentication will
work.

=item api_version

C<v4>, which is the default, or C<v4beta> for operations Linode has not
released yet.  It is a preference rather than a rule: an operation that exists
in only one version is sent to that version whichever you ask for.

=item specification

The path to an OpenAPI specification to use instead of the one shipped with
this distribution.  Linode publishes theirs from
L<https://github.com/linode/linode-api-docs>, and a newer copy of it is the
reason to pass this.

=back

Anything else is passed to L<OpenAPI::Client/new> unchanged: C<base_url>,
C<ua>, C<coerce>, and C<app> for testing against a local L<Mojolicious>
application.

The object returned is of a class generated from the specification, which
inherits from this one.  Test it with C<isa>, not C<ref>.

Reading the specification and building a method for each of its operations
takes a couple of seconds.  That is done once for each specification file and
API version in a process, and every later client built from the same pair
reuses it.

=for test_synopsis use feature qw{say}; my ( $personal_access_token, $id );

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Linode-API/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
