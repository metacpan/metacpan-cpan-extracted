package GID::Dir;
BEGIN {
  $GID::Dir::AUTHORITY = 'cpan:GETTY';
}
{
  $GID::Dir::VERSION = '0.004';
}
# ABSTRACT: A dir representation in GID

use strictures 1;
use base 'Path::Class::Dir';
use Scalar::Util qw( blessed );
use File::Temp ();
use GID::File;

sub mkdir {
	my $self = shift;
	my $newdir = blessed $self
		? $self->dir(@_)
		: $self->new(@_)->absolute;
	$newdir->mkpath;
	return $newdir;
}

sub dir { shift->subdir(@_) }
sub rm { shift->remove(@_) }
sub rmrf { shift->rmtree(@_) }

sub tempfile {
	my $self = shift;
	# TODO: should actually parse $filename and use $self->file($parsed_filename_base);
	my ($fh, $filename) = File::Temp::tempfile(@_, DIR => $self);
	return GID::File->new($filename);
}

sub _parse_entities_selectors {
	my $self = shift;
	my @selectors;
	my $code;
	for (@_) {
		if (ref $_ eq 'CODE') {
			$code = $_;
			last; # so far no handling of parameters after CODEREF
		} else {
			push @selectors, $_;
		}
	}
	return $code, @selectors;
}

sub files {
	my $self = shift;
	my ( $code, @selectors ) = $self->_parse_entities_selectors(@_);
	$self->entities(@selectors,sub {
		$code->() unless $_->is_dir;
	});
}

sub dirs {
	my $self = shift;
	my ( $code, @selectors ) = $self->_parse_entities_selectors(@_);
	$self->entities(@selectors,sub {
		$code->() if $_->is_dir;
	});
}

sub entities {
	my $self = shift;
	my ( $code, @selectors ) = $self->_parse_entities_selectors(@_);
	for my $child ($self->children) {
		my $match;
		for (@selectors) {
			if ($child->basename =~ $_) {
				$match = 1;
				last;
			}
		}
		$code->() for ($child);
	}
}

1;

__END__

=pod

=head1 NAME

GID::Dir - A dir representation in GID

=head1 VERSION

version 0.004

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
