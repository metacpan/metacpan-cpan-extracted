#$Id: Config.pm,v 1.5 2008/09/02 13:14:18 kawas Exp $

=head1 NAME

MOBY::Config.pm - An object containing information about how to get access to teh Moby databases, resources, etc. from the 
mobycentral.config file

=cut


=head2 USAGE

  $CONF = MOBY::Config->new();

  # for fields in the mobycentral.config file, use the section name
  # as the first object, then the item name as the hash-hey within that
  # object.
  # i.e.    $CONF->mobycentral returns a MOBY::dbConfig representing the
  # [mobycentral] part of the mobycentral.config file

  $centraluser = $CONF->mobycentral->{username}
  $centralpass = $CONF->mobycentral->{password}
  $objectuser =  $CONF->mobyobject->{username}

  $ADAPTOR = $CONF->getDataAdaptor(source => 'mobyobject');
  # $ADAPTOR is probably a MOBY::adaptor::queryapi::mysql object

  my $dbh = $ADAPTOR->dbh();
  my $sth = $object_dbh->prepare("select description from object where object_type = ?");
  $sth->execute("GenericSequence");

=cut


package MOBY::Config;

BEGIN {}
use strict;
use Carp;
use MOBY::dbConfig;
use vars qw($AUTOLOAD);
use Text::Shellwords;
use vars '$VERSION', '@ISA', '@EXPORT', '$CONFIG';

$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

@ISA    = qw(Exporter);
@EXPORT = ('$CONFIG');
{

	my %_attr_data =    #         DEFAULT    	ACCESSIBILITY
	  (
		mobycentral      => [ undef, 'read/write' ],
		mobyobject       => [ undef, 'read/write' ],
		mobynamespace    => [ undef, 'read/write' ],
		mobyservice      => [ undef, 'read/write' ],
		mobyrelationship => [ undef, 'read/write' ],
		valid_secondary_datatypes => [["String", "Integer", "DateTime", "Float", "Boolean"],  'read'],
		primitive_datatypes => [["String", "Integer", "DateTime", "Float", "Boolean"], 'read'],

	  );

	my $file = $ENV{MOBY_CENTRAL_CONFIG};
	( -e $file ) || die "MOBY Configuration file $file doesn't exist $!\n";
	chomp $file;
	if ( ( -e $file ) && ( !( -d $file ) ) ) {
	    open IN, $file
		or die
		"can't open MOBY Configuration file $file for unknown reasons: $!\n";
	}
	my @sections = split /(\[\s*\S+\s*\][^\[]*)/s, join "", <IN>;

	#print STDERR "split into @sections\n";
	foreach my $section (@sections) {

		#print STDERR "calling MOBY::dbConfig\n";
		my $dbConfig =
		  MOBY::dbConfig->new( section => $section )
		  ; # this is an object full of strings, no actual connections.  It represents the information in the config file
		next unless $dbConfig;
		my $dbname = $dbConfig->section_title;
		next unless $dbname;
		$_attr_data{$dbname} = [$dbConfig, 'read'];  # something like $_attr_data{mobycentral} = [$config, 'read']
	}

	#Encapsulated class data
	#___________________________________________________________
	#ATTRIBUTES

	#_____________________________________________________________
	# METHODS, to operate on encapsulated class data
	# Is a specified object attribute accessible in a given mode
	sub _accessible {
		my ( $self, $attr, $mode ) = @_;
		$_attr_data{$attr}[1] =~ /$mode/;
	}

	# Classwide default value for a specified object attribute
	sub _default_for {
		my ( $self, $attr ) = @_;
		$_attr_data{$attr}[0];
	}

	# List of names of all specified object attributes
	sub _standard_keys {
		keys %_attr_data;
	}
}

# the expected sections (listed above) will have their dbConfig objects available
# as methods.  The unexpected sections will have their dbConfig objects available
# by $dbConfig = $CONFIG->{section_title}
sub new {
	my ( $caller, %args ) = @_;

	#print STDERR "creating MOBY::Config\n";
	my $caller_is_obj = ref($caller);
	my $class         = $caller_is_obj || $caller;
	my $self          = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} && defined $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ($caller_is_obj) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for($attrname);
		}
	}
#	return $self if $self->mobycentral->{'dbname'};  # if it has been set, then just return it
#print STDERR "setting the COnfig dbConfig for the title $dbname with object $dbConfig\n\n";
	$CONFIG = $self;
	return $self;
}

sub getDataAdaptor {
	my ( $self, %args ) = @_;
	my $source = $args{datasource} || $args{source} || "mobycentral";
	if ( $self->{"${source}Adaptor"} ) { return $self->{"${source}Adaptor"} }
	;    # read from cache
	my $username = $self->$source->{username};# $self->$source returns a MOBY::dbConfig object
	my $password = $self->$source->{password};
	my $port     = $self->$source->{port};
	my $dbname   = $self->$source->{dbname};
	my $url      = $self->$source->{url};
	my $adaptor  = $self->$source->{adaptor};
	eval "require $adaptor";
	return undef if $@;
	my $ADAPTOR = $adaptor->new(    # by default, this is queryapi::mysql
					 username => $username,
					 password => $password,
					 port     => $port,
					 dbname   => $dbname,
					 url      => $url,
	);
	if ($ADAPTOR) {
		$self->{"${source}Adaptor"} = $ADAPTOR;    # cache it
		return $ADAPTOR;
	} else {
		return undef;
	}
}
sub DESTROY { }

sub AUTOLOAD {
	no strict "refs";
	my ( $self, $newval ) = @_;
	$AUTOLOAD =~ /.*::(\w+)/;
	my $attr = $1;
	if ( $self->_accessible( $attr, 'write' ) ) {
		*{$AUTOLOAD} = sub {
			if ( defined $_[1] ) { $_[0]->{$attr} = $_[1] }
			return $_[0]->{$attr};
		};    ### end of created subroutine
###  this is called first time only
		if ( defined $newval ) {
			$self->{$attr} = $newval;
		}
		return $self->{$attr};
	} elsif ( $self->_accessible( $attr, 'read' ) ) {
		*{$AUTOLOAD} = sub {
			return $_[0]->{$attr};
		};    ### end of created subroutine
		return $self->{$attr};
	}

	# Must have been a mistake then...
	croak "No such method: $AUTOLOAD";
}
1;
