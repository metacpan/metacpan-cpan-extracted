package HTML::FormWizard;

use vars qw($VERSION);

use strict;

$VERSION="0.1.09";

=head1 NAME

	HTML::FormWizard - Forms HTML made simple.

=head1 SYNOPSIS

	# this script does almost the same that CGI.pm
	# example. And, yes, I use CGI, that is,
	# writes a form and write the submited values
	
	use CGI();
	use HTML::FormWizard();


	my $form = HTML::FormWizard->new(
	  -title 	=> 'A simple Example',
	  -fields => [ 
	      { name 		=> 'name',
		    description	=> "What's your name?"},
	      { name			=> 'words',
			descritpion	=> "What's the combination?",
			type 		=> 'check',
			value		=> ['eenie','meenie',
				'minie',moe'],
			defaults	=> ['eenie','minie'] },
		  { name		=> 'color',
		    description	=> "What's your favorite color?",
		    type		=> 'list',
		    value		=> ['red','green',
				'blue','chartreuse']}
		]
	);
	
	# Well, That almost it... But now, that do other things...
	
	# Append field another list field, this one with
	# descriptions, for example... that you must select, 
	# initially saying "--Select Please--".
	
	$form->add(
		{ name 		=> 'country',
		  description 	=> 'Where did you born?',
		  type			=> 'list',
		  value => 
		  		{ pt => 'Portugal',
		   		  us => 'United States',
				  uk => 'United Kingdom',
				  fr => 'France',
				 '--' => 'Other',
				 ''	=> '--Select Please--'},
		 default		=> '',
		 needed 		=> 1 }
	);

	# And just one more... A password field, that must 
	# have 3 to 8 characters length, and you want to
	# validate with a function you wrote...
	
	$form->add( 
		{ name 		=> 'password',
		  type 		=> 'password',
		  minlen	=> 3,
		  maxlen	=> 8,
		  validate 	=> sub {
		  	my $pass = shift;
			return 0 if (($pass =~ /\d/) 
					and ($pass =~ /[a-zA-Z]/)
					and ($pass =~ /\W/));
			return "The field password must have at least a number,".
					" a letter and a symbol";
		  },
		  needed    => 1
		}
	);
			
	# And now... let's get the results!!!
	
	if (my $data=$form->run) {
		print 
		qq(
			Your name id $$data{name}<br>
			The Keywords are: ), 
				join(", ", @{$$data{words}}),qq(<br>
			Your Favorite Color is $$data{color}<br>
			Your birth country is $$data{country}<br>
			And you password is $$data{password}<br>
		)
	}

=head1 DESCRIPTION

There are to much libs that write forms, and only a few that
process both things, that is, write HTML forms, and retrieve
the data send by the user.

Or... in a more correct way... That handles everything 
between the first request and the correct data introduction.
Why should every program we devel ask some module to create
a form, and then ask some other to verify that the submit is 
correct? Or why should it verify the data?

HTML::FormWizard was wrote for that.

It uses CGI to retrieve data from the requests,
and the HTML forms are produced using an object template
that if not provided, will be $self (a self reference).

=head1 METHODS

The following methods are available (for properties list, see above):

=head2 $form = HTML::FormWizard->new([$property => $value]+);

Constructor for the FormWizard. Returns a reference for a
HTML::FormWizard object.

=cut

my %validators=(
	email => sub {
				my $str=shift;
				if ($str=~/^[a-zA-Z][\w\.\_\-]*\@[\w\.\-]+\.[a-zA-Z]{2,4}$/) {
					return 0;
				} else {
					return "Invalid Email";
				}
			},
	phone => sub {
				my $str=shift;
				if ($str=~
					/^(\+\d{1,3})? ?([\(-\s])?\d{1,3}?([\s-\)])[\d\s\-]+$/) {
					return 0;
				} else {
					return "This is not a valid phone number";
				}
			},
	ccard => sub {
				my $str=shift;
				if ($str =~ /^\d{4}[\- ]?\d{4}[\- ]?\d{4}[\- ]?\d{4}$|^\d{4}[\- ]?\d{6}[\- ]?\d{5}$/) {
					return 0;
				} else {
					return "The credit card number you type is not valid";
				}
			},
	pt_cp => sub {
				my $str=shift;
				if ($str=~/^\d{4}(-\d{3})$/ ) {
					return 0;
				} else {
					return "The Postal Code you typed isn't a valid Portuguese Postal Code.";
				}
			},
	us_cp => sub {
				my $str=shift;
				if ($str=~/^\d{5}(-\d{4})?$/) {
					return 0
				} else {
					return "The Postal Code you typed is not a US postal code.";
				}
			},
	ipv4 => sub {
				my $zbr=shift;
				my @secs=split /./, $zbr;
				if (scalar @secs!=4 or $secs[0]<1 or $secs[0]>255
					or $secs[1]<0 or $secs[1]>255
					or $secs[2]<0 or $secs[2]>255
					or $secs[3]<1 or $secs[3]>255) {
						return "This is not a value IPv4 value.";
				} else {
					return 0;
				}
			}
);

my $error_field;
my $error_msg;

sub new {
	my $self={};
	bless $self, shift;
	if (scalar @_) {
		if (((scalar @_ + 1) % 2) and ($_[0] =~ /^\-/)) {
			my ($key,$val);
			while (@_) {
				$key = shift;
				if ($key =~ /^\-(\w+)/) {
					my $value = shift;
					$self->{lc($1)} = $value;
				} else {
					die "Can't use init option parameters and init ".
						"standard parameters together.";
				}
			}
		} else {
			my ($url, $method, $template, $title, $cgi, $fields) = @_;
			$self->{url} = $url if $url;
			$self->{method} = $method if $method;
			$self->{template} = $template if $template;
			$self->{title} = $title if $title;
			$self->{cgi} = $cgi if $cgi;
			$self->{fields} = $fields if $fields;
		}
	}
	
	$self->{url}="" unless $self->{url};
	$self->{method}="POST" unless $self->{method};
	$self->{template}=$self unless $self->{template};
	$self->{title}="" unless $self->{title};
	$self->{cgi}=undef unless $self->{cgi};
	$self->{fields}=[()] unless $self->{fields};
	$self->{actions}=[({ undef => 'Send' })] unless $self->{actions};
	$self->{encoding}="multipart/form-data" unless $self->{encoding};


	return $self;
}

=head2 $form->set([$property => $value]+);

This method allow you to set the properties that you didn't set initially
with new(). This methos only allow you to set a property for each call.

With new() you can set as much properties as you want, but set was
thought to modify values predefined or values that you can't know when
you init the object.

=cut

sub set {
	my $self = shift;
	my $key = shift;
	my $value=shift;
	return 0 unless $key =~/^\-(\w+)/;
	
	$self->{lc($1)}=$value;
}

=head2 $form->add([$field]+);

This method allows you to add fields to the fields list at any time.

For field properties see below.

=cut

sub add {
	my $self = shift;
	push @{$self->{fields}}, @_;
}

=head2 HTML::FormWizard::validate($fieldsref,$dataref);
	
This function allows validation of a datahash againt a fields list.
This allows you to create an hash of data received by email or
already on a database and verify that it is valid for a fields list.

This function is used internally to verify that data. It's called by
run() method.

=cut

sub validate {
	my $fields = shift;
	my $data = shift;
	
	for my $field (@{$fields}) {
		$error_msg = $$field{name} if $$field{name};
		$error_msg = $$field{description} if $$field{description};
		$error_field=$$field{name};
		$$field{type}='line' unless $$field{type};
		if ($$field{type} eq 'group') {
			if ($$field{name}) {
				return 0 unless validate($$field{parts}, 
								$$data{lc($$field{name})});
			} else {
				return 0 unless validate($$field{parts}, $data);
			}
		} elsif (($$field{type} eq 'radio') or ($$field{type} eq 'list')){
			if ($$field{name}) {
				return 0 if ref $$data{lc($$field{name})};
				my $ok=0;
				if (my $rtype=ref($$field{value})) {
					my @values;
					if($rtype eq "ARRAY") {
						@values = @{$$field{value}};
					} else {
						@values = keys %{$$field{value}};
					}
					for (@values) {
						$ok = 1 if $_ eq $$data{lc($$field{name})};
						last if $ok;
					}	
				} else {
					$ok = $$data{lc($$field{name})} eq $$field{value};
				}
				return 0 if ($$data{lc($$field{name})} and not $ok);
				return 0 if ($$field{needed} and not $ok);
			}
		} elsif (($$field{type} eq 'checkbox') or ($$field{type} eq 'check')
				or ($$field{type} eq 'mlist')) {
			if ($$field{name}) {
				my $ok=1;
				if (ref $$data{lc($$field{name})}) {
					if (my $rtype=ref $$field{value}) {
						my @vals;
						if ($rtype eq "ARRAY") {
							@vals = @{$$field{value}};
						} else {
							@vals = keys %{$$field{value}};
						}
						my $vok;
						for my $value (@{$$data{lc($$field{name})}}) {
							$vok = 0;
							for (@vals) {
								$vok = 1 if $value eq $_;
								last if $vok;
							}
							$ok = 0 unless $vok;
							last unless $ok;
						}
					} else {
						$ok = 0;
					}
				} else {
					$ok=0;
					if (my $rtype=ref($$field{value})) {
						my @values;
						if ($rtype eq "ARRAY") {
							@values = @{$$field{value}};
						} else {
							@values = keys %{$$field{value}};
						}
						for (@values) {
							$ok = 1 if $$data{lc($$field{name})} eq $_;
							last if $ok;
						}
					} else {
						$ok = 1 if ($$data{lc($$field{name})}
									eq $$field{value});
					}
				}
				return 0 unless $ok;
			}
		} elsif ($$field{type} eq 'file') {
			return 0 unless $$data{lc($$field{name})} or !$$field{needed};
		} else {
			return 0 unless $$data{lc($$field{name})} or !$$field{needed};
			return 0 if (($$field{minlen}
					and length($$data{lc($$field{name})})<$$field{minlen})
				or ($$field{maxlen} 
					and length($$data{lc($$field{name})})>$$field{maxlen}));
		}
		if (defined($$field{datatype})
			and defined($validators{$$field{datatype}})
			and $$data{lc($$field{name})}) {
			my $zbr=$validators{$$field{datatype}}->($$data{lc($$field{name})});
			if ($zbr) {
				$error_msg = $zbr;
				return 0;
			}
		}
		if (defined($$field{validate})) {
			my $zbr=$$field{validate}->($$data{lc($$field{name})});
			if ($zbr) {
				$error_msg = $zbr;
				return 0;
			}
		}
	}

	$error_field="";
	return 1;
}

=head2 my $dataref = $form->getdata([$field]+);

Loads the data from the request and returns a reference to a datahash.

This method receives a list of fields, so it can be called recursively
to handle group items.

It returns a HASH with pair:

	{ fieldname => fieldvalue }

=head2 fieldvalue is an ARRAYREF

This happens when fieldvalue is more than a value.
The values for mlist and checkboxes are frequently of this time.

=head2 fieldvalue is an HASHREF

This happens to every named group. One of the group type is group.

In true, group is not an field, but a group of field. If a group have name
getdata will create an fieldpair with the key equal to the group name
property and the value equal to an HASHREF to an hash of VALUES, with the
same structure.

=cut

sub getdata {
	my $self = shift;

	my $data = {};
	
	for my $field (@_) {
		$$field{type}='line' unless $$field{type};
		if ($$field{type} eq 'group') {
			my $values = $self->getdata(@{$$field{parts}});
			if ($$field{name}) {
				$$data{lc($$field{name})} = $values;
			} else {
				for (keys %{$values}) {
					$$data{$_} = $$values{$_};
				}
			}
		} else {
			if ($$field{name}) {
				my $vals=[];
				@{$vals} = $self->{cgi}->param($$field{name});
				if (scalar @{$vals} <= 1) {
					$$data{lc($$field{name})}=$$vals[0]||"";
					chomp($$data{lc($$field{name})});
				} else {
					$$data{lc($$field{name})}=$vals;
				}
				$vals=undef;
			}
		}
	}
	
	return $data;
}

sub _set_fields {
	my $fields=shift;
	my $data = shift;
	for my $field (@{$fields}) {
		if ($$field{type} eq 'group') {
			if ($$field{name}) {
				_set_fields($$field{parts}, $$data{$$field{name}});
			} else {
				_set_fields($$field{parts}, $data);
			}
		} elsif (($$field{type} eq 'radio') or ($$field{type} eq 'list')) {
			$$field{default} = $$data{lc($$field{name})};
		} elsif (($$field{type} eq 'check') or ($$field{type} eq 'checkbox')
				or ($$field{type} eq 'mlist')) {
			$$field{defaults} = $$data{lc($$field{name})};
		} else {
			$$field{value}=$$data{lc($$field{name})};
		}
	}
}

sub _set_defaults {
	my $self = shift;
	$self->{erro} = $error_msg;
	$self->{fielderror}=$error_field;

	_set_fields($self->{fields}, $self->{data});
	
	return;
}

=head2 my $data = $form->run();

Verify when the request is a submission to the form or just a form
request, and in the first case it calls getdata and validade to verify
the data. If the data is valid return a reference to the datahash (see
getdata() for datahash format).

=cut

sub run {
	my $self = shift;
	
	$self->{fields} = [] unless $self->{fields};
	
	if (($self->{cgi}) and ($self->{cgi}->param())) {
		if (($self->{data}=$self->getdata(@{$self->{fields}}))
				and (validate($self->{fields},$self->{data}))) {
			return $self->{data};
		} else {
			$self->_set_defaults;
		}
	}
	$self->write;
	return undef;
}

=head2 $form->write;

Writes the HTML to the form. This function is called by $form->run. In true
it calls the functions from the template property to write the help.

See more about the template above.

=cut

sub write {

	my $self = shift;
	my $html="";

	$self->{template} = $self unless $self->{template};
	$self->{method} = "POST" unless $self->{method};
	$self->{encoding} = "multipart/form-data" unless $self->{encoding};
	$self->{erro} = "" unless $self->{erro};
	$self->{fielderror}="" unless $self->{fielderror};

	$html = $self->{template}->header;
	$html .= $self->{template}->form_header(
				$self->{title}, $self->{url}, $self->{method},
				$self->{encoding}, $self->{erro},$self->{fielderror});

	$self->{fields} = [] unless $self->{fields};

	$html .= $self->_write_fields(@{$self->{fields}});

	$html .= $self->_write_actions(@{$self->{actions}});
				
	$html .= $self->{template}->form_footer;
	$html .= $self->{template}->footer;
	
	$self->_print($html);
}

sub _write_actions {
	my $self = shift;

	@_ = ( { value => 'Send' } ) unless @_;

	my @html_buttons = ();

	for my $button (@_) {
		my $html = "";

		$$button{type}="" unless $$button{type};
		
		if ($$button{type} eq "image") {
			$html = _image_button($button);
		} elsif ($$button{type} eq "reset") {
			$html = _reset_button($button);
		} else {
			$html = _button($button);
		}
		
		unshift @html_buttons, $html;
	}
	
	my $html = $self->{template}->form_actions(@html_buttons);
	
	return $html;
}

sub _image_button {
	my $button = shift;

	return  "<!-- Invalid Image Button -->" unless $$button{src};

	my $html="<INPUT TYPE=IMAGE NAME=action";

	$html .= " ALT='$$button{alt}'" if $$button{alt};

	$html .= " SRC='$$button{src}'>";
	
	return $html;
}

sub _reset_button {
	my $button=shift;

	my $html = "<INPUT TYPE=RESET";

	$html .= " VALUE='$$button{value}'" if $$button{value};

	$html .= ">";

	return $html;
}

sub _button {
	my $button=shift;

	my $html = "<INPUT TYPE=SUBMIT NAME=action";

	$html .= " VALUE='$$button{value}'" if $$button{value};

	$html .= ">";

	return $html;
}

sub _write_fields {
	my $self = shift;
	my $html="";
	$self->{fielderror}="" unless $self->{fielderror};
	
	for my $field (@_) {

		$$field{description} = ucfirst($$field{name})
				unless $$field{description};
		my $erro=0;
		$erro=1 if $$field{name} eq $self->{fielderror};
		$$field{type}='line' unless $$field{type};
		if ($$field{type} eq "line") {
			$html .= $self->{template}->form_field($$field{description},
						_input_line($field),$$field{needed},$erro);
		} elsif (($$field{type} eq "passwd") or
					($$field{type} eq "password")) {
			$html .= $self->{template}->form_field($$field{description},
						_input_line($field,1),$$field{needed},$erro);
		} elsif (($$field{type} eq "check") or ($$field{type} eq "checkbox")) {
			$html .= $self->{template}->form_field($$field{description},
						_checkbox($field),$$field{needed},$erro);
		} elsif ($$field{type} eq "radio") {
			$html .= $self->{template}->form_field($$field{description},
						_radio($field),$$field{needed},$erro);
		} elsif ($$field{type} eq "list") {
			$html .= $self->{template}->form_field($$field{description},
						_list($field),$$field{needed},$erro);
		} elsif ($$field{type} eq "mlist") {
			$html .= $self->{template}->form_field($$field{description},
						_mlist($field),$$field{needed},$erro);
		} elsif ($$field{type} eq "text") {
			$html .= $self->{template}->form_field($$field{description},
						_textarea($field),$$field{needed},$erro);
		} elsif ($$field{type} eq "file") {
			$html .= $self->{template}->form_field($$field{description},
						_file($field),$$field{needed},$erro);
		} elsif ($$field{type} eq "group") {
			$html .= $self->_group($field);
		} elsif ($$field{type} eq "hidden") {
			$html .= $self->_hidden($field);
		} else {
			$html .= $self->{template}->form_field($$field{description},
                        _input_line($field),$$field{needed},$erro);
		}
	}
	return $html;
}

sub _group {
	my $self = shift;
	my $field = shift;

	$$field{title}="" unless $$field{title};

	my $html = $self->{template}->form_group_init($$field{title});

	$$field{parts} = [] unless $$field{parts};

	$html .= $self->_write_fields(@{$$field{parts}});

	$html .= $self->{template}->form_group_end;

	return $html;
}

sub _hidden {
	my $field = shift;

	return "<!--invalid hidden field-->" unless $$field{name};

	my $html="<INPUT TYPE=HIDDEN NAME=$$field{name}";

	$html .= " VALUE='$$field{value}'" if $$field{value};

	$html .= ">";

	return $html;
}

sub _input_line {
	my $field = shift;
	my $passwd = shift;

	return "<!--invalid field -->" unless $$field{name};
	
	my $html="";

	$html .= "<INPUT NAME=$$field{name}";
	
	if ($passwd) {
		$html .= " TYPE=PASSWORD";
	} else {
		$html .= " TYPE=TEXT";
	}
	if ($$field{value}) {
		$html .= " VALUE='$$field{value}'";
	}
	if ($$field{size}) {
		$html .= " SIZE=$$field{size}";
	}
	$$field{maxlen}=$$field{maxlength} if $$field{maxlength};
	if ($$field{maxlen}) {
		$html .=" MAXLENGTH=$$field{maxlen}";
	}
	$html .= ">";
	return $html;
}

sub _file {
	my $field = shift;

	return "<!-- Invalid File field -->" unless $$field{name};

	my $html;

	$html = "<INPUT TYPE=FILE NAME=$$field{name}";

	$html .= " ACCEPT='$$field{mime}'" if $$field{mime};

	$html .= " SIZE=$$field{size}" if $$field{size};

	$html .= ">";

	return $html;
}

sub _textarea {
	my $field = shift;

	return "<!-- invalid textarea -->" unless $$field{name};

	my $html;

	$html = "<TEXTAREA NAME=$$field{name}";

	$html .= " COLS=$$field{cols}" if $$field{cols};

	$$field{rows} = $$field{lines} if $$field{lines};
	$html .= " ROWS=$$field{rows}" if $$field{rows};
	
	$html .= ">";

	$html .= $$field{value} if $$field{value};

	$html .= "</TEXTAREA>";

	return $html;
}

sub _checkbox {
	my $field = shift;
	
	return "<!--invalid checkbox group -->" unless $$field{name};
	
	my $html;

	if (!ref($$field{value})) {
		$html  = "<INPUT NAME=$$field{name} TYPE=CHECKBOX VALUE=$$field{value}";
		$html .= " CHECKED" if $$field{default};
		$html .= "> $$field{description}";
	} elsif (ref($$field{value}) eq "HASH") {
		$$field{cols} = 4 unless defined($$field{cols});
		$html .= "<table cellpadding=0 cellspacing=0 border=0 width=100%><tr>";
		my $col=0;
		for my $value (sort {$$field{value}->{$a} cmp $$field{value}->{$b}}
				keys %{$$field{value}}) {
			$html .= "<td><INPUT NAME=$$field{name} TYPE=CHECKBOX";
			$html .= " VALUE=$value";
			for (@{$$field{defaults}}) {
				$html .= " CHECKED" if $value eq $_;
			}
			$html .= ">";
			$html .= $$field{value}->{$value};
			$html .= "</td>";
			$col++;
			if ($col==$$field{cols}) {
            	$html .= "</tr>\n<tr>";
				$col = 0;
			}
		}
		
		$html .= "</tr></table>";
	} elsif (ref($$field{value}) eq "ARRAY") {
        $$field{cols} = 4 unless defined($$field{cols});
        $html .= "<table cellpadding=0 cellspacing=0 border=0 width=100%><tr>";
        my $col=0;
        for my $value (sort @{$$field{value}}) {
            $html .= "<td><INPUT NAME=$$field{name} TYPE=CHECKBOX";
            $html .= " VALUE=$value";
            for (@{$$field{defaults}}) {
                $html .= " CHECKED" if $value eq $_;
            }
            $html .= ">";
            $html .= ucfirst($value);
            $html .= "</td>";
            $col++;
			if ($col==$$field{cols}) {
            	$html .= "</tr>\n<tr>";
				$col = 0;
			}
        }

        $html .= "</tr></table>";
	} else {
		$html = "";
	}
	return $html;
}

sub _mlist {
	my $field = shift;

	return "<!-- Invalid multiple select field -->" unless $$field{name};

	my $html;
	
	if (ref($$field{value}) eq "HASH") {
		$html = "<SELECT NAME=$$field{name} MULTIPLE";
		$html .= " SIZE=$$field{size}" if $$field{size};
		$html .= ">";
		for my $value (keys %{$$field{value}}) {
			$html .= "<OPTION VALUE=$value";
			for (@{$$field{defaults}}) {
				$html .= " SELECTED" if $value eq $_;
			}
			$html .= ">";
			$html .= $$field{value}->{$value};
		}
		$html .= "</SELECT>";
	} elsif (ref($$field{value}) eq "ARRAY") {
		$html = "<SELECT NAME=$$field{name} MULTIPLE";
		$html .= " SIZE=$$field{size}" if $$field{size};
		$html .= ">";
		for my $value (@{$$field{value}}) {
			$html .= "<OPTION VALUE=$value";
			for (@{$$field{defaults}}) {
				$html .= " SELECTED" if $value eq $_;
			}
			$html .= ">";
			$html .= ucfirst($value);
		}
		$html .= "</SELECT>";
	} else {
		$html = "";
	}
	
}

sub _list {
	my $field = shift;

	return "<!--Invalid select field -->" unless $$field{name};

	my $html;

	if (ref($$field{value}) eq "HASH") {
		$html = "<SELECT NAME=$$field{name}>";
		for my $value (keys %{$$field{value}}) {
			$html .= "<OPTION VALUE=$value";
			$html .= " SELECTED" if $$field{default} eq $value;
			$html .= ">";
			$html .= $$field{value}->{$value};
		}
		$html .= "</SELECT>";
	} elsif (ref($$field{value}) eq "ARRAY") {
		$html = "<SELECT NAME=$$field{name}>";
		for my $value (@{$$field{value}}) {
			$html .= "<OPTION VALUE=$value";
			$html .= " SELECTED" if $$field{default} eq $value;
			$html .= ">";
			$html .= ucfirst($value);
		}
		$html .= "</SELECT>";
	} else {
		$html = "";
	}
	return $html;
}

sub _radio {
	my $field = shift;
	
	return "<!--invalid radio group -->" unless $$field{name};
	
	my $html;

	if (!ref($$field{value})) {
		$html  = "<INPUT NAME=$$field{name} TYPE=RADIO VALUE=$$field{value}";
		$html .= " CHECKED" if $$field{default};
		$html .= "> $$field{description}";
	} elsif (ref($$field{value}) eq "HASH") {
		$$field{cols} = 4 unless defined($$field{cols});
		$html .= "<table cellpadding=0 cellspacing=0 border=0 width=100%><tr>";
		my $col=0;
		for my $value (sort {$$field{value}->{$a} cmp $$field{value}->{$b}}
				keys %{$$field{value}}) {
			$html .= "<td><INPUT NAME=$$field{name} TYPE=RADIO";
			$html .= " VALUE=$value";
			$html .= " CHECKED" if $value eq $$field{default};
			$html .= ">";
			$html .= $$field{value}->{$value};
			$html .= "</td>";
			$col++;
			if ($col==$$field{cols}) {
            	$html .= "</tr>\n<tr>";
				$col = 0;
			}
			$html .= "</tr>\n<tr>" if $col==$$field{cols};
		}
		
		$html .= "</tr></table>";
	} elsif (ref($$field{value}) eq "ARRAY") {
        $$field{cols} = 4 unless defined($$field{cols});
        $html .= "<table cellpadding=0 cellspacing=0 border=0 width=100%><tr>";
        my $col=0;
        for my $value (sort @{$$field{value}}) {
            $html .= "<td><INPUT NAME=$$field{name} TYPE=RADIO";
            $html .= " VALUE=$value";
            $html .= " CHECKED" if $value eq $$field{default};
            $html .= ">";
            $html .= ucfirst($value);
            $html .= "</td>";
            $col++;
			if ($col==$$field{cols}) {
            	$html .= "</tr>\n<tr>";
				$col = 0;
			}
        }

        $html .= "</tr></table>";
	} else {
		$html = "";
	}
	return $html;
}

=head1 Templates

The template must return a complete HTML page with only the folling calls:

	print 
	$template->header(),
	$template->form_header($title,$method,$url,$encoding,$erro),
	$template->form_footer(),
	$template->footer();

This must write a complete HTML page.

However, here are still missing some other methods.

The important to remember now is ... Templates don't print, return. Why?

That way it's up to the module when he really must print the HTML, and it
can be  used to print to files, without the file handler been carry for
every single function.
	
=head2 $template->header;

This method must create the HTML header for every page. This Header is
mustn't open nothing that the footer method will not close.

For example, if the header creates a table to preserve space for something
but the form, the table must be closed on the header itself or in the footer
method.

It can be closed anywhere else.
	
=cut

sub header {
	return q(
<html>
	<header>
		<title>Magick Form</title>
		<style type=text/css>
H1 {font-size:24pt; text-align:center; color:blue }
H2 {font-size:18pt; text-align:center; color:red }
.form_group {font-size:14pt; text-align:center; color:white; font-weight:bold }
.form_field {font-size:12pt; text-align:left; color:white }
		</style>
	</header>
	<body>
);
}

=head2 $template->form_header($title,$url[,$meth[,$enctype[,$erro]]]);

This method receive up to five parameters:

=head2 $title

This is the value that should be the heading line for the form.

=head2 $url

The URI where the submission should be done.

=head2 $meth

The HTTP Method to use.

=head2 $enctype

The Encoding that should be used to make the submission.

=head2 $erro

The field description for a invalid field value. Must be used to show 
a error message.

=cut

sub form_header {
	shift;
	my $title = shift;
	my $url=shift;
	my $meth=shift;
	my $encod = shift;
	my $erro=shift;
	my $field=shift;
	my $html = qq(		<H1>$title</H1><br>);
	$html .= qq(
<h2>$erro</h2><br>) if $erro;
	$html .= qq(
<h2>The value you introduced in the field '$field' is invalid.</h2>) 
		if $field and not $erro;
	$html .= qq(
		<form action='$url');
	$html .= " METHOD=$meth" if $meth;
	$html .= " ENCTYPE='$encod'" if $encod;
	$html .= qq(>
		<table border=1 cellpadding=5 cellspacing=0 align=center>
);
	return $html;
}

=head2 $template->form_field($fieldname,$fieldhtml);

This method from the template must write a form field. It receive to
parameters:

=head2 $fieldname

This is a description to the field. It's the label that the user must see
associated to the field.

=head2 $fieldhtml

This is the HTML to the field. It is the final HTML, no the field
properties to write the HTML. 

=cut

sub form_field {
	shift;
	my $name=shift;
	my $field = shift;
	my $needed=shift;
	my $errado=shift;
	$name="<b>$name</b>" if $needed;
	$name="<h2>$name</h2>" if $errado;
	return 
qq(<tr><td bgcolor=blue width=100 class=form_field>$name</td>
	<td>$field</td>
</tr>
);
}

=head2 $template->form_group_init($group);

This method receive only the description for the group. The must start the
group. The function $template->form_group_end() will be called to end
everything form_group_init() leave open.

=cut

sub form_group_init {
	shift;
	my $group = shift;

	return
qq(<tr><td colspan=2 bgcolor=blue class=form_group>$group</td></tr>
);
}

=head2 $template->form_group_end()

This function get no parameters, and must close any HTML tag that the
previous open form_group_init() leave open, or return the HTML to show that
the group ends here.

=cut

sub form_group_end {
	return "<tr><td colspan=2 bgcolor=blue height=3></td></tr>";
}

=head2 $template->form_actions()

This method receive a list of HTML strings, one for each action button or
image that the form must have.

=cut

sub form_actions {
	shift;
	my $html=
q(<tr><td bgcolor=blue colspan=2 align=right>);
	$html .= qq($_) for (@_);
	$html .= 
q(</td></tr>
);
	return $html;
}

=head2 $template->form_footer();

This must close any HTML tag that the call to $template->form_footer() leave.

It receive no parameters.

=cut

sub form_footer {
	return 
q(		</table>
		</form>
);
}

=head2 $template->footer

This function must complete the HTML document. 

=cut

sub footer {
	return 
q(	</body>
</html>
);
}


sub _print {
	my $self=shift;
	if ($self->{cgi}) {
		$self->{cgi}->print(@_);
	} else {
		print @_;
	}
}

1;

=head1 HTML::FormWizard Properties 

The list of properties listed new can be set on new(), or later with set().
See this methods documentation for more informations about them.

=head2 -title

This is the title for the form, the heading that is write by

	$template->form_init(); 

The value for this property must be a string. For exemple:

	$form->set(-title => 'Simple Test Form');

=head2 -url

This property defines the URL to where the post will be done.

For example:

	$form->set(-url => 'http://www.camelot.co.pt/forms/zbr.html');

=head2 -method

This property defines the HTTP method that will be used to submit the
data. The default to this value is POST.

=head2 -encoding

Encoding is the type of encoding that will be used for submitting the data
from the client to the server. Once this library was written to work with
itself, and CGI accepts "multipart/form-data" without problems,
this is the default value for this property, set it if you will be submitting
data to old CGI, or scripts that do not support that format.

=head2 -template

The property allows the definition of a diferent template for producing the
HTML to the form. The default value for this value is the $self reference.

The template is any object that have the functions listed in the previous
section.

=head2 -cgi

This property must be a reference to CGI or any other lib that can
param() and print in a compatible way with CGI.

If this property is not defined, the values will never be returned and the
form will always printed to STDOUT.

=head2 -fields

This is a reference for a list of form fields. See next section for details.

=head2 -actions

This is a reference to a list of buttons and image inputs.
See after Fields Details for details about actions.

=head1 Fields Details

Diferent field types have diferents properties. The diferent valid types are:

Each Field is an HASH, with the property name as key.
The property that defines the type of field is type.

For example:

	{ type => 'line',
	  name => 'zbr' }

Defines a simple inputbox field named 'zbr'.

=head2 type

This defines the type of field. Valid values for type are:

	line
	passwd or password
	check or checkbox
	radio
	list
	mlist
	text
	file
	hidden

	or

	group

Any other value will be ignored and line type will be created if possible.

=head2 name

Every field must have a property name, or will not be created. This field is
needed to retrieve the data also, so it can't be omitted.

There is only one exception to this: the groups don't need a name. 

BUT, if a group don't have name, the field values will be stay on the base
data HASH, and not in a sub HASH.

=head2 description

This property is optional. If not defined, the module will create it with
ucfirst(name).

Used for the field label.

=head2 validate

This property is optional. If used, it must be a function that receives a
string or an arrayref, depending on the type of field, and return false or
an error string to be printed in the form requesting the repost.

=head2 datatype

This property is still experimental, and actually only validates 6 diferent
kind of values:

	email => validate email address;
	phone => validate phone numbers;
	pt_cp => portuguese postal codes;
	us_cp => american postal codes;
	ipv4  => IP addresses;
	ccard => Credit cards.

Others will be implementated as soon as possible.

=head2 Type specific field properties

Some of the properties listed on this section applies to more than one field
type, but may differ on the final result.

=head2 line and passwd

This is normal inputbox (filled with * for passwd).

Its properties are:

	 value

Must be a scalar, and will be the default value for the field.

	 size

Must be a number. Will be assigned to the SIZE property of the INPUT in HTML.

	 maxlen

Maxlen is the max number of character the field will receive. It is assign to
the input box, but will also be verified be validate().

	 minlen

minlen isn't defined by HTML, so it will only be verified by validate
function.

=head2 radio

This can be a single radio button or a group of radio buttons.

	 value

Depending on what you want, the value property for radio fields must be
diferent things too.

If you want s single radio button (I know, it's usual, but...), The value
Property can be a scalar.

If you want a group of radio buttons, the value property can be either an
ARRAY or an HASH. In the first case the each element of the ARRAY will be
used for the value of the radio and for the label associated with it. In the
second case (when value is a HASH), the keys will be used as values and the
values in the HASH will be uses as labels.

	 default

This must be a scalar containning the value initially selected.

	 cols

This sets the number of radio buttons for line.

=head2 checkbox

This is a checkbox or a group of checkboxes. See radio for details about
properties.

	 defaults

This property is used when you have more than one checkbox. This is a list
of all the default checked boxes.


=head1 COPYRIGHT

Copyright 2002 Merlin, The Mage - camelot.co.pt

This library if open source, you can redistribute it and/or modify it under
the same terms as Perl itself.


=head1 AUTHOR

Merlin, The Mage <merlin@camelot.co.pt>

=cut
