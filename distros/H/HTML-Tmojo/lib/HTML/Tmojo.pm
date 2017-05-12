###########################################################################
# Copyright 2003, 2004 Lab-01 LLC <http://lab-01.com/>
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Tmojo(tm) is a trademark of Lab-01 LLC.
###########################################################################

package HTML::Tmojo;

our $VERSION = '0.300';

=head1 NAME

HTML::Tmojo - Dynamic Text Generation Engine

=head1 SYNOPSIS

  my $tmojo = HTML::Tmojo->new(
    template_dir => '/location/of/templates',
    cache_dir    => '/place/to/save/compiled/templates',
  );
  
  my $result = $tmojo->call('my_template.tmojo', arg1 => 1, arg2 => 3);
  
  # HONESTLY, THIS SYNOPSIS DOESN'T COVER NEARLY ENOUGH.
  # GO READ TMOJO IN A NUTSHELL

=head1 ABSTRACT

Tmojo is used for generating dynamic text documents.
While it is particularly suited to generating HTML
and XML documents, it can be used effectively to
produce any text output, including dynamically
generated source code.

=head1 AUTHOR

Will Conant <will@willconant.com>

=cut

use strict;
use Data::Dumper;
use Symbol qw(delete_package);

use HTML::Tmojo::TemplateLoader;

our %memory_cache;

sub new {
	my ($class, %args) = @_;

	if (defined $args{template_dir}) {
		$args{template_loader} = HTML::Tmojo::TemplateLoader->new($args{template_dir}, $args{tmojo_lite});
		delete $args{template_dir};
	}
	elsif (not defined $args{template_loader}) {
		$args{template_loader} = HTML::Tmojo::TemplateLoader->new($ENV{TMOJO_TEMPLATE_DIR}, $args{tmojo_lite});
	}
	
	%args = (
		cache_dir    => $ENV{TMOJO_CACHE_DIR},
		context_path => '',
		
		%args,
	);
	
	$args{cache_dir} =~ s/\/$//;
		
	my $self = {
		%args
	};
	
	return bless $self, $class;
}

sub call {
	my ($self, $template_id, %args) = @_;
	return $self->call_with_container($template_id, undef, %args);
}

sub call_with_container {
	my ($self, $template_id, $container_override_id, %args) = @_;
	
	my $result = eval {
	
		my $current_package = $self->get_template_class($template_id);
		my $current_template = $current_package->new(\%args);
		
		# WE HAVE TO KEEP TRACK OF WHICH CONTAINERS HAVE BEEN USED,
		# SO THAT USERS CAN'T CREATE AN INFINITE CONTAINER LOOP
		my %used_containers = (
			$self->normalize_template_id($template_id) => 1,
		);
		
		for (;;) {
			no strict 'refs';
			
			my $contextual_tmojo = ${$current_package . '::Tmojo'};
			
			my $container_id;
			if (defined $container_override_id) {
				$container_id = $container_override_id;
				$container_override_id = undef;
			}
			else {
				$container_id = ${$current_package . '::TMOJO_CONTAINER'};
			}
			
			if (defined $container_id) {
				# NORMALIZE THE CONTAINER ID FOR GOOD MEASURE
				$container_id = $contextual_tmojo->normalize_template_id($container_id);
				
				# CHECK TO MAKE SURE THAT THE CONTAINER HASN'T ALREADY BEEN USED
				if (defined $used_containers{$container_id}) {
					die "circular container reference, $container_id already used (this will cause an infinite loop)";
				}
				
				# PUT IT IN THE USED LIST
				$used_containers{$container_id} = 1;
				
				# MOVE ON UP
				$current_package = $contextual_tmojo->get_template_class($container_id);
				$current_template = $current_package->new(\%args, $current_template);
			}
			else {
				return $current_template->main();
			}
		}
	
	};
	if ($@) {
		$self->report_error($@);
	}
	
	return $result;
}

sub prepare {
	my ($self, $template_id, %args) = @_;
	
	my $package = $self->get_template_class($template_id);
	my $template = $package->new(\%args);
	
	return $template;
}

sub template_exists {
	my ($self, $template_id) = @_;
	
	$template_id = $self->normalize_template_id($template_id);
	return $self->{template_loader}->template_exists($template_id);	
}

