use lib 'lib';
use html::Greeting;

use Data::Dumper;

print Dumper \%INC; # shows we are using the hhtml::Greeting which
                    # obtains its file via HTML::Seamstress::Base::comp_root()
                    # instead of via __PACKAGE__->html( )

my $tree = html::Greeting->new;

$tree->process;

print $tree->as_HTML(undef, ' ');
