package Jaipo::Notify;
use warnings;
use strict;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors (qw/notifier/);

sub new {
	my $class = shift;
	my $arg = shift;	# should be "1" or the module name "Jaipo::Notify::SomeNotify::Module"
	my $self = {};
	bless $self , $class;
	$self->init($arg);
	return $self;
}

sub init {
	my $self = shift;
	my $notify_module = shift;
	$self->notifier( {} );

	if ( not $notify_module ) {		# use default notify module
		if( $^O =~ m/linux/i  ) {
			$notify_module = "Jaipo::Notify::LibNotify";
		} elsif ( $^O =~ m/darwin/i ) {
			$notify_module = "Jaipo::Notify::MacGrwol";
		}
	}

	eval "require $notify_module";
	my $notify = $notify_module->new;

	# save notify object to accessor
	$self->notifier( $notify );
	print "$notify_module Notifier Initialized\n";
}

sub create {
	my ( $self, $args ) = @_;
	$self->notifier->yell( $args->{message} );
}

1;
