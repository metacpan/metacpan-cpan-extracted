#Test for the unparsed tag and method

package Dotiac::DTL::Tag::unparsed;
use base qw/Dotiac::DTL::Tag/;
use strict;
use warnings;

sub new {
	my $class=shift;
	my $self={p=>shift()};
	my $name=shift;
	my $obj=shift;
	my $data=shift;
	my $pos=shift;
	my $found="";
	$self->{content}=$obj->unparsed($data,$pos,\$found,"unparsed","endunparsed");
	bless $self,$class;
	return $self;
}
sub print {
	my $self=shift;
	print $self->{p};
	my $vars=shift;
	my $escape=shift;
	print $self->{content};
	$self->{n}->print($vars,$escape,@_);
}
sub string {
	my $self=shift;
	my $vars=shift;
	my $escape=shift;
	my $r="";
	return $self->{p}.$self->{content}.$self->{n}->string($vars,$escape,@_);
	
}
sub perl {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	$self->SUPER::perl($fh,$id,@_);
	print $fh "my ";
	print $fh (Data::Dumper->Dump([$self->{content}],["\$content$id"]));
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
	print $fh "\t" x $level,"print \$content$id;\n";
	return $self->{n}->perlprint($fh,$id+1,$level,@_);
}
sub perlstring {
	my $self=shift;
	my $fh=shift;
	my $id=shift;
	my $level=shift;
	$self->SUPER::perlstring($fh,$id,$level,@_);
	print $fh "\t" x $level,"\$r.=\$content$id;\n";
	return $self->{n}->perlstring($fh,$id+1,$level,@_);
}
sub perleval {
	my $self=shift;
	my $fh=shift;
	my $id=shift;	
	$self->{n}->perleval($fh,$id+1,@_);
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
	$self->{content}->eval(@_);
	$self->{n}->eval(@_);
}
1;
