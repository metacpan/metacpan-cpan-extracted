package Graphics::VTK::Pipeline;

use 5.006;
use strict;
use warnings;

use Graphics::VTK;
use Tk;
use Tk::Tree;


=head1 NAME

Graphics::VTK::Pipeline - VTK Visual Pipeline Browser 

=head1 SYNOPSIS

  use Graphics::VTK::Pipeline;
  
  Your VTK pipeline setup code here
  .
  .
  .
  
  # Show the visualization pipeline in a Tk window:
  Graphics::VTK::Pipeline::show($renderWindow);
  
  
=head1 DESCRIPTION

This is a perl port of Paul Rajlich's tcl/tk VTK pipeline browser. 

It will display the layout of the VTK visualization pipeline in your perl
program using a Tk tree widget. Clicking on a particular element in the tree will
display the VTK objects information in a window to the right of the tree.

Information on the original tcl/tk browser is available at: http://brighton.ncsa.uiuc.edu/prajlich/vtkPipeline

See the examples/pipeline directory of the L<Graphics::VTK> Source distribution
for some example scripts that use this module.
 
=head2 Known Issues

=over 1

=item *

The VTK-object edit capability of Paul's original browser is not implemented yet.

=item *

Variables names are not displayed in the pipeline browser, just the object
types. Due to the way Perl hides Lexical variables from the symbol table, I
don't know of a way around this problem. If anybody has any good ideas, let
me know.

=item *

vtkCubeAxesActor2D actors don't appear to show up in the pipeline.

=back

=head1 AUTHOR

John Cerney

=head1 SEE ALSO

L<perl>.

=cut


sub removeAll
{
 my $tree = shift;
 my $c;
 # Global Variables Declared for this function: vtkPipelineWin
 # Global Variables Declared for this function: Tree
 foreach $c ($tree->infoChildren())
  {
   eval
    {
     $tree->delete('entry',$c);
    }
   ;
  }
}



# new idea...
#
sub buildFrom
{
 my $tree = shift;
 my $obj = shift;
 my $prev = shift;
 my $actor = shift;
 my $c;
 my $dataPos;
 my $i;
 my $index;
 my $input;
 my $item;
 my $len;
 my $mapper;
 my $methods;
 my $numSrcs;
 my $object;
 my $property;
 my $result;
 my $slash;
 my $src;
 my @str;
 my $string;
 # Global Variables Declared for this function: vtkPipelineWin
 
 $str[0] = $obj if($obj);
 $@ = ''; # reset error indicator for the while loop condition
 
 while (!$@ && $prev)  # step thru until an error or untill no prev
  {
   
   unshift @str, $prev;
   eval{
	$prev = $prev->GetSource;
	};
   next if( $@ || !$prev); # Next if error
   unshift @str, $prev;
    eval{
     $input = $prev->GetInput;
    };
   next if( $@); # Next if error
   $src = undef;
    eval
    {
     $src = $prev->GetSource;
    };
   buildFrom($tree,$prev,$src)  unless($@);
   eval
    {
     $src = $prev->GetSource(0); # take care of 1-arg getSource (vtkGlyph3D)
    };
   unless($@)
    {
     $numSrcs = $prev->GetNumberOfSources;
     for ($i = 0; $i < $numSrcs; $i += 1)
      {
       buildFrom($tree,$prev,$prev->GetSource($i));
      }
    }
   $prev = $input;
    $@ = ''; # reset error indicator for the while loop condition
  }
 
 my @tempStr = map getID($_), @str; # Make array of object IDs
 my $str = join("/",@tempStr); #build tree id string
 unless($actor)
  {
   # put extra slash to include last filter ($obj)
   $str = "$str/";
  }
 # add "dirs" to tree
 
 my @items = @str; # get the items
 foreach my $object(@items){
 	if( $item ){
		$item = "$item/".getID($object);
	}
	else{
		$item = getID($object);
	}
	#print "object in pipeline '$object'\n";
	
	unless( $tree->infoExists($item) ){
		if ( $object->isa('Graphics::VTK::ProcessObject') ){ # If a process object that is not already there
			$tree->add($item, -image => 'pipelineIprocess', -text => getname($object), -data => $object);
			$object->SetStartMethod( sub{ $tree->selectionSet($item); $tree->update; $tree->idletasks;});
			$object->SetEndMethod( sub{ $tree->selectionSet(); $tree->update; $tree->idletasks;});
		}
		else{
			$tree->add($item, -image => 'pipelineIdata', -text => getname($object), -data => $object);
		}
		my $parent;
		if( $parent = $tree->infoParent($item)){ # add close/open indicator if this is a child
			$tree->setmode($parent => 'close');
		}
	}
 }
		
  if ($actor)
  {
   $mapper = $actor->GetMapper;
   $property = $actor->GetProperty;
   $tree->setmode($str => 'close');
   $tree->add("$str/".getID($mapper),'-image' => 'pipelineIprocess', -data => $mapper, -text => getname($mapper));
   $tree->add("$str/".getID($property),'-image','pipelineIfile', -data => $property, -text => getname($property));
   $tree->add("$str/".getID($actor),'-image','pipelineIactor',-data => $actor, -text => getname($actor));
  }
}

