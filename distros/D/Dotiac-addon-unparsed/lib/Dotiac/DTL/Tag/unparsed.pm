###############################################################################
#unparsed.pm
#Last Change: 2009-01-16
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.2
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#unparsed.pm is published under the terms of the MIT license, which basically 
#means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with libsofu distributions. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


package Dotiac::DTL::Tag::unparsed;
use base qw/Dotiac::DTL::Tag/;
use strict;
use warnings;

our $VERSION=0.2;

sub new {
	my $class=shift;
	my $self={p=>shift()};
	my $name=shift;
	my $obj=shift;
	my $data=shift;
	my $pos=shift;
	my $found="";
	my %name=Dotiac::DTL::get_variables(($name || ""),"as");
	$self->{filters}=[split /\|/,$name{""}->[0]] if $name{""} and $name{""}->[0];
	$self->{var}=$name{"as"}->[0] if $name{"as"} and $name{"as"}->[0];
	$self->{content}=$obj->unparsed($data,$pos,\$found,"unparsed","endunparsed");
	bless $self,$class;
	return $self;
}
sub print {
	my $self=shift;
	print $self->{p};
	my $vars=shift;
	my $escape=shift;
	my $c=$self->{content};
	$c=Dotiac::DTL::apply_filters($c,$vars,0,@{$self->{filters}})->string() if $self->{filters};
	if ($self->{var}) {
		$vars->{$self->{var}}=$c;
	}
	else {
		print $c;
	}
	$self->{n}->print($vars,$escape,@_);
}
sub string {
	my $self=shift;
	my $vars=shift;
	my $escape=shift;
	my $c=$self->{content};
	$c=Dotiac::DTL::apply_filters($c,$vars,0,@{$self->{filters}})->string() if $self->{filters};
	if ($self->{var}) {
		$vars->{$self->{var}}=$c;
		return $self->{p}.$self->{n}->string($vars,$escape,@_);
	}
	else {
		return $self->{p}.$c.$self->{n}->string($vars,$escape,@_);
	}
}
sub perl {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	$self->SUPER::perl($fh,$id,@_);
	print $fh "my ";
	print $fh (Data::Dumper->Dump([$self->{content}],["\$content$id"]));
	if ($self->{filters}) {
		print $fh "my ";
		print $fh (Data::Dumper->Dump([$self->{filters}],["\$filters$id"]));
	}
	if ($self->{var}) {
		print $fh "my ";
		print $fh (Data::Dumper->Dump([$self->{var}],["\$var$id"]));
	}
	return $self->{n}->perl($fh,$id+1,@_)
}
sub perlinit {
	my $self=shift;
	my $fh=shift;
	my $id=shift;	
	return $self->{n}->perlinit($fh,$id+1,@_)
}
sub perlprint {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	my $level=shift;
	$self->SUPER::perlprint($fh,$id,$level,@_);
	if ($self->{var}) {
		if ($self->{filters}) {
			print $fh "\t" x $level,"\$vars->{\$var$id}=Dotiac::DTL::apply_filters(\$content$id,\$vars,0,\@{\$filters$id},\@_)->string();\n";
		}
		else {
			print $fh "\t" x $level,"\$vars->{\$var$id}=\$content$id;\n";
		}
	}
	elsif ($self->{filters}) {
		print $fh "\t" x $level,"print Dotiac::DTL::apply_filters(\$content$id,\$vars,0,\@{\$filters$id},\@_)->string();\n";
	}
	else {
		print $fh "\t" x $level,"print \$content$id;\n";
	}
	return $self->{n}->perlprint($fh,$id+1,$level,@_);
}
sub perlstring {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	my $level=shift;
	$self->SUPER::perlstring($fh,$id,$level,@_);
	if ($self->{var}) {
		if ($self->{filters}) {
			print $fh "\t" x $level,"\$vars->{\$var$id}=Dotiac::DTL::apply_filters(\$content$id,\$vars,0,\@{\$filters$id},\@_)->string();\n";
		}
		else {
			print $fh "\t" x $level,"\$vars->{\$var$id}=\$content$id;\n";
		}
	}
	elsif ($self->{filters}) {
		print $fh "\t" x $level,"\$r.=Dotiac::DTL::apply_filters(\$content$id,\$vars,0,\@{\$filters$id},\@_)->string();\n";
	}
	else {
		print $fh "\t" x $level,"\$r.=\$content$id;\n";
	}
	return $self->{n}->perlstring($fh,$id+1,$level,@_);
}
sub perleval {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	my $level=shift;
	if ($self->{var}) {
		if ($self->{filters}) {
			print $fh "\t" x $level,"\$vars->{\$var$id}=Dotiac::DTL::apply_filters(\$content$id,\$vars,0,\@{\$filters$id},\@_)->string();\n";
		}
		else {
			print $fh "\t" x $level,"\$vars->{\$var$id}=\$content$id;\n";
		}
	}
	$self->{n}->perleval($fh,$id+1,$level,@_);
}
sub perlcount {
	my $self=shift;
	my $id=shift;
	return $self->{n}->perlcount($id+1);
}
sub next {
	my $self=shift;
	$self->{n}=shift;
}
sub eval {
	my $self=shift;
	my $vars=shift;
	if ($self->{var}) {
		my $c=$self->{content};
		$c=Dotiac::DTL::apply_filters($c,$vars,0,@{$self->{filters}})->string() if $self->{filters};
		$vars->{$self->{var}}=$c;
	}
	$self->{n}->eval($vars,@_);
}
1;

__END__

=head1 NAME

Dotiac::DTL::Tag::unparsed - The {% unparsed [FILTER[|FILTER2[|...]]] [as NEWVAR] %} tag

=head1 SYNOPSIS

Template file:

	{% unparsed cut:"x"|lower %}
		{% FOR xi IN xtext %}... {% ENDFOR %} 
	{% endunparsed %}
	{% unparsed %}
		The {% unparsed %} .. {% endunparsed %}-Tag
	{% endunparsed %}
	{% unparsed as var %}<a href="{{ Tag }}">{% endunparsed %}
	{{ var|escape }}

This will be rendered to:

	{% for i in text %}...{% endfor %}
	The {% unparsed %} .. {% endunparsed %}-Tag
	&lt;a href=&quot;{{ Tag }}&quot;&gt;

=head1 DESCRIPTION

Reads template text verbatim, without evaluating it. Optionally runs it through a stack of FILTERS and returns it or saves into a NEW VARIABLE.

If a NEW VARIABLEname is given, the content will not be returned but saved in that variable name.

This tag will read everything till the next {% endunparsed %} tag, unless there is an inner {% unparsed %}, in that case it will skip the corresponding {% endunparsed %} tag. Therefore it requires the inner {% unparsed %}, {% endunparsed %} tags to be balanced. 

The filtered/returned content is marked safe.

=head1 BUGS 

When saved into a variable the string is no longer marked safe, it has to be marked save manually. This is intended to be that way for writing documentation of tags in the Django Template Language.

	{% unparsed as image %}<img src="foo.jpg">{% endunparsed %}
	{{ image }} {# &lt;img src=&quot;foo.jpg&quot;&gt; #}
	{{ image|safe }} {# <img src="foo.jpg"> #}

Please report anything else at L<https://sourceforge.net/tracker2/?group_id=249411&atid=1126445>

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut
