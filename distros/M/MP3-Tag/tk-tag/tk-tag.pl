#!/usr/bin/perl -w
use Tk;
use Tk::JPEG;
use Tk::DialogBox;
use Tk::BrowseEntry;
use Tk::FBox;
use Tk::TextUndo;
#use POSIX;
use strict;
use MP3::Tag;

### TODO
#
# make all buttons alive
#
# view binary data (as hex dump)
#
# delete/add more than one frame at once
#
# better open function
#
# ...
#
# doing changes automatically to all selected files
#       (like setting filename, applying Control-u to all filename,
#        deleting all ID3v2 frames or whatsoever)



#
# Sorry, but I know that this is ugly code...
#

use vars qw/$tktag $VERSION %element %var/;

$VERSION="0.15";

$var{dir}= shift || "./"; #/mp3/unsorted";
$var{v2specent}={TIT2=>{name=>"Song"}, TPE1=>{name=>"Artist"},
		 TALB=>{name=>"Album"}};
$var{filter}="";
$var{fnformat} = "%a - %s.mp3";
$var{autoinfo} = ["ID3v2","ID3v1","filename"];
formatstr($var{fnformat});

$tktag = MainWindow->new(); #main window
create_window();

#&load_filelist;
    &scan_dir;
    &filter_and_show;

MainLoop;

exit 0;

####################################


###### tk subs
sub key_bindings {
  $tktag->bind('<Control-U>'=>\&use_ucase);
  $tktag->bind('<Control-u>'=>\&use_ucase_first);
  $tktag->bind('<Control-l>'=>\&use_lcase);
  $tktag->bind('<Control-space>'=>\&use_spaces);
  $tktag->bind('<Control-S>'=>\&save);
  $tktag->bind('<Control-f>'=>\&autosetfilename);

  $tktag->bind('<Control-n>'=> 
	       sub {
		 $element{filelist}->activate($element{filelist}
					      ->index("active")+1);
		 &select; });
}

