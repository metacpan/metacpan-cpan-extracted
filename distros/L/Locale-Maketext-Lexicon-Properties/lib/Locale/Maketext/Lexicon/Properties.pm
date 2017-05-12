package Locale::Maketext::Lexicon::Properties;
use 5.008005;
use strict;
use warnings;
use utf8;
use Encode ();
use Locale::Maketext::Lexicon;

our $VERSION = "0.03";

sub parse {
    my $self = shift;

    my @out;
    for (@_) {
        if (Locale::Maketext::Lexicon::option('decode')) {
            $_ = Encode::decode_utf8($_);
        }

        # e.g.
        #   foo=bar\r\n
        #   ~~~ ~~~
        #   $1  $2
        if (/\A[ \t]*([^=]+?)[ \t]*=[ \t]*(.+?)[\015\012]*\z/) {
            my ($key, $value) = ($1,$2);
            $value =~ s!\\n!\n!g;
            push @out, $key, $value;
        }
    }
    return +{ @out };
}

1;
__END__

=encoding utf-8

=head1 NAME

Locale::Maketext::Lexicon::Properties - Properties file parser for Maketext

=head1 SYNOPSIS

Called via L<Locale::Maketext::Lexicon>:

    package Hello::I18N;
    use parent 'Locale::Maketext';
    use Locale::Maketext::Lexicon {
        en => [ Properties => "en_US/hello.properties" ],
    };

    package main;
    my $lh = Hello::I18N->get_handle('en');
    print $lh->maketext('foo');

Directly calling C<Locale::Maketext::Lexicon::Properties::parse()>:

    use Locale::Maketext::Lexicon::Properties;
    my %lexicon = %{ Locale::Maketext::Lexicon::Properties->parse(<DATA>) };
    __DATA__
    foo=bar
    baz=qux

=head1 DESCRIPTION

This module parses the properties file (from Java) for L<Locale::Maketext> by using L<Locale::Maketext::Lexicon>. And it can also return a Lexicon hash.

You are able to look up the property value by specifying key to C<maketext()> or Lexcon hash.

=head1 NOTES

Properties file can use colon (:) as delimiter as an alternative to equal (=), however this module cannot.
And properties file allows multi-line property, but this module cannot handle it.

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

moznion E<lt>moznion@gmail.comE<gt>

=cut

