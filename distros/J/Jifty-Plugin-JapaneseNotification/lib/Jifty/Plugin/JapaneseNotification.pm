package Jifty::Plugin::JapaneseNotification;

use warnings;
use strict;

use base qw/Jifty::Plugin/;

our $VERSION = '0.01';

=encoding utf8

=head1 NAME

Jifty::Plugin::JapaneseNotification - Send emails from Jifty with Japanese character code

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

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at bokut.in> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Jifty::Plugin::JapaneseNotification
