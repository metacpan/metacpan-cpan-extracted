#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 172;
use Test::MockModule;

use CGI;
use URI;

use Maypole;

# simple test class that inherits from Maypole
{
  package MyDriver;
  @MyDriver::ISA = 'Maypole';
  @MyDriver::VERSION = 1;
}

# back to package main;
my $driver_class = 'MyDriver';
my $r = $driver_class->new;

my $query = { list   => [ qw/ fee fi fo / ], string => 'baz', number => 4 };

my $query_string = '?number=4&string=baz&list=fee&list=fi&list=fo';

my @bases = ( 'http://www.example.com',
	      'http://www.example.com/', 'http://www.example.com/foo',
	      'http://www.example.com/foo/', );

# make_uri
{
  my @uris = (
	      { expect   =>'',
		send     => [ '' ],
	      },
	      { expect   => '',
		send     => [ () ],
	      },
	      { expect   => '/table',
		send     => [ qw( table ) ],
	      },
	      { expect   => '/table/action',
		send     => [ qw( table action ) ],
	      },
	      { expect   => '/table/action/id',
		send     => [ qw( table action id ) ],
	      },
	      { expect   =>'',
		send     => [ '', $query ],
	      },
	      { expect   => '',
		send     => [ $query ],
	      },
	      { expect   => '/table',
		send     => [ qw( table ), $query ],
	      },
	      { expect   => '/table/action',
		send     => [ qw( table action ), $query ],
	      },
	      { expect   => '/table/action/id',
		send     => [ qw( table action id ), $query ],
	      },
	     );

  foreach my $base (@bases) {
    $driver_class->config->uri_base($base);
    (my $base_no_slash = $base) =~ s|/$||;
    my $base_or_slash = $base_no_slash || '/';
    my $i = 1;

    foreach my $test (@uris) {
      #diag "BASE: $base - URI #$i"; $i++;
      my @s      = @{ $test->{send} };
      my $expect = $test->{expect};
      my $uri = $r->make_uri(@s);

      my $expected = $base_or_slash.$test->{expect};

      my ($uri_basepath,$uri_query) = split(/\?/,$uri);

      my $q_got = new CGI($uri_query);

      if ($uri_query) {
	# check query params
	# list   => [ qw/ fee fi fo / ], string => 'baz', number => 4
	is($q_got->param('string'),'baz','string param correct');
	is($q_got->param('number'),4,'number param correct');
	is_deeply([$q_got->param('list')],[ qw/ fee fi fo / ],'list param correct');
      }
      ok(URI::eq($expected,$uri_basepath),'host and path match');

    }
  }
} ;


# make_path
{
  # expect       # send
  my @uris = ( 
	      { expect   => '/table/action',
		send     => [ qw( table action ) ],
	      },
	      { expect   => '/table/action/id',
		send     => [ qw( table action id ) ],
	      },
	      { expect   => '/table/action',
		send     => [ qw( table action ), $query ],
	      },
	     );

  foreach my $base (@bases) {
    $driver_class->config->uri_base($base);

    (my $base_no_slash = $base) =~ s|/$||;
    my $base_or_slash = $base_no_slash || '/';

    my $i = 1;
    foreach my $test (@uris) {
      #diag "BASE: $base - URI #$i"; $i++;

      my @args = @{ $test->{send} };

      my %args = ( table  => $args[0],
		   action => $args[1],
		   additional => $args[2],
		 );

      my %arg_sets = ( array => \@args, 
		       hash  => \%args, 
		       hashref => \%args,
		     );

      my $expect = $test->{expect};

      foreach my $set (keys %arg_sets) {

	my $path;
	$path = $r->make_path(@{ $arg_sets{$set} }) if $set eq 'array';
	$path = $r->make_path(%{ $arg_sets{$set} }) if $set eq 'hash';
	$path = $r->make_path($arg_sets{$set})   if $set eq 'hashref';

	my ($uri_path,$uri_query) = split(/\?/,$path);
	my $q_got = new CGI($uri_query);

	my $expected = $expect =~ m|^/| ? "$base_no_slash$expect" : "$base_or_slash$expect";
	if ($uri_query) {
	  # check query params
	  # list   => [ qw/ fee fi fo / ], string => 'baz', number => 4
	  is($q_got->param('string'),'baz','string param correct');
	  is($q_got->param('number'),4,'number param correct');
	  is_deeply([$q_got->param('list')],[ qw/ fee fi fo / ],'list param correct');
	}
	ok(URI::eq($expected,$uri_path),'host and path match');

      }
    }
  }
};
