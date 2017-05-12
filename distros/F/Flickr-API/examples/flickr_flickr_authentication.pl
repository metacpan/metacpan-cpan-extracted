#!/usr/bin/perl
#
# Example for using Flickr's Deprecated Authentication
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
of OAuth. The example flickr_oauth_authentication.pl should be
used in favor of this one. However, this script uses the deprecated--
but seemingly still alive-- Flickr authentication to go from having
just the api_key and api_secret to an authenticated token.

=head1 USAGE

 ./flickr_flickr_authentication.pl \
    --api_key="24680beef13579feed987654321ddcc6" \
    --api_secret="de0cafe4feed0242" \
  [ --perms={read,write,delete} \]
  [ --config_out="/path/to/a/writable/config.st" ]
  [ --help ]
  [ --man ]

If not specified, perms defaults to read.

--key and --api_key are synonymous and --secret and --api_secret 
are also synonymous.

The script will produce a url for you to enter into a browser
then prompt you to press [ENTER] once you have authenticated
on Flickr.

It then does a Data::Dumper dump of the parameter keys and
values which can be recorded for future use. If you want to
make it more complete, you could modify the script to format
and dump the information into a config file of some type.
Alternatively, you can use the --config_out to specify a
filename that the API can use to save itself into using the
storable format.


=head1 PROGRAM FLOW

Following the flow laid out in L<https://www.flickr.com/services/api/auth.howto.desktop.html> more or less.

=cut

=head2 Flickr Steps 1&2, Obtain and configure an api_key

Out of scope for this particular script. We are assuming you
have already obtained and configured youe api_key.


=cut


my $term = Term::ReadLine->new('Flickr deprecated authentication');
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
    'api_key=s',
    'api_secret=s',
    'key=s',
    'secret=s',
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

$cli_args->{'api_key'} =  $cli_args->{'api_key'} || $cli_args->{'key'};
delete $cli_args->{'key'};

$cli_args->{'api_secret'} = $cli_args->{'api_secret'} || $cli_args->{'secret'};
delete $cli_args->{'secret'};

=head2 Flickr Step 3, Application: get a frob

The script takes the api_key and api_secret and
creates a Flickr::API object. It then calls the B<flickr.auth.getFrob>
method.

  my $api = Flickr::API->new($cli_args);
  my $rsp = $api->execute_method("flickr.auth.getFrob");

=cut

my $api = Flickr::API->new($cli_args);

my $rsp = $api->execute_method("flickr.auth.getFrob");

unless ($rsp->success()) { die "\ngetFrob failed with ",$rsp->error_code,": ",$rsp->error_message,"\n"; }

my $answer = $rsp->as_hash();

my $frob = $answer->{frob};


=head2 Flickr Step 4. Application: Direct user to Flickr for Authorization

The script now calls the B<request_auth_uri> method with
the optional I<perms> parameter. The Flickr::API returns a
uri which (in this case) is cut from the terminal and pasted
into a browser.

  my $request4 = $api->request_auth_uri($perms, $frob);

  print "\n\nYou now need to open: \n\n$request4\n\nin a browser.\n ";

=cut


my $permreq = 'read';
if ( $permstr && $permstr =~ /^(read|write|delete)$/) {
    $permreq = $permstr;
}

my $uri = $api->request_auth_url($permreq,$frob);

my $request4 = $uri->as_string;

print "\n\nYou now need to open: \n\n$request4\n\nin a browser.\n ";


=head2 Flickr Step 4. Flickr: Prompts user to provide Authorization

Assuming all is well with the I<frob> and I<request_auth_uri> Flickr
will open a webpage to allow you to authenticate the application
identified by the B<api_key> to have the requested B<perms>.


=head2 Flickr Step 4. User: User authorizes application access

This is you, granting permission to the application.

=cut


print "\n\n";

ReadMode(1);
my $response4 = $term->readline('Press [Enter] after setting up authorization on Flickr. ');


=head2 Flickr Step 5, Application: exchange frob for token

The script takes the B<frob> and exchanges it for a B<token>.

  my $request5 = $api->flickr_access_token($frob);

=cut

my $request5 = $api->flickr_access_token($frob);


=head2 Flickr Step 5, Flickr: returns a token

Flickr will return a B<token> if all has gone well. This is
stashed in the Flickr::API object.

=head2 Save the access information

How you save the access information is outside the scope of this
example. However, the B<export_config> method can be used
to retrieve the flickr parameters from the Flickr::API object.

  my %fconfig = $api->export_config();

  print Dumper(\%fconfig);

=cut

my %fconfig = $api->export_config();

print Dumper(\%fconfig);

if ($configfile) { $api->export_storable_config($configfile); }

exit;

__END__

=pod

=head1 AUTHOR

Louis B. Moore <lbmoore at cpan.org> 

=head1 COPYRIGHT AND LICENSE

Copyright 2016, Louis B. Moore

This program is released under the Artistic License 2.0 by The Perl Foundation.

=cut

