=head1 NAME

MKDoc::Core::Init::Resources - Initializes Resources base directories.

=cut
package MKDoc::Core::Init::Resources;
use warnings;
use strict;
use Petal;


sub init
{
    $::MKD_RESOURCES_DIR = [
        map { -d $_ ? $_ : () }
          ( $ENV{SITE_DIR}  . '/resources',
            $ENV{MKDOC_DIR} . '/resources',
            (map { "$_/MKDoc/resources" } ) )
    ];
}


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
