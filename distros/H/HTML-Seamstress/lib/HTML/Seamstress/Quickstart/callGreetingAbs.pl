use html::GreetingAbs;

my $tree = html::GreetingAbs->new;

$tree->process;

print $tree->as_HTML(undef, ' ');