sub create_window {
  my ($l);

  &key_bindings;

  $element{leftFrame}  = $tktag->Frame();
  $element{rightFrame} = $tktag->Frame();
  $element{rightFrameMul} = $tktag->Frame();

  # create menu
  $element{menu} = create_menu($tktag);

  # special fonts
  $tktag->fontCreate('C_big', -family => 'courier', -weight => 'bold',
		     -size => 18);

  # create Filelist
  $element{filelist} = $element{leftFrame}->Scrolled("Listbox", -width=>25,
						     -selectmode=>"extended",
						     -scrollbars=>"osre",
						     -takefocus=>1,
						     -exportselection=>0);
  $element{filelist}->bind("<Double-1>" => \&select);
  $element{filelist}->bind("<Key-Return>" => \&select);
  $var{simple}=1;
  $element{filelist}->bind("<1>" => \&check_multi);
  $element{filelist}->bind("<Control-a>" => [$element{filelist},
					     'selectionSet',"0","end"]);
  my $filter=$element{leftFrame}->Frame();
  my $cbline=$filter->Frame();
  my $illine=$filter->Frame();
  $cbline->Checkbutton(-text     => 'ID3v1',
		       -variable => \$var{v1filter},
		       -command  => \&filter_and_show,
		       -relief   => 'flat')->pack(-side=>"left");
  $cbline->Checkbutton(-text     => 'ID3v2',
		       -variable => \$var{v2filter},
		       -command  => \&filter_and_show,
		       -relief   => 'flat')->pack(-side=>"left");
  $illine->Checkbutton(-text     => 'Inverse',
		       -variable => \$var{filter_inv},
		       -command  => \&filter_and_show,
		       -relief   => 'flat')->pack(-side=>"left");
  $illine->Label(-textvariable=>\$var{visiblefiles}, -relief=>"sunken",
		 width=>5)->pack(-side=>"left", -anchor=>"e");
  $cbline->pack(-side=>"top");
  $l=$filter->Entry(-textvariable=>\$var{filter}, -width=>25)->pack(-side=>"top");
  $l->bind("<FocusOut>" => \&filter_and_show);
  $l->bind("<KeyPress-Return>" => \&filter_and_show);
  $illine->pack(-side=>"top");
  $element{rightFrameMul}->Label(-text=>"Options for automatic processing ".
				 "of serveral files")
    ->pack(-side=>"top", -expand=>1, -fill=>"x");
  # create filename-area
  my $fn1area = $element{rightFrame}->Frame(Name=>"fnframe");
  my $fn2area = $element{rightFrame}->Frame();
  $element{filenamelabel} = $fn1area->Label(-text=>"Filename:")
    ->pack(-side=>"left", anchor=>"w");
  $var{bgcolor}=$element{filenamelabel}->cget("-background");
  $l=$fn1area->Entry(-textvariable=>\$var{filename}, -validate=>"key",
		 -vcmd=>val_fn($element{filenamelabel}))
    ->pack(-side=>"left", -fill=>"x", -expand=>"yes", -anchor=>"w");

  $fn1area->Button(-text=>"Save changes", -command=>\&save)
    ->pack(-side=>"left", -anchor=>"w");
  $element{setfilename} = $fn2area->Menubutton(qw/-underline 0 -relief raised/,
					       -text => "Set Filename  --",
					       -direction => "below");
  $element{setfilename}->configure(-menu => $element{setfilename}->menu);
  $element{setfilename}->command(-label => "from ID3v1 Tag",
				 -command=>[\&setfilename, "ID3v1"]);
  $element{setfilename}->command(-label => "from ID3v2 Tag",
				 -command=>[\&setfilename, "ID3v2"]);
  $element{setfilename}->pack(-side=>"left", anchor=>"n", -padx=>15);

  $element{setid3v1} = $fn2area->Menubutton(qw/-underline 0 -relief raised/,
					       -text => "Set ID3v1  --",
					    -direction => "below");
  $element{setid3v1}->configure(-menu => $element{setid3v1}->menu);
  $element{setid3v1}->command(-label => "from Filename",
			      -command=>[\&copyfntov1]);
  $element{setid3v1}->command(-label => "from ID3v2 Tag",
			      -command=>[\&copyv2tov1]);
  $element{setid3v1}->pack(-side=>"left", anchor=>"n", -padx=>15);

  $element{setid3v2} = $fn2area->Menubutton(qw/-underline 0 -relief raised/,
					       -text => "Set ID3v2  --",
					    -direction => "below");
  $element{setid3v2}->configure(-menu => $element{setid3v2}->menu);
  $element{setid3v2}->command(-label => "from Filename",
			      -command=>[\&copyfntov2]);
  $element{setid3v2}->command(-label => "from ID3v1 Tag",
			      -command=>\&copyv1tov2);
  $element{setid3v2}->pack(-side=>"left", anchor=>"n", -padx=>15);

  $element{removebutton} = $fn2area->Menubutton(qw/-underline 0 -relief raised/,
					       -text => "Remove  --",
						-direction => "below");
  $element{removebutton}->configure(-menu => $element{removebutton}->menu);
  $element{removebutton}->command(-label => "File", 
				  -command=>sub{
				    $var{filename}="";
				    $element{filenamelabel}
				      ->configure(-background=>"red");});
  $element{removebutton}->command(-label => "ID3v1 Tag",
				  -command=>sub{
				    if (exists $var{v1}) {
				      &remove_id3v1;
				      $element{v1caption}
					->configure(-background=>"red");}});
  $element{removebutton}->command(-label => "ID3v2 Tag",
				  -command=>sub{
				    if (exists $var{v2}) {
				      &remove_id3v2;
				      $element{v2caption}
					->configure(-background=>"red");}});
  $element{removebutton}->pack(-side=>"left", anchor=>"n", -padx=>15);

  # create ID3v1 area
  my $v1area = $element{rightFrame}->Frame(Name=>"v1frame");
  my $v1caption = $v1area->Frame(-background=>"red");
  my $v1labels = $v1area->Frame();
  my $v1entries = $v1area->Frame();
  my $v2apic = $v1area->Frame();
  my $a=0;
  $element{v1caption}=$v1caption->Label(-text=>"ID3v1.1", -font=>"C_big",
					-background=>"red", -relief=>"ridge")
    ->pack(-side=>"top", -anchor=>"c", -expand=>"yes", -fill=>"x");
  $l = $v1labels->Label(-text=>"Song:")->pack(-side=>"top", -anchor=>"e");
  $v1entries->Entry(-textvariable=>\$var{v1song}, -width=>30,
		    -validate=>"key", -vcmd=>val_text($l,30))
    ->pack(-side=>"top", -anchor=>"w");
  $l = $v1labels->Label(-text=>"Artist:")->pack(-side=>"top", -anchor=>"e",
						-pady=>2);
  $v1entries->Entry(-textvariable=>\$var{v1artist}, -width=>30,
		    -validate=>"key", -vcmd=>&val_text($l,30))
    ->pack(-side=>"top", -anchor=>"w");
  $l = $v1labels->Label(-text=>"Album:")->pack(-side=>"top", -anchor=>"e");
  $v1entries->Entry(-textvariable=>\$var{v1album}, -width=>30,
		    -validate=>"key", -vcmd=>&val_text($l,30))
    ->pack(-side=>"top", -anchor=>"w");
  $l = $v1labels->Label(-text=>"Comment:")->pack(-side=>"top", -anchor=>"e",
						 -pady=>1);
  $v1entries->Entry(-textvariable=>\$var{v1comment}, -width=>30,
		    -validate=>"key", -vcmd=>val_text($l,28))
    ->pack(-side=>"top", -anchor=>"w");
  $element{genrelabel} = $v1labels->Label(-text=>"Genre:")->pack(-side=>"top",
								 -anchor=>"e");
  my $genres = ["", sort @{MP3::Tag::genres()}];
  $v1entries->BrowseEntry(-variable => \$var{v1genre}, -choices => $genres, 
			  -state=>"readonly", -browsecmd=> 
			  sub { $element{genrelabel}
				  ->configure(-background=>"yellow");
				$element{v1caption}
				  ->configure(-background=>"yellow");
				push @{$var{labels}}, $element{genrelabel} })
    ->pack(-side=>"top", -anchor=>"w");
  $l = $v1labels->Label(-text=>"Year:")->pack(-side=>"top", -anchor=>"e");
  $v1entries->Entry(-textvariable=>\$var{v1year}, -width=>4,
		    -validate=>"key", -vcmd=>val_num($l,4))
    ->pack(-side=>"top", -anchor=>"w");
  $l = $v1labels->Label(-text=>"Track:")->pack(-side=>"top", -anchor=>"e",
					       -pady=>2);
  $v1entries->Entry(-textvariable=>\$var{v1track}, -width=>4,
		    -validate=>"key", -vcmd=>val_num($l,3))
    ->pack(-side=>"top", -anchor=>"w");
  $element{apic} = $v2apic->Photo('apic');
  $element{apic}->blank;
  $v2apic->Label(-image=>'apic', -height=>150, -width=>180)
    ->pack(-side=>"top", -anchor=>"center");
  $element{apictext}=$v2apic->Label(-text=>"")->pack(-side=>"top",
						     -anchor=>"center");
  $v1caption->pack(-side=>"top", -expand=>"yes", -fill=>"x");
  $v1labels->pack(-side=>"left");
  $v1entries->pack(-side=>"left");
  $v2apic->pack(-side=>"right");

  # ID3v2 area
  my $v2area = $element{rightFrame}->Frame(Name=>"v2frame");
  my $v2caption = $v2area->Frame();
  my $v2top = $v2area->Frame();
  my $v2right = $v2area->Frame();
  my $v2buttons = $v2top->Frame();
  my $v2labent = $v2top->Frame();
  my $v2labels = $v2labent->Frame();
  my $v2entries = $v2labent->Frame();
  my $v2parea = $v2right->Frame();
  my $v2iarea = $v2right->Frame();
  $element{v2caption}=$v2caption->Label(-text=>"ID3v2.3", -font=>"C_big",
					-background=>"red", -relief=>"ridge")
    ->pack(-side=>"top", -anchor=>"c", -fill=>"x", -expand=>"yes");
  while (my ($fname,$val) = each %{$var{v2specent}}) {
    $val->{label} = $v2labels->Label(-text=>$val->{name})->pack(-side=>"top",
								-anchor=>"e");
    $val->{entry} = $v2entries->Entry(-textvariable=>\$var{"v2$fname"},
				      -width=>40, -validate=>"key",
				      -vcmd=>[\&val_v2,$element{v2caption},
					      $val->{label}, $a])
      ->pack(-side=>"top", -anchor=>"w");
  }
  $v2buttons->Button(-text=>"Add Frame", -command=>\&add_frame)
    ->pack(-side=>"left", -anchor=>"c");
  $v2buttons->Button(-text=>"Delete Frame(s)", -command=>\&del_frame)
    ->pack(-side=>"left", -anchor=>"c");
  $element{frames} = $v2iarea->Scrolled("Listbox", -scrollbars=>"re", -width=>"8",
					-selectmode=>"browse", -takefocus=>1)
    ->pack(-side=>"left");
  $element{frames}->bind("<Double-1>" => \&show_frame);
  $element{frames}->bind("<Key-Return>" => \&show_frame);
  $v2parea->Label(-textvariable=>\$var{longname})->pack(-side=>"top",
							-anchor=>"n", -pady=>5);
  $element{frameinfo} = $v2parea;
  $v2labels->pack(-side=>"left");
  $v2entries->pack(-side=>"left");
  $v2labent->pack(-side=>"left", -anchor=>"nw");
  $v2buttons->pack(-side=>"left", -fill=>"y", -expand=>"yes");
  $v2iarea->pack(-side=>"left", -anchor=>"nw");
  $v2parea->pack(-side=>"left", -fill=>"both", -expand=>"yes", -anchor=>"nw");
  $v2caption->pack(-side=>"top", -expand=>"yes", -fill=>"x");
  $v2top->pack(-side=>"top", -fill=>"x", -expand=>"yes", -anchor=>"n");
  $v2right->pack(-side=>"left", -fill=>"both", -expand=>"yes", -anchor=>"n");

  # pack left Frame
  $element{filelist}->pack(-side=>"top", -fill=>"y", -expand=>"yes");
  $filter->pack(-side=>"bottom");

  # pack right Frame
  $fn1area->pack(-side=>"top", -anchor=>"nw", -expand=>"yes", -fill=>"x");
  $fn2area->pack(-side=>"top", -anchor=>"nw", -expand=>"yes", -fill=>"x");
  $v1area->pack(-side=>"top", -anchor=>"nw", -expand=>"yes", -fill=>"x",
		-pady=>10);
  $v2area->pack(-side=>"top", -anchor=>"nw", -expand=>"yes", -fill=>"x");
  $v2parea->pack(-side=>"top", -anchor=>"nw", -expand=>"yes", -fill=>"x");

  # pack main window
  $element{menu}->pack(-side=>"top", -fill=>"x", -anchor=>"nw");
  $element{leftFrame}->pack(-side=>"left", -fill=>"y", -anchor=>"w");
  $element{rightFrame}->pack(-side=>"left",-fill=>"both",-expand=>"yes",
			     -anchor=>"nw");

  #prepare open dialog window
  $element{open} = $tktag->DialogBox(-title=>"Open directory",
				     -buttons=>["Open", "Cancel"]);
  $element{open}->add("Label", -text=>"Directory:")->pack();
  $element{open}->add("Entry", -width=>35, -textvariable=>\$var{dir})->pack();

  $element{fnformat} = $tktag->DialogBox(-title=>"Set filename format",
					 -buttons=>["Set", "Cancel"]);
  $element{fnformat}->add("Label", -text=>"Format")->pack();
  $element{fnformat}->add("Entry", -width=>35, -textvariable=>\$var{fnformat})
    ->pack();
  $element{fnformat}->add("Label", 
			  -text=>"%s - Song       %l - Album\n%a - Artist".
			         "     %t - Track\n %c - Comment    ".
			         "%g - Genre\n %y - Year".
			         "\nSee also README file")->pack();

  $element{addelframe} = $tktag->DialogBox(-buttons=>["Ok", "Cancel"]);
  $element{addelabel} = $element{addelframe}->add("Label")
    ->pack();
  $element{addelistbox} = $element{addelframe}->add("Scrolled", "Listbox",
						 -scrollbars=>"osre", -width=>50)
    ->pack(-fill=>"both", -expand=>1);

}


