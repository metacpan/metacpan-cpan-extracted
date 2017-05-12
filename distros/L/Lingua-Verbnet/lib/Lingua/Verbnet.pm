package Lingua::Verbnet;

use strict;
use warnings;
our $VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)/g;

use XML::Parser;
use Lingua::Verbnet::Ambiguity; 
use Carp;

sub new {
	my %stats = (); # currently just the ambiguity stats
	my $class = shift;
	my $parser = new XML::Parser(
		Style => 'Subs', 
		Pkg => 'Lingua::Verbnet::StatHandlers');
	{
		package Lingua::Verbnet::StatHandlers; # handlers to fill up %stats
		no warnings 'once';
		no warnings 'redefine'; # we purposefully redefine the subs here,
		# in order to package the correct %stats/$frames/@members in the closure
		*{VNCLASS} = sub { # in Lingua::Verbnet::StatHandlers::
			my $frames = 0;
			my @members = ();

			*{MEMBER} = sub {
				my ($parser, $el, %attrs) = @_;
				push @members, $attrs{'name'};
			};

			*{FRAME} = sub { $frames++; };

			*{VNCLASS_} = sub { 
				for my $e (@members) {
					# let += operate on unused slots silently
					no warnings 'uninitialized';
					$stats{$e} += $frames;
				}
			};
		};
	}
	for my $file (@_) {
		$parser->parsefile($file);
	}
	my %ambiguity = %stats;
	my $closure = sub {
		if ('ambiguity' eq $_[0]) {
			bless \%ambiguity, 'Lingua::Verbnet::Ambiguity';
		}
		else {
			croak "$class can't $_[0]";
		}
	};
	bless $closure, $class;
}

sub DESTROY {}
sub AUTOLOAD {
	   my $self = shift;

	   # Remove the package name. See perlbot(1).
	   our $AUTOLOAD =~ s/^.*:://;

	   $self->($AUTOLOAD,@_);
}

1;
=head1 NAME

Lingua::Verbnet -- extract stats from verbnet xml files

=head1 SYNOPSIS

	use Lingua::Verbnet;
	my @verbnet_xml_files = ... ;
	my $verbnet = Lingua::Verbnet->new(@verbnet_xml_files);
	$verbnet->ambiguity->score('cut'); # get the ambiguity score of the verb 'cut'
	my %stats = $verbnet->ambiguity->hash; # get the full ambiguity scores hash (verb => score)

=head1 DESCRIPTION

Potentially, collect and query various aspects of data
from the verbnet XML files. Currently, supports just
the ambiguity stats extraction.

=head1 METHODS

=over

=item new

Constructor, arguments include the list of the source files
to contain the verbnet XML data. If no arguments given,
assumes reading from the STDIN.

=item ambiguity

Return an Lingua::Verbnet::Ambiguity object for querying 
the verb ambiguity stats.

=back

=head1 THANKS

Published mainly for the purpose of demonstrating the concise way of using
the Subs style of XML::Parser together with closures, which is inspired
by DSSSL (thanks, James Clark!) and SGMLSpm script "sgmlspl.pl" by David Megginson
(thanks, and blue skies!). Thanks also to Yuval Kogman for his persistent
insistence that the above is a good enough reason to publish this on CPAN.
Thanks to Dr. Michael Elhadad who asked me to do the cross-evaluation
of two probabilistic parsers at http://www.cs.bgu.ac.il/~nlpproj/parse-eval/ ,
where this code originated.

=head1 SEE ALSO

L<verbstat(1)>, L<difficult(1)>, L<Lingua::Verbnet::Ambiguity>,
I<VerbNet> at L<http://verbs.colorado.edu/verb-index/index.php>

=head1 AUTHOR

Vassilii Khachaturov <F<vassilii@tarunz.org>>

=head1 LICENSE

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
