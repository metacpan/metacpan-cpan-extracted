package MediaWiki::Bot::Plugin::Steward;
# ABSTRACT: A plugin to MediaWiki::Bot providing steward functions

use strict;
use warnings;

use Carp;
use Net::CIDR qw(range2cidr cidrvalidate);
use URI::Escape qw(uri_escape_utf8);
use WWW::Mechanize 1.30;

our $VERSION = 0.0003;



use Exporter qw(import);
our @EXPORT = qw(steward_new g_block g_unblock ca_lock ca_unlock _screenscrape_get _screenscrape_put _screenscrape_error _screenscrape_login);


sub steward_new {
    my $self = shift;

    my $mech = WWW::Mechanize->new(
        onerror     => \&Carp::carp,
        stack_depth => 1,
        agent       => $self->{'useragent'},
    );
    my $cookies = ".mediawiki-bot-$self->{'username'}-cookies";
    if (-r $cookies) {
        $mech->{'cookie_jar'}->load($cookies);
        $mech->{'cookie_jar'}->{'ignore_discard'} = 1;
    }
    else {
        croak "$cookies doesn't exist or isn't readable";
    }
    $self->{'mech'} = $mech;

    my $check_login = $self->_screenscrape_get('Special:BlankPage');
    if ($check_login->decoded_content() =~ m/wgUserName="\Q$self->{'username'}\E"/) {
        return 1;
    }
    else {
        croak "Steward plugin couldn't log in";
    }
}


sub g_block {
    my $self    = shift;
    my $ip      = ref $_[0] eq 'HASH' ? $_[0]->{'ip'} : shift; # Allow giving just an IP
    my $ao      = exists($_[0]->{'ao'}) ? $_[0]->{'ao'} : 0;
    my $reason  = $_[0]->{'reason'} || 'cross-wiki abuse';
    my $expiry  = $_[0]->{'expiry'} || '31 hours';
    my $clobber = exists($_[0]->{'clobber'}) ? $_[0]->{'clobber'} : 1;

    my $start;
    if ($ip =~ m/-/) {
        $start = (split(/\-/, $ip, 2))[0];
        $ip = range2cidr($start);
    }
    elsif ($ip =~ m,/\d\d$,) {
        $start = $ip;
        $start =~ s,/\d\d$,,;
    }
    unless ($ip =~ m,/\d\d$, || cidrvalidate($ip)) {
        carp "Invalid IP $ip" if $self->{'debug'};
    }

    my $opts = {
        'wpAddress'     => $ip,     # mw-globalblock-address
        'wpExpiryOther' => $expiry, # mw-globalblock-expiry-other
        'wpReason'      => $reason, # mw-globalblock-reason
        'wpAnonOnly'    => $ao,     # mw-globalblock-anon-only
    };
    my $res = $self->_screenscrape_put('Special:GlobalBlock', $opts, 1);
    if ($res->decoded_content() =~ m/class="error"/) {
        if ($clobber and $res->decoded_content() =~ 'already blocked globally') {
            # Resubmit unless noclobber
            $res = $self->{'mech'}->submit_form(
                with_fields => $opts,
            );
        }
        else {
            my $error = $self->_screenscrape_error($res->decoded_content());
            carp $error if $self->{'debug'};
            return;
        }
    }

    return $res;
}


