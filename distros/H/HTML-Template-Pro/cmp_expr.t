#!/usr/bin/perl -w

use HTML::Template;
use HTML::Template::Expr;
use HTML::Template::Pro;

my @arglist;
while (@ARGV) {
    push @arglist, split /=/, shift @ARGV;
}
print "Arguments: ".join(' ',@arglist),"\n" if @arglist; 

while (<>) {
	chomp;
	my $tmplline='<tmpl_var expr="'.$_.'">';
	print 'tmpl:',$tmplline,"\n";
	eval {
	    print 'Pro:',"\n";
	    my $tmpl=HTML::Template::Pro->new(scalarref => \$tmplline, die_on_bad_params=>0);
	    $tmpl->param(@arglist);
	    print 'Output:',$tmpl->output(),"\n";
	};
	print 'Pro: failed with:',"\n",$@,"\n" if $@;
	eval {
	    print 'Expr:',"\n";
	    my $tmpl=HTML::Template::Expr->new(scalarref => \$tmplline, die_on_bad_params=>0);
	    $tmpl->param(@arglist);
	    print 'Output:',$tmpl->output(),"\n";
	};
	print 'Expr: failed with:',"\n",$@,"\n" if $@;
}

