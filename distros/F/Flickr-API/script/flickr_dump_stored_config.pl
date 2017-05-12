#!/usr/bin/env perl

#-----------------------------
# flickr_dump_stored_config.pl
#_____________________________

use warnings;
use strict;
use Data::Dumper;
use Storable  qw(store_fd retrieve_fd);
use Getopt::Long;
use Pod::Usage;

my $config;
my $cli_args = {};

GetOptions (
			$cli_args,
			'config_in=s',
			'help',
			'man',
			'usage'
		   );


if (defined($ARGV[0])) { $cli_args->{'config_in'} = $ARGV[0]; }


#-------------------------------------------------------------
# Respond to help-type arguments or if missing required params
#_____________________________________________________________

if ($cli_args->{'help'} or $cli_args->{'usage'}  or $cli_args->{'man'} or !$cli_args->{'config_in'}) {

        pod2usage({ -verbose => 2 });

}



open my $CFG, "<", $cli_args->{'config_in'}
  or die "Failed to open  $cli_args->{'config_in'}: $!";

$config = retrieve_fd($CFG);

close $CFG;

$Data::Dumper::Sortkeys=1;

print "\n\n\n\nRetrieved\n\n",Dumper($config),"\nfrom ",$cli_args->{'config_in'}," using Storable\n\n";

exit;

__END__

=pod

=head1 NAME

flickr_dump_stored_config.pl - script to display contents of a Flickr::API
storable configuration file.

=head1 SYNOPSIS

C<flickr_dump_stored_config.pl [/path/to/file or --config_in=Config-File_to_dump]>

=head1 OPTIONS

=head2 Required:
B< >

=over 5

=item Either a B</path/to/config/file> or

=item B<--config_in> pointing to the stored Flickr config file.

B< >

=back

=over 5

=item  B<--help> as expected

=item  B<--usage>

=item  B<--man>

=back

=head1 DESCRIPTION

This script is a lightweight way to dump the contents of a
Flickr::API storable configuration. It does not I<use Flickr::API;> 
and sticks to modules from perl core so that it can be used 
prior to-- and perhaps in conjunction with-- installation 
and testing of the Flickr::API module.



=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015-2016, Louis B. Moore C<< <lbmoore@cpan.org> >>.

This program is released under the Artistic License 2.0 by The Perl Foundation.


=head1 SEE ALSO

The README in the Flickr::API distribution.