sub g_unblock {
    my $self   = shift;
    my $ip     = ref $_[0] eq 'HASH' ? $_[0]->{'ip'} : shift;
    my $reason = $_[0]->{'reason'} || 'Removing obsolete block';

    my $start;
    if ($ip =~ m/-/) {
        $start = (split(/\-/, $ip, 2))[0];
        $ip = range2cidr($start);
    }
    elsif ($ip =~ m,/\d\d$,) {
        $start = $ip;
        $start =~ s,/\d\d$,,;
    }
    unless ($ip =~ m,/\d\d$, || cidrvalidate($ip)) {
        carp "Invalid IP $ip" if $self->{'debug'};
    }

    if ($start) {
        # When rangeblocks are placed, the CIDR gets normalized - so you cannot unblock
        # the same range you blocked. You'll need to do some kind of lookup. Probably,
        # you can convert CIDR to A-B range, take the first IP, see whether it is blocked
        # and what rangeblock affects it, then unblock that.

        $ip = $self->is_g_blocked($start);
        unless ($ip) {
            carp "Couldn't find the matching rangeblock" if $self->{'debug'};
            return;
        }
    }

    my $opts = {
        'address'   => $ip,
        'wpReason'  => $reason,
    };
    my $res = $self->_screenscrape_put('Special:GlobalUnblock', $opts, 1);

    if ($res->decoded_content() =~ m/class="error"/) {
        my $error = $self->_screenscrape_error($res->decoded_content());
        carp $error if $self->{'debug'};
        return;
    }

    return 1;
}


sub ca_lock {
    my $self   = shift;
    my $user   = ref $_[0] eq 'HASH' ? $_[0]->{'user'} : shift;
    my $hide   = $_[0]->{'hide'} || 0;
    my $reason = $_[0]->{'reason'} || 'cross-wiki abuse';
    my $lock   = defined($_[0]->{'lock'}) ? $_[0]->{'lock'} : 1;

    if ($hide == 0) {
        $hide = '';
    }
    elsif ($hide == 1) {
        $hide = 'lists';
    }
    elsif ($hide == 2) {
        $hide = 'suppressed';
    }
    $user =~ s/^User://i;
    $user =~ s/\@global$//i;

    my $res = $self->_screenscrape_put("Special:CentralAuth", {target=>$user}, 1);
    if ($res->decoded_content() =~ m/class="error"/) {
        my $error = $self->_screenscrape_error($res->decoded_content());
        carp $error if $self->{'debug'};
        return;
    }

    $res = $self->{'mech'}->submit_form(
        with_fields => {
            wpStatusLocked  => $lock,
            wpStatusHidden  => $hide,
            wpReason        => $reason,
        },
    );
    if ($res->decoded_content() =~ m/class="error"/) {
        my $error = $self->_screenscrape_error($res->decoded_content());
        carp $error if $self->{'debug'};
        return;
    }

    return $res;
}


sub ca_unlock {
    my $self = shift;
    my $user = ref $_[0] eq 'HASH' ? $_[0]->{'user'} : shift;
    my $hide = $_[0]->{'hide'} || 0;
    my $reason = $_[0]->{'reason'} || 'Removing obsolete account lock';
    my $lock = defined($_[0]->{'lock'}) ? $_[0]->{'lock'} : 0;

    return $self->ca_lock({
        user    => $user,
        hide    => $hide,
        reason  => $reason,
        lock    => $lock,
    });
}


################
# Internal use #
################

# Submits a form screenscrape-style (barf!)
sub _screenscrape_put {
    my $self    = shift;
    my $page    = shift;
    my $options = shift;
    my $no_esc  = shift;
    my $extra   = shift;

    my $res     = $self->_screenscrape_get($page, $no_esc, $extra);
    return unless (ref($res) eq 'HTTP::Response' && $res->is_success);

    $res = $self->{'mech'}->submit_form(
        with_fields => $options,
    );

    return $res;
}

# Gets a page screenscrape-style (barf!)
sub _screenscrape_get {
    my $self      = shift;
    my $page      = shift;
    my $no_escape = shift || 0;
    my $extra     = shift || '&uselang=en&useskin=monobook';

    $page = uri_escape_utf8($page) unless $no_escape;

    my $url = "http://$self->{host}/$self->{path}/index.php?title=$page";
    $url .= $extra if $extra;
    print "Retrieving $url\n" if $self->{debug};

    my $res = $self->{'mech'}->get($url);
    return unless (ref($res) eq 'HTTP::Response' && $res->is_success());

    if ($res->decoded_content() =~ m/class="error"/) {
        my $error = $self->_screenscrape_error($res->decoded_content());
        carp $error if $self->{'debug'};
        return;
    }

    return $res;
}