sub val_v2 {
  my ($label1, $label2, $change) = @_;
  if ($_[7] == -1) {
    $change=0;
    return 1;
  }
  return 1 if $change++;
  $label1->configure(-background=>"yellow");
  if (defined $label2) {
    $label2->configure(-background=>"yellow");
    push @{$var{labels}}, $label2;
  }
  return 1;
}

sub val_fn {
  my ($label1, $change) = @_;
  return 
    sub {
      if ($_[4] == -1) {
	$change=0;
	return 1;
      }
      return 1 if $change++;
      $label1->configure(-background=>"yellow");
      return 1;
    }
}


sub val_text {
  my ($label, $length, $change) = @_;
  return 
    sub {
      my ($pro, undef, undef, undef, $type) = @_; 
      return 0 if $type == 1 && length($pro) > $length;
      if ($type == -1) {
	$change=0;
	return 1;
      }
      return 1 if $change++;
      $label->configure(-background=>"yellow");
      $element{v1caption}->configure(-background=>"yellow");
      push @{$var{labels}}, $label;
      return 1;
    }
}

sub val_num {
  my ($label, $length, $change) = @_;
  return 
    sub {
      my ($pro, undef, undef, undef, $type) = @_; 
      return 0 if $type == 1 && !($pro =~ /^\d{0,$length}$/o);
      if ($type == -1) {
	$change=0;
	return 1;
      }
      return 1 if $change++;
      $label->configure(-background=>"yellow");
      $element{v1caption}->configure(-background=>"yellow");
      push @{$var{labels}}, $label;
      return 1;
    }
}

