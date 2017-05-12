#! perl -w

use Encode::Arabic::Buckwalter ':xml';
use Encode::Arabic;

our $VERSION = $Encode::Arabic::VERSION;

use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

$options = { 'p' => '', 's' => '' };

getopts('p:s:v', $options);

die $Encode::Arabic::VERSION . "\n" if exists $options->{'v'};

$e = shift @ARGV;

while (<>) {

    print encode "utf8", decode $e, $options->{'p'} . $_ . $options->{'s'};
}


__END__


=head1 NAME

decode - Filter script mimicking the decode function


=head1 SYNOPSIS

Examples of command-line invocation:

    $ decode ArabTeX < decode.d | encode Buckwalter > encode.d
    $ decode MacArabic < data.MacArabic > data.UTF8
    $ encode WinArabic < data.UTF8 > data.WinArabic

The core of the implementation:

    getopts('p:s:v', $options);

    $e = shift @ARGV;

    while (<>) {

        print encode "utf8", decode $e, $options->{'p'} . $_ . $options->{'s'};
    }


=head1 DESCRIPTION

The L<Encode|Encode> library provides a unified interface for converting strings
from different encodings into a common representation, and vice versa.

The L<encode|encode> and L<decode|decode> programs mimick the fuction calls to
the C<encode> and C<decode> methods, respectively.

For the list of supported encoding schemes, please refer to L<Encode|Encode> and
the source files of the programs. The naming of encodings is case-insensitive.


=head1 OPTIONS

  decode [OPTIONS] encoding
    -v       --version      show program's version
             --help         show usage information
    -p text  --prefix=text  prefix input with text
    -s text  --suffix=text  suffix input with text


=head1 SEE ALSO

Encode Arabic Online Interface  L<http://encode-arabic.sourceforge.net/>

Encode Arabic Project           L<http://sourceforge.net/projects/encode-arabic/>

ElixirFM Project                L<http://sourceforge.net/projects/elixir-fm/>

L<Encode|Encode>,
L<Encode::Encoding|Encode::Encoding>,
L<Encode::Arabic|Encode::Arabic>


=head1 AUTHOR

Otakar Smrz C<< <otakar-smrz users.sf.net> >>, L<http://otakar-smrz.users.sf.net/>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2012 Otakar Smrz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
