###########################################################################
# Copyright 2004 Lab-01 LLC <http://lab-01.com/>
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

package HTML::Tmojo::TemplateLoader;

use strict;

sub new {
	my ($class, $template_dir, $tmojo_lite) = @_;
	
	$template_dir =~ s/\/$//;
	
	my $self = {
		template_dir => $template_dir,
		tmojo_lite   => $tmojo_lite,
	};
	
	return bless $self, $class;
}

sub load_template {
	my ($self, $normalized_template_id, $cache_time_stamp) = @_;
	
	my $file_name = "$self->{template_dir}$normalized_template_id";
	
	unless (-r $file_name) {
		die "couldn't find template '$normalized_template_id' ($file_name)";
	}
	
	if (-d $file_name) {
		die "template '$normalized_template_id' ($file_name) is a directory";
	}
	
	my $source_time_stamp = (stat($file_name))[9];
	
	if ($source_time_stamp > $cache_time_stamp) {
		# LOAD AND RETURN THE FILE
		open my ($fh), $file_name;
		local $/ = "\n"; # THIS CAN GET EXTRA SCREWED UP IN MOD_PERL
		my @template_lines = <$fh>;
		close $fh;
		
		return \@template_lines, $self->{tmojo_lite};
	}
	else {
		return 0;
	}
}

sub template_exists {
	my ($self, $normalized_template_id) = @_;
	
	my $file_name = "$self->{template_dir}$normalized_template_id";
	
	if (-r $file_name) {
		return 1;
	}
	else {
		return 0;
	}
}

sub template_package_name {
	my ($self, $normalized_template_id) = @_;
	
	my $package = "$self->{template_dir}$normalized_template_id";
	
	for ($package) {
		tr/:/_/;
		s{/}{::}g;
		s/[^\d\w:]/_/g;
	}
	
	$package = "HTML::Tmojo::TemplateLoader::$package";
	
	return $package;
}

1;