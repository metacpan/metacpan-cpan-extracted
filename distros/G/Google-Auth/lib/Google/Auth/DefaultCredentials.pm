# Copyright 2022 Google, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Auth::DefaultCredentials;

use strict;
use warnings;

use Moo;
use JSON::PP;
use File::Spec;
use Google::Auth::EnvironmentVars;
use Google::Auth::Exceptions;

our $VERSION = '0.02';

has environment => (
    is      => 'ro',
    default => sub { Google::Auth::EnvironmentVars->new() },
);

sub make_creds {
    my ( $self, %options ) = @_;
    # Allow calling as class or instance method
    $self = ref $self ? $self : $self->new();

    my $json_key     = $options{json_key};
    my $json_content = $options{json_content};
    my $json_path    = $options{json_path};
    my $scopes       = $options{scope};

    my $info;

    eval {
        if ($json_key) {
            $info = $json_key;
        }
        elsif ($json_content) {
            $info = decode_json($json_content);
        }
        elsif ($json_path) {
            if ( -f $json_path ) {
                my $content = $self->_read_file($json_path);
                $info = decode_json($content);
            }
            else {
                Google::Auth::DefaultCredentialsError->throw(
                    'Credential file ' . $json_path . ' does not exist'
                );
            }
        }
    };
    if ($@) {
        Google::Auth::DefaultCredentialsError->throw(
            'Failed to parse credential JSON: ' . $@
        );
    }


    if ($info) {
        my $type = $info->{type};
        if ( !$type ) {
            Google::Auth::DefaultCredentialsError->throw(
                'The json is missing the type field'
            );
        }

        my $creds_class = $self->_determine_class_for_type($type);
        if ( $creds_class->can('make_creds') ) {
            return $creds_class->make_creds(
                json_key => $info,
                scope    => $scopes,
                %options
            );
        }
        return $creds_class->new(
            json_key => $info,
            scope    => $scopes,
            %options
        );
    }

    # If no explicit json info was provided, fallback to checking environment variables
    my $env = $self->environment;
    if ( $ENV{GOOGLE_PRIVATE_KEY} && $ENV{GOOGLE_CLIENT_EMAIL} ) {
        require Google::Auth::ServiceAccountCredentials;
        return Google::Auth::ServiceAccountCredentials->new(
            private_key  => $ENV{GOOGLE_PRIVATE_KEY},
            client_email => $ENV{GOOGLE_CLIENT_EMAIL},
            scope        => $scopes,
            %options
        );
    }

    return;
}

sub from_env {
    my ( $self, $scopes, %options ) = @_;
    $self = ref $self ? $self : $self->new();

    my $credentials_path = $ENV{GOOGLE_APPLICATION_CREDENTIALS} || $self->environment->CREDENTIALS;

    if ( $credentials_path && -f $credentials_path ) {
        return $self->make_creds(
            json_path => $credentials_path,
            scope     => $scopes,
            %options
        );
    }
    return;
}

sub from_well_known_path {
    my ( $self, $scopes, %options ) = @_;
    $self = ref $self ? $self : $self->new();

    my $env  = $self->environment;
    my $home = $ENV{HOME};
    if ( $^O eq 'MSWin32' ) {
        $home = $ENV{APPDATA};
    }

    return unless $home;

    my $well_known_file;
    if ( $^O eq 'MSWin32' ) {
        $well_known_file = File::Spec->catfile(
            $home, 'gcloud', 'application_default_credentials.json'
        );
    }
    else {
        my $config_dir = $env->CLOUD_SDK_CONFIG_DIR
          || File::Spec->catdir( $home, '.config' );
        $well_known_file = File::Spec->catfile(
            $config_dir, 'gcloud', 'application_default_credentials.json'
        );
    }

    if ( -f $well_known_file ) {
        return $self->make_creds(
            json_path => $well_known_file,
            scope     => $scopes,
            %options
        );
    }
    return;
}

sub from_system_default_path {
    my ( $self, $scopes, %options ) = @_;
    $self = ref $self ? $self : $self->new();

    my $system_default_file;
    if ( $^O eq 'MSWin32' ) {
        return unless $ENV{ProgramData};
        $system_default_file = File::Spec->catfile(
            $ENV{ProgramData}, 'Google', 'Auth',
            'application_default_credentials.json'
        );
    }
    else {
        $system_default_file =
          '/etc/google/auth/application_default_credentials.json';
    }

    if ( -f $system_default_file ) {
        return $self->make_creds(
            json_path => $system_default_file,
            scope     => $scopes,
            %options
        );
    }
    return;
}

sub _determine_class_for_type {
    my ( $self, $type ) = @_;

    if ( $type eq 'service_account' ) {
        require Google::Auth::ServiceAccountCredentials;
        return 'Google::Auth::ServiceAccountCredentials';
    }
    elsif ( $type eq 'authorized_user' ) {
        require Google::Auth::UserRefreshCredentials;
        return 'Google::Auth::UserRefreshCredentials';
    }
    elsif ( $type eq 'compute_engine' ) {
        require Google::Auth::ComputeEngine;
        return 'Google::Auth::ComputeEngine';
    }
    elsif ( $type eq 'impersonated_service_account' ) {
        require Google::Auth::ImpersonatedServiceAccountCredentials;
        return 'Google::Auth::ImpersonatedServiceAccountCredentials';
    }
    elsif ( $type eq 'external_account' ) {
        require Google::Auth::ExternalAccountCredentials;
        return 'Google::Auth::ExternalAccountCredentials';
    }

    Google::Auth::DefaultCredentialsError->throw(
        'Unsupported credential type: ' . $type
    );
}

sub _read_file {
    my ( $self, $path ) = @_;
    open( my $fh, '<', $path )
      or Google::Auth::DefaultCredentialsError->throw(
        'Could not open file ' . $path . ': ' . $!
      );
    local $/;
    my $content = <$fh>;
    close($fh);
    return $content;
}

1;

