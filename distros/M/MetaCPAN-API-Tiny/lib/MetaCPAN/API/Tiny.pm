package MetaCPAN::API::Tiny;
$MetaCPAN::API::Tiny::VERSION = '1.150270';
use strict;
use warnings;
# ABSTRACT: (DEPRECATED) A Tiny API client for MetaCPAN

use Carp;
use JSON::PP 'encode_json', 'decode_json';
use HTTP::Tiny;


sub new {
    my ($class, @args) = @_;

    $#_ % 2 == 0
        or croak 'Arguments must be provided as name/value pairs';
    
    my %params = @args;

    die 'ua_args must be an array reference'
        if $params{ua_args} && ref($params{ua_args}) ne 'ARRAY';

    my $self = +{
        base_url => $params{base_url} || 'http://api.metacpan.org/v0',
        ua => $params{ua} || HTTP::Tiny->new(
            $params{ua_args}
                ? @{$params{ua_args}}
                : (agent => 'MetaCPAN::API::Tiny/'
                    . ($MetaCPAN::API::VERSION || 'xx'))),
    };
    
    return bless($self, $class);
}

sub _build_extra_params {
    my $self = shift;

    @_ % 2 == 0
        or croak 'Incorrect number of params, must be key/value';

    my %extra = @_;
    my $ua = $self->{ua};

    foreach my $key (keys %extra)
    {
        # The implementation in HTTP::Tiny uses + instead of %20, fix that
        $extra{$key} = $ua->_uri_escape($extra{$key});
        $extra{$key} =~ s/\+/%20/g;
    }

    my $params = join '&', map { "$_=" . $extra{$_} } sort keys %extra;

    return $params;
}


# /source/{author}/{release}/{path}
sub source {
    my $self  = shift;
    my %opts  = @_ ? @_ : ();
    my $url   = '';
    my $error = "Provide 'author' and 'release' and 'path'";

    %opts or croak $error;

    if (
        defined ( my $author  = $opts{'author'}  ) &&
        defined ( my $release = $opts{'release'} ) &&
        defined ( my $path    = $opts{'path'}    )
      ) {
        $url = "source/$author/$release/$path";
    } else {
        croak $error;
    }

    $url = $self->{base_url} . "/$url";
    
    my $result = $self->{ua}->get($url);
    $result->{'success'}
        or croak "Failed to fetch '$url': " . $result->{'reason'};

    return $result->{'content'};
}


# /release/{distribution}
# /release/{author}/{release}
sub release {
    my $self  = shift;
    my %opts  = @_ ? @_ : ();
    my $url   = '';
    my $error = "Either provide 'distribution', or 'author' and 'release', " .
                "or 'search'";

    %opts or croak $error;

    my %extra_opts = ();

    if ( defined ( my $dist = $opts{'distribution'} ) ) {
        $url = "release/$dist";
    } elsif (
        defined ( my $author  = $opts{'author'}  ) &&
        defined ( my $release = $opts{'release'} )
      ) {
        $url = "release/$author/$release";
    } elsif ( defined ( my $search_opts = $opts{'search'} ) ) {
        ref $search_opts && ref $search_opts eq 'HASH'
            or croak $error;

        %extra_opts = %{$search_opts};
        $url        = 'release/_search';
    } else {
        croak $error;
    }

    return $self->fetch( $url, %extra_opts );
}


# /pod/{module}
# /pod/{author}/{release}/{path}
sub pod {
    my $self  = shift;
    my %opts  = @_ ? @_ : ();
    my $url   = '';
    my $error = "Either provide 'module' or 'author and 'release' and 'path'";

    %opts or croak $error;

    if ( defined ( my $module = $opts{'module'} ) ) {
        $url = "pod/$module";
    } elsif (
        defined ( my $author  = $opts{'author'}  ) &&
        defined ( my $release = $opts{'release'} ) &&
        defined ( my $path    = $opts{'path'}    )
      ) {
        $url = "pod/$author/$release/$path";
    } else {
        croak $error;
    }

    # check content-type
    my %extra = ();
    if ( defined ( my $type = $opts{'content-type'} ) ) {
        $type =~ m{^ text/ (?: html|plain|x-pod|x-markdown ) $}x
            or croak 'Incorrect content-type provided';

        $extra{headers}{'content-type'} = $type;
    }

    $url = $self->{base_url}. "/$url";
    
    my $result = $self->{ua}->get( $url, \%extra );
    $result->{'success'}
        or croak "Failed to fetch '$url': " . $result->{'reason'};

    return $result->{'content'};
}


# /module/{module}
sub module {
    my $self = shift;
    my $name = shift;

    $name or croak 'Please provide a module name';

    return $self->fetch("module/$name");
}


# file() is a synonym of module
sub file { goto &module }


# /author/{author}
sub author {
    my $self = shift;
    my ( $pause_id, $url, %extra_opts );

    if ( @_ == 1 ) {
        $url = 'author/' . shift;
    } elsif ( @_ == 2 ) {
        my %opts = @_;

        if ( defined $opts{'pauseid'} ) {
            $url = "author/" . $opts{'pauseid'};
        } elsif ( defined $opts{'search'} ) {
            my $search_opts = $opts{'search'};

            ref $search_opts && ref $search_opts eq 'HASH'
                or croak "'search' key must be hashref";

            %extra_opts = %{$search_opts};
            $url        = 'author/_search';
        } else {
            croak 'Unknown option given';
        }
    } else {
        croak 'Please provide an author PAUSEID or a "search"';
    }

    return $self->fetch( $url, %extra_opts );
}



