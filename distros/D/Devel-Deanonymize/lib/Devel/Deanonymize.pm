=head1 NAME

Devel::Deanonymize - A small tool to make anonymous sub visible

=head1 DESCRIPTION

When collecting Coverage statistics with L<Devel::Cover> a construct like below appear to be invisible and is simply ignored
by the statistic:

    my $sub = sub {
        print "hello";
    }

This script aims to solve this problem by wrapping each file in a sub and thus making these subs I<visible>.
Code is based on L<https://github.com/pjcj/Devel--Cover/issues/51#issuecomment-17222928>

=head1 SYNOPSIS

    # Perl scripts
    perl -MDevel::Cover=-ignore,^t/,Deanonymize -MDevel::Deanonymize=<inculde_pattern> your_script.pl

    # Perl tests
    HARNESS_PERL_SWITCHES="-MDevel::Cover=-ignore,^t/,Deanonymize -MDevel::Deanonymize=<include_pattern>"  prove t/


=head1 DEBUGGING

If your tests suddenly fail for some weird reason, you can set C<DEANONYMIZE_DEBUG>. If this environment variable is set,
we print out the filename for every modified file write its contents to C<filepath/filename_mod.pl>.

It is also important to note that the regex which matches the end-marker is not perfect. In general it can be summarized
as follows:

We start at the end of a file and search for the first occurrence of either C<__END__>, C<__DATA__> or C<1;>. To improve
robustness, these markers must occur alone on their respective line.
A special case is C<1> without semicolon: We only consider this case if its the very last character of a file.

Files with no endmarkers at all are dangerous to use in conjunction with this module...


=head1 EXAMPLES

Please referer to the files provided in the I<examples/> directory


=head1 AUTHORS

Since there is a lot of spam flooding my mailbox, I had to put spam filtering in place. If you want to make sure
that your email gets delivered into my mailbox, include C<#im_not_a_bot#> in the B<subject!>

S<Tobias Bossert E<lt>tobib at cpan.orgE<gt>>

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Tobias Bossert, OETIKER+PARTNER AG Switzerland

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

package Devel::Deanonymize;
use strict;
use warnings FATAL => 'all';
use base 'Exporter';

our @EXPORT = qw(alterContent);

our $VERSION = "0.2.0"; # Do not change manually, changed automatically on `make build` target

my $include_pattern;

sub import {
    # capture input parameters
    $include_pattern = $_[1] ? $_[1] : die("Devel::Deanonymize: An include Pattern must be specified \n");
}

sub alterContent {
    my $input = shift;
    my $subName = shift;
    # define everything in a sub, so Devel::Cover will DTRT
    # NB this introduces no extra linefeeds so D::C's line numbers
    # in reports match the file on disk
    # - In general, we match only if <white_space>*ENDMARKER<white_space>*<end_of_line>
    # - We only allow `1` without a semicolon if found at the very end
    $input =~ s/(.*?package\s+\S+)(.*)^[\s]*(__END__|1;|1\Z|__DATA__)[\s]*$(.*)\Z/$1sub $subName {$2} $subName();$3$4/sgm;

    # unhide private methods to avoid "Variable will not stay shared"
    # warnings that appear due to change of applicable scoping rules
    # Note: not '\s*' in the start of string, to avoid matching and
    # removing blank lines before the private sub definitions.
    $input =~ s/(^[\t| ]*)my\s+(\S+\s*=\s*sub.*)$/$1our $2/gm;

    return $input
}

sub hasEndmarker {
    my $input = shift;
    if ($input =~ /^[\s]*(__END__|1;|1\Z|__DATA__)[\s]*$(.*)\Z/gms) {
        return 1;
    }
    return 0;
}


sub modify_files {
    # Internal notes:
    # Basically, this code replaces every file path in @INC with a reference to an anonymous sub which wraps each
    # file in sub classWrapper { $orig_content } classWrapper(); However, this sub is **not** necessarily run at INIT or UNITCHECK stage!
    # NB, this also explains why its is possible to have $include_pattern "defined" at UNITCHECK even if its run **before** import()
    # Also make sure each file either ends with __DATA__, __END__, or 1;
    unshift @INC, sub {
        my (undef, $filename) = @_;
        return () if ($filename !~ /$include_pattern/);
        if (my $found = (grep {-e $_} map {"$_/$filename"} grep {!ref} @INC)[0]) {
            print "Devel::Deanonymize: $found" . "\n" if $ENV{DEANONYMIZE_DEBUG};
            local $/ = undef;
            open my $fh, '<', $found or die("Can't read module file $found\n");
            my $module_text = <$fh>;
            close $fh;

            if (not hasEndmarker($module_text)) {
                warn("Devel::Deanonymize: Found no endmarker in file `$filename` - skipping\n");
                return ();
            }

            $module_text = alterContent($module_text, "_anon");

            # filehandle on the scalar
            open $fh, '<', \$module_text;

            if ($ENV{DEANONYMIZE_DEBUG}) {
                open my $mod_fh, '>', $found . "_mod.pl";
                print $mod_fh $module_text;
                close $mod_fh;
            }

            # and put it into %INC too so that it looks like we loaded the code
            # from the file directly
            $INC{$filename} = $found;
            return $fh;
        }
        else {
            return ();
        }
    };
}


# We call modify_files twice since depending on how a module is loaded (use or required) it is present in @INC at different stages
# Also, "double-modification" is not possible because we only alter non references
INIT {
    modify_files();
}

UNITCHECK {
    modify_files();
}

1;
