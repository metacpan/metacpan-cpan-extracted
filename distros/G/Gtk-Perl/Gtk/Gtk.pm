package Gtk;

=pod

=head1 NAME

Gtk - Perl module for the Gimp Toolkit library

=head1 SYNOPSIS

	use Gtk '-init';
	my $window = new Gtk::Window;
	my $button = new Gtk::Button("Quit");
	$button->signal_connect("clicked", sub {Gtk->main_quit});
	$window->add($button);
	$window->show_all;
	Gtk->main;
	
=head1 DESCRIPTION

The Gtk module allows Perl access to the Gtk+ graphical user interface
library. You can find more information about Gtk+ on http://www.gtk.org.
The Perl binding tries to follow the C interface as much as possible,
providing at the same time a fully object oriented interface and
Perl-style calling conventions.

You will find the reference documentation for the Gtk module in the
C<Gtk::reference> manpage. There is also a cookbook style manual in
C<Gtk::cookbook>. The C<Gtk::objects> manpage contains a list of
the arguments and signals for each of the classes available in the
Gtk, Gnome and related modules. There is also a list of the flags
and enumerations along with their possible values.

More information can be found on http://www.gtkperl.org.

=head1 AUTHOR

Kenneth Albanowski, Paolo Molaro

=head1 SEE ALSO

perl(1), Gtk::reference(3pm)

=cut

require Exporter;
require DynaLoader;
require AutoLoader;

require Carp;

$VERSION = "0.7010";

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw(
);

sub import {
	my $self = shift;
	foreach (@_) {
		$self->init(),	next if /^-init$/;
		Gtk->set_locale(),	next if /^-locale$/;
	}
}

# use RTLD_GLOBAL
# unfortunately there is no way to know what platforms don't support this from
# within perl...
sub dl_load_flags {$^O =~ /hp/i ? 0: 0x01}

bootstrap Gtk;

# Preloaded methods go here.

@Gtk::Gdk::Bitmap::ISA = qw(Gtk::Gdk::Pixmap);
@Gtk::Gdk::Window::ISA = qw(Gtk::Gdk::Pixmap);

$Gtk::_init_package = "Gtk" if not defined $Gtk::_init_package;

package Gtk::_LazyLoader;

sub isa {
	my($object, $type) = @_;
	my($class);
	no strict;
	$class = ref($object) || $object;
	
	#return 1 if $class eq $type;

	foreach (@{$class . "::_ISA"}, @{$class . "::ISA"}) {
		return 1 if $_ eq $type or $_->isa($type);
	}

	return 0;
}

sub _boot_package {
	my $class = shift;
	no strict;
	if (! @{$class . "::_ISA"} ) {
		foreach my $parent (@{$class . "::ISA"}) {
			_boot_package ($parent);
		}
		return;
	}
	foreach my $parent (@{$class . "::_ISA"}) {
		_boot_package ($parent);
	}
	@{$class . "::ISA"} = @{$class . "::_ISA"};
	undef @{$class . "::_ISA"};
	# warn "Booting $class\n";
	$class =~ tr/:/_/;
	my $sym = DynaLoader::dl_find_symbol_anywhere("boot_$class");
	if ($sym) {
		Gtk::_bootstrap($sym);
	} else {
		# should never happen
		warn "Cannot find boot_$class anywhere\n";
	}
}

sub AUTOLOAD { 
	my($method,$class);
	# warn "Autoloading $AUTOLOAD\n";
	$method = $AUTOLOAD;
	$method =~ s/.*:://;
	$class = ref($_[0]) || $_[0];
	#print "1. Method=$method, object=$object, class=$class\n";

	_boot_package ($class);
	# need to use shift here to avoid creating a new reference to the
	# object when DESTROY happens to be autoloaded
	shift->$method(@_);
}
  
package Gtk::Object;

