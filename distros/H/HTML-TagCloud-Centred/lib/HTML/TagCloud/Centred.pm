use strict;
use warnings;

=head1 NAME

HTML::TagCloud::Centred - Biggest tags in the centre

=head1 SYNOPSIS

	use HTML::TagCloud::Centred;
	my $cloud = HTML::TagCloud::Centred->new(
		# size_min_pc => 50,
		# size_max_pc => 200,
		# scale_code => sub { ... },
		# html_esc_code => sub { ... },
		# clr_max => '#FF0000',
		# clr_min => '#550000',
	);
	$cloud->add( 'FirstWord', 'http://www.google.co.uk' );
	foreach my $w (
		('Biggest')x7, ('Medium')x5, ('Small')x5, ('Smallest')x10 
	){
		$cloud->add( $w );
	}
	open my $OUT, '>cloud.html';
	# print $OUT $cloud->css;
	# print $OUT $cloud->html;
	print $OUT $cloud->html_and_css;
	close $OUT;
	warn 'Tags: ',Dumper $cloud->tags;	
	exit;
	
=head1 DESCRIPTION

This modules produces a tag cloud with the heaviest words in the centre,
and the lightest on the outside, to make it appear a bit like the clouds
seen in the sky.

Words are accepted through L<add|add> in a sorted order - that is,
add the heaviest word first, the lightest last. When the C<html> or C<css_and_html>
methods are called, the words are added to a grid in a simple spiral: this may
change to produce a prettier cloud, but it works well enough as it is.
	
Otherwise, it is API-compatible with L<HTML::TagCloud|HTML::TagCloud>, though
that module is not required. For further details of this modules methods,
please see L<HTML::TagCloud>.

=head2 OUTPUT

Output is HTML and/or CSS. The HTML contains a C<div> of class C<tagcloud>,
that contains one or more C<div> of class C<row>. Each row contains
C<a> elements for each linked word. If words were supplied without links, 
they are contained in C<span> elements.

Colouring and font-sizing is contained in the C<a> and C<span> C<style>
attributes. The base size can of course be set in your CSS, since all sizing
is by percentage relevant to the parent container. The CSS supplied is minimal,
just to centre the rows.

=cut
	
package HTML::TagCloud::Centred::Base; # Things you have to do without Moose.

sub new {
	my $class = ref($_[0])? ref(shift) : shift;
	my $self  = bless( (ref($_[0])? shift : {@_}), $class );
	$self->_init;
	return $self;
}

sub _init {}

package HTML::TagCloud::Centred;
use base 'HTML::TagCloud::Centred::Base';
use Data::Dumper; # for debugging
use Carp;
use constant BLANK => '_';

eval { require Color::Spectrum };

our $VERSION = 5;

# use Log4perl if we have it, otherwise stub:
# See Log::Log4perl::FAQ
BEGIN {
	eval { require Log::Log4perl };

	# No Log4perl so hide calls to it: see Log4perl FAQ
	if($@) {
		no strict qw"refs";
		*{__PACKAGE__."::$_"} = sub { } for qw(TRACE DEBUG INFO WARN ERROR FATAL);
	}

	# Setup log4perl
	else {
		no warnings;
		no strict qw"refs";
		require Log::Log4perl::Level;
		Log::Log4perl::Level->import(__PACKAGE__);
		Log::Log4perl->import(":easy");
		if ($Log::Log4perl::VERSION < 1.11){ # Add calls to present in early versions
			*{__PACKAGE__."::TRACE"} = *DEBUG;
		}
	}
}

sub add {
	my ($self, $word, $url, $count) = @_;
	confess "No word was supplied" if not defined $word or not length $word;
	push @{ $self->{words} }, new HTML::TagCloud::Centred::Word(
		name => $word,
		url  => $url,
		($self->{html_esc_code}? (html_esc_code => $self->{html_esc_code}) : ())
	);
	return $self;
}

=head2 CONSTRUCTOR (new)

Takes the following optional parameters:

=over 4

=item size_max_pc

The maximum font size of the output, as a CSS percentage value. Default is 120.

=item size_min_pc

The minimum font size of the output, as a CSS percentgage value. Default is
half of C<size_max_pc>.

=item scale_code

Code reference to calculate the scaling of items in the cloud. Defaults to 
something reasonable, but could be used to implement logarithmic or exponential scaling.
The routine gets called as an instance method. Note that the words added to
create the cloud are stored as a list in C<words>.

=item html_esc_code

Code referene to escape HTML in the output (text within 
the cloud and in C<a> element C<title> attributes). Default is to require
C<CGI::Util>, and call C<CGI::Util::escape>. The sole argument is the word to escape.

=item clr_max, clr_min

You can supply these as arguments for L<Color::Spectrum|Color::Spectrum>, 
if you have it installed. See L<Color::Spectrum>. By defaul these values
are not set.

=back

=cut

#=item size_x, size_y
#
#By default, the cloud is laid out on a square grid. If you set both
#C<size_x> and C<size_y>, you can override this, but no error checking is performed.
#

sub html_and_css {
	my $self = shift;
	return $self->css . $self->html;	
}

sub css {
	my $self = shift;
	return "<style type='text/css'>.tagcloud { text-align: center }</style>\n";
}

sub html {
	my $self = shift;
	$self->{limit} = $_[0] if $_[0];

	my $out = "\n<div class='tagcloud'>";
	my $blank = quotemeta BLANK;
	my $re = qr/^\s*$blank+\s*$/;

	$self->_build;

	for my $y (1..$self->{size_y} ){
		my $row = '';
		for my $x (1..$self->{size_x} ){
			next if not defined $self->{grid}->[$x-1]->[$y-1]
				or $self->{grid}->[$x-1]->[$y-1] eq BLANK;
			$row .= "\t" . $self->{grid}->[$x-1]->[$y-1]->html ."\n";
		}
		$out .= "\n<div class='row'>\n" . $row . "</div>\n"
			unless $row eq '' or $row =~ /$re/s;
	}
	
	$out .= "</div>\n";
	return $out;
}

# Move into sub html
sub tags {
	my $self = shift;
	$self->{limit} = $_[0] if $_[0];
	$self->_build unless $self->{inputs};
	my $c = 0;
	
	my $t = scalar( @{ $self->{words} } );
	my @rv;
	my $blank = quotemeta BLANK;
	my $re = qr/^$blank+$/;
	for my $y (1..$self->{size_y} ){
		for my $x (1..$self->{size_x} ){
			next if not defined $self->{grid}->[$x-1]->[$y-1]
				or $self->{grid}->[$x-1]->[$y-1] eq BLANK;
			my $w = $self->{grid}->[$x-1]->[$y-1];
			push @rv, { 
				%$w,
				count	=> $t - $c,
				level	=> $c,
			};
			$c ++;
		}
	}
	
	return @rv;
}


sub _prepare {
	my $self = shift;
	die "No words from which to create a cloud - see add(...)."
	unless $self->{words} and scalar @{ $self->{words} };
	
	# Custom size does not work yet
	#if (not $self->{size_x} and not $self->{size_y}){
		$self->{size_y} = $self->{size_x} = int( sqrt(scalar @{$self->{words}})) +1;
	#}
	
	$self->{inputs}		= [@{ $self->{words} }];
	$self->{grid} 		= [];
	$self->{tags}		= []; # HTML::TagCloud API
	
	$self->{size_max_pc} ||= 120;
	$self->{size_min_pc} ||= $self->{size_max_pc} / 2;
	
	$self->{scale_code} ||= sub {
		($self->{size_max_pc} - $self->{size_min_pc}) / scalar @{$self->{words}};
	};

	$self->{scale_f} = $self->{scale_code}->($self);
	
	for my $y (1..$self->{size_y}){
		$self->{grid}->[$y-1] = [];
		for my $x (1..$self->{size_x}){
			$self->{grid}->[$y-1]->[$x-1] = BLANK;
		}
	}

	# If inputs supplied as words:
	foreach my $w (@{ $self->{inputs} } ){
		if (not ref $w){
			$w = new HTML::TagCloud::Centred::Word( %$w );
			$w->{html_esc_code} = $self->{html_esc_code} if $self->{html_esc_code};
		}
	}
	
	# For API of HTML::TagCloud
	if (exists $self->{limit}){
		$self->{inputs} = [
			@{ $self->{inputs} } [ 0 .. $self->{limit} -1 ]
		];
	}
	
	return $self;
}


