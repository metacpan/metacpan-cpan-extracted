package Hardware::Vhdl::Automake::UnitName;
# just a holder of information, at the moment
use Carp;

use strict;
use warnings;

sub new { # class or object method, returns a new object
	my $class = shift;
    my $arg1 = shift;
    
    $class = ref $class || $class;
	my $self={
        type => undef,
        library => undef,
        pname => undef,
    };
    
    if (ref $arg1 eq 'HASH') {
        # check required args
        for my $argname (qw/ type library pname /) {
            croak "'$argname' parameter is required for new $class" unless exists $arg1->{$argname};
        }
        croak "'type' parameter to new $class must be package, package body, entity, architecture, configuration, or Verilog unit"
            unless $arg1->{type} =~ m/^(package|package body|entity|architecture|configuration|Verilog unit)$/i;
        if (lc $arg1->{type} eq 'architecture') {
            croak "'sname' parameter is required for new architecture UnitName" if !exists $arg1->{sname};
        } elsif (exists $arg1->{sname}) {
            croak "'sname' parameter is only allowed for architecture UnitNames" if defined $arg1->{sname};
            delete $arg1->{sname};
        }
        # copy args to self
        for my $argname (qw/ type library pname sname /) {
            if (exists $arg1->{$argname}) {
                $self->{$argname} = $arg1->{$argname};
                delete $arg1->{$argname};
            }
        }
        # check there are no passed args left
        if (scalar keys %$arg1) { croak "unrecognised parameter(s) ".join(', ', keys %$arg1)." passed to new UnitName" }
    } elsif (lc $arg1 eq 'architecture' && @_ == 3) {
        $self->{type} = $arg1;
        ($self->{library}, $self->{pname}, $self->{sname}) = @_;
    } elsif (!(ref $arg1) && @_ == 2 || (@_ == 3 || !defined $_[2])) {
        croak "first parameter to new $class must be package, package body, entity, architecture, configuration, or Verilog unit"
            unless $arg1 =~ m/^(package|package body|entity|architecture|configuration|Verilog unit)$/i;
        $self->{type} = $arg1;
        ($self->{library}, $self->{pname}) = @_;
    } else {
        croak "${class}::new should be passed a hashref of information, or a 3 or 4-element list";
    }
    
    # normalise the names, check none is undef
    for my $k (qw/type library pname sname/) {
        if ( exists $self->{$k} ) {
            croak "'$k' parameter to new $class must be defined" unless defined $self->{$k};
            $self->{$k} = lc $self->{$k} unless substr( $self->{$k}, 0, 1 ) eq '\\' ;
        }
    }

	bless $self, $class;
}

# field accessors
sub type { $_[0]->{type} } # returns package, package body, entity, architecture, or configuration
sub library { $_[0]->{library} }
sub pname { $_[0]->{pname} }
sub sname { $_[0]->{sname} }

sub long_string {
    my $self = shift;
    $self->{type}.' '
        .(exists $self->{sname} ? $self->{sname}.' of '.$self->{pname} : $self->{pname})
        .' in library '.$self->{library};
}

sub short_string {
    my $self = shift;
    $self->{type}.' '
        .$self->{library}.'.'
        .$self->{pname}
        .(exists $self->{sname} ? '('.$self->{sname}.')' : '');
}

sub filename_string {
    my $self = shift;
    # convert a design-unit name to a valid and unique file name, preserving the case of the name
    my $file = $self->{type};
    $file =~ s/ /_/g;
    $file .= ' '.&_name2file($self->{library}).' '.&_name2file($self->{pname});
    $file .= ' '.&_name2file($self->{sname}) if exists $self->{sname};
    $file;
}

sub library_dirname_string {
    my $self = shift;
    # convert a library name to a valid and unique directory name with no spaces, preserving the case of the name
    &_name2file($self->{library})
}

sub _name2file {
    my $name = shift;
    croak "name passed to _name2file not defined" unless defined $name;
    # convert a library or design-unit name to a valid and unique directory/file name with no spaces, preserving the case of the name
    $name =~ s/([^A-Za-z0-9_])/sprintf('%%%02x',ord($1))/ge;
    $name =~ s/[A-Z]/\@$1/g;
    lc $name;
}

sub equals {
    my ($s1, $s2) = @_;
    $s1->{type} eq $s2->{type}
    && $s1->{pname} eq $s2->{pname}
    && $s1->{library} eq $s2->{library}
    && (exists $s1->{sname}) == (exists $s2->{sname})
    && ((!exists $s1->{sname}) || ($s1->{sname} eq $s2->{sname}));
}
    
1;