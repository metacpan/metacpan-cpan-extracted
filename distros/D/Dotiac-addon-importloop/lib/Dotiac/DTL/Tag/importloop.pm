#importloop.pm
#Last Change: 2009-02-04
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.2
####################
#This file is part of the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#import.pm is published under the terms of the MIT license, which basically 
#means "Do with it whatever you want". For more inimportmation, see the 
#license.txt file that should be enclosed with libsofu distributions. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################

package Dotiac::DTL::Tag::importloop;
use base qw/Dotiac::DTL::Tag/;
use strict;
use warnings;
require Scalar::Util;

our $VERSION = 0.2;

sub new {
	my $class=shift;
	my $self={p=>shift()};
	my $name=shift;
	my %name = Dotiac::DTL::get_variables($name,"reversed","merge","contextvars");
	$self->{source}=shift @{$name{""}};
	if ($name{reversed}) {
		$self->{rev}=1;
	}
	if ($name{merge}) {
		$self->{merge}=1;
	}
	if ($name{contextvars}) {
		$self->{contextvars}=1;
	}
	foreach my $e (map {@{$name{$_}}} keys %name) {
		if ($e eq "contextvars") {
			$self->{contextvars}=1;
		}
		elsif ($e eq "merge") {
			$self->{merge}=1;
		}
		elsif ($e eq "reversed") {
			$self->{rev}=1;
		}
	}
	die "Can't use \"importloop\" without a datasource" unless $self->{source};
	my $obj=shift;
	my $data=shift;
	my $pos=shift;
	my $found="";
	$self->{content}=$obj->parse($data,$pos,\$found,"endimportloop","empty");
	if ($found eq "empty") {
		$self->{empty}=$obj->parse($data,$pos,\$found,"endimportloop");
	}
	bless $self,$class;
	return $self;
}

sub perl {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	$self->SUPER::perl($fh,$id,@_);
	print $fh "my ";
	print $fh (Data::Dumper->Dump([$self->{source}],["\$source$id"]));	
	$id=$self->{content}->perl($fh,$id+1,@_);
	$id=$self->{empty}->perl($fh,$id+1,@_) if $self->{empty};
	return $self->{n}->perl($fh,$id+1,@_);


	
}

