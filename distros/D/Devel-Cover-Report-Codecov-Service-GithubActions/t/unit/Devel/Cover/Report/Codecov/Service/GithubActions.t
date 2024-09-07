=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Devel::Cover::Report::Codecov::Service::GithubActions>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2024 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'Devel::Cover::Report::Codecov::Service::GithubActions';
use Test2::Tools::Spec;
use Data::Dumper;

describe "method `detect`" => sub {

	tests 'correctly detects when run by github' => sub {
		local $ENV{GITHUB_ACTIONS} = 1;
		ok $CLASS->detect;
	};
	
	tests 'correctly detects when NOT run by github' => sub {
		local $ENV{GITHUB_ACTIONS} = 0;
		ok !$CLASS->detect;
	};
};

describe "method `configuration`" => sub {

	tests 'gathers data from env variables as expected (branch)' => sub {
		local $ENV{GITHUB_ACTIONS} = 1;
		
		local $ENV{GITHUB_SHA} = 'abc123';
		local $ENV{GITHUB_RUN_ID} = 1;
		local $ENV{GITHUB_RUN_NUMBER} = 2;
		local $ENV{GITHUB_RUN_ATTEMPT} = 3;
		local $ENV{GITHUB_SERVER_URL} = 'https://example.com';
		local $ENV{GITHUB_REPOSITORY} = 'foo/bar';
		local $ENV{GITHUB_REF_TYPE} = 'branch';
		local $ENV{GITHUB_HEAD_REF} = 'xyzzy';
		
		is( $CLASS->configuration, hash {
			field service   => 'custom';
			field commit    => 'abc123';
			field build     => sprintf( '%s.%s.%s', 1, 2, 3 );
			field build_url => sprintf( '%s/%s/actions/runs/%s', 'https://example.com', 'foo/bar', 1 );
			field job       => 1;
			field branch    => 'xyzzy';
			field slug      => 'foo/bar';
		} );
	};

	tests 'gathers data from env variables as expected (tag)' => sub {
		local $ENV{GITHUB_ACTIONS} = 1;
		
		local $ENV{GITHUB_SHA} = 'abc123';
		local $ENV{GITHUB_RUN_ID} = 1;
		local $ENV{GITHUB_RUN_NUMBER} = 2;
		local $ENV{GITHUB_RUN_ATTEMPT} = 3;
		local $ENV{GITHUB_SERVER_URL} = 'https://example.com';
		local $ENV{GITHUB_REPOSITORY} = 'foo/bar';
		local $ENV{GITHUB_REF_TYPE} = 'tag';
		local $ENV{GITHUB_HEAD_REF} = 'xyzzy';
		
		is( $CLASS->configuration, hash {
			field service   => 'custom';
			field commit    => 'abc123';
			field build     => sprintf( '%s.%s.%s', 1, 2, 3 );
			field build_url => sprintf( '%s/%s/actions/runs/%s', 'https://example.com', 'foo/bar', 1 );
			field job       => 1;
			field tag       => 'xyzzy';
			field slug      => 'foo/bar';
		} );
	};
};

done_testing;