sub fetch {
    my $self    = shift;
    my $url     = shift;
    my $extra   = $self->_build_extra_params(@_);
    my $base    = $self->{base_url};
    my $req_url = $extra ? "$base/$url?$extra" : "$base/$url";
    
    my $result  = $self->{ua}->get($req_url);
    return $self->_decode_result( $result, $req_url );
}


sub post {
    my $self  = shift;
    my $url   = shift;
    my $query = shift;
    my $base  = $self->{base_url};

    defined $url
        or croak 'First argument of URL must be provided';

    ref $query and ref $query eq 'HASH'
        or croak 'Second argument of query hashref must be provided';

    my $query_json = encode_json( $query );
    my $result     = $self->{ua}->request(
        'POST',
        "$base/$url",
        {
            headers => { 'Content-Type' => 'application/json' },
            content => $query_json,
        }
    );

    return $self->_decode_result( $result, $url, $query_json );
}

sub _decode_result {
    my $self = shift;
    my ( $result, $url, $original ) = @_;
    my $decoded_result;

    ref $result and ref $result eq 'HASH'
        or croak 'First argument must be hashref';

    defined $url
        or croak 'Second argument of a URL must be provided';

    if ( defined ( my $success = $result->{'success'} ) ) {
        my $reason = $result->{'reason'} || '';
        $reason .= ( defined $original ? " (request: $original)" : '' );

        $success or croak "Failed to fetch '$url': $reason";
    } else {
        croak 'Missing success in return value';
    }

    defined ( my $content = $result->{'content'} )
        or croak 'Missing content in return value';

    eval { $decoded_result = decode_json $content; 1 }
    or do { croak "Couldn't decode '$content': $@" };

    return $decoded_result;
}

1;

__END__

=pod

=head1 NAME

MetaCPAN::API::Tiny - (DEPRECATED) A Tiny API client for MetaCPAN

=head1 VERSION

version 1.150270

=head1 DESCRIPTION

This module has been deprecated please use L<MetaCPAN::Client>.

This is the Tiny version of L<MetaCPAN::API>. It implements a compatible API
with a few notable exceptions:

=over 4

=item Attributes are direct hash access

The attributes defined using Mo(o|u)se are now accessed via the blessed hash
directly. There are no accessors defined to access this elements.

=item Exception handling

Instead of using Try::Tiny, raw evals are used. This could potentially cause
issues, so just be aware.

=item Testing

Test::Fatal was replaced with an eval implementation of exception().
Test::TinyMocker usage is retained, but may be absorbed since it is pure perl

=back

=head1 CLASS_METHODS

=head2 new

new is the constructor for MetaCPAN::API::Tiny. In the non-tiny version of this
module, this is provided via Any::Moose built from the attributes defined. In
the tiny version, we define our own constructor. It takes the same arguments
and provides similar checks to MetaCPAN::API with regards to arguments passed.

=head1 PUBLIC_METHODS

=head2 source

    my $source = $mcpan->source(
        author  => 'DOY',
        release => 'Moose-2.0201',
        path    => 'lib/Moose.pm',
    );

Searches MetaCPAN for a module or a specific release and returns the plain source.

=head2 release

    my $result = $mcpan->release( distribution => 'Moose' );

    # or
    my $result = $mcpan->release( author => 'DOY', release => 'Moose-2.0001' );

Searches MetaCPAN for a dist.

You can do complex searches using 'search' parameter:

    # example lifted from MetaCPAN docs
    my $result = $mcpan->release(
        search => {
            author => "OALDERS AND ",
            filter => "status:latest",
            fields => "name",
            size   => 1,
        },
    );

=head2 pod

    my $result = $mcpan->pod( module => 'Moose' );

    # or
    my $result = $mcpan->pod(
        author  => 'DOY',
        release => 'Moose-2.0201',
        path    => 'lib/Moose.pm',
    );

Searches MetaCPAN for a module or a specific release and returns the POD.

=head2 module

    my $result = $mcpan->module('MetaCPAN::API');

Searches MetaCPAN and returns a module's ".pm" file.

=head2 file

A synonym of L</module>

=head2 author

    my $result1 = $mcpan->author('XSAWYERX');
    my $result2 = $mcpan->author( pauseid => 'XSAWYERX' );

Searches MetaCPAN for a specific author.

You can do complex searches using 'search' parameter:

    # example lifted from MetaCPAN docs
    my $result = $mcpan->author(
        search => {
            q    => 'profile.name:twitter',
            size => 1,
        },
    );

=head2 fetch

    my $result = $mcpan->fetch('/release/distribution/Moose');

    # with parameters
    my $more = $mcpan->fetch(
        '/release/distribution/Moose',
        param => 'value',
    );

This is a helper method for API implementations. It fetches a path from MetaCPAN, decodes the JSON from the content variable and returns it.

You don't really need to use it, but you can in case you want to write your own extension implementation to MetaCPAN::API.

It accepts an additional hash as "GET" parameters.

=head2 post

    # /release&content={"query":{"match_all":{}},"filter":{"prefix":{"archive":"Cache-Cache-1.06"}}}
    my $result = $mcpan->post(
        'release',
        {   
            query  => { match_all => {} },
            filter => { prefix => { archive => 'Cache-Cache-1.06' } },
        },
    );

The POST equivalent of the "fetch()" method. It gets the path and JSON request.

=head1 THANKS

Overall the tests and code were ripped directly from MetaCPAN::API and
tiny-fied. A big thanks to Sawyer X for writing the original module.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
