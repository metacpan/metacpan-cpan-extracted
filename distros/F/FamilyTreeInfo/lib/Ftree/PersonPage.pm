package Ftree::PersonPage;
use strict;
use warnings;

use version;
our $VERSION = qv('2.3.41');

use Ftree::FamilyTreeBase;
use Sub::Exporter -setup => { exports => [ qw(new main) ] };
use Params::Validate qw(:all);
use Encode qw(decode_utf8);
my $q = new CGI;

use base 'Ftree::FamilyTreeBase';

sub new{
    my $type = shift;
    my $self = $type->SUPER::new(@_);
    $self->{target_person} = undef;
    return $self;
}

sub main{
    my ($self) = validate_pos( @_, { type => HASHREF } );
    $self->_set_target();
    $self->_target_check();
    $self->_password_check();
    $self->{imgwidth}  = 240;
    $self->{imgheight} = $self->{imgwidth} * 1.5;
    $self->_draw_single_person_page();
    $self->_endpage();

    return;
}
#######################################################
# processing the parameters (type and passwd)
sub _set_target {
    my ($self) = validate_pos( @_, { type => HASHREF } );
    $self->SUPER::_process_parameters();
    my $id = decode_utf8( CGI::param('target') );
    my $family_tree_data =
      Ftree::FamilyTreeDataFactory::getFamilyTree( $self->{settings}{data_source} );
    $self->{target_person} = $family_tree_data->get_person($id);

    return;
}

#######################################################
# check if target person exists in database
sub _target_check {
    my ($self) = validate_pos( @_, { type => HASHREF } );
    if ( !defined $self->{target_person} ) {
        my $title = $self->{textGenerator}->noDataAbout( CGI::param('target') );
        $self->_toppage($title);
        print $q->br, $title, $q->br, "\n";
        $self->_endpage();
        exit 1;
    }

    return;
}

sub _draw_row {
    my ( $self, $key, $value ) = validate_pos(
        @_,
        { type => HASHREF },
        { type => SCALAR },
        { type => SCALAR | UNDEF }
    );
    return unless defined $value;

    print $q->start_Tr, $q->td( $q->strong( $self->{textGenerator}->{$key} ) );
    print $q->td($value), $q->end_Tr, "\n";

    return;
}

sub _draw_pictures {
    my ( $self, $the_person ) =
      validate_pos( @_, { type => HASHREF }, { type => SCALARREF } );
    my $column_number = 3;
    my $index         = 0;
    print $q->hr, $q->h3('Image gallery'),
      $q->br, $q->start_table( { -align => 'center' } );
    foreach my $picture ( @{ $the_person->{pictures} } ) {
        print "\n";
        print $q->start_Tr() if ( $index % $column_number == 0 );
        print $q->start_td( { -width => 220 } ),
          $q->a(
            { -href => $picture->{file_name} },
            $q->img(
                {
                    -width => 200,
                    -src   => $picture->{file_name},
                    -alt   => $picture->{comment}
                }
            )
          ),
          $q->br,
          $picture->{comment}, $q->end_td;
        print $q->end_Tr()
          if ( ( $index % $column_number ) == $column_number - 1 );
        ++$index;
    }
    print $q->end_Tr(), "\n" if ( ( $index % $column_number ) != 0 );
    print $q->br, $q->end_table(), $q->br;

    return;
}

