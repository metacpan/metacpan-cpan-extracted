use strict;
use Test::Base tests => 1;
use HTML::Split;

filters {
    input    => [ qw( chomp ) ],
    expected => [ qw( lines chomp array ) ],
};

sub paginate {
    my $len = filter_arguments;
    return [ HTML::Split->split(html => $_, length => $len) ];
}

run_compare;

__END__

=== Endless loop (bugzid:60519)
--- input paginate=15
<div class="foo"><p class="bar">loop</p></div>
--- expected
<div class="foo"></div>
<div class="foo"><p class="bar"></p></div>
<div class="foo"><p class="bar">loop</p></div>
