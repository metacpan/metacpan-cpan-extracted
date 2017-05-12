# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen;

use Carp;
use Storable;
use common::sense;

our $VERSION = '1.5008';

our $AUTOLOAD;

our %opp  = (n=>"s", e=>"w", s=>"n", w=>"e");
our %full = (n=>"north", e=>"east", s=>"south", w=>"west");

# known_opts {{{
our %known_opts = (
    generator              => "Basic",
    exporter               => "Text",
    bounding_box           => "50x50",
    tile_size              => 10,
    cell_size              => "20x20",

    nocolor => 0, # for the text map generator

    num_rooms              => "1d4+1",
    min_room_size          => "2x2",
    max_room_size          => "7x7",

    sparseness             => 10,
          same_way_percent => 90,
         same_node_percent => 30,
    remove_deadend_percent => 60,
);
# }}}

# _check_mod_path {{{
sub _check_mod_path  {
    my $this = shift;
    my $omod = shift;
       $omod =~ s/\:\:/\//g;

    for my $mod ($omod, map {$_ . "::$omod"} "Games::RolePlay::MapGen::Generator", "Games::RolePlay::MapGen::GeneratorPlugin",
            "Games::RolePlay::MapGen::Exporter", "Games::RolePlay::MapGen::ExporterPlugin") {

        return $mod if eval "require $mod";
    }

    return;
}
# }}}
# _check_opts {{{
sub _check_opts {
    my $this = shift;
    my @e    = ();

    # warn "checking known_opts";
    for my $k (keys %known_opts) {
        "set_$k"->($this, $known_opts{$k} ) unless defined $this->{$k};
    }

    for my $k ( keys %$this ) {
        unless( exists $known_opts{$k} ) {
            next if $k eq "objs";
            next if $k eq "_the_map";
            next if $k eq "_the_groups";

            push @e, "unrecognized option: '$k'";
        }
    }

    return "ERROR:\n\t" . join("\n\t", @e) . "\n" if @e;
    return;
}
# }}}

# AUTOLOAD {{{
sub AUTOLOAD {
    my $this = shift;
    my $sub  = $AUTOLOAD;

    # sub set_generator
    # sub set_exporter

    if( $sub =~ m/MapGen\:\:set_(generator|exporter)$/ ) {
        my $type = $1;
        my $modu = shift;

        delete $this->{objs}{$type} if $this->{objs}{$type};

        my $module = "Games::RolePlay::MapGen::" . (ucfirst $type) . "::$modu";
        croak "Couldn't locate module \"$modu\" during execution of $sub() $@" unless eval { "require $module" };

        # NOTE: why does this not have {objs}? 5/12/8
        $this->{$type} = $module;

        return;

    } elsif( $sub =~ m/MapGen\:\:add_(generator|exporter)_plugin$/ ) {
        my $type = $1;
        my $plug = shift;

        my $newn = "Games::RolePlay::MapGen::" . (ucfirst $type) . "Plugin::$plug";
        croak "Couldn't locate module \"$plug\" during execution of $sub()" unless eval { "require $newn" };

        push @{ $this->{plugins}{$type} }, $newn;

        return;

    } elsif( $sub =~ m/MapGen\:\:set_([\w\d\_]+)$/ ) {
        my $n = $1;

        croak "ERROR: set_$n() unknown setting during execution of $sub()" unless exists $known_opts{$n};

        $this->{$n} = shift;

        for my $o (qw(generator exporter)) {
            if( my $oo = $this->{objs}{$o} ) {

                # NOTE: how does this->{$n} relate to this->{objs}{$n} ... 5/12/8
                $oo->{o}{$n} = $this->{$n};
            }
        }

        return;
    }

    croak "ERROR: function $sub() not found";
}
sub DESTROY {}
# }}}
# new {{{
sub new {
    my $class = shift;
    my @opts  = @_;
    my $opts  = ( (@opts == 1 and ref($opts[0]) eq "HASH") ? {%{$opts[0]}} : {@opts} );
    my $this  = bless $opts, $class;

    if( my $e = $this->_check_opts ) { croak $e }

    return $this;
}
# }}}

