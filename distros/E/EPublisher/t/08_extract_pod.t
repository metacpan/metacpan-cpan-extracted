#!/usr/bin/perl

use strict;
use warnings;
use EPublisher::Utils::PPI qw(extract_pod);
use Test::More tests => 1;

=head1 NAME

08_extract_pod.t - Unit test file for PPI utility module

=cut

my $file = __FILE__;

my $pod = extract_pod( $file );

my $check = qq~=pod

=head1 NAME

08_extract_pod.t - Unit test file for PPI utility module

=head2 AUTHOR

Au. Thor

=cut
~;

is $pod, $check, 'check if extract_pod works ok';

=head2 AUTHOR

Au. Thor

=cut
