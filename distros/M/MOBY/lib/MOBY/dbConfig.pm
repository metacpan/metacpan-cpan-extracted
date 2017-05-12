package MOBY::dbConfig;
use strict;
use Carp;
use vars qw($AUTOLOAD);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use Text::Shellwords;
{

	#Encapsulated class data
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		section_title => [ undef, 'read/write' ],
		username      => [ undef, 'read/write' ],
		password      => [ undef, 'read/write' ],
		dbname        => [ undef, 'read/write' ],
		port          => [ undef, 'read/write' ],
		proxy         => [ undef, 'read/write' ],
		adaptor => [ "MOBY::Adaptor::moby::queryapi::mysql", 'read/write' ],
		url     => [ undef,                                  'read/write' ],
		section => [ undef,                                  'read/write' ],
	  );

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

	sub database_title {
		my ( $self, $val ) = @_;
		$self->section_title($val) if $val;
		return $self->section_title;
	}
}

# this object will contain the full hash of what is in the config file, even if
# the key/value pairs are not expected.  Only the expected key/value pairs will be available as
# methods, however (i.e. those in the _standard_keys hash above)
sub new {
	my ( $caller, %args ) = @_;
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
	my $key;

	#eval {$key = $self->_readSections($self->section);};
	$key = $self->_readSections( $self->section );

   #if ($@){die "MOBY Configuration file is misconfigured: dbConfig line 71\n";}
   #print STDERR "I received the key $key\n";
	return undef unless $key;
	return undef unless $key =~ /\S/;

	#print STDERR "returning the dbConfig object for database title $key\n";
	$self->section_title($key);
	return $self;
}

sub _readSections {
	my ( $self, $section ) = @_;
	my $key;
	my @lines = split "\n", $section;
	while ( my $l = shift @lines ) {
		chomp $l;
		next unless $l;
		next if $l =~ /\s*\#/;    # ignore comments
		next unless $l =~ /\S/;   # ignore pure whitespace;

		#print STDERR "reading line $l\n";
		if ( $l =~ /\[(\w+)\]/ ) {
			$key = $1;
			while ( my $l2 = shift @lines ) {
				chomp $l2;
				last unless ( $l2 =~ /\S/ );
				my @terms = shellwords($l2);
				last unless ( scalar @terms >= 2 );
				$self->{ $terms[0] } = $terms[2];
			}
		}
	}

   #print STDERR "returning key $key with terms ",(keys %{$self->{$key}})," \n";
	return $key;    # will be undef if this was not a valid section
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
