package Locale::Maketext::Lexicon::CSV;
{
  $Locale::Maketext::Lexicon::CSV::VERSION = '0.96';
}

use strict;
use Text::CSV_XS;

# ABSTRACT: Use CSV files as lexicons for Maketext


sub parse {
    my @lines = @_;
    my $csv = Text::CSV_XS->new({
        binary => 1,
    });
    my %out;

    foreach my $line (@lines)
    {
        $csv->parse($line);
        my @fields = $csv->fields;
        $out{$fields[0]} = $fields[1];
    }

    return \%out;
}

1;

__END__

=pod

=head1 NAME

Locale::Maketext::Lexicon::CSV - Use CSV files as lexicons for Maketext

=head1 VERSION

version 0.96

=head1 SYNOPSIS

    package Hello::I18N;
    use base 'Locale::Maketext';
    use Locale::Maketext::Lexicon {
        en => [ CSV => 'en.csv' ],
    };

=head1 DESCRIPTION

This module lets you use simple CSV files as lexicons for L<Locale::Maketext::Lexicon>.

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>

=head1 AUTHORS

David Arnold E<lt>david.arnold@online-rewards.comE<gt>

=head1 COPYRIGHT

Copyright 2014 by David Arnold E<lt>david.arnold@online-rewards.comE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=head1 AUTHORS

=over 4

=item *

David Arnold <david.arnold@online-rewards.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Arnold.

This is free software, licensed under:

  The MIT (X11) License

=cut