sub create_menu {
  my $menu = shift->Menu(-type=>"menubar");

  my $file=$menu->cascade(-label=>"File");
  $file->command(-label=>"Open", -command=>\&load_filelist);
  $file->separator();
  $file->command(-label=>"Exit", -command=>sub {exit 0;});

  my $opts=$menu->cascade(-label=>"Options");
  $opts->command(-label=>"Filename format", -command=>\&filename_format);

  return $menu;
}

sub tk_question {
  my $text = shift;
  my $ans = $tktag->messageBox(-text=>$text, -title=>"Question", -type=>"YesNo",
			       -default=>"No", -icon=>"question" );
  return $ans eq "Yes" ? 1 : 0;
}

sub tk_warning {
  my $text = shift;
  $tktag->messageBox(-text=>$text, -title=>"Warning", -buttons=>"Ok",
		     -icon=>"warning" );
}

####### file subs

sub load_filelist {
  $element{open}->configure(-title=>"Open directory");
  my $answer = $element{open}->Show;
  if ($answer eq "Open") {
    $var{dir} =~ s!/$!!;
    $var{dir} .= "/";
    &scan_dir;
    &filter_and_show;
  }
}

sub scan_dir {
  delete $var{files};
  opendir(DIR, $var{dir}) or return;
  $tktag->Busy;
  $tktag->update;
  my $file;
  while (defined($file = readdir(DIR))) {
    if (-d $var{dir} . $file) {
      $var{files}->{$file}={dir=>$var{dir}, isDir=>1}; 
    } elsif (-f _) {
      my $mp3=MP3::Tag->new($var{dir}.$file);
      $var{files}->{$file}={dir=>$var{dir}};
      foreach ($mp3->getTags) {
	$var{files}->{$file}->{$_}=1;
      } 
    }
  }
  closedir DIR;
  $tktag->Unbusy;
}

sub filter_and_show {
  my (@files, @dirs, $name, $val, $filter);
  $element{filelist}->delete("0", "end");
  if ($var{filter} ne "") {
    $filter = qr/$var{filter}/i;
  }
  while (($name, $val)=each %{$var{files}}) {
    if (exists $val->{isDir}) {
      push @dirs, "[$name]";
    } else {
      if (!$var{v1filter} || (!$var{filter_inv} && $val->{ID3v1})
	  || ($var{filter_inv} && !$val->{ID3v1})) {
	if (!$var{v2filter} || (!$var{filter_inv} && $val->{ID3v2})
	    || ($var{filter_inv} && !$val->{ID3v2})) {
	  if (!$filter || (!$var{filter_inv} && $name =~ $filter)
	      || ($var{filter_inv} && !($name =~ $filter))) {
	    push @files, $name;
	  }
	}
      }
    }
  }
  $element{filelist}->insert("end", sort @dirs);
  $element{filelist}->insert("end", sort @files);
  $var{visiblefiles}=$#files+1;
}


sub select {
  my $active =$element{filelist}->get("active","active");
  if ($active =~ /^\[(.*)\]$/) {
    if (exists $var{files}->{$1}->{isDir}) {
      $var{dir}.="$1/";
      &scan_dir;
      &filter_and_show;
      return;
    }
  }
  $var{filename}=$active; 
  $var{oldfilename} = $var{filename};
  my $filename = $var{dir}.$var{filename};
  $var{mp3}->close if exists $var{mp3};
  delete $var{v1};
  delete $var{v2};
  $element{filenamelabel}->configure(-background=>$var{bgcolor});
  $var{mp3} = MP3::Tag->new($filename);
  $var{mp3}->getTags;

  # remove old things
  foreach (@{$var{fpack}}) {
    $_->packForget();
  }
  $var{fpack} = [];
  $var{longname}="";
  if (exists $var{labels}) {
    while (my $label = shift @{$var{labels}}) {
      $label->configure(-background=>$var{bgcolor});
    }
  }

  # set information of ID3v1 tag
  if (exists $var{mp3}->{ID3v1}) {
    $element{v1caption}->configure(-background=>"green");
    $var{v1}=$var{mp3}->{ID3v1};
    ($var{v1song},$var{v1artist},$var{v1album},$var{v1year},$var{v1comment},$var{v1track},$var{v1genre})
      = $var{v1}->all();
  } else {
    ($var{v1song},$var{v1artist},$var{v1album},$var{v1year},$var{v1comment},$var{v1track},$var{v1genre})
      = ("","","","","","","");
    $element{v1caption}->configure(-background=>"red");
  }

  #set information of ID3v2 tag
  if (exists $var{mp3}->{ID3v2}) {
    $element{v2caption}->configure(-background=>"green");
    $var{v2}=$var{mp3}->{ID3v2};
    my $frames = $var{v2}->getFrameIDs;
    while (my ($fname, $val) = each %{$var{v2specent}}) {
      if (exists $frames->{$fname}) {
	$var{"v2$fname"} = $var{v2}->getFrame($fname);
	$val->{entry}->bind('<FocusOut>' => v2_specent_change($fname));
      } else {
	$var{"v2$fname"} = "";
	$val->{entry}->bind('<FocusOut>' => v2_specent_create($fname));
      }
    }
    if (exists $frames->{"APIC"}) {
      show_picture("APIC");
    } else {
      $element{apic}->blank;
      $element{apictext}->configure(-text=>"");
    }
    my @frames = sort keys %$frames;
    $element{frames}->delete("0","end");
    $element{frames}->insert("end", @frames);
    show_frame($frames[0],1);
  } else {
    while (my ($fname, $val) = each %{$var{v2specent}}) {
      $var{"v2$fname"}="";
      $val->{entry}->bind('<FocusOut>' => v2_specent_create($fname));
    }
    $element{v2caption}->configure(-background=>"red");
    $element{frames}->delete("0","end");
    $element{apic}->blank;
    $element{apictext}->configure(-text=>"");
  }
}

