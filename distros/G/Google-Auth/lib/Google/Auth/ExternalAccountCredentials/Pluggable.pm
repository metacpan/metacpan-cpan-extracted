# Copyright 2026 Google LLC
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

package Google::Auth::ExternalAccountCredentials::Pluggable;

use strict;
use warnings;

use Moo;
extends 'Google::Auth::ExternalAccountCredentials';

use JSON::PP;
use Google::Auth::Exceptions;
use Capture::Tiny qw(capture);
use Log::Any qw($log);

our $VERSION = '0.02';

sub retrieve_subject_token {
    my ($self) = @_;

    my $source = $self->credential_source;
    my $exec   = $source->{executable};
    if ( !defined $exec ) {
        $log->errorf('Missing executable configuration in Pluggable credential_source');
        Google::Auth::Error->throw('Missing executable configuration in credential_source');
    }

    my $command = $exec->{command};
    if ( !defined $command ) {
        $log->errorf('Missing command in Pluggable executable configuration');
        Google::Auth::Error->throw('Missing command in executable configuration');
    }

    my $env_vars = $exec->{environment_variables} // {};
    local %ENV = %ENV;
    while ( my ( $k, $v ) = each %$env_vars ) {
        $ENV{$k} = $v;
    }

    $log->infof('Executing Pluggable credential command: %s', $command);
    my ($stdout, $stderr, $exit) = capture {
        system($command);
    };

    if ($exit != 0) {
        my $exit_code = $exit >> 8;
        $log->errorf('Pluggable command failed with exit code %d: %s', $exit_code, $stderr);
        Google::Auth::Error->throw('Pluggable credential command failed with exit code ' . $exit_code . ': ' . $stderr);
    }

    my $format      = $source->{format} // {};
    my $format_type = $format->{type} // 'json';

    my $token;
    if ( $format_type eq 'json' ) {
        $log->tracef('Parsing JSON output from Pluggable command...');
        my $data = eval { decode_json($stdout) };
        if ($@) {
            $log->errorf('Pluggable JSON parsing failed: %s', $@);
            Google::Auth::Error->throw('Failed to parse JSON from pluggable command output: ' . $@);
        }
        my $field = $format->{subject_token_field_name} // 'id_token';
        $token = $data->{$field};
    }
    elsif ( $format_type eq 'text' ) {
        $log->tracef('Using raw text output from Pluggable command...');
        $token = $stdout;
        $token =~ s/\r?\n$//;
    }
    else {
        $log->errorf('Invalid Pluggable credential_source format: %s', $format_type);
        Google::Auth::Error->throw('Invalid credential_source format: ' . $format_type);
    }

    if ( !defined $token ) {
        $log->errorf('Pluggable command returned empty subject token.');
        Google::Auth::Error->throw('Pluggable credential command did not return a valid subject token');
    }

    $log->tracef('Pluggable subject token retrieved successfully.');
    return $token;
}

1;
