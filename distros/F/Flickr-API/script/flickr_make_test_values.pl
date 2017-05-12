#!/usr/bin/env perl

#-------------------------------
# flickr_make_test_values.pl
#_______________________________

use warnings;
use strict;
use Term::ReadLine;
use Pod::Usage;
use Getopt::Long;

my $values   = {};
my $cli_args = {};

my %defaults = (
    'search_email' => '',
    'search_username'  => '',
    );

my %prompts = (
    'search_email' => 'An email to search for',
    'search_username'  => 'A user id to search for',
    );

my $invalues = \%defaults;


GetOptions (
			$cli_args,
			'values_in=s',
			'values_out=s',
			'help',
			'man',
			'usage'
		   );


#-------------------------------------------------------------
# Respond to help-type arguments or if missing required params
#_____________________________________________________________

if ($cli_args->{'help'} or $cli_args->{'usage'}  or $cli_args->{'man'} or !$cli_args->{'values_out'}) {

        pod2usage({ -verbose => 2 });

}


#------------------------------------------------------------------
# If an incoming values is specified and exists, read it if we can.
# if any of the keys are defined (that is, a value we will use)
# overwrite the default.
#__________________________________________________________________

if (defined($cli_args->{'values_in'}) and -e $cli_args->{'values_in'}) {

    my $key;
    my $value;

	open my $VALUES_IN, '<', $cli_args->{'values_in'} or die "\nCannot open $cli_args->{'values_in'} for read: $!\n";
    while (<$VALUES_IN>) {

        s/\s+//g;
        ($key,$value) = split(/=/);

        if (defined($invalues->{$key})) { $invalues->{$key}=$value; }
    }

	close($VALUES_IN) or die "\nClose error $!\n";

}


#---------------------------------
# Create a term incase we need it.
#_________________________________

my $term = Term::ReadLine->new('Flickr Value Collector');
$term->ornaments(0);

my $which_rl = $term->ReadLine;

if ($which_rl eq "Term::ReadLine::Perl" or $which_rl eq "Term::ReadLine::Perl5") {

        warn "\n\nTerm::ReadLine::Perl and Term::ReadLine::Perl5 may display prompts" .
             "\nincorrectly. If this is the case for you, try adding \"PERL_RL=Stub\"" .
             "\nto the environment variables passed in with make test\n\n";

}


#--------------------------------------------------------------------
# build or confirm values
#____________________________________________________________________

foreach my $key (sort keys %defaults) {

    my $value = $term->readline( $prompts{$key} ." [ ". $invalues->{$key}."]:   ");

    if (!$value) { $values->{$key} = $invalues->{$key}; }
    else { $values->{$key} = $value; }

}



#-------------------------------
# Display values and store same.
#_______________________________


open my $VALUES_OUT, '>', $cli_args->{'values_out'} or die "\nCannot open $cli_args->{'values_out'} for write: $!\n";

foreach my $key (sort keys %defaults) {

    print $key," = ",$values->{$key},"\n";
    print $VALUES_OUT $key," = ",$values->{$key},"\n";

}

close($VALUES_OUT) or die "\nClose error $!\n";


exit;



__END__

=pod

=head1 NAME

flickr_make_test_values.pl - script to assist with testing the Flickr::API

=head1 SYNOPSIS

C<flickr_make_test_values.pl --values_out=file_to_build [--values_in=existing_file]>

=head1 OPTIONS

=head2 Required:
B< >

=over 5

=item  B<--values_out> points to where to create the stored Flickr values file

=back

=head2 Optional:


B< >


=over 5

=item  B<--values_in>   points to the optional input values file to use as a base 
                        for the I<--values_out> file you are creating.

B< >

=item  B<--help> as expected

=item  B<--usage>

=item  B<--man>

=back




=head1 DESCRIPTION

This script is a lightweight method to assemble key/value pairs
for testing the Flickr::API. It is used to build a file
for the B<make test> portion of installation. It does not
I<use Flickr::API;> and sticks to modules from perl core so
that it can be used prior to-- and perhaps in conjunction with--
installation and testing of the Flickr::API module.


When you B<make test>, add the environment variable MAKETEST_VALUES,
pointing to the key/values file you specified. The command should 
look something like:

  make test MAKETEST_VALUES=/home/myusername/test-flickr-values.txt

or

  make test MAKETEST_VALUES=/home/myusername/test-flickr-values.txt \
          MAKETEST_OAUTH_CFG=/home/myusername/test-flickr-oauth.st



=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015, Louis B. Moore C<< <lbmoore@cpan.org> >>.


This program is released under the Artistic License 2.0 by The Perl Foundation.


=head1 SEE ALSO

The README in the Flickr::API distribution.

