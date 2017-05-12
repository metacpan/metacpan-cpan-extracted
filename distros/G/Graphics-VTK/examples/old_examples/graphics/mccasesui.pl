#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$MW->{'.case1'} = $MW->Radiobutton('-text',"Case 1",'-value','case1','-command',"case1 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case1c'} = $MW->Radiobutton('-text',"Case 1 Complement",'-value','case1c','-command',"case1 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case2'} = $MW->Radiobutton('-text',"Case 2",'-value','case2','-command',"case2 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case2c'} = $MW->Radiobutton('-text',"Case 2 Complement",'-value','case2c','-command',"case2 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case3'} = $MW->Radiobutton('-text',"Case 3",'-value','case3','-command',"case3 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case3c'} = $MW->Radiobutton('-text',"Case 3 Complement",'-value','case3c','-command',"case3 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case4'} = $MW->Radiobutton('-text',"Case 4",'-value','case4','-command',"case4 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case4c'} = $MW->Radiobutton('-text',"Case 4 Complement",'-value','case4c','-command',"case4 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case5'} = $MW->Radiobutton('-text',"Case 5",'-value','case5','-command',"case5 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case5c'} = $MW->Radiobutton('-text',"Case 5 Complement",'-value','case5c','-command',"case5 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case6'} = $MW->Radiobutton('-text',"Case 6",'-value','case6','-command',"case6 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case6c'} = $MW->Radiobutton('-text',"Case 6 Complement",'-value','case6c','-command',"case6 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case7'} = $MW->Radiobutton('-text',"Case 7",'-value','case7','-command',"case7 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case7c'} = $MW->Radiobutton('-text',"Case 7 Complement",'-value','case7c','-command',"case7 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case8'} = $MW->Radiobutton('-text',"Case 8",'-value','case8','-command',"case8 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case8c'} = $MW->Radiobutton('-text',"Case 8 Complement",'-value','case8c','-command',"case8 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case9'} = $MW->Radiobutton('-text',"Case 9",'-value','case9','-command',"case9 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case9c'} = $MW->Radiobutton('-text',"Case 9 Complement",'-value','case9c','-command',"case9 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case10'} = $MW->Radiobutton('-text',"Case 10",'-value','case10','-command',"case10 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case10c'} = $MW->Radiobutton('-text',"Case 10 Complement",'-value','case10c','-command',"case10 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case11'} = $MW->Radiobutton('-text',"Case 11",'-value','case11','-command',"case11 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case11c'} = $MW->Radiobutton('-text',"Case 11 Complement",'-value','case11c','-command',"case11 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case12'} = $MW->Radiobutton('-text',"Case 12",'-value','case12','-command',"case12 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case12c'} = $MW->Radiobutton('-text',"Case 12 Complement",'-value','case12c','-command',"case12 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case13'} = $MW->Radiobutton('-text',"Case 13",'-value','case13','-command',"case13 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case13c'} = $MW->Radiobutton('-text',"Case 13 Complement",'-value','case13c','-command',"case13 Scalars 0 1; Grid Modified; renWin Render;");
$MW->{'.case14'} = $MW->Radiobutton('-text',"Case 14",'-value','case14','-command',"case14 Scalars 1 0; Grid Modified; renWin Render;");
$MW->{'.case14c'} = $MW->Radiobutton('-text',"Case 14 Complement",'-value','case14c','-command',"case14 Scalars 0 1; Grid Modified; renWin Render;");
foreach $_ (())
 {
  $_->pack;
 }

Tk->MainLoop;
