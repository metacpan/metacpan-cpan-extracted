package Filter::BoxString;

our $VERSION = '0.05';

use 5.008008;
use strict;
use warnings FATAL => 'all';
use Filter::Simple;

my $Delimiter = 'FILTER_BOXSTRING';

my $Scalar_Regex = qr/
    [\$] \w+ (?: \{ [^\}]+ \} | \[ [^\]]+ \] )?
/xms;

my $Assignment_Regex = qr{
    (?: my \s+ )? $Scalar_Regex \s* =
}xms;

my $BoxString_Regex = qr{
    ( $Assignment_Regex ) ( \s* [+] (?: .*? ) [+]; )
}msx;

FILTER_ONLY
executable => sub {

    while ( m/$BoxString_Regex/msxg ) {

        my $heredoc   = $1;
        my $boxstring = $2;

        while ( $boxstring =~ m/$Delimiter/ ) {

            $Delimiter .= int rand 999;
        }

        $heredoc .= qq{ <<"$Delimiter";\n};

        my @lines = split /\n\s*[|]/, $boxstring;

        shift @lines;

        if ( @lines ) {

            # strip the trailing +---+;
            $lines[$#lines] =~ s{ [+-;]+ \z}{}msxg;
        }

        for my $line (@lines) {

            if ( $line !~ s/ [|] \s* \z//msx ) {

                $line =~ s/ \s* \z//msx;
            }

            $heredoc .= "$line\n";
        }

        $heredoc .= $Delimiter;

        s/\Q$boxstring\E/$heredoc/;
    }
};

1;

__END__

=head1 NAME

Filter::BoxString - Describe your multiline strings as BoxStrings.

=head1 SYNOPSIS

    use Filter::BoxString;

       # Trailing whitespace preserved
       my $list = +---------------+
                  | 1. Milk       |
                  | 2. Eggs       |
                  | 3. Apples     |
                  +---------------+;

    # Trailing whitespace dropped
    my $noodles = +-----------------------+
                  | Ramen
                  | Shirataki
                  | Soba
                  | Somen
                  | Udon
                  +;

        my $xml = +---------------------------------------+
                  |<?xml version="1.0" encoding="UTF-8"?>
                  |  <item>Milk</item>
                  |  <item>Eggs</item>
                  |  <item>Apples</item>
                  |</shopping_list>
                  +---------------------------------------+;

    my $beatles = +
                  | Love Me Do
                  | I wanna hold your hand
                  | Lucy In The Sky With Diamonds
                  | Penny Lane
                  +------------------------------+;

        my $sql = +
                  | SELECT *
                  | FROM the_table
                  | WHERE this = 'that'
                  | AND those = 'these'
                  | ORDER BY things ASC
                  +;

  my $metachars = +------------------------------------------------------------+
                  | \\  Quote the next metacharacter
                  | ^  Match the beginning of the line
                  | .  Match any character (except newline)
                  | \$  Match the end of the line (or before newline at the end)
                  | |  Alternation
                  | () Grouping
                  | [] Character class
                  +------------------------------------------------------------+;

  my $gibberish = +-----------------------------------+
                  | +!@#%^&*()_|"?><{}>~=-\'/.,[]
                  | +=!@#%^&*()_-|\"':;?/>.<,}]{[><~`
                  +-----------------------------------+;


=head1 DESCRIPTION

This filter allows you to describe multiline strings in your code using ASCII
art style BoxStrings. Underneath it all, this filter transforms your BoxString
to the equivilent here-doc.

The purpose is purely aesthetic.

=head1 SYNTAX

The BoxString instance must be some scalar assignment like:

=over

=item *

    $identifier
        = +---+
          | x |
          +---+;

=item *

    $ident{ifier} = +---+
                    | x |
                    +---+;

=item *

    $ident[$ifier] =
        +---+
        | x |
        +---+;

=back


=head1 BUGS AND LIMITATIONS

The text of your BoxString can't contain the sequence: +;

=head1 AUTHOR

Dylan Doxey E<lt>dylan.doxey@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dylan Doxey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
