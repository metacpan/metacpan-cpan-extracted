package Jaipo;
use utf8;
use warnings;
use strict;
use feature qw(:5.10);
use Jaipo::Config;
use Jaipo::Notify;
use Jaipo::Logger;
use Data::Dumper;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/config/);

use vars qw/$NOTIFY $CONFIG $LOGGER $HANDLER $PUB_SUB @PLUGINS @SERVICES/;

my $debug = 0;

=encoding utf8

=head1 NAME

Jaipo - Micro-blogging Client

=cut

our $VERSION = '0.23';

=head1 DESCRIPTION

Jaipo ( 宅噗 )

This project started for Jaiku.com, but now is going to support
as-much-as-we-can micro-blogging sites.

"Jaiku" pronunced close to "宅窟" in Chinese, which means an area full of
computer/internet users, and it really is one of the most popular sites
recently. As jaiku is part of google and growing, there're still only few linux
client.

it's writen in perl, so it can run on any platform that you can get perl on it.
we got the first feedback that somebody use it on ARM embedded system at May 2008.

=cut

=head1 FUNCTIONS

=head2 new

=cut

sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = {};
	
    # Jaipo::$_->new($args{$_}) for keys %args;
	#~ $self{"UI"}		= Jaipo::UI->new( $args{"ui"} );
	#~ $self{"Notify"}	= Jaipo::Notify->new ( $args{"notify"} );
	#~ $self{"Service"}	= Jaipo::Service->new ( $args{"service"} );
	
	bless $self, $class;
	return $self;
}

=head2 config

return L<Jaipo::Config>

=cut

sub config {
	my $class = shift;
	$CONFIG = shift if (@_);
	$CONFIG ||= Jaipo::Config->new ();
	return $CONFIG;
}

sub notify {
	my $class = shift;
	$NOTIFY ||= Jaipo::Notify->new;
	return $NOTIFY;
}

=head2 services

=cut

sub services {
	my $class = shift;
	@SERVICES = @_ if @_;
	return @SERVICES;
}

sub logger {
	my $class = shift;
	$LOGGER = shift if (@_);
	return $LOGGER;
}

=head2 init CALLER_OBJECT

=cut

sub init {
	my $self   = shift;
	my $caller = shift;

	# Logger turn on
	Jaipo->logger ( Jaipo::Logger->new );

	# prereserve arguments for service plugin
	# my $args = {
	#
	# };
    Jaipo->notify;

	# we initialize service plugin class here
	# Set up plugins
    my @services;
    my @services_to_load = @{ Jaipo->config->app ('Services') };

    my @plugins;
    my @plugins_to_load;

	for ( my $i = 0; my $service = $services_to_load[$i]; $i++ ) {

		# Prepare to learn the plugin class name
		my ($service_name) = keys %{$service};
        say "Jaipo: Init " . $service_name;

		my $class;

		# Is the plugin name a fully-qualified class name?
		if ( $service_name =~ /^Jaipo::Service::/ ) {

            # app-specific plugins use fully qualified names, Jaipo service plugins may
			$class = $service_name;
		}

		# otherwise, assume it's a short name, qualify it
		else {
			$class = "Jaipo::Service::" . $service_name;
		}

		# Load the service plugin options
		my %options = ( %{ $service->{$service_name} } );

		if ( !$options{enable} ) {
			Jaipo->logger->info ( '%s is disabled', $service_name );
			next;
		}

		# Load the service plugin code
		$self->_try_to_require ($class);

        # XXX: if Service don't have trigger_name, we have to do something
        # 
		# Initialize the plugin and mark the prerequisites for loading too
		my $plugin_obj = $class->new (%options);
		$plugin_obj->init ($caller);

		push @services, $plugin_obj;
		foreach my $name ( $plugin_obj->prereq_plugins ) {
			next if grep { $_ eq $name } @plugins_to_load;
			push @plugins_to_load, { $name => {} };
		}

	}

	# All plugins loaded, save them for later reference
	Jaipo->services (@services);

	# XXX: need to implement plugin loader

	# warn "No supported service provider initialled!\n" if not $has_site;

	# when initialize jaipo, there are some new settings that we need to save.
	Jaipo->config->save;
	Jaipo->logger->info ('Configuration saved.');
}

