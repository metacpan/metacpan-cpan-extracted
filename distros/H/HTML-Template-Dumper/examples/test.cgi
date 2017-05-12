#!/usr/local/bin/perl -T
# 
# Author:  Timm Murray <tmurray@agronomy.org>
# Name:  test 
# Description:  Demonstates the use of a test template
#

=head1 COPYRIGHT

Copyright 2003, American Society of Agronomy. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software 
Foundation; either version 2, or (at your option) any later version, or

b) the "Artistic License" which comes with Perl.

=cut


use strict;
use warnings;

use constant DEBUG => 1;


{
	my @FIELDS = qw( foo );
	sub set_params 
	{
		my $q = shift;
		my %params = map { $_ => $q->param($_) || 0 } @FIELDS;
		return \%params;
	}
}

sub get_template
{
	my $template_data;
	while(my $line = <DATA>) { $template_data .= $line }

	my $tmpl;
	if(DEBUG) {
		use HTML::Template::Dumper;
		$tmpl = HTML::Template::Dumper->new(
			scalarref => \$template_data, 
		);
	}
	else {
		use HTML::Template;
		$tmpl = HTML::Template->new(
			scalarref => \$template_data, 
		);
	}

	return $tmpl;
}


{
	use CGI;
	my $q = CGI->new();
	my $params = set_params($q);

	my $tmpl = get_template();
	$tmpl->param( bar => $params->{foo} + 1 );

	print $q->header('text/html');
	$tmpl->output( print_to => *STDOUT );
}


__DATA__

<html>
<head>
<title>Test Page</title>
</head>
<body bgcolor="#FFFFFF">
<pre>
	<TMPL_VAR bar>
</pre>
</body>
</html>

