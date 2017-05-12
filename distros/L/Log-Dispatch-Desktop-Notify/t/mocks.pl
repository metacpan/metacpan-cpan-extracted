use Mock::Quick;

our $last_notification;

our $notification_mock = qclass(
    -implement => 'Desktop::Notify::Notification',
    -with_new => 1,
    -attributes => [ qw( summary timeout ) ],
    show => sub {
	my $self = shift;
	$last_notification = $self;
    }
    );

our $notify_mock = qclass(
    -implement => 'Desktop::Notify',
    -with_new => 1,
    -attributes => [ qw( app_name ) ],
    create => sub {
	my $self = shift;
	return Desktop::Notify::Notification->new(@_);
    }
    );

1;