=head2 list_loaded_triggers

=cut

sub list_loaded_triggers {
    my @services = Jaipo->services;
    for my $s (@services) {
        print $s->trigger_name, " => ", ref ($s), "\n";
    }
}

=head2 list_triggers

=cut

sub list_triggers {
	my @service_configs = @{ Jaipo->config->app ('Services') };
	for my $s (@service_configs) {
		my @v = values %$s;
		print $v[0]->{trigger_name}, " => ", join ( q||, keys (%$s) ), "\n";
	}
}

=head2 find_service_by_trigger  TRIGGER_NAME  [ SERVICES ]

=cut

sub find_service_by_trigger {
	my ( $self, $tg, $services ) = @_;
	$services ||= [ Jaipo->services ];
	for my $s (@$services) {
		my $s_tg = $s->trigger_name;
		print "Service: $s_tg\n";
		return $s if $s->trigger_name eq $tg;
	}
}

=head2 _require ( module => MODULE , ... )

=cut

sub _require {
	my $self  = shift;
	my %args  = @_;
	my $class = $args{module};

	return 1 if $self->_already_required ($class);

	my $file = $class;
	$file .= '.pm' unless $file =~ /\.pm$/;
	$file =~ s|::|/|g;

	my $retval = eval { CORE::require "$file" };
	my $error = $@;
	if ( my $message = $error ) {
		$message =~ s/ at .*?\n$//;
		if ( $args{'quiet'} and $message =~ /^Can't locate $file/ ) {
			return 0;
		}
		elsif ( $error !~ /^Can't locate $file/ ) {
			die $error;
		}
		else {
		   #log->error(sprintf("$message at %s line %d\n", (caller(1))[1,2]));
			return 0;
		}
	}
}

=head2 _already_required CLASS_NAME

=cut

sub _already_required {
	my $self  = shift;
	my $class = shift;
	my ($path) = ( $class =~ s|::|/|g );
	$path .= '.pm';
	return $INC{$path} ? 1 : 0;
}

=head2 _try_to_require CLASS_NAME

=cut

sub _try_to_require {
	my $self   = shift;
	my $module = shift;
	$self->_require ( module => $module, quiet => 0 );
}

=head2 find_plugin CLASS_NAME

Find plugins by class name, which is full-qualified class name.

=cut

sub find_plugin {
	my $self    = shift;
	my $name    = shift;
	my @plugins = grep { $_->isa ($name) } Jaipo->plugins;
	return wantarray ? @plugins : $plugins[0];
}

=head2 set_plugin_trigger PLUGIN_OBJECT CLASS

=cut

# this may used by runtime_load_service
sub set_plugin_trigger {
	my ( $self, $plugin_obj, $options, $class, $services ) = @_;

	# give a trigger to plugin obj , take a look.  :p
	my $trigger_name;
	if ( defined $options->{trigger_name} ) {
		$trigger_name = $options->{trigger_name};
	}

	else {
		($trigger_name) = ( $class =~ m/(?<=Service::)(\w+)$/ );
		$trigger_name = lc $trigger_name;    # lower case
	}

	# repeat service trigger name
	while ( my $s
		= $self->find_service_by_trigger ( $trigger_name, $services ) )
	{

		# give an another trigger name for it or ask user
		# TODO: provide a config option to let user set jaipo to ask
		$trigger_name .= '_';
	}

	# set trigger name
	$plugin_obj->trigger_name ($trigger_name);
	print "set trigger: ", $trigger_name, ' for ', $class, "\n";
}

=head2 runtime_load_service  CALLER  SERVICE_NAME [TRIGGER_NAME]

if trigger name is specified, and it doesn't exist in config.
Jaipo will create a new service object, and assign the trigger name to it.

if trigger name is specified, and Jaipo will try to search the service config
by trigger name and load the service.

if trigger name is not specified. Jaipo will try to find service configs
by service name. if there are two or more same service, Jaipo will load the 
default trigger name ( service name in lowcase )

=cut

