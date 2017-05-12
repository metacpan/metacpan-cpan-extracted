#   Copyright 2007 Daniel Born <danborn@cpan.org>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

=head1 NAME

Mail::SpamAssassin::Plugin::GoogleSafeBrowsing - SpamAssassin plugin to score
mail based on Google blocklists.

=head1 SYNOPSIS

  loadplugin Mail::SpamAssassin::Plugin::GoogleSafeBrowsing
  body GOOGLE_SAFEBROWSING eval:check_google_safebrowsing_blocklists()

=head1 DESCRIPTION

Score messages by checking the URIs they contain against Google's safebrowsing
tables. See L<http://code.google.com/apis/safebrowsing/>

=head1 CONFIGURATION

The GoogleSafeBrowsing SpamAssassin plugin relies on a local cache of the
URI tables to scan messages. The local cache should be updated at least once
every 30 minutes. The recommended setup looks something like:

=over

=item Install the required Perl modules:

  Net::Google::SafeBrowsing::Blocklist
  Net::Google::SafeBrowsing::UpdateRequest
  Mail::SpamAssassin::Plugin::GoogleSafeBrowsing

=item Get an API key from Google

L<http://code.google.com/apis/safebrowsing/key_signup.html>

=item Use the blocklist_updater Perl script to keep the local cache up to date.

Install a cron job that, every 25 minutes or so, runs something like:

  APIKEY=ABCD...
  for LIST in goog-black-hash goog-malware-hash; do
    blocklist_updater --apikey "$APIKEY" --blocklist $LIST --dbfile /var/cache/spamassassin/${LIST}-db
  done

"goog-black-hash" and "goog-malware-hash" are the only lists Google has for now.
goog-black-hash seems to be a list for the worst sites.

=item Configure spamassassin

Typically in local.cf, include lines:
  loadplugin Mail::SpamAssassin::Plugin::GoogleSafeBrowsing
  body GOOGLE_SAFEBROWSING eval:check_google_safebrowsing_blocklists()

  google_safebrowsing_dir /var/cache/spamassassin
  google_safebrowsing_apikey ABCD...
  google_safebrowsing_blocklist goog-black-hash 0.2
  google_safebrowsing_blocklist goog-malware-hash 0.1

In this example, for each URI in a message that has a match in goog-black-hash,
add 0.2 to the message's spam score.

=back

=cut

package Mail::SpamAssassin::Plugin::GoogleSafeBrowsing;
use strict;
use warnings;
use Net::Google::SafeBrowsing::Blocklist;
use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::Logger;
use URI;
use File::Spec;
use base qw(Mail::SpamAssassin::Plugin);
our $VERSION = '1.03';

our $CONFIG_DIR = 'google_safebrowsing_dir';
our $CONFIG_APIKEY = 'google_safebrowsing_apikey';
our $CONFIG_BLOCKLIST = 'google_safebrowsing_blocklist';
# Map config key to number of args.
our %CONFIGKEYS = ($CONFIG_DIR => 1,
                   $CONFIG_APIKEY => 1,
                   $CONFIG_BLOCKLIST => 1);

our $RULENAME = 'GOOGLE_SAFEBROWSING';
our $LOG_FACILITY = 'GoogleSafeBrowsing';

# Fields:
# mailsa - Mail::SpamAssassin instance
# blocklists - {$name => {bl => Net::Google::SafeBrowsing::Blocklist, score => <score>},
#               ...,}
sub new {
  my ($class, $mailsa) = @_;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new($mailsa);
  bless($self, $class);
  $self->{mailsa} = $mailsa;
  Mail::SpamAssassin::Logger::add_facilities($LOG_FACILITY);
  $self->register_eval_rule('check_google_safebrowsing_blocklists');
  $self->set_config($mailsa->{conf});
  return $self;
}

