use strict;
use warnings;
#use diagnostics;
package MediaWiki::Bot::Shell;
BEGIN {
  $MediaWiki::Bot::Shell::VERSION = '0.002';
}

use base qw(Term::Shell);
use MediaWiki::Bot '3.1.6';
use Config::General qw(ParseConfig SaveConfig);
use Term::Prompt;
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Select;
use Pod::Text::Termcap;
use IO::Handle;
use Encode;
use File::Copy qw(cp);

binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

=head1 NAME

MediaWiki::Bot::Shell - a shell interface to your MediaWiki::Bot

=head1 SYNOPSIS

    use MediaWiki::Bot::Shell;

    my $shell = MediaWiki::Bot::Shell->new();
    $shell->cmdloop();

=head1 DESCRIPTION

This provides a shell interface to your L<MediaWiki::Bot>. By initializing one
or more MediaWiki::Bot objects and using them for the duration of your shell
session, initialization costs are amortized.

Configuration data is read from F<~/.perlwikibot-shell.rc>, or prompted for at
startup.

You should probably run C<pwb>, which is included with this module, to enter
your shell.

=head1 OPTIONS

Options are passed to the constructor as a hashref. Options are currently:

=over 4

=item debug

Like it says on the tin. Setting debug provides debug output from this module,
as well as from the underlying L<MediaWiki::Bot> object(s).

=item norc

Don't read options from F<~/.perlwikibot-shell.rc>. This will result in the
user being prompted for username, password etc.

=back

=head1 COMMANDS

=cut

# Take some pod and Termcap it!
sub _render_help {
    my $pod = shift;
    my $pod_parser = Pod::Text::Termcap->new(
        width       => 72,
        utf8        => 1,
    );
    my $rendered_pod;
    $pod_parser->output_string(\$rendered_pod);
    $pod_parser->parse_string_document($pod);

    return $rendered_pod;
}

# Sets the shell prompt - How can I get rid of the underline?
sub prompt_str {
    my $o = shift;
    my $u = $o->{'SHELL'}->{'bot'};

    return (
        $u
        ? ( $u->{'host'} eq 'secure.wikimedia.org'
            ? $u->{'username'} . '>'
            : $u->{'username'} . '@' . $u->domain_to_db($u->{'host'}) . '>')
        : 'perlwikibot>'
    );
}

