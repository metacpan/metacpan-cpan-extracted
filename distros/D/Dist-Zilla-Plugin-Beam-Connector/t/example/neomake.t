
use strict;
use warnings;

use Test::More;
use Path::Tiny qw( cwd path );
use constant _eg => cwd()->child('examples/neo-makemaker')->stringify;
use lib _eg;

# ABSTRACT: Test neomake example works

use Test::DZil qw( Builder );
my $tzil = Builder->from_config( { dist_root => _eg } );
$tzil->chrome->logger->set_debug(1);
$tzil->build;

pass("Built ok");

my $file_content = $tzil->slurp_file('build/Makefile.PL');

my (@matches) = grep /win32/i, split /\n/, $file_content;

# Importat: These lines are duplicates of each other
note explain \@matches;

is( scalar @matches, 4, "4 lines added referencing Win32" );
is( scalar( grep /MSWin32/i,     @matches ), 2, "2 lines added referencing MSWin32" );
is( scalar( grep /Unsupported/i, @matches ), 2, "2 lines added referencing Unsupported" );

my (@messages) = grep /This message brought/i, split /\n/, $file_content;
note explain \@messages;
is( scalar @messages, 2, "2 messages added by non-dzil code!" );
is( scalar( grep /letter G/i, @messages ), 1, "Letter G arrived" );
is( scalar( grep /letter M/i, @messages ), 1, "Letter M arrived" );

done_testing;

