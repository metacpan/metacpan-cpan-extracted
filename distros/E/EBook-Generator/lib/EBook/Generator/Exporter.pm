package EBook::Generator::Exporter;

use 5.008009;
use strict;
use warnings;

use Data::Dumper;
use EBook::Generator::Exporter::PDF;
use EBook::Generator::Exporter::Text;
use EBook::Generator::Exporter::XHTML;

our $VERSION = '0.01';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->init(@args);
}

sub init
{
	my ($self, $browser, $log) = @_;
	$self->{'browser'} = $browser;
	$self->{'log'} = $log;
	foreach my $format (qw(pdf text epub xhtml)) {
		$self->{$format.'-exporter'} = undef;
	}
	return $self;
}

sub initExporter
{
	my ($self, $format) = @_;
	
	# there is no extra exporter for EPUB, its just a special kind of XHTML!
	if ($format =~ /^epub$/i) {
		$self->{'options'}->{'epub'} = 1;
		$format = 'xhtml';
	}

	# create exporter for requested export format
	if ($format =~ /^(x?html?)$/i && !defined $self->{'xhtml-exporter'}) {
		$self->{'xhtml-exporter'} = EBook::Generator::Exporter::XHTML->new($self->{'browser'});
		return $self->{'xhtml-exporter'};
	}
	elsif ($format =~ /^(te?xt)$/i && !defined $self->{'text-exporter'}) {
		$self->{'text-exporter'} = EBook::Generator::Exporter::Text->new($self->{'browser'});
		return $self->{'text-exporter'};
	}
	else { #($format =~ /^(pdf)$/i && !defined $self->{'pdf-exporter'}) {
		$self->{'pdf-exporter'} = EBook::Generator::Exporter::PDF->new($self->{'browser'});
		return $self->{'pdf-exporter'};
	}
	#die "unable to handle unknown export format '$format'\n";
}

sub writeEBook
{
	my ($self, $ebook, $format, $options) = @_;
	my $exporter = $self->initExporter($format);
	#print Dumper($exporter);
	return $exporter->writeEBook($ebook, $options);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

EBook::Generator - Perl extension for creating EBooks from Websites.

=head1 SYNOPSIS

  use EBook::Generator;
  my $g = EBook::Generator->new();
  my $ebook = $g->readSource("http://www.google.com", fontSize => 12, grayImages => 1);
  $ebook->writeEBook("./Google.pdf");

=head1 DESCRIPTION

EBook::Generator can be used to generate a beautifully looking
e-book out of a website, aka HTML source. It uses LaTeX to
create the actual e-book.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Tom Kirchner, E<lt>kitomer@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
