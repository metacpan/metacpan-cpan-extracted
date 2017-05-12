#!/usr/bin/perl
#
# Method Test Echo
#

=pod

=head1 NAME

flickr_method_test_echo.pl

an example for using either OAuth or Old School Flickr

=cut

use warnings;
use strict;
use Flickr::API;
use Getopt::Long;

=pod

=head1 DESCRIPTION

This script uses either the Flickr or OAuth parameters to call
the flickr.test.echo method.

=head1 USAGE

 flickr_method_test_echo.pl --use_api=[oauth, flickr] \
    --key="24680beef13579feed987654321ddcc6" \
    --secret="de0cafe4feed0242"

Depending on what you specify with B<--use_api> the flickr.test.echo
call will use the appropriate parameter set. If B<Flickr::API->new> is
called with a consumer_key, OAuth is used. If B<Flickr::API->new> with
key the old Flickr Authentication is used.


=cut

my $config = {};
my $api;

GetOptions (
    $config,
    'use_api=s',
    'key=s',
    'secret=s',
);

=head1 CALL DIFFERENCES

 if ($config->{use_api} =~ m/flickr/i) {

    $api = Flickr::API->new({'key'    => $config->{key},
                             'secret' => $config->{secret}});
 }
 elsif  ($config->{use_api} =~ m/oauth/i) {

    $api = Flickr::API->new({'consumer_key'    => $config->{key},
                             'consumer_secret' => $config->{secret}});

}
 else {

     die "\n --use_api must be either 'flickr' or 'oauth' \n";

 }

=cut

if ($config->{use_api} =~ m/flickr/i) {

    $api = Flickr::API->new({
        'key'    => $config->{key},
        'secret' => $config->{secret},
    });
}
elsif  ($config->{use_api} =~ m/oauth/i) {

    $api = Flickr::API->new({
        'consumer_key'    => $config->{key},
        'consumer_secret' => $config->{secret},
    });
}
else {

    die "\n --use_api must be either 'flickr' or 'oauth' \n";

}

my $response = $api->execute_method('flickr.test.echo', {
                     'foo' => 'bar',
                     'baz' => 'quux',
               });

my $ref = $response->as_hash();

print "\n\n",$ref->{method},"\n";
print "  Key: foo  received: ",$ref->{foo},"\n";
print "  Key: baz  received: ",$ref->{baz},"\n\n\n";

exit;

__END__

=pod

=head1 AUTHOR

Louis B. Moore <lbmoore at cpan.org> Based on the code in Flickr::API.

=head1 COPYRIGHT AND LICENSE

Copyright 2014, Louis B. Moore

This program is released under the Artistic License 2.0 by The Perl Foundation.

=cut

