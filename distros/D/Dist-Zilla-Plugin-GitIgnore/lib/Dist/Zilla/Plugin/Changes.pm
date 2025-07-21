package Dist::Zilla::Plugin::Changes;
$Dist::Zilla::Plugin::Changes::VERSION = '0.003';
use Moose;
with qw/Dist::Zilla::Role::FileGatherer/;
use MooseX::Types::Moose qw/Str Int/;

use experimental 'signatures';

use namespace::autoclean;

has filename => (
	is      => 'ro',
	isa     => Str,
	default => 'Changes',
);

has initial => (
	is        => 'ro',
	isa       => Str,
	predicate => 'has_initial',
);

has indent => (
	is        => 'ro',
	isa       => Int,
	default   => 10,   # [NextRelease]
);

sub gather_files($self) {
	my $header = "Revision history for " . $self->zilla->name;
	my @lines = ($header, '', '{{$NEXT}}');

	if ($self->has_initial) {
		my $indent = ' ' x $self->indent;
		push @lines, $indent . $self->initial
	}

	my $payload = join '', map { "$_\n" } @lines;
	$self->add_file(Dist::Zilla::File::InMemory->new(
		name    => $self->filename,
		content => $payload,
	));

	return;
}

1;

# ABSTRACT: Create a changes file

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Changes - Create a changes file

=head1 VERSION

version 0.003

=head1 SYNOPSIS

In your profile.ini

 [Changes]
 initial = - Initial release

=head1 DESCRIPTION

This is a minting plugin to add a changelog file, meant to be used together with L<NextRelease|https://metacpan.org/pod/Dist::Zilla::Plugin::NextRelease>.

=head1 ATTRIBUTES

=head2 filename

This sets the filename of the changelog. It defaults to C<Changes>.

=head2 initial

This is default entry for the initial version. This could be something like C<- Initial release>. If not set, no such line is added.

=head2 indent

This is the indentation used for the initial line, it defaults to C<10>, to match the default indentation of C<NextRelease>. This should only be changed if you override the C<format> argument to C<NextRelease>.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
