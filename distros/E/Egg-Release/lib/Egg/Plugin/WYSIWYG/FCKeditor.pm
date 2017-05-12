package Egg::Plugin::WYSIWYG::FCKeditor;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FCKeditor.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION = '3.00';

sub _setup {
	my($e)= @_;
	$e->isa('Egg::Plugin::Tools')
	   || die q{ I want 'Egg::Plugin::Tools' loaded. };
	my $c= $e->config->{plugin_wysiwyg_fckeditor} ||= {};
	$c->{width}    ||= '100%';
	$c->{height}   ||= '450px';
	$c->{style}    ||= "width:$c->{width}; height:$c->{height}";
	$c->{instance} ||= 'FCKfield';
	$c->{tool_bar} ||= 'Default';
	$c->{base_uri} ||= '/FCKeditor';
	$c->{base_uri}=~s{/+$} [];
	$e->next::method;
}
sub fck {
	$_[0]->{fck_editor} ||= Egg::Plugin::WYSIWYG::FCKeditor::handler->new(@_);
}

package Egg::Plugin::WYSIWYG::FCKeditor::handler;
use strict;
use base qw/ Egg::Base /;

sub new {
	my($class, $e)= @_;
	$class->SUPER::new($e, $e->config->{plugin_wysiwyg_fckeditor});
}
sub is_compat {
	return $_[0]->{is_compat} if exists($_[0]->{is_compat});
	$_[0]->{is_compat}= do {
		my $a= $_[0]->e->request->agent;
		($a=~/MSIE/i and $a!~/mac/i and $a!~/Opera/i) ? do {
			return 0 if $a!~m{\d};
			substr($a, index($a, 'MSIE')+ 5, 3)>= 5.5 ? 1: 0;
		  }:
		($a=~/Gecko\//i) ? do {
			substr($a, index($a,'Gecko/')+ 6, 8)>= 20030210 ? 1: 0;
		  }: do { 0 };
	  };
}
sub html {
	my $self= shift;
	my $attr= $_[1] ? {@_}: (ref($_[0]) eq 'HASH' ? $_[0]: {});
	if ($attr->{width} or $attr->{height}) {
		$attr->{style}=
		  'width:'  . ($attr->{width}  || $self->params->{width})
		. ';height:'. ($attr->{height} || $self->params->{height});
	}
	my $p= { %{$self->params}, %$attr };
	my $query;
	if ($query= $self->e->request->param($p->{instance}) || "") {
		$query= $self->e->escape_html($query);
	}
	return $self->is_compat ? do {
		<<END_HTML
<textarea id="$p->{instance}"
  name="$p->{instance}" style="$p->{style}">$query</textarea>
END_HTML
	  }: do {
		my $uri= "$p->{base_uri}/editor/fckeditor.html"
		       . "?InstanceName=$p->{instance}&Toolbar=$p->{tool_bar}";
		<<END_HTML
<input type="hidden" id="$p->{instance}"
  name="$p->{instance}" value="$query" style="display:none" />
<input type="hidden" id="$p->{instance}___Config" value="" style="display:none" />
<iframe id="$p->{instance}___Frame" src="$uri"
  scrolling="no" border="0" frameborder="no" style="$p->{style}"></iframe>
END_HTML
	  };
}
sub js {
	my $self = shift;
	my $p= { %{$self->params},
	         %{$_[1] ? {@_}: (ref($_[0]) eq 'HASH' ? $_[0]: {}) } };
	   $p->{width} =~s{px$} [];
	   $p->{height}=~s{px$} [];
	<<END_JS;
<script type="text/javascript" src="$p->{base_uri}/fckeditor.js"></script>
<script type="text/javascript"><!-- //
window.onload = function() {
	var oFCKeditor= new FCKeditor('$p->{instance}');
	oFCKeditor.BasePath= "$p->{base_uri}/";
	oFCKeditor.Width = "$p->{width}";
	oFCKeditor.Height= "$p->{height}";
	oFCKeditor.ReplaceTextarea();
}
// --></script>
END_JS
}

1;

__END__

=head1 NAME

Egg::Plugin::WYSIWYG::FCKeditor - Plugin to use FCKeditor that is WYSIWYG. 

=head1 SYNOPSIS

  use Egg qw/ WYSIWYG::FCKeditor Tools /;
  
  my $fck= $e->fck;
  
  # Input form HTML source for FCKeditor is obtained.
  $e->stash->{fck_input_form}= $fck->html;
  
  # The JAVA script for FCKeditor is obtained.
  $e->stash->{fck_javascript}= $fck->js;
  
  # The received source is used with the template etc.

=head1 DESCRIPTION

It is a plugin to use FCKeditor.

FCKeditor is WYSIWYG HTML editor distributed under LGPL.

An original distribution site is here. L<http://www.fckeditor.net/>

It is necessary to be installed in the site that FCKeditor uses beforehand to
use this plugin.

In addition, please load L<Egg::Plugin::Tools> by the controller.

=head1 INSTALL

The directory of the name 'FCKeditor' is made for the document route of and the
project.

The document route of the project is a place set to dir->{htdocs} of the
configuration.

If it is default, it is "[PROJECT_ROOT]/htdocs".

When the package is downloaded on the distribution site of FCKeditor,
it defrosts in a suitable place, and all fckeditor.js and the editor directory
in that are arranged in this 'FCKeditor'.

The preparation for using FCKeditor by this is completed.

Any name of the directory made in the document route is not cared about.

Please set the name of the made directory to 'base_uri' of the configuration.

=head1 CONFIGURATION

The configuration is set with 'plugin_wysiwyg_fckeditor' key.

  plugin_wysiwyg_fckeditor => {
    ............
    ....
    },

=head2 width

Width of input form.

Default is '100%'

  width => '100%',

=head2 height

Width of length of input form.

Default is '450px'.

  height => '450px',

=head2 style

Style of input form.

Default is "width:[width]; height:[height]".

=head2 instance

Parameter name of input form.

Default is 'FCKfield'.

The content input to FCKeditor will be received by this name.

 instance => 'FCKfield',

=head2 tool_bar

Setting of toolbar of FCKeditor.

Default is 'Default'.

  tool_bar => 'Default',

=head2 base_uri

URI of the place where the component of FCKeditor was installed is set.

Default is '/FCKeditor'.

  base_uri => '/FCKeditor',

=head1 METHODS

=head2 fck

The Egg::Plugin::WYSIWYG::FCKeditor::handler object is returned.

  my $fck= $e->fck;

=head1 HANDLER METHODS

=head2 new

Constructor. When the fck method is called, it is called internally.

=head2 is_compat

The interchangeability of FCKeditor is judged.

'Html' method refers to this.
I do not think that there is a thing used from the application usually.

  if ($fck->is_compat) {
     .........
  } else {
     .........
  }

=head2 html ([OPTION_HASH])

The HTML source for the input form of FCKeditor is returned.

When OPTION_HASH is passed, the configuration is overwrited.

  my $inputo_form= $e->fck->html(
    width => '500px', height => '300px',
    );

=head2 js ([OPTION_HASH])

The JAVA script for FCKeditor is returned.

When OPTION_HASH is passed, the configuration is overwrited.

  my $javascript= $e->fck->js(
    width => '500px', height => '300px',
    );

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Base>,
L<Egg::Plugin::Tools>,
L<http://www.fckeditor.net/>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

