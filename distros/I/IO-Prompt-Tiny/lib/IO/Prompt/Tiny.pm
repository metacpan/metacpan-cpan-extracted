use 5.006;
use strict;
use warnings;

package IO::Prompt::Tiny;
# ABSTRACT: Prompt for user input with a default option

our $VERSION = '0.003';

use Exporter ();
use Carp     ();
our @ISA       = qw/Exporter/;
our @EXPORT_OK = qw/prompt/;

# Copied from ExtUtils::MakeMaker (by many authors)
sub prompt {
    my ( $mess, $def ) = @_;
    Carp::croak("prompt function called without an argument")
      unless defined $mess;

    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";

    local $| = 1;
    local $\;
    print "$mess $dispdef";

    my $ans;
    if ( $ENV{PERL_MM_USE_DEFAULT} || !_is_interactive() ) {
        print "$def\n";
    }
    else {
        $ans = <STDIN>;
        if ( defined $ans ) {
            chomp $ans;
        }
        else { # user hit ctrl-D
            print "\n";
        }
    }

    return ( !defined $ans || $ans eq '' ) ? $def : $ans;
}

# Copied (without comments) from IO::Interactive::Tiny by Daniel Muey,
# based on IO::Interactive by Damian Conway and brian d foy
sub _is_interactive {
    my ($out_handle) = ( @_, select );
    return 0 if not -t $out_handle;
    if ( tied(*ARGV) or defined( fileno(ARGV) ) ) {
        return -t *STDIN if defined $ARGV && $ARGV eq '-';
        return @ARGV > 0 && $ARGV[0] eq '-' && -t *STDIN if eof *ARGV;
        return -t *ARGV;
    }
    else {
        return -t *STDIN;
    }
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Prompt::Tiny - Prompt for user input with a default option

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use IO::Prompt::Tiny qw/prompt/;

  my $answer = prompt("Yes or no? (y/n)", "n");

=head1 DESCRIPTION

This is an extremely simple prompting module, based on the extremely simple
prompt offered by L<ExtUtils::MakeMaker>.In many cases, that's all you need and
this module gives it to you without all the overhead of ExtUtils::MakeMaker
just to prompt for input.

It doesn't do any validation, coloring, menus, timeouts, or any of the wild,
crazy, cool stuff that other prompting modules do.  It just prompts with
a default.  That's it!

=head1 USAGE

The following function may be explicitly imported. No functions are imported by
default.

=head2 prompt

    my $value = prompt($message);
    my $value = prompt($message, $default);

The prompt() function displays the message as a prompt for input and returns
the (chomped) response from the user, or the default if the response was
empty.

If the program is not running interactively or if the PERL_MM_USE_DEFAULT
environment variable is set to true, the default will be used without
prompting.

If no default is provided, an empty string will be used instead.

Unlike ExtUtils::MakeMaker::prompt(), this prompt() does not use
prototypes, so this will work as expected:

  my @args = ($prompt, $default);
  prompt(@args);

=head1 ENVIRONMENT

=head2 PERL_MM_USE_DEFAULT

If set to a true value, IO::Prompt::Tiny will always return the default
without waiting for user input, just like ExtUtils::MakeMaker does.

=head1 ACKNOWLEDGMENTS

The guts of this module are based on L<ExtUtils::MakeMaker> and
L<IO::Interactive::Tiny> (which is based on L<IO::Interactive>).
Thank you to the authors of those modules.

=head1 SEE ALSO

=over 4

=item *

L<IO::Prompt>

=item *

L<IO::Prompt::Simple>

=item *

L<Prompt::Timeout>

=item *

L<Term::Prompt>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/IO-Prompt-Tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/IO-Prompt-Tiny>

  git clone https://github.com/dagolden/IO-Prompt-Tiny.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
