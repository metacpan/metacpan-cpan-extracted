#!perl -T

use strict;
use warnings;
use Test::More tests => 21;

sub not_in_file_ok
{
        my ($filename, %regex) = @_;
        open my $fh, "<", $filename
            or die "couldn't open $filename for reading: $!";

        my %violated;

        while (my $line = <$fh>) {
                while (my ($desc, $regex) = each %regex) {
                        if ($line =~ $regex) {
                                push @{ $violated{$desc} ||= [] }, $.;
                        }
                }
        }

        if (%violated) {
                fail("$filename contains boilerplate text");
                diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
        } else {
                pass("$filename contains no boilerplate text");
        }
}

not_in_file_ok(README                       => "The README is used..." => qr/The README is used/,
               "'version information here'" => qr/to provide version information/,);

not_in_file_ok(Changes => "placeholder date/time" => qr(Date/time));

sub module_boilerplate_ok
{
        my ($module) = @_;
        not_in_file_ok($module                    => 'the great new $MODULENAME' => qr/ - The great new /,
                       'boilerplate description'  => qr/Quick summary of what the module/,
                       'stub function definition' => qr/function[12]/,
        );
}

module_boilerplate_ok('lib/Log/Fine.pm');
module_boilerplate_ok('lib/Log/Fine/Formatter.pm');
module_boilerplate_ok('lib/Log/Fine/Formatter/Basic.pm');
module_boilerplate_ok('lib/Log/Fine/Formatter/Detailed.pm');
module_boilerplate_ok('lib/Log/Fine/Formatter/Syslog.pm');
module_boilerplate_ok('lib/Log/Fine/Formatter/Template.pm');
module_boilerplate_ok('lib/Log/Fine/Handle.pm');
module_boilerplate_ok('lib/Log/Fine/Handle/Console.pm');
module_boilerplate_ok('lib/Log/Fine/Handle/Email.pm');
module_boilerplate_ok('lib/Log/Fine/Handle/File.pm');
module_boilerplate_ok('lib/Log/Fine/Handle/File/Timestamp.pm');
module_boilerplate_ok('lib/Log/Fine/Handle/Null.pm');
module_boilerplate_ok('lib/Log/Fine/Handle/Syslog.pm');
module_boilerplate_ok('lib/Log/Fine/Handle/String.pm');
module_boilerplate_ok('lib/Log/Fine/Levels.pm');
module_boilerplate_ok('lib/Log/Fine/Levels/Syslog.pm');
module_boilerplate_ok('lib/Log/Fine/Levels/Java.pm');
module_boilerplate_ok('lib/Log/Fine/Logger.pm');
module_boilerplate_ok('lib/Log/Fine/Utils.pm');
