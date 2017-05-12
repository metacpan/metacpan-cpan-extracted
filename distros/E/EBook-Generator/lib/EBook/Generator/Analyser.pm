package EBook::Generator::Analyser;

use 5.008009;
use strict;
use warnings;

use Data::Dumper;

our $VERSION = '0.01';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->init(@args);
}

sub init
{
	my ($self, $log) = @_;
	$self->{'log'} = $log;
	return $self;
}

sub analyseContent
{
	my ($self, $ebook) = @_;
	$self->{'options'} = $ebook->{'options'};
	#push @{$self->{'log'}}, Dumper($ebook->{'data'});
	my @newnodes = $self->analyse_nodes($ebook->{'data'});
	$ebook->{'data'} = $newnodes[0];
	return 1;
}

sub analyse_nodes
{
	my ($self, @nodes) = @_;
	
	my %handlers = (
		'document' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			return [$type, $opts, $self->analyse_nodes(@subnodes)];
		},
		'paragraph' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my @newsubnodes = $self->analyse_nodes(@subnodes);
			return () if scalar @newsubnodes == 0;
			return [$type, $opts, @newsubnodes];
		},
		'headline' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my @newsubnodes = $self->analyse_nodes(@subnodes);
			return () if scalar @newsubnodes == 0;
			return [$type, $opts, @newsubnodes];
		},
		'text' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			my @newsubnodes = $self->analyse_nodes(@subnodes);
			return () if scalar @newsubnodes == 0;
			return [$type, $opts, @newsubnodes];
		},
		'link' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my @newsubnodes = $self->analyse_nodes(@subnodes);
			return () if scalar @newsubnodes == 0;
			return [$type, $opts, @newsubnodes];
		},
		'media' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my @newsubnodes = $self->analyse_nodes(@subnodes);
			return [$type, $opts, @newsubnodes];
		},
		'list' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my @newsubnodes = $self->analyse_nodes(@subnodes);
			return () if scalar @newsubnodes == 0;
			return [$type, $opts, @newsubnodes];
		},
		'preformatted' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my @newsubnodes = $self->analyse_nodes(@subnodes);
			return () if scalar @newsubnodes == 0;
			return [$type, $opts, @newsubnodes];
		},
		'quote' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my @newsubnodes = $self->analyse_nodes(@subnodes);
			return () if scalar @newsubnodes == 0;
			return [$type, $opts, @newsubnodes];
		},
	);
	
	my @newnodes = ();
	foreach my $node (@nodes) {
		if (ref $node) {
			my $type = $node->[0];
			if (exists $handlers{$type}) {
				push @newnodes, $handlers{$type}->($self, $node)		
			}	else {
				# push it anyway, so we don't forget any content
				push @newnodes, $node;
			}
		}
		else {
			# cleanup text node
			$node =~ s/^[\s\t\n\r]*//img;
			$node =~ s/[\s\t\n\r]*$//img;
			push @newnodes, $node
				if length $node;
		}
	}
	return @newnodes;
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
