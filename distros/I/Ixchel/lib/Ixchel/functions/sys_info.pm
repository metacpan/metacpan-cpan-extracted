package Ixchel::functions::sys_info;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(sys_info);
use Rex -feature => [qw/1.4/];
use Rex::Hardware;
use Ixchel::functions::product;
use Ixchel::functions::serial;


# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::functions::sys_info - Fetches system info via Rex::Hardware.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::sys_info;
    use Data::Dumper;

    my $returned=sys_info;

    print Dumper($returned);

$returned->{Host}{product} is filled in via Ixchel::functions::product and
$returned->{Host}{serial} is filled in via Ixchel::functions::serial for the purpose
making sure those are handled properly in a cross platform manner given a bug in Rex.

=head1 Functions

=head2 sys_info

Calls L<Rex::Hardware>->get and returns the data as a hash ref.

=cut

sub sys_info {
	my %all=Rex::Hardware->get(qw/ All /);

	$all{Host}{product}=product;
	$all{Host}{serial}=serial_num;

	return \%all;
}

1;
