package ENV::Util;
use strict;
use warnings;

our $VERSION = 0.03;

sub import {
    my ($pkg, $cmd, @args) = @_;
    return if !defined $cmd;
    if ($cmd eq '-load_dotenv') {
        load_dotenv(@args)
    }
    else {
        local($!, $^E);
        my ($pkg, $file, $line) = caller(1);
        die "invalid import action for $pkg in $file line $line.";
    }
}

sub prefix2hash {
    my ($prefix) = @_;
    $prefix = '' unless defined $prefix;
    my $start_index = length($prefix);
    my %options = map { lc(substr($_, $start_index)) => $ENV{$_} } grep index($_, $prefix) == 0, keys %ENV;
    return %options;
}

sub load_dotenv {
    my ($filename) = @_;
    $filename = '.env' unless defined $filename;
    return unless -f $filename;

    open my $fh, '<:raw:encoding(UTF-8)', $filename
      or die "unable to open env file '$filename': $!";

    my @lines;
    { local $!; @lines = <$fh> }
    my %env;
    # POSIX convention for env variable names:
    my $varname_re = qr/[a-zA-Z_][a-zA-Z0-9_]+/;
    foreach my $line (@lines) {
        # code heavily inspired by Dotenv.pm (BooK++)
        if (my ($k, $v) = $line =~ m{
            \A\s*
            # 'export' (bash), 'set'/'setenv' ([t]csh) are optional keywords:
            (?: (?:export|set|setenv) \s+ )?
            ( $varname_re )
            (?: \s* (?:=|\s+) \s* )       # separator is '=' or spaces
            (
              '[^']*(?:\\'|[^']*)*'  # single quoted value
             |"[^"]*(?:\\"|[^"]*)*"  # or double quoted value
             | [^\#\r\n]+            # or unquoted value
            )?
            \s* (?: \# .* )?            # inline comment
            \z}sx
        ) {
            $v = '' unless defined $v;
            $v =~ s/\s*\z//;

            my $interpolate_vars = 1; # unquoted strings interpolate variables.

            # drops quotes from quoted values, and interpolate if double quoted:
            if ( $v =~ s/\A(['"])(.*)\1\z/$2/) {
                if ($1 eq '"' ) {
                    $v =~ s/\\n/\n/g;
                    $v =~ s/\\//g;
                }
                else {
                    $interpolate_vars = 0;
                }
            }

            if ($interpolate_vars) {
                # $env{$1} could point to a variable that doesn't exist.
                no warnings 'uninitialized';
                $v =~ s{\$($varname_re)}{exists $ENV{$1} ? $ENV{$1} : $env{$1}}ge;
            }
            $env{$k} = $v;
        }
    }
    %ENV = (%env, %ENV);
    return;
}

sub redacted_env {
    my (%opts) = @_;
    if (!$opts{rules}) {
        $opts{rules} = [
            {
                key => qr(USER|ID|NAME|MAIL|ACC|TOKEN|PASS|PW|SECRET|KEY|ACCESS|PIN|SSN|CARD|IP),
                mask => '<redacted>',
            },
            {
                value => qr(\@|:|=),
                mask  => '<redacted>',
            },
        ]
    }
    my %redacted;
    ENVKEY:
    foreach my $k (keys %ENV) {
        my $v = $ENV{$k};
        foreach my $rule (@{ $opts{rules} }) {
            if ( ($rule->{key} && $k =~ $rule->{key})
              || ($rule->{value} && $v =~ $rule->{value})
            ) {
              if ( ($rule->{key} && $k =~ $rule->{key}) ) {
              } elsif($rule->{value} && $v =~ $rule->{value}) {
              }
              next ENVKEY if $rule->{drop};
              $v = $rule->{mask};
              last;
            }
        }
        $redacted{$k} = $v;
    }
    return %redacted;
}

1;
__END__

=head1 NAME

ENV::Util - parse prefixed environment variables and dotnev (.env) files into Perl

=head1 SYNOPSIS

Efficiently load an L<'.env'|/"The .env file format"> file into %ENV:

    use ENV::Util -load_dotenv;

Turn all %ENV keys that match a prefix into a lowercased config hash:

    use ENV::Util;

    my %cfg = ENV::Util::prefix2hash('MYAPP_');
    # MYAPP_SOME_OPTION becomes $cfg{ some_option }

Safe dump of %ENV without tokens or passwords:

    use ENV::Util;
    my %masked_env = ENV::Util::redacted_env();
    say $masked_env{token_secret}; # '<redacted>'

=head1 DESCRIPTION

This module provides a set of utilities to let you easily handle environment
variables from within your Perl program.

It is lightweight, should work on any Perl 5 version and has no dependencies.

=head1 FUNCTIONS