sub report_error {
	my ($self, $error) = @_;
		
	my $err = (split(/\n/, $error))[0];
	if ($err =~ /at ([^\s]+) line\s+(\d+)/) {
		my $file_name = $1;
		my $line_number = $2;
		
		my $template_id;
		
		open FH, "$file_name.lines";
		local $/ = "\n"; # THIS CAN GET EXTRA SCREWED UP IN MOD_PERL
		
		my $cur_line = 1;
		while (my $line = <FH>) {
			if ($line =~ /^###TMOJO_TEMPLATE_ID: (.+)$/) {
				$template_id = $1;
				chomp $template_id;
			}
			
			if ($cur_line == $line_number) {
				if ($line =~ /###TMOJO_LINE: (\d+)$/) {
					die "Error at $template_id line $1.\n$@";
				}
			}
			
			$cur_line += 1;
		}
		close FH;
	}
	
	die $error;
}

sub parse_template {
	my ($source) = @_;
	
	my @parsed;
	
	my $tag_open  = "<:";
	my $tag_close = ":>";
	my $tag_line  = ":";
	
	my $tag_open_r;
	my $tag_close_r;
	my $tag_line_r;
	
	my $make_regexes = sub {
		$tag_open_r  = $tag_open;
		$tag_close_r = $tag_close;
		$tag_line_r  = $tag_line;
		
		$tag_open_r  =~ s/([\[\]\{\}\(\)\$\@\^\\\|\?\*\+])/\\$1/g;
		$tag_close_r =~ s/([\[\]\{\}\(\)\$\@\^\\\|\?\*\+])/\\$1/g;
		$tag_line_r  =~ s/([\[\]\{\}\(\)\$\@\^\\\|\?\*\+])/\\$1/g;
	};
	
	my $count_newlines = sub {
		my $count = 0;
		my $pos   = 0;
		
		while ($pos > -1) {
			$pos = index($_[0], "\n", $pos);
			if ($pos > -1) {
				$pos += 1;
				$count += 1;
			}
		}
		
		return $count;
	};
	
	$make_regexes->();
	
	my $keywords = "GLOBAL|INIT|METHOD|PERL|MERGE|CAPTURE|FILTER|REGEX|NOP|TAG_STYLE";
	my %crush_defaults = (
		'GLOBAL'    => [0, 0],
		'/GLOBAL'   => [0, 2],
		
		'INIT'      => [0, 0],
		'/INIT'     => [0, 2],
		
		'METHOD'    => [0, 2],
		'/METHOD'   => [2, 2],
		
		'PERL'      => [1, 0],
		'/PERL'     => [0, 0],
		
		'MERGE'     => [0, 0],
		
		'CAPTURE'   => [1, 2],
		'/CAPTURE'  => [2, 0],
		
		'FILTER'    => [0, 0],
		'/FILTER'   => [0, 0],
		
		'REGEX'     => [0, 0],
		'/REGEX'    => [0, 0],
		
		'TAG_STYLE' => [1, 0],
		
		'NOP'       => [0, 0],
	);
	
	my $current_line = 1;

	while ($source ne '') {
	
		# SNAG THE NEXT TAG
		# -------------------
		
		my $found_tag = 0;
		my $tag_notation;
		my $pre_tag_text;

		if (scalar(@parsed) == 0) {
			if ($source =~ s/^([ \t]*)$tag_line_r//s) {
				$found_tag = 1;
				$tag_notation = 'line';
				$pre_tag_text = $1;
			}
		}
		
		unless ($found_tag == 1) {
			if ($source =~ s/^(.*?)($tag_open_r|(\n[ \t]*)$tag_line_r)//s) {
				$found_tag = 1;
				
				# DETERMINE IF THIS IS A LINE OR INLINE TAG
				if ($2 eq $tag_open) {
					$tag_notation = 'inline';
				}
				else {
					$tag_notation = 'line';
				}
				
				# DETERMINE THE PRE TAG TEXT
				$pre_tag_text = $1;
				if ($tag_notation eq 'line') {
					$pre_tag_text .= $3;
				}
			}
		}
		
		if ($found_tag == 1) {
				
			if ($pre_tag_text ne '') {
				# PUSH PLAIN TEXT ONTO THE PARSED RESULT
				push @parsed, { type => 'TEXT', text => $pre_tag_text, source => $pre_tag_text, crush_before => 0, crush_after => 0, start_line => $current_line };
				
				# COUNT THE NUMBER OF NEWLINES
				$current_line += $count_newlines->($pre_tag_text);
			}
			
			# GRAB THE REST OF THE TAG
			my $tag_source;
			my $tag_inside;
			
			if ($tag_notation eq 'inline') {
				$tag_source = $tag_line;
				
				if ($source =~ s/^(.*?)$tag_close_r//s) {
					$tag_inside = $1;
					$tag_source .= "$1$tag_close";
				}
				else {
					die "expected '$tag_close'";
				}
			}
			else {
				$tag_source = $tag_open;
				
				# GOBBLE UP THE REST OF THE LINE
				$source =~ s/^([^\n]*)//;
				$tag_inside = $1;
				$tag_source .= $1;
			}
			
			# NOTCH UP THE LINES
			$current_line += $count_newlines->($tag_source);
			
			# PARSE THE TAG INSIDES
			
			my %tag = (
				source       => $tag_source,
				start_line   => $current_line,
			);
			
			# LOOK FOR WHITESPACE CRUSHERS
			
			if ($tag_notation eq 'inline') {
				if ($tag_inside =~ s/^--//) {
					$tag{crush_before} = 2;
				}
				elsif ($tag_inside =~ s/^-//) {
					$tag{crush_before} = 1;
				}
				elsif ($tag_inside =~ s/^\+//) {
					$tag{crush_before} = 0;
				}
				
				if ($tag_inside =~ s/--$//) {
					$tag{crush_after} = 2;
				}
				elsif ($tag_inside =~ s/-$//) {
					$tag{crush_after} = 1;
				}
				elsif ($tag_inside =~ s/\+$//) {
					$tag{crush_after} = 0;
				}
			}
			
			# FIGURE OUT THE TAG TYPE
			
			if ($tag_inside =~ /^\s*$/) {
				$tag{type} = 'NOP';
			}
			elsif ($tag_inside =~ s/^\s*(\/?(?:$keywords))\s+//) {
				$tag{type} = $1;
			}
			elsif ($tag_notation eq 'inline') {
				# USE A LITTLE MAGIC TO SEE IF WE'VE GOT A STATEMENT OR AN EXPRESSION
				if ($tag_inside =~ /^\s*(if|unless|while|until|for|foreach)\s+/) {
					 # THIS LOOKS LIKE A PERL STATEMENT
					 $tag{type} = 'PERL';
				}
				elsif ($tag_inside =~ /^\s*\}?\s*(else|elsif|continue)\s+/) {
					# THIS LOOKS LIKE A PERL STATEMENT
					$tag{type} = 'PERL';
				}
				elsif ($tag_inside =~ /^\s*\}\s*$/) {
					# THIS LOOKS LIKE A PERL STATEMENT
					$tag{type} = 'PERL';
				}
				else {
					# MUST BE A PERL EXPRESSION
					$tag{type} = 'MERGE';
				}
			}
			else {
				$tag{type} = 'PERL';
			}
			
			# PUT WHAT'S LEFT IN THE TAG TEXT
			
			$tag_inside =~ s/(^\s+|\s+$)//g;
			$tag{text} = $tag_inside;
			
			# SET DEFAULT CRUSHING
			
			if (not defined $tag{crush_before}) {
				$tag{crush_before} = $crush_defaults{$tag{type}}[0];
			}
			
			if (not defined $tag{crush_after}) {
				$tag{crush_after} = $crush_defaults{$tag{type}}[1];
			}
			
			
			# HANDLE FIRST-PASS TAGS
			# ----------------------
			if ($tag{type} eq 'TAG_STYLE') {
				if ($tag{text} eq 'default') {
					($tag_open, $tag_close, $tag_line) = ('<:', ':>', ':');
				}
				else {
					($tag_open, $tag_close, $tag_line) = split /\s+/, $tag{text};
				}
				
				if ($tag_open eq '') {
					die "invalid open tag marker";
				}
				
				if ($tag_close eq '') {
					die "invalid close tag marker";
				}
				
				if ($tag_line eq '') {
					die "invalid line tag marker";
				}
				
				if ($tag_line eq $tag_open or $tag_line eq $tag_close) {
					die "line tag marker must not be the same as either the open tag marker or close tag marker";
				}
				
				$make_regexes->();
			}
			
			# PUSH THE TAG ONTO THE RESULT
			
			push @parsed, \%tag;
		}
		elsif ($source ne '') {
			push @parsed, { type => 'TEXT', text => $source, source => $source, crush_before => 0, crush_after => 0, start_line => $current_line };
			$source = '';
		}
	}
	
	# RUN THROUGH AGAIN AND CRUSH WHITESPACE
	for (my $i = 0; $i < scalar(@parsed); $i++) {
		if ($parsed[$i]{crush_before} == 1 and $i > 0 and $parsed[$i-1]{type} eq 'TEXT') {
			$parsed[$i-1]{text} =~ s/\n?[ \t]*$//;
		}
		elsif ($parsed[$i]{crush_before} == 2 and $i > 0 and $parsed[$i-1]{type} eq 'TEXT') {
			$parsed[$i-1]{text} =~ s/\s+$//;
		}
		
		if ($parsed[$i]{crush_after} == 1 and $i < (scalar(@parsed)-1) and $parsed[$i+1]{type} eq 'TEXT') {
			$parsed[$i+1]{text} =~ s/^[ \t]*\n?//;
		}
		elsif ($parsed[$i]{crush_after} == 2 and $i < (scalar(@parsed)-1) and $parsed[$i+1]{type} eq 'TEXT') {
			$parsed[$i+1]{text} =~ s/^\s+//;
		}
	}
	
	# AND WE'RE DONE
	return \@parsed;
}