# save_map {{{
sub save_map {
    my $this     = shift;
    my $filename = shift;

    $this->{_the_map}->disconnect_map;

    my $str;
    if( $filename ) {
        Storable::store($this, $filename);

    } else {
        $str = Storable::freeze($this);
    }

    $this->{_the_map}->interconnect_map;

    return $str;
}
# }}}
# load_map {{{
sub load_map {
    my $this     = shift;
    my $filename = shift;

    if( -f $filename ) {
        eval { %$this = %{ Storable::retrieve( $filename ) } }
            or die "ERROR while evaluating saved map from file: $@";

    } else {
        eval { %$this = %{ Storable::thaw( $filename ) } }
            or die "ERROR while evaluating saved map from string: $@";
    }

    require Games::RolePlay::MapGen::Tools; # This would already be loaded if we were the blessed ref that did the saving
    $this->{_the_map}->interconnect_map;    # bit it wouldn't be loaded otherwise!
}
# }}}
# legacy_load_map {{{
sub legacy_load_map {
    my $this     = shift;
    my $filename = shift;

    open my $load, "$filename" or die "couldn't open $filename for read: $!";
    local $/ = undef;
    my $entire_file = <$load>;
    close $load;

    eval $entire_file;
    die "ERROR while evaluating saved map: $@" if $@;

    require Games::RolePlay::MapGen::Tools; # This would already be loaded if we were the blessed ref that did the saving
    $this->{_the_map}->interconnect_map;    # bit it wouldn't be loaded otherwise!
}
# }}}
# generate {{{
sub generate {
    my $this = shift;
    my $err;

    __MADE_GEN_OBJ:
    if( my $gen = $this->{objs}{generator} ) {
        my $new_opts;

        ($this->{_the_map}, $this->{_the_groups}, $new_opts) = $gen->go( @_ );

        if( $new_opts and keys %$new_opts ) {
            for my $k (keys %$new_opts) {
                $this->{$k} = $new_opts->{$k};
            }
        }

        return;

    } else {
        die "ERROR: problem creating new generator object" if $err;
    }

    eval qq( require $this->{generator} ); 
    croak "ERROR locating generator module:\n\t$@\n " if $@;

    my $obj;
    my @opts = map(($_=>$this->{$_}), grep {defined $this->{$_} and $_ ne "objs"  and $_ ne "plugins" } keys %$this);

    eval qq( \$obj = new $this->{generator} (\@opts); );
    if( $@ ) {
        die   "ERROR generating generator:\n\t$@\n " if $@ =~ m/ERROR/;
        croak "ERROR generating generator:\n\t$@\n " if $@;
    }

    $obj->add_plugin( $_ ) for @{ $this->{plugins}{generator} };

    $this->{objs}{generator} = $obj;
    $err = 1;

    $this->_check_opts; # plugins, generators and exporters can add default options

    goto __MADE_GEN_OBJ;
}
# }}}
# export {{{
sub export {
    my $this = shift;
    my $err;

    __MADE_VIS_OBJ:
    if( my $vis = $this->{objs}{exporter} ) {

        return $vis->go( _the_map => $this->{_the_map}, _the_groups => $this->{_the_groups}, (@_==1 ? (fname=>$_[0]) : @_) );

    } else {
        die "problem creating new exporter object" if $err;
    }

    eval qq( require $this->{exporter} );
    croak "ERROR locating exporter module:\n\t$@\n " if $@;

    my $obj;
    my @opts = map(($_=>$this->{$_}), grep {defined $this->{$_} and $_ ne "objs"  and $_ ne "plugins" } keys %$this);

    eval qq( \$obj = new $this->{exporter} (\@opts); );
    if( $@ ) {
        die   "ERROR generating exporter:\n\t$@\n " if $@ =~ m/ERROR/;
        croak "ERROR generating exporter:\n\t$@\n " if $@;
    }

    $this->{objs}{exporter} = $obj;
    $err = 1;

    $this->_check_opts; # plugins, generators and exporters can add default options

    goto __MADE_VIS_OBJ;
}
# }}}

# import_xml {{{
sub import_xml {
    my $this = shift;
    my $that = shift; croak "no such file that=$that" unless -f $that;

    $this = $this->new unless ref $this;

    $this->set_generator( "XMLImport" );
    if( -f $that ) {
        $this->generate( xml_input_file => $that, @_ );

    } else {
        $this->generate( xml_input      => $that, @_ );
    }
    $this;
}
# }}}
# sub_map {{{
sub sub_map {
    my $this = shift;
    my $that = shift; croak "that's not a map" unless ref $that;
    my $ul   = shift; croak "upper left should be an arrayref two tuple" unless 2==eval {@$ul};
    my $lr   = shift; croak "lower right should be an arrayref two tuple" unless 2==eval {@$lr};

    $this = $this->new unless ref $this;
    $this->set_generator( "SubMap" );
    $this->generate( map_input => $that, upper_left=>$ul, lower_right=>$lr );
    $this;
}
# }}}
# size {{{
sub size {
    my $this = shift;
    my $map  = $this->{_the_map};

    my $x = @{$map->[0]};
    my $y = @$map;

    return ($x, $y) if wantarray;
    return [$x, $y];
}
# }}}

# {{{ FREEZE_THAW_HOOKS
FREEZE_THAW_HOOKS: {
    my $going;
    sub STORABLE_freeze {
        return if $going;
        my $this = shift;
        $going = 1;
        my $str = $this->save_map;
        $going = 0;
        return $str;
    }

    sub STORABLE_thaw {
        my $this = shift;
        $this->load_map($_[1]);
    }
}

# }}}

1;

__END__