sub vtkPipelineRefresh
{
 my $renWin = shift;
 my $tree = shift;
 my $actors;
 my $currActor;
 my $currRen;
 my $mapper;
 my $prev;
 my $renderers;
 # Global Variables Declared for this function: vtkPipelineWin, Tree
 #print("refresh");
 removeAll($tree);
 $renderers = $renWin->GetRenderers;
 $renderers->InitTraversal;
 $currRen = $renderers->GetNextItem;
 while ($currRen)
  {
   $actors = $currRen->GetActors;
   $actors->InitTraversal;
   $currActor = $actors->GetNextItem;
   # for each actor, trace back through pipeline
   while ($currActor)
    {
     $mapper = $currActor->GetMapper;
     $prev = $mapper->GetInput;
     # build dir path-like string
     #print "Top Level Build prev = $prev, currActor = $currActor\n";
     buildFrom($tree,undef,$prev,$currActor);
     $currActor = $actors->GetNextItem;
    }
   $currRen = $renderers->GetNextItem;
  }
 vtkPipelineOpenAll($tree,$renWin);
}

#
sub openAll
{
 my $tree = shift;
 my $renWin = shift;
 my $v = shift;
 my $c;
 $tree->open($v);
 foreach $c ($tree->infoChildren($v))
  {
   eval
    {
     openAll($tree,$renWin,"$v/$c");
    }
   ;
  }
}
#
sub vtkPipelineOpenAll
{
 my $tree = shift;
 my $renWin = shift;
 my $c;
 # Global Variables Declared for this function: vtkPipelineWin
 # Global Variables Declared for this function: Tree
 #print("opening all");
 foreach $c ($tree->infoChildren())
  {
   eval
    {
     openAll($tree,$renWin,"$c");
    }
   ;
  }
}


