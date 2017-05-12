use strict;
use Test;

BEGIN { plan tests => 12 }

use HTML::FormWizard;
ok(1);

my $form=HTML::FormWizard->new(
	-title => 'Camelot Forms Wizard');

ok($form->{title},'Camelot Forms Wizard');

$form->set(-url => 'http://www.camelot.co.pt/');

ok('http://www.camelot.co.pt/',$form->{url});

$form->add({ name => 'teste' });

ok(1,scalar @{$form->{fields}});

my $x=q/
package Form::TestCGI;

sub new {
	my $y={};
	$y->{call}=();
	bless $y;
}

sub header {
	my $self=shift;
	unshift @{$self->{call}}, "header";
	return "-";
}

sub form_header {
	my $self=shift;
	unshift @{$self->{call}}, "form_header";
	return "-";
}

sub form_field {
	my $self=shift;
	unshift @{$self->{call}}, "form_field";
	return "-";
}

sub form_group_init {
	my $self=shift;
	unshift @{$self->{call}}, "form_group_init";
	return "-";
}

sub form_group_end {
	my $self=shift;
	unshift @{$self->{call}}, "form_group_end";
	return "-";
}

sub form_actions {
	my $self=shift;
	unshift @{$self->{call}}, "form_actions";
	return "-";
}

sub form_footer {
	my $self=shift;
	unshift @{$self->{call}}, "form_footer";
	return "-";
}

sub footer {
	my $self=shift;
	unshift @{$self->{call}}, "footer";
	return "-";
}

1;
/;

my $tmpl;

$x .= "
package __PACKAGE__;

\$tmpl=Form::TestCGI->new();
";

eval $x;

if ($@) {
	print $@;
	ok(0);
} else {
	ok(1);
}

$form->set(-template => $tmpl);

$form->write;
print "\n";

ok(1);

print join ", ",@{$tmpl->{call}};
print "\n";

my $zbr = shift @{$tmpl->{call}};
ok("footer",$zbr);
$zbr=shift @{$tmpl->{call}};
ok("form_footer",$zbr);
$zbr=shift @{$tmpl->{call}};
ok(form_actions=>$zbr);
$zbr=shift @{$tmpl->{call}};
ok(form_field=>$zbr);
$zbr=shift @{$tmpl->{call}};
ok(form_header=>$zbr);
$zbr=shift @{$tmpl->{call}};
ok(header=>$zbr);
