
package Inline::JSON;

use v5.10;
use strict;
use warnings;
no warnings 'once';

use Filter::Simple;
use JSON;

# This is using recursive balanced regex as per:
# http://learn.perl.org/faq/perlfaq6.html#Can-I-use-Perl-regular-expressions-to-match-balanced-text-
FILTER_ONLY
    'executable' => sub {
        s/
            (                         # Outer capture group 1 start
                json: (\s*)           # Capture group 2 (space) start
                (                     # Capture group 3 (braces) start
                   \{                 # Opening brace
                       (?:
                           [^\{\}]++  # Non-braces, no backtrace
                           | 
                           (?3)       # Recursively capture group 2 (braces)
                       )*
                   \}
                )
            )
        /
            my $space = $2;
            my $json = $3;
            $json =~ s|'|\\'|;
            $space."JSON->new->decode('$json')";
        /gsex;
    },
    'executable' => sub {
        s/
            (                         # Outer capture group 1 start
                json: (\s*)           # Capture group 2 (space) start
                (                     # Capture group 3 (brackets) start
                   \[                 # Opening bracket
                       (?:
                           [^\[\]]++  # Non-brackets, no backtrace
                           | 
                           (?3)       # Recursively capture group 2 (brackets)
                       )*
                   \]
                )
            )
        /
            my $space = $2;
            my $json = $3;
            $json =~ s|'|\\'|;
            $space."JSON->new->decode('$json')";
        /gsex;
    },
    'all' => sub {
        return unless $Inline::JSON::DEBUG;
        print STDERR join '', map {"Inline::JSON> $_\n"} split /\n/, $_;
    },
;



=head1 NAME

Inline::JSON - Embed JSON data structures directly into your Perl code

=cut

our $VERSION = '1.0.4';

=head1 SYNOPSIS

    use Inline::JSON;

    my $json = json: {
        "name":   "Awesome",
        "title":  "Mr.",
        "skills": [
            "Nunchucking",
            "Bowhunting",
            "Computer Hacking",
            "Being Awesome",
        ]
    };

    use Data::Dumper;
    print Dumper($json);

Yields the output like:

    $VAR1 = {
               'name' => 'Awesome',
               'title' => 'Mr.',
               'skills' => [
                             'Nunchucking',
                             'Bowhunting',
                             'Computer Hacking',
                             'Being Awesome',
                           ]
            };

You can also specify array references as the top-level JSON element, by using
brackets instead of curly braces:

    my $list_of_hashrefs = json: [
        {
            "id": "1",
            "name": "one",
        },
        {
            "id": "2",
            "name": "two",
        },
        {
            "id": "3",
            "name": "three",
        },
    ];

=head1 DESCRIPTION

JSON is a data specification format used for interoperability with a
multitude of languages. Sometimes you have a chunk of JSON that you need to
turn into a Perl data structure.  This module allows you to specify that
code inline within your perl program.  It is syntactic sugar on top of
the existing JSON module, you could just as easily say:

   my $json = JSON->new->decode('{
       // JSON code here
   }');

Which is what the module is doing internally, it just looks nicer.

=head1 CAVEATS

This module uses simple balanced brackets or curly braces matching to
determine the end of the chunk of JSON code, and does not pay attention to
quotes.  If you have curly braces embedded in the strings in your JSON code,
it can cause the filter to misinterpret the end of the JSON.

If you'd like to see what the filtered perl code looks like after the source
filter has been run on it, set the variable $Inline::JSON::DEBUG to a true
value prior to the 'use Inline::JSON' statement.

=head1 SEE ALSO

=over 8

=item L<JSON>

The module being used to parse the JSON content.

=item L<Inline::YAML>

The inspiration for this module.

=back


=head1 AUTHOR

Anthony Kilna, C<< <anthony at kilna.com> >> - L<http://anthony.kilna.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-inline-json at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Inline-JSON>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Inline::JSON


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Inline-JSON>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Inline-JSON>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Inline-JSON>

=item * Search CPAN

L<http://search.cpan.org/dist/Inline-JSON/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Kilna Companies.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Inline::JSON
