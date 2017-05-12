#!perl -T

use strict;
use warnings;
use Test::More tests => 3;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open my $fh, "<", $filename
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
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

not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

sub module_boilerplate_ok {
    my ($module) = @_;
    my %boilerplate_text = (
        'the great new $MODULENAME'    => qr/ - The great new /,
        'boilerplate description'      => qr/Quick summary of what the module/,
        'stub function definition'     => qr/function[12]/,
    );
    for my $text (split /\n/, <<"ENDEND"
Module::Name
Author name
Maintainer name
contact address
One line description of module's purpose
The initial template usually just has
Brief but working code example(s)
This section will be as far as many users bother reading
A full description of the module and its features.
May include numerous subsections
A separate section listing the public components
In an object-oriented module, this section should begin with
A list of every error and warning message that the module can generate
A full explanation of any configuration system
A list of all the other modules that this module relies upon
A list of any modules that this module cannot be used in conjunction with
A list of known problems with the module, together with some indication
Also a list of restrictions on the features the module does provide
Followed by whatever licence you wish to release it under
ENDEND
    ) {
        $boilerplate_text{qq/"$text"/} = qr/$text/i;
    }
    not_in_file_ok($module => %boilerplate_text);
}

module_boilerplate_ok('lib/Hardware/Vhdl/Tidy.pm');
