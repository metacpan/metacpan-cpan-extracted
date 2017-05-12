package Ftree::FamilyTreeGraphics;
use strict;
use warnings;

use version; our $VERSION = qv('2.3.41');

use Ftree::FamilyTreeBase;

use Params::Validate qw(:all);
use List::Util qw(first max);
use List::MoreUtils qw(first_index);
use CGI::Carp qw(warningsToBrowser);# warningsToBrowser set_message);

use Sub::Exporter -setup => { exports => [ qw(new main) ] };
use utf8;
use Encode qw(decode_utf8);
use Ftree::Picture;



#######################################################
#
# The HTML output table is generated in three parts:
#   - the Ancestor tree (ATree)
#   - the peer level (peers)
#   - the Descendant tree (DTree)
#
#
#######################################################

use base 'Ftree::FamilyTreeBase';
sub new{
  my $type = shift;
  my $self = $type->SUPER::new(@_);
  $self->{target_person} = undef;
  $self->{DLevels}       = 0;        # nr of levels in DTree
  $self->{cellwidth}     = undef;    # width of a cell
  $self->{gridWidth}     = undef;    # width of the tree
  $self->{fontsize}      = undef;

  return $self;
}

sub main{
  my ($self) = validate_pos(@_, HASHREF);
    # my $title='/nophoto_m.jpg';
    # warningsToBrowser(1);
  $self->_process_parameters();

  #set_message("This is a better message for the end.");
  #die ("This is a test die");

    # print $self->{cgi}->center( $self->{cgi}->h1($title) ), "\n";


  $Ftree::Person::unknown_male->set_default_picture(Ftree::Picture->new(
  	{file_name => $self->{graphicsUrl} . '/nophoto_m.jpg',
     comment => ""}));
  $Ftree::Person::unknown_female->set_default_picture(Ftree::Picture->new(
  	{file_name => $self->{graphicsUrl} . '/nophoto_f.jpg',
     comment => ""}));

  $self->_target_check();
  $self->set_size();
  $self->_password_check();

  if ( $self->{reqLevels} > 0 ) {
  	 $self->_draw_familytree_page();
  }
  else {
  	  my $address = $self->{cgi}->url(-relative=>0);
  	  $address =~ s/$self->{treeScript}/$self->{personScript}/xm;
  	  $address .= "?target=".$self->{target_person}->get_id()
  	     .";lang=".$self->{lang};
  	  print $self->{cgi}->redirect($address);
  }

  return;
}

#######################################################
# processing the parameters (type and passwd)
sub _process_parameters {
  my ($self) = validate_pos(@_, HASHREF);
  $self->SUPER::_process_parameters();
  my $id = decode_utf8(CGI::param('target'));
  my $family_tree_data =
    	Ftree::FamilyTreeDataFactory::getFamilyTree( $self->{settings}{data_source} );
  $self->{target_person} = $family_tree_data->get_person($id);
  $self->{reqLevels}     = CGI::param('levels');
  $self->{reqLevels}     = 2 unless ( defined $self->{reqLevels} );

  return;
}

#######################################################
# check if target person exists in database
sub _target_check {
  my ($self) = validate_pos(@_, HASHREF);
  if ( !defined $self->{target_person} ) {
    my $title = $self->{textGenerator}->noDataAbout( CGI::param('target') );
    $self->_toppage($title);
    print $self->{cgi}->br, $title, $self->{cgi}->br, "\n";
    $self->_endpage();
    exit 1;
  }

  return;
}

#######################################################
# Size the output according to the no. levels being displayed
sub set_size {
  my ($self) = validate_pos(@_, HASHREF);
  if ( $self->{reqLevels} > 3 ) {
    $self->{imgwidth}  = 45;
    $self->{fontsize}  = 1;
  }
  elsif ( $self->{reqLevels} == 3 ) {
    $self->{imgwidth}  = 60;
    $self->{fontsize}  = 2;
  }
  elsif ( $self->{reqLevels} == 2 ) {
    $self->{imgwidth}  = 90;
    $self->{fontsize}  = 3;
  }
  elsif ( $self->{reqLevels} == 1 ) {
    $self->{imgwidth}  = 110;
    $self->{fontsize}  = 2;
  }
  elsif ( $self->{reqLevels} == 0 ) {
    $self->{imgwidth}  = 240;
    $self->{fontsize}  = 2;
  }
  else {
    $self->{cellwidth} = 70;
    $self->{imgwidth}  = 60;
    $self->{fontsize}  = 2;
  }
  $self->{cellwidth} = "100%";
  $self->{imgheight} = $self->{imgwidth} * 1.5;

  return;
}

