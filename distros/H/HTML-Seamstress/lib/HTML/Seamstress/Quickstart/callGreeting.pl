use html::Greeting;

my $tree = html::Greeting->new;

$tree->process;

print $tree->as_HTML(undef, ' ');
