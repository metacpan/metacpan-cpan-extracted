package ExtUtils::Builder::Compiler::VMS;
$ExtUtils::Builder::Compiler::VMS::VERSION = '0.029';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Compiler';

use Carp ();

sub _init {
	my ($self, %args) = @_;
	$args{cc} //= ['CC/DECC'];
	$self->SUPER::_init(%args);
	return;
}

# The VMS compiler can only have one define and one include qualifier, so we need to juggle here

sub add_argument {
	my ($self, %opts) = @_;
	my @value;
	for my $elem (@{ delete $opts{value} }) {
		if ($elem =~ m{ / def [^=]+ =+ (\()? ( [^/\)]* ) (?(1) \) ) }xi) {
			my @defines = $2 =~ m/ ( \w+ | "[^"]+" ) /gx;
			push @{ $self->{defines} }, @defines;
		}
		elsif ($elem =~ m{ / inc [^=]+ =+ (\()?  ( [^/\)]* ) (?(1) \) ) }xi) {
			$self->add_include_dir([$2]);
		}
		else {
			push @value, $elem;
		}
	}
	$self->SUPER::add_argument(%opts, value => \@value);
	return;
}

sub compile_flags {
	my ($self, $from, $to) = @_;

	my @ret;
	my @include_dirs = map { $_->{value} } @{ $self->{include_dirs} };
	my @defines = map { defined $_->{value} ? $_->{value} ne '' ? qq/"$_->{key}=$_->{value}"/ : qq{"$_->{key}"} : Carp::croak("Can't undefine '$_->{key}'") } @{ $self->{defines} };
	push @ret, $self->new_argument(ranking => 30, value => [ '/include=' . join ',', @include_dirs ]) if @include_dirs;
	push @ret, $self->new_argument(ranking => 40, value => [ '/define=' . join ',', @defines ])     if @defines;
	push @ret, $self->new_argument(ranking => 75, value => [ "/obj=$to", $from ]);
	return @ret;
}

1;

#ABSTRACT: Class for compiling with a VMS compiler

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Compiler::VMS - Class for compiling with a VMS compiler

=head1 VERSION

version 0.029

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
