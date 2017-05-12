#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Xql::Shell;

use strict qw(vars refs subs);
use Meta::Shell::Shell qw();
use Meta::Class::MethodMaker qw();
use Meta::Lang::Html::Html qw();
use XML::XQL qw();
use XML::XQL::DOM qw();
use Meta::Utils::Output qw();
use Meta::Template::Sub qw();
use Meta::Utils::System qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Shell::Shell);

#sub BEGIN();
#sub new($);
#sub process($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_file",
		-java=>"_content",
		-java=>"_xml_content",
		-java=>"_dom",
	);
}

sub new($) {
	my($class)=@_;
	my($self)=Meta::Shell::Shell::new($class);

	my($attribs)=$self->Attribs();
	$attribs->{completion_entry_function}=$attribs->{list_completion_function};
	$attribs->{completion_word}=[qw(
		HISTORY_LOAD
		HISTORY_SAVE
		LOAD_HTML_FILE
		LOAD_HTML_URL
		LOAD_XML_FILE
		LOAD_XML_URL
		PROMPT
		EVAL
		SYSTEM
		EDIT
		QUIT
		HELP
	)];
	return($self);
}

sub process($$) {
	my($self,$line)=@_;

	my($handled)=0;
	if($line=~/^\s*HISTORY_LOAD\s*$/) {
		$handled=1;
		Meta::Utils::Output::verbose($self->get_verbose(),"loading history\n");
		if(-r $self->get_history_file()) {
			$self->ReadHistory($self->get_history_file());
		}
	}
	if($line=~/^\s*HISTORY_SAVE\s*$/) {
		$handled=1;
		Meta::Utils::Output::verbose($self->get_verbose(),"saving history\n");
		$self->WriteHistory($self->get_history_file());
	}
	if($line=~/^\s*LOAD_HTML_FILE\s+'(.*)'\s*$/) {
		$handled=1;
		my($file)=($line=~/^\s*LOAD_HTML_FILE\s+'(.*)'\s*$/);
		Meta::Utils::Output::verbose($self->get_verbose(),"loading file [".$file."]...\n");
		CORE::eval {
			my($content);
			Meta::Utils::File::File::load($file,\$content);
			$self->set_content($content);
			$self->set_dom(Meta::Lang::Html::Html::c2dom($self->get_content()));
		};
		if($@) {
			Meta::Utils::Output::verbose($self->get_verbose(),"errors encountered [".$@."]\n");
		} else {
			Meta::Utils::Output::verbose($self->get_verbose(),"file [".$file."] loaded\n");
		}
	}
	if($line=~/^\s*LOAD_HTML_URL\s+'(.*)'\s*$/) {
		$handled=1;
		my($file)=($line=~/^\s*LOAD_HTML_URL\s+'(.*)'\s*$/);
		Meta::Utils::Output::verbose($self->get_verbose(),"getting [".$file."]\n");
		CORE::eval {
		};
		if($@) {
			Meta::Utils::Output::verbose($self->get_verbose(),"errors encountered [".$@."]\n");
		} else {
			Meta::Utils::Output::verbose($self->get_verbose(),"url [".$file."] loaded\n");
		}
	}
	if($line=~/^\s*LOAD_XML_FILE\s+'(.*)'\s*$/) {
		$handled=1;
		Meta::Utils::Output::verbose($self->get_verbose(),"not implemented yet\n");
	}
	if($line=~/^\s*LOAD_XML_URL\s+'(.*)'\s*$/) {
		$handled=1;
		Meta::Utils::Output::verbose($self->get_verbose(),"not implemented yet\n");
	}
	if($line=~/^\s*PROMPT\s+'(.*)'\s*$/) {
		$handled=1;
		my($prompt)=($line=~/^\s*PROMPT\s+'(.*)'\s*$/);
		$prompt=Meta::Template::Sub::interpolate($prompt);
		Meta::Utils::Output::verbose($self->get_verbose(),"setting prompt to [".$prompt."]\n");
		$self->set_prompt($prompt);
	}
	if($line=~/^\s*EVAL\s+'(.*)'\s*$/) {
		$handled=1;
		if(!defined($self->get_dom())) {
			Meta::Utils::Output::verbose($self->get_verbose(),"No input file defined\n");
		} else {
			my($expr)=($line=~/^\s*EVAL\s+'(.*)'\s*$/);
			Meta::Utils::Output::verbose($self->get_verbose(),"evaluating [".$expr."]\n");
			my(@result);
			CORE::eval {
				my($query)=XML::XQL::Query->new(Expr=>$expr);
				@result=$query->solve($self->get_dom());
				#@result=$dom->xql($expr);
				my($size)=$#result+1;
				Meta::Utils::Output::verbose($self->get_verbose(),"result size is [".$size."]\n");
				for(my($i)=0;$i<$size;$i++) {
					my($curr)=$result[$i];
					Meta::Utils::Output::verbose($self->get_verbose(),"[".$i."] [".$curr->xql_toString()."]\n");
#					if($curr->can('xql_toString')) {
#						Meta::Utils::Output::verbose($self->get_verbose(),"[".$i."] [".$curr->xql_toString()."]\n");
#					} else {
#						Meta::Utils::Output::verbose($self->get_verbose(),"[".$i."] [".$curr->toString()."]\n");
#					}
				}
			};
			if($@) {
				Meta::Utils::Output::verbose($self->get_verbose(),"errors encountered [".$@."]\n");
			}
		}
	}
	if($line=~/^\s*SYSTEM\s+'(.*)'\s*$/) {
		$handled=1;
		my($cmd)=($line=~/^\s*SYSTEM\s+'(.*)'\s*$/);
		my($res)=Meta::Utils::System::system_shell_nodie($cmd);
		if(!$res) {
			Meta::Utils::Output::verbose($self->get_verbose(),"result was [".$res."]\n");
		}
	}
	if($line=~/^\s*EDIT\s*$/) {
		$handled=1;
		Meta::Utils::Output::verbose($self->get_verbose(),"not implemented yet\n");
		#$content=Meta::Tool::Editor::edit_content($content);
		#CORE::eval {
			#convert content to DOM
		#};
		#if($@) {
		#	Meta::Utils::Output::verbose($self->get_verbose(),"errors encountered [".$@."]\n");
		#} else {
		#	Meta::Utils::Output::verbose($self->get_verbose(),"file [".$file."] loaded\n");
		#}
	}
	if($line=~/^\s*QUIT\s*$/) {
		$handled=1;
		$self->set_quit(1);
	}
	if($line=~/^\s*HELP\s*$/) {
		$handled=1;
		Meta::Utils::Output::verbose($self->get_verbose(),"not implemented yet\n");
	}
	if(!$handled) {
		Meta::Utils::Output::verbose($self->get_verbose(),"unrecognized command [".$line."]\n");
	}
	$self->SUPER::process($line);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Xql::Shell - XQL experimentation shell class.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Shell.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Xql::Shell qw();
	my($object)=Meta::Lang::Xql::Shell->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class, which is derived from Meta::Shell::Shell implements a shell
which allows you to experiment with XQL.

=head1 FUNCTIONS

	BEGIN()
	new($)
	process($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to create accessors for the following fields:
0. file - the file which is currently processed.
1. content - the content of the file which is currently processed.
2. xml_content - the xml form of the content of the file which is currently processed.
3. dom - the XML::XQL::DOM form of the content.

=item B<new($)>

Constructor for this which constructs Meta::Shell::Shell and adds auto completion for
all commands that this shell provides.

=item B<process($$)>

This is the actual method which does the processing of commands entered by the user.

=item B<TEST($)>

This is a testing suite for the Meta::Lang::Xql::Shell module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

Currently this test does nothing.

=back

=head1 SUPER CLASSES

Meta::Shell::Shell(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Lang::Html::Html(3), Meta::Shell::Shell(3), Meta::Template::Sub(3), Meta::Utils::Output(3), Meta::Utils::System(3), XML::XQL(3), XML::XQL::DOM(3), strict(3)

=head1 TODO

Nothing.
