package Kwiki::ReferrerLog;
use strict;
use warnings;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
use Storable qw(lock_store lock_retrieve);
use POSIX qw(strftime);
our $VERSION = '0.05';

our $DAY_SECONDS = 86400;

const class_id    => 'referrerlog';
const class_title => 'ReferrerLog Display';
const config_file => 'referrerlog.yaml';

const css_file             => 'referrerlog.css';
const referrerlog_template => 'referrerlog_content.html';

const log_file    => 'referrers.log';

sub init {
    super;
    $self->hub->add_post_process($self->class_id, 'log_referrer');
}

sub register {
    my $registry = shift;
    $registry->add(preload => 'referrerlog');

    $registry->add(action => 'show_referrerlog');
    $registry->add(toolbar => 'referrerlog_button',
                   template => 'referrerlog_button.html');
}

sub log_referrer {
    my $ref = $ENV{HTTP_REFERER};
    return unless $ref;

    my $excl_subd = $self->config->exclude_subdomains;
    my @test = ();
    grep {
        if ( $excl_subd ) { return if $ref =~ m!^http://[a-zA-Z]*\.*$_!; }
        else { return if $ref =~ m!^http://$_! ; }
    } @{$self->config->exclude_referrers} if ref $self->config->exclude_referrers;

    my $log = $self->load_log;
    $log->{$ref}->[0]++ ;      # referrer count
    $log->{$ref}->[1] = time;  # time
    $log->{$ref}->[2] = $self->pages->current->uri;  # where did it go?

    $self->delete_old_logs($log);
    $self->store_log($log);
}


sub show_referrerlog {
    my $reflength = $self->config->truncate_referrers;

    my $log = $self->load_log;
    my $refs = [];
    foreach (keys %$log) {
      push @$refs, {'visitcount' => $log->{$_}->[0], 'time'   => $log->{$_}->[1],
                    'uri'    => $log->{$_}->[2],     'refuri' => $_};
    }

    # puts the latest referrers on the top of the list
    @$refs = sort { $a->{'time'} <=> $b->{'time'} } @$refs;

    $self->render_screen(
        screen_title => $self->class_title,
        'log' => $refs,
    );
}


sub file_path {
    join '/', $self->plugin_directory, $self->log_file;
}


sub load_log {
    lock_retrieve($self->file_path) if -f $self->file_path;
}


sub store_log {
    lock_store shift, $self->file_path;
}


sub delete_old_logs {
    my $log = shift;

    if ( $self->config->keep_days > 0 ) {
      my $now = time;
      my @to_delete = ();
      foreach (keys %$log) {
          push @to_delete, $_ if ($now - $log->{$_}->[1]) > $self->config->keep_days * $DAY_SECONDS;
      }
      delete $log->{$_} for @to_delete
    }
}


sub date_fmt {
    strftime($self->config->date_format, localtime(shift))
}

1;
__DATA__
=head1 NAME

Kwiki::ReferrerLog - Kwiki ReferrerLog Class

=head1 DESCRIPTION

This module logs all referers coming from external sites to your Kwiki wiki,
and displays them in a convenient, stylable table. That's all. It's very basic
but you can easily redefine/change most of the functionality by overriding the
appropriate methods (see below).

=head1 OPTIONS

The following configurationoptions can be overriden in your config.yaml file:

=over 4

=item C<keep_days>

 This determines after which number of days, a log entry gets
deleted from the store, if there weren't any requests coming in from that
URL. Don't set this value too high. (default is: 2)

=item C<date_format>

 The date format that is used in the display of logged referrers.
This is directly passed to the L<strftime> function of the L<POSIX> package,
so don't hate me, if you specify a wrong pattern (default is: %d.%m.%Y %H:%M)

=item C<exclude_referrers>

 This is a list of domains, that won't be logged as
referrers. You should set this at least to the domain your Kwiki installation is
running on, so the clicking around on your wiki won't result in a flood of
referrers showing up in you referrer log.
The list must be in a YAML anonymous array format, that looks like this:

=begin text

exclude_referrers:
- example.com
- site.org

=end text

=item C<exclude_subdomains>

This boolean value specifies (0 is false, everything else
is true), is subdomains of the configured L<exclude_referrers> domains
should be exluded too, or if they should be logged.
Example: If L<exclude_referrers> is set to exclude the domain example.com, then
requests coming from sample.example.com will be logged if L<exclude_subdomains>
is set to 0, while they won't be logged when L<exclude_subdomains> is set to 1.
(default value: 1)

=item C<truncate_referrers>

 This number defines, after how much characters the referring
address should be truncated in the ReferrerLog Display (default value: 40).

=back

=head1 METHODS

The behaviour of the Kwiki::ReferrerLog module can be changed quite easily.
Simply stuff the module in your @ISA array (or use it as a base class) and
override selected methods.
The module provides the following methods, which can be overridden:

=over 4

=item C<show_referrerlog()>

This method loads the stored referrers and renders the
template for showing the result back to the browser. It is registered as the
action-method for this module.

=item C<log_referrer>

This method logs the referrer. For this it checks if the
referrer comes from an external site. If this is not the case, the control
flow leaves the method. Otherwise the stored referrers are loaded and the
current one is appended to the list. Afterwards it checks, if some
of the referrers are older than the configured value for L<keep_days>. If this
is the case, the corresponding referrers are deleted from the list.

=item C<file_path>

This method returns a relative path to the location of the
referrer log file (default: F<plugin_directory/referrerlog/referrers.log>).

=item C<load_log>

This method loads the stored referrer entries and returns them as
an hash reference, that contains, keyed by referring URLs, array references.

The following example should clarify the structure:

=begin text
$hashref = { 'http://www.example.com/ref1' =>
                                  [ $visitcount,
                                    $time_of_last_request_via_this_referrer,
                                    $last_uri_that_was_requested_from_this_referrer ]
           }

=end text

=item C<store_log>

This method takes a hash reference as described above and stores
it, so that the L<load_log> method can retrieve it later.


=item C<date_fmt>

This method uses the L<date_format> configuration option, to format
the timestamp that is passed as the first and only parameter, as the user/admin
wishes.

=item C<delete_old_logs>

This method is called before every call to L<store_log>, and
deletes entries, that are older than the number of days specified by the
keep_days option (see above).

=back

=head1 AUTHOR

Benjamin Reitzammer C<cpan@nur-eine-i.de>

=head1 COPYRIGHT

Copyright (c) 2004. Benjamin Reitzammer. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 SEE ALSO

L<POSIX> for strftime date format syntax, L<Storable> is used for referrer
storage

=cut
__config/referrerlog.yaml__
keep_days: 2
date_format: %d.%m.%Y %H:%M
exclude_referrers:
exclude_subdomains: 1
truncate_referrers: 40
__template/tt2/referrerlog_button.html__
<a href="[% script_name %]?action=show_referrerlog" title="Log of Referrers">
[% INCLUDE referrerlog_button_icon.html %]
</a>
__template/tt2/referrerlog_button_icon.html__
Referrers
__template/tt2/referrerlog_content.html__
This is a list of sites, that refer to this website. The 'count' column denotes
the number of visitors, that have arrived from the corresponding site until now.
<table id="reflog_table">
  <tr>
    <th class="reflog_head">Viewed Page</th>
    <th class="reflog_head">Referring URL</th>
    <th class="reflog_head">Last Request</th>
    <th class="reflog_head">Count</th>
  </tr>
[% FOR  ref = log -%]
  <tr>
    <td class="[% 'odd_' IF loop.count % 2 == 0 %]reflog_line">
      <a href="[% script_name %]?[% ref.uri %]" title="link to [% ref.refuri %]">[% ref.uri %]</a></td>
    <td class="[% 'odd_' IF loop.count % 2 == 0 %]reflog_line">
      <a href="[% ref.refuri %]" title="external link to [% ref.refuri %]">
      [% IF ref.refuri.length > self.config.truncate_referrers %]
        [% FILTER truncate(self.config.truncate_referrers) %] [% ref.refuri %] [% END %]
      [% ELSE %]
        [% ref.refuri %]
      [% END %]
      </a>
    </td>
    <td class="[% 'odd_' IF loop.count % 2 == 0 %]reflog_line">[% self.date_fmt(ref.time) %]</td>
    <td class="[% 'odd_' IF loop.count % 2 == 0 %]reflog_line">[% ref.visitcount %]</td>
  </tr>
[% END %]
</table>
__css/referrerlog.css__
#reflog_table { width:100%; }
.reflog_head  {}
.reflog_line      { font-size:8px; font-family:fixed; }
.odd_reflog_line  { font-size:8px; font-family:fixed; background-color:#fffff7; }
