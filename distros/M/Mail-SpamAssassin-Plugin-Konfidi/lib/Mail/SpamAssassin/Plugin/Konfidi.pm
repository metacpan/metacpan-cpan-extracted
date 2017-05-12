# <@LICENSE>
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# </@LICENSE>

package Mail::SpamAssassin::Plugin::Konfidi;

=head1 NAME

Mail::SpamAssassin::Plugin::Konfidi - A SpamAssassin plugin that uses the Konfidi distributed trust network for authenticated messages.

=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';

=head1 SYNOPSIS

Install this module by running:

 cpan Mail::SpamAssassin::Plugin::Konfidi

Tell SpamAssassin to use it by putting the following (from this module's F<etc/init_konfidi.pre>) in a configuration file

 loadplugin Mail::SpamAssassin::Plugin::Konfidi

Configure the plugin by putting the following (from this module's F<etc/61_konfidi.cf>) in a configuration file (see L<http://wiki.apache.org/spamassassin/WhereDoLocalSettingsGo>)

 ifplugin Mail::SpamAssassin::Plugin::Konfidi
 
 full    KONFIDI_TRUST_VALUE     eval:check_konfidi()
 describe KONFIDI_TRUST_VALUE     Konfidi-computed trust value for sender, if sender is authenticated
 
 endif   # Mail::SpamAssassin::Plugin::Konfidi

Set settings for yourself:

 konfidi_service_url http://test-server.konfidi.org/
 konfidi_my_pgp_fingerprint 1234DEADBEEF5678... # this should be your full 40-digit fingerprint
 
 konfidi_rating0_becomes_score 0
 konfidi_rating1_becomes_score -20

The rating-becomes-score settings define a linear scale, so using the above example, a Konfidi rating of 0.75 would generate a SpamAssassin score of -15.  You do not set any regular 'score' rules since the scores are assigned dynamically based on these settings.

=head1 DESCRIPTION

This plugin currently only uses OpenPGP signatures for authentication and requires L<Mail::SpamAssassin::Plugin::OpenPGP>.  Future versions will also support L<Mail::SpamAssassin::Plugin::SPF> and
L<Mail::SpamAssassin::Plugin::DKIM> for authentication.

The loadplugin statement for OpenPGP must occur before the loadplugin statement for Konfidi.  This can be done by putting them in order in one file, or naming your configuration files in order like 26_openpgp.cf and 61_konfidi.cf

For project information, see L<http://konfidi.org>

=head1 USER SETTINGS

If you want to add a header that shows the Konfidi trust value, use this:

 add_header all Konfidi-Trust-Value _KONFIDITRUSTVALUE_

=cut

use warnings;
use strict;
use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::Logger;
use Mail::SpamAssassin::Timeout;
use Konfidi::Client;
use Error qw(:try);

use vars qw(@ISA);
@ISA = qw(Mail::SpamAssassin::Plugin);

sub new {
    my $class = shift;
    my $mailsaobject = shift;

    # some boilerplate...
    $class = ref($class) || $class;
    my $self = $class->SUPER::new($mailsaobject);
    bless ($self, $class);

    dbg "konfidi: created";
    
    $self->register_eval_rule ("check_konfidi");
    
    $self->{konfidi_client} = Konfidi::Client->new();
    
    $self->set_config($mailsaobject->{conf});
    
    return $self;
}

# SA 3.1 style of parsing config options
sub set_config {
  my($self, $conf) = @_;
  my @cmds = ();

  # see Mail::SpamAssassin::Conf::Parser for expected format of the "config blocks" stored in @cmds

  push(@cmds, {
    setting => 'konfidi_service_url', 
    default => 'http://test-server.konfidi.org/', 
    type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
  });
  push(@cmds, {
    setting => 'konfidi_my_pgp_fingerprint', 
    #default => 'http://test-server.konfidi.org/', 
    type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
  });
   #TODO: make this required
   # TODO validate format
  push(@cmds, {
    setting => 'konfidi_rating1_becomes_score', 
    default => 0, 
    type => $Mail::SpamAssassin::Conf::CONF_TYPE_NUMERIC,
  });
  push(@cmds, {
    setting => 'konfidi_rating0_becomes_score', 
    default => 0, 
    type => $Mail::SpamAssassin::Conf::CONF_TYPE_NUMERIC,
  });
  
  # grr, why isn't register_commands documented?
  $conf->{parser}->register_commands(\@cmds);
  
    # FIXME: validate that this gets set
    $self->{konfidi_client}->server($conf->{konfidi_service_url});
}

# see http://wiki.apache.org/spamassassin/PluginWritingTips "Writing plugins with dynamic score rules"
sub check_konfidi {
    my ($self, $scan) = @_;
    dbg "konfidi: running check_konfidi";
    if ($scan->{openpgp_signed_good}) {
        # FIXME: timeouts, ala http://wiki.apache.org/spamassassin/iXhash
        my $kr;
        try {
            $kr = $self->{konfidi_client}->query($scan->{conf}->{konfidi_my_pgp_fingerprint}, $scan->{openpgp_fingerprint}, 'http://www.konfidi.org/ns/topics/0.0#internet-communication');
            dbg "konfidi: response value: " . $kr->{'Rating'};
        } catch Konfidi::Client::Error with {
            my $E = shift;
            dbg "konfidi: couldn't query the trustserver: $E";
            # for some reason this doesn't exit the sub???
            return 0;
        };
        return 0 unless $kr;
        
        # convert [0,1] rating to SA score
        my $score = $scan->{conf}->{konfidi_rating0_becomes_score} - $kr->{'Rating'} * 
                    ($scan->{conf}->{konfidi_rating0_becomes_score} - $scan->{conf}->{konfidi_rating1_becomes_score});
        dbg "konfidi: scoring " . sprintf("%0.3f", $score);
        
        # http://wiki.apache.org/spamassassin/PluginWritingTips dynamic score rules
        $scan->got_hit("KONFIDI_TRUST_VALUE", "KONFIDI: ", ruletype => 'eval', score => $score);
        for my $set (0..3) {
            $scan->{conf}->{scoreset}->[$set]->{"KONFIDI_TRUST_VALUE"} = sprintf("%0.3f", $score);
        }
        # "KONFIDI" as $area?

        # Mail::SpamAssassin::Plugin::AWL 3.1.7 line 387
        # $scan->_handle_hit("KONFIDI_TRUST_VALUE", $score, "KONFIDI: ", $scan->{conf}->{descriptions}->{KONFIDI_TRUST_VALUE});

        $scan->set_tag("KONFIDITRUSTVALUE", $kr->{'Rating'});

    } else {
        dbg "konfidi: skipping message, did not have a good PGP signature (make sure Mail::SpamAssassin::Plugin::OpenPGP is in use)";
    }
	return 0;
}

# http://mail-archives.apache.org/mod_mbox/spamassassin-dev/200707.mbox/%3c46AFF6EC.3090404@brondsema.net%3e
#~ sub parsed_metadata {
	#~ my ($self, $opts) = @_;
	#~ return if $self->{main}->{local_tests_only};

	#~ my $scan = $opts->{permsgstatus} or die "No scanner!";
    #~ dbg "konfidi: parsed_metadata: " . $scan->{openpgp_signed};
	#~ #$self->_karma_send($scanner);

	#~ return undef;
#~ }

#~ # "This is a good place to harvest your own asynchronously-started network lookups."
#~ # http://search.cpan.org/~shevek/Mail-Karmasphere-Client-2.10/lib/Mail/SpamAssassin/Plugin/Karmasphere.pm#INTERNALS
#~ sub check_post_dnsbl {
	#~ my ($self, $opts) = @_;
	#~ return if $self->{main}->{local_tests_only};

	#~ my $scan = $opts->{permsgstatus} or die "No scanner!";
    #~ dbg "konfidi: check_post_dnsbl: " . $scan->{openpgp_signed};
#~ }

1; # End of Mail::SpamAssassin::Plugin::Konfidi
__END__

=head1 AUTHOR

Dave Brondsema, C<< <dave at brondsema.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mail-spamassassin-plugin-konfidi at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-SpamAssassin-Plugin-Konfidi>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::SpamAssassin::Plugin::Konfidi

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-SpamAssassin-Plugin-Konfidi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-SpamAssassin-Plugin-Konfidi>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-SpamAssassin-Plugin-Konfidi>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-SpamAssassin-Plugin-Konfidi>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Dave Brondsema, all rights reserved.

This program is released under the following license: Apache License, Version 2.0

=cut
