#!/usr/bin/env perl

#-------------------------------
# flickr_make_stored_config.pl
#_______________________________

use warnings;
use strict;
use Data::Dumper;
use Term::ReadLine;
use Storable qw( retrieve_fd store_fd );
use Pod::Usage;
use Getopt::Long;

my $config   = {};
my $inconfig = {};
my $cli_args = {};
my $heads_up = 0;

GetOptions (
			$cli_args,
			'config_in=s',
			'config_out=s',
			'api_type=s',
			'frob=s',
			'api_key=s',
			'api_secret=s',
			'key=s',
			'secret=s',
			'token=s',
			'consumer_key=s',
			'consumer_secret=s',
			'callback=s',
			'token=s',
			'token_secret=s',
			'help',
			'man',
			'usage'
		   );


#-------------------------------------------------------------
# Respond to help-type arguments or if missing required params
#_____________________________________________________________

if ($cli_args->{'help'} or $cli_args->{'usage'}  or $cli_args->{'man'} or !$cli_args->{'config_out'}) {

        pod2usage({ -verbose => 2 });

}


#------------------------------------------------------------------
# If an incoming config is specified and exists, read it if we can.
#__________________________________________________________________

if (defined($cli_args->{'config_in'}) and -e $cli_args->{'config_in'}) {

	open my $CONFIG_IN, '<', $cli_args->{'config_in'} or die "\nCannot open $cli_args->{'config_in'} for read: $!\n";
	$inconfig = retrieve_fd($CONFIG_IN);
	close($CONFIG_IN) or die "\nClose error $!\n";

}


#---------------------------------
# Create a term incase we need it.
#_________________________________

my $term = Term::ReadLine->new('Flickr Configurer');
$term->ornaments(0);

my $which_rl = $term->ReadLine;

if ($which_rl eq "Term::ReadLine::Perl" or $which_rl eq "Term::ReadLine::Perl5") {

        warn "\n\nTerm::ReadLine::Perl and Term::ReadLine::Perl5 may display prompts" .
             "\nincorrectly. If this is the case for you, try adding \"PERL_RL=Stub\"" .
             "\nto the environment variables passed in with make test\n\n";

}


#------------------
# Flickr or OAuth ?
#__________________

if (defined($cli_args->{'api_type'}) and  $cli_args->{'api_type'} =~ m/^f.*/i ) {

	$cli_args->{'api_type'} = 'flickr';

}
else {

	$cli_args->{'api_type'} = 'oauth';

}



#--------------------------------------------------------------------
# build config in layers. 1st undef, then config_in and finally args.
# Prompt if missing key/secret
# save key and secret as api_key and api_secret, moving api away from
# un-specified key type
#____________________________________________________________________

if ( $cli_args->{'api_type'} eq 'flickr' ) {

	$config->{'api_key'}    =  undef;
	$config->{'api_secret'} =  undef;
	$config->{'frob'}       =  undef;
	$config->{'callback'}   =  undef;
	$config->{'token'}      =  undef;

	if (defined($inconfig->{'key'}))        { $config->{'api_key'}    = $inconfig->{'key'}; $heads_up++; }
	if (defined($inconfig->{'secret'}))     { $config->{'api_secret'} = $inconfig->{'secret'}; $heads_up++;  }
	if (defined($inconfig->{'api_key'}))    { $config->{'api_key'}    = $inconfig->{'api_key'}; }
	if (defined($inconfig->{'api_secret'})) { $config->{'api_secret'} = $inconfig->{'api_secret'}; }
	if (defined($inconfig->{'frob'}))       { $config->{'frob'}       = $inconfig->{'frob'}; }
	if (defined($inconfig->{'callback'}))   { $config->{'callback'}   = $inconfig->{'callback'}; }
	if (defined($inconfig->{'token'}))      { $config->{'token'}      = $inconfig->{'token'}; }

	if (defined($cli_args->{'key'}))        { $config->{'api_key'}    = $cli_args->{'key'};  $heads_up++;}
	if (defined($cli_args->{'secret'}))     { $config->{'api_secret'} = $cli_args->{'secret'};  $heads_up++;}
	if (defined($cli_args->{'api_key'}))    { $config->{'api_key'}    = $cli_args->{'api_key'}; }
	if (defined($cli_args->{'api_secret'})) { $config->{'api_secret'} = $cli_args->{'api_secret'}; }
	if (defined($cli_args->{'frob'}))       { $config->{'frob'}       = $cli_args->{'frob'}; }
	if (defined($cli_args->{'callback'}))   { $config->{'callback'}   = $cli_args->{'callback'}; }
	if (defined($cli_args->{'token'}))      { $config->{'token'}      = $cli_args->{'token'}; }

    if ($heads_up > 0) { warn "\n\nNote: key and secret are changing to api_key and api_secret as part of the\nmove to OAuth to help make it more evident that the Flickr authentication is being used.\n\n"; }

	unless (defined($config->{'api_key'})) {

		$config->{'api_key'} = get_key($cli_args->{'api_type'});
	}

	unless (defined($config->{'api_secret'})) {

		$config->{'api_secret'} = get_secret($cli_args->{'api_type'});
	}
}


