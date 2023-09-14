package HTTP::Request::Diff;
use 5.020;
use Moo 2;

our $VERSION = '0.01';

use feature 'signatures';
no warnings 'experimental::signatures';
use Algorithm::Diff;
use Carp 'croak';
use List::Util 'pairs', 'uniq', 'max';
use CGI::Tiny::Multipart 'parse_multipart_form_data';

=encoding utf-8

=head1 NAME

HTTP::Request::Diff - create diffs between HTTP request

=head1 SYNOPSIS

  my $diff = HTTP::Request::Diff->new(
      reference => $req,
      #actual    => $req2,
      skip_headers => \@skip,
      ignore_headers => \@skip2,
      mode => 'exact', # default is 'semantic'
  );

  my @differences = $diff->diff( $actual );
  say Dumper $differences[0];
  # {
  #   'kind' => 'value',
  #   'type' => 'query.foo',
  #   'reference' => [
  #                    undef
  #                  ],
  #   'actual' => [
  #                 'bar'
  #               ]
  # }
  #

=head1 METHODS

=head2 C<< ->new >>

  my $diff = HTTP::Request::Diff->new(
      mode => 'semantic',
  );

=head3 Options

=over 4

=item * C<mode>

  mode => 'strict',

The comparison mode. The default is semantic comparison, which considers some
differences insignificant:

=over 4

=item * The order of HTTP headers

=item * The boundary strings of multipart POST requests

=item * The order of query parameters

=item * The order of form parameters

=back

C<strict> mode wants the requests to be as identical as possible.
C<lax> mode considers query parameters in the POST body as equivalent.

=cut

# lax      -> parameters may be query or post-parameters
# semantic -> many things in requests are equivalent
# strict   -> requests must be string-identical
has 'mode' => (
    is => 'ro',
    default => 'semantic',
);

=item * C<reference>

(optional) The reference request to compare against. Alternatively pass in
the request in the call to C<< ->diff >>.

=cut

has 'reference' => (
    is => 'ro',
);

=item * C<skip_headers>

  skip_headers => ['X-Proxied-For'],

List of headers to skip when comparing. Missing headers are not significant.

=cut

has 'skip_headers' => (
    is => 'ro',
    default => sub { [] },
);

=item * C<ignore_headers>

  ignore_headers => ['Accept-Encoding'],

List of headers to ignore when comparing. Missing headers are significant.

=cut

has 'ignore_headers' => (
    is => 'ro',
    default => sub { [] },
);

=item * C<canonicalize>

Callback to canonicalize a request. The request will be passed in unmodified
either as a string or a L<HTTP::Request>.

=cut

has 'canonicalize' => (
    is => 'ro',
);

=item * C<compare>

Arrayref of things to compare.

=back

=cut

has 'compare' => (
    is => 'ro',
    default => sub {
        return [
            request => 'method',
            uri     => 'host',
            uri     => 'port',
            uri     => 'path',
        ];
    },
);

sub fetch_value($self, $req, $item, $req_params=undef) {
    my $obj;
    if( $item->key eq 'request' ) {
        my $v = $item->value;
        return $req->$v;

    } elsif( $item->key eq 'headers' ) {
        return $req->headers->header( $item->value );

    } elsif( $item->key eq 'query' ) {
        return [ $req->uri->query_param( $item->value )];

    } elsif( $item->key eq 'uri' ) {
        my $u = $req->uri;
        if( my $c = $u->can( $item->value )) {
            return $c->($u)
        } else {
            return
        }

    } elsif( $item->key eq 'form' ) {
        return $req_params->{ $item->value };

    } else {
        croak sprintf "Unknown key '%s'", $item->key;
    }

}

sub get_form_parameters( $self, $req ) {
    my(undef, $boundary) = $req->headers->content_type;
    my $str = $req->content;
    $boundary =~ s!^boundary=!!;

    my %res;
    for my $p (parse_multipart_form_data( \$str, length($str), $boundary)->@*) {
        $res{ $p->{name} } //= [];
        push $res{ $p->{name}}->@*, $p->{content};
    };
    return \%res;
}

sub get_request_header_names( $self, $req ) {
    if( $req =~ /\n/ ) {
        my( $header ) = $req =~ m/^(.*?)\r\n\r\n/ms
            or croak "No header in request <$req>";
        my @headers = ($header =~ /^([A-Z][A-Za-z\d-]+):/mg);
        return @headers;
    } else {
        return
    }
}

=head2 C<< ->diff >>

  my @diff = $diff->diff( $reference, $actual );
  my @diff = $diff->diff( $actual );

Performs the diff and returns an array of hashrefs with differences.

=cut

