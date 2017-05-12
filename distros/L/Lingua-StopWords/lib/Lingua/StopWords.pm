package Lingua::StopWords;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( getStopWords ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = 0.09;

sub getStopWords {
    my ( $language, $encoding ) = @_;

    return undef unless $language;

    $language = uc($language);
    eval { require "Lingua/StopWords/$language.pm"; };
    return undef if $@;

    my @args = $encoding ? ($encoding) : ();
    no strict 'refs';
    return &{ "Lingua::StopWords::$language\::getStopWords" }(@args);
}

1;

__END__

=head1 NAME

Lingua::StopWords - Stop words for several languages.

=head1 SYNOPSIS

    use Lingua::StopWords qw( getStopWords );
    my $stopwords = getStopWords('en');
    
    my @words = qw( i am the walrus goo goo g'joob );
    
    # prints "walrus goo goo g'joob"
    print join ' ', grep { !$stopwords->{$_} } @words;

=head1 DESCRIPTION

In keyword search, it is common practice to suppress a collection of
"stopwords": words such as "the", "and", "maybe", etc. which exist in in a
large number of documents and do not tell you anything important about any
document which contains them.  This module provides such "stoplists" in
several languages.

=head2 Supported Languages

    |-----------------------------------------------------------|
    | Language   | ISO code | default encoding | also available |
    |-----------------------------------------------------------|
    | Danish     | da       | ISO-8859-1       | UTF-8          | 
    | Dutch      | nl       | ISO-8859-1       | UTF-8          | 
    | English    | en       | ISO-8859-1       | UTF-8          |
    | Finnish    | fi       | ISO-8859-1       | UTF-8          |
    | French     | fr       | ISO-8859-1       | UTF-8          |
    | German     | de       | ISO-8859-1       | UTF-8          | 
    | Hungarian  | hu       | ISO-8859-1       | UTF-8          | 
    | Italian    | it       | ISO-8859-1       | UTF-8          | 
    | Norwegian  | no       | ISO-8859-1       | UTF-8          | 
    | Portuguese | pt       | ISO-8859-1       | UTF-8          | 
    | Spanish    | es       | ISO-8859-1       | UTF-8          | 
    | Swedish    | sv       | ISO-8859-1       | UTF-8          | 
    | Russian    | ru       | KOI8-R           | UTF-8          | 
    |-----------------------------------------------------------|

=head1 FUNCTIONS

=head2 getStopWords

    my $stoplist      = getStopWords('en');
    my $utf8_stoplist = getStopWords('en', 'UTF-8');

Retrieve a stoplist in the form of a hashref where the keys are all
stopwords and the values are all 1.

    $stoplist = {
        and => 1,
        if  => 1,
        # ...
    };

getStopWords() expects 1-2 arguments.  The first, which is required, is an ISO
code representing a supported language.  If the ISO code cannot be found,
getStopWords returns undef.

The second argument should be 'UTF-8' if you want the stopwords encoded in
UTF-8.  The UTF-8 flag will be turned on, so make sure you understand all the
implications of that.
    
=head1 SEE ALSO

The stoplists supplied by this module were created as part of the Snowball
project (see L<http://snowball.tartarus.org>,
L<Lingua::Stem::Snowball|Lingua::Stem::Snowball>).

L<Lingua::EN::StopWords|Lingua::EN::StopWords> provides a different stoplist
for English.

=head1 AUTHOR

Maintained by Marvin Humphrey E<lt>marvin at rectangular dot comE<gt>.
Original author Fabien Potencier, E<lt>fabpot at cpan dot orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008 Fabien Potencier, Marvin Humphrey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