sub html_img {
  my ( $self, $person ) = validate_pos(@_, HASHREF, SCALARREF);

  my $img = $self->SUPER::html_img($person);
  return ($person == $self->{target_person} ||
      $person == $Ftree::Person::unknown_male ||
      $person == $Ftree::Person::unknown_female ) ? $img : $self->aref_tree($img, $person);
}

sub img_graph {
  my ( $self, $graphics ) = validate_pos(@_, HASHREF, SCALAR, 0);
  return $self->{cgi}->img(
          {
            -width => $self->{cellwidth},
            -height=> "26",
            -src   => "$self->{graphicsUrl}/".$graphics.".gif",
            -alt   => "",
          } );
}
sub hone_img_graph {
  my ( $self ) = validate_pos(@_, HASHREF, 0);
  return $self->img_graph('hone');
}
sub getATreeWidth {
  my ( $self, $levels ) = validate_pos(@_, HASHREF, SCALAR, 0);
  return 2**( $levels );
}
#######################################################
# returns the width of tree below this person
# root_person:  this person
# levels:     no. of levels to descend in tree
sub getDTreeWidth {
  my ( $self, $levels, $root_person ) = validate_pos(@_,
    HASHREF, SCALAR, SCALARREF );

#  carp "called: getDTreeWidth with \$root_person = " . $root_person->get_name()->get_long_name() . ", \$levels = $levels";

  return 1 if ( 0 == $levels);
  return 1 if ($root_person == $Ftree::Person::unknown_male ||
               $root_person == $Ftree::Person::unknown_female);
  return 1 unless defined $root_person->get_children();

  my $width = 0;
  $width += $self->getDTreeWidth( $levels - 1, $_ )
    for ( @{ $root_person->get_children() } );
  return $width;
}

#######################################################
# returns the no. levels available in Ancestor tree
#   above this person
# root_person:  this person
# anc_level:  current level of ancestor tree (0=root_node)
# req_levels: no. levels requested
sub getATreeLevels {
  my ( $self, $root_person, $anc_level, $req_levels ) = validate_pos(@_,
    HASHREF, {type => SCALARREF|UNDEF}, SCALAR, SCALAR );

#  print "called: getATreeLevels (root_node=$root_person->get_name()->get_full_name(), anc_level=$anc_level,  req_levels=$req_levels)\n";
  return 0 if ( $req_levels == 0 );
  return $anc_level unless defined $root_person;
  return $anc_level unless ( defined $root_person->get_father() ||
    defined $root_person->get_mother());
  return $anc_level if($anc_level == $req_levels );

  my $p1_levels = $self->getATreeLevels( $root_person->get_father(),
      $anc_level + 1, $req_levels );
  my $p2_levels = $self->getATreeLevels( $root_person->get_mother(),
      $anc_level + 1, $req_levels );
  return List::Util::max($p1_levels, $p2_levels);
}

#######################################################
# populate the Descendant Tree structure for all
#   people below the person specified
# $root_person:  this person
# dec_level:  current level of descendant tree (0=root_node)
# req_levels: no. levels requested
sub fillDTree {
  my ( $self, $root_person, $dec_level, $req_levels, $DTree_ref ) = validate_pos(@_,
    HASHREF, SCALARREF, SCALAR, SCALAR, ARRAYREF );

#  print "called: fillDTree (root_node=$root_node_id, dec_level=$dec_level,  req_levels=$req_levels)\n";
  $dec_level++;

  if ( $root_person != $Ftree::Person::unknown_male
       && $root_person != $Ftree::Person::unknown_female
  	   && defined $root_person->get_children() ) {
    push @{ $DTree_ref->[$dec_level] }, @{$root_person->get_children()};
    $self->{DLevels} = $dec_level if ( $dec_level > $self->{DLevels} );
  }
  else {
    push @{ $DTree_ref->[$dec_level] }, $Ftree::Person::unknown_female;
  }

  if ( $dec_level < $req_levels ) {
  	if(defined $root_person->get_children()) {
  	  $self->fillDTree( $_, $dec_level, $req_levels, $DTree_ref )
        for ( @{ $root_person->get_children() } );
  	}
  	else {
      $self->fillDTree( $Ftree::Person::unknown_female, $dec_level, $req_levels, $DTree_ref );
  	}
  }

  return;
}

