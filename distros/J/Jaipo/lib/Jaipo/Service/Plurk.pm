package Jaipo::Service::Plurk;
use warnings;
use strict;
use WWW::Plurk;
use base qw/Jaipo::Service Class::Accessor::Fast/;
use utf8;

# XXX:
# www-plurk module can not work!! hate!!

sub init {
	my $self   = shift;
	my $caller = shift;
	my $opt = $self->options;

	unless( $opt->{username} and $opt->{password} ) {

		# request to setup parameter
		# XXX TODO: we need to simplify this, let it like jifty dbi schema  or
		# something
		$caller->setup_service ( {
				package_name => __PACKAGE__,
				require_args => [ {
						username => {
							label       => 'Username',
							description => '',
							type        => 'text'
						}
					},
					{   password => {
							label       => 'Password',
							description => '',
							type        => 'text'
						} } ]
			},
			$opt
		);
	}

	Jaipo->config->set_service_option( 'Plurk' , $opt );

	my $plurk = new WWW::Plurk;

	unless( $plurk ) {
		# XXX: need to implement logger:  Jaipo->log->warn( );
		print "plurk init failed\n";
	}

	$plurk->login(  $opt->{username} , $opt->{password}  );

	$self->core( $plurk );
}


sub send_msg {
	my ( $self , $message ) = @_;
    print "Sending to Plurk...";
	my $result = $self->core->add_plurk( content => $message );
    print "Done\n";
}

# updates from user himself
sub read_user_timeline {
    my $self = shift;
    my @plurks = $self->plurks;
    for ( @plurks ) {
      # XXX: make this work with text::table::zh
      printf "%s %s %s",$_->{uid}, $_->{date_from}, $_->{date_offset};
    }
}

# updates from user's friends or channel
sub read_public_timeline {
    my $self = shift;
}


sub read_global_timeline {
    my $self = shift;

}




1;