sub print {
	my $self=shift;
	print $self->{p};
	my $var=Dotiac::DTL::devar_raw($self->{source},@_);
	my $vars=shift;
	my $merge=$self->{merge};
	my $cv=$self->{contextvars};
	my @loop=();
	@loop=grep {
		Scalar::Util::reftype($_) eq "HASH";
	} @{$var->content} if $var->array;
	if (@loop) {
		@loop=reverse @loop if $self->{rev};
		foreach my $v (0 .. $#loop) {
			my $newvars;
			if ($merge) {
				$newvars={%{$vars},%{$loop[$v]}} if $merge;
			}
			else {
				$newvars={%{$loop[$v]}};
			}
			if ($cv) { #HTML::Template like loop_context_vars:
				$newvars->{__first__}=($v == 0);
				$newvars->{__inner__}=($v!=0 and $v!=$#loop);
				$newvars->{__last__}=($v == $#loop);
				$newvars->{__counter__}=$v+1;
				$newvars->{__odd__}=!($v%2);
			}
			$self->{content}->print($newvars,@_);

			
		}
	}
	else {
		$self->{empty}->print($vars,@_) if $self->{empty};
	}
	$self->{n}->print($vars,@_);
}
sub string {
	my $self=shift;
	my $var=Dotiac::DTL::devar_raw($self->{source},@_);
	my $vars=shift;
	my $merge=$self->{merge};
	my $cv=$self->{contextvars};
	my @loop=();
	my $r="";
	@loop=grep {
		Scalar::Util::reftype($_) eq "HASH";
	} @{$var->content} if $var->array;
	if (@loop) {
		@loop=reverse @loop if $self->{rev};
		foreach my $v (0 .. $#loop) {
			my $newvars;
			if ($merge) { #HTML::Template like global_vars
				$newvars={%{$vars},%{$loop[$v]}} if $merge;
			}
			else {
				$newvars={%{$loop[$v]}};
			}
			if ($cv) { #HTML::Template like loop_context_vars:
				$newvars->{__first__}=($v == 0);
				$newvars->{__inner__}=($v!=0 and $v!=$#loop);
				$newvars->{__last__}=($v == $#loop);
				$newvars->{__counter__}=$v+1;
				$newvars->{__odd__}=!($v%2);
			}
			$r.=$self->{content}->string($newvars,@_);
		}
	}
	else {
		$r.=$self->{empty}->string($vars,@_) if $self->{empty};
	}
	return $self->{p}.$r.$self->{n}->string($vars,@_);
	
}

sub perlprint {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	my $level=shift;
	$self->SUPER::perlprint($fh,$id,$level,@_);
	my $in="\t" x $level;
	print $fh $in,"my \$importvar$id = Dotiac::DTL::devar_raw(\$source$id,\$vars,\$escape,\@_);\n";
	print $fh $in,"my \$importvars$id = \$vars;\n" if $self->{merge};
	print $fh $in,"my \@importloop$id = ();\n";
	print $fh $in,"my \$ref$id = Scalar::Util::reftype(\$importvar$id);\n";
	print $fh $in,"\@importloop$id=grep { Scalar::Util::reftype(\$_) eq \"HASH\"} \@{\$importvar$id->content} if \$importvar$id->array;\n";
	print $fh $in,"\@importloop$id = reverse \@importloop$id;\n" if $self->{rev};
	if ($self->{empty}) {
		print $fh $in,"if (\@importloop$id) {\n";
		print $fh $in,"\tforeach my \$loop (0 .. \$#importloop$id) {\n";
		$level++;
	}
	else {
		print $fh $in,"foreach my \$loop (0 .. \$#importloop$id) {\n";
	}
	my $in2="\t" x ($level+1);
	if ($self->{merge}) {
		print $fh $in2, "my \$vars={\%{\$importvars$id},\%{\$importloop$id"."[\$loop]}};";
	}
	else {
		print $fh $in2, "my \$vars={\%{\$importloop$id"."[\$loop]}};";
	}
	if ($self->{contextvars}) { #HTML::Template like loop_context_vars:
		print $fh $in2, "\$vars->{__first__}=(\$loop == 0);\n";
		print $fh $in2, "\$vars->{__inner__}=(\$loop!=0 and \$loop!=\$#importloop$id);\n";
		print $fh $in2, "\$vars->{__last__}=(\$loop == \$#importloop$id);\n";
		print $fh $in2, "\$vars->{__counter__}=\$loop+1;\n";
		print $fh $in2, "\$vars->{__odd__}=!(\$loop%2);\n";
	}
	$id = $self->{content}->perlprint($fh,$id+1,$level+1,@_);
	if ($self->{empty}) {
		print $fh $in,"\t}\n";
		print $fh $in,"} else {\n";
		$id = $self->{empty}->perlprint($fh,$id+1,$level+1,@_);
		print $fh $in,"}\n";
		$level--;
	}
	else {
		print $fh $in,"}\n";
	}
	return $self->{n}->perlprint($fh,$id+1,$level,@_);
}
sub perlstring {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	my $level=shift;
	$self->SUPER::perlstring($fh,$id,$level,@_);
	my $in="\t" x $level;
	print $fh $in,"my \$importvar$id = Dotiac::DTL::devar_raw(\$source$id,\$vars,\$escape,\@_);\n";
	print $fh $in,"my \$importvars$id = \$vars;\n" if $self->{merge};
	print $fh $in,"my \@importloop$id = ();\n";
	print $fh $in,"my \$ref$id = Scalar::Util::reftype(\$importvar$id);\n";
	print $fh $in,"\@importloop$id=grep { Scalar::Util::reftype(\$_) eq \"HASH\"} \@{\$importvar$id->content} if \$importvar$id"."->array;\n";
	print $fh $in,"\@importloop$id = reverse \@importloop$id;\n" if $self->{rev};
	if ($self->{empty}) {
		print $fh $in,"if (\@importloop$id) {\n";
		print $fh $in,"\tforeach my \$loop (0 .. \$#importloop$id) {\n";
		$level++;
	}
	else {
		print $fh $in,"foreach my \$loop (0 .. \$#importloop$id) {\n";
	}
	my $in2="\t" x ($level+1);
	if ($self->{merge}) {
		print $fh $in2, "my \$vars={\%{\$importvars$id},\%{\$importloop$id"."[\$loop]}};";
	}
	else {
		print $fh $in2, "my \$vars={\%{\$importloop$id"."[\$loop]}};";
	}
	if ($self->{contextvars}) { #HTML::Template like loop_context_vars:
		print $fh $in2, "\$vars->{__first__}=(\$loop == 0);\n";
		print $fh $in2, "\$vars->{__inner__}=(\$loop!=0 and \$loop!=\$#importloop$id);\n";
		print $fh $in2, "\$vars->{__last__}=(\$loop == \$#importloop$id);\n";
		print $fh $in2, "\$vars->{__counter__}=\$loop+1;\n";
		print $fh $in2, "\$vars->{__odd__}=!(\$loop%2);\n";
	}
	$id = $self->{content}->perlstring($fh,$id+1,$level+1,@_);
	if ($self->{empty}) {
		print $fh $in,"\t}\n";
		print $fh $in,"} else {\n";
		$id = $self->{empty}->perlstring($fh,$id+1,$level+1,@_);
		print $fh $in,"}\n";
		$level--;
	}
	else {
		print $fh $in,"}\n";
	}
	return $self->{n}->perlstring($fh,$id+1,$level,@_);
}

sub perleval {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	$id=$self->{content}->perleval($fh,$id+1,@_);
	$id=$self->{empty}->perleval($fh,$id+1,@_) if $self->{empty};
	$self->{n}->perleval($fh,$id+1,@_);
}
sub perlcount {
	my $self=shift;
	my $id=shift;
	$id=$self->{content}->perlcount($id+1,@_);
	$id=$self->{empty}->perlcount($id+1,@_) if $self->{empty};
	return $self->{n}->perlcount($id+1);
}
sub perlinit {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	$id=$self->{content}->perlinit($fh,$id+1,@_);
	$id=$self->{empty}->perlinit($fh,$id+1,@_) if $self->{empty};
	return $self->{n}->perlinit($fh,$id+1);
}
sub next {
	my $self=shift;
	$self->{n}=shift;
}
sub eval {
	my $self=shift;
	$self->{n}->eval(@_);
}
1;

__END__

=head1 NAME

Dotiac::DTL::Tag::importloop - The {% importloop ARRAYOFHASHES [reversed] [merge] [contextvars] %} tag

=head1 SYNOPSIS

Variables:

	posts=>[
		{Title=>"test",Content="A test post",Date=>time},
		{Title=>"My first post",Content="Nothing to say here",Date=>time-3600}
	]

Template file:

	{% importloop posts %}
		<h1>{{ Title }}</h1> {# Title is now in the main namespace #}
		{{ Content|linebreaks }}
		<em>{{ Date|date:jS F Y H:i" }}</em>
	{% empty %}
		No entries
	{% endimportloop %}

=head1 DESCRIPTION

Iterates over a an ARRAY OF HASHES and imports those hashes into the top-level namespace.

If the loop is empty and an {% empty %} tag is given, it will run the templatecode from {% empty %} to {% endimportloop %}.

This tag works almost like L<HTML::Template>'s TMPL_LOOP tag.

=head2 reversed

If reversed is put after the source the list/array is reversed before the iteration

=head2 merge

If merge is given, the namespace is not replaced (default), but merged with the content of the hash.

=head2 contextvars

Similar to  L<HTML::Template>'s C<loop_context_vars> option, adds some variables into the namespace about the loop

=head3 __first__

True if this is the first iteration

=head3 __inner__

True if this is neither the first nor the last iteration.

=head3 __last__

True if this is the last iteration.

If there is only one iteration, C<__first__> and C<__last__> are both true, but not C<__inner__>

=head3 __counter__

The current iteration, 1 indexed.

=head3 __odd__

True on the first line and every other line (first, third, fifth and so on)

=head1 BUGS AND DIFFERENCES TO DJANGO

Also sets importloop.key if iterating over a hash.

=head1 SEE ALSO

L<http://www.djangoproject.com>, L<Dotiac::DTL>

=head1 LEGAL

Dotiac::DTL was built according to http://docs.djangoproject.com/en/dev/ref/templates/builtins/.

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut

