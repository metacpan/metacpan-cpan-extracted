
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id$
#
###################################################################################

package Embperl::Form::Control::tinymce ;

use strict ;
use base 'Embperl::Form::Control::textarea' ;

use Embperl::Inline ;

1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req) 

my $options = $self -> {tinymce} || {} ;
foreach my $k (keys %$options)
    {
    my $v = $options -> {$k} ;
    $v =~ s/\'/\"/g ;
    $options -> {$k} = $v if ($v =~ s/%%(.+?)%%/$fdat{$1}/g) ;
    }
$]

[- $ctrlid = $self -> SUPER::show_control ($req) ; -]
<script>
$('#[+ $ctrlid +]').tinymce({
	script_url : '/_appserv/js/tiny_mce/tiny_mce.js',
	theme : "advanced",
	//plugins : "table,insertdatetime,searchreplace,print,contextmenu,paste,fullscreen,noneditable",
	plugins : "insertdatetime,searchreplace,print,contextmenu,paste,fullscreen,noneditable,autoresize,inlinepopups",
   dialog_type : "modal",
	theme_advanced_buttons1 : "bold,italic,underline,strikethrough,styleselect,bullist,numlist,outdent,indent,undo,redo,link,unlink,image,sub,sup,charmap,insertdate,inserttime,search,replace,fullscreen",
	theme_advanced_buttons2 : '', //"print,cut,copy,pastetext,pasteword,selectall",
	theme_advanced_buttons3 : "",
	theme_advanced_toolbar_location : "top",
	theme_advanced_toolbar_align : "left",
	theme_advanced_path : false,
	//content_css : "example_full.css",
	plugin_insertdate_dateFormat : "%d.%m.%Y",
	plugin_insertdate_timeFormat : "%H:%M:%S",
	extended_valid_elements : "hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style]",
	theme_advanced_resizing : true,
	inline_styles : false,
    [$ foreach my $k (keys %$options) $] 
    [+ $k +] : '[+ $options -> {$k} +]',
    [$endforeach$]
	onchange_callback : function () 
		{ 
		$('#[+ $ctrlid +]').trigger ('input_changed') ; 
		}
    
   });
</script>
[#
<script language="javascript" type="text/javascript" src="/tiny_mce/tiny_mce.js"></script>
[$ if $self -> {theme} ne 'big' $]
<script language="javascript" type="text/javascript">
	tinyMCE.init({
		mode : "textareas",
		theme : "advanced",
		plugins : "table,insertdatetime,searchreplace,print,contextmenu,paste,fullscreen,noneditable",
                theme_advanced_buttons1 : "bold,italic,underline,strikethrough,bullist,numlist,outdent,indent,undo,redo,link,unlink,image,code,hr,sub,sup,forecolor,backcolor,charmap,table",
                theme_advanced_buttons2 : "",
                theme_advanced_buttons3 : "",
                theme_advanced_toolbar_location : "top",
		theme_advanced_toolbar_align : "left",
		theme_advanced_path_location : "bottom",
		content_css : "example_full.css",
                plugin_insertdate_dateFormat : "%d.%m.%Y",
                plugin_insertdate_timeFormat : "%H:%M:%S",
		extended_valid_elements : "hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style]",
		xtheme_advanced_resize_horizontal : false,
		theme_advanced_resizing : true,
                editor_selector : "cBase cControl cMceEditor",
                width: "100%"
	});
</script>
[$else$]
<script language="javascript" type="text/javascript">
	tinyMCE.init({
		mode : "textareas",
		theme : "advanced",
		plugins : "table,insertdatetime,searchreplace,print,contextmenu,paste,fullscreen,noneditable",
                theme_advanced_buttons1 : "bold,italic,underline,strikethrough,bullist,numlist,outdent,indent,undo,redo,link,unlink,image,code,hr,sub,sup,forecolor,backcolor,charmap,anchor,table,search,replace",
                theme_advanced_buttons2 : "removeformat,formatselect,fontselect,fontsizeselect,fullscreen,insertdate,inserttime",
                theme_advanced_buttons3 : "",
                theme_advanced_toolbar_location : "top",
		theme_advanced_toolbar_align : "left",
		theme_advanced_path_location : "bottom",
		content_css : "example_full.css",
                plugin_insertdate_dateFormat : "%d.%m.%Y",
                plugin_insertdate_timeFormat : "%H:%M:%S",
		extended_valid_elements : "hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style]",
		xtheme_advanced_resize_horizontal : false,
		theme_advanced_resizing : true,
                editor_selector : "cBase cControl cMceEditor",
                width: "100%"
	});
</script>
[$endif$]
#]

[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::tinymce - A tinymce input control inside an Embperl Form


=head1 SYNOPSIS

  {
  type => 'tinymce',
  text => 'blabla',
  name => 'foo',
  rows => 10,
  cols => 80,
  }

=head1 DESCRIPTION

Used to create an input control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'tinymce'

=head3 text

Will be used as label for the text input control

=head3 cols

Number of columns

=head3 rows

Number of rows

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


