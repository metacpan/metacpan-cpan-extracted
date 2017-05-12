=head1 NAME

MKDoc::Core::Plugin::Not_Found - 404 Not Found plugin.

=head1 SUMMARY

This plugin should be executed last. It displays a custom '404 Not Found' page.

=cut
package MKDoc::Core::Plugin::Not_Found;
use base qw /MKDoc::Core::Plugin/;
use strict;
use warnings;


sub activate { 1 }


sub HTTP_Status { '404 Not Found' };


1;


__END__


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  L<Petal> TAL for perl
  MKDoc: http://www.mkdoc.com/

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk
