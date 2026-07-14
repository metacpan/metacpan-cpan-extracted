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

package Google::Auth::RetryHelper;

use strict;
use warnings;

use Google::Auth::Exceptions;
use Time::HiRes;
use Log::Any qw($log);

our $VERSION = '0.02';

sub execute_with_retry {
    my ( $class, $code, %options ) = @_;

    my $max_retries    = $options{max_retries}    // 3;
    my $initial_delay  = $options{initial_delay}  // 1.0;
    my $backoff_factor = $options{backoff_factor} // 2.0;

    my $attempt = 0;
    my $delay   = $initial_delay;

    while (1) {
        $attempt++;
        my $res = eval { $code->() };
        if (!$@) {
            return $res;
        }

        my $err = $@;
        if ( $attempt >= $max_retries ) {
            $log->errorf('Max retry attempts (%d/%d) reached. Throwing error: %s', $attempt, $max_retries, $err);
            die $err;
        }

        if ( $err =~ /Credential file.*does not exist/i 
          || $err =~ /Missing required/i 
          || $err =~ /Ambiguous/i 
          || $err =~ /Invalid credential_source/i ) {
            $log->errorf('Fatal un-retryable error encountered: %s. Propagating...', $err);
            die $err;
        }

        $log->warnf('Transient error on attempt %d/%d: %s. Retrying in %s seconds...', $attempt, $max_retries, $err, $delay);
        Time::HiRes::sleep($delay);
        $delay *= $backoff_factor;
    }
}

1;
