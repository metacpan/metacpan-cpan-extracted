package Flickr::Tools;

use Flickr::API;
use Flickr::Roles::Permissions;
use Flickr::Types::Tools qw( FlickrAPI  FlickrToken FlickrAPIargs HexNum);
use Types::Standard qw( Maybe Str HashRef Int InstanceOf Bool);

use Storable qw( retrieve_fd );
use Data::Dumper;

use 5.010;
use Carp;
use Moo;
use strictures;
use namespace::clean;

our $VERSION = '1.22';

with('Flickr::Roles::Permissions');

has _api => (
    is        => 'ro',
    isa       => InstanceOf ['Flickr::API'],
    clearer   => 1,
    predicate => 'has_api',
    lazy      => 1,
    builder   => '_build_api',
    required  => 1,
);

has '_api_name' => (
    is       => 'ro',
    isa      => sub { $_[0] =~ m/^Flickr::API$/ },
    required => 1,
    default  => 'Flickr::API',
);

has access_token => (
    is       => 'ro',
    clearer  => 1,
    isa      => Maybe [ InstanceOf ['Net::OAuth::AccessTokenResponse'] ],
    required => 0,
);

has auth_uri => (
    is       => 'ro',
    isa      => Maybe [Str],
    clearer  => 1,
    required => 0,
    default  => 'https://api.flickr.com/services/oauth/authorize',
);

has callback => (
    is       => 'ro',
    isa      => Maybe [Str],
    clearer  => 1,
    required => 0,
);

has config_file => (
    is       => 'ro',
    isa      => Maybe [Str],
    clearer  => 1,
    required => 0,
);

has consumer_key => (
    is       => 'ro',
    isa      => HexNum,
    required => 1,
);

has consumer_secret => (
    is       => 'ro',
    isa      => HexNum,
    required => 1,
);

has local => (
    is       => 'rw',
    isa      => Maybe [HashRef],
    clearer  => 1,
    required => 0,
);

has request_method => (
    is       => 'ro',
    clearer  => 1,
    isa      => Maybe [Str],
    required => 0,
    default  => 'GET',
);

has request_token => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf ['Net::OAuth::V1_0A::RequestTokenResponse'] ],
    clearer => 1,
    required => 0,
);

has request_url => (
    is       => 'ro',
    isa      => Maybe [Str],
    clearer  => 1,
    required => 0,
    default  => 'https://api.flickr.com/services/rest/',
);

has rest_uri => (
    is       => 'ro',
    isa      => Maybe [Str],
    clearer  => 1,
    required => 0,
    default  => 'https://api.flickr.com/services/rest/',
);

has signature_method => (
    is       => 'ro',
    isa      => Maybe [Str],
    clearer  => 1,
    required => 0,
    default  => 'HMAC-SHA1',
);

has token => (
    is        => 'ro',
    isa       => Maybe [FlickrToken],
    predicate => 1,
    clearer   => 1,
    required  => 0,
);

has token_secret => (
    is        => 'ro',
    isa       => Maybe [HexNum],
    predicate => 1,
    clearer   => 1,
    required  => 0,
);

has unicode => (
    is       => 'ro',
    isa      => sub { $_[0] != 0 ? 1 : 0; },
    clearer  => 1,
    required => 0,
    default  => 0,
);

has _user => (
    is        => 'rw',
    isa       => Maybe [HashRef],
    predicate => 1,
    clearer   => 1,
    required  => 0,
);

has version => (
    is       => 'ro',
    isa      => Maybe [Str],
    clearer  => 1,
    required => 0,
    default  => '1.0',
);

sub _dump {
    my $self = shift;
    say 'Examine the tool';
    print Dumper($self);
    return;
}

sub BUILDARGS {

    my $class = shift;
    my $args  = shift;

    my $import;

# args should be either a hashref, or a string containing the path to a config file

    unless ( ref $args ) {

        my $config_filename = $args;
        undef $args;
        $args->{config_file} = $config_filename;

    }

    confess
"\n\nFlickr::Tools->new() expects a hashref,\n  or at least the name of a config file\n\n"
      unless ref($args) eq 'HASH';

    if ( $args->{config_file} ) {

        if ( -r $args->{config_file} ) {

            my $info = Storable::file_magic( $args->{config_file} );
            if ( $info->{version} ) {

                open my $IMPORT, '<', $args->{config_file}
                  or carp "\nCannot open $args->{config_file} for read: $!\n";
                $import = retrieve_fd($IMPORT);
                close $IMPORT;

            }
            else {

                carp $args->{config_file},
                  " is not in storable format, removing from arguments\n";
                delete $args->{config_file};
            }
        }
        else {

            carp $args->{config_file},
              " is not a readable file, removing from arguments\n";
            delete $args->{config_file};
        }

    }

    my $fullargs = _merge_configs( $args, $import );

    unless (exists( $fullargs->{consumer_key} )
        and exists( $fullargs->{consumer_secret} ) )
    {

        carp
"\nMust provide, at least, a consumer_key and consumer_secret. They can be\npassed directly or in a config_file\n";

    }

    return $fullargs;
}

sub api {
    my $self = shift;
    return $self->_api if $self->has_api;
    $self->_build_api;
    return $self->_api;
}

sub clear_api {
    my $self = shift;
    $self->_clear_api;
    $self->_clear_api_connects;
    return;
}

sub user {
    my $self = shift;
    return $self->_user if $self->_has_user;
    carp 'No user found';
    return;
}

sub prepare_method { }

sub validate_method { }

sub call_method { }

sub make_arglist { }

sub auth_method { }

