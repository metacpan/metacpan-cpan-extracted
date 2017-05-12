#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::TreeBuilder;
use MKDoc::XML::TreePrinter;


{
    my $xml = <<'EOF';
<!DOCTYPE html PUBLIC 
  "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<foo>This is a <br /> quite good <span class="important">test</span>.
We should see if the method which grabs descendant nodes is:
<?some_pi?>
<ul>
  <li>OK</li>
  <li>Kind of OK</li>
  <li>Completely Fubar</li>
</ul>
<!-- some comment -->
</foo>
EOF
   
    $xml =~ s/\s+$//; 
    my @nodes = MKDoc::XML::TreeBuilder->process_data ($xml);
    my $res   = MKDoc::XML::TreePrinter->process (@nodes);
    is ($res => $xml);
}


1;


__END__