sub v2_specent_change {
  my $fname = shift;
  return sub {
    $var{v2}->change_frame($fname, $var{"v2$fname"});
    if (exists $var{current_frame} && $var{current_frame} eq $fname) {
      $var{frame_Text}->delete("0.1", "end");
      $var{frame_Text}->insert("0.1", $var{"v2$fname"});
    }
  };
}

sub v2_specent_create {
  my $fname = shift;
  return sub {
    return if $var{"v2$fname"} eq "";
    $var{v2}=$var{mp3}->newTag("ID3v2") unless exists $var{v2};
    $var{v2}->add_frame($fname, $var{"v2$fname"});
    my @allframes = $element{frames}->get(0,"end");
    push @allframes, $fname;
    $element{frames}->delete(0,"end");
    $element{frames}->insert("end", sort @allframes);
    $var{v2specent}->{$fname}->{entry}->bind('<FocusOut>' =>
					     v2_specent_change($fname));
  };
}

sub show_frame {
  my ($fname, $tagchanged) = @_;
  if (ref $fname) { # called from listbox-bind
    $fname = $fname->get("active");
  }
  save_frameinfo() unless defined $tagchanged;
  # delete last info
  foreach (@{$var{fpack}}) {
    $_->packForget();
  }
  $var{fpack} = [];
  $var{current_frame}="";
  return unless length($fname) == 4 || length($fname) == 6;
  my $info;
  $var{current_frame} = $fname;
  ($info, $var{longname}) = $var{v2}->getFrame($fname);
  (undef, $var{restrinp}) = $var{v2}->what_data($fname);
  if (ref $info) {
    my ($key, $value);
    foreach $key (sort keys %$info) {
      $value = $info->{$key};
      my $f = $element{frameinfo}->Frame();
      push @{$var{fpack}}, $f;
      if ($key =~ s/^_//) {
	my $l=$f->Label(-text=>"$key:", -justify=>"left")
	  ->pack(-side=>"left", -anchor=>"w");
	my $b=$f->Menubutton(qw/-underline 0 -relief raised/,
			     -text => "Data of " .length($value) .
			     " Bytes  --", -direction => "below");
	$b->configure(-menu => $b->menu);
	$var{"data_$key"}=$value;
	$b->command(-label => "Save Data", -command=>[\&save_data,$key]);
	$b->command(-label => "Load Data", -command=>[\&load_data,$key,$b, $l]);
	$b->command(-label => "View Data", -command=>[\&view_data,$key]);
	$b->pack(-side=>"left", anchor=>"n");
      } else {
	my $l=$f->Label(-text=>"$key:", -justify=>"left")
	  ->pack(-side=>"left", -anchor=>"w");
	if (exists $var{restrinp}->{$key}) {
	  my $state="readonly";
	  if (exists $var{restrinp}->{$key}->{"_FREE"}) {
	    $state="normal";
	    delete $var{restrinp}->{$key}->{"_FREE"};
	  }
	  $var{"frame_$key"}=$value;
	  my @inps=sort keys %{$var{restrinp}->{$key}}; 
	  $f->BrowseEntry(-variable => \$var{"frame_$key"}, -choices => \@inps,
			  -state=>$state, -width=>37, -browsecmd=>
			  sub { $l->configure(-background=>"yellow");
				$element{v2caption}
				  ->configure(-background=>"yellow");})
	    ->pack(-side=>"right", -anchor=>"e");

	} else {
	  $var{"frame_$key"} = $f->TextUndo(-height=>2, -width=>40, -wrap=>"word")
	    ->pack(-side=>"right", -anchor=>"e");
	  $var{"frame_$key"}->insert("0.0", $value);
	  $var{"frame_$key"}->bind('<Double-1>' =>
				   sub{ $var{"frame_$key"}
					  ->configure(-disable=>1);});
	  push @{$var{fpack}}, $var{"frame_$key"};
	  $var{"frame_$key"}->bind('<Key>'=>[\&yyy, $l]);
	}
      }
      $f->pack(-side=>"top", -anchor=>"w", -fill=>"x", -expand=>"yes");
    }
  } else {
    if (exists $var{restrinp}->{Text}) {
      my $state="readonly";
      if (exists $var{restrinp}->{Text}->{"_FREE"}) {
	$state="normal";
	delete $var{restrinp}->{Text}->{"_FREE"};
      }
      $var{"frame_Text"}=$info;
      my @inps=sort keys %{$var{restrinp}->{Text}};
      push @{$var{fpack}},$element{frameinfo}->BrowseEntry(
				       -variable => \$var{"frame_Text"},
				       -choices => \@inps, -width=>37,
				       -state=>$state, -browsecmd=>
				       sub { $element{v2caption}
					       ->configure(-background=>"yellow")})
	->pack(-side=>"top", -anchor=>"n");
    } else {
      $var{frame_Text} = $element{frameinfo}->TextUndo(-height=>2, -width=>40,
						       -wrap=>"word")
	->pack(-side=>"top", -anchor=>"n");
      $var{frame_Text}->insert("0.0", $info);
      push @{$var{fpack}}, $var{frame_Text}; 
      if (exists $var{v2specent}->{$fname}) {
	$var{frame_Text}->bind('<Key>'=>[\&xxx, $fname]);
      }
    }
  }
}

sub save_frameinfo {
  # save last info
  return unless exists $var{current_frame};
  my ($format, $resinp) = $var{v2}->what_data($var{current_frame});
  my @data=();
  foreach (@$format) {
    if (/^_/) {
      push @data, $var{"data$_"};
      next;
    }
    my $d;
    if ($var{"frame_$_"} =~ /Text/) {
      $d= $var{"frame_$_"}->get("0.1","end");
    } else {
      $d= $var{"frame_$_"};
      $d= $resinp->{$_}->{$d} if (defined $resinp->{$_}->{$d});
    };
    chomp $d;
    $d =~ s/ +$//;
    push @data, $d; 
  }
  $var{v2}->change_frame($var{current_frame}, @data);
}

