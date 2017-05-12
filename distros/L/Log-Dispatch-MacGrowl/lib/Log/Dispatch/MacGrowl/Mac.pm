# 

package Log::Dispatch::MacGrowl::Mac;

use strict;
use vars qw($VERSION);
use Mac::Growl ();

$VERSION = '0.01';

sub log_message {
    my $self = shift;
    my %p = @_;

    Mac::Growl::PostNotification( $self->{app_name}, $self->_notification_name,
	$self->{title}, $p{message},
	$self->{sticky}, $self->{priority}, $self->{icon_file} );
}

sub _set_global {
    my $self = shift;

    my $global = [ $self->_notification_name ];
    Mac::Growl::RegisterNotifications( $self->{app_name}, $global, $global );
}

1;

__END__

=head1 NAME

Log::Dispatch::MacGrowl::Mac - Mac::Growl backend for L::D::MacGrowl

=head1 DEPENDENCY

Mac::Growl

=head1 AUTHOR

Ryo Okamoto C<< <ryo at aquahill dot net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2010 Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
