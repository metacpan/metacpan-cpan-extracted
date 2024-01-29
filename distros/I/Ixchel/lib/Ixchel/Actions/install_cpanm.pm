package Ixchel::Actions::install_cpanm;

use 5.006;
use strict;
use warnings;
use Ixchel::functions::install_cpanm;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::install_cpanm - Install cpanm via packages.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a install_cpanm

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'install_cpanm', opts=>{});

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra {
} ## end sub new

sub action {
	my $self = $_[0];

	$self->status_add(status=>'Installing cpanm via packges');

	eval{
		install_cpanm;
	};
	if ($@) {
		$self->status_add(status=>'Failed to install cpanm via packages ... '.$@, error=>1);
	}else {
		$self->status_add(status=>'cpanm installed');
	}

	if (!defined($self->{results}{errors}[0])) {
		$self->{results}{ok}=1;
	}else {
		$self->{results}{ok}=0;
	}

	return $self->{results};
} ## end sub action

sub short {
	return 'Install cpanm via packages.';
}

1;
