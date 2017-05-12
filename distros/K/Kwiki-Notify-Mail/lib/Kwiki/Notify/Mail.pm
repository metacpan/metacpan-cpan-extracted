# $Header: /home/staff/peregrin/cvs/Kwiki-Notify-Mail/lib/Kwiki/Notify/Mail.pm,v 1.8 2005/11/11 23:04:17 peregrin Exp $
#
package Kwiki::Notify::Mail;
use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
use MIME::Lite;

our $VERSION = '0.04';

const class_id    => 'notify_mail';
const class_title => 'Kwiki page edit notification via email';
const config_file => 'notify_mail.yaml';

sub debug {
    my $debug = $self->hub->config->notify_mail_debug || 0;
    return $debug;
}

sub register {
    my $registry = shift;
    $registry->add(
        hook => 'page:store',
        post => 'notify',
    );
}

sub recipient_list {
    my $notify_mail_obj = $self->hub->load_class('notify_mail');
    my $mail_to         = $notify_mail_obj->config->notify_mail_to;
    my $topic           = $notify_mail_obj->config->notify_mail_topic;
    my $meta_data       = $self->hub->edit->pages->current->metadata;
    my $who             = $meta_data->{edit_by};
    my $page_name       = $meta_data->{id};
    my ( $cfg, $page, $email );

    return undef
        unless defined $mail_to && defined $who && defined $page_name;

    # Support for a notify_mail_topic configuration entry giving a page from
    # which notification info can be read.
    $cfg = $self->hub->pages->new_page($topic);
    if ( defined $cfg ) {
        foreach ( split( /\n/, $cfg->content ) ) {
            s/#.*//;
            next if /^\s*$/;
            unless ( ( $page, $email ) = /^([^:]+):\s*(.+)/ ) {
                print STDERR "Kwiki::Notify::Mail: Unrecognised line in ",
                    $topic, ": ", $_, "\n";
                next;
            }
            next unless $page_name =~ /^$page$/;
            $mail_to .= " " . $email;
        }
    }

    return $mail_to;
}

sub notify {
    my $hook            = pop;
    my $page            = shift;
    my $notify_mail_obj = $self->hub->load_class('notify_mail');

    my $meta_data  = $self->hub->edit->pages->current->metadata;
    my $site_title = $self->hub->config->site_title;

    my $edited_by = $meta_data->{edit_by} || 'unknown name';
    my $page_name = $meta_data->{id}      || 'unknown page';
    my $to      = $notify_mail_obj->recipient_list();
    my $from    = $notify_mail_obj->config->notify_mail_from || 'unknown';
    my $subject = sprintf( $notify_mail_obj->config->notify_mail_subject,
        $site_title, $page_name, $edited_by )
        || 'unknown';
    $subject =~ s/\$1/$site_title/g;
    $subject =~ s/\$2/$page_name/g;
    $subject =~ s/\$3/$edited_by/g;

    my $body = "$site_title page $page_name edited by $edited_by\n";

    $notify_mail_obj->mail_it( $to, $from, $subject, $body ) if $to;
    return $self;
}

sub mail_it {
    my ( $to, $from, $subject, $body ) = @_;

    my $msg = MIME::Lite->new(
        To      => $to,
        From    => $from,
        Subject => $subject,
        Data    => $body,
    );

    if ( debug($self) ) {
        open( TEMPFILE, '>', '/tmp/kwiki_notify_mail.txt' )
            || die "can't open tmp file $!";
        $msg->print( \*TEMPFILE );
        close TEMPFILE;
    }
    else {
        $msg->send;
    }
}

1;    # End of Kwiki::Notify::Mail

__DATA__

=head1 NAME

Kwiki::Notify::Mail - send an email when a page is updated

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

 $ cd /path/to/kwiki
 $ kwiki -add Kwiki::Notify::Mail
 $ cat config/notify_mail.yaml >> config.yaml
 $ edit config.yaml

=head1 REQUIRES

This module requires MIME::Lite to send email.

=head1 DESCRIPTION

This module allows you to notify yourself by email when some one
updates a page.  You can specify the To:, From: and Subject: headers,
but the email message body is not currently configurable.

