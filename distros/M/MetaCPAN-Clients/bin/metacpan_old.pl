#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Based on example supplied by Moritz Onken.

Fetching distribution in a specific time range that are still on CPAN (and not only on Backpan)

The idea was to fetch old distributions and check if they can still compile and work on a modern version of Perl?
It is especially interesting if the module have new versions as well - if a module is maintained.

=cut

use LWP::UserAgent;
use JSON qw(from_json);
use Data::Dumper qw(Dumper);

print Dumper get('1995-10-05T00:00:00', '2095-10-10T00:00:00', 10);

sub get {
	my ($from, $to, $limit) = @_;

	my $ua = LWP::UserAgent->new;
	#$ua->agent("MyApp/0.1 ");
	my $req = HTTP::Request->new(POST => 'http://api.metacpan.org/release/_search');
	$req->content_type('application/x-www-form-urlencoded');
	$req->content(qq{
	{
	  "query" : {
	    "constant_score" : {
	      "filter" : {
	        "and" : [
	          {
	            "range" : {
	              "release.date" : {
	                "to" : "$to",
	                "from" : "$from"
	              }
	            }
	          },
	          {
	            "not" : {
	              "term" : {
	                "status" : "backpan"
	              }
	            }
	          }
	        ]
	      }
	    }
	  },
	  "fields" : ["distribution", "date", "status"],
	  "size" : $limit
	}
	});

	my $res = $ua->request($req);

	if ($res->is_success) {
		my $result = from_json $res->content;
		return $result->{hits}{hits};
	} else {
		die $res->status_line;
	}
}



