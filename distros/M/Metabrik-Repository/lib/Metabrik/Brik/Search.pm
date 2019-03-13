#
# $Id: Search.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# brik::search Brik
#
package Metabrik::Brik::Search;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      commands => {
         all => [ ],
         string => [ qw(string) ],
         tag => [ qw(Tag) ],
         not_tag => [ qw(Tag) ],
         used => [ ],
         not_used => [ ],
         show_require_modules => [ ],
         command => [ qw(Command) ],
         category => [ qw(Category) ],
         list_categories => [ ],
      },
   };
}

sub all {
   my $self = shift;

   if (! defined($self->context)) {
      return $self->log->error("all: no core::context Brik");
   }

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   my $count = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      next unless $context->used->{$brik}->can('brik_tags');
      my $tags = $context->used->{$brik}->brik_tags;
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $count++;
      $total++;
   }
   $self->log->info("Count: $count");

   $count = 0;
   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      next unless $context->not_used->{$brik}->can('brik_tags');
      my $tags = $context->not_used->{$brik}->brik_tags;
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $count++;
      $total++;
   }
   $self->log->info("Count: $count");

   return $total;
}

sub string {
   my $self = shift;
   my ($string) = @_;

   if (! defined($self->context)) {
      return $self->log->error("string: no core::context Brik");
   }

   $self->brik_help_run_undef_arg('string', $string) or return;

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      next unless $brik =~ /$string/;
      next unless $context->used->{$brik}->can('brik_tags');
      my $tags = $context->used->{$brik}->brik_tags;
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $total++;
   }

   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      next unless $brik =~ /$string/;
      next unless $context->not_used->{$brik}->can('brik_tags');
      my $tags = $context->not_used->{$brik}->brik_tags;
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $total++;
   }

   return $total;
}

sub tag {
   my $self = shift;
   my ($tag) = @_;

   if (! defined($self->context)) {
      return $self->log->error("tag: no core::context Brik");
   }

   $self->brik_help_run_undef_arg('tag', $tag) or return;

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      next unless $context->used->{$brik}->can('brik_tags');
      my $tags = $context->used->{$brik}->brik_tags;
      push @$tags, 'used';
      for my $this (@$tags) {
         next unless $this eq $tag;
         $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
         $total++;
         last;
      }
   }

   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      next unless $context->not_used->{$brik}->can('brik_tags');
      my $tags = $context->not_used->{$brik}->brik_tags;
      push @$tags, 'not_used';
      for my $this (@$tags) {
         next unless $this eq $tag;
         $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
         $total++;
         last;
      }
   }


   return $total;
}

sub not_tag {
   my $self = shift;
   my ($tag) = @_;

   if (! defined($self->context)) {
      return $self->log->error("not_tag: no core::context Brik");
   }

   $self->brik_help_run_undef_arg('not_tag', $tag) or return;

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      next unless $context->used->{$brik}->can('brik_tags');
      my $tags = $context->used->{$brik}->brik_tags;
      push @$tags, 'used';
      for my $this (@$tags) {
         next if $this eq $tag;
         $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
         $total++;
         last;
      }
   }

   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      next unless $context->not_used->{$brik}->can('brik_tags');
      my $tags = $context->not_used->{$brik}->brik_tags;
      push @$tags, 'not_used';
      for my $this (@$tags) {
         next if $this eq $tag;
         $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
         $total++;
         last;
      }
   }

   return $total;
}

sub used {
   my $self = shift;

   return $self->tag('used');
}

sub not_used {
   my $self = shift;

   return $self->not_tag('used');
}

sub show_require_modules {
   my $self = shift;

   if (! defined($self->context)) {
      return $self->log->error("show_require_modules: no core::context Brik");
   }

   my $context = $self->context;
   my $available = $context->available;

   # Don't show require for Core modules
   my $core = {
      'core::context',
      'core::log',
      'core::shell',
      'core::global',
   };

   my %require_modules = ();
   for my $brik (keys %$available) {
      next if (exists($core->{$brik}));
      if ($available->{$brik}->can('brik_properties')) {
         my $modules = $available->{$brik}->brik_properties->{require_modules};
         for my $module (keys %$modules) {
            next if $module =~ /^Metabrik/;
            $require_modules{$module} = $brik;
         }
      }
   }

   return [ sort { $a cmp $b } keys %require_modules ];
}

sub command {
   my $self = shift;
   my ($command) = @_;

   if (! defined($self->context)) {
      return $self->log->error("command: no core::context Brik");
   }

   $self->brik_help_run_undef_arg('command', $command) or return;

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      if (exists($context->used->{$brik}->brik_properties->{commands})) {
         next unless $context->used->{$brik}->can('brik_tags');
         my $tags = $context->used->{$brik}->brik_tags;
         push @$tags, 'used';
         for my $key (keys %{$context->used->{$brik}->brik_properties->{commands}}) {
            if ($key =~ /$command/i) {
               $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
               $total++;
            }
         }
      }
   }

   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      if (exists($context->not_used->{$brik}->brik_properties->{commands})) {
         next unless $context->not_used->{$brik}->can('brik_tags');
         my $tags = $context->not_used->{$brik}->brik_tags;
         push @$tags, 'not_used';
         for my $key (keys %{$context->not_used->{$brik}->brik_properties->{commands}}) {
            if ($key =~ /$command/i) {
               $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
               $total++;
            }
         }
      }
   }

   return $total;
}

sub category {
   my $self = shift;
   my ($category) = @_;

   if (! defined($self->context)) {
      return $self->log->error("category: no core::context Brik");
   }

   $self->brik_help_run_undef_arg('category', $category) or return;

   my $context = $self->context;
   my $status = $context->status;

   my $total = 0;
   $self->log->info("Used:");
   for my $brik (@{$status->{used}}) {
      next unless defined($context->used->{$brik});
      next unless $context->used->{$brik}->can('brik_category');
      my $brik_category = $context->used->{$brik}->brik_category;
      next unless $brik_category eq $category;
      next unless $context->used->{$brik}->can('brik_tags');
      my $tags = $context->used->{$brik}->brik_tags;
      push @$tags, 'used';
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $total++;
   }

   $self->log->info("Not used:");
   for my $brik (@{$status->{not_used}}) {
      next unless defined($context->not_used->{$brik});
      next unless $context->not_used->{$brik}->can('brik_category');
      my $brik_category = $context->not_used->{$brik}->brik_category;
      next unless $brik_category eq $category;
      next unless $context->not_used->{$brik}->can('brik_tags');
      my $tags = $context->not_used->{$brik}->brik_tags;
      push @$tags, 'not_used';
      $self->log->info(sprintf("   %-20s [%s]", $brik, join(', ', @$tags)));
      $total++;
   }

   return $total;
}

sub list_categories {
   my $self = shift;

   if (! defined($self->context)) {
      return $self->log->error("list_categories: no core::context Brik");
   }

   my $con = $self->context;
   my $available = $con->find_available;

   my @categories = ();
   for my $k (keys %$available) {
      my @t = split(/::/, $k);
      if (@t == 2) {  # Category and Name
         push @categories, $t[0];
      }
      elsif (@t == 3) {  # Repository, Category and Name
         push @categories, $t[1];
      }
      else {  # Error
         $self->log->warning("list_categories: Brik [$k] has no Category?");
      } 
   }

   my %uniq = map { $_ => 1 } @categories;
   return [ sort { $a cmp $b } keys %uniq ];
}

1;

__END__

=head1 NAME

Metabrik::Brik::Search - brik::search Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