sub compile_template {
	my ($source, $template_id, $package_name) = @_;
	
	# ADJUST FOR SOURCE LINES
	if (ref($source) eq 'ARRAY') {
		$source = join "", @$source;
	}
	
	# PARSE THE SOURCE INTO TAGS
	my $tags = parse_template($source);
	
	# INITIALIZE OUR PARSE VARIABLES
	my $global_section = '';
	my $init_section   = '';
	
	my %methods = (
		main => '',
	);
	
	my $cur_method = 'main';
	
	my @stack;
	my @stack_details;
	my @stack_lines;
	
	# DEFINE A USEFUL LITTLE FUNCTION
	my $format_perl = sub {
		my ($source, $start_line) = @_;
		
		my @lines = split /\n/, $source;
		
		my $result;
		my $cur_line = $start_line;
		foreach my $line (@lines) {
			$result .= "$line###TMOJO_LINE: $cur_line\n";
			$cur_line += 1;
		}
		
		return $result;
	};
	
	# PARSE ALL OF THE TAGS
	while (my $tag = shift @$tags) {
	
		# TEXT TAG
		# ---------------------------------
	
		if ($tag->{type} eq 'TEXT') {
			my $dumper = Data::Dumper->new([$tag->{text}]);
			$dumper->Useqq(1);
			$dumper->Indent(0);
			$dumper->Terse(1);
			my $literal = $dumper->Dump();
			
			$methods{$cur_method} .= "\t\$Result .= $literal;\n";
		}
		
		# GLOBAL TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'GLOBAL') {
			
			if ($cur_method ne 'main') {
				die "cannot declare METHOD here";
			}
			
			if ($global_section ne '') {
				die "attempting to redefine GLOBAL section";
			}
			
			my $source = '';
			my $start_line;
			
			while (my $tag = shift @$tags) {
				if (not defined $tag) {
					die "missing /GLOBAL tag";
				}
				
				if ($tag->{type} eq '/GLOBAL') {
					last;
				}
				elsif ($tag->{type} ne 'TEXT') {
					die "non-text tag in GLOBAL section in '$template_id' starting at line $tag->{start_line}";
				}
				else {
					if (not defined $start_line) {
						$start_line = $tag->{start_line};
					}
					$source .= $tag->{source};
				}
			}
			
			$global_section .= $format_perl->($source, $start_line);
		}
		
		# INIT TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'INIT') {
			
			if ($cur_method ne 'main') {
				die "cannot declare METHOD here";
			}
			
			if ($init_section ne '') {
				die "attempting to redefine INIT section";
			}
			
			my $source = '';
			my $start_line;
			
			while (my $tag = shift @$tags) {
				if (not defined $tag) {
					die "missing /INIT tag";
				}
				
				if ($tag->{type} eq '/INIT') {
					last;
				}
				elsif ($tag->{type} ne 'TEXT') {
					die "non-text tag in INIT section in '$template_id' starting at line $tag->{start_line}";
				}
				else {
					if (not defined $start_line) {
						$start_line = $tag->{start_line};
					}
					$source .= $tag->{source};
				}
			}
			
			$init_section .= $format_perl->($source, $start_line);
		}
		
		# PERL TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'PERL') {
			
			if ($tag->{text} ne '') {
				my @lines = split /\n/, $tag->{text};
			
				my $cur_line = $tag->{start_line};
				while ($_ = shift @lines) {
					$methods{$cur_method} .= "$_###TMOJO_LINE: $cur_line\n";				
					$cur_line += 1;
				}
			}
			else {
				my $source = '';
				my $start_line;
				
				while (my $tag = shift @$tags) {
					if (not defined $tag) {
						die "missing /PERL tag";
					}
					
					if ($tag->{type} eq '/PERL') {
						last;
					}
					elsif ($tag->{type} ne 'TEXT') {
						die "non-text tag in PERL section in '$template_id' starting at line $tag->{start_line}";
					}
					else {
						if (not defined $start_line) {
							$start_line = $tag->{start_line};
						}
						$source .= $tag->{source};
					}
				}
				
				$methods{$cur_method} .= $format_perl->($source, $start_line);
			}
		}
		
		# METHOD TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'METHOD') {
			
			if ($cur_method ne 'main') {
				die "cannot declare METHOD here";
			}
			
			$cur_method = $tag->{text};
			if ($cur_method !~ /^[a-zA-Z]\w*$/) {
				die "illegal method name $cur_method";
			}
			
			if (defined $methods{$cur_method}) {
				die "attempting to redefine METHOD $cur_method";
			}
		}
		
		# /METHOD TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq '/METHOD') {
			
			if ($cur_method eq 'main') {
				die "cannot end METHOD here";
			}
			
			$cur_method = 'main';
		}
		
		# MERGE TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'MERGE') {
			
			# FORMAT THE PERL
			$methods{$cur_method} .= "\t\$Result .= (";
			
			my @lines = split /\n/, $tag->{text};
			
			my $cur_line = $tag->{start_line};
			while ($_ = shift @lines) {
				$methods{$cur_method} .= $_;
				if (@lines) {
					$methods{$cur_method} .= "###TMOJO_LINE: $cur_line\n";
				}
				else {
					$methods{$cur_method} .= "); ###TMOJO_LINE: $cur_line\n";
				}
				
				$cur_line += 1;
			}
		}
		
		# CAPTURE TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'CAPTURE') {
			
			push @stack, 'CAPTURE';
			push @stack_details, $tag->{text};
			push @stack_lines, $tag->{start_line};
			
			$methods{$cur_method} .= "\tpush(\@ResultStack, ''); local \*Result = \\\$ResultStack[-1];\n";
		}
		
		# /CAPTURE TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq '/CAPTURE') {
			
			if (pop(@stack) ne 'CAPTURE') {
				die "unexpected /CAPTURE tag>";
			}
			
			my $capture_lvalue = pop @stack_details;
			my $capture_line = pop @stack_lines;
			
			$methods{$cur_method} .= "\t$capture_lvalue = pop(\@ResultStack); local \*Result = \\\$ResultStack[-1];###TMOJO_LINE: $capture_line\n";
		}
		
		# FILTER TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'FILTER') {
			
			push @stack, 'FILTER';
			push @stack_details, $tag->{text};
			push @stack_lines, $tag->{start_line};
			
			$methods{$cur_method} .= "\tpush(\@ResultStack, ''); local \*Result = \\\$ResultStack[-1];\n";
		}
		
		# /FILTER TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq '/FILTER') {
			
			if (pop(@stack) ne 'FILTER') {
				die "unexpected /FILTER tag>";
			}
			
			my $filter_code = pop @stack_details;
			my $filter_line = pop @stack_lines;
			
			$methods{$cur_method} .= "\t\$ResultStack[-2] .= ($filter_code); pop(\@ResultStack); local \*Result = \\\$ResultStack[-1];###TMOJO_LINE: $filter_line\n";
		}
		
		# REGEX TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'REGEX') {
			
			push @stack, 'REGEX';
			push @stack_details, $tag->{text};
			push @stack_lines, $tag->{start_line};
			
			$methods{$cur_method} .= "\tpush(\@ResultStack, ''); local \*Result = \\\$ResultStack[-1];\n";
		}
		
		# /REGEX TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq '/REGEX') {
			
			if (pop(@stack) ne 'REGEX') {
				die "unexpected /REGEX tag>";
			}
			
			my $regex = pop @stack_details;
			my $regex_line = pop @stack_lines;
			
			$methods{$cur_method} .= "\t\$Result =~ $regex; \$ResultStack[-2] .= \$Result; pop(\@ResultStack); local \*Result = \\\$ResultStack[-1];###TMOJO_LINE: $regex_line\n";
		}
	}
	
	# MAKE SURE OUR MODE IS COOL
	if ($cur_method ne 'main') {
		die "expected /METHOD tag";
	}
	
	if (@stack) {
		die "expected /$stack[-1] tag";
	}
	
	# NOW, WE CONSTRUCT THE ENTIRE PACKAGE
	# --------------------------------------
	
	my $template_compiled = qq{###TMOJO_TEMPLATE_ID: $template_id
package $package_name;

use strict;

our \$Tmojo;

$global_section

sub new {					
	my \$Self = {
		args    => \$_[1],
		next    => \$_[2],
		vars    => {},
	};
	
	bless \$Self, \$_[0];
	
	# DEFINE THE IMPLICIT VARIABLES
	my \$Next  = \$Self->{next};
	our \%Args; local \*Args = \$Self->{args};
	our \%Vars; local \*Vars = \$Self->{vars};
	
	# --- BEGIN USER CODE ---
$init_section
	# --- END USER CODE ---
	
	# RETURN THE VALUE
	return \$Self;
}
	};
	
	foreach my $method (keys %methods) {
		$template_compiled .= qq{
sub $method {
	my \$Self = shift \@_;
	
	# DEFINE THE IMPLICIT VARIABLES
	my \$Next  = \$Self->{next};
	our \%Args; local \*Args = \$Self->{args};
	our \%Vars; local \*Vars = \$Self->{vars};
	
	my \@ResultStack = ('');
	our \$Result; local \*Result = \\\$ResultStack[-1];
	
	
	# --- BEGIN USER CODE ---
$methods{$method}
	# --- END USER CODE ---
	
	return \$Result;
}
		};
	}
	
	$template_compiled .= "\n1;\n";
	
	return $template_compiled;
}





