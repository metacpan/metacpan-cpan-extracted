=head1 NAME

Devel::PerlySense::Editor::Vim - Integration with Vim

=head1 DESCRIPTION


=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Editor::Vim;
$Devel::PerlySense::Editor::Vim::VERSION = '0.0219';
use base "Devel::PerlySense::Editor";





use Spiffy -Base;
use Data::Dumper;
use File::Basename;
use Graph::Easy;
use Text::Table;
use List::Util qw/ max first /;
use POSIX qw/ ceil /;
use Path::Class;

use Devel::PerlySense;
use Devel::PerlySense::Class;
use Devel::PerlySense::Util;
use Devel::PerlySense::Util::Log;
use Devel::PerlySense::Document::Api::Method;





=head1 PROPERTIES

=head1 CLASS METHODS

=head1 METHODS

=head2 formatOutputDataStructure(rhData)

Return stringification of $rhData suited for the Editor.

=cut
sub formatOutputDataStructure {
    my ($rhData) = Devel::PerlySense::Util::aNamedArg(["rhData"], @_);
    my $keysValues = $self->formatOutputItem($rhData);
    return $keysValues;
}





=head2 formatOutputItem($item)

Return stringification of $item suited for the Editor. $item can be a
scalar, array ref or hash ref.

=cut
sub formatOutputItem {
    my ($value) =  @_;

    my $output = "";
    if(ref($value) eq "ARRAY") {
        $output = "[" . join(", ", map { $self->formatOutputItem($_) } @$value) . "]"
    }
    elsif(ref($value) eq "HASH") {
        $output = "{" . join(", ", map {
            my $key = $_;
            my $item_value = $value->{$_};
            $item_value = $self->formatOutputItem($item_value);

            $key = $self->renameIdentifier($key);
            $key = $self->escapeValue($key);

            qq|"$key": $item_value|;

        } sort keys %$value) . "}";
    }
    else {
        $output = $self->escapeValue($value);
        $output = qq|"$output"|;
    }

    return $output;
}





sub escapeValue {
    my ($value) = (@_);

    $value =~ s| ([\\"]) |\\$1|gsmx;
    $value =~ s| \n |\\n|gsmx;

    return $value;
}





1;





__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