# Returns the text of the first div with class 'error'
sub _screenscrape_error {
    my $self = shift;
    my $html = shift;

    require HTML::TreeBuilder;
    my $tree = HTML::TreeBuilder->new_from_content($html);
    my $error = $tree->look_down(
        '_tag', 'div',
        'class', 'error'
    );

    my $error_text = $error->as_text();
    $self->{'error'}->{'details'} = $error_text;
    $self->{'error'}->{'code'}   = 3;
    return $error_text;
}


1;



=pod

=head1 NAME

MediaWiki::Bot::Plugin::Steward - A plugin to MediaWiki::Bot providing steward functions

=head1 VERSION

version 0.0003

=head1 SYNOPSIS

    use MediaWiki::Bot;
    my $bot = MediaWiki::Bot->new({
        operator    => 'Mike.lifeguard',
        assert      => 'bot',
        protocol    => 'https',
        host        => 'secure.wikimedia.org',
        path        => 'wikipedia/meta/w',
        login_data  => { username => "Mike.lifeguard", password => $pass },
    });
    $bot->g_block({
        ip => '127.0.0.1',
        ao => 0,
        summary => 'bloody vandals...',
    });

=head1 DESCRIPTION

A plugin to the MediaWiki::Bot framework to provide steward functions to a bot.

=head1 METHODS

=head2 import()

Calling import from any module will, quite simply, transfer these subroutines into that module's namespace. This is possible from any module which is compatible with MediaWiki::Bot.

=head2 steward_new($data_hashref)

=head2 g_block($data_hashref)

This places a global block on an IP or IP range. You can provide either CIDR or classful ranges. To easily place a vandalism block, pass just the IP.

=over 4

=item *
ip - the IP or IP range to block. Use a single IP, CIDR range, or classful range.

=item *
ao - whether to block anon-only; default is true.

=item *
reason - the log summary. Default is 'cross-wiki abuse'.

=item *
expiry - the expiry setting. Default is 31 hours.

=back

    $bot->g_block({
        ip     => '127.0.0.1',
        ao     => 0,
        reason => 'silly vandals',
        expiry => '1 week',
    });

    # Or, use defaults
    $bot->g_block('127.0.0.0-127.0.0.255');

=head2 g_unblock($data)

Remove the global block affecting an IP or range. The hashref is:

=over 4

=item *
ip - the IP or range to unblock. You don't need to convert your range into a CIDR, just pass in your range in xxx.xxx.xxx.xxx-yyy.yyy.yyy.yyy format and let this method do the work.

=item *
reason - the log reason. Default is 'Removing obsolete block'.

=back

If you pass only the IP, a generic reason will be used.

    $bot->g_unblock({
        ip      => '127.0.0.0-127.0.0.255',
        reason  => 'oops',
    });
    # Or
    $bot->g_unblock('127.0.0.1');

=head2 ca_lock($data)

Locks and hides a user with CentralAuth. $data is a hash:

=over 4

=item *
user - the user to target

=item *
lock - whether to lock or unlock the account - default is lock (0=unlocked, 1=locked)

=item *
hide - how hard to hide the account - default is not at all (0=none, 1=lists, 2=oversight)

=item *
reason - default is 'cross-wiki abuse'

=back

If you pass in only a username, the account will be locked but not hidden, and the default reason will be used:

    $bot->ca_lock("Mike.lifeguard");
    # Or, the more complete call:
    $bot->ca_lock({
        user    => "Mike.lifeguard",
        reason  => "test",
    });

=head2 ca_unlock($data)

Same parameters as ca_lock(), but with the default setting for lock reversed (ie, default is I<unlock>).

=head1 AUTHORS

=over 4

=item *

Mike.lifeguard <mike.lifeguard@gmail.com>

=item *

patch and bug report contributors

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by the MediaWiki::Bot team <perlwikibot@googlegroups.com>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut


__END__
