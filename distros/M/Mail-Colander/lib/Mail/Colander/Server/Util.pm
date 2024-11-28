package Mail::Colander::Server::Util;
use v5.24;
use warnings;
use experimental qw< signatures >;
{ our $VERSION = '0.004' }

use Data::HexDump::XXD qw< xxd >;

use Exporter qw< import >;
our @EXPORT_OK = qw< xxd_message >;

sub xxd_message ($data, %opts) {
   my @lines = xxd($data);

   my $n_max_lines = $opts{max_lines} // 3;
   if ($n_max_lines > 0 && @lines > $n_max_lines) {
      if ($n_max_lines == 1) {
         splice(@lines, 1);
      }
      elsif ($n_max_lines == 2) {
         splice(@lines, 1);
         push(@lines, '...');
      }
      else {
         my $last_line = pop(@lines);
         splice(@lines, $n_max_lines - 2);
         push(@lines, '...', $last_line);
      }
   }

   my $prefix = $opts{prefix} // '  ';
   @lines = map { $prefix . $_ } @lines;

   if (defined(my $pre = $opts{preamble})) {
      unshift(@lines, ref($pre) eq 'ARRAY' ? $pre->@* : $pre);
   }

   return @lines if wantarray;
   return join("\n", @lines);
}

1;
