#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::Tk::Continents;
# ABSTRACT: continents information
$Games::Risk::Tk::Continents::VERSION = '4.000';
use POE                    qw{ Loop::Tk };
use List::MoreUtils        qw{ firstidx };
use List::Util             qw{ max };
use Moose;
use MooseX::Has::Sugar;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;
use Tk;
use Tk::Sugar;
use Tk::TableMatrix;

with 'Tk::Role::Dialog' => { -version => 1.112380 }; # _clear_w


use Games::Risk::I18n   qw{ T };
use Games::Risk::Logger qw{ debug };
use Games::Risk::Utils  qw{ $SHAREDIR };

Readonly my $K => $poe_kernel;


# -- attributes

has _continents => ( rw, isa=>'ArrayRef', auto_deref );
has _values => (
    ro,
    traits     => ['Hash'],
    isa        => 'HashRef[Str|Int]',
    default    => sub { {} },
    handles    => {
        _set_value => 'set',   # $self->_set_value( "$row,$col", $value );
    }
);


# -- initialization / finalization

sub _build_hidden    { 1 }
sub _build_title     { 'prisk - ' . T('continents') }
sub _build_icon      { $SHAREDIR->file('icons', '32','continents.png') }
sub _build_header    { T('Continents information') }
sub _build_resizable { 0 }
sub _build_hide      { T('Close') }


#
# session initialization.
#
sub START {
    my ($self, $s) = @_[OBJECT, SESSION];
    $K->alias_set('continents');

    #-- trap some events
    my $top = $self->_toplevel;
    $top->protocol( WM_DELETE_WINDOW => $s->postback('visibility_toggle'));
    $top->bind('<F6>', $s->postback('visibility_toggle'));
}


#
# session destruction.
#
sub STOP {
    debug( "gui-continents shutdown\n" );
}


# -- public events


event chown => sub {
    my ($self, $country, $looser) = @_[OBJECT, ARG0, ARG1];
    my $owner = $country->owner;

    # continent information
    my $continent = $country->continent;
    my $row = 1 + firstidx { $_ eq $continent } $self->_continents;

    # mark table as enabled to update it
    my $tm = $self->_w('tm');
    $tm->configure(enabled);

    foreach my $player ( grep { defined } $owner, $looser ) {
        my $col = 3 + firstidx { $_ eq $player } Games::Risk->new->players;
        my $value = scalar ( grep { $_->owner eq $player } $continent->countries );
        $self->_set_value( "$row,$col", $value );

        # mark continent as owned if needed
        my $tag = ( $player eq $owner && $continent->is_owned($player) ) ? "own-$player" : '';
        $tm->tagCell( $tag, "$row,$col" );
    }

    # update finished, disable table once again
    $tm->configure(disabled);
};



event player_add => sub {
    my ($self, $player) = @_[OBJECT, ARG0];
    my $tm = $self->_w( 'tm' );

    # add a new column. we must first enable the table since
    # tk::tablematrix cannot insert a column when it is disabled.
    my $col = $tm->index( 'end', 'col' );
    $tm->configure( enabled );
    $tm->insertCols($col, 1); $col++;
    $tm->configure( disabled );
    $tm->colWidth( $col, 5 );

    # new player gets a tag with her color
    $tm->tagConfigure( $player, -relief=>'raised', -bg=>$player->color );
    $tm->tagConfigure( "own-$player", -bg=>$player->color );
    $tm->tagCell( $player, "0,$col" );

    # fill in the column with the player information
    my @continents = $self->_continents;
    $self->_set_value( "$_,$col", 0 ) for 1 .. scalar @continents;
};



event shutdown => sub {
    my ($self, $destroy) = @_[OBJECT, ARG0];
    $self->_toplevel->destroy if $destroy;
    $self->_clear_w;
    $K->alias_remove('continents');
};



event visibility_toggle => sub {
    my $self = shift;

    my $top = $self->_toplevel;
    my $method = ($top->state eq 'normal') ? 'withdraw' : 'deiconify'; # parens needed for xgettext
    $top->$method;
};


# -- private methods

#
# $self->_build_gui;
#
# called by tk:role:dialog to build the inner dialog.
#
sub _build_gui {
    my ($self, $f) = @_;

    # populate continents list
    my $map = Games::Risk->instance->map;
    my @continents =
        sort {
             $b->bonus <=> $a->bonus ||
             $a->name  cmp $b->name
        }
        $map->continents;
    $self->_set_continents( \@continents );

    # create the table
    my $tm = $f->TableMatrix(
        -cols           => 3,
        -colstretchmode => 'all',
        -justify        => 'center',
        -rows           => scalar(@continents) + 1,
        -variable       => $self->_values,
        -resizeborders  =>'none',
        disabled,
    )->pack(top, xfill2);
    $self->_set_w( tm => $tm );
    $tm->tagConfigure( 'left',   -bg => 'grey', W );
    $tm->tagConfigure( 'title',  -bg => 'grey', -relief => 'raised' );
    $tm->tagConfigure( 'static', -bg => 'grey' );

    # populate static continent information
    $self->_set_value( '0,0', T('continent') );
    $self->_set_value( '0,1', T('bonus') );
    $self->_set_value( '0,2', T('# countries') );
    $tm->tagCell( 'title', "0,$_" ) for 0..2;
    my $row = 0;
    foreach my $c ( @continents ) {
        my @countries = $c->countries;
        $row++;
        $self->_set_value( "$row,0", $c->name );
        $self->_set_value( "$row,1", $c->bonus );
        $self->_set_value( "$row,2", scalar( @countries ) );
        $tm->tagCell( 'left', "$row,0" );
        $tm->tagCell( 'static', "$row,$_" ) for 1..2;
    }

    # set 1st column width
    my $max = max map { length $_->name } @continents;
    $tm->colWidth( 0, $max );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Games::Risk::Tk::Continents - continents information

=head1 VERSION

version 4.000

=head1 DESCRIPTION

C<GR::Tk::Continents> implements a POE session, creating a Tk window to
list the continents of the map and their associated bonus.

The methods are in fact the events accepted by the session.

=head1 ATTRIBUTES

=head2 parent

A L<Tk> window that will be the parent of the toplevel window created.
This parameter is mandatory.

=head1 METHODS

=head2 chown

    $K->post( 'gui-continents' => chown => $country, $looser);

Update the country count of player for a given continent.

=head2 player_add

    $K->post( 'gui-continents' => player_add => $player );

Add a new column in the table to display the new player.

=head2 shutdown

    $K->post( continents => 'shutdown', $destroy );

Kill current session. If C<$destroy> is true, the toplevel window will
also be destroyed.

=head2 visibility_toggle

    $K->post( 'gui-continents' => 'visibility_toggle' );

Request window to be hidden / shown depending on its previous state.

=for Pod::Coverage START STOP

=head1 SYNOPSYS

    Games::Risk::Tk::Continents->new(%opts);

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