sub diff( $self, $actual_or_reference, $actual=undef ) {

    # Downconvert things to strings, unless we have strings already
    # reparse into HTTP::Request for easy structural checks

    my $ref;
    if( $actual ) {
        $ref = $actual_or_reference
            or croak "Need a reference request";
    } elsif( $actual_or_reference ) {
        $ref = $self->reference
            or croak "Need a reference request";
        $actual = $actual_or_reference // $self->actual
            or croak "Need an actual request to diff";
    } else {
        $ref = $self->reference
            or croak "Need a reference request";
        $actual = $self->actual
            or croak "Need an actual request to diff";
    }

    # [ ] get query parameter separator, and check these (strict)

    if( my $c = $self->canonicalize ) {
        $ref = $c->( $ref )
            or croak "Request canonicalizer returned no request";
        $actual = $c->( $actual )
            or croak "Request canonicalizer returned no request";
    };

    # maybe cache that in our builder?!
    my %ignore_diff = map {; "headers.$_" => 1 } $self->ignore_headers->@*;

    # maybe cache that in our builder?!
    my %skip_header = map { $_ => 1 } $self->skip_headers->@*;

    if( ref $ref ) {
        $ref = $ref->as_string("\r\n");
    };
    if( ref $actual ) {
        $actual = $actual->as_string("\r\n");
    };
    my $r_ref = HTTP::Request->parse( $ref );
    my $r_actual = HTTP::Request->parse( $actual );

    my @ref_header_order = $self->get_request_header_names( $ref );
    my @actual_header_order = $self->get_request_header_names( $actual );

    my @headers = map {; ("headers", $_) }
                  grep { ! $skip_header{ $_ } }
                  uniq( @ref_header_order,
                        @actual_header_order
                  );

    my @query_params = map {; ("query", $_) }
                  uniq( $r_ref->uri->query_param,
                        $r_actual->uri->query_param,
                  );
    my @form_params;
    my ($ref_params, $actual_params);
    if(    $self->mode eq 'semantic'
        or $self->mode eq 'lax' ) {

        if(     $r_ref->headers->content_type eq 'multipart/form-data'
            and $r_actual->headers->content_type eq 'multipart/form-data' ) {

            # We've checked the content type already, we can ignore the boundary
            # value for semantic checks
            $ignore_diff{ 'headers.Content-Type' } = 1;

            $ref_params = $self->get_form_parameters( $r_ref );
            $actual_params = $self->get_form_parameters( $r_actual );

            @form_params = map {; ("form", $_) }
                    uniq( keys( $ref_params->%* ),
                          keys( $actual_params->%*),
                    );
        };
    };
    my @check = ($self->compare->@*, @headers, @query_params, @form_params);

    if( !@form_params ) {
        push @check, 'request' => 'content';
    };

    if( $self->mode eq 'strict' ) {
        push @check, 'request' => 'header_order';
    }

    # also, we should check for cookies

    my @diff;
    for my $p (pairs @check) {

        my $ref_v;
        my $actual_v;

        if( $p->value eq 'header_order' ) {
            $ref_v = \@ref_header_order;
            $actual_v = \@actual_header_order;

        } else {
            $ref_v = $self->fetch_value( $r_ref, $p, $ref_params );
            $actual_v = $self->fetch_value( $r_actual, $p, $actual_params );
        }

        if( (defined $ref_v xor defined $actual_v)) {
            # One is missing

            push @diff, {
                reference => $ref_v,
                actual => $actual_v,
                type => sprintf( '%s.%s', @$p ),
                kind => 'missing',
            };

        } elsif( ref $ref_v ) {
            # Here we have a list of values, let's check if the lists
            # of values match
            my $diff = Algorithm::Diff->new( $ref_v, $actual_v );
            my $diff_type;
            my @ref;
            my @act;

            while( $diff->Next() ) {
                if( $diff->Same() ) {
                    push @ref, $diff->Items(1);
                    push @act, $diff->Items(2);

                } elsif( !$diff->Items(2) ) {
                    push @ref, $diff->Items(1);
                    push @act, (undef) x scalar($diff->Items(1));
                    $diff_type //= 'missing';

                } elsif( !$diff->Items(1) ) {
                    push @ref, (undef) x scalar($diff->Items(2));
                    push @act, $diff->Items(2);
                    $diff_type //= 'missing';

                } else {
                    my $count = max( scalar $diff->Items(1), scalar $diff->Items(2));
                    push @ref, $diff->Items(1);
                    push @ref, (undef) x (scalar($diff->Items(2)) - $count);
                    push @act, $diff->Items(2);
                    push @act, (undef) x (scalar($diff->Items(1)) - $count);

                    $diff_type = 'value';
                }
            };

            if( $diff_type ) {
                # Do we really want to downconvert to strings?!
                #my $ref_diff = join "\n", @ref;
                #my $actual_diff = join "\n", @act;
                my $ref_diff = \@ref;
                my $actual_diff = \@act;
                push @diff, {
                    reference => $ref_diff,
                    actual => $actual_diff,
                    type => sprintf( '%s.%s', @$p ),
                    kind => $diff_type,
                };
            };

        } elsif( !defined $ref_v and !defined $actual_v ) {
            # neither value exists

        } elsif( $ref_v ne $actual_v ) {
            my $type = sprintf( '%s.%s', @$p );
            if( ! $ignore_diff{ $type }) {
                push @diff, {
                    reference => $ref_v,
                    actual => $actual_v,
                    type => $type,
                    kind => 'value',
                };
            }
        };
    }
    # parameters switching between body and query string
    # if( $ref->headers->content_type eq '' ) {
    # compare form values
    # } else {
    # compare request body
    # }

    return @diff;
}

=head2 C<< ->as_table( @diff ) >>

  my @diff = $diff->diff( $request1, $request2 );
  print $diff->as_table( @diff );
  # +-----------------+-----------+--------+
  # | Type            | Reference | Actual |
  # | request.content | Ümloud    | Umloud |
  # +-----------------+-----------+--------+

Renders a diff as a table, using L<Text::Table::Any>.

=cut

sub as_table($self,@diff) {
    require Text::Table::Any;

    if( @diff ) {
        Text::Table::Any::generate_table(
            rows => [
                ['Type', 'Reference', 'Actual'],
                map {[ $_->{type},
                       ref $_->{reference} ? join "\n", map { $_ // '<missing>' } $_->{reference}->@* : $_->{reference} // '<missing>',
                       ref $_->{actual} ? join "\n", map { $_ // '<missing>' } $_->{actual}->@* : $_->{actual} // '<missing>',
                    ]} @diff
            ],
        );
    };
}

1;
