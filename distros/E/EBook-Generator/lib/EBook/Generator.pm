package EBook::Generator;

use 5.008009;
use strict;
use warnings;
#use Data::Dumper;

use EBook::Generator::EBook;

our $VERSION = '0.01';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->init(@args);
}

sub init
{
	my ($self) = @_;
	$self->{'ebooks'} = [];
	$self->{'latest-log'} = [];
	return $self;
}

sub processSource
{
	my ($self, $url, $format, @options) = @_;
	my $ebook = EBook::Generator::EBook->new($url, @options);
	push @{$self->{'ebooks'}}, $ebook;
	my $filename = $ebook->writeEBook($format);
	$self->{'latest-log'} = $ebook->getLog();
	return $filename;
}

sub getLog
{
	my ($self) = @_;
	return $self->{'latest-log'};
}

# Preloaded methods go here.

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