sub compile_lite_template {
	my ($source, $template_id, $package_name) = @_;
	
	# ADJUST FOR SOURCE LINES
	if (ref($source) eq 'ARRAY') {
		$source = join "", @$source;
	}
	
	# PARSE THE SOURCE INTO TAGS
	my $tags = parse_template($source);
	
	my %methods = (
		main => '',
	);
	
	my $cur_method = 'main';
	
	# PARSE ALL OF THE TAGS
	while (my $tag = shift @$tags) {
	
		# TEXT TAG
		# ---------------------------------
	
		if ($tag->{type} eq 'TEXT') {
			my $dumper = Data::Dumper->new([$tag->{text}]);
			$dumper->Useqq(1);
			$dumper->Indent(0);
			$dumper->Terse(1);
			my $literal = $dumper->Dump();
			
			$methods{$cur_method} .= "\t\$Result .= $literal;\n";
		}
				
		# METHOD TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'METHOD') {
			
			if ($cur_method ne 'main') {
				die "cannot declare METHOD here";
			}
			
			$cur_method = $tag->{text};
			if ($cur_method !~ /^[a-zA-Z]\w*$/) {
				die "illegal method name $cur_method";
			}
			
			if ($methods{$cur_method} ne '') {
				die "attempting to redefine METHOD $cur_method";
			}
		}
		
		# /METHOD TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq '/METHOD') {
			
			if ($cur_method eq 'main') {
				die "cannot end METHOD here";
			}
			
			$cur_method = 'main';
		}
				
		# MERGE TAG
		# ---------------------------------
		
		elsif ($tag->{type} eq 'MERGE') {
			
			if ($tag->{text} =~ /^\$([\w\.]+)$/) {
				my $lookup = $1;
				$lookup =~ s/\.(\w+)/}{$1/g;
				$methods{$cur_method} .= "\t\$Result .= \$args->{$lookup};###TMOJO_LINE: $tag->{start_line}\n";
			}
			else {
				die "malformed merge tag in $template_id on line $tag->{start_line}";
			}			
		}
	}
	
	# MAKE SURE OUR MODE IS COOL
	if ($cur_method ne 'main') {
		die "expected /METHOD tag";
	}
	
	# NOW, WE CONSTRUCT THE ENTIRE PACKAGE
	# --------------------------------------
	
	my $template_compiled = qq{###TMOJO_TEMPLATE_ID: $template_id
package $package_name;

use strict;

our \$Tmojo;

sub new {					
	my \$Self = {
		args    => \$_[1],
	};
	
	# RETURN THE VALUE
	return bless \$Self, \$_[0];
}
	};
	
	foreach my $method (keys %methods) {
		$template_compiled .= qq{
sub $method {
	my \$Self = shift \@_;
	
	my \$args = \$Self->{args};
	if (\@_) {
		\$args = { \@_ };
	}
	
	my \$Result = '';
	
	# --- BEGIN USER CODE ---
$methods{$method}
	# --- END USER CODE ---
	
	return \$Result;
}
		};
	}
	
	$template_compiled .= "\n1;\n";
	
	return $template_compiled;
}