# At shell startup - right before cmdloop() begins
sub preloop {
    my $o = shift;
    my $options = $o->{'API'}->{'args'}->[0];

    $o->{'SHELL'}->{'debug'} = $options->{'verbose'} || 0;
    my $debug = $o->{'SHELL'}->{'debug'};
    print "Debugging on\n" if $debug;

    print "Setting STDOUT and STDERR to autoflush.\n" if $debug;
    STDOUT->autoflush(1);
    STDERR->autoflush(1);

    my $filename = "$ENV{'HOME'}/.perlwikibot-shell.rc";
    if (-r $filename and !$options->{'norc'}) {
        my $chmod = (stat(_))[2] & 07777;
        if ($chmod != 0600) {
            my $do_chmod = prompt('y', "$filename isn't private - should I try to make it so?", '', 'y');
            if ($do_chmod) {
                chmod 0600, $filename or die "Couldn't chmod $filename: $!";
            }
        }

        my %main = ParseConfig (
            -ConfigFile     => $filename,
            -AutoTrue       => 1,
            -UTF8           => 1,
        );

        print "Logging into $main{'username'}...";
        my $bot = MediaWiki::Bot->new({
            login_data => { username => $main{'username'},
                            password => $main{'password'},
                            do_sul   => $main{'do_sul'},
            },
            protocol   => $main{'protocol'},
            host       => $main{'host'},
            path       => $main{'path'},
            debug      => $debug,
        }) or die q{Couldn't log in};
        $bot->steward_new() or die q{Couldn't log in};
        print ($bot ? " OK\n" : " FAILED\n");
        $o->{'SHELL'}->{'bot'} = $bot;
    }
    else {
        my %main;
        $main{'username'}  = prompt('x', 'Account name:', '', '');
        $main{'password'}  = prompt('p', 'Password:', '', '');
        print "\n";
        $main{'host'}      = prompt('x', 'Domain name:', '', 'meta.wikimedia.org');
        $main{'path'}      = 'w';
        $main{'protocol'}  = 'http';
        if ($main{'host'} eq 'secure.wikimedia.org') {
            $main{'path'}     = prompt('x', 'Path:', '', 'wikipedia/meta/w');
            $main{'protocol'} = 'https';
            $main{'do_sul'}   = 0;
        }
        else {
            $main{'do_sul'} = prompt('y', 'Use SUL?', '', 'y');
        }

        my $save = prompt('y', 'Save settings for next time?', '', 'y');
        if ($save) {
            if (-e $filename) {
                my $clobber = prompt('y', "$filename already exists - overwrite?", '', 'n');
                cp($filename, "$filename.bak") or die "Couldn't make a backup: $!";
            }
            SaveConfig($filename, \%main);
            chmod 0600, $filename or die "Couldn't chmod 600 $filename: $!";
        }
        else {
            print "You didn't want to save the settings, so I threw them away\n";
        }

        print "Logging in...";
        my $bot = MediaWiki::Bot->new({
            login_data => { username => $main{'username'},
                            password => $main{'password'},
                            do_sul   => $main{'do_sul'},
            },
            protocol    => $main{'protocol'},
            host        => $main{'host'},
            path        => $main{'path'},
            debug       => $main{'debug'},
        }) or die q{Couldn't log in};
        $bot->steward_new() or die q{Couldn't log in};
        print ($bot ? " OK\n" : " FAILED\n");
        $o->{'SHELL'}->{'bot'} = $bot;
    }

    die "Login failed; can't do anything fun without a MediaWiki::Bot\n" unless $o->{'SHELL'}->{'bot'};
}

# At shell shutdown - right after cmdloop() ends
sub postloop {
    my $o = shift;
    my $u = $o->{'SHELL'}->{'bot'};

    $u = $u->logout() if ($u and $u->can('logout'));
    print "Logged out\n";
}

sub run_delete  {
    my $o       = shift;
    my $page    = shift;
    my $summary = shift || 'Vandalism ([[m:S|S]])';
    if (@_ > 0) {
        my $abort = prompt('y', 'Abort?', qq{Check your quoting - did you mean to delete [[$page]] with reason "$summary"?}, 'y');
        return 1 if $abort;
    }
    my $u = $o->{'SHELL'}->{'bot'};

    my $success = $u->delete($page, $summary);

    if ($success) {
        print "Deletion successful\n";
    }
    else {
        print "Deletion failed:\n"
            . "    $u->{'error'}->{'details'}\n";
    }
}
sub smry_delete {
    return 'delete a page';
}
sub help_delete {
    my $help = <<'=cut';
=head2 delete

This will delete a page on the wiki you're currently using:

    delete "Main Page" "for teh lulz"

To delete a page on another wiki, use [[w:fr:Page Title]]:

    delete "[[w:fr:Page Title]]" "pour les lulz"

Make sure you quote your input correctly.

=cut

    return _render_help($help);
}

sub run_set_wiki {
    my $o      = shift;
    my $domain = shift;
    my $path   = shift;

    my $u = $o->{'SHELL'}->{'bot'};

    if (!$domain) {
        $domain = prompt('x', 'Switch to what domain?', '', '');
        $path   = prompt('x', "What path on $domain?", '', 'w');
    }

    my $success;
    if ($domain eq 'secure.wikimedia.org') {
        $path = prompt('x', 'What path on secure.wikimedia.org?', '', '') unless defined($path);
        $success = $u->set_wiki({
            protocol => 'https',
            host     => $domain,
            path     => $path,
        });
    }
    else {
        $success = $u->set_wiki({
            host => $domain,
            path => $path
        });
    }

    if ($success) {
        print "Switched successfully\n";
    }
    else {
        print "Couldn't switch wiki\n";
    }
}
sub smry_set_wiki {
    return 'switch to another wiki';
}
sub help_set_wiki {
    my $help = <<'=cut';
=head2 set_wiki

Switch wikis:

    set_wiki meta.wikimedia.org
    set_wiki secure.wikimedia.org wikipedia/meta/w

=cut

    return _render_help($help);
}

sub run_debug {
    my $o     = shift;
    my $debug = shift;

    my $on  = "Debug output on\n";
    my $off = "Debug output off\n";
    if (!defined($debug)) {
        $o->{'SHELL'}->{'debug'} = 1;
        print $on;
    }
    elsif (defined($debug) and $debug =~ m/^(y|yes|1|true|on)$/i) {
        $o->{'SHELL'}->{'debug'} = 1;
        print $on;
    }
    elsif (defined($debug) and $debug =~ m/^(n|no|0|false|off)$/i) {
        $o->{'SHELL'}->{'debug'} = 0;
        print $off;
    }
    else {
        $debug = prompt('y', 'Provide debug output?', '', 'n');
        $o->{'SHELL'}->{'debug'} = $debug;
        print ($debug ? $on : $off);
    }
    $o->{'SHELL'}->{'bot'} = $o->{'SHELL'}->{'debug'};
}
sub smry_debug {
    return 'switch debugging on or off';
}
sub help_debug {
    my $help = <<'=cut';
=head2 debug

Turn debugging on or off

    debug on
    debug off

=cut

    return _render_help($help);
}

sub run_read {
    my $o    = shift;
    my $page = shift;
    if (@_ > 0) {
        $page = "$page " . join(' ', @_);
        my $continue = prompt('y', "Did you mean [[$page]]?", '', 'y');
        return unless $continue;
    }

    my $u = $o->{'SHELL'}->{'bot'};

    my $text = $u->get_text($page);
    if (defined($text)) {
        $o->page($text);
        print "\n";
    }
    else {
        print "[[$page]] doesn't exist\n";
    }
}
sub smry_read {
    return 'read a wiki page';
}
sub help_read {
    my $help = <<'=cut';
=head2 read

Read the wikitext of the given page. Remember to quote the page title correctly:

    read "Main Page"

=cut

    return _render_help($help);
}

sub run_kill {
    my $o        = shift;
    my $username = decode('utf8', shift);

    my $u = $o->{'SHELL'}->{'bot'};

    my $success = $u->ca_lock({
        user    => $username,
        lock    => 1,
        hide    => 0,
        reason  => 'cross-wiki abuse',
    });

    if ($success) {
        print "'$username' locked\n";
    }
    else {
        print "Couldn't lock '$username':\n"
            . "    $u->{'error'}->{'details'}\n";
    }
}
sub smry_kill {
    return 'lock a vandalism account';
}
sub help_kill {
    my $help = <<'=cut';
=head2 kill

Lock a cross-wiki vandal's account:

    kill "Some stupid vandal"

=cut

    return _render_help($help);
}

sub run_nuke {
    my $o        = shift;
    my $username = decode('utf8', shift);

    my $u = $o->{'SHELL'}->{'bot'};

    my $success = $u->ca_lock({
        user    => $username,
        lock    => 1,
        hide    => 2,
        reason  => 'cross-wiki abuse',
    });

    if ($success) {
        print "'$username' locked and hidden\n";
    }
    else {
        print "Couldn't lock and hide '$username':\n"
            . "    $u->{'error'}->{'details'}\n";
    }
}
sub smry_nuke {
    return 'lock and hide a vandalism account';
}
sub help_nuke {
    my $help = <<'=cut';
=head2 nuke

The nuclear option: globally lock I<and hide> an account:

    nuke "Mike.lifeguard lives at 123 Main St."

=cut

    return _render_help($help);
}

sub run_globalblock {
    my $o      = shift;
    my $ip     = shift;
    my @args   = @_;

    my $u = $o->{'SHELL'}->{'bot'};

    my $reason    = 'cross-wiki abuse';
    my $expiry    = '31 hours';
    my $anon_only = 0;
    my $block     = 1;
    my $result    = GetOptionsFromArray (\@args,
        'reason|summary=s'  => \$reason,
        'expiry|length=s'   => \$expiry,
        'anon-only|ao!'     => \$anon_only,
        'block!'            => \$block,
    );

    if ($block) {
        my $success = $u->g_block({
            ip     => $ip,
            ao     => $anon_only,
            reason => $reason,
            expiry => $expiry,
        });

        if ($success) {
            print "$ip blocked.\n"
        }
        else {
            print "Couldn't block $ip:\n"
                . "    $u->{'error'}->{'details'}\n";
        }
    }
    else {
        my $success = $u->g_unblock({
            ip      => $ip,
            reason  => $reason,
        });

        if ($success) {
            print "$ip unblocked.\n";
        }
        else {
            print "Couldn't unblock $ip:\n"
                . "    $u->{'error'}->{'details'}\n";
        }
    }
}
sub smry_globalblock {
    return 'place or remove a global IP block';
}
sub help_globalblock {
    my $help = <<'=cut';
=head2 globalblock

Apply a global block to an IP or CIDR range:

    globalblock 127.0.0.1 --expiry "31 hours"
    globalblock 192.168.0.1 --no-anon-only

=head3 Options:

=over 4

=item B<--block>, --no-block

Whether to block or unblock the target. Default is to block. When unblocking,
all settings except C<--reason> are ignored.

=item B<--anon-only>, --ao

=item B<--no-anon-only>, --no-ao

Whether to block only anonymous users, or all users. Default is to hardblock
(no-anon-only).

=item B<--reason>, --summary

Sets the block reason.

=item B<--expiry>, --length

Sets the block expiry.

=back

=cut

    return _render_help($help);
}

sub run_rollback {
    my $o    = shift;
    my $user = shift;
    my @args = @_;

    my $force = 0;
    my $result = GetOptionsFromArray (\@args,
        'force' => \$force,
    );
    my $max = ($force ? 0 : 10);

    my $u = $o->{'SHELL'}->{'bot'};
    my $debug = $o->{'SHELL'}->{'debug'};

    $u->top_edits($user, {
        max => $max,
        hook => sub {
            my $pages = shift;

            RV: foreach my $page (@$pages) {
                # CAREFUL! top_edits can't filter results when you use a callback
                next RV unless exists($page->{'top'});

                my $title = $page->{'title'};
                print "Rolling back edit on $title... " if $debug;
                my $success = $u->rollback($title, $user, undef, 1);
                print ($success ? "OK\n" : "FAILED\n") if $debug;
            }
        },
    });

    print "Finished reverting edits by $user.\n" if $debug;
}
sub smry_rollback {
    return q{rollback all of a vandal's edits};
}
sub help_rollback {
    my $help = <<'=cut';
=head2 rollback

Finds all top edits by the specified user and rolls them back using
mark-as-bot.

    rollback "Fugly vandal"

=over 4

=item B<--force>

Override the 10-query limit. Use this when reverting mass vandals which
have done hundreds of edits. The limit is intended to guard against
accidentally rolling back edits of an established user.

=back

Note that this does not (currently) revert page moves, nor delete page
creations.

=cut

    return _render_help($help);
}

=head1 SEE ALSO

L<pwb>, L<MediaWiki::Bot> and L<the admin plugin|MediaWiki::Bot::Plugin::Admin>.

=head1 BUGS

Yes. This is a proof-of-concept, and there are several issues with both
L<MediaWiki::Bot::Plugin::Steward> and this module. It should be considered
pre-alpha. I'm releasing the code so others can find and fix them, in the
hope that it will be useful for others.

Please do not report bugs to me without a patch. I have no plans to work on
this further.

=head1 AUTHOR

Mike.lifeguard <mike.lifeguard@gmail.com>

=head1 COPYING

Copyright (C) 2010 by Mike.lifeguard.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;

__END__

