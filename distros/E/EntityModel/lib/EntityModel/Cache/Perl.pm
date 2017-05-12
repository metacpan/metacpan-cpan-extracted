package EntityModel::Cache::Perl;
{
  $EntityModel::Cache::Perl::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw(EntityModel::Cache)],
};

=head1 NAME

EntityModel::Cache::Perl - simple proof-of-concept Perl-level caching layer

=head1 VERSION

version 0.102

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Tie::Cache::LRU;

our %cache;
tie %cache, 'Tie::Cache::LRU', 1024;

=head1 METHODS

=cut

sub get {
	my $self = shift;
	my $k = shift;
	return $cache{$k};
}

sub remove {
	my $self = shift;
	my $k = shift;
	delete $cache{$k};
	return $self;
}

sub incr {
	my $self = shift;
	my $k = shift;
	++$cache{$k};
}

sub decr {
	my $self = shift;
	my $k = shift;
	--$cache{$k};
}

sub set {
	my $self = shift;
	my $k = shift;
	$cache{$k} = shift;
	return $self;
}

sub atomic {
	my $self = shift;
	die 'This is an instance method' unless ref($self);
	my $k = shift;
	my $f = shift;
	my $v = $self->get($k);

	if($v) {
		logDebug('[%s] is cached, %d bytes', $k, length($v));
		return $v;
	}

	$v = $f->($k); # old memcached without cas support may die here
	$self->set($k, $v, 5);
	return $v;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