else {

	$config->{'consumer_key'}     = undef;
	$config->{'consumer_secret'}  = undef;
	$config->{'callback'}         = undef;
	$config->{'token_secret'}     = undef;
	$config->{'token'}            = undef;

	if (defined($inconfig->{'consumer_key'}))    { $config->{'consumer_key'}     = $inconfig->{'consumer_key'}; }
	if (defined($inconfig->{'consumer_secret'})) { $config->{'consumer_secret'}  = $inconfig->{'consumer_secret'}; }
	if (defined($inconfig->{'callback'}))        { $config->{'callback'}         = $inconfig->{'callback'}; }
	if (defined($inconfig->{'token_secret'})) {
		$config->{'token_secret'} = $inconfig->{'token_secret'};
	}
	if (defined($inconfig->{'token'}))     { $config->{'token'}      = $inconfig->{'token'}; }


	if (defined($cli_args->{'consumer_key'}))    { $config->{'consumer_key'}     = $cli_args->{'consumer_key'}; }
	if (defined($cli_args->{'consumer_secret'})) { $config->{'consumer_secret'}  = $cli_args->{'consumer_secret'}; }
	if (defined($cli_args->{'callback'}))        { $config->{'callback'}         = $cli_args->{'callback'}; }
	if (defined($cli_args->{'token_secret'})) {
		$config->{'token_secret'} = $cli_args->{'token_secret'};
	}
	if (defined($cli_args->{'token'}))     { $config->{'token'}      = $cli_args->{'token'}; }


	unless (defined($config->{'consumer_key'})) {

		$config->{'consumer_key'} = get_key($cli_args->{'api_type'});
	}

	unless (defined($config->{'consumer_secret'})) {

		$config->{'consumer_secret'} = get_secret($cli_args->{'api_type'});
	}

}


#-------------------------------
# Display config and store same.
#_______________________________

print "\n\nSaving\n\n",Dumper($config),"\nin ",$cli_args->{'config_out'}," using Storable\n\n";

open my $CONFIG_OUT, '>', $cli_args->{'config_out'} or die "\nCannot open $cli_args->{'config_out'} for write: $!\n";
store_fd $config, $CONFIG_OUT;
close($CONFIG_OUT) or die "\nClose error $!\n";


exit;


#--------------
#  Subroutiones
#______________

sub get_key {

	my $authtype = shift;

	my $loop = 0;
	my $getkey;

	while ($loop == 0) {

		my $keyprompt = 'OAuth consumer key for Flickr';

		if ($authtype eq 'flickr') {

			$keyprompt = 'Flickr api key';

		}

		print "\n";
		$getkey = $term->readline("Enter your " . $keyprompt .":   ");

		if ($getkey =~ m/^[0-9a-f]+$/i) {

			print "\n$keyprompt: ",$getkey," accepted\n";
			$loop++

		}
		else {

			print "\n$keyprompt ",$getkey,"is not a hex number\n";

		}
	}

	return $getkey;
}

