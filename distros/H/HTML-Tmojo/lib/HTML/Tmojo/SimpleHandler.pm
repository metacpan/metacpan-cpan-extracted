###########################################################################
# Copyright 2004 Lab-01 LLC <http://lab-01.com/>
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Tmojo(tm) is a trademark of Lab-01 LLC.
###########################################################################

package HTML::Tmojo::SimpleHandler;

=head1 NAME

HTML::Tmojo::SimpleHandler

=head1 SYNOPSIS

  # IN YOUR APACHE CONFIG
  DirectoryIndex index.tmojo index.html

  <LocationMatch "\.tmojo$">
    SetHandler perl-script
    PerlHandler HTML::Tmojo::SimpleHandler
    PerlSetEnv TMOJO_CACHE_DIR /tmp/mojo
  </LocationMatch>

=head1 ABSTRACT

The SimpleHandler can be used to quickly deploy
Tmojo to your apache/mod_perl environment. Simply
adding the above code to your httpd.conf will allow
Apache to serve any .tmojo documents in your htdocs
as Tmojo templates.
  
=head1 OPTIONS

The SimpleHandler obeys the following environment
variables:

=over

=item TMOJO_TEMPLATE_DIR

SimpleHandler will look for its templates in this directory.
If not specified, SimpleHandler will look for its templates
in the apache document root.

=item TMOJO_CACHE_DIR

This required setting tells SimpleHandler where to
store compiled Tmojo templates. The directory must
be writable by apache.

=item TMOJO_DEFAULT_CONTAINER

If specified, SimpleHandler will use this path to determine
the container template on each requested template. This
option will override any $TMOJO_CONTAINER specified within
templates.

Normally, you would use this option to create a directory
level containment mechanism. For instance, by setting
TMOJO_DEFAULT_CONTAINER to C<container.tmojo^>, you can
make the SimpleHandler use the deepest template named
F<container.tmojo> as the container for the requested
template.

=back

=head1 AUTHOR

Will Conant <will@willconant.com>

=cut


use strict;

use Apache::Constants qw(OK NOT_FOUND);

use HTML::Tmojo;
use HTML::Tmojo::HttpArgParser;

sub handler {
	my $apache_request = shift;
	
	# DECIDE ON OUR TEMPLATE DIR
	my $template_dir = $ENV{TMOJO_TEMPLATE_DIR};
	if ($template_dir eq '') {
		$template_dir = $ENV{DOCUMENT_ROOT};
	}
	
	# PRIME OUR COOL OBJECTS
	my $arg_parser = HTML::Tmojo::HttpArgParser->new();
	my $tmojo = HTML::Tmojo->new(template_dir => $template_dir);
	
	# DECIDE ON THE DEFAULT CONTAINER
	my $default_container = $ENV{TMOJO_DEFAULT_CONTAINER};
	
	# GET THE ARGUMENTS
	my %args = $arg_parser->args();
	
	# GET THE TMOJO TEMPLATE PATH
	my $template_id = $ENV{REQUEST_URI};
	$template_id =~ s/\?.*$//;
	
	if (substr($template_id, -1) eq '/') {
		if ($ENV{TMOJO_DIR_INDEX} ne '') {
			$template_id .= $ENV{TMOJO_DIR_INDEX};
		}
		elsif ($ENV{SCRIPT_FILENAME} =~ m/\/([^\/]+)$/) {
			$template_id .= $1;
		}
	}
	
	# CHECK TO SEE IF THE TEMPLATE IS THERE
	unless ($tmojo->template_exists($template_id)) {
		return NOT_FOUND;
	}
	
	# OUTPUT THE APACHE HEADER
	$apache_request->send_http_header('text/html; charset=utf8');
	
	# CALL THE TMOJO TEMPLATE
	if ($default_container ne '') {
		print $tmojo->call_with_container($template_id, $default_container, %args);
	} else {
		print $tmojo->call($template_id, %args);
	}
	
	# AND WE'RE DONE
	return OK;
}

1;
