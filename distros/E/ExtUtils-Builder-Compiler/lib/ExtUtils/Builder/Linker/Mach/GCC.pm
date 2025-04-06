package ExtUtils::Builder::Linker::Mach::GCC;
$ExtUtils::Builder::Linker::Mach::GCC::VERSION = '0.027';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Linker::Unixy';

sub _init {
	my ($self, %args) = @_;
	$args{ld} //= [qw/env MACOSX_DEPLOYMENT_TARGET=10.3 cc/];
	$args{export} //= 'all';
	$self->SUPER::_init(%args);
	return;
}

my %flag_for = (
	'loadable-object' => [qw/-bundle -undefined dynamic_lookup/],
	'shared-library'  => ['-dynamiclib'],
);

sub linker_flags {
	my ($self, $from, $to, %args) = @_;
	my @ret = $self->SUPER::linker_flags($from, $to, %args);
	push @ret, $self->new_argument(rank => 10, value => $flag_for{ $self->type }) if $flag_for{ $self->type };
	return @ret;
}

sub add_runtime_path {
	my ($self, $dirs, %opts) = @_;
	$self->add_argument(ranking => $self->fix_ranking(30, $opts{ranking}), value => [ map { "-Wl,-rpath,$_" } @{$dirs} ]);
	return;
}

1;
