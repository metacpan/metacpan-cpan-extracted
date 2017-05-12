package LIMS::Web::Interface;

use 5.006;

our $VERSION = '1.4';

{ package lims_interface;

	require LIMS::Base;
	use CGI qw( :standard :html3 *table *Tr *td *div *p );
	
	our @ISA = qw( lims );

	sub DESTROY {
		my $self = shift;
		$self->SUPER::DESTROY;
	}
	sub start_cgi {
		my $self = shift;
		my $q = new CGI or die "Could not create CGI object";
		$self->{ _cgi } = $q;
	}
	sub get_cgi {
		my $self = shift;
		unless (defined $self->{ _cgi }){
			$self->start_cgi;
		}
		$self->{ _cgi };
	}
	sub has_cgi {
		my $self = shift;
		if (defined $self->{ _cgi }){
			return 1;
		} else {
			return;
		}
	}
	sub page_title {
		my $self = shift;
		$self->{ _page_title };
	}
	sub css {
		return;
	}
	sub verbatim {
		return;
	}
	sub print_header {
		my $self = shift;
		$self->print_cgi_header;
		$self->print_title;
	}
	sub print_title {
		my $self = shift;
		return if ($self->title_printed);
		my $q = $self->get_cgi;
		print $q->h1($self->page_title);	
		$self->{ _title } = 1;	
	}
	sub print_footer {
		my $self = shift;
		return if ($self->footer_printed);
		$self->print_header unless ($self->header_printed);
		print $self->footer;
		$self->{ _footer } = 1;
	}
	sub print_cgi_header {
		my $self = shift;
		return if ($self->header_printed);		
		my $q = $self->get_cgi;
		my $home_id = $self->home_id;
		my $base_url = $self->base_url;
		my $css = $self->css;
		my $verbatim = $self->verbatim;
		my $javascript = $self->javascript;
		my $bgcolor = $self->bgcolor;
		my $font_color = $self->font_color;
		
	    print 	$q->header( -type => "text/html", -expires => "+30m" ),
	    	 	$q->start_html( -title=>$home_id,
	    	 					-script=>$javascript,
	                     	 	-style=>{	-verbatim=>$verbatim,
				                     	 	-src=>$css },
				                     	 	-topmargin=>0,
				                     	 	-leftmargin=>0,
				                     	 	-marginheight=>0,
				                     	 	-marginwidth=>0,
				                     	 	-bgcolor=>$bgcolor,
				                     	 	-text=>$font_color
	                     		);
		$self->{ _cgi_header } = 1;
	}
	# the javascript value can be a hash ref containing one or more urls to javascript files
	# of the kind { -language => 'JAVASCRIPT', -src => $url }
	# or a HERE string of formatted javascript code to be included in the <HEAD> tag
	# either way, this has to be specified in your script, and the default is null
	sub javascript {
		my $self = shift;
		@_	?	$self->{ _javascript } = shift
			:	$self->{ _javascript };
	}
	sub right_graphic {
		my $self = shift;
		if (@_){
			$self->{ _right_graphic } = shift;
		} else {
			if (defined $self->{ _right_graphic }){
				$self->{ _right_graphic };
			} else {
				$self->default_right_graphic;
			}
		}
	}
	sub breadcrumb_printed {
		my $self = shift;
		$self->{ _breadcrumb };
	}
	sub sidebar_printed {
		my $self = shift;
		$self->{ _sidebar };
	}
	sub header_printed {
		my $self = shift;
		$self->{ _cgi_header };
	}
	sub title_printed {
		my $self = shift;
		$self->{ _title };
	}
	sub footer_printed {
		my $self = shift;
		$self->{ _footer };
	}
	#ÊVery dirty way of moving parameters from one script to the next.
	#ÊOught to be a better way to do it.
	sub param_forward {
		my $self = shift;
		return if ($self->forward_done);
		# Get all parameter names
		my $q = $self->get_cgi;
		my @aParam_Names = $q->param;
		for my $param(@aParam_Names){
			print $q->hidden($param,$q->param($param));
		}
		$self->{ _forward } = 1;
	}
	sub min_param_forward {
		my $self = shift;
		return if ($self->forward_done);
		my $q = $self->get_cgi;
		my @aParam = ('user_name','personnel_id','session_id');
		for my $param (@aParam){
			print $q->hidden($param,$q->param($param));
		}
		$self->{ _forward } = 1;
	}
	sub forward_done {
		my $self = shift;
		$self->{ _forward };
	}
	sub finish {
		my $self = shift;
		$self->param_forward;
		$self->print_footer;
	}
	sub format_url_base_query {
		my $self = shift;
		my $q = $self->get_cgi;
		return if ($q->param('logout'));
		if (my $user_name = $self->db_user_name){
			my $personnel_id = $self->personnel_id;
			my $session_id = $self->session_id;
			return "?user_name=$user_name&personnel_id=$personnel_id&session_id=$session_id";
		} else {
			return;
		}
	}
	sub format_full_url_query {
		my $self = shift;
		my $q = $self->get_cgi;
		my @aParam_Names = $q->param;
		my $query_string = '?';
		for my $param(@aParam_Names){
			$query_string .= "$param=".$q->param($param)."&";
		}
		$query_string =~ s/&$//;
		return $query_string;
	}
	sub url_add_params {
		my $self = shift;
		my $link = shift;
		my $aParams = shift;
		my $q = $self->get_cgi;
		for my $param (@$aParams){
			$link .= "&$param=".$q->param($param);
		}
		return $link;
	}
	sub redirect_add_params {
		my $self = shift;
		$self->url_add_params($self->format_redirect(shift),shift);	# shifting $script, $aParams
	}
	sub format_redirect {
		my $self = shift;
		my $script = shift;
		return "http://".$self->base_url."/cgi-bin/$script".$self->format_url_base_query;
	}
	sub format_redirect_full {
		my $self = shift;
		my $script = shift;
		return "http://".$self->base_url."/cgi-bin/$script".$self->format_full_url_query;
	}
	sub referring_page {
		my $self = shift;
		@_	?	$self->{ _referring_page } = shift
			:	$self->{ _referring_page };
	}
	sub is_back_sensitive {
		my $self = shift;
		$self->back_sensitive(1);
	}
	sub back_sensitive {
		my $self = shift;
		my $q = $self->get_cgi;
		@_	?	$q->param('back_sensitive',1)
			:	$q->param('back_sensitive');
	}
	sub not_back_sensitive {
		my $self = shift;
		my $q = $self->get_cgi;
		$q->delete('back_sensitive');
	}
	sub print_standard_errors {
		my $self = shift;
		return unless (my $aErrors = $self->standard_error);
		if ($self->has_cgi){
			my $q = $self->get_cgi;
			$self->print_header unless ($self->title_printed);
			print 	$q->start_p;
			for my $error (@$aErrors){
				print $q->em($error), br;
			}
			print 	$q->end_p;
		} else {
			print $self->get_error_string($aErrors);
		}
	}
	sub upload_file {
		use CGI::Upload;
		my $self = shift;
		my $var = shift;	# the param name
		my ($file_name,$filehandle);
		my $upload = CGI::Upload->new;
		if (@_){
			$file_name = shift;	# user defined file name without extension
			my $upload_name = $upload->file_name($var);
			$upload_name =~ s/.*\./\./;	# leave upload file extension
			$file_name .= $upload_name;	# append upload file extension
		} else {
			$file_name = $upload->file_name($var);
		}
		$filehandle = $upload->file_handle($var);
		return ($filehandle,$file_name);
	}
	sub bgcolor {
		'#FFFFFF'
	}
	sub font_color {
		'#000000'
	}		
}