sub putNTD {
  my ( $self, $n, $data ) = validate_pos(@_,
    HASHREF, SCALAR, {type => SCALAR, default => ""} );
    print $self->{cgi}->td($data), "\n" for (1 .. $n);

  return;
}
sub drawRow {
  my ( $self, $used_width, $people, $diff_levels, $this_level,
    $left_fill, $emptyTDCond, $group_width_func, $display_func ) = validate_pos(@_,
    HASHREF, SCALAR, ARRAYREF, {type => SCALAR|UNDEF},
    {type => SCALAR|UNDEF}, SCALAR, CODEREF, CODEREF, CODEREF );
  my $right_fill = $self->{gridWidth} - $used_width - $left_fill;
  my $is_blank_line = 1;

  print $self->{cgi}->start_Tr, "\n";
  $self->putNTD($left_fill);
  foreach my $person (@{$people}) {
    my $group_width  = $group_width_func->($self, $diff_levels, $person);
    my $left  = int( ( $group_width - 1 ) / 2 );
    my $right = $group_width - 1 - $left;

    $self->putNTD($left);
    if ( $emptyTDCond->($self, $person, $this_level) ) {
      print $self->{cgi}->td(), "\n";
    }
    else {
      print $self->{cgi}->td( {-align => "center" },
        $display_func->($self, $person) );
      $is_blank_line = 0;
    }
    $self->putNTD($right);
  }
  $self->putNTD($right_fill);
  print $self->{cgi}->end_Tr, "\n";

  return $is_blank_line;
}
sub unknownEquiCond {
  my ( $self, $person ) = validate_pos(@_, HASHREF, SCALARREF, 0 );
  return $person == $Ftree::Person::unknown_male || $person == $Ftree::Person::unknown_female;
}
sub unknownEquiNoChildrenCond {
  my ( $self, $person, $this_level ) = validate_pos(@_,
    HASHREF, SCALARREF, SCALAR );
  return $person == $Ftree::Person::unknown_female ||
    $person == $Ftree::Person::unknown_male ||
    ! defined $person->get_children()  ||
    ( $this_level == $self->{reqLevels} );
}
sub falseCond {
  return 0;
}
#######################################################
# generate a line of the D-tree graphics OVER the
# level specified
# this_level: level of grid to generate
# max_levels: max depth that will be shown
sub getDGridLineG {
  my ( $self, $this_level, $max_levels, $DWidth, $DTree_ref ) = validate_pos(@_,
    HASHREF, SCALAR, SCALAR, SCALAR, ARRAYREF );
#  print "called: getDGridLineG (this_level = $this_level, max_levels = $max_levels)\n";

  my ( $left_fill, $branch, $right_fill );
  my $lefto_fill  = int( ( $self->{gridWidth} - $DWidth ) / 2 );
  my $righto_fill = $self->{gridWidth} - $DWidth - $lefto_fill;

  # Spacers on LHS - fills gap between overall grid width and width of Dgrid
  print $self->{cgi}->start_Tr, "\n";
  $self->putNTD($lefto_fill);

  if ( @{ $DTree_ref->[$this_level] } == 0 ) {
    printf '|;';
  }
  else {
    foreach my $person (@{ $DTree_ref->[$this_level] }) {
      # Find which parent is in the level above...
      my $this_parent;

      if ( 1 == $this_level ) {
        $this_parent = $self->{target_person};
      } else {
      	$this_parent = List::Util::first {$_ == $person->get_father()}
      	  @{ $DTree_ref->[$this_level - 1] }
      	  if(defined $person->get_father());
        $this_parent = List::Util::first {$_ == $person->get_mother()}
      	  @{ $DTree_ref->[$this_level - 1] }
      	  unless( defined $this_parent);
      }

      if ( $person == $Ftree::Person::unknown_female  ) {
        # This blank person
        $left_fill = $branch = $right_fill = "";
      }
      elsif ( 1 == @{$this_parent->get_children() } )
      {
        # This person is an only child
        $left_fill = $right_fill = "";
        $branch    = $self->img_graph('hone');
      }
      elsif ( $person == $this_parent->get_children()->[0] )
      {
        # Is this person the first child of this parent?
        $left_fill = "";
        $branch    = $self->img_graph('hleft');
        $right_fill = $self->img_graph('hblank');
      }
      elsif ( $person == $this_parent->get_children()->[-1] )
      {
         # Is this person the last child of this parent?
        $left_fill = $self->img_graph('hblank');
        $branch = $self->img_graph('hright');
        $right_fill = "";
      }
      else {
        $left_fill = $right_fill = $self->img_graph('hblank');
        $branch = $self->img_graph('hbranch');
      }

      my $group_width = $self->getDTreeWidth( $max_levels - $this_level, $person );
      my $left  = int( ( $group_width - 1 ) / 2 );
      my $right = $group_width - 1 - $left;

      $self->putNTD( $left, $left_fill );
      print $self->{cgi}->td($branch);
      $self->putNTD( $right, $right_fill );
    }
  }

  # Spacers on RHS - fills gap between overall grid width and width of Dgrid
  $self->putNTD($righto_fill);
  print $self->{cgi}->end_Tr, "\n";

  return;
}

#######################################################
# build A-tree for this person
# root_node: this person
# anc_level:  current level of ancestor tree (0=root node)
# req_levels: no. levels requested
sub fillATree {
  my ( $self, $root_person, $anc_level, $req_levels, $ATree_ref ) =
  	validate_pos(@_, HASHREF, {type => SCALARREF|UNDEF},
  	SCALAR, SCALAR, ARRAYREF );

  return unless $anc_level < $req_levels;
#  print "called: fillATree (root_node = $root_person, anc_level = $anc_level, req_levels = $req_levels)\n";

  my $father = defined $root_person->get_father() ?
    $root_person->get_father() : $Ftree::Person::unknown_male;

  my $mother =  defined $root_person->get_mother() ?
    $root_person->get_mother() : $Ftree::Person::unknown_female;

  push @{ $ATree_ref->[$anc_level] }, ($father, $mother);

  $anc_level++;
  $self->fillATree( $father, $anc_level, $req_levels, $ATree_ref );
  $self->fillATree( $mother, $anc_level, $req_levels, $ATree_ref );

  return;
}

#######################################################
# draw the graphics UNDER the level specified
# this_level: level of grid to generate
# max_levels: max depth that will be shown
sub getAGridLineG {
  my ( $self, $diff_levels, $AWidth, $aRow ) = validate_pos(@_,
    HASHREF, SCALAR, SCALAR, ARRAYREF);

  return if ( 0 > $diff_levels );

  my $left_fill  = int( ( $self->{gridWidth} - $AWidth + 1 ) / 2 );
  my $right_fill = $self->{gridWidth} - $AWidth - $left_fill;

  print $self->{cgi}->start_Tr, "\n";
  $self->putNTD($left_fill);

  my $node_width = 2**$diff_levels ;
  my $nodel_fill = int( ( $node_width - 1 ) / 2 );
  my $noder_fill = $node_width - 1 - $nodel_fill;

  for ( my $index = 0; $index < @$aRow; $index += 2 )
  {
    $self->putNTD($nodel_fill);
    print $self->{cgi}->td( $self->img_graph("hleftup")),"\n";
    $self->putNTD( $node_width - 1, $self->img_graph("hblankup") );
    print $self->{cgi}->td( $self->img_graph("hrightup") ), "\n";
    $self->putNTD($noder_fill);
  }

  $self->putNTD($right_fill);
  print $self->{cgi}->end_Tr, "\n";

  print $self->{cgi}->start_Tr, "\n";
  $self->putNTD($left_fill);

  for ( my $index = 0 ; $index < @$aRow; $index += 2 )
  {
    $self->putNTD( $node_width - 1 );
    print $self->{cgi}->td( $self->img_graph("hone") ), "\n";
    $self->putNTD($node_width);
  }

  $self->putNTD($right_fill);
  print $self->{cgi}->end_Tr, "\n";

  return;
}