# Naive spiral - 1,1,2,2,3,3,..N,N. Replace!
sub _build {
	my $self = shift;
	$self->_prepare;
	my $x = int ($self->{size_x} / 2);	# Centre starting position
	my $y = int ($self->{size_y} / 2);	# Centre starting position
	my @d = (								# Direction of turns
		[1, 0],
		[0, 1],
		[-1, 0],
		[0, -1]
	);
	my $tside	= 0;		# Total sides so far
	my $cside	= 0;		# Current side, index to @d
	my $length	= 1;		# Length of current side
	
	my @clrs;				# Color palette if requested
	if ($Color::Spectrum::VERSION){
		@clrs = Color::Spectrum::generate( 
			scalar( @{ $self->{inputs} } ),
			$self->{clr_max},
			$self->{clr_min}
		);
	}

	while (@{ $self->{inputs} } ){
		my $add_x = ($length * $d[ $cside ]->[0] );
		my $add_y = ($length * $d[ $cside ]->[1] );

		$self->_create_side( 
			from_x	=> $x,
			from_y	=> $y,
			to_x	=> $x + $add_x,
			to_y	=> $y + $add_y,
			(@clrs? (clrs => \@clrs) : ()),
		);

		$x += $add_x;
		$y += $add_y;
		
		DEBUG "For $tside $cside, X $x,  Y $y \n\tadd to x $add_x;  add to y $add_y \n";

		# Increase length every second side
		$length += 1 if $cside % 2;

		# Next side
		if (++$cside == 4){
			$cside = 0;
		}
		
		$tside++;
	}
}

sub _create_side {
	my ($self, $args) = (shift, ref($_[0])? shift : {@_});
	my ($from_x, $from_y, $to_x, $to_y);
	
	if ($args->{from_x} > $args->{to_x}){
		$from_x = $args->{to_x};
		$to_x	= $args->{from_x};
	} else {
		$from_x	= $args->{from_x};
		$to_x	= $args->{to_x};
	}
	
	if ($args->{from_y} > $args->{to_y}){
		$from_y = $args->{to_y};
		$to_y	= $args->{from_y};
	} else {
		$from_y	= $args->{from_y};
		$to_y	= $args->{to_y};
	}

	DEBUG "From X $from_x -> $to_x;From Y $from_y -> $to_y";
	WORDS:
	for my $x ($from_x .. $to_x){
		for my $y ($from_y .. $to_y){
			# TRACE $x-1, ', ', $y-1;
			next if not $self->{grid}->[ $x-1 ]->[ $y-1 ];
			next if $self->{grid}->[ $x-1 ]->[ $y-1 ] ne BLANK;
			last WORDS if not @{ $self->{inputs} };
			my $word = shift @{ $self->{inputs} };	
			DEBUG "     set $x $y = $word->{name}";
			$word->{clr} = $args->{clr} if $args->{clr};
			$word->{x} = $x-1;
			$word->{y} = $y-1;
			$word->{size} = int $self->{size_min_pc} + ( $self->{scale_f} * (1 + scalar @{ $self->{inputs} }));
			$word->{clr} = shift( @{$args->{clrs}}) if $args->{clrs};
			$self->{grid}->[ $x-1 ]->[ $y-1 ] = $word;
		}
	}
}


package HTML::TagCloud::Centred::Word;
use base 'HTML::TagCloud::Centred::Base';

sub _init {
	my $self = shift;
	$self->{html_esc_code} ||= sub {
		if (require CGI::Util){ return CGI::Util::escape(shift)}
		return shift;
	};
	die "No 'name'?" if not defined $self->{name};
}

sub html {
	my $self = shift;
	my $ctag = 'span';
	my $otag = $ctag;
	my $name = $self->{html_esc_code}->( $self->{name} );
	if (defined $self->{url}){
		$ctag = 'a';
		$otag = "a href='$self->{url}' title='$name'";
	}
	my $clr = defined($self->{clr})? 'color:'.$self->{clr} : '';
	return "<$otag style='$clr; font-size:$self->{size}%'>$name</$ctag>";
}

1;

=head1 SEE ALSO

L<HTML::TagCloud>.

=head1 AUTHOR AND COPYRIGHT

Copyright (C) Lee Goddard, 2010-2011. All Rights Reserved.

This distribution is made available under the same terms as Perl.


