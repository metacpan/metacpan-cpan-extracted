use strict;
use Test::More;
our ($dir, $DEBUG);
my $tpf_name;
BEGIN {
#  $Gimp::verbose = 3;
  $DEBUG = 0;
  require './t/gimpsetup.pl';
  use Config;
  $tpf_name = "test_perl_extension";
  write_plugin($DEBUG, $tpf_name, $Config{startperl}.
    " -w\nBEGIN { \$Gimp::verbose = ".int($Gimp::verbose||0).'; }'.<<'EOF');

use strict;
use Gimp;
use Gimp::Fu;
use Gimp::Extension;

podregister {
  (0, $num + 1);
};

podregister_temp test_temp => sub {
  my ($image, $drawable, $v1) = @_;
  ();
};

exit main;
__END__

=head1 NAME

extension_test - test Gimp::Extension

=head1 SYNOPSIS

<Image>/Filters/Languages/Perl/Test

=head1 DESCRIPTION

Description.

=head1 PARAMETERS

 [&Gimp::PDB_INT32, "num", "internal flags (must be 0)"],

=head1 RETURN VALUES

 [&Gimp::PDB_INT32, "retnum", "Number returned"],

=head1 TEMPORARY PROCEDURES

=head2 test_temp - blurb

Longer help text.

=head3 SYNOPSIS

<Image>/File/Label...

=head3 IMAGE TYPES

*

=head3 PARAMETERS

  [ PF_TOGGLE, 'var', 'Var description' ],

=head1 AUTHOR

Author.

=head1 DATE

1999-12-02

=head1 LICENSE

Same terms as Gimp-Perl.
EOF
}
use Gimp "net_init=spawn/";

is((Gimp::Plugin->extension_test(7))[1], 8, 'return val');

Gimp::Net::server_quit;
Gimp::Net::server_wait;

done_testing;