sub AUTOLOAD {
    # This AUTOLOAD is used to automatically perform accessor/mutator functions
    # for Gtk object data members, in lieu of defined functions.
    
    my($result);
    my ($realname) = $AUTOLOAD;
    $realname =~ s/^.*:://;
    eval {
        my ($argn, $classn, $flags) = $_[0]->_get_arg_info($realname);
	    my $is_readable = $flags->{readable} || $flags->{readwrite};
	    my $is_writable = $flags->{writable} || $flags->{readwrite};
            #print STDERR "GOT ARG: $AUTOLOAD -> $argn ($classn) ", join(' ', keys %{$flags}), " - ",  join(' ', values %{$flags}),"\n";
   
	    if (@_ == 2 && $is_writable) {
	    	$_[0]->set($argn, $_[1]);
	    } elsif (@_ == 1 && $is_readable) {
	    	$result = $_[0]->get($argn);
	    } else {
	    	die;
	    }
	    
	    # Set up real method, to speed subsequent access
	    eval <<"EOT";
	    
	    sub ${classn}::$realname {
	    	if (\@_ == 2 && $is_writable) {
	    		\$_[0]->set('$argn', \$_[1]);
	    	} elsif (\@_ == 1 && $is_readable) {
	    		\$_[0]->get('$argn');
	    	} else {
	    		die "Usage: ${classn}::$realname (Object [, new_value])";
	    	}
	    }
EOT
	    
	};
	if ($@) {
		if (ref $_[0]) {
			$AUTOLOAD =~ s/^.*:://;
			Carp::croak ("Can't locate object method \"$AUTOLOAD\" via package \"" . ref($_[0]) . "\"");
		} else {
			Carp::croak ("Undefined subroutine \&$AUTOLOAD called");
		}
	}
	$result;
}

# Note: $handler and $slot_object are swapped!
sub signal_connect_object {
	my ($obj, $signal, $slot_object, $handler, @data) = @_;

	$obj->signal_connect($signal, sub {
		# throw away the object
		shift; 
		$slot_object->$handler(@_);
	}, @data);
}

sub signal_connect_object_after {
	my ($obj, $signal, $slot_object, $handler, @data) = @_;

	$obj->signal_connect_after($signal, sub {
		# throw away the object
		shift; 
		$slot_object->$handler(@_);
	}, @data);
}

package Gtk::Widget;

sub new {
	my ($class, @args) = @_;
	my ($obj) = Gtk::Object::new(@args);
	$class->add($obj) if ref($class);
	return $obj;
}

sub new_child {return new @_}

package Gtk::CTree;

sub insert_node_defaults {
	my ($ctree, %values) = @_;

	$values{spacing} = 5 unless defined $values{spacing};
	$values{is_leaf} = 1 unless defined $values{is_leaf};
	$values{expanded} = 0 unless defined $values{expanded};
	$values{titles} = $values{text} unless defined $values{titles};
	
	return $ctree->insert_node(@values{qw/parent sibling titles spacing pixmap_closed mask_closed pixmap_opened mask_opened is_leaf expanded/});
}

package Gtk;

if ($Gtk::lazy) {
	require Gtk::TypesLazy;
	Gtk::_bootstrap(DynaLoader::dl_find_symbol_anywhere("boot_Gtk__Object"));
	#Gtk::_LazyLoader::_boot_package('Gtk::Widget');
} else {
	require Gtk::Types;
	&Gtk::_boot_all();
}

sub getopt_options {
	my $dummy;
	return (
		"gdk-debug=s"	=> \$dummy,
		"gdk-no-debug=s"	=> \$dummy,
		"display=s"	=> \$dummy,
		"sync"	=> \$dummy,
		"no-xshm"	=> \$dummy,
		"name=s"	=> \$dummy,
		"class=s"	=> \$dummy,
		"gxid_host=s"	=> \$dummy,
		"gxid_port=s"	=> \$dummy,
		"xim-preedit=s"	=> \$dummy,
		"xim-status=s"	=> \$dummy,
		"gtk-debug=s"	=> \$dummy,
		"gtk-no-debug=s"	=> \$dummy,
		"g-fatal-warnings"	=> \$dummy,
		"gtk-module=s"	=> \$dummy,
	);
}

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__
