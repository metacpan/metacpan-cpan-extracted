package Getopt::Pad::Config::Format;

use v5.26;
use strict;
use warnings;
use experimental 'signatures';

use Object::Pad;
use Getopt::Pad::Registry;

our $VERSION = '0.04';

my @builtins = map { "Getopt::Pad::Config::Format::$_" } qw(Yaml Json);
my $registry;

sub registry() {
	return $registry //= Getopt::Pad::Registry->new(kind => 'config format')->register(@builtins);
}

sub registerFormat($class) {
	return registry()->register($class);
}

class Getopt::Pad::Config::Format :abstract {
	method parse;
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Config::Format - Base class of config file formats, and how
to add one

=head1 SYNOPSIS

=for highlighter language=perl

    use v5.26;
    use Object::Pad;
    use Getopt::Pad;
    use Getopt::Pad::Config::Format;

    class My::Format::Toml :isa(Getopt::Pad::Config::Format) {
        use TOML::Tiny ();

        use constant NAMES => ['toml'];

        method parse($text) {
            return TOML::Tiny::from_toml($text);
        }

        # Optional: enables --create-default-config for this format.
        method dump($data) {
            return TOML::Tiny::to_toml($data) . "\n";
        }
    }

    Getopt::Pad::Config::Format::registerFormat('My::Format::Toml');

    my $opt = GetOptions(
        options => {
            'log-level' => { type => 'string', default => 'info' },
        },
        config => { format => 'toml', paths => ['~/.tool.toml'] },
    );

=head1 DESCRIPTION

A format translates one config file syntax, such as YAML or JSON, between
text and Perl data. Getopt::Pad comes with the formats C<yaml> (also
C<yml>, see L<Getopt::Pad::Config::Format::Yaml>) and C<json> (see
L<Getopt::Pad::Config::Format::Json>). Every format is a subclass of
Getopt::Pad::Config::Format, including the ones you write yourself.

A format only translates. Getopt::Pad finds, reads and writes the files
itself, always as UTF-8, and checks the data a format returns. How config
files are used is described in L<Getopt::Pad/CONFIG FILES>.

To add a format:

=over 4

=item 1.

Write an L<Object::Pad> class that inherits from
Getopt::Pad::Config::Format.

=item 2.

Give it a C<NAMES> constant and a C<parse> method, and optionally a
C<dump> method (see L</THE FORMAT CONTRACT>).

=item 3.

Register it with L</registerFormat> before the first C<GetOptions> call
whose C<config> block uses one of its names.

=back

=head1 THE FORMAT CONTRACT

=head2 NAMES

=for highlighter language=perl

    use constant NAMES => ['toml'];

Required. A constant that returns an arrayref of the names the format
answers to in the C<format> key of the C<config> block. Names are matched
case-insensitively. A name that another class has already registered,
built-in or not, cannot be taken over: L</registerFormat> dies.

=head2 parse

=for highlighter language=perl

    method parse($text) { return TOML::Tiny::from_toml($text) }

Required. Receives the complete content of one config file as a Perl
character string (already decoded from UTF-8) and returns the data as a
hashref. The format does not open files and does not deal with encodings.

The hashref has the layout described in L<Getopt::Pad/File layout>:

=for highlighter language=perl

    {
        Options  => { 'log-level' => 'debug' },          # group => { option => value }
        Target   => { owner => 'dave' },
        commands => {                                   # command sections
            document => { Options => { notes => '/srv/docs/notes.txt' } },
        },
    }

Values are plain scalars, arrayrefs (for C<multiple> and C<objectlist>
options) and hashrefs (for C<hash> and C<objectlist> options). Getopt::Pad
checks the structure and every value, so C<parse> does not need to.
Booleans may be returned as C<1> and C<0> or as boolean objects such as
L<JSON::PP::Boolean>; an undefined value is reported to the user as
C<no value given>.

When the text cannot be parsed, C<parse> dies. Getopt::Pad reports the
message to the user as a config error that names the file, for example
C<ERROR: config file '~/.tool.toml': toml parse error at line 3:
...>. A trailing C<at FILE line N.> is removed from the message. If the
text parses to something other than a hashref, for example an empty
document, that is reported as C<config file 'PATH' must contain a mapping
of group names>.

=head2 dump

=for highlighter language=perl

    method dump($data) { return TOML::Tiny::to_toml($data) . "\n" }

Optional. Receives a hashref in the same layout as C<parse> returns and
returns it serialized as a Perl character string; Getopt::Pad encodes it
as UTF-8 and writes the file. C<--create-default-config> uses it. Without
C<dump>, C<--create-default-config> fails with the user error
C<config format 'NAME' cannot write config files>.

When C<dump> dies, no file is created, and the exception propagates out
of C<GetOptions> unchanged.

=head1 FUNCTIONS

=head2 registerFormat

=for highlighter language=perl

    Getopt::Pad::Config::Format::registerFormat('My::Format::Toml');

Registers a format class under the names in its L</NAMES> constant, for
all specs in the program. The argument is the class name. If the class has
no C<NAMES> method yet, which usually means that its module is not
loaded, its module file is loaded first (for example
F<My/Format/Toml.pm> from C<@INC>).

It dies when a name is already registered by another class, with
C<Getopt::Pad: config format name 'NAME' is already registered by
CLASS>, and when the class has no C<NAMES> constant. Registering the same
class again does nothing. The function is not exported; call it with its
full name.

=head1 EXAMPLES

The distribution's F<examples/05-custom-format.pl> is a runnable version
of the TOML format from the L</SYNOPSIS>. Unlike the synopsis, which loads
L<TOML::Tiny> with C<use>, it loads the module only when a TOML file is
actually read or written, so the program also runs without TOML::Tiny as
long as no TOML file is used:

=for highlighter language=perl

    method parse($text) {
        try { require TOML::Tiny }
        catch ($error) { croak "config format 'toml' requires the TOML::Tiny module" }

        return TOML::Tiny::from_toml($text);
    }

The built-in formats are short and can serve as examples as well:
L<Getopt::Pad::Config::Format::Json> and
L<Getopt::Pad::Config::Format::Yaml>.

=head1 SEE ALSO

L<Getopt::Pad/CONFIG FILES>, L<Getopt::Pad::Type> (the other extension
point), L<Object::Pad>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
