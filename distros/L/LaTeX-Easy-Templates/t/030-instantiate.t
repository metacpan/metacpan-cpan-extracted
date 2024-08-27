#!/usr/bin/env perl

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

our $VERSION = '0.06';

use Test::More;
use Test::More::UTF8;
use FindBin;
use File::Spec;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 1;

my $curdir = $FindBin::Bin;

my $tests = create_test_data();
ok(defined($tests), 'create_test_data()'." : called and got test data") or BAIL_OUT;
is(ref($tests), 'ARRAY', 'create_test_data()'." : called and got test data as an ARRAY") or BAIL_OUT;
ok(scalar(@$tests)>0, 'create_test_data()'." : called and got test data and it is not empty") or BAIL_OUT;

# and do the tests:
for my $atest (@$tests){
	my $result = $atest->{'result'};
	my $pars = $atest->{'params'};
	my $name = $atest->{'name'};
	my $latter = LaTeX::Easy::Templates->new({
		'debug' => {
			'verbosity' => $VERBOSITY,
		},
		%$pars
	});
	if( $result =~ /^success/ ){
		ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called for test '${name}' and got success.") or BAIL_OUT;
	} else {
		ok(!defined($latter), 'LaTeX::Easy::Templates->new()'." : called for test '${name}' and got failure (as it was expected, all good).") or BAIL_OUT;
	}
}

# returns an array of tests to do
sub create_test_data {
	# the following controls all the tests, one test is one array item
	# if params->processors->template->content exists (but undef)
	# and also params->processors->template->filename exists (and defined)
	# then the 'filename' will be read into a string,
	# filename will be erased and 'content' added.
	my @tests = (
	  {
		# specify templates as real, existing filenames (key), value is undef
		'result' => 'success',
		'name' => 'test1',
		'params' => {
		  'processors' => {
			# 2 on disk
			'simple20-in-memory' => {
			   'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				'filepath' => File::Spec->catfile($curdir, 'templates', 'simple20', 'main.tex.tx'),
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
			'complex-on-disk' => {
			  'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				'filepath' => File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files', 'main.tex.tx'),
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
		  },
		},
	  },
	  {
		# specify templates as real, existing filenames (key), value is undef
		'result' => 'success',
		'name' => 'test2',
		'params' => {
		  'processors' => {
			# 1 in memory string
			'simple20-in-memory' => {
			   'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				# content will be read from file and set and filename will be deleted
				'filepath' => File::Spec->catfile($curdir, 'templates', 'simple20', 'main.tex.tx'),
				'content' => undef,
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
		  },
		},
	  },
	  {
		'result' => 'success',
		'name' => 'test3',
		'params' => {
		  'processors' => {
			# 1 in memory string and 1 on disk
			'simple20-in-memory' => {
			   'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				# content will be read from file and set and filename will be deleted
				'filepath' => File::Spec->catfile($curdir, 'templates', 'simple20', 'main.tex.tx'),
				'content' => undef,
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
			'complex-on-disk' => {
			  'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				# content will be read from file and set and filename will be deleted
				'filepath' => File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files', 'main.tex.tx'),
				'content' => undef,
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
		  },
		},
	  },
	  {
		# this must fail
		'result' => 'fail',
		'name' => 'test5',
		'params' => {},
	  },
	);

	# create the in-memory strings
	for my $atest (@tests){
		if( exists($atest->{'params'}->{'processors'}) && defined($atest->{'params'}->{'processors'})
		 && exists($atest->{'params'}->{'processors'}->{'template'}) && defined($atest->{'params'}->{'processors'}->{'template'})
		 && exists($atest->{'params'}->{'processors'}->{'template'}->{'content'})
		 && ! defined($atest->{'params'}->{'processors'}->{'template'}->{'content'})
		 && exists($atest->{'params'}->{'processors'}->{'template'}->{'filename'})
		 && defined($atest->{'params'}->{'processors'}->{'template'}->{'filename'})
		){
			# read file into content
			my $FH;
			ok(open($FH, '<:utf8', $atest->{'params'}->{'processors'}->{'template'}->{'filename'}), "Opened template file '".$atest->{'params'}->{'processors'}->{'template'}->{'filename'}."' for reading.") or BAIL_OUT("no: $!");
			{ local $/ = undef; $atest->{'params'}->{'processors'}->{'template'}->{'content'} = <$FH> } close $FH;
			delete $atest->{'params'}->{'processors'}->{'template'}->{'filename'};
		}
	}

	return \@tests
}
# END
done_testing();
