package Memory::Leak::Hunter;
{
  $Memory::Leak::Hunter::VERSION = '0.02';
}
use strict;
use warnings;

use Devel::Gladiator;

sub new {
	my ($class) = @_;
	return bless { records => [] }, $class;
}

sub record {
	my ($self, $name) = @_;
	push @{ $self->{records} }, {
		time  => time,
		count => Devel::Gladiator::arena_ref_counts,
		name  => $name,
	};
	return;
}

sub records {
	my ($self) = @_;
	return $self->{records};
}

sub last_diff {
	my ($self) = @_;
	Carp::croak('last_diff called before having 2 records')
		if @{ $self->{records} } < 2;
	return _diff($self->{records}[-2]{count}, $self->{records}[-1]{count});
	
}

sub _diff {
	my ($first, $second) = @_;

	my %diff;
	foreach my $k (keys %$second) {
		my $d = $second->{$k} - ($first->{$k} || 0);
		if ($d) {
			$diff{$k} = $d;
		}
	}

	return \%diff;
}


sub report {
	my ($self) = @_;

	my $str = '';
	foreach my $r (@{ $self->{records} }) {
		$str .= sprintf "%5s, %20s", $r->{time}, $r->{name};
		for my $k (sort keys %{ $r->{count} }) {
			$str .= " $k=$r->{count}{$k} ";
		}
		$str .= "\n";
	}

	return $str;
}

=head1 NAME

Memory::Leak::Hunter - help to find memory leaks

=head1 SYNOPSIS

Experimantal usage of L<Devel::Gladiator>

=head1 AUTHOR

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gabor Szabo L<http://szabgab.com/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut




1;