sub xxx {
  my ($textobject, $fname) = @_;
  my $text = $textobject->get("0.1","end");
  chomp($text);
  $var{"v2$fname"} = $text;
  $var{v2specent}->{$fname}->{label}->configure(-background=>"yellow");
  $element{v2caption}->configure(-background=>"yellow");
}

sub yyy {
  $_[1]->configure(-background=>"yellow");
  $element{v2caption}->configure(-background=>"yellow");
}


sub show_picture {
  my $fname = shift;
  my $frame = $var{v2}->getFrame($fname);
  if ($frame->{"MIME type"} =~ /image\/(gif|jpe?g|bmp)/i) { 
    my $type = lc $1;
    $type =~ s/jpg/jpeg/;
    open(TMP, ">/tmp/_tk_temp.jpg");
    binmode TMP;
    print TMP $frame->{_Data};
    close TMP;
    $element{apic}->configure(-format=>$1, -file=>"/tmp/_tk_temp.jpg");
    my $text .= $frame->{"Picture Type"};
    $text = $frame->{Description} if $text eq "Other";
    $text = "ID3v2.3-" . uc($fname) . ": ". $text; 
    $element{apictext}->configure(-text=>$text);
    unlink "/tmp/_tk_temp.jpg";
  }
}

sub save {
  # save changes to filename
  if ($var{filename} ne $var{oldfilename}) {
    return 0 unless change_filename();
  }
  $element{filenamelabel}->configure(-background=>$var{bgcolor});
  #save changes of ID3v1 tag
  if ($element{v1caption}->cget("-background") eq "yellow") {
    my @fields;
    for (qw/v1song v1artist v1album v1year v1comment v1track v1genre/) {
      push @fields, $var{$_};
    }
    $var{v1}=$var{mp3}->newTag("ID3v1") unless exists $var{v1};
    $var{v1}->all(@fields);
    $var{v1}->writeTag;
    $var{v1genre}=$var{v1}->genre();
    $element{v1caption}->configure(-background=>"green");
  } elsif (exists $var{v1} && $element{v1caption}->cget("-background") eq "red") {
    $var{v1}->removeTag;
    delete $var{v1};
  }

  #save changes of ID3v2 tag
  if ($element{v2caption}->cget("-background") eq "yellow") {
    $var{v2}=$var{mp3}->newTag("ID3v2") unless exists $var{v2};
    save_frameinfo();
    while (my ($fname, $val)=each %{$var{v2specent}}) {
      if ($var{"v2$fname"} ne "" &&
	  $val->{label}->cget("-background") eq "yellow") {
	my $d=$var{"v2$fname"};
	$d=~s/ +$//;
	if (defined $var{v2}->getFrame($fname)) {
	  $var{v2}->change_frame($fname, $d);
	} else {
	  $var{v2}->add_frame($fname, $d);
	}
	$val->{label}->configure(-background=>$var{bgcolor});
      }
    }
    $var{v2}->write_tag;
    $element{v2caption}->configure(-background=>"green");
    foreach my $v2e ( @{$var{fpack}}) {
      foreach ($v2e->children) {
	$_->configure(-background=>$var{bgcolor}) if /Label/;
      }
    }
  } elsif (exists $var{v2} &&
	   $element{v2caption}->cget("-background") eq "red") {
    $var{v2}->remove_tag;
    delete $var{v2};
  }
  if (exists $var{labels}) {
    while (my $label = shift @{$var{labels}}) {
      $label->configure(-background=>$var{bgcolor});
    }
  }
}

sub change_filename {
  my $success = 0;
  if ($var{filename} eq "") {
    if (tk_question("Filename is empty. Do you want to ".
		    "delete $var{oldfilename}?")) {
      $var{mp3}->close;
      if (unlink $var{dir}.$var{oldfilename}) {
	remove_id3v1();
	remove_id3v2();
	$element{v1caption}->configure(-background=>"red");
	$element{v2caption}->configure(-background=>"red");
	$element{filelist}->delete("active","active");
	delete $var{files}->{$var{oldfilename}};
	$success = 1;
      } else { 
	tk_warning("Cannot delete file.");
      }
    }
  } elsif (-e $var{dir}.$var{filename}) {
    if (-f _) {
      if (tk_question("Files $var{filename} exists. Do you want".
		      " to overwrite it?")) {
	goto re;
      }
    } else {
      tk_warning("$var{filename} exists and it isn't a plain file.".
		 " Can't rename $var{oldfilename}!");
    }
  } else {
  re:
    if (rename($var{dir}.$var{oldfilename}, $var{dir}.$var{filename}) ||
	(system("mv", $var{dir}.$var{oldfilename}, $var{dir}.$var{filename})==0)) {
      $var{files}->{$var{filename}}=$var{files}->{$var{oldfilename}};
      delete $var{files}->{$var{oldfilename}};
      $var{oldfilename} = $var{filename};
      my $index=$element{filelist}->index("active");
      filter_and_show;
      $element{filelist}->see($index);   
      $element{filelist}->activate($index);   
      $var{mp3}->{filename}=$var{dir}.$var{filename};
      $success = 1;
    } else {
      tk_warning("Couldn't rename $var{oldfilename} to $var{filename}");
    }
  }
  return $success;
}

sub remove_id3v1 {
  for (qw/v1song v1artist v1album v1year v1comment v1track v1genre/) {
    $var{$_} = "";
  }
}

sub remove_id3v2 {
  for (keys %{$var{v2specent}}) {
    $var{"v2$_"} = "";
  }
  $element{frames}->delete("0","end");
  foreach (@{$var{fpack}}) {
    $_->packForget();
  }
  $var{fpack} = [];
  $var{longname}="";
}