#######################################################
sub buildDGrid {
  my ($self, $DWidth, $DTree_ref) = validate_pos(@_, HASHREF, SCALAR, ARRAYREF);

  my $left_fill = int( ( $self->{gridWidth} - $DWidth ) / 2 );

  for my $this_level (1 .. $self->{DLevels}) {
    $self->getDGridLineG( $this_level, $self->{reqLevels}, $DWidth, $DTree_ref );

    my $is_blank_line = $self->drawRow($DWidth, \@{ $DTree_ref->[$this_level] },
      $self->{reqLevels} - $this_level, $this_level, $left_fill,
      \&unknownEquiCond, \&getDTreeWidth, \&Ftree::FamilyTreeGraphics::html_img);

    $self->drawRow($DWidth, \@{ $DTree_ref->[$this_level] },
      $self->{reqLevels} - $this_level, $this_level, $left_fill,
      \&unknownEquiCond, \&getDTreeWidth, \&html_name);

    $self->drawRow($DWidth, \@{ $DTree_ref->[$this_level] },
      $self->{reqLevels} - $this_level, $this_level, $left_fill,
      \&unknownEquiNoChildrenCond, \&getDTreeWidth, \&hone_img_graph);

    $self->{DLevels} = $this_level - 1 if ( $is_blank_line );
  }

  return;
}

#######################################################
sub buildDestroyAGrid {
  my ( $self, $ATree_ref  ) = validate_pos(@_, {type => HASHREF}, ARRAYREF);
#printf "calling: getAGridLine \n";

  my $aLevel = @$ATree_ref;
  my $AWidth = 2 ** $aLevel;
  --$aLevel;
  my $left_fill  = int( ( $self->{gridWidth} - $AWidth + 1 ) / 2 );

  for ( my $this_level = $aLevel; $this_level >= 0 ; --$this_level ) {
    my $aRow = pop @$ATree_ref;
    $self->drawRow($AWidth, $aRow, $aLevel - $this_level, $this_level, $left_fill,
      \&falseCond, \&getATreeWidth , \&Ftree::FamilyTreeGraphics::html_img);

    $self->drawRow($AWidth, $aRow, $aLevel - $this_level, $this_level, $left_fill,
      \&falseCond, \&getATreeWidth, \&html_name);

    $self->getAGridLineG( $aLevel - $this_level, $AWidth, $aRow );
  }

  #printf "buildAGrid returns";
  return;
}

