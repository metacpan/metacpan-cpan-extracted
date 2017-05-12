package HTML::PageIndex;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use strict;

require Exporter;

@ISA=qw(Exporter);
@EXPORT=qw();
@EXPORT_OK=qw();

$VERSION = '0.3';

sub new {
	my ($class) = @_; 
	my ($self) = {};
	bless ($self, $class);
	return $self;
}

################################################################################
# Public methods

sub makeindex {
	my ($self, $total, $current, $Base, $Arg, $np) =@_;

	if (!$Base) { print __PACKAGE__.": Base URL not provided"; return;}

	$self->{'BASE'} = $Base;
	$self->{'ARG'} = $Arg if $Arg;

	if ($total <= 1) {
		return "";
	}
	
	# Handle defaults and guard against absurd input values
	
	$current = 1 if $current < 1;
	$current = $total if $current > $total;
	$np=0 if !$np;

	return $self->_text_numbers($total, $current,$np);
}



################################################################################
# Private methods

sub _text_numbers {
	my ($self, $total, $current,$np) = @_;

	my ($prev) = $current - 1;
	my ($next) = $current + 1;

	my ($out);

	# Display [Prev] unless on first page

	if ($current > 1) {
		$out .= "<a href=\"" .
			$self->_url($prev) .
			"\">&nbsp;[Prev]&nbsp;</a>\n";
	} else {
		if ($np > 0) {
			$out .= "&nbsp[Prev]&nbsp\n";
		}
	}

	# Display 1 2 3 etc...

	my ($i);

	for ($i = 1; $i<=$total; $i++) {
		if ($i == $current) {
			$out .= "<b>&nbsp;$i</b>&nbsp;\n";
		} else {
			$out .= "<a href=\"" .
				$self->_url($i) .
				"\">&nbsp;$i&nbsp;</a>\n";
		}
	}

	# Display [Next] unless on last page

	if ($current < $total) {
		$out .= "<a href=\"" .
			$self->_url($next) .
			"\">&nbsp;[Next]&nbsp;</a>\n";
	} else {
		if ($np > 0) {
			$out .= "&nbsp[Next]&nbsp\n";
		}
	}

	return $out;
}

sub _url {
	my ($self, $tagValue) = @_;

	my ($url) = $self->{'BASE'};
	my ($arg) = $self->{'ARG'};

	if ($arg) {

		$url =~ s/\&$arg=[^&]*//g;
		$url =~ s/\?$arg=[^&]*&/?/g;
		$url =~ s/\?$arg=[^&]*$//;

		if ($url =~ /\?/) {
			$url .= "&$arg=$tagValue";
		} else {
			$url .= "?$arg=$tagValue";
		}
	}

	return $url;
}


1; # wheeee;

__END__


=head1 NAME

HTML::PageIndex - Class to create HTML page index objects.

=head1 SYNOPSIS

 use HTML::PageIndex;

 $foo = new HTML::PageIndex;

 $zog = $foo->makeindex([total pages],[current page],[base url],[url arguement],[show prev/next]);

 print $zog;

=head1 DESCRIPTION

Will return an object which will display a dynamic index of html pages. It would look like:

	[Prev] 1 2 3 4 5 6 [Next]

=item makeindex([total pages],[current page],[base url],[url arguement],[show prev/next]);

This is currently the only public method. The args are as follows:

	[total pages] - How many total pages are there. 

	[current page] - What the current page is. It is expected that the using script
			 would generate this.

	[base url] - The base url to link to.

	[url arguement] - May be "", but if it isn't it will build a 
			  URL with ?[URL arguement]=[page number]

	[show prev/next] - Default is 0. If 0 it will not show [Prev] if you are on the
			first page, or [Next] if you are on the last page. If 1, it will 
			show [Prev] and [Next] as text.


=head1 INSTALLATION

You install HTML::PageIndex, as you would install any perl module library,
by running these commands:

   perl Makefile.PL
   make
   make install
   make clean


=head1 BUGS

None knows at time of writing.

=head1 AVAILABILITY

The latest version of HTML::PageIndex should always be available from:

    $CPAN/modules/by-authors/id/K/KM/KMELTZ/

Visit <URL:http://www.perl.com/CPAN/> to find a CPAN
site near you.

Or, from <URL:http://www.perlguy.com/perl>.

=head1 AUTHOR INFORMATION

Copyright 2002, Kevin Meltzer. This software is releases with no warranty, and
under the terms of Perl itself.

Address bug reports and comments to:
perlguy@perlguy.com

The author makes no warranties, promises, or gaurentees of this software. As with all
software, use at your own risk.

=cut
