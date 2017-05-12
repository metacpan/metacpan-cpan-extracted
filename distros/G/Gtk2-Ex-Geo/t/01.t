use Carp;
use Gtk2::Ex::Geo;
use Gtk2::TestHelper tests => 1;

eval {
    require IPC::Gnuplot;
};
my $have_gnuplot = !$@;

{
    package My::Test::Layer;
    our @ISA = qw(Gtk2::Ex::Geo::Layer);
    sub registration {
	my $class = shift;
	my $registration = $class->SUPER::registration() if $class;
	return $registration;
    }
    sub new {
	my($package) = @_;
	my $self = Gtk2::Ex::Geo::Layer::new($package);
	return $self;
    }
    sub name {
	'test';
    }
    sub world {
	return (0, 0, 100, 100);
    }
    sub render {
	my($self, $pb, $cr, $overlay, $viewport) = @_;
    }
}

ok(1);

if (0) {
    my($window, $gis) = Gtk2::Ex::Geo::simple(classes => [qw/My::Test::Layer/]);
    ok(1);
    
    if ($have_gnuplot) {
	my $gnuplot = IPC::Gnuplot->new();
	$gis->register_function( name => 'plot', object => $gnuplot );
	$gis->register_function( name => 'p', object => $gnuplot );
    }
    
    my $layer = My::Test::Layer->new();
    $gis->add_layer($layer);
    
    $gis->register_commands
	( [ { tag => 'test', 
	      label => 'test',	
	      sub => sub {
		  my(undef, $gui) = @_;
		  croak "test command";
	      } 
	    } ] );
    
    $window->show;
    ok(1);

    $layer->open_symbols_dialog($gis);
    ok(1);

    $layer->open_colors_dialog($gis);
    ok(1);
    $layer->open_labels_dialog($gis);
    ok(1);
    eval {
	$layer->properties_dialog($gis);
    };
    ok($@ =~ /^no properties/);
    $gis->inspect($layer, 'test');
    ok(1);

    eval {
	$layer->open_features_dialog($gis);
    };
    ok($@ =~ /^no features/);
    $gis->message('test');
    ok(1);

    $gis->run_command('zoom to all');
    ok(1);
    eval{
	$gis->run_command('test');
    };
    ok($@ =~ /^test command/);
}