# XXX: need to re-check logic
sub runtime_load_service {
	my ( $self, $caller, $service_name, $trigger_name ) = @_;

	$trigger_name ||= lc $service_name;
	my $class = "Jaipo::Service::" . ucfirst $service_name;

	my $options = {};
	my @sp_options
		= Jaipo->config->find_service_option_by_trigger ($trigger_name);

	# can not find option , set default trigger name and sp_id
	if ( !@sp_options ) {
		$options->{trigger_name} = $trigger_name;
		my $num_rec = Number::RecordLocator->new;
		$options->{sp_id} = $num_rec->encode ( Jaipo->config->last_sp_cnt );
	}

	elsif ( scalar @sp_options == 1 ) {
		$options = $sp_options[0];
	}

	# XXX:
	# actually won't happen, config loader will canonicalize the config
	# service plugin will get it's default trigger namd from service name.
	else {
	 # find by service name
	 #       elsif ( scalar @sp_options > 1 ) {
	 #           # find service by trigger name
	 #           for my $s (@sp_options) {
	 #               $options = $s if ( $s->{trigger_name} eq $trigger_name );
	 #           }
	 #       }
	}

	# Load the service plugin code
	$self->_try_to_require ($class);

	# Jaipo::ClassLoader->new(base => $class)->require;

	my $plugin_obj = $class->new (%$options);
	$plugin_obj->init ($caller);

	# $self->set_plugin_trigger( $plugin_obj , $class );

	my @services = Jaipo->services;
	push @services, $plugin_obj;
	foreach my $name ( $plugin_obj->prereq_plugins ) {

		# next if grep { $_ eq $name } @plugins_to_load;
		#push @plugins_to_load, {$name => {}};
	}
	Jaipo->services (@services);

   # call save configuration here
   # TODO: this may overwrites other plugins afterload options
   # make sure that user did config jaipo , or we don't need to rewrite config
	Jaipo->config->save;
}

=head2 dispatch_to_service SERVICE_TRIGGER , MESSAGE

command start with C<:[service]> ( e.g. C<:twitter> or C<:plurk> ) something
like that will call the servcie dispatch method,  service plugin will decide
what to do with.

=cut

sub dispatch_to_service {
	print "going to dispatch\n";
	my ( $self, $service_tg, $line ) = @_;
	my $s = $self->find_service_by_trigger ($service_tg);
	print "choosen: $s\n";
    my ($sub_command) = ($line =~ m[^(\w+)] );
    $s->dispatch_sub_command( $sub_command , $line );

}

sub cache_clear {
	my @services = Jaipo->services;
	foreach my $service (@services) {
        if( UNIVERSAL::can( $service , 'get_cache' ) ) {
            my $c = $service->get_cache;
            $c->clear;
        }
	}
}

=head2 action ACTION, PARAM

=cut

sub action {
	my ( $self, $action, $param ) = @_;
	my @services = Jaipo->services;
	print "Services: @services \n" if $debug;
    foreach my $service (@services) {
        if ( UNIVERSAL::can( $service, $action ) ) {
            my $ret = $service->$action($param);
            if ($debug) {
				use Data::Dumper::Simple;
            	warn Dumper( $ret );
			}

            # XXX:
            #  - we should check ret->{type} eq 'notification'
            #  - and call Notify::init
            if ( ref $ret 
                and $ret->{type} eq 'notification' 
                and $ret->{updates} > 0 ) 
            {
                Jaipo->notify->create($ret);
            }
        }
        else {
		warn "Not a supported action.\n";
            # service plugin doesn't support this kind of action
        }
    }

}

=head1 AUTHOR

BlueT - Matthew Lien - 練喆明, C<< <BlueT at BlueT.org> >>
Cornelius, C<< cornelius.howl at gmail.com >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jaipo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Jaipo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Jaipo


You can also look for information at:

=over 4

=item * our main git repository is located at github.com.
	L<https://github.com/BlueT/jaipo>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Jaipo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Jaipo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Jaipo>

=item * Search CPAN

L<http://search.cpan.org/dist/Jaipo/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 BlueT - Matthew Lien - 練喆明.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Jaipo
