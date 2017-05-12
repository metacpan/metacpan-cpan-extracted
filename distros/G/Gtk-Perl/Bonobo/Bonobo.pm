

package Bonobo;

require Gnome;
require Exporter;
require DynaLoader;
require AutoLoader;
use CORBA::ORBit 
	defines => "-D__ORBIT_IDL__ -D__BONOBO_COMPILATION",
	idl_path => "/usr/share/idl:/usr/local/share/idl:/opt/idl", 
	idl => ['Bonobo.idl'];

require Carp;

$VERSION = "0.7010";

my $orb =  CORBA::ORB_init("orbit-local-orb");
my $poa = $orb->resolve_initial_references("RootPOA");

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
        
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw(
);

require Bonobo::Types;

sub dl_load_flags {Gtk::dl_load_flags()}

bootstrap Bonobo $VERSION;

# Autoload methods go after __END__, and are processed by the autosplit program.

sub getopt_options {
	my $dummy;
	return (
		"oaf-od-ior=s"	=> \$dummy,
		"oaf-ior-fd=i"	=> \$dummy,
		"oaf-activate-iid=s"	=> \$dummy,
		"oaf-private"	=> \$dummy,
		);
}

# perl-side interface implementations
my $ListenerId = 0;

package Bonobo::UnknownImpl;
@ISA = "POA_".CORBA::ORBit::find_interface("IDL:Bonobo/Unknown:1.0");

sub new {
	my ($class, @attrs) = @_;
	my $self = bless {__repoid => $class->_porbit_repoid, @attrs}, $class;
	return $self;
}

# do we actually need to ref/unref here? What about objects we haven't created?
sub ref { }

sub unref { }

sub queryInterface {
	my ($self, $repo) = @_;
	if (!defined($repo) || $repo eq $self->{__repoid}) {
		return $self->{__object} if exists $self->{__object};
		my $id = $poa->activate_object ($self);
		return $self->{__object} = $poa->id_to_reference ($id);
	}
	foreach my $child (@{$self->{__objects}}) {
		my $ref = $child->queryInterface($repo);
		return $ref if defined $ref;
	}
	return undef;
}

package Bonobo::ListenerImpl;
@ISA = ("POA_".CORBA::ORBit::find_interface("IDL:Bonobo/Listener:1.0"), 'Bonobo::UnknownImpl');

sub event {
	my ($self, $event_name, $any) = @_;
	Carp::carp "$self received event '$event_name': you need to provide your own event handler";
}

package Bonobo::EventSourceImpl;
@ISA = ("POA_".CORBA::ORBit::find_interface("IDL:Bonobo/EventSource:1.0"), 'Bonobo::UnknownImpl');

sub addListener {
	$_[0]->addListenerWithMask($_[1]);
}

sub addListenerWithMask {
	my ($self, $listener, $event_mask) = @_;
	$ListenerId++;
	$self->{__listeners}->{$ListenerId} = $listener;
	if (defined $event_mask) {
		$self->{__emasks}->{$ListenerId} = [split(/,/,$event_mask)]
	}
	return $ListenerId;
}

sub removeListener {
	my ($self, $id) = @_;
	my $ref = delete $self->{__listeners}->{$id};
	# raise exception unless defined($ref);
}

# for use in perl, not a function in the interface
sub notify {
	my ($self, $event, $val) = @_;
	foreach my $id (keys %{$self->{__listeners}}) {
		my $listener = $self->{__listeners}->{$id};
		if (!exists $self->{__emasks}->{$id}) {
			$listener->event($event, $val);
		} else {
			# implement the same undocumented way the C version uses
			foreach my $m (@{$self->{__emasks}->{$id}}) {
				if ($m =~ /^=/ && $event eq substr($m, 1)) {
					$listener->event($event, $val);
					next;
				} elsif ($m eq substr($event, 0, length($m))) {
					$listener->event($event, $val);
				}
			}
		}
	}
}

package Bonobo::PropertyImpl;
@ISA = ("POA_".CORBA::ORBit::find_interface("IDL:Bonobo/Property:1.0"), 'Bonobo::UnknownImpl');

sub addListener {
	my ($self, $listener) = @_;
	$ListenerId++;
	$self->{__listeners}->{$ListenerId} = $listener;
	return $ListenerId;
}

sub removeListener {
	my ($self, $id) = @_;
	my $ref = delete $self->{__listeners}->{$id};
	# raise exception unless defined($ref);
}

# the default is a string
sub getType {
	my $self = shift;
	exists ($self->{__any}) ? $self->{__any}->type : CORBA::TypeCode->new('IDL:CORBA/String:1.0');
}

sub getName {
	return $_[0]->{__name};
}

sub getDocString {
	return $_[0]->{__docstring};
}

sub getValue {
	my $self = shift;
	return $self->{__any};
}

sub getFlags {return 6}

package Bonobo::PropertyBagImpl;
@ISA = ("POA_".CORBA::ORBit::find_interface("IDL:Bonobo/PropertyBag:1.0"), 'Bonobo::UnknownImpl');

# make autosplit happy
package Bonobo;
1;
__END__
