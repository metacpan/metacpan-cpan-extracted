package ExtUtils::Builder::Linker::Unixy;
$ExtUtils::Builder::Linker::Unixy::VERSION = '0.032';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Linker';

sub linker_flags {
	my ($self, $from, $to, %opts) = @_;
	my @ret;
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "-L$_->{value}" ]) } @{ $self->{library_dirs} };
	push @ret, map { $self->new_argument(ranking => $_->{ranking}, value => [ "-l$_->{value}" ]) } @{ $self->{libraries} };
	push @ret, $self->new_argument(ranking => 50, value => [ '-o' => $to, @{$from} ]);
	return @ret;
}

1;