A sample email looks like: 

 Content-Disposition: inline
 Content-Length: 52
 Content-Transfer-Encoding: binary
 Content-Type: text/plain
 MIME-Version: 1.0
 X-Mailer: MIME::Lite 3.01 (F2.72; B3.01; Q3.01)
 Date: Sun, 29 Aug 2004 22:00:31 UT
 To: geo_bush@casablanca.gov
 From: nobody@countykerry.ir
 Subject: Kwiki page update

 Kwiki page LotsOfWikiWords edited by AnonymousGnome

=head2 Configuration Directives

=over 4

=item * notify_mail_to

Specify the mail address you are sending to.  Email will be sent to these
addresses for all page updates.

=item * notify_mail_topic

Specify the mail topic or ConfigPage that is used to decide who to send mail
to.  The ConfigPage is of the format

    WikiPage: email@domain.com

WikiPage may be given as a regular expression, and multiple email addresses
may be given.  For example:

    HomePage: me@my.domain.com
    .*: bigmailbox@my.domain.com
    Doc.*: docs@my.domain.com me@my.domain.com

If you are also using the notify_mail_to directive, any email will
also be sent to that address.

Note: Addresses are separated by spaces.  If your message transfer
agent expects addresses separated by commas, then use a comma.
However in this case you can't also use the notify_mail_to directive,
because it will be added to the email From: line with a space.

=item * notify_mail_from

Specify the address this is apparently from.

=item * notify_mail_subject

Specify a subject line for the mail message.  You can make use of
sprintf()-type formatting codes (%s is the only one that is relevant).
If you put one or more %s in the configuration directive it will print out
the site title, page name and whom it was edited by.  You may also put
$1, $2 and/or $3 in the subject line.  They will be replaced with the site
title, the page name and whom it was edited by respectively.

Examples:

 notify_mail_subject: Kwiki was updated

gives you the Subject: line

 Subject: Kwiki was updated

If your site title (defined in site_title in config.yaml) was
'ProjectDiscussion', then

 notify_mail_subject: My wiki %s was updated

gives you the Subject: line

 Subject: My wiki ProjectDiscussion was updated

Next you can add the page name with a second %s.  If the updated
page happened to be 'NextWeeksAgenda', the configuration directive

 notify_mail_subject: My wiki %s page %s was updated

gives you the Subject: line

 Subject: My wiki ProjectDiscussion page NextWeeksAgenda was updated

Finally, a third %s gives you the name of the person who edited the page:

 notify_mail_subject: My wiki %s page %s was updated by %s

 Subject: My wiki ProjectDiscussion page NextWeeksAgenda was updated
 by PointyHairedBoss

The important thing to remember is that when using %s, you can't change the
order of argument substitution.  To do that, you need something like this:

 notify_mail_subject: $3 has updated $2 on $1

gives you the Subject: line

 Subject: PointyHairedBoss has updated NextWeeksAgenda on ProjectDiscussion

The default value is

 notify_mail_subject: %s wiki page %s updated by %s

which should be fine for most people.

=item * notify_mail_debug

When set, saves the mail message to /tmp/kwiki_notify_mail.txt instead
of sending it.

=back

=head1 AUTHOR

James Peregrino, C<< <jperegrino@post.harvard.edu> >>

=head1 ACKNOWLEDGMENTS

The folks at irc::/irc.freenode.net/kwiki, especially alevin and
statico.  The style of this module has been adapted from statico's
Kwiki::Notify::IRC.

Brian Somers C<< <brian@FreeBSD.org> >> provided the code and
documentation for the notify_mail_topic feature.

=head1 BUGS

The debug file is saved to /tmp and should be user configurable.  This
module was not tested under Windows and certainly /tmp doesn't exist
there.

Please report any bugs or feature requests to
C<bug-kwiki-notify-mail@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 James Peregrino, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
__config/notify_mail.yaml__
notify_mail_to:
notify_mail_topic: NotifyMail
notify_mail_from: nobody
notify_mail_subject: %s wiki page %s updated by %s
notify_mail_debug: 0

