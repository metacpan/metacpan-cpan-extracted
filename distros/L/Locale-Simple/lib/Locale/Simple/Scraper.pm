use strict;
use warnings;

package Locale::Simple::Scraper;
our $VERSION = '0.200';
# ABSTRACT: scraper to find translation tokens in a directory

use Exporter 'import';
use Getopt::Long;
use File::Find;
use Cwd;
use Locale::Simple;
use Data::Dumper;
use Locale::Simple::Scraper::Parser;

our @EXPORT = qw(scrape);

my %OUTPUT_FORMATS = map { $_ => 1 } qw( po perl json yaml );

my $USAGE = <<'END';
Usage: locale-simple scrape [OPTIONS]

Walks the current directory and writes a .pot template to STDOUT; progress and
parse problems go to STDERR.

Options:
  --js EXT --pl EXT --py EXT --php EXT --go EXT --rs EXT --tx EXT
                     extra file extensions for a language, comma-separated,
                     repeatable (defaults: js; pl pm t; py; php; go; rs; tx)
  --ignore REGEX     skip files whose path matches, repeatable
  --only REGEX       read only files whose path matches, repeatable
  --output FORMAT    po (default), perl, json or yaml (yaml needs the YAML module)
  --md5              write MD5 hashes of the file names
  --no_line_numbers  leave out the #: location comments
  -h, --help         show this text
END

sub usage { return $USAGE }

sub _bad_call {
    my ($message) = @_;
    $message .= "\n" unless $message =~ /\n\z/;
    die bless { message => $message }, 'Locale::Simple::Scraper::BadCall';
}

