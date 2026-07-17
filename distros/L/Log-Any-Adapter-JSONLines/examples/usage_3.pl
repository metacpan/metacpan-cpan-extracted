#!/usr/bin/env perl
use strict;
use warnings;
use 5.008_006;
our $VERSION = 0.001;

use Log::Any qw( $log );
use Log::Any::Adapter( 'JSONLines',
    hooks => {
        before => [
            \&mask_card_number,
        ]
    },
    # log_level => 'warning',
    canonical => 1,
);
sub mask_card_number {
    my ($level, $category, $log_entry) = @_;
    my $last_nums = ($log_entry->{card} =~ m/^\d{12}(\d{4})$/msx)[0];
    $log_entry->{card} = q{XXXX XXXX XXXX } . $last_nums;
    return;
}

# ###################################################################
# main
sub main {
    $log->trace('Logging TRACE', { card=>'0123456789012345' });
    $log->debug('Logging DEBUG', { card=>'0123456789012345' });
    $log->info('Logging INFO', { card=>'0123456789012345' });
    $log->warning('Logging WARNING', { card=>'0123456789012345' });
    $log->error('Logging ERROR', { card=>'0123456789012345' });
    $log->fatal('Logging FATAL', { card=>'0123456789012345' });
    return 0;
}

exit main(@ARGV);