sub get_secret {

	my $authtype = shift;

	my $loop = 0;
	my $getsecret;

	while ($loop == 0) {

		my $secretprompt = 'OAuth consumer secret for Flickr';

		if ($authtype eq 'flickr') {

			$secretprompt = 'Flickr api secret';

		}

		print "\n";
		$getsecret = $term->readline("Enter your " . $secretprompt .":   ");

		if ($getsecret =~ m/^[0-9a-f]+$/i) {

			print "\n$secretprompt: ",$getsecret," accepted\n";
			$loop++

		}
		else {

			print "\n$secretprompt ",$getsecret,"is not a hex number\n";

		}
	}

	return $getsecret;
}


__END__

=pod

=head1 NAME

flickr_make_stored_config.pl - script to assist with testing and using the Flickr::API

=head1 SYNOPSIS

C<flickr_make_stored_config.pl --config_out=Config-File_to_build [--config_in=file  --consumer_key=...]>

=head1 OPTIONS

=head2 Required:
B< >

=over 5

=item  B<--config_out> points to where to create the stored Flickr config file

=back

=head2 Optional:


B< >


=over 5

=item  B<--config_in>   points to the optional input config file to use as a base 
                        for the I<--config_out> file you are creating.

B< >

=item  B<--api_type>  either I<flickr> for the original, but deprecated, Flickr
                      authentication OR I<oauth> for the OAuth authentication.
                      it defaults to I<oauth>

B< >

I<For Flickr Auth>

=item  B<--api_key> The api key when used with Flickr authentication 
       I<required for testing> B<--key> still works to maintain compatibility
       with L<Flickr::API> 1.10 and before, but it is saved as api_key.

B< >

=item  B<--secret> The api secret when used with Flickr authentication
       I<required for testing> B<--secret> still works to maintain compatibility
       with L<Flickr::API> 1.10 and before, but it is saved as api_secret.

B< >

=item  B<--frob>  The frob used in Flickr authentication

B< >

=item  B<--token> The auth token can be either a Flickr or OAuth Access token 
       used with Flickr authentication

B< >

I<For OAuth>


=item  B<--consumer_key> The api key when used with OAuth authentication
       I<required for testing>

B< >


=item  B<--consumer_secret> The api secret when used with OAuth authentication
       I<required for testing>

B< >


=item  B<--callback> The callback uri for use in OAuth authentication

B< >

=item  B<--token_secret> The OAuth access token secret

B< >

B< >

=item  B<--help> as expected

=item  B<--usage>

=item  B<--man>

=back




=head1 DESCRIPTION

This script is a lightweight method to assemble the required
arguments for using the Flickr::API. It can be used to assemble
the configuration(s) needed for the B<make test> portion of
installation. It does not I<use Flickr::API;> and sticks to
modules from perl core so that it can be used prior to-- and
perhaps in conjunction with-- installation and testing of the
Flickr::API module.


When you B<make test>, add the environment variable MAKETEST_OAUTH_CFG,
MAKETEST_FLICKR_CFG or both; each pointing to the configuration file
you specified. The command should look something like:

  make test MAKETEST_OAUTH_CFG=/home/myusername/test-flickr-oauth.cfg

or

  make test MAKETEST_FLICKR_CFG=/home/myusername/test-flickrs-auth.cfg
 
or

  make test MAKETEST_FLICKR_CFG=/home/myusername/test-flickrs-auth.cfg \
          MAKETEST_OAUTH_CFG=/home/myusername/test-flickr-oauth.cfg



=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015-2016, Louis B. Moore C<< <lbmoore@cpan.org> >>.


This program is released under the Artistic License 2.0 by The Perl Foundation.


=head1 SEE ALSO

The README in the Flickr::API distribution.