sub add_frame {
  return unless exists $var{mp3};
  $element{addelframe}->configure(-title=>"Add Frame");
  $element{addelabel}->configure(-text=>"Select a frame to add:");
  $element{addelistbox}->delete("0","end");
  $var{v2}=$var{mp3}->newTag("ID3v2") unless exists $var{v2};
  my $list = $var{v2}->supported_frames;
  my @list = map {"$_ - $list->{$_}"} sort keys %$list;
  $element{addelistbox}->insert("end",@list);
  if ($element{addelframe}->Show() eq "Ok") {
    $element{v2caption}->configure(-background=>"yellow");
    my $fname= substr $element{addelistbox}->get("active","active"),0,4;
    $fname = $var{v2}->add_frame($fname);
    my $index=0;
    my $maxindex = $element{frames}->index("end");
    while ($index<$maxindex && $element{frames}->get($index,$index) lt $fname) {
      $index++;
    }
    $element{frames}->insert($index, $fname);
    $element{frames}->activate($index);
    $element{frames}->selectionSet($index);
    show_frame($fname);
  }
}

sub del_frame {
  return unless exists $var{v2};
  $element{addelframe}->configure(-title=>"Delete Frame");
  $element{addelabel}->configure(-text=>"Select a frame to delete:");
  $element{addelistbox}->delete("0","end");
  my $list = $var{v2}->getFrameIDs;
  my @list = map {"$_ - $list->{$_}"} sort keys %$list;
  $element{addelistbox}->insert("end",@list);
  if ($element{addelframe}->Show() eq "Ok") {
    $element{v2caption}->configure(-background=>"yellow");
    my $fname= $element{addelistbox}->get("active","active");
    $fname =~ s/^([A-Z0-9]+) .*/$1/;
    $var{v2}->remove_frame($fname);
    my $index=0;
    my $maxindex = $element{frames}->index("end");
    while ($index<$maxindex && $element{frames}->get($index,$index) ne $fname) {
      $index++;
    }
    $element{frames}->delete($index,$index);
    if ($var{current_frame} eq $fname) {
      show_frame($element{frames}->get("active"),1);
    }
    if (exists $var{v2specent}->{$fname}) {
      $var{"v2$fname"}="";
      $var{v2specent}->{$fname}->{label}->configure(-background=>"yellow");
    }
  }
}

sub check_multi {
  my ($h,$w,%info);
  my @sel = $element{filelist}->curselection();
  if ($#sel >0 && $var{simple}) {
    $element{rightFrame}->packForget;
    $element{rightFrameMul}->pack(-side=>"left",-fill=>"both",
				  -expand=>"yes", -anchor=>"nw");
    $var{simple}=0;
  } elsif ($#sel == 0 && ! $var{simple}) {
    $element{rightFrameMul}->packForget;
    $element{rightFrame}->pack(-side=>"left",-fill=>"both",
			       -expand=>"yes", -anchor=>"nw");
    $var{simple}=1;
  }
}

sub setfilename {
  my $tag = shift; # may be 'ID3v1', 'ID3v2' or 'filename'
  $tag =~ s/ID3//;
  return undef unless exists $var{$tag} || $tag eq "filename";
  my $new = $var{setfilename}->{stencil};
  my $i=0;
  foreach my $part (@{$var{setfilename}->{details}}) {
    my $code=$part->{tag};
    if ($tag eq "v2") {
      $code =~ s/song/TIT2/ ||
      $code =~ s/album/TALB/ ||
      $code =~ s/artist/TPE1/;
    }
    my $txt="";
    if ($tag eq "filename") {
      if ($code eq "song" || $code eq "artist" ||
	  $code eq "album" || $code eq "track") {
	$txt = $var{mp3}->{filename}->$code($var{dir}.$var{filename});
      }
    } else {
      $txt = $var{"$tag$code"};
    }
    $txt =~ s/ *$//;
    $txt = substr $txt, 0, $part->{length} if exists $part->{length} &&
      ((! exists $part->{fill}) || exists  $part->{precise} );
    $txt = $part->{fill} x ($part->{length}-length($txt)) . $txt
      if exists $part->{fill};
    $new =~ s/%$i/$txt/;
    $i++;
  }
  $new =~ s/ /_/g if exists $var{setfilename}->{nospaces};
  $var{filename}=$new;
  $element{filenamelabel}->configure(-background=>"yellow");
  return 1;
}

sub formatstr {
  my $format = shift;
  my %tags = (s=>"song", a=>"artist", l=>"album", y=>"year",
	      g=>"genre", t=>"track");
  my @fmt;

  while ($format =~ /%([0-9]*)(?:(!)?:(.))?([salygt])/g) {
    my $t;
    $t->{length}=$1 if defined $1 && $1 ne "";
    $t->{precise}=1 if defined $2 && $2 ne "";
    $t->{fill}=$3 if defined $3 && $3 ne "";
    $t->{tag} = $tags{$4} if defined $4 && $4 ne "";
    push @fmt, $t if defined $4 && $4 ne "";
  }
  my $i=0;
  $format =~ s/%([0-9]*)(?:(!)?:(.))?([salygt])/"%".$i++/eg;
  $var{setfilename}->{stencil}=$format;
  $var{setfilename}->{details}=\@fmt;
}

sub element_change {
  my $element = shift;

  if ($element->PathName =~/v1/) {
    $element{v1caption}->configure(-background=>"yellow");
  } elsif ($element->PathName =~/v2/) {
    $element{v2caption}->configure(-background=>"yellow");
  } elsif ($element->PathName =~/fn/) {
    $element{filenamelabel}->configure(-background=>"yellow");
  }
}

sub use_ucase {
 my $element=shift;
 if ($element =~ /Entry/) {
   my $evar = $element->cget(-textvariable);
   my $ovar = $$evar;
   $$evar =~ tr/[a-z]/[A-Z]/;
   $$evar =~ s/\.MP3$/.mp3/;
   if ($ovar ne $$evar) {
     element_change($element);
   }
 } elsif ($element =~ /Text/) {
   my $text = $element->get("0.1","end");
   chomp $text;
   return if $text eq "";
   if ($text =~ tr/[a-z]/[A-Z]/) {
     element_change($element);
     $element->delete("0.1","end");
     $element->insert("end",$text);
   }
 }
}