=head2 prefix2hash( 'PREFIX' )

    my %config = ENV::Util::prefix2hash( 'MYAPP_' );

This function returns all data from environment variables that begin with
the given prefix. You can use that to allow users to control your program
directly from their environment without risking name clashing of env vars.

So for example if your app is called "MYAPP", you can allow them to setup
MYAPP_TOKEN, MYAPP_USERNAME, MYAPP_ROLES, MYAPP_TOKEN, etc. as environment
variables. By calling C<prefix2hash()> with the proper prefix (in this case,
'MYAPP_'), you get a hash of all the specified keys and values, with the
prefix properly stripped and all keys in lowercase, as is common practice
in Perl code.

=head2 load_dotenv()

=head2 load_dotenv( $filename )

This functions load the contents of any L<dotenv file|https://12factor.net/config>
(defaults to 'C<.env>') into %ENV. It does B<*NOT*> override keys/values already
in the environment (%ENV). To use a filename other than "C<.env>", simply pass
it as an argument.

    ENV::Util::load_dotenv();                # loads ".env"
    ENV::Util::load_dotenv('somefile.env');  # loads "somefile.env"

    # to load multiple files in a given order:
    ENV::Util::load_dotenv($_) for qw( file1.env file2.env file3.env );

B<NOTE:> because loading a C<.env> file is so common for apps running in
containers, we added a shortcut that loads it directly at compile time:

    use ENV::Util -load_dotenv;

=head3 The .env file format

Despite being almost ubiquitous in containerized environments, there is no
standard format for "dotenv", and each implementation does its own thing.

This is ours:

    # comments can be standalone or inline.
    # blank lines are also accepted.

    # variable names must follow the pattern [A-Za-z_][a-zA-Z0-9_]+
    # but usually are just A..Z in all caps.
    FOO  =  some value   # spaces are trimmed except inside the string.
    FOO='some value'     # so both lines here are the same.

    NEWLINE=\n           # unquoted values are treated WITH interpolation.
    NEWLINE="\n"         # so this line and the one above are the same.
    LITERAL='\n'         # but this is a literal '\' and a literal 'n'.

    BAR=baz          # bash/zsh format.
    export BAR=baz   # bash format.
    set BAR=baz      # tcsh/csh format.
    setenv BAR baz   # tcsh/csh format (note this one lacks '=').

    # empty values are set to the empty string ''
    NONE =
    ALSONONE

    # you can prepend '$' to variable names to interpolate them
    # in unquoted or double quoted values. You can point to variables
    # declared before in the file or available in your %ENV
    # *AS LONG AS* you don't try to replace variables from %ENV,
    # which is not allowed by design.
    MYKEY=$OTHERKEY
    MYKEY=$MYKEY and something else  # ok to use the same variable.


=head2 redacted_env()

=head2 redacted_env( %options )

    $ENV{ HARMLESS_VAR } = 1234;
    $ENV{ APP_SECRET } = 4321;

    my %masked = ENV::Util::redacted_env();
    say $masked{ HARMLESS_VAR };  # 1234;
    say $masked{ APP_SECRET };    # <redacted>;

Returns a masked (redacted) version of %ENV, (hopefully) without sensitive information.
This can be useful if you are dumping your environment variables to a log/debug facility
without compromising information security/privacy.

B<WARNING>: This function is heuristic and redacts based on suspicious token/value data.
B<< There is NO WARRANTY that your sensitive data will be redacted >>. You are advised
to test and tweak options according to your environment and data, and use it at your
own discretion and risk.

Any keys matching the following will be redacted/masked: USER, ID, NAME,
MAIL, ACC, TOKEN, PASS, PW, SECRET, KEY, ACCESS, PIN, SSN, CARD, IP.

Regardless of keys, any I<values> that contain '@', ':' or '=' will also
be redacted.

=head3 Creating your own mask/redaction rules:

To override the following rules with your own, simply pass to the function a
hash with a C<rules> key, holding an array reference of hash references
containing each rule. The format is as follows:

    my %masked_env = ENV::Util::redacted_env(
        rules => [
            { key => qr(...), mask => '<redacted>' },
            { key => qr( another key ), drop => 1 },
        ],
    );

As you can see above, each rule is a hash reference that may contain the
following fields:

=over 4

=item * C<key> is a regexp to be tested against %ENV keys.

=item * C<value> is a regexp to be tested against %ENV values.

=item * C<mask> is what to replace the value with. Default to C<undef>.

=item * C<drop> if set to true, removes the matching key entirely.

=back

=head1 SEE ALSO

L<Dotenv>, L<Env::Dot>, L<Config::ENV>, L<Config::Layered::Source::ENV>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 Breno G. de Oliveira

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR
THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU.
SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY
SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO
YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED
INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE
SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER
PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