#
sub show
{
 my $renWin = shift;
 my $vtkPipelineWin = shift;
 
 # Create vtkPipelineWin if not supplied
 unless( $vtkPipelineWin){
 	$vtkPipelineWin = Tk::MainWindow->new( -title => 'VTK Pipeline: '.$0);
 }
 
 # Create images:
 my $idir = $vtkPipelineWin->Photo('pipelineIdir', -data => '
      R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4APj4+P///wAAAAAAACwAAAAAEAAQAAADPVi63P4w
      LkKCtTTnUsXwQqBtAfh910UU4ugGAEucpgnLNY3Gop7folwNOBOeiEYQ0acDpp6pGAFArVqt
      hQQAO///
  ');
 
  my $ifile = $vtkPipelineWin->Photo('pipelineIfile', -data => '
      R0lGODdhEAAQAPIAAAAAAHh4eLi4uPj4+P///wAAAAAAAAAAACwAAAAAEAAQAAADPkixzPOD
      yADrWE8qC8WN0+BZAmBq1GMOqwigXFXCrGk/cxjjr27fLtout6n9eMIYMTXsFZsogXRKJf6u
      P0kCADv/
  ');
 
  my $idata = $vtkPipelineWin->Photo('pipelineIdata', -data => '
      R0lGODlhEgANAPAAAAAAAP///yH+JSAgSW1wb3J0ZWQgZnJvbSBTR0kgaW1hZ2U6IGltYWdl
      My5yZ2IALAAAAAASAA0AQALQTBIRERERQgghhBBCCAGEEABBEARBEARBEAQBEAQBEARBEARB
      EARBEAgEAoFAIBAIBAKBQCAQCAQCgUAgEAgEAoFAIBAIBAIBQCAQCAACgUAgEAgEAoFAIBAI
      BAKBQCAQEBAQAAAAAAAAAAAAAAAAAAAAABAQEBAQEBAAAAAAEBAQEBAQEBAQEBAQEBAAEBAQ
      EAAQEBAQEBAQEBAQEBAAEBAQEAAQEBAQEBAQEBAQEBAAAAAAEBAQEBAQEBAQAAAAAAAAAAAA
      AAAAAAAAABBQAAA7
  ');

  my $iprocess = $vtkPipelineWin->Photo('pipelineIprocess', -data => '
      R0lGODlhEgANAPEAABwNDuFocf///wAAACH+JSAgSW1wb3J0ZWQgZnJvbSBTR0kgaW1hZ2U6
      IGltYWdlNC5yZ2IALAAAAAASAA0AQALQlCQiIiIihBBCCAFCCCGAEARBEAQBIAhAEARBAARB
      AARBEACCIAiCIBAIBAKBQCAQCAQCgQAACAQCgUAgEAgEAACBQAAIBAKBAAAAAAQCgUAAIBAI
      AIBAIBAIBAKBQAAAICAgICAAAAAAAAAAAAAAAAAgICAgAAAQEBAQAAAAABAQEBAAACAgABAQ
      EBAQABAQEAAQEBAQACAgABAQEBAQABAQEBAQEBAQACAgAAAQEBAQABAQEBAQEBAAACAgICAA
      AAAAAAAAAAAAAAAgICBQAAA7
  ');

  my $iactor = $vtkPipelineWin->Photo('pipelineIactor', -data => '
      R0lGODlhEgANAPEAABIVGo+n0f///wAAACH+JSAgSW1wb3J0ZWQgZnJvbSBTR0kgaW1hZ2U6
      IGltYWdlNS5yZ2IALAAAAAASAA0AQALQlCQiIiIihBBCCAFCCCGAEABBEAQBIAhAEARBEABA
      EARBEACCIAiCIBAIBAKBQCAQCAQCASAQCAQCgUAgEAgEAgGAQAAIBAKBACAQAAQCgUAAIBAA
      AoFAIBAIBAKBQCAQACAgAAAAAAAAAAAAAAAAAAAAACAgABAQEBAQEBAAEBAQEBAQACAgABAQ
      EBAQEAAQABAQEBAQACAgABAQEBAQAAAAABAQEBAQACAgABAQEBAAEBAQEAAQEBAQACAgAAAA
      AAAAAAAAAAAAAAAAACBQAAA7
  ');
  
 
 $vtkPipelineWin->configure('-bd',3,'-relief','flat');
 my $buttonFrame = $vtkPipelineWin->Frame('-bg','white');
 $buttonFrame->pack('-fill','x','-expand',0, -side => 'top');



# my $tree =  $vtkPipelineWin->Scrolled('Tree',-separator => "/",'-width',300,'-height',200,-drawbranch => 1, -bg => 'white');
 my $tree =  $vtkPipelineWin->Scrolled('Tree',-separator => "/",-drawbranch => 1, -bg => 'white','-width',50,);
 $tree->packAdjust( -fill,'both','-expand',1, -side => 'left', -delay => 1);

 my $refreshButton = $buttonFrame->Button('-text',"refresh",'-command',[\&vtkPipelineRefresh, $renWin,$tree]);
 my $openButton = $buttonFrame->Button('-text',"open all",'-command',
  sub
   {
    vtkPipelineOpenAll($tree,$renWin);
   }
 );

 foreach $_ ($refreshButton, $openButton)
  {
   $_->pack('-side','left');
  }
  
 my $infoText = $vtkPipelineWin->Scrolled('Text','-background','white', -width => 40);
 $infoText->pack('-side','right','-fill','both', -expand => 1);
 vtkPipelineRefresh($renWin,$tree);
 
 # Set Bindings
 
 # Button 3 would call the vtkShow dialog, but this
 #  hasn't been translated to perl yet.
 $tree->bind('<3>', sub{
 	print "vtkShow not implemented yet\n";
	}
	);
	
 $tree->bind('<1>', sub{  # print the info on the function
	if (defined $tree->info('selection')){
		my $selection = $tree->info('selection');
		my $data = $tree->entrycget($selection,'-data');
		
		if( defined($data) && ref($data) =~ /^Graphics::VTK/){
			my $string = $data->Print;
			$infoText->delete('1.0','end');
			$infoText->insert('1.0',$string);
		}
	}
	}
	);
	
 $vtkPipelineWin->update;
 	
 
 #$vtkPipelineWin.f.w bind x <2> {
 #  set lbl [Tree:labelat %W %x %y]
 #  Tree:delitem %W $lbl
}


#########################################
# Sub to get a shortened name of a VTK object
#  Just gets rid of the Graphics::VTK part
sub getname{

	my $object = shift;
	
	my $name  = ref($object);
	$name =~ s/^Graphics::VTK:://;
	
	return $name;
}
#########################################
# Sub to get a unique id for an object, using
# the VTK modified time. Using just the stringified variable references
#   for VTK object leads to some identical objects being id'ed as different
sub getID{

	my $object = shift;
	
	unless( defined($object)){
		return "undef Value!";
		#print "undef value in getID\n";
		#confess("object is undefined\n");
	}
	my $name  = ref($object);
	$name =~ s/^Graphics::VTK:://;
	
	$name .= $object->GetMTime;
	#print "name is $name\n";
	return $name;
}

1;