sub use_lcase {
 my $element=shift;

 if ($element =~ /Entry/) {
   my $evar = $element->cget(-textvariable);
   return if $$evar eq "";
   if ($$evar =~ tr/[A-Z]/[a-z]/) {
     element_change($element);
   }
 } elsif ($element =~ /Text/) {
   my $text = $element->get("0.1","end");
   chomp $text;
   return if $text eq "";
   if ($text =~ tr/[A-Z]/[a-z]/) {
     element_change($element);
     $element->delete("0.1","end");
     $element->insert("end",$text);
   }
 }
}

sub use_ucase_first {
 my $element=shift;

 if ($element =~ /Entry/) {
   my $evar = $element->cget(-textvariable);
   return if $$evar eq "";
   my $ovar=$$evar;
   $$evar=ucase_first($$evar);
   if ($ovar ne $$evar) {
     element_change($element);
   }
 } elsif ($element =~ /Text/) {
   my $text = $element->get("0.1","end");
   chomp $text;
   return if $text eq "";
   my $otext = ucase_first($text);
   if ($otext ne $text) {
     $element->delete("0.1","end");
     $element->insert("end",$otext);
     element_change($element);
   }
 }
}

sub ucase_first {
  my $text=shift;
  $text =~ s/(\w+)/\L\u$1/gm;
  $text =~ s/('[A-Z])/\L$1/g; #');
  $text =~ s/\.Mp3$/.mp3/;
  return $text;
}

sub use_spaces {
 my $element=shift;
 if ($element =~ /Entry/) {
   my $evar = $element->cget(-textvariable);
   return if $$evar eq "";
   my $ovar=$$evar;
   $$evar=spaces($$evar);
   if ($ovar ne $$evar) {
     element_change($element);
   }
 }
}

sub spaces {
  my $text=shift;
  $text =~ s/%20/_/g;
  if ((($text =~ tr/././) >2)) {
    $text =~ s/\./ /g;
    $text =~ s/ (mp3)$/.$1/i;
    $text =~ s/(\w)-(\w)/$1 - $2/g;
  } elsif ($text =~ /_/) {
    $text =~ s/_/ /g;
    $text =~ s/(\w)-(\w)/$1 - $2/g;
  } else {
    $text =~ s/ /_/g;
    $text =~ s/_-_/-/g;
  }
  $text=~ s/ +/ /g;
  return $text;
}


sub filename_format {
  if ( $element{fnformat}->Show eq "Set") {
    formatstr($var{fnformat});
  }
}

sub view_data {
  my $key= shift;
  warn "Viewing of $key of $var{current_frame} not supported yet\n";
}

sub load_data {
  my ($key, $button,$label)= @_;
  my @types=(["All files", "*"]);
  my $file = $tktag->getOpenFile(-filetypes => \@types);
  if (open (LOAD, $file)) {
    binmode LOAD;
    local $/;
    undef $/;
    $var{"data_$key"}=<LOAD>;
    close LOAD;
    warn "Please set mime type according to new data\n";
    $button->configure(-text => "Data of " .length($var{"data_$key"}) .
		       " Bytes  --");
    $label->configure(-background=>"yellow");
    $element{v2caption}->configure(-background=>"yellow");
  } else {
    warn "Couldn't open $file for saving $var{current_frame}.$key";
  }
}

sub save_data {
  my $key= shift;
  my @types=(["All files", "*"]);
  my $file = $tktag->getSaveFile(-filetypes => \@types,
			     -initialfile => 'Untitled',
			     -defaultextension => '.dat');
  if (open (SAVE, ">$file")) {
    binmode SAVE;
    print SAVE $var{"data_$key"};
    close SAVE;
  } else {
    warn "Couldn't open $file for saving $var{current_frame}.$key";
  }
}

sub copyv1tov2 {
  my %v1tov2 = (artist=>"TPE1", album=>"TALB", song=>"TIT2", 
	        year=>"TYER", track=>"TRCK", comment=>"COMM", genre=>"TCON");
  return unless exists $var{v1};
  $var{v2}=$var{mp3}->newTag("ID3v2") unless exists $var{v2};
  my $frames = $var{v2}->getFrameIDs;
  while (my ($v1,$v2) = each %v1tov2) {
    next if $var{"v1$v1"} eq "";
    my ($data, $restr) = $var{v2}->what_data($v2);
    my @newdata;
    if ($#{$data}==0) {
      @newdata = ($var{"v1$v1"});
    } else {
      foreach (@$data) {
	if ($_ eq "Text") {
	  push @newdata, $var{"v1$v1"};
	} else {
	  push @newdata, "";
	}
      }
    }
    if (exists $frames->{$v2}) {
      $var{v2}->change_frame($v2, @newdata);
    } else {
      $var{v2}->add_frame($v2, @newdata);
      add2framelist($v2);
    }
    if (exists $var{v2specent}->{$v2}) {
      $var{"v2$v2"}=$var{"v1$v1"};
      $var{v2specent}->{$v2}->{label}->configure(-background=>"yellow");
    }
  }
  $element{v2caption}->configure(-background=>"yellow");
}

sub copyv2tov1 {
}

sub copyfntov1 {
  $var{v1}=$var{mp3}->newTag("ID3v1") unless exists $var{v1};
  foreach (qw/song artist album track/) {
    $var{"v1$_"}=$var{mp3}->{filename}->$_($var{dir}.$var{filename});
  }
}

sub copyfntov2 {
}

sub add2framelist {
  my $fname = shift;
  my $index=0;
  my $maxindex = $element{frames}->index("end");
  while ($index<$maxindex && $element{frames}->get($index,$index) lt $fname) {
    $index++;
  }
  $element{frames}->insert($index, $fname);
  $element{frames}->activate($index);
  $element{frames}->selectionSet($index);	
}

sub autosetfilename {
  foreach (@{$var{autoinfo}}) {
    last if setfilename($_);
  }
}
