use strict;
use warnings;

package Dist::Zilla::Plugin::DOAP;
# ABSTRACT: create a doap.xml file for your project

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moose;
with qw(
	Dist::Zilla::Role::FileGatherer
);

use namespace::autoclean;
use CPAN::Changes;
use CPAN::Meta;
use Dist::Zilla::File::InMemory;
use Dist::Zilla::Types qw(OneZero);
use RDF::DOAP::Lite;

has xml_filename => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
	default => 'doap.xml',
);

has ttl_filename => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
);

has process_changes => (
	is      => 'ro',
	isa     => OneZero,
	default => 0,
	coerce  => 1,
);

sub gather_files
{
	my $self  = shift;
	
	my $zilla = $self->zilla;
	my $doap  = 'RDF::DOAP::Lite'->new(
		meta => 'CPAN::Meta'->new( {%{$zilla->distmeta}} ),
		(($self->process_changes and -f 'Changes')
			? (changes => 'CPAN::Changes'->load('Changes'))
			: ()),
	);
	
	if ($self->xml_filename)
	{
		my $data;
		open my $fh, '>', \$data;
		$doap->doap_xml($fh);
		close $fh;
		
		$self->add_file('Dist::Zilla::File::InMemory'->new(
			name    => $self->xml_filename,
			content => $data,
		));
	}	

	if ($self->ttl_filename)
	{
		my $data;
		open my $fh, '>', \$data;
		$doap->doap_ttl($fh);
		close $fh;
		
		$self->add_file('Dist::Zilla::File::InMemory'->new(
			name    => $self->ttl_filename,
			content => $data,
		));
	}	
}
 
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::DOAP - create a doap.xml file for your project

=head1 SYNOPSIS

In dist.ini:

   [DOAP]

Or even:

   [DOAP]
   xml_filename = project.xml
   ttl_filename = project.ttl

=head1 DESCRIPTION

This is a small plugin for L<Dist::Zilla>, enabling you to bundle a
DOAP file with your distribution.

=head2 The Straight DOAP

So what is DOAP? This explanation is lifted from
L<Wikipedia|http://en.wikipedia.org/wiki/DOAP>.

I<< DOAP (Description of a Project) is an RDF Schema and XML vocabulary
to describe software projects, in particular free and open source
software. >>

I<< It was created and initially developed by Edd Dumbill to convey
semantic information associated with open source software projects. >>

I<< It is currently used in the Mozilla Foundation's project page and
in several other software repositories, notably the Python Package
Index. >>

=head2 Configuration

This plugin has three settings that you can tweak in your C<dist.ini> file:

=over

=item C<< xml_filename >>

The filename for DOAP output, serialized as XML. Defaults to "doap.xml".
Set this to the empty string to disable XML output.

=item C<< ttl_filename >>

The filename for DOAP output, serialized in the slightly more readable
Turtle format. Defaults to undef. Set this to a filename to output some
Turtle.

=item C<< process_changes >>

A boolean indicating whether your C<Changes> file should be processed
to generate a release history. Defaults to 0 (no).

=back

=head2 Hints

For the most part, everything should "just work". The plugin will figure
out everything it needs from your C<distmeta> (i.e. META.json) and
C<Changes> file (if it exists). Here are a few hints though...

=over

=item *

For this module to have the best chance of reading your changelog, format
it as per L<CPAN::Changes::Spec>.

=item *

DOAP represents people as structured resources, while META.json represents
them as strings. This module expects authors and contributors listed in
META.json to conform to one of the following formats:

   Joe Bloggs (JOEB) <joe.bloggs@example.net>
   Joe Bloggs <joe.bloggs@example.net>
   Joe Bloggs

(Assuming that "JOEB" is Joe's PAUSE login.)

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Dist-Zilla-Plugin-DOAP>.

=head1 SEE ALSO

L<RDF::DOAP>, L<RDF::DOAP::Lite>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
