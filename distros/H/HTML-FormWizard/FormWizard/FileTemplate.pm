package HTML::FormWizard::FileTemplate;

=head1 NAME

		HTML::FormWizard::FileTemplate - Template para o Modulo
			HTML::FormWizard

=head1 SYNOPSIS

		use HTML::FormWizard::FileTemplate();
		use HTML::FormWizard();

		my $template=HTML::FormWizard::FileTemplate->new(
			"formxpto", #Template
			"./", #base_dir
			"red", #descriptions background
			"white", #fields background
			"green" #error messages background
		);
		
		my $form = HTML::FormWizard->new(
			-title	=> 'Form Title',
			-fields => [ ],
			-template => $template
		); #see perldoc HTML::FormWizard for details.
		
		if (my $data=$form->run()) {
			#do things with data.!
		}

=head1 DESCRIPTION

	This is a template used to print forms with HTML header and footers.

=cut

sub new {
	my $self={};

	bless $self, shift;

	$self->{template}=shift;
	$self->{base_dir}= shift||"./";
	$self->{cor1}=shift||"blue";
	$self->{cor2}=shift||"white";
	$self->{cor3}=shift||"red";

	return $self;
}

sub header {
	my $self=shift;
	my $fname= $self->{base_dir}.$self->{template}."_header.html";
	open FH, $fname;
	$/="";
	my $header="";
	while (<FH>) {
		$header .= $_;
	}
	return $header;
}

sub form_header {
	my $self=shift;
	my $title=shift;
	my $url = shift;
	my $meth=shift;
	my $encod=shift;
	my $erro=shift;
	my $field=shift;
	my $html = qq( <H1>$title</H1><br>\n);
	$html .= qq(<font color=$self->{cor3} align=center>$erro</font><br>
		) if $erro;
 	$html .= qq(<font color=$self->{cor3} align=center>
		The value you typed in '$field' is invalid</font><br>) 
	if $field and not $erro;
	$html .= qq(<form action='$url');
	$html .= qq( METHOD=$meth) if $meth;
	$html .= qq( ENCTYPE='$encod') if $encod;
	$html .= qq(>
			<table border=0 cellpadding=5 cellspacing=0 align=center>
);
	return $html;
}

sub form_field {
	my $self=shift;
	my $name=shift;
	my $field=shift;
	my $needed=shift;
	my $errado=shift;
	$name="<b>$name</b>";
	$name="<font color=$self->{cor3}>$name</font>";
	return
qq(<tr><td bgcolor=$self->{cor1} width=100>$name</td>
	<td bgcolor=$self->{cor2}>$field</td>
</tr>
);
}

sub form_group_init {
	my $self=shift;
	my $group = shift;

	return
qq(<tr><td colspan=2 bgcolor=$self->{cor1}><strong>$group</strong></td></tr>
);
}

sub form_group_end {
	my $self=shift;
	return "<tr><td colspan=2 bgcolor=$self->{cor1} height=3></td></tr>";
}

sub form_actions {
	my $self=shift;
	my $html=
qq(<tr><td bgcolor=$self->{cor1} colspan=2 align=right>);
	$html .= qq($_) for @_;
	$html .=
q(</td></tr>
);
	return $html;
}

sub form_footer {
	return
q(		</table>
		</form>
);
}

sub footer {
	my $self=shift;
	my $fname= $self->{base_dir}.$self->{template}."_footer.html";
	open FH,$fname;
	$/ = "";
	my $footer="";
	while (<FH>) {
		$footer .= $_;
	}
	return $footer;
}

1;
