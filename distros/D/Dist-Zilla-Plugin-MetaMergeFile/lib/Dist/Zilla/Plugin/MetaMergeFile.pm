package Dist::Zilla::Plugin::MetaMergeFile;
$Dist::Zilla::Plugin::MetaMergeFile::VERSION = '0.003';
use Moose;
use namespace::autoclean;

with qw/Dist::Zilla::Role::MetaProvider Dist::Zilla::Role::PrereqSource/;

use MooseX::Types::Stringlike 'Stringlike';
use Parse::CPAN::Meta;

my @defaults = qw/metamerge.json metamerge.yml/;

has filename => (
	is       => 'ro',
	isa      => Stringlike,
	default  => sub {
		return (grep { -f } @defaults)[0];
	},
);

has _rawdata => (
	is       => 'ro',
	lazy     => 1,
	builder  => '_build_rawdata',
);

sub _build_rawdata {
	my $self = shift;
	return Parse::CPAN::Meta->load_file($self->filename);
}

sub metadata {
	my $self = shift;
	my %data = %{ $self->_rawdata };
	delete $data{prereqs};
	return \%data;
}

sub register_prereqs {
	my $self = shift;
	my $prereqs = $self->_rawdata->{prereqs};
	for my $phase (keys %{ $prereqs }) {
		for my $type (keys %{ $prereqs->{$phase} }) {
			$self->zilla->register_prereqs(
				{ phase => $phase, type => $type },
				%{ $prereqs->{$phase}{$type} }
			);
		}
	}
}

__PACKAGE__->meta->make_immutable;

1;

#ABSTRACT: Add arbitrary metadata using a mergefile

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaMergeFile - Add arbitrary metadata using a mergefile

=head1 VERSION

version 0.003

=head1 SYNOPSIS

=head3 dist.ini:

 [MetaMergeFile]

=head3 metamerge.yml

 prereqs:
   runtime:
     recommends:
       Foo: 0.023
     suggests:
       Bar: 0
 resources
   homepage: http://www.example.com/MyModule/
   x_twitter: http://twitter.com/cpan_linked/

=head1 DESCRIPTION

This plugin implements metamerge files. These allow you to easily add arbitrary information to your metafiles.

=head2 Why metamerge files?

Metamerge files are somewhat similar to cpanfiles, but with a few important differences. Firstly, they're not limited to prereqs but allow any valid type of metadata. Secondly, they don't involve evaluating code to produce data, data should be data.

=head2 Names and formats

This file reads either a JSON formatted F<metamerge.json>, or a YAML formatted F<metamerge.yml> (or another file if passed with the C<filename> parameter). Regardless of the format, it will parse them as L<META 2.0|CPAN::Meta::Spec> unless their C<meta-spec> field claims otherwise.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
