package GuiBuilder;

use 5.006;
use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# Copyright (c) 2014 Sandeep Vaniya. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it under 
# the same terms as Perl itself.
#------------------------------------------------------------------------------
package GuiBuilder;

use Tk;
require Tk::MsgBox;
require Tk::Pane;

sub new() {
  my $this = {};
  bless $this;
  return $this;
}

my  $gui_file;
my  @gui_options_array = ();
my  %field_ref_hash;
my  %radio_button_ref_hash;
my  %place_occupied_hash;
my  $DBG_ON = 0;


my $F_GI;
my @sub_decl_array;
my @grid_array;
my @name_array;
my @radio_button_name_array;
my $pad_x_all = 10;
my $pad_y_all = 2;
my $TYPE_IDX = 0;
my $NAME_IDX = 1;
my $LOC_IDX  = 2;
my $LIST_IDX = 3;
my $RADIO_BUTTON_GRP_IDX = 3;
my $DBG_ON = 0;
my %radio_button_group_hash;
my $main;

#------------------------------------------------------------------------------
# These subroutines are for generating perl gui script based on info provided.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
sub generate_gui_file {
  if($DBG_ON) {
    print("gui_file = $gui_file.\n");
    print("gui_options_array = @gui_options_array.\n");
  }
  open(F_GI, ">$gui_file") or die("$!");
  &process_options_array();
  &update_gui_file("Auto Generated Gui");
  &declare_subroutines(@sub_decl_array);
  &define_process_option_subroutine();
  &define_clear_text_subroutine();
  &define_deselect_radio_button_subroutine();
  close(F_GI);
  my $msg_box = $main->MsgBox(-title => "Gui File Generated", -icon=>'info', -type=>'ok', -message=>"Generated '$gui_file'...\n");
  my $button = $msg_box->Show;
  print("Generated '$gui_file'...\n");
  exit;
}

