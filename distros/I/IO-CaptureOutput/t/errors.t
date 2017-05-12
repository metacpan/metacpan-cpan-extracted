use strict;
use Test::More; 
use IO::CaptureOutput qw/capture/;
use File::Temp qw/tempfile/;
use Config;

# save output to specified files
my ($out, $err);
(undef, my $saved_out) = tempfile; unlink $saved_out;
(undef, my $saved_err) = tempfile; unlink $saved_err;

sub _reset { $_ = '' for ($out, $err); 1};
sub _print_stuff { print __PACKAGE__; print STDERR __FILE__}

my @valid_args = (
  q[ ],
  q[ \$out ],
  q[ undef, \$err ],
  q[ \$out, \$err ],
  q[ \$out, \$out ],
  q[ undef, undef ],
  q[ \$out, undef, $saved_out ],
  q[ \$out, undef, $saved_out, $saved_err ],
  q[ undef, \$err, undef, $saved_err ],
  q[ undef, \$err, $saved_out, $saved_err ],
  q[ \$out, \$err, $saved_out, $saved_err ],
  q[ \$out, \$out, $saved_out, $saved_out ],
  q[ undef, undef, $saved_out, $saved_out ],
);

my @invalid_args = (
  q[ \$out, \$out, $saved_out, $saved_err ],
  q[ undef, undef, $saved_out, $saved_err ],
);

plan tests => @valid_args + @invalid_args;

for my $arg ( @valid_args ) {
  _reset;
  eval "capture { _print_stuff() } $arg";
  is( $@, q{}, "no error: '$arg'" );
}

for my $arg ( @invalid_args ) {
  _reset;
  eval "capture { _print_stuff() } $arg";
  ok( $@, "error: '$arg'" );
}

