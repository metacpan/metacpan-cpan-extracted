#!/usr/bin/perl -w
#

=head1 NAME

mail_tempaddress_purge.pl - purge Mail::TempAddress::Address object when
they expire

=head1 SYNOPSIS

  mail_tempaddress_purge.pl directory [min_age] [-v]

=cut

use strict;

# apply roles
use Mail::TempAddress::Addresses;
use Mail::Action::Role::Purge;
use Class::Roles
    apply => {
        role => 'Purge',
        to   => 'Mail::TempAddress::Addresses'
    };

# parse command line
use Getopt::Long;
my $verbose;
GetOptions( "verbose" => \$verbose );
my $dir = shift;
my $min_age = shift;
die( "usage: $0 address_dir [min_age]\n" ) unless $dir;

# create a tempaddr object
my $addys = Mail::TempAddress::Addresses->new( $dir );

# report how many addresses exist
print "$dir contains ", $addys->num_objects, " addresses\n";

# if verbose, list the addresses
list_addresses() if $verbose;

# run the purge routine
my $purged = 0;
$purged = $addys->purge($min_age);

# report how many addresses were purged;
my $justone = (1 == $purged);
print $purged . ($justone ? " address was"
                         : " addresses were") . " purged\n";

# if verbose, list the addresses
list_addresses() if $verbose;

# all done!
exit(0);

sub list_addresses
{

    my $i = 0;
    for( @{ $addys->object_names } ) {
        print $i++ . " $_\n";
    }

}


__END__


=head1 DESCRIPTION

B<mail_tempaddress_addresses.pl> applies the C<Purge> role from
Mail::Action::Role::Purge to a Mail::TempAddress::Addresses collection. This
role allows the purging of expired Mail::TempAddress::Address objects. This
program is intended to be run on a regular basis from cron or a similar
facility.

When run the number of addresses present in the address directory before the
purge and the number of addresses purged will be listed to the terminal.

=head1 ARGUMENTS

The only required argument is the directory in which the addresses are
stored. This is the same as the argument to the Mail::TempAddress
constructor. For safety it is recommended that this be a absolute directory
path.

=head1 OPTIONS

A minimum time that each address has been expired for may be passed as an
optional argument. The time may be in seconds or a freeform expression such
as "1h30m" or "2m1w".

If C<-v> or C<--verbose> is passed then the addresses present will be listed
to the terminal both before and after the purge.

=head1 AUTHOR

James FitzGibbon, E<lt>jfitz@CPAN.ORGE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, James FitzGibbon.  This program is free software; you
may use/modify it under the same terms as Perl itself.

=cut

#
# EOF
