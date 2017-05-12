#
# $Id: Google.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# www::google Brik
#
package Metabrik::Www::Google;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         language => [ qw(fr|uk|de|ch) ],
         page => [ qw(number) ],
         filter => [ qw(0|1) ],
      },
      attributes_default => {
         language => 'fr',
         page => 1,
         do_javascript => 1,
         filter => 0,
      },
      commands => {
         search => [ qw(keywords) ],
      },
      require_modules => {
         'WWW::Mechanize::PhantomJS' => [ ],
         'Metabrik::String::Html' => [ ],
         'Metabrik::String::Uri' => [ ],
      },
   };
}

# Search last 24 hours: &tbs=qdr:d

# my $url = 'http://www.google.fr/#q=gomor'
# set client::www do_javascript 1
# run client::www get $url
# my $content = $RUN->{content}
# run client::www parse $content
# my $body = $RUN->content

sub search {
   my $self = shift;
   my @args = @_;

   if (@args <= 0) {
      $self->brik_help_run_undef_arg('search', undef) or return;
   }

   my $language = $self->language;
   my $page = $self->page;
   my $filter = $self->filter;

   my $keywords = join(' ', @args);

   my $si = Metabrik::String::Uri->new_from_brik_init($self) or return;
   $keywords = $si->encode($keywords) or return;

   if ($language eq 'fr' || $language eq 'uk' || $language eq 'de' || $language eq 'ch') {
   }
   else {
      return $self->log->error("search: unsupported language [$language]");
   }

   my $cache = {
      fr => 'en cache',
      de => 'im cache',
      ch => 'im cache',
      uk => 'cached',
   };

   # Google UK is google.co.uk
   my $url = 'http://www.google.'.$language.'/#q=';
   if ($language eq 'uk') {
      $url = 'http://www.google.co.uk/#q=';
   }

   my $start = ($page - 1);
   if ($start < 0) {
      $start = 0;
   }
   $start *= 10;
   my $search = $url.$keywords.'&start='.$start.'&filter='.$filter;

   $self->log->verbose("search: [$search]");

   my $get = $self->get($search) or return;
   if ($get->{code} == 200) {
      my $tree = $self->parse($get->{content}) or return;
      my $body = $tree->content;

      my $r = $self->_traverse($body->[1]);

      # We merge cache stuff within results
      my @merged = ();
      my $this = {};
      for (@$r) {
         $self->debug && $self->log->debug("url: [".$_->{url}."]");
         $self->debug && $self->log->debug("title: [".$_->{title}."]");

         if ($_->{title} =~ m/^@{[$cache->{$language}]}/i) {
            $self->debug && $self->log->debug("cache: [".$_->{url}."]");
            $merged[-1]->{cache_url} = $_->{url};
         }
         else {
            $this->{url} = $_->{url};
            $this->{title} = $_->{title};
            push @merged, $this;
            $this = {};
         }
      }

      return \@merged;
   }

   return $self->log->error("search: unhandled error");
}

sub _traverse {
   my $self = shift;
   my ($node) = @_;

   my @results = ();

   my @list = $node->content_list;
   for my $this (@list) {
      if (ref($this) eq 'HTML::Element') {
         my $tag = $this->tag;
         if ($tag eq 'a') {
            my $h = $self->_href_to_hash($this);
            if ($h && keys %$h > 0) {
               #print Data::Dumper::Dumper($h)."\n";
               push @results, $h;
            }
            next;
         }

         # Do it recursively
         my $new = $self->_traverse($this);
         push @results, @$new;
      }
   }

   return \@results;
}

sub _href_to_hash {
   my $self = shift;
   my ($element) = @_;

   # /url?q=http://www.justanswer.com/military-law/5ps6l-read-gomor-submitted-rebuttal-go-will.html&sa=U&ved=0ahUKEwi_hP_LgJTPAhVEWRoKHdlaDKQQFghHMAk&usg=AFQjCNGs50hYJHY-aJ6yxYeiP0p5Qd52-A
   my $is_incomplete = 0;
   my $title = '';
   my $url = '';
   my $href = $element->{href};
   if ($href =~ m{^/url\?q=}) { # && $href !~ m{/url\?q=http://webcache.googleusercontent.com/}) {
      $url = $href;
      $url =~ s{^/url\?q=}{};
      $url =~ s{&sa=.+?$}{};
      my @list = @{$element->content};
      for (@list) {
         if (ref($_) eq 'HTML::Element') {
            if (defined($_->content)) {
               my $txt = join(' ', @{$_->content});
               $title .= $txt;
            }
            else {
               return {};
            }
         }
         else {
            $title .= $_;
         }
      }
   }
   else {
      return;
   }

   my $sh = Metabrik::String::Html->new_from_brik_init($self) or return;
   my $si = Metabrik::String::Uri->new_from_brik_init($self) or return;

   $title = $sh->decode($title);
   $url = $si->decode($url);

   return {
      url => $url,
      title => $title,
   };
}

1;

__END__

=head1 NAME

Metabrik::Www::Google - www::google Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
