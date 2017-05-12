# 

package Log::Dispatch::MacGrowl::Cocoa;

use strict;
use vars qw($VERSION);
use Cocoa::Growl ();

$VERSION = '0.01';

sub log_message {
    my $self = shift;
    my %p = @_;

    Cocoa::Growl::growl_notify(
	name => $self->_notification_name,
	icon => $self->{icon_file},
	sticky => $self->{sticky},
	priority => $self->{priority},
	title => $self->{title},
	description => $p{message},
    );
}

sub _set_global {
    my $self = shift;

    Cocoa::Growl::growl_register(
	app => $self->{app_name},
	notifications => [ $self->_notification_name ],
    );
}

1;

__END__

=head1 NAME

Log::Dispatch::MacGrowl::Cocoa - Cocoa::Growl backend for L::D::MacGrowl

=head1 DEPENDENCY

Cocoa::Growl

=head1 AUTHOR

Ryo Okamoto C<< <ryo at aquahill dot net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2010 Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
