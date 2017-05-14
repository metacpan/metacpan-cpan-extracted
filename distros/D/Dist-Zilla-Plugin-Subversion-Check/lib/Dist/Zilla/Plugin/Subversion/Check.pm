use strict;
use warnings;
package Dist::Zilla::Plugin::Subversion::Check;
# ABSTRACT: check SVN working copy before release

use Dist::Zilla 4 ();
use Moose;

use SVN::Client;

with 'Dist::Zilla::Role::BeforeRelease';

has 'svn' => (
        is => 'ro',
        isa => 'SVN::Client',
        lazy => 1,
        default => sub {
                my $self = shift;
                SVN::Client->new();
        },
);

has check_up2date => ( is => 'rw', isa => 'Bool', default => 1 );
has check_uncommited => ( is => 'rw', isa => 'Bool', default => 1 );
has check_missing => ( is => 'rw', isa => 'Bool', default => 1 );
has check_untracked => ( is => 'rw', isa => 'Bool', default => 1 );

has '_wc_revision' => ( is => 'ro', isa => 'Int', lazy => 1,
	default => sub {
		my $self = shift;
		my $rev;
		$self->svn->info("", undef, 'WORKING', sub { $rev = $_[1]->rev }, 0);
		return($rev);
	}
);

has '_repo_head_revision' => ( is => 'ro', isa => 'Int', lazy => 1,
	default => sub {
		my $self = shift;
		my $rev;
		$self->svn->info("", undef, 'HEAD', sub { $rev = $_[1]->rev }, 0);
		return($rev);
	}
);

has '_svn_status' => ( is => 'ro', isa => 'HashRef[ArrayRef[Str]]', lazy_build => 1 );

sub _build__svn_status {
	my $self = shift;
	my $ret = { 'untracked' => [], 'added' => [], 'missing' => [], 'deleted' => [],
		'modified' => [], 'merged' => [], 'conflicted' => [] };
	$self->svn->status('', 'HEAD', sub {
		if($_[1]->text_status == 2) { push(@{$ret->{'untracked'}}, $_[0]); }
		if($_[1]->text_status == 4) { push(@{$ret->{'added'}}, $_[0]); }
		if($_[1]->text_status == 5) { push(@{$ret->{'missing'}}, $_[0]); }
		if($_[1]->text_status == 6) { push(@{$ret->{'deleted'}}, $_[0]); }
		if($_[1]->text_status == 8) { push(@{$ret->{'modified'}}, $_[0]); }
		if($_[1]->text_status == 9) { push(@{$ret->{'merged'}}, $_[0]); }
		if($_[1]->text_status == 10) { push(@{$ret->{'conflicted'}}, $_[0]); }
	}, 1, 1, 1, 0);

	return($ret);
}

foreach my $i ('untracked', 'added', 'missing', 'deleted', 'modified', 'merged', 'conflicted') {
	has '_'.$i.'_files' => (
		is => 'ro', isa => 'ArrayRef[Str]', lazy => 1,
		traits => [ 'Array' ],
		default => sub {
			my $self = shift;
			return($self->_svn_status->{$i});
		},
		handles => {
			'_'.$i.'_files_count' => 'count',
		},
	);
}

sub before_release {
        my $self = shift;

	$self->log('WC revision: '.$self->_wc_revision);
	$self->log('Repository HEAD revision: '.$self->_repo_head_revision);
        if( $self->check_up2date && $self->_wc_revision < $self->_repo_head_revision ) {
                $self->log_fatal("Working copy not up-to-date!");
        }

	foreach my $type ( keys %{$self->_svn_status} ) {
		if( scalar @{$self->_svn_status->{$type}} ) {
			$self->log($type." files: ".join(', ', @{$self->_svn_status->{$type}}) );
		}
	}

	if( $self->check_missing && $self->_missing_files_count ) {
		$self->log_fatal('Some files in working copy are missing!');
	}


	if( $self->check_untracked && $self->_untracked_files_count ) {
		$self->log_fatal('Some files in working copy are not under version control!');
	}

	if( $self->check_uncommited && (
				$self->_added_files_count ||
				$self->_deleted_files_count ||
				$self->_modified_files_count ||
				$self->_merged_files_count ||
				$self->_conflicted_files_count )
			) {
		$self->log_fatal('Working copy has uncommited changes!');
	}

	return;
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::Subversion::Check - check SVN working copy before release

=head1 SYNOPSIS

In your F<dist.ini>:

  [Subversion::Check]
  # you may want to disable individual checks (uncomment)
  #check_up2date = 0
  #check_uncommited = 0
  #check_missing = 0
  #check_untracked = 0

=head1 DESCRIPTION

This plugin checks your current working copy before doing a dzil release.

The plugin accepts the following options:

=over

=item *

C<check_up2date> (default: 1) - check if working copy is up-to-date.

=item *

C<check_uncommited> (default: 1) - check if the working copy has uncommited changes.

=item *

C<check_missing> (default: 1) - check if files in the working copy are missing.

=item *

C<check_untracked> (default: 1) - check if there are untracked files in the current working copy.

=back

=head1 AUTHOR

Markus Benning

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Markus Benning

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

