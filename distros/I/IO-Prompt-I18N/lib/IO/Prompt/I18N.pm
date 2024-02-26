package IO::Prompt::I18N;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-20'; # DATE
our $DIST = 'IO-Prompt-I18N'; # DIST
our $VERSION = '0.81'; # VERSION

our @EXPORT_OK = qw(prompt confirm);

sub prompt {
    my ($text, $opts) = @_;

    $text //= "Enter value";
    $opts //= {};

    my $answer;

    my $default;
    $default = ${$opts->{var}} if $opts->{var};
    $default = $opts->{default} if defined($opts->{default});

    while (1) {
        # prompt
        print $text;
        print " ($default)" if defined($default) && $opts->{show_default}//1;
        print ":" unless $text =~ /[:?]\s*$/;
        print " ";

        # get input
        $answer = <STDIN>;
        if (!defined($answer)) {
            print "\n";
            $answer = "";
        }
        chomp($answer);

        # check+process answer
        if (defined($default)) {
            $answer = $default if !length($answer);
        }
        my $success = 1;
        if ($opts->{required}) {
            $success = 0 if !length($answer);
        }
        if ($opts->{regex}) {
            $success = 0 if $answer !~ /$opts->{regex}/;
        }
        last if $success;
    }
    ${$opts->{var}} = $answer if $opts->{var};
    $answer;
}

sub confirm {
    my ($text, $opts) = @_;

    $opts //= {};

    state $supported_langs = {
        en => {yes_words=>[qw/y yes/], no_words=>[qw/n no/]   , text=>'Confirm'},
        fr => {yes_words=>[qw/o oui/], no_words=>[qw/n non/]  , text=>'Confirmer'},
        id => {yes_words=>[qw/y ya/] , no_words=>[qw/t tidak/], text=>'Konfirmasi'},
    };

    $opts->{lang} //= do {
        if ($ENV{LANG} && $ENV{LANG} =~ /^([a-z]{2})/ &&
                $supported_langs->{$1}) {
            $1;
        } elsif ($ENV{LANGUAGE} && $ENV{LANGUAGE} =~ /^([a-z]{2})/ &&
                $supported_langs->{$1}) {
            $1;
        } else {
            'en';
        }
    };

    my $lang = $supported_langs->{$opts->{lang}}
        or die "Unknown language '$opts->{lang}'";
    $text //= $lang->{text};
    $opts->{yes_words} //= $lang->{yes_words};
    $opts->{no_words}  //= $lang->{no_words};

    my $default;
    if (defined $opts->{default}) {
        if ($opts->{default}) {
            $default = $opts->{yes_words}[0];
        } else {
            $default = $opts->{no_words}[0];
        }
    }

    my $suffix;
    my $show_default = 1;
    unless ($text =~ /[?]/) {
        $text .=
            join("",
                 " (",
                 join("/",
                      (map {$opts->{default} ? uc($_) : lc($_)}
                           @{ $opts->{yes_words} }),
                      (map {defined($opts->{default}) && !$opts->{default} ?
                                        uc($_) : lc($_)}
                           @{ $opts->{no_words} }),
                  ),
                 ")?",
             );
        $show_default = 0; # because we already indicate which using uppercase
    }

    my $re = join("|", map {quotemeta}
                      (@{$opts->{yes_words}}, @{$opts->{no_words}}));
    $re = qr/\A($re)\z/i;

    my $answer = prompt($text, {
        required     => 1,
        regex        => $re,
        show_default => $show_default,
        default      => $default,
    });
    (grep {$_ eq $answer} @{$opts->{yes_words}}) ? 1:0;
}

1;
# ABSTRACT: Prompt user question, with some options (including I18N)

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Prompt::I18N - Prompt user question, with some options (including I18N)

=head1 VERSION

This document describes version 0.81 of IO::Prompt::I18N (from Perl distribution IO-Prompt-I18N), released on 2023-11-20.

=head1 SYNOPSIS

 use IO::Prompt::I18N qw(prompt confirm);
 use Text::LocaleDomain 'My-App';

 my $file = prompt(__"Enter filename");

 if (confirm(__"Really delete filename", {lang=>"id", default=>0})) {
     unlink $file;
 }

=head1 DESCRIPTION

This module provides the C<prompt> function to ask for a value from STDIN. It
features prompt text, default value, validation (using regex),
optional/required. It also provides C<confirm> wrapper to ask yes/no, with
localizable text.

=head1 FUNCTIONS

=head2 prompt([ $text[, \%opts] ]) => val

Display C<$text> and ask value from STDIN. Will re-ask if value is not valid.
Return the chomp-ed value.

Options:

=over

=item * var => \$var

=item * required => bool

If set to true then will require that value is not empty (zero-length).

=item * default => VALUE

Set default value.

=item * show_default => bool (default: 1)

Whether to show default value if defined.

=item * regex => REGEX

Validate using regex.

=back

=head2 confirm([ $text, [\%opts] ]) => bool

Display C<$text> (defaults to C<Confirm> in English) and ask for yes or no. Will
return bool. Basically a convenient wrapper around C<prompt>.

Options:

=over

=item * lang => str

Support several languages (C<id>, C<en>, C<fr>). Default to using LANG/LANGUAGE
or English. Will preset C<yes_words> and C<no_words> and adds the choice of
words to C<$text>. Will die if language is not supported. Here are the supported
languages:

  lang  yes_words     no_regex   default text
  ----  ---------     --------   ------------
  en    y, yes        n, no      Confirm
  fr    o, oui        n, non     Confirmer
  id    y, ya         t, tidak   Konfirmasi

=item * yes_words => array

Overrides preset from C<lang>.

=item * no_words => array

Overrides preset from C<lang>.

=item * default => bool

Set default value.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/IO-Prompt-I18N>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-IO-Prompt-I18N>.

=head1 SEE ALSO

L<IO::Prompt>, L<IO::Prompt::Tiny>, L<Term::Prompt>, L<Prompt::Timeout>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=IO-Prompt-I18N>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
