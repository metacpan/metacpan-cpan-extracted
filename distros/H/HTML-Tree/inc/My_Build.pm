#---------------------------------------------------------------------
package inc::My_Build;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 31 May 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Customize Module::Build for HTML-Tree
#---------------------------------------------------------------------

use 5.008;
use strict;
use Module::Build ();

our @ISA = ('Module::Build');

#=====================================================================

sub prereq_failures
{
  my $self = shift @_;

  my $out = $self->SUPER::prereq_failures(@_);

  return $out unless $out and $out->{recommends};

  my @missing = sort keys %{ $out->{recommends} };

  my %about = (
    'HTML::FormatText' => "HTML::Element's\n" .
    '   "format" method, which converts HTML to formatted plain text.',

    'LWP::UserAgent'   => "HTML::TreeBuilder's\n" .
    '   "new_from_url" method, which fetches a document given its URL.',
  );

  for my $module (@missing) {
      $out->{recommends}{$missing[-1]}{message} .=
        "\n\n   $module is only required if you want to use $about{$module}"
            if $about{$module};
  }

  $out->{recommends}{$missing[-1]}{message} .= sprintf
     "\n\n   If you install %s later, you do NOT need to reinstall HTML-Tree.",
     (@missing == 1) ? 'this module' : 'these modules';

  return $out;
} # end prereq_failures

#=====================================================================
# Package Return Value:

1;
