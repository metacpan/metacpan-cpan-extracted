use 5.008001;
use strict;
use warnings;

package Devel::Cover::Report::Codecov::Service::GithubActions;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub detect {
	return $ENV{GITHUB_ACTIONS};
}

sub configuration {
	return {
		service   => 'custom',
		commit    => $ENV{GITHUB_SHA},
		build     => sprintf( '%s.%s.%s', $ENV{GITHUB_RUN_ID}, $ENV{GITHUB_RUN_NUMBER}, $ENV{GITHUB_RUN_ATTEMPT} ),
		build_url => sprintf( '%s/%s/actions/runs/%s', $ENV{GITHUB_SERVER_URL}, $ENV{GITHUB_REPOSITORY}, $ENV{GITHUB_RUN_ID} ),
		job       => $ENV{GITHUB_RUN_ID},
		slug      => $ENV{GITHUB_REPOSITORY},
		$ENV{GITHUB_REF_TYPE} => $ENV{GITHUB_HEAD_REF},
	};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Devel::Cover::Report::Codecov::Service::GithubActions - gather env vars from Github Actions for Codecov report

=head1 DESCRIPTION

Glue between L<Devel::Cover::Report::Codecov> and Github Actions.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-devel-cover-report-codecov-service-githubactions/issues>.

=head1 SEE ALSO

L<Devel::Cover::Report::Codecov>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2024 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

