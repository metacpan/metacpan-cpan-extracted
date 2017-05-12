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

package HTML::Tmojo::Filters;

use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	html_attribute
	html_content
	reduce_indentation
);

sub html_attribute {
	my ($val) = @_;
	
	for ($val) {
		s/'/&apos;/g;
		s/"/&quot;/g;
	}
	
	return $val;
}

sub html_content {
	my ($val) = @_;
	
	for ($val) {
		s/&/&amp;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
	}
	
	return $val;
}

sub reduce_indentation {
	my $text = shift;
	my %args = @_;
	
	if ($args{tabs_to_spaces} ne '') {
		$text =~ s/\t/' ' x $args{tabs_to_spaces}/eg;
	}
	
	$text =~ /^(\s+)/;
	my $remove = $1;
	
	my @lines = split /\n/, $text;
	foreach my $line (@lines) {
		$line =~ s/^$remove//;
		if ($args{base_indentation} ne '') {
			$line = $args{base_indentation} . $line;
		}
	}
	
	return join("\n", @lines);
}


1;