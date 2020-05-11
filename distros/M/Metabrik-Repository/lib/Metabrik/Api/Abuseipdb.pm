#
# $Id$
#
# api::abuseipdb Brik
#
package Metabrik::Api::Abuseipdb;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         api_key => [ qw(key) ],
      },
      commands => {
         get_categories => [ ],
         check => [ qw(ip days|OPTIONAL) ],
         check_from_hostname => [ qw(hostname days|OPTIONAL) ],
         report => [ qw(ip category comment|OPTIONAL) ],
      },
   };
}

#
# https://www.abuseipdb.com/categories
#
sub get_categories {
   my $self = shift;

   return {
      3 => {
        title => 'Fraud Orders',
        description => 'Fraudulent orders.',
      },
      4 => {
        title => 'DDoS Attack',
        description => 'Participating in distributed denial-of-service (usually part of botnet).'
      },
      9 => {
        title => 'Open Proxy',
        description => 'Open proxy, open relay, or Tor exit node.',
      },
      10 => {
        title => 'Web Spam',
        description => 'Comment/forum spam, HTTP referer spam, or other CMS spam.',
      },
      11 => {
        title => 'Email Spam',
        description => 'Spam email content, infected attachments, phishing emails, and spoofed senders (typically via exploited host or SMTP server abuse). Note: Limit comments to only relevent information (instead of log dumps) and be sure to remove PII if you want to remain anonymous.',
      },
      14 => {
        title => 'Port Scan',
        description => 'Scanning for open ports and vulnerable services.',
      },
      18 => {
        title => 'Brute-Force',
        description => 'Credential brute-force attacks on webpage logins and services like SSH, FTP, SIP, SMTP, RDP, etc. This category is seperate from DDoS attacks.',
      },
      19 => {
        title => 'Bad Web Bot',
        description => 'Webpage scraping (for email addresses, content, etc) and crawlers that do not honor robots.txt. Excessive requests and user agent spoofing can also be reported here.',
      },
      20 => {
        title => 'Exploited Host',
        description => 'Host is likely infected with malware and being used for other attacks or to host malicious content. The host owner may not be aware of the compromise. This category is often used in combination with other attack categories.',
      },
      21 => {
        title => 'Web App Attack',
        description => 'Attempts to probe for or exploit installed web applications such as a CMS like WordPress/Drupal, e-commerce solutions, forum software, phpMyAdmin and various other software plugins/solutions.',
      },
      22 => {
        title => 'SSH',
        description => 'Secure Shell (SSH) abuse. Use this category in combination with more specific categories.',
      },
      23 => {
        title => 'IoT Targeted',
        description => 'Abuse was targeted at an "Internet of Things" type device. Include information about what type of device was targeted in the comments.',
      },
   };
}

#
# https://www.abuseipdb.com/api.html
#
sub check {
   my $self = shift;
   my ($ip, $days) = @_;

   $days ||= 30;
   my $api_key = $self->api_key;
   $self->brik_help_set_undef_arg('api_key', $api_key) or return;
   $self->brik_help_run_undef_arg('check', $ip) or return;

   #
   # https://www.abuseipdb.com/check/[IP]/json?key=[API_KEY]&days=[DAYS]
   #
   $self->get(
      'https://www.abuseipdb.com/check/'.$ip.'/json?key='.$api_key.'&days='.$days
   ) or return;

   my $r = $self->content('json');
   # We always want an ARRAY to be returned, we convert here if that's not the case.
   if (ref($r) ne 'ARRAY') {
      $r = [ $r ];
   }

   my $categories = $self->get_categories or return;

   for my $this (@$r) {
      my @new_categories = ();
      for my $c (@{$this->{category}}) {
         push @new_categories, $categories->{$c}{title};
      }
      $this->{category} = \@new_categories;
   }

   return $r;
}

sub check_from_hostname {
   my $self = shift;
   my ($hostname, $days) = @_;

   $days ||= 30;
   my $api_key = $self->api_key;
   $self->brik_help_set_undef_arg('api_key', $api_key) or return;
   $self->brik_help_run_undef_arg('check_from_hostname', $hostname) or return;

   my $cd = Metabrik::Client::Dns->new_from_brik_init($self) or return;
   my $a = $cd->a_lookup($hostname) or return;

   my %list = ();
   for (@$a) {
      $list{$_} = $self->check($_);
   }

   return \%list;
}

#
# https://www.abuseipdb.com/api.html
#
# run api::abuseipdb report 127.0.0.1 21,22,23
#
sub report {
   my $self = shift;
   my ($ip, $category, $comment) = @_;

   $comment ||= '';
   my $api_key = $self->api_key;
   $self->brik_help_set_undef_arg('api_key', $api_key) or return;
   $self->brik_help_run_undef_arg('report', $ip) or return;
   $self->brik_help_run_undef_arg('report', $category) or return;

   #
   # https://www.abuseipdb.com/report/json?key=[API_KEY]&category=[CATEGORIES]&comment=[COMMENT]&ip=[IP]
   #
   $self->get(
      'https://www.abuseipdb.com/report/json?key='.$api_key.'&category='.$category.
      '&comment='.$comment.'&ip='.$ip
   ) or return;

   return $self->content('json');
}

1;

__END__

=head1 NAME

Metabrik::Api::Abuseipdb - api::abuseipdb Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
