package TestSqliteCmd;
use strict;
use warnings;

sub which_sqlite {
   eval { require 5.008_000; 1 }
     or return (undef, 'perl 5.8 needed for external command execution');
   my $prg = $ENV{SQLITE_PATH} || 'sqlite3';
   open my $fh, '-|', $prg, '-version'
     or return (undef, "no pipe to $prg");
   my $version = <$fh>;
   return (undef, "could not read $prg version") unless $version;
   my ($major) = split /\./, $version;
   $major =~ /\A \d+ \z/mxs
     or return (undef, "no suitable version in $prg");
   $major >= 3 or return (undef, "need $prg to be at least version 3");
   return ($prg, undef);
} ## end sub which_sqlite

1;