sub get_template_class {

	my ($self, $template_id, $used_parents) = @_;
	
	# NORMALIZE THE TEMPLATE_ID
	my $normalized_template_id = $self->normalize_template_id($template_id);
	
	# GET THE PACKAGE NAME
	my $package_name = $self->{template_loader}->template_package_name($normalized_template_id);
	
	# FIGURE OUT WHERE WE'D CACHE THIS THING
	my $template_compiled_fn = $self->get_template_compiled_fn($package_name);
	
	# LOOK IN OUR CACHE TO SEE IF WE HAVE THE TEMPLATE
	my $cache_time_stamp = 0;
	if (-r $template_compiled_fn) {
		$cache_time_stamp = (stat($template_compiled_fn))[9];
	}
	
	# ATTEMPT TO LOAD THE TEMPLATE
	my ($template_lines, $tmojo_lite) = $self->{template_loader}->load_template($normalized_template_id, $cache_time_stamp);
	
	# IF $template_lines CAME BACK AS A ZERO, THEN OUR CACHED VERSION IS STILL GOOD
	my $cache_level = 0;
	if ($template_lines == 0) {
		$cache_level = 1;
		
		if (exists $memory_cache{$package_name}) {
			if ($cache_time_stamp <= $memory_cache{$package_name}) {
				$cache_level = 2;
			}
		}
	}
	
	# IF WE DON'T HAVE IT IN THE CACHE
	if ($cache_level == 0) {
			
		# COMPILE THE TEMPLATE
		my $template_compiled;
		if ($tmojo_lite) {
			$template_compiled = compile_lite_template($template_lines, $normalized_template_id, $package_name);
		}
		else {
			$template_compiled = compile_template($template_lines, $normalized_template_id, $package_name);
		}
		
		# CACHE THE TEMPLATE
		# ------------------
		# IT TURNS OUT THAT YOU CAN'T GET AWAY WITH HAVING THE LINE
		# NUMBERS IN THE PERL CODE, BECAUSE IT SCREWS UP qq{} AND
		# OTHER NEATO THINGS
		
		# SO, ALAS, NOW THAT WE'VE GONE TO THE TROUBLE OF ADDING THE
		# LINE NUMBERS, WE'RE GOING TO STRIP THEM AND PUT THEM IN
		# ANOTHER FILE... :(
		my @final_lines = split /\n/, $template_compiled;
		
		open CODE_FH, ">$template_compiled_fn" or die "$! ($template_compiled_fn)";
		open LINE_FH, ">$template_compiled_fn.lines" or die "$! ($template_compiled_fn.lines)";
		
		foreach my $line (@final_lines) {
			if ($line =~ /^(.*)(###TMOJO_(TEMPLATE_ID|LINE): .+)$/) {
				print CODE_FH "$1\n";
				print LINE_FH "$2\n";
			}
			else {
				print CODE_FH "$line\n";
				print LINE_FH ".\n";
			}
		}
		
		close CODE_FH;
		close LINE_FH;
	}
	
	# IF IT'S NOT IN THE MEMORY CACHE
	if ($cache_level < 2) {
		# DELETE THE PACKAGE
		delete_package($package_name);
		
		# PUT A CONTEXTUAL TMOJO OBJECT INTO THE PACKAGE
		{
			no strict 'refs';
			my $context_path = $normalized_template_id;
			$context_path =~ s{/[^/]+$}{};
			my $contextual_tmojo = HTML::Tmojo->new(%$self, context_path => $context_path);
			${$package_name . '::Tmojo'} = $contextual_tmojo;
		}
		
		# NOW WE DO THE FILE
		do $template_compiled_fn;
		die if $@;
		
		# REMOVE THE TEMPLATE FROM %INC (BECAUSE StatINC HURTS)
		delete $INC{$template_compiled_fn};
		
		# RECORD THE LAST TIME THAT THE PACKAGE WAS COMPILED
		$memory_cache{$package_name} = time();
	}
	
	# MAKE SURE THAT LOAD TEMPLATE HAS BEEN CALLED ON THE PARENT TEMPLATES
	{
		no strict 'refs';
		
		# MAKE SURE THAT WE DON'T HAVE AN INFINITE LOOP HERE
		if (defined $used_parents) {
			if ($used_parents->{$normalized_template_id} == 1) {
				die "circular parent reference, $normalized_template_id already used (this will cause an infinite loop)";
			}
		}
		else {
			$used_parents = {};
		}
		
		$used_parents->{$normalized_template_id} = 1;
		
		my @parents = @{$package_name . '::TMOJO_ISA'};
		
		if (@parents) {
			foreach (@parents) {
				my $contextual_tmojo = ${$package_name . '::Tmojo'};
				$_ = $contextual_tmojo->get_template_class($_, $used_parents);
			}
			
			@{$package_name . '::ISA'} = @parents;
		}
	}
	
	# RETURN THE PACKAGE NAME
	return $package_name;
}

sub normalize_template_id {
	my ($self, $template_id) = @_;
	
	# THIS IS WHERE THE MAGIC OF THE CONTEXT PATH IS RESOLVED
	if (substr($template_id, 0, 3) eq '../') {
		my $context_path = $self->{context_path};
		
		while (substr($template_id, 0, 3) eq '../') {
			$context_path =~ s{/[^/]*$}{};
			$template_id = substr($template_id, 3);
		}
		
		$template_id = "$context_path/$template_id";
	}
	elsif (substr($template_id, 0, 1) ne '/') {
		$template_id = "$self->{context_path}/$template_id";
	}
	
	# HANDLE UPWARD TRAVERSAL
	if (substr($template_id, -1, 1) eq '^') {
		$template_id = substr($template_id, 0, -1);
		
		while (rindex($template_id, '/') > 0) {
			if ($self->{template_loader}->template_exists($template_id)) {
				last;
			}
			else {
				$template_id =~ s{/[^/]+/([^/]+)$}{/$1};
			}
		}
	}
	
	# NOW WE'VE GOT OUR NAME
	return $template_id;
}

sub get_template_compiled_fn {
	my ($self, $package_name) = @_;
	
	# MAKE SURE ALL OF THE DIRECTORIES ARE THERE
	my @parts = split('::', $package_name);
	my $current_dir = $self->{cache_dir};
	
	# GET RID OF THE LAST ONE
	my $last_part = pop @parts;
	
	# MAKE ALL OF THE DIRECTORIES
	while (@parts) {
		$current_dir .= '/' . shift(@parts);
		unless (-d $current_dir) {
			mkdir $current_dir;
		}
	}
	
	my $compiled_fn = $current_dir . "/$last_part";
	
	return $compiled_fn;
}

1;
