package Lingua::IT::Hyphenate;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(sillabe);

use vars qw( $VERSION $_V $_C );

$VERSION = "0.14";

$_V = "[aeiouàèéìòù]";
$_C = "[b-df-hj-np-tv-z]";

sub sillabe {
    my(@words) = split(/[^a-zA-Zàèéìòù'0-9]+/, join(" ", @_)); #'
    my @result = ();
    foreach $word (@words) {
#DEBUG  print "word $word --> ";
        $word =~ s/($_V)([bcfgptv][lr])/$1=$2/gi;
        $word =~ s/($_V)([cg]h)/$1=$2/gi;     
        $word =~ s/($_V)(gn)/$1=$2/gi;     
        $word =~ s/($_C)\1/$1=$1/gi;
        $word =~ s/(s$_C)/=$1/gi;
        1 while $word =~ s/($_V*$_C+$_V+)($_C$_V)/$1=$2/gi;
        1 while $word =~ s/($_V*$_C+$_V+$_C)($_C)/$1=$2/gi;
        $word =~ s/^($_V+$_C)($_C)/$1=$2/gi;
        $word =~ s/^($_V+)($_C$_V)/$1=$2/gi;
        $word =~ s/^=//;
        $word =~ s/=$//;
        $word =~ s/=+/=/g;
#DEBUG  print "$word\n";
        push(@result, split(/=/, $word));
    }
    return @result;
}

1;

__END__

=head1 NAME

Lingua::IT::Hyphenate - Italian word hyphenation

=head1 SYNOPSIS

    use Lingua::IT::Hyphenate qw( sillabe );
    
    @syllabes = sillabe( @whatever );

=head1 DESCRIPTION

The C<sillabe> (italian for "syllabes") function,
which can be exported to your main namespace,
gets one or more text strings and returns an array
of syllabes. Note that it destroys everything which
is not considered part of a word (punctuation et alia);
it leaves untouched numbers and the ' (single quote).

    print join("-", sillabe("salve, mondo!"));
    
    # returns: sal-ve-mon-do

The hyphenation algorithm doesn't take
into account sequences of vowels for which there
are no predictable rules (eg. it doesn't distinguish
between italian "iato" and "dittongo"), so "aiuto"
is hyphenated as "aiu-to" (instead of the correct
"a-iu-to").

It's not complete, but at least it doesn't produce wrong results.

=head1 AUTHOR

Aldo Calpini ( C<dada@perl.it> ).

=cut
