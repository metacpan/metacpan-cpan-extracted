# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::Generator;

use common::sense;
use Carp;

our @ISA;

1;

# new {{{
sub new {
    my $class = shift;
    my $this  = bless {o => {@_}}, $class;

    $this->{plugins} = {
         pre => [ ], # after the entire map is built, this executes on the topnode (before treasure and traps are added)

        trap => [ ],
        door => [ ],
        encr => [ ],
        tres => [ ],

        post => [ ], # after the entire map is built and treasure traps and doors are added
    };

    return $this;
}
# }}}
# gen_opts {{{
sub gen_opts {
    my $this = shift;
    my $opts = {@_};

    for my $k (keys %{ $this->{o} }) {
        $opts->{$k} = $this->{o}{$k} if not exists $opts->{$k};
    }

    return $opts;
}
# }}}
# go {{{
sub go {
    my $this = shift;
    my $opts = $this->gen_opts(@_);

    $this->gen_bounding_size( $opts );

    croak "ERROR: bounding_box is a required option for " . ref($this) . "::go()" unless $opts->{x_size} and $opts->{y_size};
    croak "ERROR: num_rooms is a required option for " . ref($this) . "::go()" unless $opts->{num_rooms};

    $opts->{min_room_size} = "2x2" unless $opts->{min_room_size};
    $opts->{max_room_size} = "9x9" unless $opts->{max_room_size};

    croak "ERROR: room sizes are of the form 9x9, 3x10, 2x2, etc" unless $opts->{min_room_size} =~ m/^\d+x\d+$/ and $opts->{max_room_size} =~ m/^\d+x\d+$/;

    my ($map, $groups) = $this->genmap( $opts );

    my $changed_options = $this->post_genmap( $opts, $map, $groups );

    return ($map, $groups, $changed_options);
}
# }}}
# gen_bounding_size {{{
sub gen_bounding_size {
    my $this = shift;
    my $opts = shift;

    if( $opts->{bounding_box} ) {
        die "ERROR: illegal bounding box description '$opts->{bounding_box}'" unless $opts->{bounding_box} =~ m/^(\d+)x(\d+)/;
        $opts->{x_size} = $1;
        $opts->{y_size} = $2;
    }
}
# }}}
# post_genmap  {{{
sub post_genmap  {
    my $this = shift;
    my ($opts, $map, $groups) = @_;

    $this->pre( $opts, $map, $groups );

    $this->doorgen(      $opts, $map, $groups );
    $this->trapgen(      $opts, $map, $groups );
    $this->encountergen( $opts, $map, $groups );
    $this->treasuregen(  $opts, $map, $groups );

    $this->post( $opts, $map, $groups );

    my $changed_options = {};
    for my $k (keys %$opts) {
        $changed_options->{$k} = $opts->{$k} if $opts->{$k} ne $this->{o};
    }

    return $changed_options;
}
# }}}

# Meant to be overloaded elsewhere:
sub trapgen      { my $this = shift; $_->trapgen(@_)      while $_ = shift @{$this->{plugins}{trap}} }
sub doorgen      { my $this = shift; $_->doorgen(@_)      while $_ = shift @{$this->{plugins}{door}} }
sub encountergen { my $this = shift; $_->encountergen(@_) while $_ = shift @{$this->{plugins}{encr}} }
sub treasuregen  { my $this = shift; $_->treasuregen(@_)  while $_ = shift @{$this->{plugins}{tres}} }
sub post         { my $this = shift; $_->post(@_)         while $_ = shift @{$this->{plugins}{post}} }
sub pre          { my $this = shift; $_->pre(@_)          while $_ = shift @{$this->{plugins}{pre} } }

# add_plugin {{{
sub add_plugin {
    my $this   = shift;
    my $plugin = shift;

    ## This is a nice idea, but it actually sux0rs ... toast
    ## # Check to see if it works
    ## push @ISA, $plugin;
    ## $Games::RolePlay::MapGen::Generator::doorgen = 

    eval "use $plugin";
    croak $@ if $@;

    my $obj; 
    eval "\$obj = new $plugin";
    croak $@ if $@;

    croak "uesless plugin" unless int(@$obj) > 0;
    for my $e (@$obj) {
        my $pt = $this->{plugins}{$e};
        croak "plugin hooks unknown event" unless ref($pt) eq "ARRAY";
        push @$pt, $obj;
    }
}
# }}}