#######################################################
sub buildPGrid {
  my ($self, $PWidth) = validate_pos(@_, {type => HASHREF}, SCALAR);

  my @peers = $self->{target_person}->get_peers( );

  my $left_side   = List::MoreUtils::first_index {$_ == $self->{target_person}} @peers;
  my $left_fill  = int(( $self->{gridWidth} - 1 ) / 2 ) - $left_side;
  my $right_fill = $self->{gridWidth} - $PWidth - $left_fill;


  print $self->{cgi}->start_Tr, "\n";
  $self->putNTD($left_fill);

  if ( @peers > 1 ) {
    print $self->{cgi}->td( $self->img_graph("hleft") ), "\n";
    $self->putNTD($#peers - 1, $self->img_graph("hbranch"));
    print $self->{cgi}->td( $self->img_graph("hright") ),  "\n";
  }
  else {
    print $self->{cgi}->td( $self->img_graph("hone") ), "\n";
  }
  $self->putNTD($right_fill);
  print $self->{cgi}->end_Tr, "\n";

  $self->drawRow($PWidth, \@peers,
      undef, undef, $left_fill,
      \&falseCond, sub {return 1} , \&Ftree::FamilyTreeGraphics::html_img);

  $self->drawRow($PWidth, \@peers,
      undef, undef, $left_fill,
      \&falseCond, sub {return 1} , \&Ftree::FamilyTreeGraphics::html_name);

  if ( defined $self->{target_person}->get_children() ) {
    print $self->{cgi}->start_Tr, "\n";
    my $gridLeft = int( ( $self->{gridWidth} - 1 ) / 2 );
    my $gridRight = $self->{gridWidth} - 1 - $gridLeft;
    $self->putNTD($gridLeft);
    print $self->{cgi}->td( $self->img_graph("hone") ), "\n";
    $self->putNTD($gridRight);
    print $self->{cgi}->end_Tr, "\n";
  }

  return;
}

#######################################################
# find the width of the peer line
# (allowing for the fact that it may be off-centre)
sub getPTreeWidth {
  my ($self) = validate_pos(@_, {type => HASHREF});

  my @peers = $self->{target_person}->get_peers( );
  my $node_pos = List::MoreUtils::first_index {$_ == $self->{target_person}} @peers;

  my $right_side = $#peers - $node_pos;
  my $big_side = List::Util::max ($node_pos, $right_side );
  return $big_side * 2  + 1;
}

#######################################################
# generates the html for the name of this person
sub html_name {
  my ( $self, $person ) = validate_pos(@_, {type => HASHREF}, {type => SCALARREF});
  return $self->{cgi}->font({-size => $self->{fontsize}}, $self->{textGenerator}{Unknown})
    if ( !defined $person || $person == $Ftree::Person::unknown_male || $person == $Ftree::Person::unknown_female );
  my $show_name;
  if(defined $person->get_name()) {
    $show_name = ( $self->{reqLevels} > 1 ) ?
      $person->get_name()->get_first_name() : $person->get_name()->get_short_name();
  } else {
    $show_name = $self->{textGenerator}{Unknown};
  }
  if ( $person == $self->{target_person} ) {
    return $self->{cgi}->strong($self->{cgi}->font({-size => $self->{fontsize}}, $show_name));
  }
  else {
    return $self->{cgi}->font({-size => $self->{fontsize}}, $self->aref_tree($show_name, $person));
  }
}


sub print_zoom_buttons {
  my ( $self, $aLevels ) = validate_pos(@_, {type => HASHREF}, SCALAR);
  my $lev_minus1 = $self->{reqLevels} - 1;

  print $self->{cgi}->start_table(
    { -border => "0", -cellpadding => "0", -cellspacing => "2" } ), "\n",
    $self->{cgi}->start_Tr;
  if ( $lev_minus1 >= 0 ) {
    print $self->{cgi}->start_td({-align => "center"}), "\n",
      $self->aref_tree($self->{cgi}->img( {
          -src => "$self->{graphicsUrl}/zoomin.gif",
          -alt => $self->{textGenerator}->ZoomIn($lev_minus1) }), $self->{target_person}, $lev_minus1),
      $self->{cgi}->end_td, "\n";
  }

  if( $self->{reqLevels} <= $aLevels  ) {
    my $lev_plus1  = $self->{reqLevels} + 1;
    print $self->{cgi}->start_td({-align => "center"}), "\n",
      $self->aref_tree($self->{cgi}->img( {
          -src => "$self->{graphicsUrl}/zoomout.gif",
          -alt => $self->{textGenerator}->ZoomOut($lev_plus1) }), $self->{target_person}, $lev_plus1),
        $self->{cgi}->end_td;
  }
  print $self->{cgi}->end_Tr, "\n",
        $self->{cgi}->end_table, $self->{cgi}->br, $self->{cgi}->br, "\n";

  return;
}
#########################################################
# OUTPUT SECTION                                        #
#########################################################
sub _draw_start_page {
  my ( $self, $aLevels ) = validate_pos(@_, {type => HASHREF}, SCALAR);

  # header html for page
  my $title = $self->{textGenerator}->familyTreeFor(
       defined $self->{target_person}->get_name() ?          # He may have id but not any name
          $self->{target_person}->get_name()->get_full_name():
          $self->{textGenerator}->{Unknown});
  $self->_toppage($title);

  # Zoom buttons
  print $self->{cgi}->start_center, "\n";
  $self->print_zoom_buttons($aLevels);

  return;
}

sub _draw_familytree_page {
	my ($self) = @_;

	my $aLevels = $self->getATreeLevels( $self->{target_person}, 0, $self->{reqLevels} );
	my $AWidth = 2 ** $aLevels;
	my $PWidth = $self->getPTreeWidth();
	my $DWidth = $self->getDTreeWidth( $self->{reqLevels}, $self->{target_person} );

	$self->{gridWidth} = List::Util::max( $AWidth, $PWidth, $DWidth );

	# fill the grid
	my @ATree;
	$self->fillATree( $self->{target_person}, 0, $aLevels, \@ATree );
	my @DTree;
	$self->fillDTree( $self->{target_person}, 0, $self->{reqLevels}, \@DTree );


	$self->_draw_start_page(List::Util::max($aLevels, $self->{DLevels}));


    # Draw the grid
	print $self->{cgi}->start_table(
		{ -border => "0", -cellpadding => "0", -cellspacing => "0" } ), "\n";
	$self->buildDestroyAGrid(\@ATree);
	$self->buildPGrid($PWidth);
	$self->buildDGrid($DWidth, \@DTree);
	print $self->{cgi}->end_table, "\n", $self->{cgi}->end_center, "\n";


	$self->_endpage();
	return;
}

1;
