package EBook::Generator::Exporter::Text;

use 5.008009;
use strict;
use warnings;

use Text::Wrap;

our $VERSION = '0.01';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->init(@args);
}

sub init
{
	my ($self, $browser) = @_;

	$self->{'final-dir'} = '/tmp/';

	$self->{'browser'} = $browser;

	$self->{'log'} = [];

	$self->{'handlers'} = {
		'document' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my $content = $self->transform_nodes(@subnodes);
			$self->{'meta'}->{'date'} = time() if $self->{'meta'}->{'date'} =~ /\\today/;
			return
					$self->{'meta'}->{'title'}."\n\n".
					'by '.$self->{'meta'}->{'author'}."\n".
					$self->{'meta'}->{'date'}."\n".
					$self->transform_text($self->{'meta'}->{'url'})."\n\n".
					$content;
		},
		'paragraph' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return wrap('','',$self->transform_nodes(@subnodes))."\n\n";
		},
		'headline' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			return wrap('','',$self->transform_nodes(@subnodes))."\n\n";
		},
		'text' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			return ' '.$self->transform_nodes(@subnodes);
		},
		'link' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return
				' '.$self->transform_nodes(@subnodes).
				' [see '.$self->transform_text($opts->{'target'}).'] ';
		},
		'media' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			if ($opts->{'type'} =~ /^(gif|jpe?g|png)$/i) {
				# picture	
				return "\n\n".'[Image: '.$opts->{'url'}.'"]'."\n\n";
			}
			return '';
		},
		'list' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			my $name = ($opts->{'type'} eq 'ordered' ? 'ol' : 'ul');
			my $count = 0;
			return 
				join('', map {
					$count++;
					"\n\n".$count.'.'.wrap('','',$self->transform_nodes($_))."\n\n";
				} @subnodes);
		},
		'preformatted' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return ' '.$self->transform_nodes(@subnodes);
		},
		'quote' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return ' '.$self->transform_nodes(@subnodes);
		},
	};
	
	return $self;
}

sub writeEBook
{
	my ($self, $ebook, $options) = @_;

	$self->{'url'} = $ebook->{'url'};
	$self->{'options'} = $options;

	# convert to xhtml
	$self->{'meta'} = $ebook->{'meta'};
	my $converted = $self->transform_nodes($ebook->{'data'});
	
	# write xhtml file
	my $filename = $self->{'final-dir'}.$ebook->{'meta'}->{'title'}.".txt";
	unlink($filename) if -f $filename;
	my $fh = IO::File->new("> ".$filename);
	print $fh $converted;
	
	print "have fun with: ".$filename."\n";
	return $filename;
}

sub transform_nodes
{
	my ($self, @nodes) = @_;	
	my $conv = '';
	foreach my $node (@nodes) {
		if (ref $node) {
			my $type = $node->[0];
			if (exists $self->{'handlers'}->{$type}) {
				$conv .= $self->{'handlers'}->{$type}->($self, $node);
			} else {
				my ($type, $opts, @subnodes) = @{$node};
				$conv .= $self->transform_nodes(@subnodes);
			}
		}
		else {
			$conv .= $self->transform_text($node);
		}
	}
	return $conv;
}

sub transform_text
{
	my ($self, $s) = @_;
	# ...
	return $s;
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