sub scrape {
    @ARGV = @_;

    $| = 1;

    # Supported filetypes and the extensions read as them. --js, --pl, ...
    # add more: repeatable, each a comma-separated list.
    my %defaults = (
        js  => ['js'],                 # Javascript
        pl  => [ 'pl', 'pm', 't' ],    # Perl
        tx  => ['tx'],                 # Text::Xslate (Kolon or Metakolon)
        py  => ['py'],                 # Python
        php => ['php'],                # PHP
        go  => ['go'],                 # Go
        rs  => ['rs'],                 # Rust
    );
    my @types = qw( js pl tx py php go rs );
    my %extra = map { $_ => [] } @types;

    my @ignores;
    my @only;

    my $output = 'po';
    my ($md5, $no_line_numbers, $help);

    my @problems;
    my $parsed = do {
        local $SIG{__WARN__} = sub { push @problems, @_ };
        GetOptions(
            ( map { ( "$_=s" => $extra{$_} ) } @types ),
            "ignore=s"        => \@ignores,
            "only=s"          => \@only,
            "output=s"        => \$output,
            "md5"             => \$md5,
            "no_line_numbers" => \$no_line_numbers,
            "help|h"          => \$help,
        );
    };
    _bad_call( join '', @problems ) unless $parsed;
    if ($help) {
        print STDOUT $USAGE;
        return;
    }
    _bad_call("Unexpected argument: $ARGV[0]") if @ARGV;
    _bad_call("Unknown output format: $output (use po, perl, json or yaml)")
      unless $OUTPUT_FORMATS{$output};

    # extension list
    my %e;
    for my $type ( @types ) {
        $e{$_} = $type for ( map { split /,/ } @{ $extra{$type} } ), @{ $defaults{$type} };
    }

    # functions with count of locale simple with function of parameter
    #
    # 1 = msgid
    # 2 = msgid_plural
    # 3 = msgctxt
    # 4 = domain
    #
    my %f = (
        l     => [1],
        ln    => [ 1, 2 ],
        ld    => [ 4, 1 ],
        lp    => [ 3, 1 ],
        lnp   => [ 3, 1, 2 ],
        ldn   => [ 4, 1, 2 ],
        ldp   => [ 4, 3, 1 ],
        ldnp  => [ 4, 3, 1, 2 ],

        # Deferred-translation markers (see DEFERRED TRANSLATION in
        # Locale::Simple). Same mapping as their l* twins — identical
        # .pot output.
        N_    => [1],
        Nn_   => [ 1, 2 ],
        Nd_   => [ 4, 1 ],
        Np_   => [ 3, 1 ],
        Nnp_  => [ 3, 1, 2 ],
        Ndn_  => [ 4, 1, 2 ],
        Ndp_  => [ 4, 3, 1 ],
        Ndnp_ => [ 4, 3, 1, 2 ],
    );

    my %files;

    my $dir = getcwd;

    finddepth(
        sub {
            my $filename = $File::Find::name;
            $filename =~ s/^\Q$dir\E\///;
            my $stored_filename = $filename;
            if ( $md5 ) {
                eval {
                    require Digest::MD5;
                    Digest::MD5->import( 'md5_hex' );
                };
                die "This feature requires Digest::MD5" if $@;
                $stored_filename = md5_hex( $filename );
            }
            for ( @ignores ) {
                return if $filename =~ /$_/;
            }
            if ( @only ) {
                my $found = 0;
                for ( @only ) {
                    $found = 1 if $filename =~ /$_/;
                }
                return unless $found;
            }
            my @fileparts = split( '\.', $File::Find::name );
            my $ext = pop @fileparts;
            $files{$File::Find::name} = [ $ext, $filename, $stored_filename ] if grep { $ext eq $_ } keys %e;
        },
        $dir
    );

    my @found;
    for my $file ( sort keys %files ) {
        my ( $ext, $filename, $stored_filename ) = @{ $files{$file} };
        my $type = $e{$ext};
        print STDERR $type . " => " . $file . "\n";
        next if -l $file and not -e $file;
        my $parses = Locale::Simple::Scraper::Parser->new( type => $type )->from_file( $file );
        my @file_things = map {
            {
                %{ result_from_params( $_->{args}, $f{ $_->{func} } ) },
                  line => $_->{line},
                  file => $stored_filename,
                  type => $type,
            }
        } @{$parses};
        push @found, @file_things;
    }

    if ( $output eq 'po' ) {
        my %files;
        my %token;
        for ( @found ) {
            my $key .= defined $_->{domain}       ? '"' . $_->{domain} . '"'       : 'undef';
            $key    .= defined $_->{msgctxt}      ? '"' . $_->{msgctxt} . '"'      : 'undef';
            $key    .= defined $_->{msgid}        ? '"' . $_->{msgid} . '"'        : 'undef';
            $key    .= defined $_->{msgid_plural} ? '"' . $_->{msgid_plural} . '"' : 'undef';
            $token{$key} = $_ unless defined $token{$key};
            $files{$key} = [] unless defined $files{$key};
            push @{ $files{$key} }, $_->{file} . ':' . $_->{line};
        }
        for my $k ( sort { $a cmp $b } keys %files ) {
            print "\n";
            print "#: " . join( ' ', @{ $files{$k} } ) . "\n" if !$no_line_numbers;
            print "#, locale-simple-format";
            print " " . $token{$k}{domain} if defined $token{$k}{domain};
            print "\n";
            for ( qw( msgctxt msgid msgid_plural ) ) {
                print $_. ' "' . Locale::Simple::gettext_escape( $token{$k}{$_} ) . '"' . "\n"
                  if defined $token{$k}{$_};
            }
            my $plural_marker = $token{$k}{msgid_plural} ? "[0]" : "";
            print qq[msgstr$plural_marker ""\n];

        }
    }
    elsif ( $output eq 'perl' ) {
        local $Data::Dumper::Sortkeys = 1;
        print Dumper \@found;
    }
    elsif ( $output eq 'json' ) {
        require JSON::PP;
        print JSON::PP->new->canonical->encode( \@found );
    }
    elsif ( $output eq 'yaml' ) {
        eval { require YAML; 1 } or die "--output yaml needs the YAML module\n";
        print YAML::Dump( \@found );
    }
}

sub parse_line {
    my ( $line, $type, $f, @results ) = @_;
    return if $line =~ /^\s*\#.*/;
    for ( keys %{$f} ) {
        my @args = @{ $f->{$_} };
        my $params = get_func_params( $_, $line );
        next if !$params;
        my $argc = scalar @args;
        my ( $remainder, @params ) = parse_params( $params, $type, $argc );
        if ( scalar @params == $argc ) {
            push @results, result_from_params( \@params, \@args ), parse_line( $remainder, $type, $f );
        }
    }
    return @results;
}