1;

__END__


=head1 NAME

LIMS::Web::Interface - Perl object layer to work between a LIMS database and its web interface

=head1 DESCRIPTION

LIMS::Web::Interface is an object-oriented Perl module designed to be the object layer between a LIMS database and its web interface. It inherits from L<LIMS::Base|LIMS::Base> and provides automation for HTML/CGI services required by a LIMS web interface, enabling rapid development of Perl CGI scripts. See L<LIMS::Controller|LIMS::Controller> for information about setting up and using the LIMS modules. 

=head1 METHODS

=over

=item B<get_cgi>

Returns the embedded CGI object. It is recommended that you use the object-oriented style of calling CGI methods, although you I<probably> don't HAVE to.  

=item B<is_back_sensitive>

Prevents the user from using the back button on their browser by rejecting an old C<session_id>. 

=item B<page_title>

Returns the page title, set in the C<new()> and C<new_guest()> methods. 

=item B<param_forward>

Forwards all current parameters as hidden values. (Hidden in a '4-year old playing hide-and-seek' kind of way - in the HTML).

=item B<min_param_forward>

Forwards only C<'user_name'> and C<'session_id'> parameters as hidden values

=item B<format_url_base_query>

Formats C<'user_name'> and C<'session_id'> parameter values to append to a cgi script's url

=item B<format_redirect>

Pass a script name to format a url to the script with C<'user_name'> and C<'session_id'> parameter values

=item B<format_redirect_full>

Pass a script name to format a url to the script with all parameters

=item B<javascript>

Creates a C<<script>> tag in the HTML header for defining Javascript code. You can pass either an array ref containing one or more URLs to javascript files, or a C<HERE> string of formatted javascript code. 

=item B<finish>

Tidies up at the end of a script; prints a page footer (if there is one) and forwards parameters if not already performed.

=back

=head3 Handling Errors

One of the main reasons for writing the LIMS modules was because I wanted to be able to deal with all errors - Perl, CGI, DBI - in a more efficient manner, all at the same time. When using LIMS::Web::Interface in isolation, then the methods C<standard_error()> and C<any_error()> do the same thing, and the C<kill_pipeline()> method prints out errors upon killing the script. If you have a simple situation where you want to kill the script with an error you've caught in your script, you can combine the error with the C<kill_pipeline()> method;

	$database->kill_pipeline('got a problem');

Errors can be returned in text (rather than HTML) format by calling the method C<text_errors()>, or printed separately without calling C<kill_pipeline()> using the C<print_errors()> method. If you need to, you can clear errors using C<clear_all_errors()>. 

=head1 SEE ALSO

L<LIMS::Base|LIMS::Base>, L<LIMS::Controller|LIMS::Controller>, L<LIMS::Database::Util|LIMS::Database::Util>

=head1 AUTHORS

Christopher Jones and James Morris, Translational Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/trl>

c.jones@ucl.ac.uk, james.morris@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Christopher Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