sub set_method {
    my $self = shift;
    my $args = shift;

    if ( $args->{method} =~ m/flickr\.people\./x ) {

    }
    else {

    }

    return;
}

# then specific tools::person or such operate on the family of methods
# and they can override some of the above.

sub _build_api {

    my $self = shift;
    my $args = shift;
    my $call = {};

    # required args
    $call->{consumer_key}    = $self->consumer_key;
    $call->{consumer_secret} = $self->consumer_secret;
    $call->{api_type}        = 'oauth';

    $call->{unicode}          = $self->unicode;
    $call->{request_method}   = $self->request_method;
    $call->{request_url}      = $self->request_url;
    $call->{rest_uri}         = $self->rest_uri;
    $call->{auth_uri}         = $self->auth_uri;
    $call->{signature_method} = $self->signature_method;
    $call->{version}          = $self->version;
    $call->{callback}         = $self->callback;

    if ( $self->has_token && $self->has_token_secret ) {

        $call->{token}        = $self->token;
        $call->{token_secret} = $self->token_secret;

    }

    $self->{_api} = $self->{_api_name}->new($call);
    return;
}

#
# make a template configuration and overwrite template values
# with ones passed into new(). Any extra keys get weeded out
# and added to args->{local}->{unused_keys}
#
sub _merge_configs {
    my @hashes    = (@_);
    my $template  = _make_config_template();
    my $extrakeys = {};
    my $key;
    my $value;

    foreach my $hashref (@hashes) {

        while ( ( $key, $value ) = each %{$hashref} ) {

            if ( exists( $template->{$key} ) ) {

                $template->{$key} = $value;

            }
            else {

                $extrakeys->{$key} = $value;
            }
        }
    }

    $template->{local}->{unused_args} = $extrakeys;

    return $template;
}

#
# make a shell of a configuration to deal with any random stuff
# that might be sent into new().
#
sub _make_config_template {

    my %empty = (
        access_token     => undef,
        auth_uri         => 'https://api.flickr.com/services/oauth/authorize',
        callback         => undef,
        config_file      => undef,
        consumer_key     => undef,
        consumer_secret  => undef,
        local            => undef,
        nonce            => undef,
        request_method   => 'GET',
        request_token    => undef,
        request_url      => 'https://api.flickr.com/services/rest/',
        rest_uri         => 'https://api.flickr.com/services/rest/',
        signature_method => 'HMAC-SHA1',
        timestamp        => undef,
        token            => undef,
        token_secret     => undef,
        unicode          => 0,
        user             => undef,
        version          => '1.0',
    );

    return \%empty;

}

1;

__END__

=pod

=head1 NAME

Flickr::Tools - Tools to assist using the Flickr API

=head1 VERSION

CPAN:        1.22
Development: 1.22_01

=head1 SYNOPSIS

This is the base class for the various Flickr::Tools, you will probably want
one of the subclasses, such as Flickr::Tools::Person.

  my $tool = Flickr::Tool->new({config_file => 'my/storable/config/file.st'});

  my $tool = Flickr::Tool->new({
                                consumer_key    => '1234567890abcdefedcba0987654321',
                                consumer_secret => '123beefcafe321',
                                token           => '12345678909876-acdbeef55321',
                                token_secret    => '1234cafe4123b',
                               });


=head1 DESCRIPTION


=head1 METHODS

=over

=item C<new>

Returns a new Tool

=item C<api>

Returns the Flickr::API object this tool is using.

=item C<clear_api>

removes the Flickr::API object this tool was using.

=item C<user>

Returns the Flickr user hashref for the Flickr::API 
object this tool is using.

=back

=head1 PUBLIC ATTRIBUTES

=over

=item C<access_token> a read only attribute.

Returns your oauth access token if it is there. You
will more commonly use C<token> below.

=item C<auth_uri> a read only attribute.

Returns the Flickr oauth api uri. The default is most
likely what youy want.


=item C<callback> a read only attribute.

Returns your callback url if there is one.


=item C<config_file> a read only attribute.

Returns the path of your storable format configuration file, if there is one.

=item C<consumer_key> a read only attribute.

Returns your consumer key, this is required to create a tool object.

=item C<consumer_secret> a read only attribute.

Returns your consumer secret, this is required to create a tool object.

=item C<local> a read/write attribute.

local is a hashref that the tool keeps, but doesn't use. It is there to
store you own items in a tool.

 $tool->local($hashref);

or

 my $local = $tool->local;

=item C<request_method> a read only attribute.

=item C<request_token> a read only attribute.

=item C<request_url> a read only attribute.

=item C<rest_uri> a read only attribute.

=item C<signature_method> a read only attribute.

=item C<token> a read only attribute.

=item C<token_secret> a read only attribute.

=item C<unicode> a read only attribute.

=item C<version> a read only attribute.


=back

=head1 PRIVATE ATTRIBUTES

=over

=item C<_api>

=item C<_api_name>

=item C<_user>

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

Perl 5.10 and Moo.

=head1 INCOMPATIBILITIES

None known of, yet.

=head1 BUGS AND LIMITATIONS

Yes

=head1 AUTHOR

Louis B. Moore <lbmoore@cpan.org>

=head1 LICENSE AND COPYRIGHT


Copyright (C) 2014-2015 Louis B. Moore <lbmoore@cpan.org>


This program is released under the Artistic License 2.0 by The Perl Foundation.
L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Flickr|http://www.flickr.com/>,
L<http://www.flickr.com/services/api/>
L<https://www.flickr.com/services/api/auth.oauth.html>
L<https://github.com/iamcal/perl-Flickr-API>

=cut
