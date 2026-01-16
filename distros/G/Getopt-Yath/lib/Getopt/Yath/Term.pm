package Getopt::Yath::Term;
use strict;
use warnings;

our $VERSION = '2.000007';

our @EXPORT = qw/color USE_COLOR term_size fit_to_width/;
use Importer Importer => 'import';

use Term::Table::Util qw/term_size/;

BEGIN {
    if (eval { require Term::ANSIColor; 1 }) {
        *USE_COLOR = sub() { 1 };
        *color = \&Term::ANSIColor::color;
    }
    else {
        *USE_COLOR = sub() { 0 };
        *color = sub { '' };
    }
}

sub fit_to_width {
    my ($join, $text, %params) = @_;

    my $prefix = $params{prefix};
    my $width  = $params{width};
    unless (defined $width) {
        $width = term_size() - 20;
        $width = 80 unless $width && $width >= 80;
    }

    my @parts = ref($text) ? @$text : split /\s+/, $text;

    my @out;

    my $line = "";
    for my $part (@parts) {
        my $new = $line ? "$line$join$part" : $part;

        if ($line && length($new) > $width) {
            push @out => $line;
            $line = $part;
        }
        else {
            $line = $new;
        }
    }
    push @out => $line if $line;

    if(defined $prefix) {
        $_ =~ s/^/  /gm for @out;
    }

    return join "\n" => @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Term - Terminal utility methods

=head1 DESCRIPTION

Functions for manipulating text intended for the terminal.

=head1 SYNOPSIS

    use Getopt::Yath::Term qw{
        USE_COLOR
        color
        fit_to_width
        term_size
    };

=head1 EXPORTS

=over 4

=item $bool = USE_COLOR()

True if color can/should be used.

=item $ansi_escape = color($color_name)

Get the ANSI escape sequence for the specified color, or return an emptt string
if color cannot be used.

=item $new_text = fit_to_width($old_text)

Wrap text to fit nicely in the terminal.

=item $cols = term_size()

Get the width of the terminal in columns.

=back

=head1 SOURCE

The source code repository for Getopt-Yath can be found at
L<http://github.com/Test-More/Getopt-Yath/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
