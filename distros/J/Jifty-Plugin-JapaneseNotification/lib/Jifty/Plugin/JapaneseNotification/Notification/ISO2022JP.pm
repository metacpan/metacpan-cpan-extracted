package Jifty::Plugin::JapaneseNotification::Notification::ISO2022JP;

=encoding utf8

=head1 NAME

Jifty::Plugin::JapaneseNotification::Notification::ISO2022JP - Send emails from Jifty with Japanese character code

=head1 SYNOPSIS

Add the following to your site_config.yml

    framework: 
      Plugins: 
        - JapaneseNotification: {}

in your application

    use utf8;

    my $notification =
        Jifty->app_class('Notification', 'ISO2022JP')->new(
            from    => 'Pikari <pi@null.in>',
            to      => 'Keronyo <ke@null.in>',
            subject => 'Hello!',
            body    => 'FumoFumo--',
        );
    $notification->send;

=cut

use strict;
use warnings;

use base qw/Jifty::Notification/;

use Encode;

=head1 METHODS

=head2 send_one_message

=cut

sub send_one_message {
    my $self       = shift;
    my @recipients = $self->recipients;
    my $to         = join( ', ',
        map { ( ref $_ && $_->can('email') ? $_->email : $_ ) } grep {$_} @recipients );
    $self->log->debug("Sending a ".ref($self)." to $to"); 
    return unless ($to);
    my $message = "";
    my $appname = Jifty->config->framework('ApplicationName');

    #my %attrs = ( charset => 'UTF-8' );
    my %attrs = ( charset => 'ISO-2022-JP' );

    if ($self->html_body) {
      $message = Email::MIME->create_html(
					     header => [
							From    => ($self->from    || _('%1 <%2>' , $appname, Jifty->config->framework('AdminEmail'))) ,
							To      => $to,
							Subject => Encode::encode('MIME-Header', $self->subject || _("A notification from %1!",$appname )),
						       ],
					     attributes => \%attrs,
                         text_body_attributes => \%attrs,
                         body_attributes => \%attrs,
					     text_body => Encode::encode_utf8($self->full_body),
					     body => Encode::encode_utf8($self->full_html),
                         embed => 0,
                         inline_css => 0
					    );
        # Since the containing messsage will still be us-ascii otherwise
        $message->charset_set( $attrs{'charset'} );
    } else {
            $message = Email::MIME->create(
					     header => [
							From    => Encode::encode('MIME-Header-ISO_2022_JP', $self->from    || _('%1 <%2>' , $appname, Jifty->config->framework('AdminEmail'))) ,
							To      => Encode::encode('MIME-Header-ISO_2022_JP', $to),
							Subject => Encode::encode('MIME-Header-ISO_2022_JP', $self->subject || _("A notification from %1!",$appname )),
						       ],
					     attributes => \%attrs,
					     
					     parts => $self->parts
					    );
	  }
    $message->encoding_set('7bit')
        if (scalar $message->parts == 1);
    $self->set_headers($message);

    my $method   = Jifty->config->framework('Mailer');
    my $args_ref = Jifty->config->framework('MailerArgs');
    $args_ref = [] unless defined $args_ref;

    my $sender
        = Email::Send->new( { mailer => $method, mailer_args => $args_ref } );

    my $ret = $sender->send($message);

    unless ($ret) {
        $self->log->error("Error sending mail: $ret");
    }

    $ret;
}

=head2 parts

=cut

sub parts {
  my $self = shift;
  return [
    Email::MIME->create(
      attributes => { charset => 'ISO-2022-JP' },
      body       => Encode::encode('ISO-2022-JP', $self->full_body),
    )
  ];
}

=head2 send

=cut

sub send {
    my $self = shift;
    my $currentuser_object_class = Jifty->app_class("CurrentUser");
    for my $to ( grep {defined} ($self->to, $self->to_list) ) {
        # Can't call method "can" without a package or object reference at /opt/local/lib/perl5/site_perl/5.8.8/Jifty/Notification.pm line 248.
        #if ($to->can('id')) {
        if (ref $to and $to->can('id')) {
        next if     $currentuser_object_class->can("nobody")
                and $currentuser_object_class->nobody->id
                and $to->id == $currentuser_object_class->nobody->id;
                
        next if $to->id == $currentuser_object_class->superuser->id;
        } 
        $self->to($to);
        $self->recipients($to);
        $self->send_one_message(@_);
    }
}

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at bokut.in> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
