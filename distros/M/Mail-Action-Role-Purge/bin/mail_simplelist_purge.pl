#!/usr/bin/perl -w
#

=head1 NAME

mail_tempaddress_purge.pl - purge Mail::SimpleList::Alias object when
they expire

=head1 SYNOPSIS

  mail_tempaddress_purge.pl directory [min_age] [-v]

=cut

use strict;

# apply roles
use Mail::SimpleList::Aliases;
use Mail::Action::Role::Purge;
use Class::Roles
    apply => {
        role => 'Purge',
        to   => 'Mail::SimpleList::Aliases'
    };

# parse command line
use Getopt::Long;
my $verbose;
GetOptions( "verbose" => \$verbose );
my $dir = shift;
my $min_age = shift;
die( "usage: $0 address_dir [min_age]\n" ) unless $dir;

# create a tempaddr object
my $aliases = Mail::SimpleList::Aliases->new( $dir );

# report how many aliases exist
print "$dir contains ", $aliases->num_objects, " aliases\n";

# if verbose, list the aliases
list_aliases() if $verbose;

# run the purge routine
my $purged = 0;
$purged = $aliases->purge($min_age);

# report how many aliases were purged;
my $justone = (1 == $purged);
print $purged . ($justone ? " address was"
                         : " aliases were") . " purged\n";

# if verbose, list the aliases
list_aliases() if $verbose;

# all done!
exit(0);

sub list_aliases
{

    my $i = 0;
    for( @{ $aliases->object_names } ) {
        print $i++ . " $_\n";
    }

}


__END__


=head1 DESCRIPTION

B<mail_simplelist_purge.pl> applies the C<Purge> role from
Mail::Action::Role::Purge to a Mail::SimpleList::Aliases collection. This
role allows the purging of expired Mail::SimpleList::Alias objects. This
program is intended to be run on a regular basis from cron or a similar
facility.

When run the number of aliases present in the address directory before the
purge and the number of aliases purged will be listed to the terminal.

=head1 ARGUMENTS

The only required argument is the directory in which the aliases are stored.
This is the same as the argument to the Mail::TempAddress constructor. For
safety it is recommended that this be a absolute directory path.

=head1 OPTIONS

A minimum time that each address has been expired for may be passed as an
optional argument. The time may be in seconds or a freeform expression such
as "1h30m" or "2m1w".

If C<-v> or C<--verbose> is passed then the aliases present will be listed
to the terminal both before and after the purge.

=head1 AUTHOR

James FitzGibbon, E<lt>jfitz@CPAN.ORGE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, James FitzGibbon.  This program is free software; you
may use/modify it under the same terms as Perl itself.

=cut

#
# EOF
