#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::TreeBuilder;
use MKDoc::XML::Tokenizer;


{
    my $xml = <<'EOF';
<foo>This is a <br /> quite good <span class="important">test</span>.
We should see if the method which grabs descendant nodes is:
<ul>
  <li>OK</li>
  <li>Kind of OK</li>
  <li>Completely Fubar</li>
</ul>
</foo>
EOF
    
    my $tokens  = MKDoc::XML::Tokenizer->process_data ($xml);
    my $token   = shift @{$tokens};
    my $d = MKDoc::XML::TreeBuilder::_descendant_tokens ($token, $tokens);
    is ($d->[0]->as_string(), 'This is a ');
    is ($d->[1]->as_string(), '<br />');
    is ($d->[2]->as_string(), ' quite good ');
    is ($d->[3]->as_string(), '<span class="important">');
    is ($d->[4]->as_string(), 'test');
    is ($d->[5]->as_string(), '</span>');
    
    my ($foo_node) = MKDoc::XML::TreeBuilder->process_data ($xml);
    is ($foo_node->{_tag} => 'foo');
}


1;


__END__