sub result_from_params {
    my ( $params, $args ) = @_;
    my %result;
    my $pos = 0;
    for ( @{$args} ) {
        $result{msgid}        = $params->[$pos] if $_ eq 1;
        $result{msgid_plural} = $params->[$pos] if $_ eq 2;
        $result{msgctxt}      = $params->[$pos] if $_ eq 3;
        $result{domain}       = $params->[$pos] if $_ eq 4;
        $pos++;
    }
    return \%result;
}

sub get_func_params {
    my ( $func, $line ) = @_;
    $line =~ /([^\w]|^)$func\((.*)/;
    return $2;
}


sub parse_params {
    my ( $params, $type, $argc ) = @_;
    my @chars = split( '', $params );
    my @args;
    my $arg         = "";
    my $q_state     = 0;    # 0 = code, 1 = qoute, 2 = double qoute
    my $comma_state = 1;
    while ( defined( my $c = shift @chars ) ) {
        next if $c =~ /\s/ and !$q_state;
        if ( $q_state ) {
            if ( $c eq '\\' ) {
                my $esc = shift @chars;
                if ( $esc eq "'" or $esc eq '"' or $esc eq '\\' ) {
                    $arg .= $esc;
                }
                else {
                    warn "Unknown escape char '" . $esc . "'";
                }
            }
            elsif ( ( $c eq "'" and $q_state == 1 ) or ( $c eq '"' and $q_state == 2 ) ) {
                $q_state     = 0;
                $comma_state = 0;
                push @args, $arg;
                $arg = "";
                last if scalar @args == $argc;
            }
            else {
                $arg .= $c;
            }
        }
        else {
            if ( $c eq "'" or $c eq '"' ) {
                die "quote found where comma expected: " . $params unless $comma_state;
                $q_state = $c eq "'" ? 1 : 2;
            }
            elsif ( $c eq ',' ) {
                die "comma found after comma in code: " . $params if $comma_state;
                $comma_state = 1;
            }
            elsif ( $type eq 'js' ) {
                last;
            }
            else {
                last;
            }
        }
    }
    return join( '', @chars ), @args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Simple::Scraper - scraper to find translation tokens in a directory

=head1 VERSION

version 0.200

=head1 SYNOPSIS

  use Locale::Simple::Scraper 'scrape';

  # Parse @ARGV-style options; emits a .pot template to STDOUT.
  scrape(
      '--ignore', 'node_modules',
      '--ignore', 'build',
      '--output', 'po',
  );

=head1 DESCRIPTION

C<Locale::Simple::Scraper> walks the current working directory, parses
recognised source files with L<Parser::MGC>, extracts every
C<l()>/C<ln()>/C<lp()>/C<lnp()>/C<ld()>/C<ldn()>/C<ldp()>/C<ldnp()> call
it can resolve statically, and writes a C<.pot> (gettext template) or one
of a few alternative output formats.

Usually invoked through C<locale-simple scrape>; the C<scrape>
function is exported so build tools can drive it directly.

=head1 EXPORTED FUNCTIONS

=head2 scrape(@argv)

Run the scraper. C<@argv> is parsed with L<Getopt::Long>. Reads files
from the current working directory recursively and prints to STDOUT.
C<--help> prints the options and returns. A bad call (unknown option,
unexpected argument, unknown C<--output> format) dies with a
C<Locale::Simple::Scraper::BadCall> object whose C<message> field holds the
reason, before anything is written.

=head2 usage()

Returns the text of the options, as C<locale-simple scrape --help> prints it.

=head1 OPTIONS

=over 4

=item C<--js=EXT>, C<--pl=EXT>, C<--py=EXT>, C<--php=EXT>, C<--go=EXT>, C<--rs=EXT>, C<--tx=EXT>

Comma-separated list of extra file extensions to recognise as the given
language. Repeatable; the lists add up. The built-in defaults (C<.js>;
C<.pl>/C<.pm>/C<.t>; C<.py>; C<.tx>; C<.php>; C<.go>; C<.rs>) are always
included.

=item C<--ignore=REGEX>

Skip any file whose path matches this regex. Repeatable.

=item C<--only=REGEX>

Process only files whose path matches one of the given regexes.
Repeatable; combines with C<--ignore>.

=item C<--output=FORMAT>

Output format — C<po> (default), C<perl> (L<Data::Dumper>, keys sorted),
C<json> (through L<JSON::PP>, keys sorted) or C<yaml> (needs the optional
L<YAML> module).

=item C<--md5>

Hash filenames with MD5 before writing them — useful when paths may
contain sensitive information. Requires L<Digest::MD5>.

=item C<--no_line_numbers>

Omit C<#:> source-location comments from the C<.pot>.

=back

=head1 SUPPORTED CALLS

Recognised call shapes (identical across Perl, Python and JavaScript):

  l( msgid, ... )
  ln( msgid, msgid_plural, n, ... )
  lp( msgctxt, msgid, ... )
  lnp( msgctxt, msgid, msgid_plural, n, ... )
  ld( domain, msgid, ... )
  ldn( domain, msgid, msgid_plural, n, ... )
  ldp( domain, msgctxt, msgid, ... )
  ldnp( domain, msgctxt, msgid, msgid_plural, n, ... )

Strings must be statically resolvable — literal strings and static
concatenation (C<"a" . "b"> in Perl/PHP, C<"a" + "b"> in JS/Python,
C<"a" ~ "b"> in Xslate Kolon). PHP also reads heredoc and nowdoc literals;
calls qualified with the PHP namespace are found as well.

Escapes are read the way the language reads them, so the msgid is the text
the program sees: C<"Line\n"> gives a msgid ending in a newline, which the
C<.pot> writes as C<\n>. Single quotes in Perl, Xslate and PHP know only
C<\\> and C<\'>. A character named by its code point is stored as UTF-8. A
literal with an escape the language rejects is skipped, and so is a Perl
literal with a case change such as C<\U>.

A literal that interpolates is not constant either. In Perl double quotes
every C<$> is a variable (C<$name>, C<$1>, C<$::name>, C<${...}>, C<$%> as in
C<"$%.2f">, C<$ total> after a space; a final C<$> does not compile), and so
is an C<@> before a name, C<::>, C<'>, C<$>, C<+>, C<->, a digit or C<{>.
PHP double quotes and heredocs interpolate C<$name>, C<{$...}> and
C<${...}>. An escaped C<\$> or C<\@> is text. Python reads plain, raw (C<r"...">) and C<u"..."> strings in single or
triple quotes, raw ones keeping their backslashes, and joins adjacent
literals (C<"a" "b">); f-strings and bytes are not msgids. A JavaScript
template literal is a msgid while it holds no C<${...}>. A call with a
string that is not constant is skipped and reported on STDERR; the calls in
its arguments are still extracted.

That holds for the msgid, the plural msgid, the context and the domain. The
count and the arguments after them can be any code, such as C<$name>,
C<< $obj->count >>, C<count($items)>, C<items.len()> or C<n as i64>. Such an
argument ends at the comma or closing bracket outside any string literal or
bracket pair, and the translation calls inside it are extracted as well.

Go exports its helpers capitalised: C<L>, C<Ln>, C<Lp>, C<Lnp>, C<Ld>, C<Ldn>,
C<Ldp>, C<Ldnp> (the deferred markers keep their names). They are found with any
package prefix or bare after a dot import; strings are C<"..."> and backtick
raw strings, never C<'...'> (a rune in Go). The argument shapes are those
above.

Rust calls are macros: the names carry a bang and the deferred markers are
lower case (C<n_!>, C<nn_!>, C<np_!>, C<nnp_!>, C<nd_!>, C<ndn_!>, C<ndp_!>,
C<ndnp_!>), a path before the macro is fine. Only the round brackets are read
as the argument list, not C<{}> or C<[]>. Strings are C<"..."> and raw strings
with any number of hashes; there is no concatenation operator and no
C<'...'> (chars and lifetimes). Comments are not skipped, as in every other
language, so a commented-out call is extracted. Runtime interpolation is not extracted;
keep msgids constant and pass dynamic data as sprintf arguments.

=head1 SEE ALSO

L<Locale::Simple>, L<Locale::Simple::Scraper::Parser>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/locale-simple/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software, licensed under:

  The MIT (X11) License

=cut
