package MY::Mason;
use ExtUtils::testlib;
use Inline::Mason::OO qw(no_autoload);
our @ISA = qw(Inline::Mason::OO);
Inline::Mason::OO::to_load_files(__FILE__);

1;

__END__
__CARDINALS__
% my @cardinals = qw(eins zwei drei);
<% join q/ /, @cardinals %>
