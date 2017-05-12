package Goo::CompressWhitespace;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename: 	Goo::CompressWhitespace.pm
# Description: 	Remove whitespace for web transmission
#
# Date 			Change
# -----------------------------------------------------------------------------
# 02/02/2005 	Auto generated file
# 02/02/2005 	Needed to reduce filesizes for more speed!
#				Ideally all pages should be less than 1300 MTU (allowing for 
#				HTTP headers).
#
###############################################################################

use strict;


###############################################################################
#
# compress_html - remove excess white space in html
#
###############################################################################

sub compress_html {
	
	my ($string_ref) = @_;

	# strip whitespace but preserve newlines
	# to avoid Javascript bugs
	$$string_ref =~ s{([\s\n]+)}{($1 =~ /\n/) ? "\n" : " "}eg;

	# remove spaces around = signs
	$$string_ref =~ s/\s+\=\s+/=/g;
					
	# strip single spaces between tags
	$$string_ref =~ s/\>\s\</\>\</g;
	
	#return $string_ref;

}

1;


__END__

=head1 NAME

Goo::CompressWhitespace - Remove excess whitespace

=head1 SYNOPSIS

use Goo::CompressWhitespace;

=head1 DESCRIPTION


=head1 METHODS

=over

=item compress_html

remove excess whitespace in HTML and Javascript to reduce overall byte size


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

