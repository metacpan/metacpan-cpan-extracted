#
# $Id: Twitter.pm,v dfc28e2a169d 2017/03/06 20:06:58 gomor $
#
# client::twitter Brik
#
package Metabrik::Client::Twitter;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: dfc28e2a169d $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         connect => [ qw(consumer_key|OPTIONAL consumer_secret|OPTIONAL access_token|OPTIONAL access_token_secret|OPTIONAL) ],
         tweet => [ qw(message) ],
         account_settings => [ ],
         followers => [ ],
         following => [ ],
         follow => [ qw(username) ],
         unfollow => [ qw(username) ],
         disconnect => [ ],
         rate_limit_status => [ ],
      },
      attributes => {
         consumer_key => [ qw(string) ],
         consumer_secret => [ qw(string) ],
         access_token => [ qw(string) ],
         access_token_secret => [ qw(string) ],
         net_twitter => [ qw(object|INTERNAL) ],
      },
      require_modules => {
         'Net::Twitter' => [ ],
      },
   };
}

#
# REST API:
# https://dev.twitter.com/rest/public
#

sub connect {
   my $self = shift;
   my ($consumer_key, $consumer_secret, $access_token, $access_token_secret) = @_;

   # Return the handle if already connected.
   if (defined($self->net_twitter)) {
      return $self->net_twitter;
   }

   # Get API keys: authenticate and go to https://apps.twitter.com/app/new

   $consumer_key ||= $self->consumer_key;
   $consumer_secret ||= $self->consumer_secret;
   $access_token ||= $self->access_token;
   $access_token_secret ||= $self->access_token_secret;
   $self->brik_help_run_undef_arg('connect', $consumer_key) or return;
   $self->brik_help_run_undef_arg('connect', $consumer_secret) or return;
   $self->brik_help_run_undef_arg('connect', $access_token) or return;
   $self->brik_help_run_undef_arg('connect', $access_token_secret) or return;

   # Without that, we got:
   # "500 Can't connect to api.twitter.com:443 (Crypt-SSLeay can't verify hostnames)"
   #$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

   my $nt;
   eval {
      local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';
      $nt = Net::Twitter->new(
         traits => [qw/API::RESTv1_1/],
         consumer_key => $consumer_key,
         consumer_secret => $consumer_secret,
         access_token => $access_token,
         access_token_secret => $access_token_secret,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("connect: unable to connect [$@]");
   }
   elsif (! defined($nt)) {
      return $self->log->error("connect: unable to connect [unknown error]");
   }

   return $self->net_twitter($nt);
}

sub tweet {
   my $self = shift;
   my ($message) = @_;

   $self->brik_help_run_undef_arg('tweet', $message) or return;

   my $nt = $self->connect or return;

   my $r;
   eval {
      local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';
      $r = $nt->update($message);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("tweet: unable to tweet [$@]");
   }
   elsif (! defined($r)) {
      return $self->log->error("tweet: unable to tweet [unknown error]");
   }

   return $message;
}

sub account_settings {
   my $self = shift;

   my $nt = $self->connect or return;

   my $r;
   eval {
      local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';
      $r = $nt->account_settings;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("account_settings: unable to call method [$@]");
   }
   elsif (! defined($r)) {
      return $self->log->error("account_settings: unable to call method [unknown error]");
   }

   return $r;
}

sub followers {
   my $self = shift;

   my $nt = $self->connect or return;

   my @list = ();

   eval {
      my $r;
      my $previous_cursor;
      my $next_cursor = -1;
      while ($next_cursor) {
         $self->log->info("followers: iterating on users with next_cursor [$next_cursor]");

         local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';
         $r = $nt->followers({ cursor => $next_cursor });
         last if ! defined($r);
         $next_cursor = $r->{next_cursor};
         $r->{previous_cursor} = $previous_cursor || 0;
         $previous_cursor = $next_cursor;

         for my $user (@{$r->{users}}) {
            $self->log->verbose("followers: found user [".$user->{screen_name}."]");

            push @list, {
               name => $user->{name},
               screen_name => $user->{screen_name},
               description => $user->{description},
               location => $user->{location},
               following_count => $user->{friends_count},
               followers_count => $user->{followers_count},
               created => $user->{created_at},
               language => $user->{lang},
            };
         }
      }
   };
   if ($@) {
      chomp($@);

      if ($@ =~ m{Rate limit exceeded}i) {
         $self->log->warning("followers: rate limit exceeded, returning partial results");
         return \@list;
      }

      return $self->log->error("followers: unable to call method [$@]");
   }

   return \@list;
}

sub following {
   my $self = shift;

   my $nt = $self->connect or return;

   my @list = ();

   eval {
      my $r;
      my $cursor = -1;
      while ($cursor) {
         $self->log->info("following: iterating on users with cursor [$cursor]");

         local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';
         $r = $nt->friends({ cursor => $cursor });
         last if ! defined($r);
         $cursor = $r->{next_cursor};

         for my $user (@{$r->{users}}) {
            $self->log->verbose("following: found user [".$user->{screen_name}."]");

            push @list, {
               name => $user->{name},
               screen_name => $user->{screen_name},
               description => $user->{description},
               location => $user->{location},
               following_count => $user->{friends_count},
               followers_count => $user->{followers_count},
               created => $user->{created_at},
               language => $user->{lang},
            };
         }
      }
   };
   if ($@) {
      chomp($@);

      if ($@ =~ m{Rate limit exceeded}i) {
         $self->log->warning("following: rate limit exceeded, returning partial results");
         return \@list;
      }

      return $self->log->error("following: unable to call method [$@]");
   }

   return \@list;
}
sub follow {
   my $self = shift;
   my ($username) = @_;

   $self->brik_help_run_undef_arg('follow', $username) or return;

   my $nt = $self->connect or return;

   my $r;
   eval {
      local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';
      $r = $nt->follow($username);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("follow: unable to call method [$@]");
   }

   return $username;
}

sub unfollow {
   my $self = shift;
   my ($username) = @_;

   $self->brik_help_run_undef_arg('unfollow', $username) or return;

   my $nt = $self->connect or return;

   my $r;
   eval {
      local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';
      $r = $nt->unfollow($username);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("unfollow: unable to call method [$@]");
   }
   elsif (! defined($r)) {
      return $self->log->error("unfollow: unable to call method [unknown error]");
   }

   return $username;
}

sub disconnect {
   my $self = shift;

   $self->net_twitter(undef);

   return 1;
}

#
# https://dev.twitter.com/rest/public/rate-limits
#
sub rate_limit_status {
   my $self = shift;

   my $nt = $self->connect or return;

   my $r;
   eval {
      local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';
      $r = $nt->rate_limit_status;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("rate_limit_status: unable to call method [$@]");
   }
   elsif (! defined($r)) {
      return $self->log->error("rate_limit_status: unable to call method ".
         "[unknown error]");
   }

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Client::Twitter - client::twitter Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