#------------------------------------------------------------------------------
sub get_max_frame {
  my $option_str;
  my @option_param_array;
  my $max_frame = 0;

  for(my $opc_cnt = 0; $opc_cnt < @gui_options_array; $opc_cnt++) {
    $option_str = $gui_options_array[$opc_cnt];
    @option_param_array = split(/#/, $option_str);
    my ($frame, $row, $column) = &get_location_details($option_param_array[$LOC_IDX]);
    if($max_frame < $frame) {
      $max_frame = $frame;
    }
  }
  if($DBG_ON) { print("max_frame = $max_frame.\n"); }
  return $max_frame;
}

#------------------------------------------------------------------------------
sub update_gui_file {
  my ($title) = @_;
  my $max_frames;
  my %row_start_for_frame;
  my %num_row_in_frame;
  my $tmp_file_name = "tmp.gui";

  open(F_TMP, ">$tmp_file_name") or die("$!");
print F_TMP <<EOF
use strict;
use Tk;
require Tk::MsgBox;
require Tk::Pane;

my %field_ref_hash;
my %radio_button_ref_hash;
& main();

sub main {
  my \$main;
  my \$row_num_1;

  \$main = MainWindow->new;
  \$main->configure(-title => '$title');
  my \$pane = \$main->Scrolled('Pane', -scrollbars=>'osoe',-sticky=>'ewns',-width=>1000, -height=>500);
  my \$sframe = \$pane->Frame();
EOF
;
  print F_TMP "\n";
  # Declaring the frames.
  $max_frames = &get_max_frame();
  for(my $idx = 1; $idx <= $max_frames; $idx++) {
    my $frame_name = "\$frame_"."$idx";
    print F_TMP "  my $frame_name = \$sframe->Frame();\n";
    $row_start_for_frame{$idx} = 1;
    $num_row_in_frame{$idx} = 0;
  }
  print F_TMP "\n";

  # Find maximum row number for each frame.
  for(my $grid_cnt = 0; $grid_cnt < @grid_array; $grid_cnt++) {
    my $grid_str = $grid_array[$grid_cnt];
    my ($field_name, $frame, $row, $col) = &unpack_grid_data($grid_str);
    if($DBG_ON) { print("num_row_in_frame{$frame} = $num_row_in_frame{$frame}, row = $row.\n"); }
    if($num_row_in_frame{$frame} < $row) {
      $num_row_in_frame{$frame} = $row;
    }
    if($DBG_ON) { print("num_row_in_frame{$frame} = $num_row_in_frame{$frame}.\n"); }
  }

  # Generating starting row number for each frame.
  for(my $idx = 1; $idx <= $max_frames; $idx++) {
    my $id_2;
    for($id_2 = 1; $id_2 < $idx; $id_2++) {
      $row_start_for_frame{$idx} += $num_row_in_frame{$id_2};
    }
  }

  close(F_GI);
  open(F_GI, "<$gui_file") or die("$!");
  # Copying existing code from gui_file to tmp file.
  my $line;
  while($line = <F_GI>) {
    print F_TMP $line;
  }
  close(F_TMP);
  close(F_GI);

  # Copying content from tmp file to gui_file.
  open(F_GI, ">$gui_file") or die("$!");
  open(F_TMP, "<$tmp_file_name") or die("$!");
  while($line = <F_TMP>) {
    print F_GI $line;
  }
  close(F_TMP);

  # Adding new code at the end in gui file.
  print F_GI "  # Adding grids for different frames for different groups.\n";
  print F_GI "  \$pane -> grid(-row=>1,-column=>1,-columnspan=>1,-sticky=>'w');\n";
  print F_GI "  \$sframe -> grid(-row=>1,-column=>1,-columnspan=>1,-sticky=>'w');\n";
  my $frame_name;
  for(my $idx = 1; $idx <= $max_frames; $idx++) {
    $frame_name = "\$frame_"."$idx";
    my $row_var_name = "\$row_num_"."$idx";
    print F_GI "  my $row_var_name = $row_start_for_frame{$idx};\n";
    print F_GI "  $frame_name -> grid(-row=>$row_var_name,-column=>1,-columnspan=>1,-sticky=>'w');\n";
  }
  print F_GI "  my \$developer = $frame_name->Label(-text => \"Developed By: Sandeep Vaniya, eInfochips Ltd.\", -border=>2, -relief=>'ridge');\n";
  print F_GI "\n";

  print F_GI "  # Adding grids for different objects.\n";
  for(my $grid_cnt = 0; $grid_cnt < @grid_array; $grid_cnt++) {
    my $grid_str = $grid_array[$grid_cnt];
    my ($field_name, $frame, $row, $col) = &unpack_grid_data($grid_str);
    print F_GI "  $field_name->grid(-row=>$row,-column=>$col,-padx=>$pad_x_all,-pady=>$pad_y_all,-sticky=>'w');\n";
  }
  my $row_num = $row_start_for_frame{$max_frames} + $num_row_in_frame{$max_frames} + 1;
  print F_GI "  \$developer->grid(-row=>$row_num,-column=>1,-padx=>$pad_x_all,-pady=>$pad_y_all,-sticky=>'w');\n";

  print F_GI "\n";
  print F_GI<<EOF
  MainLoop;
} # main
EOF
;

}

#------------------------------------------------------------------------------
sub process_options_array {
  my $option_str;
  my @option_param_array;

  for(my $opc_cnt = 0; $opc_cnt < @gui_options_array; $opc_cnt++) {
    $option_str = $gui_options_array[$opc_cnt];
    @option_param_array = split(/#/, $option_str);
    if($option_param_array[$TYPE_IDX] =~ /^Checkbutton$/) {
      process_check_button(@option_param_array);
    }
    elsif($option_param_array[$TYPE_IDX] =~ /^Button$/) {
      process_button(@option_param_array);
    }
    elsif($option_param_array[$TYPE_IDX] =~ /^Text$/) {
      process_text_box(@option_param_array);
    }
    elsif($option_param_array[$TYPE_IDX] =~ /^Radiobutton$/) {
      process_radio_button(@option_param_array);
    }
    elsif($option_param_array[$TYPE_IDX] =~ /^Listbox$/) {
      process_list_box(@option_param_array);
    }
    elsif($option_param_array[$TYPE_IDX] =~ /^Label$/) {
      process_label(@option_param_array);
    }
    else {
      print("ERROR: Illegal Options specified.\n");
    }
  }
  if(@gui_options_array == 0) {
    my $msg_box = $main->MsgBox(-title => "No Options Specified...", -icon=>'error', -type=>'ok', -message=>"No Options are specified...\n");
    my $button = $msg_box->Show;
    exit;
  }
}

#------------------------------------------------------------------------------
sub unpack_grid_data {
  my ($grid_str) = @_;
  my @grid_data = split(/#/, $grid_str);
  if($DBG_ON) { print("grid_data = @grid_data.\n"); }
  return @grid_data;
}

#------------------------------------------------------------------------------
sub get_location_details {
  my ($loc_str) = @_;
  my $loc_str_1;
  my @loc_array = split(/-LOC-/, $loc_str);
  $loc_str_1 = $loc_array[1];
  @loc_array = split(/,/, $loc_str_1);
  my $frame  = $loc_array[0];
  my $row    = $loc_array[1];
  my $column = $loc_array[2];
  if($DBG_ON) { print("loc_str = $loc_str, loc_str_1 = $loc_str_1, frame = $frame, row = $row, column = $column.\n"); }
  return ($frame, $row, $column);
}

#------------------------------------------------------------------------------
sub process_check_button {
  my (@option_array) = @_;

  my ($frame_num, $row_num, $col_num) = &get_location_details($option_array[$LOC_IDX]);
  my $name = $option_array[$NAME_IDX];
  my $orig_name = $name;
  $name =~ s/ /_/g;
  $name = lc($name);
  my $button_name = "\$"."$name"."_chk_button";
  my $var_name = "\$"."$name"."_chk_button_var";
  my $frame_name = "\$"."frame_"."$frame_num";

  print F_GI<<EOF
  # logic for '$orig_name' Checkbutton.
  my $var_name = "0";
  my $button_name = $frame_name->Checkbutton(-text => '$orig_name', -variable => \\$var_name);
  $button_name->deselect();
  \$field_ref_hash{$name} = \\$var_name;

EOF
;
  push(@grid_array, "$button_name#$frame_num#$row_num#$col_num");
  push(@name_array, "Checkbutton#$name");
}

#------------------------------------------------------------------------------
sub process_button {
  my (@option_array) = @_;

  my ($frame_num, $row_num, $col_num) = &get_location_details($option_array[$LOC_IDX]);
  my $name = $option_array[$NAME_IDX];
  my $orig_name = $name;
  $name =~ s/ /_/g;
  $name = lc($name);
  my $button_name = "\$"."$name"."_button";
  my $sub_name = "$name" . "_action";
  my $frame_name = "\$"."frame_"."$frame_num";

  print F_GI<<EOF
  # logic for '$orig_name' Button.
  my $button_name = $frame_name->Button(-text => ' $orig_name ', -command => sub{$sub_name();}); 

EOF
;
  push(@sub_decl_array, "$sub_name#-NO_ARG-");
  push(@grid_array, "$button_name#$frame_num#$row_num#$col_num");
  
}

#------------------------------------------------------------------------------
sub process_radio_button {
  my (@option_array) = @_;

  my ($frame_num, $row_num, $col_num) = &get_location_details($option_array[$LOC_IDX]);
  my $name = $option_array[$NAME_IDX];
  my $group = $option_array[$RADIO_BUTTON_GRP_IDX];
  my $group_key = "grp__"."$group"."_"."$frame_num";
  my $orig_name = $name;
  $name =~ s/ /_/g;
  $name = lc($name);
  my $button_name = "\$"."$name"."_radio_button";
  my $saved_name;

  $saved_name = $name;

  print F_GI ("  # logic for '$orig_name' Radiobutton.\n");

  if($group =~ /^NA$/i) {
    push(@name_array, "Radiobutton#$name");
    $var_name = "\$"."$name"."_radio_button_var";
    print F_GI ("  my $var_name;\n");
  }
  else {
    if(exists($radio_button_group_hash{$group_key}) > 0) {
    }
    else {
      $name = $group_key;
      push(@name_array, "Radiobutton#$name");
      $radio_button_group_hash{$group_key} = 1;
      $var_name = "\$"."$group_key"."_var";
      print F_GI ("  my $var_name;\n");
    }
  }
  push(@radio_button_name_array, "Radiobutton#$saved_name");

  my $frame_name = "\$"."frame_"."$frame_num";

  print F_GI<<EOF
  my $button_name = $frame_name->Radiobutton(-text => '$orig_name', -variable => \\$var_name, -value => '$orig_name');
  $button_name->deselect();
  \$field_ref_hash{$name} = \\$var_name;
  \$radio_button_ref_hash{$saved_name} = $button_name;

EOF
;
  push(@grid_array, "$button_name#$frame_num#$row_num#$col_num");
}

#------------------------------------------------------------------------------
sub process_text_box {
  my (@option_array) = @_;

  my ($frame_num, $row_num, $col_num) = &get_location_details($option_array[$LOC_IDX]);
  my $name = $option_array[$NAME_IDX];
  my $orig_name = $name;
  $name =~ s/ /_/g;
  $name = lc($name);
  my $text_box_name = "\$"."$name"."_text_box";
  my $frame_name = "\$"."frame_"."$frame_num";

  print F_GI<<EOF
  # logic for '$orig_name' Text box.
  my $text_box_name = $frame_name->Text(-width => '30', -height => '1');
  \$field_ref_hash{$name} = $text_box_name;

EOF
;
  push(@grid_array, "$text_box_name#$frame_num#$row_num#$col_num");
  push(@name_array, "Text#$name");
}

#------------------------------------------------------------------------------
sub process_label {
  my (@option_array) = @_;

  my ($frame_num, $row_num, $col_num) = &get_location_details($option_array[$LOC_IDX]);
  my $name = $option_array[$NAME_IDX];
  my $orig_name = $name;
  $name =~ s/ /_/g;
  $name = lc($name);
  my $label_name = "\$"."$name"."_label";
  my $frame_name = "\$"."frame_"."$frame_num";

  print F_GI<<EOF
  # logic for '$orig_name' Label.
  my $label_name = $frame_name->Label(-text => "$orig_name");

EOF
;
  push(@grid_array, "$label_name#$frame_num#$row_num#$col_num");
}

#------------------------------------------------------------------------------
sub process_list_box {
  my (@option_array) = @_;

  my ($frame_num, $row_num, $col_num) = &get_location_details($option_array[$LOC_IDX]);
  my $name = $option_array[$NAME_IDX];
  my $list_str = $option_array[$LIST_IDX];
  my $frame_name = "\$"."frame_"."$frame_num";
  
  my $max_width;

  my @list_array = split(/,/, $list_str);
  my $max_depth = @list_array + 1;
  if($max_depth > 5) {
    $max_depth = 5;
  }
  $max_width = length($list_array[0]);
  $list_str = "\"$list_array[0]\"";
  for(my $idx = 1; $idx < @list_array; $idx++) {
    if($max_width < length($list_array[$idx])) {
      $max_width = length($list_array[$idx]);
    }
    $list_str = $list_str . ",\"$list_array[$idx]\"";
  }
  $max_width += 5;

  my $orig_name = $name;
  $name =~ s/ /_/g;
  $name = lc($name);
  my $list_box_name = "\$"."$name"."_button";
  my $sub_name = "$name" . "_action";

  print F_GI<<EOF
  # logic for '$orig_name' Listbox.
  my $list_box_name = $frame_name->Scrolled("Listbox", -selectmode=>'single', -exportselection=>0, -width=>$max_width, -height=>$max_depth);
  $list_box_name -> insert('end', $list_str);
  $list_box_name -> activate(0);
  \$field_ref_hash{$name} = $list_box_name;

EOF
;
  push(@grid_array, "$list_box_name#$frame_num#$row_num#$col_num");
  push(@name_array, "Listbox#$name");
}

#------------------------------------------------------------------------------
sub declare_subroutines {
  my (@sub_decl_array) = @_;
  my $sub_str;
  my @sub_array;
  my $sub_name;
  my $sub_args;
  my $sub_decl_str;

  for(my $sub_cnt = 0; $sub_cnt < @sub_decl_array; $sub_cnt++) {
    $sub_str = $sub_decl_array[$sub_cnt];
    @sub_array = split(/#/, $sub_str);
    $sub_name = $sub_array[0];
    $sub_args = "";
    $sub_decl_str = "#------------------------------------------------------------------------------\nsub $sub_name {\n";
    # $sub_decl_str .= "  &get_gui_options();\n"; # TODO: To be removed.
    if($sub_array[1] !~ /-NO_ARG-/) {
      my $idx;
      for($idx = 1; $idx < (@sub_array - 1); $idx++) {
        $sub_args = $sub_args . $sub_array[$idx] . ", ";
      }
      $sub_args = $sub_args . $sub_array[$idx];
      $sub_decl_str = $sub_decl_str . "  my ($sub_args) = \@_;\n}\n";
    }
    else {
      $sub_decl_str = $sub_decl_str . "} # $sub_name \n";
    }
    print F_GI ("$sub_decl_str\n");
  }
}

#------------------------------------------------------------------------------
sub define_process_option_subroutine {
  my @tmp_array;
  my $field_type;
  my $field_name;
  my @return_val_array;
  my $return_val_str;
  my $var_name;
  my $list_index;
  my $list_box;
  my $sub_name;
  
  $sub_name = "get_gui_options";
  print F_GI ("#------------------------------------------------------------------------------\nsub $sub_name {\n");
  print F_GI ("  my \$list_index;\n");
  print F_GI ("  my \$list_box;\n");
  for(my $idx = 0; $idx < @name_array; $idx++) {
    @tmp_array = split(/#/, $name_array[$idx]);
    $field_type = $tmp_array[0];
    $field_name = $tmp_array[1];
    print F_GI ("  # Processing value for '$field_name' $field_type.\n");
    if($field_type =~ /Checkbutton/) {
      $var_name = $field_name . "_chk_button_var";
      print F_GI ("  my \$$var_name = \${\$field_ref_hash{$field_name}};\n\n");
      push(@return_val_array, "\$$var_name");
    }
    elsif($field_type =~ /Radiobutton/) {
      $var_name = $field_name . "_radio_button_var";
      print F_GI ("  my \$$var_name = \${\$field_ref_hash{$field_name}};\n\n");
      push(@return_val_array, "\$$var_name");
    }
    elsif($field_type =~ /Text/) {
      $var_name = $field_name . "_text_var";
      print F_GI ("  my \$$var_name = \$field_ref_hash{$field_name}->Contents();\n");
      print F_GI ("  chomp(\$$var_name);\n\n");
      push(@return_val_array, "\$$var_name");
    }
    elsif($field_type =~ /Listbox/) {
      $var_name = $field_name . "_list_box_var";
      print F_GI<<EOF 
  \$list_box = \$field_ref_hash{$field_name};
  \$list_index = \$list_box->curselection();
  if(!defined(\$list_index)) {
    \$list_index = 0;
  }
  my \$$var_name = \$list_box->get(\$list_index);

EOF
;
      push(@return_val_array, "\$$var_name");
    }
  } # for loop.
  $return_val_str = join(",\n    ", @return_val_array);
  for(my $id = 0; $id < @return_val_array; $id++) {
    my $tmp_val = $return_val_array[$id];
    $tmp_val =~ s/\$//g;
    print F_GI ("  print(\"$tmp_val = $return_val_array[$id].\\n\");\n");
  }
  print F_GI ("  return ($return_val_str);\n} # $sub_name.\n");
} # define_process_option_subroutine.


#------------------------------------------------------------------------------
sub define_clear_text_subroutine {
  my @tmp_array;
  my $field_type;
  my $field_name;
  my $sub_name;
  
  $sub_name = "clear_text_boxes";
  print F_GI ("#------------------------------------------------------------------------------\nsub $sub_name {\n");
  for(my $idx = 0; $idx < @name_array; $idx++) {
    @tmp_array = split(/#/, $name_array[$idx]);
    $field_type = $tmp_array[0];
    $field_name = $tmp_array[1];
    if($field_type =~ /Text/) {
      print F_GI ("  # Clearing value for '$field_name' $field_type.\n");
      print F_GI ("  \$field_ref_hash{$field_name}->selectAll();\n");
      print F_GI ("  \$field_ref_hash{$field_name}->deleteSelected();\n");
    }
  } # for loop.
  print F_GI ("} # $sub_name.\n");
} # define_process_option_subroutine.

#------------------------------------------------------------------------------
sub define_deselect_radio_button_subroutine {
  my @tmp_array;
  my $field_type;
  my $field_name;
  my $sub_name;
  
  $sub_name = "deselect_radio_buttons";
  # print("radio_button_name_array = @radio_button_name_array.\n");
  print F_GI ("#------------------------------------------------------------------------------\nsub $sub_name {\n");
  for(my $idx = 0; $idx < @radio_button_name_array; $idx++) {
    @tmp_array = split(/#/, $radio_button_name_array[$idx]);
    $field_type = $tmp_array[0];
    $field_name = $tmp_array[1];
    print F_GI ("  # Deselecting '$field_name' $field_type.\n");
    print F_GI ("  \$radio_button_ref_hash{$field_name}->deselect();\n");
  } # for loop.
  print F_GI ("} # $sub_name.\n");
} # define_process_option_subroutine.


#------------------------------------------------------------------------------
# These subroutines are for processing gui options which are used to generate
# gui perl script.
#------------------------------------------------------------------------------

sub generate_gui {
  my $row_num_1;

  $main = MainWindow->new;
  $main->configure(-title => 'Generate Perl Gui');
  my $pane = $main->Scrolled('Pane', -scrollbars=>'osoe',-sticky=>'ewns',-width=>1200, -height=>700);
  my $sframe = $pane->Frame();

  my $frame_1 = $sframe->Frame(-border=>2, -relief=>'ridge');
  my $frame_2 = $sframe->Frame(-border=>2, -relief=>'ridge');
  my $frame_3 = $sframe->Frame(-border=>2, -relief=>'ridge');
  my $frame_4 = $sframe->Frame();

  # logic for 'Select Type Of Field' Label.
  my $select_type_of_field_label = $frame_1->Label(-text => "Select Type Of Field");

  # logic for 'Text' Radiobutton.
  my $grp__Field_Select_Grp_1_var;
  my $text_radio_button = $frame_1->Radiobutton(-text => 'Text', -variable => \$grp__Field_Select_Grp_1_var, -value => 'Text');
  $text_radio_button->deselect();
  $field_ref_hash{grp__Field_Select_Grp_1} = \$grp__Field_Select_Grp_1_var;
  $radio_button_ref_hash{text} = $text_radio_button;

  # logic for 'Label' Radiobutton.
  my $label_radio_button = $frame_1->Radiobutton(-text => 'Label', -variable => \$grp__Field_Select_Grp_1_var, -value => 'Label');
  $label_radio_button->deselect();
  $field_ref_hash{label} = \$grp__Field_Select_Grp_1_var;
  $radio_button_ref_hash{label} = $label_radio_button;

  # logic for 'Listbox' Radiobutton.
  my $listbox_radio_button = $frame_1->Radiobutton(-text => 'Listbox', -variable => \$grp__Field_Select_Grp_1_var, -value => 'Listbox');
  $listbox_radio_button->deselect();
  $field_ref_hash{listbox} = \$grp__Field_Select_Grp_1_var;
  $radio_button_ref_hash{listbox} = $listbox_radio_button;

  # logic for 'Button' Radiobutton.
  my $button_radio_button = $frame_1->Radiobutton(-text => 'Button', -variable => \$grp__Field_Select_Grp_1_var, -value => 'Button');
  $button_radio_button->deselect();
  $field_ref_hash{button} = \$grp__Field_Select_Grp_1_var;
  $radio_button_ref_hash{button} = $button_radio_button;

  # logic for 'Checkbutton' Radiobutton.
  my $checkbutton_radio_button = $frame_1->Radiobutton(-text => 'Checkbutton', -variable => \$grp__Field_Select_Grp_1_var, -value => 'Checkbutton');
  $checkbutton_radio_button->deselect();
  $field_ref_hash{checkbutton} = \$grp__Field_Select_Grp_1_var;
  $radio_button_ref_hash{checkbutton} = $checkbutton_radio_button;

  # logic for 'Radiobutton' Radiobutton.
  my $radiobutton_radio_button = $frame_1->Radiobutton(-text => 'Radiobutton', -variable => \$grp__Field_Select_Grp_1_var, -value => 'Radiobutton');
  $radiobutton_radio_button->deselect();
  $field_ref_hash{radiobutton} = \$grp__Field_Select_Grp_1_var;
  $radio_button_ref_hash{radiobutton} = $radiobutton_radio_button;

  # logic for 'Enter Field Details' Label.
  my $enter_field_details_label = $frame_2->Label(-text => "Enter Field Details");

  # logic for 'Name' Label.
  my $name_label = $frame_2->Label(-text => "Name");

  # logic for 'Name Text' Text box.
  my $name_text_text_box = $frame_2->Text(-width => '29', -height => '1');
  $field_ref_hash{name_text} = $name_text_text_box;

  # logic for 'Frame Row Column Number Separated by Comma' Label.
  my $frame_row_column_number_separated_by_comma_label = $frame_2->Label(-text => "Frame Row Column Number Separated by Comma");

  # logic for 'Frame Row Column Number Text' Text box.
  my $frame_row_column_number_text_text_box = $frame_2->Text(-width => '9', -height => '1');
  $field_ref_hash{frame_row_column_number_text} = $frame_row_column_number_text_text_box;

  # logic for 'List Elements for List Box' Label.
  my $list_elements_for_list_box_label = $frame_2->Label(-text => "List Elements for List Box Separated by Comma");

  # logic for 'List Element Text' Text box.
  my $list_element_text_text_box = $frame_2->Text(-width => '29', -height => '1');
  $field_ref_hash{list_element_text} = $list_element_text_text_box;

  # logic for 'Group Name for Radio Button' Label.
  my $group_name_for_radio_button_label = $frame_2->Label(-text => "Group Name for Radio Button");

  # logic for 'Group Name for Radio Button Text' Text box.
  my $group_name_for_radio_button_text_text_box = $frame_2->Text(-width => '29', -height => '1');
  $field_ref_hash{group_name_for_radio_button_text} = $group_name_for_radio_button_text_text_box;

  # logic for 'Select Field To be Removed' Label.
  my $select_field_to_be_removed_label = $frame_3->Label(-text => "Select Field To be Removed");

  # logic for 'List Box To Remove Field' Listbox.
  my $list_box_to_remove_field_button = $frame_3->Scrolled("Listbox", -selectmode=>'single', -exportselection=>0, -width=>88, -height=>10);
  $list_box_to_remove_field_button -> insert('end', "");
  $list_box_to_remove_field_button -> activate(0);
  $field_ref_hash{list_box_to_remove_field} = $list_box_to_remove_field_button;

  # logic for 'Add Field' Button.
  my $add_field_button = $frame_2->Button(-text => ' Add Field ', -command => sub{add_field_action($main, $list_box_to_remove_field_button);}); 

  # logic for 'Delete Field' Button.
  my $delete_field_button = $frame_3->Button(-text => ' Delete Field ', -command => sub{delete_field_action($list_box_to_remove_field_button);}); 

  # logic for 'Save Data' Button.
  my $save_data_button = $frame_3->Button(-text => ' Save Data ', -command => sub{save_data_action($main);}); 

  # logic for 'Load Data' Button.
  my $load_data_button = $frame_3->Button(-text => ' Load Data ', -command => sub{load_data_action($main, $list_box_to_remove_field_button);}); 

  # logic for 'Generate Gui' Button.
  my $generate_gui_button = $frame_4->Button(-text => ' Generate Gui ', -border=>5, -relief=>'raised', -command => sub{generate_gui_action();}); 

  # logic for 'Quit' Button.
  my $quit_button = $frame_4->Button(-text => ' Quit ', -border=>5, -relief=>'raised', -command => sub{quit_action();}); 

  my $developer = $frame_4->Label(-text => "Developed By: Sandeep Vaniya, eInfochips Ltd.", -border=>2, -relief=>'ridge');

  # Adding grids for different frames for different groups.
  $pane -> grid(-row=>1,-column=>1,-columnspan=>1,-sticky=>'w');
  $sframe -> grid(-row=>1,-column=>1,-columnspan=>1,-sticky=>'w');
  my $row_num_1 = 1;
  $frame_1 -> grid(-row=>$row_num_1,-column=>1,-columnspan=>1,-sticky=>'w');
  my $row_num_2 = 3;
  $frame_2 -> grid(-row=>$row_num_2,-column=>1,-columnspan=>1,-sticky=>'w');
  my $row_num_3 = 8;
  $frame_3 -> grid(-row=>$row_num_3,-column=>1,-columnspan=>1,-sticky=>'w');
  my $row_num_4 = 9;
  $frame_4 -> grid(-row=>$row_num_4,-column=>1,-columnspan=>1,-sticky=>'w');

  # Adding grids for different objects.
  $select_type_of_field_label->grid(-row=>1,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $text_radio_button->grid(-row=>2,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $label_radio_button->grid(-row=>2,-column=>2,-padx=>10,-pady=>10,-sticky=>'w');
  $listbox_radio_button->grid(-row=>2,-column=>3,-padx=>10,-pady=>10,-sticky=>'w');
  $button_radio_button->grid(-row=>2,-column=>4,-padx=>10,-pady=>10,-sticky=>'w');
  $checkbutton_radio_button->grid(-row=>2,-column=>5,-padx=>10,-pady=>10,-sticky=>'w');
  $radiobutton_radio_button->grid(-row=>2,-column=>6,-padx=>10,-pady=>10,-sticky=>'w');
  $enter_field_details_label->grid(-row=>1,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $name_label->grid(-row=>2,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $name_text_text_box->grid(-row=>2,-column=>2,-padx=>10,-pady=>10,-sticky=>'w');
  $frame_row_column_number_separated_by_comma_label->grid(-row=>3,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $frame_row_column_number_text_text_box->grid(-row=>3,-column=>2,-padx=>10,-pady=>10,-sticky=>'w');
  $list_elements_for_list_box_label->grid(-row=>4,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $list_element_text_text_box->grid(-row=>4,-column=>2,-padx=>10,-pady=>10,-sticky=>'w');
  $group_name_for_radio_button_label->grid(-row=>5,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $group_name_for_radio_button_text_text_box->grid(-row=>5,-column=>2,-padx=>10,-pady=>10,-sticky=>'w');
  $add_field_button->grid(-row=>3,-column=>3,-padx=>10,-pady=>10,-sticky=>'w');
  $select_field_to_be_removed_label->grid(-row=>1,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $list_box_to_remove_field_button->grid(-row=>2,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $delete_field_button->grid(-row=>3,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $save_data_button->grid(-row=>3,-column=>1,-padx=>100,-pady=>10,-sticky=>'w');
  $load_data_button->grid(-row=>3,-column=>1,-padx=>180,-pady=>10,-sticky=>'w');
  $generate_gui_button->grid(-row=>1,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');
  $quit_button->grid(-row=>1,-column=>2,-padx=>10,-pady=>10,-sticky=>'w');
  $developer->grid(-row=>2,-column=>1,-padx=>10,-pady=>10,-sticky=>'w');

  MainLoop;
} # main

#------------------------------------------------------------------------------
sub get_gui_options {
  my $list_index;
  my $list_box;
  # Processing value for 'grp__Field_Select_Grp_1' Radiobutton.
  my $grp__Field_Select_Grp_1_radio_button_var = ${$field_ref_hash{grp__Field_Select_Grp_1}};

  # Processing value for 'name_text' Text.
  my $name_text_text_var = $field_ref_hash{name_text}->Contents();
  chomp($name_text_text_var);

  # Processing value for 'frame_row_column_number_text' Text.
  my $frame_row_column_number_text_text_var = $field_ref_hash{frame_row_column_number_text}->Contents();
  chomp($frame_row_column_number_text_text_var);

  # Processing value for 'list_element_text' Text.
  my $list_element_text_text_var = $field_ref_hash{list_element_text}->Contents();
  chomp($list_element_text_text_var);

  # Processing value for 'group_name_for_radio_button_text' Text.
  my $group_name_for_radio_button_text_text_var = $field_ref_hash{group_name_for_radio_button_text}->Contents();
  chomp($group_name_for_radio_button_text_text_var);

  # Processing value for 'list_box_to_remove_field' Listbox.
  $list_box = $field_ref_hash{list_box_to_remove_field};
  $list_index = $list_box->curselection();
  if(!defined($list_index)) {
    $list_index = 0;
  }
  my $list_box_to_remove_field_list_box_var = $list_box->get($list_index);

  if($DBG_ON) {
    print("grp__Field_Select_Grp_1_radio_button_var = $grp__Field_Select_Grp_1_radio_button_var.\n");
    print("name_text_text_var = $name_text_text_var.\n");
    print("frame_row_column_number_text_text_var = $frame_row_column_number_text_text_var.\n");
    print("list_element_text_text_var = $list_element_text_text_var.\n");
    print("group_name_for_radio_button_text_text_var = $group_name_for_radio_button_text_text_var.\n");
    print("list_box_to_remove_field_list_box_var = $list_box_to_remove_field_list_box_var.\n");
  }
  return ($grp__Field_Select_Grp_1_radio_button_var,
    $name_text_text_var,
    $frame_row_column_number_text_text_var,
    $list_element_text_text_var,
    $group_name_for_radio_button_text_text_var,
    $list_box_to_remove_field_list_box_var);
} # get_gui_options.

#------------------------------------------------------------------------------
sub generate_gui_action {
  $gui_file = "autogenerated_gui.pl";
  &generate_gui_file();
} # generate_gui_action

#------------------------------------------------------------------------------
sub quit_action {
  exit;
} # quit_action 

#------------------------------------------------------------------------------
sub clear_text_boxes {
  # Clearing value for 'name_text' Text.
  $field_ref_hash{name_text}->selectAll();
  $field_ref_hash{name_text}->deleteSelected();
  # Clearing value for 'frame_row_column_number_text' Text.
  $field_ref_hash{frame_row_column_number_text}->selectAll();
  $field_ref_hash{frame_row_column_number_text}->deleteSelected();
  # Clearing value for 'list_element_text' Text.
  $field_ref_hash{list_element_text}->selectAll();
  $field_ref_hash{list_element_text}->deleteSelected();
  # Clearing value for 'group_name_for_radio_button_text' Text.
  $field_ref_hash{group_name_for_radio_button_text}->selectAll();
  $field_ref_hash{group_name_for_radio_button_text}->deleteSelected();
} # clear_text_boxes.

#------------------------------------------------------------------------------
sub deselect_radio_buttons {
  # Deselecting 'text' Radiobutton.
  $radio_button_ref_hash{text}->deselect();
  # Deselecting 'label' Radiobutton.
  $radio_button_ref_hash{label}->deselect();
  # Deselecting 'listbox' Radiobutton.
  $radio_button_ref_hash{listbox}->deselect();
  # Deselecting 'button' Radiobutton.
  $radio_button_ref_hash{button}->deselect();
  # Deselecting 'checkbutton' Radiobutton.
  $radio_button_ref_hash{checkbutton}->deselect();
  # Deselecting 'radiobutton' Radiobutton.
  $radio_button_ref_hash{radiobutton}->deselect();
} # deselect_radio_buttons.

#------------------------------------------------------------------------------
sub add_field_action {
  my ($main, $list_box) = @_;
  my $add_delete_list_text;
  my (@gui_options) = &get_gui_options();
  my ($grp__Field_Select_Grp_1_radio_button_var,
    $name_text_text_var,
    $frame_row_column_number_text_text_var,
    $list_element_text_text_var,
    $group_name_for_radio_button_text_text_var,
    $list_box_to_remove_field_list_box_var) = @gui_options;

  my $stat = 0;

  $stat = &check_options($main, $grp__Field_Select_Grp_1_radio_button_var, $name_text_text_var, $frame_row_column_number_text_text_var, $list_element_text_text_var, $group_name_for_radio_button_text_text_var);

  if($stat == 0) {
    my $field_str = &get_field_text(@gui_options);

    push(@gui_options_array, $field_str);
    &update_list($list_box);
    &clear_text_boxes();
    &deselect_radio_buttons();
  }

} # add_field_action 

#------------------------------------------------------------------------------
sub get_field_text {
  my (@gui_options) = @_;
  my ($grp__Field_Select_Grp_1_radio_button_var,
    $name_text_text_var,
    $frame_row_column_number_text_text_var,
    $list_element_text_text_var,
    $group_name_for_radio_button_text_text_var,
    $list_box_to_remove_field_list_box_var) = @gui_options;

  my $field_str = $grp__Field_Select_Grp_1_radio_button_var . "#" . 
                  $name_text_text_var . "#" . "-LOC-$frame_row_column_number_text_text_var";
  if($grp__Field_Select_Grp_1_radio_button_var =~ /Listbox/) {
    $field_str .= "#$list_element_text_text_var";
  }
  if($grp__Field_Select_Grp_1_radio_button_var =~ /Radiobutton/) {
    $field_str .= "#$group_name_for_radio_button_text_text_var";
  }
  return $field_str;
} # get_field_text

#------------------------------------------------------------------------------
sub update_list {
  my ($list_box) = @_;

  my $list_size = $list_box -> size();
  for(my $i = 0; $i < $list_size; $i++) {
    $list_box -> delete(0);
  }
  $list_box -> insert('end', @gui_options_array);
  $list_box -> activate(0);
} # update_list

#------------------------------------------------------------------------------
sub delete_field_action {
  my ($list_box) = @_;

  my (@gui_options) = &get_gui_options();
  my $add_delete_list_text = &get_selected_element_from_list($list_box);
  &remove_list_entry($add_delete_list_text, \@gui_options_array);
  &update_list($list_box);

} # delete_field_action 

#------------------------------------------------------------------------------
sub remove_list_entry {
  my ($list_entry, $list_ref) = @_;
  my $id_to_delete;
  my $id;
  my @tmp_array;

  for($id = 0; $id < @{$list_ref}; $id++) {
    my $list_element = ${list_ref}->[$id];
    if($list_element =~ /^$list_entry$/) {
      $id_to_delete = $id;
    }
    else {
      push(@tmp_array, $list_element);
    }
  }

  @{$list_ref} = @tmp_array;
} # remove_list_entry

#------------------------------------------------------------------------------
sub get_selected_element_from_list {
  my ($list_box) = @_;

  my $list_sel_element;
  my $list_index;

  $list_index = $list_box->curselection();
  if($DBG_ON) {
    print("list_index = $list_index.\n");
  }
  if(!defined($list_index)) {
    $list_index = 0;
  }
  $list_sel_element = $list_box->get($list_index);
  if($DBG_ON) {
    print("list_sel_element = $list_sel_element.\n");
  }
  chomp($list_sel_element);
  return $list_sel_element;
} # get_selected_element_from_list

#------------------------------------------------------------------------------
sub check_options {
  my ($main, $field_type, $field_name, $frame_row_column, $list_values, $radio_button_group_value) = @_;
  my $ret_value = 0;
  my @tmp_array;
  my $non_digit_detected = 0;

  if($DBG_ON) {
    print("field_type = $field_type, frame_row_column = $frame_row_column, list_values = $list_values, radio_button_group_value = $radio_button_group_value.\n");
  }
  # Error if none of the radio buttons are selected.
  if((length($field_type) == 0)) {
    my $msg_box = $main->MsgBox(-title => "ERROR!!! Field not selected", -icon=>'error', -type=>'ok', -message=>"ERROR: None of the fields are selected\nPlease select one field...\n");
    my $button = $msg_box->Show;
    $ret_value = 1;
  }
  
  @tmp_array = split(/,/, $frame_row_column);
  # Error for non numeric character for row, column and frame.
  for(my $id = 0; $id < @tmp_array; $id++) {
    $tmp_array[$id] =~ s/ //g;
    if($tmp_array[$id] =~ /[^0-9]/) {
      $non_digit_detected = 1;
    }
  }
  if($non_digit_detected == 1) {
    my $msg_box = $main->MsgBox(-title => "ERROR!!! Numbers Only", -icon=>'error', -type=>'ok', -message=>"ERROR: Specify only numeric characters for Frame, Row and Column Number...\n");
    my $button = $msg_box->Show;
    $ret_value = 1;
  }

  my $frame  = $tmp_array[0];
  my $row    = $tmp_array[1];
  my $column = $tmp_array[2];
  my $frame_key = $frame . "_" . $row . "_" . $column;
  # Error for missing frame, row or column number.
  if((length($frame) == 0) || (length($row) == 0) || (length($column) == 0)) {
    my $msg_box = $main->MsgBox(-title => "ERROR!!! Frame, Row or Column is missing", -icon=>'error', -type=>'ok', -message=>"ERROR: Any of Frame, Row or Column number is missing. Frame=$frame, Row=$row, Column=$column...\nPlease specify comma separated values for frame, row and column...\n");
    my $button = $msg_box->Show;
    $ret_value = 1;
  }
  else {
    # Error for same frame, row and column number.
    if(exists($place_occupied_hash{$frame_key}) > 0) {
      my $msg_box = $main->MsgBox(-title => "ERROR!!! Element exists at given place", -icon=>'error', -type=>'ok', -message=>"ERROR: Element already exists at Frame=$frame, Row=$row, Column=$column...\n");
      my $button = $msg_box->Show;
      $ret_value = 1;
    }
  }

  # Error for field name missing.
  if(length($field_name) == 0) {
    my $msg_box = $main->MsgBox(-title => "ERROR!!! Name is missing", -icon=>'error', -type=>'ok', -message=>"ERROR: Please specify valid field name...\n");
    my $button = $msg_box->Show;
    $ret_value = 1;
  }

  # Error for not specifying group name for radio button.
  if($field_type =~ /Radiobutton/) {
    if((length($radio_button_group_value) == 0)) {
      my $msg_box = $main->MsgBox(-title => "ERROR!!! Radio Button Group Name missing", -icon=>'error', -type=>'ok', -message=>"ERROR: Please specify Group Name for Radio button.\nIf you don't want radio button to be part of any group, please specify 'NA' as group name.\n");
      my $button = $msg_box->Show;
      $ret_value = 1;
    }
  }

  if($field_type =~ /Listbox/) {
    if((length($list_values) == 0)) {
      my $msg_box = $main->MsgBox(-title => "ERROR!!! List Elements missing", -icon=>'error', -type=>'ok', -message=>"ERROR: Please specify comma separated list elements for Listbox.\n");
      my $button = $msg_box->Show;
      $ret_value = 1;
    }
  }

  if($DBG_ON) {
    print("check_options: ret_value = $ret_value.\n");
  }
  if($ret_value == 0) {
    $place_occupied_hash{$frame_key} = 1;
  }
  return $ret_value;
} # check_options

#------------------------------------------------------------------------------
sub save_data_action {
  my ($main) = @_;
  my $file_name = $main->getSaveFile();
  my $stat = 0;
  open(F_W, ">$file_name") or $stat = 1;
  if($stat == 1) {
    my $msg_box = $main->MsgBox(-title => "ERROR!!! Can't Open File", -icon=>'error', -type=>'ok', -message=>"ERROR: Can't open file '$file_name' for writing...\n");
    my $button = $msg_box->Show;
    return 1;
  }
  for(my $id = 0; $id < @gui_options_array; $id++) {
    print F_W ("$gui_options_array[$id]\n");
  }
  close(F_W);
} # save_data_action

#------------------------------------------------------------------------------
sub load_data_action {
  my ($main, $list_box) = @_;
  my $file_name = $main->getOpenFile();
  my $stat = 0;
  open(F_R, "<$file_name") or $stat = 1;
  if($stat == 1) {
    my $msg_box = $main->MsgBox(-title => "ERROR!!! Can't Open File", -icon=>'error', -type=>'ok', -message=>"ERROR: Can't open file '$file_name' for reading...\n");
    my $button = $msg_box->Show;
    return 1;
  }
  while(<F_R>) {
    chomp($_);
    push(@gui_options_array, $_);
  }
  close(F_R);
  &update_list($list_box);
} # load_data_action

#------------------------------------------------------------------------------





=head1 NAME

GuiBuilder - To create GUI wrapper for any script...

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

  use strict;
  
  use Tk;
  
  require Tk::MsgBox;
  
  require Tk::Pane;
  
  use GuiBuilder;
  
  my $gui_builder = GuiBuilder::new();
  
  $gui_builder->generate_gui();

=head1 DESCRIPTION

GuiBuilder generates the PERL GUI wrapper (as per options selected by user) compatible to Tk for any script/utility. 

Invoking generate_gui method opens one GUI window where user need to select/specify options needed to create GUI wrapper for any script/utility. 

It provides most commonly used GUI fields like Checkbutton, Button, Text Field, Label, Radiobutton, Listbox, etc. 

GUI invoked using generate_gui method call is self explanatory. However, some useful information is provided below to understand it better.


  For example, if user need to create GUI as depicted below within dotted box, then he need to select/specify following in GUI windows invoked by generate_gui method.

    => 3 Radio Button named Radio_Button_1, Radio_Button_2 and Radio_Button_3 at Frame/Row/Column = 1/1/1, 1/1/2 and 1/1/3 respectively.

    => 2 Check Boxes named Check_Box_1 and Check_Box_2 at Frame/Row/Column = 1/2/1 and 1/2/2 respectively.

    => 1 Label named 'Label Enter Text Here:' at Frame/Row/Column = 1/3/1

    => 1 Text Field (with any name) at Frame/Row/Column = 1/3/2

    => 2 Buttons named Button_OK and Button_Cancel at Frame/Row/Column 2/1/1 and 2/1/2 respectively.

                     |<------ Column 1 ------->|<---Column 2-------->|<-----Column 3----------->|
                     |--------------------------------------------------------------------------|
    Frame 1   Row 1  |   (.) Radio_Button_1      (.) Radio_Button_2     (.) Radio_Button_3      |
    Frame 1   Row 2  |   [+] Check_Box_1         [+] Check_Box_2                                |
    Frame 1   Row 3  |   Label Enter Text Here:  <Text_Field_1>                                 |
    Frame 2   Row 1  |   [Button_OK]             [Button_Cancel]                                |
                     |--------------------------------------------------------------------------|

    Above example explains the concept of Frame, Row and Column used here and How the fields are supposed to be entered. 
    
    User can have everything into single frame or can have as many frames as number of rows. 
    
    Mostly group of related fields should be having same frame number from GUI geometry point of view so that they can be positioned/controlled as a group.

    After selecting/specify all these details into GUI window, user can click on 'Generate Gui' Command Button which will generate one perl script named 'autogenerated_gui.pl'. 

    About 'autogenerated_gui.pl': 
      => This auto generated script is nothing but Perl GUI Wrapper for the GUI as explained above in the example. 
      => Running it, will open GUI as depicted above in dotted box. 
      => User need to edit it to add Actions based on options selected (e.g. Radio_Button_2 selected or Check_Box_2 selected).
      => It is having one subroutine named 'get_gui_options' which returns values of all the Options selcted by user in the form of list. 
         Using values provided by this subroutine user can invoke its command line version of the script/utility.

GuiBuilder also provides options for loading, saving and deleting of the options entered through GUI window. These options are useful 

=> To enter GUI configuration details in the form of text file instead of entering each details in GUI window (loading feature)

=> To delete wrong entries entered by mistake (deleting feature)

=> Saving entries which can be restored later (saving feature)

GuiBuilder will invoke GUI Error prompts on illegal/invalid user options.


=head1 SUBROUTINES/METHODS

=head2 new()

  Creates a new GuiBuilder object.

=head2 generate_gui()

  Invokes GUI window to select various GUI fields required to generate GUI wrapper for script/utility.


=head1 AUTHOR

Sandeep Vaniya, C<< <sandeep.vaniya at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-guibuilder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GuiBuilder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GuiBuilder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GuiBuilder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GuiBuilder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GuiBuilder>

=item * Search CPAN

L<http://search.cpan.org/dist/GuiBuilder/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Sandeep Vaniya.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of GuiBuilder
