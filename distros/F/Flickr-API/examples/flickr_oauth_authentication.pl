#!/usr/bin/perl
#
# Example for using Flickr OAuth Authentication
#

use warnings;
use strict;
use Flickr::API;
use Data::Dumper;
use Getopt::Long;
use Term::ReadKey;
use Term::ReadLine;
use Pod::Usage;

=pod

=head1 DESCRIPTION

The original Flickr Authentication has been deprecated in favor
of OAuth. This example script shows one way to use L<Flickr::API>
to go from having just the consumer_key and consumer_secret
(or api_key and api_secret using Flickr's terminology) to an
authenticated token.

=head1 USAGE

 ./flickr_oauth_authentication.pl \
    --consumer_key="24680beef13579feed987654321ddcc6" \
    --consumer_secret="de0cafe4feed0242" \
  [ --perms={read,write,delete} \]
  [ --config_out="/path/to/a/writable/config.st" ]
  [ --help ]
  [ --man ]

If not specified, perms defaults to read.

The script will produce a url for you to enter into a browser
then prompt you to enter the callback url that is returned
by flickr.

It then does a Data::Dumper dump of the parameter keys and
values which can be recorded for future use. If you want to
make it more complete, you could modify the script to format
and dump the information into a config file of some type.

=head1 PROGRAM FLOW

Following the flow laid out in L<https://www.flickr.com/services/api/auth.oauth.html>

=cut


my $term = Term::ReadLine->new('Flickr OAuth authentication');
$term->ornaments(0);
my $which_rl = $term->ReadLine;

if ($which_rl eq "Term::ReadLine::Perl" or $which_rl eq "Term::ReadLine::Perl5") {

        warn "\n\nTerm::ReadLine::Perl and Term::ReadLine::Perl5 may display prompts" .
             "\nincorrectly. If this is the case for you, try adding \"PERL_RL=Stub\"" .
             "\nto the environment variables passed in with make test\n\n";

}

$Data::Dumper::Sortkeys = 1;

my $cli_args = {};

GetOptions (
    $cli_args,
    'consumer_key=s',
    'consumer_secret=s',
    'perms=s',
    'config_out=s',
    'help|?|usage',
    'man'
);

pod2usage(1)  if ($cli_args->{help});
pod2usage(-verbose => 2)  if ($cli_args->{man});

#
# get $cli_args prepared to pass into API
#

my $permstr = $cli_args->{'perms'};
delete $cli_args->{'perms'};

my $configfile =  $cli_args->{'config_out'};
delete $cli_args->{'config_out'};

=head2 Flickr Step 1, Application: get a request token

The script takes the consumer_key and consumer secret and
creates a Flickr::API object. It then calls the B<oauth_request_token>
method with an optional I<callback> specified.

  my $api = Flickr::API->new($cli_args);

  $api->oauth_request_token({'callback' => 'https://127.0.0.1'});

=cut

my $api = Flickr::API->new($cli_args);

$api->oauth_request_token({'callback' => 'https://127.0.0.1'});

=head2 Flickr Step 1, Flickr: return a request token.

The oauth request token is saved in the Flickr::API object.

=head2 Flickr Step 2. Application: Direct user to Flickr for Authorization

The script now calls the B<oauth_authorize_uri> method with
the optional I<perms> parameter. The Flickr::API returns a
uri which (in this case) is cut in the terminal and pasted
into a browser.

  my $request2 = $api->oauth_authorize_uri({'perms' => $cli_args->{'perms'}});

  print "\n\nYou now need to open: \n\n$request2\n\nin a browser.\n ";

=cut

my $permreq = 'read';
if ( $permstr && $permstr =~ /^(read|write|delete)$/) {
    $permreq = $permstr;
}

my $request2 = $api->oauth_authorize_uri({'perms' => $permreq});

print "\n\nYou now need to open: \n\n$request2\n\nin a browser.\n ";

=head2 Flickr Step 2. Flickr: Prompts user to provide Authorization

Assuming all is well with the I<request token> and I<oauth_authorize_uri>
Flickr will open a webpage to allow you to authenticate the application
identified by the B<consumer_key> to have the requested B<perms>.

=head2 Flickr Step 2. User: User authorizes application access

This is you, granting permission to the application.

=head2 Flick Step 2, Flickr: redirects the user back to the application

Flickr returns an B<oauth_verifier> in the callback. In this script you
cut the callback from the browser and paste it into the terminal to continue
on to the next step.

  $response2 = $term->readline('Enter the callback redirected url:   ');

The cutting and pasting is a little crude, but you only have to do it once.

=cut

my $response2 = $term->readline('Press [Enter] after setting up authorization on Flickr. ');

print "\n\n";

ReadMode(1);
$response2 = $term->readline('Enter the callback redirected url:   ');

#
# Redirects user back to Application, passing oauth_verifier
#  (entry done by hand, snort.)
#

chomp ($response2);

print "\n\n";

my ($url2,$parm2) = split(/\?/,$response2);
my (@parms) = split(/\&/,$parm2);

my %hash2;

foreach my $param2 (@parms) {

    my ($key,$val) = split(/=/,$param2);

    $key =~ s/oauth_//;

    $hash2{$key}=$val;

}


=head2 Flickr Step 3, Application: exchange request token for access token

The script takes the B<request token> and the B<oauth_verifier> and
exchanges them for an B<access token>.

  my $request3 = $api->oauth_access_token(\%hash2);

=cut

my $request3 = $api->oauth_access_token(\%hash2);

=head2 Flickr Step 3, Flickr: returns an access token and token secret

Flickr will return an B<access token> and B<token secret> if all has gone
well. These are stashed in the Flickr::API object.

=head2 Save the access information

How you save the access information is outside the scope of this
example. However, the B<export_config> method can be used
to retrieve the oauth parameters from the Flickr::API object.

  my %oconfig = $api->export_config('protected resource');

  print Dumper(\%oconfig);

=cut

my %oconfig = $api->export_config('protected resource');

print Dumper(\%oconfig);

if ($configfile) { $api->export_storable_config($configfile); }

exit;

__END__

=pod

=head1 AUTHOR

Louis B. Moore <lbmoore at cpan.org> 

=head1 COPYRIGHT AND LICENSE

Copyright 2014,2016, Louis B. Moore

This program is released under the Artistic License 2.0 by The Perl Foundation.

=cut

