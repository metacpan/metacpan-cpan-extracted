#!/usr/bin/perl -w
use Test::More no_plan;
use HTML::Template::Pro;

my $src1 =<<"END;";
<tmpl_var EXPR="version()">
END;

my $template1   = HTML::Template::Pro->new(scalarref => \$src1, debug=> 0);
my $out=$template1->output();
print $out;
ok(length($out)>0); 

__END__