sub set_config {
  my Mail::SpamAssassin::Plugin::GoogleSafeBrowsing $self = shift;
  my ($conf) = @_;

  sub config_log {
    my ($config, @msg) = @_;
    my $msg = join('', "$LOG_FACILITY: ", @msg);
    if ($config->{lint_rules}) {
      warn $msg, "\n";
    } else {
      Mail::SpamAssassin::Logger::info($msg);
    }
  }

  sub required_dir {
    my ($config, $key, $value, $line) = @_;
    if (not defined($value) or length($value) == 0) {
      return $Mail::SpamAssassin::Conf::MISSING_REQUIRED_VALUE;
    }
    $value = Mail::SpamAssassin::Util::untaint_file_path($value);
    if (not (-d $value and -x _)) {
      config_log($config,
                 "config: $key '$value' isn't a readable directory");
      return $Mail::SpamAssassin::Conf::INVALID_VALUE;
    }
    $config->{$key} = $value;
  }

  sub blocklist_config {
    my ($config, $key, $value, $line) = @_;
    my ($name, $score) = split(/\s+/, $value, 2);
    if (not (defined($name) and defined($score) and $score =~ /^(:?\d*\.)?\d+$/)) {
      config_log($config, "config: $key <blocklist name> <score added per URI matched>");
      return $Mail::SpamAssassin::Conf::INVALID_VALUE;
    }
    $config->{$key}->{$name} = $score;
  }

  my @cmds;
  push(@cmds,
      {setting => $CONFIG_DIR,
       code => \&required_dir,},
      {setting => $CONFIG_APIKEY,
       type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,},
      {setting => $CONFIG_BLOCKLIST,
       code => \&blocklist_config,},);
  $conf->{parser}->register_commands(\@cmds);
}

sub finish_parsing_end {
  my Mail::SpamAssassin::Plugin::GoogleSafeBrowsing $self = shift;
  my ($opts) = @_;
  if (not ($opts->{conf}->{$CONFIG_BLOCKLIST} and
           $opts->{conf}->{$CONFIG_DIR} and
           $opts->{conf}->{$CONFIG_APIKEY})) {
    Mail::SpamAssassin::Logger::info("$LOG_FACILITY: Incomplete config, " .
        "need all of $CONFIG_BLOCKLIST, $CONFIG_DIR, $CONFIG_APIKEY");
    return;
  }
  while (my ($name, $score) = each(%{$opts->{conf}->{$CONFIG_BLOCKLIST}})) {
    $self->{blocklists}->{$name}->{bl} = Net::Google::SafeBrowsing::Blocklist->new(
      $name, File::Spec->join($opts->{conf}->{$CONFIG_DIR}, $name . '-db'),
      $opts->{conf}->{$CONFIG_APIKEY});
    $self->{blocklists}->{$name}->{score} = $score;
  }
}

sub l {
  Mail::SpamAssassin::Logger::dbg("$LOG_FACILITY: " . join('', @_));
}

sub check_google_safebrowsing_blocklists {
  my Mail::SpamAssassin::Plugin::GoogleSafeBrowsing $self = shift;
  my ($pms, $msg_ary_ref) = @_;
  my %uris;
  while (my($raw_uri, $urifields) = each(%{$pms->get_uri_detail_list})) {
    my $cleaned = $urifields->{cleaned};
    my $uristr;
    if (@{$cleaned} > 1) {
      $uristr = $cleaned->[1];
    } elsif (@{$cleaned} > 0) {
      $uristr = $cleaned->[0];
    } else {
      $uristr = $raw_uri;
    }
    if (defined($uristr)) {
      $uris{$uristr} = 1;
    }
  }
  my $spamscore = 0.0;
  while (my ($uristr, $unused) = each(%uris)) {
    while (my ($name, $fields) = each(%{$self->{blocklists}})) {
      my $matched_uri = $fields->{bl}->suffix_prefix_match($uristr);
      if (defined($matched_uri)) {
        $spamscore += $fields->{score};
      }
      l("URI: '", $uristr, "', blocklist: ", $name, ", match: '",
        defined($matched_uri) ? $matched_uri : "(none)", "'");
    }
  }
  l("Spam score for message: ", $spamscore);
  if ($spamscore > 0.0) {
    $pms->got_hit($RULENAME, 'BODY: ', score => $spamscore);
    for my $set (0..3) {
      $pms->{conf}->{scoreset}->[$set]->{$RULENAME} = 
        sprintf("%0.3f", $spamscore);
    }
  }
  return 0;
}


1;
