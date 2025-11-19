#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

plan tests => 10;

sub not_in_file_ok {
    my ( $filename, %regex ) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!\n";

    my %violated;

    while ( my $line = <$fh> ) {
        while ( my ( $desc, $regex ) = each %regex ) {
            if ( $line =~ $regex ) {
                push @{ $violated{ $desc } ||= [] }, $.;
            }
        }
    }
    close $fh;

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    }
    else {
        pass("$filename contains no boilerplate text");
    }
    return;
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok(
                    $module => 'the great new $MODULENAME' => qr/ - The great new /,
                    'boilerplate description' => qr/Quick summary of what the module/,
                    'stub function definition' => qr/function[12]/,
                  );
    return;
}

todo 'Need to replace the boilerplate text' => sub {

    not_in_file_ok(
                   'README.md' => "The README is used..." => qr/The README is used/,
                   "'version information here'" => qr/to provide version information/,
                  );

    not_in_file_ok(
                        'CHANGELOG.md' => "placeholder date/time" => qr(Date/time) );

    module_boilerplate_ok('lib/Dev/Util.pm');
    module_boilerplate_ok('lib/Dev/Util/Backup.pm');
    module_boilerplate_ok('lib/Dev/Util/Const.pm');
    module_boilerplate_ok('lib/Dev/Util/File.pm');
    module_boilerplate_ok('lib/Dev/Util/OS.pm');
    module_boilerplate_ok('lib/Dev/Util/Query.pm');
    module_boilerplate_ok('lib/Dev/Util/Syntax.pm');
    module_boilerplate_ok('lib/Dev/Util/Sem.pm');

};

