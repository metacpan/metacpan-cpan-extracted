package Jaipo::Config;
use warnings;
use strict;
use Hash::Merge;
use YAML::Syck;
Hash::Merge::set_behavior ('RIGHT_PRECEDENT');
use Number::RecordLocator;

use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors (qw/stash last_sp_cnt/);

use vars qw/$CONFIG/;

sub new {
	my $class = shift;
	my %args = @_;

	my $self = {};
	bless $self , $class;
	$self->stash( {} );
    $self->last_sp_cnt ( 500000 + int( rand 100 ) );
	$self->load;
	return $self;
}

sub app_config_path {
	my $self = shift;

	# XXX: get application config path for different platform
	# windows , unix	or ...
	return $ENV{HOME} . '/.jaipo.yml';
}

sub app { return shift->_get( application => @_ ) }

sub user { return shift->_get( user => @_ ) }

# A teeny helper
sub _get { return $_[0]->stash->{ $_[1] }{ $_[2] } }


sub save {
	my  $self  = shift;
	my  $config_filepath = shift || $self->app_config_path;

	open CONFIG_FH , ">" , $config_filepath;
	print CONFIG_FH Dump( $self->stash );
	close CONFIG_FH;
}


sub set_service_option {
	my $self = shift;
	my $sp_name = shift;
	my $opt = shift;

	my $new_config = $self->stash;
	my @sps = @{ $self->app('Services') };
	for( my $i=0; my $sp = $sps[ $i ] ; $i++ ) {
		my $c_spname = join q{},keys %{ $sps[$i] } ;

        if( $c_spname eq $sp_name 
                      and $sp->{ $c_spname }->{sp_id} eq $opt->{sp_id} ) 
        {
            $new_config->{application}{Services}->[$i]->{ $c_spname } = $opt
        }
	}
	$self->stash( $new_config );
}

=head2 find_service_option_by_name

Returns a config hash

=cut

sub find_service_option_by_name {
	my $self = shift;
	my $name = shift;
	my @services = @{ $self->app ('Services') };

	# @services = grep { $name eq shift keys $_ }, @services;

	my @configs = ();
	map { my ($p)=keys %$_; 
			push @configs,values %$_ 
			if $p =~ m/\Q$name/ } @services;
	return wantarray ? @configs : $configs[0];
}


=head2 find_service_option_by_trigger

in list context , returns an array of one or more service plugin
config hash.
in scalar contxt , returnes a config hash

=cut

sub find_service_option_by_trigger {
	my $self = shift;
	my $trigger = shift;
	my @services = @{ $self->app ('Services') };

	# @services = grep { $name eq shift keys $_ }, @services;

	my @configs = ();
	map { 
      my ($v)=values %$_;
			push @configs,$v 
              if $v->{trigger_name} eq $trigger;
                  } @services;
	return wantarray ? @configs : $configs[0];
}



=head2 load

=cut

sub load {
	my $self = shift;
	my $config_filepath = shift || $self->app_config_path;

	# if we can not find yml config file
	# load from default function , then write back to config file
	my $config;

	if ( -e $config_filepath ) {  # XXX: check config version
		$config = LoadFile( $config_filepath );
		$self->stash ($config);
	} 
	else {
		$config = $self->load_default_config;
		$self->stash ($config);
		# write back
		$self->save( $config_filepath );
	}

    # Canicalization
    $self->set_sp_id;
    $self->set_default_trigger_name;

	# load user jaipo yaml config from file here
	return $config;
}

sub set_default_trigger_name {
    my $self = shift;
	my $new_config = $self->stash;
	my @sps = @{ $self->app('Services') };

    # set default trigger name for each service plugin that has no trigger name
    my %triggers;
	for( my $i=0; my $sp = $sps[$i] ; $i++ ) {
		my $c_spname = join q{},keys %{ $sp } ;

        my $tn = lc $c_spname;
        $tn .= '_' while( exists $triggers{ $tn } );

		$new_config->{application}{Services}->[$i]->{ $c_spname }->{trigger_name} ||= $tn;
        $triggers{ $new_config->{application}{Services}->[$i]->{ $c_spname }->{trigger_name} } = 1;
	}

	$self->stash( $new_config );
}

sub set_sp_id {
    my $self = shift;
    my $sp_cnt =  $self->last_sp_cnt;
	my $new_config = $self->stash;
	my @sps = @{ $self->app('Services') };
    my $num_rec = Number::RecordLocator->new;
	for( my $i=0; $i < scalar @sps ; $i++ ) {
		my $c_spname = join q{},keys %{ $sps[$i] } ;

		if( ! defined $new_config->{application}{Services}->[$i]->{ $c_spname }->{sp_id} ) {
            my $sp_id = $num_rec->encode( $sp_cnt ++ );
            $new_config->{application}{Services}->[$i]->{ $c_spname }->{sp_id} = $sp_id;
            $self->last_sp_cnt( $sp_cnt );
        }
	}
	$self->stash( $new_config );
}

sub load_default_config {

	# move this to a file later
	my $config = <<YAML;
---
application:
    Verbose: 1
    SavePassword: 0
    Services:
        - Twitter:
            enable: 1
    Plugins: {}
user: {}

YAML
	return Load( $config );

}

1;
