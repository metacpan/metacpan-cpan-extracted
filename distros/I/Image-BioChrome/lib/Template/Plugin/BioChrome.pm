#============================================================================
#
# Template::Plugin::BioChrome
#
# DESCRIPTION
#  A Template Toolkit Plugin to provide access to the Image::BioChrome module
#
# AUTHOR
#  Simon Matthews <sam@tt2.org>
#
# COPYRIGHT
#  Copyright (C) 2003 Simon Matthews.  All Rights Reserved
#
#  This module is free software; you can redistribute it and/or modify
#  it under the same terms as Perl itself.
#
# REVISION
#   $Id: BioChrome.pm,v 1.5 2003/12/31 11:32:44 simon Exp $
#
#============================================================================

package Template::Plugin::BioChrome;

use strict;
use Template::Exception;
use base qw(Image::BioChrome Template::Plugin);
use Template::Plugin;
use Image::BioChrome;

use vars qw($VERSION $MOD);

$MOD = 'Template::Plugin::BioChrome';

$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

sub new {
	my $class = shift;
	my $context = shift;

	my $bio;
	
	eval {
		$bio = $class->SUPER::new(@_);
	};

	if ($@) {
		die (Template::Exception->new('biochrome', $@));
	}

	# Image::BioChrome->new(@_,1);
	return $bio;
}

sub write_file {
	my $self = shift;

	eval {
		$self->SUPER::write_file(@_);
	};

	if ($@) {
		die (Template::Exception->new('biochrome', $@));
	}
}

sub read_file {
	my $self = shift;

	eval {
		$self->SUPER::read_file(@_);
	};

	if ($@) {
		die (Template::Exception->new('biochrome', $@));
	}
}


1;


=head1 NAME

Template::Plugin::BioChrome - Template Toolkit Plugin for Image::BioChrome 

=head1 SYNOPSIS

[% USE bc = BioChrome("input.gif") %]

[% bc.alphas("ffffff_ff0000_000000_cccccc") %]

[% bc.write_file("output.gif") %]

=head1 DESCRIPTION

This Template Toolkit plugin modules provides a simple wrapper for Image::BioChrome.   It allows you to integrate the production of image files into your templates.  For full documentation you should look in the examples directory or the manual pages for Image::BioChrome.

=head1 AUTHOR

Simon Matthews E<lt>sam@tt2.orgE<gt>

=head1 REVISION

$Revision: 1.5 $

=head1 COPYRIGHT 

Copyright (C) 2003 Simon Matthews.  All Rights Reserved.

This module is free software; you can distribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

See L<Image::BioChrome> for further information on using BioChrome.

=cut