sub _draw_single_person_page {
    my ($self) = validate_pos( @_, { type => HASHREF } );
    binmode STDOUT, ":encoding(UTF-8)";
    $self->_toppage( $self->{target_person}->get_name()->get_long_name() );

    print $q->start_center;
    $self->_print_zoom_buttons();
    print $self->html_img( $self->{target_person} ), $q->br, "\n";
    print $self->{target_person}->get_date_of_birth()->format()
      if ( defined $self->{target_person}->get_date_of_birth() );
    print " - ";
    print $self->{target_person}->get_date_of_death()->format()
      if ( defined $self->{target_person}->get_date_of_death() );
    print $q->end_center, "\n";

    print $q->br, $q->start_table( { -cellspacing => 2, -cellpadding => 2 } );
    $self->_draw_row( 'nickname',
        $self->{target_person}->get_name()->get_nickname() )
      if ( defined $self->{target_person}->get_name()->get_nickname() );
    $self->_draw_row( "place_of_birth",
        $self->{target_person}->get_place_of_birth()->toString() )
      if ( defined $self->{target_person}->get_place_of_birth() );
    $self->_draw_row( "place_of_death",
        $self->{target_person}->get_place_of_death()->toString() )
      if ( defined $self->{target_person}->get_place_of_death() );
    $self->_draw_row( "cemetery",
        $self->{target_person}->get_cemetery()->toString() )
      if ( defined $self->{target_person}->get_cemetery() );
    $self->_draw_row( "schools",
        join( ', ', @{ $self->{target_person}->get_schools() } ) )
      if ( defined $self->{target_person}->get_schools() );
    $self->_draw_row( "jobs",
        join( ', ', @{ $self->{target_person}->get_jobs() } ) )
      if ( defined $self->{target_person}->get_jobs() );
    $self->_draw_row( "work_places",
        join( ', ', @{ $self->{target_person}->get_work_places() } ) )
      if ( defined $self->{target_person}->get_work_places() );
    $self->_draw_row(
        "places_of_living",
        join( ', ',
            map { $_->toString() }
              @{ $self->{target_person}->get_places_of_living() } )
    ) if ( defined $self->{target_person}->get_places_of_living() );

    $self->_draw_row(
        "father",
        $self->aref_tree(
            $self->{target_person}->get_father()->get_name()->get_long_name(),
            $self->{target_person}->get_father(), 0
        )
    ) if ( defined $self->{target_person}->get_father() );
    $self->_draw_row(
        "mother",
        $self->aref_tree(
            $self->{target_person}->get_mother()->get_name()->get_long_name(),
            $self->{target_person}->get_mother(), 0
        )
    ) if ( defined $self->{target_person}->get_mother() );
    my @spouses = $self->{target_person}->get_spouses();
    my $spouse_type =
      $self->{target_person}->get_gender() == 0 ? "wives" : "husbands";
    $self->_print_people_list( $spouse_type, \@spouses );
    my @siblings = $self->{target_person}->get_peers();
    $self->_print_people_list( "siblings", \@siblings )
      if ( @siblings > 1 );

    my @peers_on_father = $self->{target_person}->get_soft_peers('father');
    $self->_print_people_list( "siblings_on_father", \@peers_on_father );
    my @peers_on_mother = $self->{target_person}->get_soft_peers('mother');
    $self->_print_people_list( "siblings_on_mother", \@peers_on_mother );
    $self->_print_people_list( "children",
        $self->{target_person}->get_children() )
      if ( defined $self->{target_person}->get_children() );

    $self->_draw_row( "email",    $self->{target_person}->get_email() );
    $self->_draw_row( "homepage", $self->{target_person}->get_homepage() );
    $self->_draw_row( "general",  $self->{target_person}->get_general() );

    print $q->end_table;

    #  $self->draw_pictures($self->{target_person})
    #    if(defined $self->{target_person}->{pictures})

    return;
}

sub _print_zoom_buttons {
    my ($self) = validate_pos( @_, { type => HASHREF } );
    my $lev_plus1 = 2;

    print $q->start_table(
        { -border => "0", -cellpadding => "0", -cellspacing => "2" } ), "\n",
      $q->start_Tr;
    print $q->start_td( { -align => "center" } ), "\n",
      $self->aref_tree(
        $q->img(
            {
                -src => "$self->{graphicsUrl}/zoomout.gif",
                -alt => $self->{textGenerator}->ZoomOut($lev_plus1)
            }
        ),
        $self->{target_person},
        $lev_plus1
      ),
      $q->end_td,    $q->end_Tr, "\n",
      $q->end_table, $q->br,     $q->br, "\n";

    return;
}

sub _print_people_list {
    my ( $self, $people_type, $people_array_r ) = validate_pos(
        @_,
        { type => HASHREF },
        { type => SCALAR },
        { type => ARRAYREF }
    );
    if ( defined $people_array_r && @{$people_array_r} > 0 ) {
        print $q->start_Tr,
          $q->td( $q->strong( $self->{textGenerator}->{$people_type} ) ),
          $q->start_td;

        foreach my $person ( @{$people_array_r} ) {
            if (   $person != $self->{target_person}
                && $person != $Ftree::Person::unknown_male
                && $person != $Ftree::Person::unknown_female )
            {
                print $self->aref_tree( $person->get_name()->get_full_name(),
                    $person, 0 ),
                  ", ";
            }
        }
        print $q->end_td, $q->end_Tr;
    }

    return;
}

1;

