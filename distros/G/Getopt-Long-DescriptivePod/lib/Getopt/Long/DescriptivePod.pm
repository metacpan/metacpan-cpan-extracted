package Getopt::Long::DescriptivePod; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '0.04';

use Carp qw(confess);
use English qw(-no_match_vars $PROGRAM_NAME $OS_ERROR $INPUT_RECORD_SEPARATOR);
use Params::Validate qw(validate SCALAR SCALARREF CODEREF);
use Sub::Exporter -setup => {
    exports => [ qw( replace_pod trim_lines ) ],
    groups  => {
        default => [ qw( replace_pod trim_lines ) ],
    },
};

sub _on_verbose {
    my ($param_ref, $string) = @_;

    if ( $param_ref->{on_verbose} ) {
        $param_ref->{on_verbose}->($string);
    }

    return;
}

sub _close_data {
    # after __END__ this handle is open
    no warnings qw(once); ## no critic (ProhibitNoWarnings)

    return close ::DATA;
}

sub _format_block {
    my $block_ref = shift;

    for my $key ( keys %{$block_ref} ) {
        VALUE: for my $value ( $block_ref->{$key} ) { # alias only
            defined $value
                or next VALUE;
            $value =~ s{ \r\n | [\n\r]       }{\n}xmsg; # compatible \n
            $value =~ s{ \A \n* (.*?) \n* \z }{$1}xms;  # trim
            $value = [
                ( $key eq 'after' ? q{} : () ),
                ( split m{ \n }xms, $value ),
                ( $key eq 'before' ? q{} : () ),
            ];
        }
    }

    return;
}

sub _read_file {
    my $param_ref = shift;

    if ( ref $param_ref->{filename} ) {
        return ${ $param_ref->{filename} };
    }
    if ( open my $file, '< :raw', $param_ref->{filename} ) {
        local $INPUT_RECORD_SEPARATOR = ();
        my $content = <$file>;
        () = close $file;
        return $content;
    }
    _verbose( $param_ref, "Can not open file $param_ref->{filename} $OS_ERROR" );

    return;
}

sub _write_file {
    my ($param_ref, $content) = @_;

    if ( ref $param_ref->{filename} ) {
        ${ $param_ref->{filename} } = $content;
        return;
    }
    open my $file, '> :raw', $param_ref->{filename}
        or confess "Can not open file $param_ref->{filename} $OS_ERROR";
    print {$file} $content
        or confess "Can not write file $param_ref->{filename} $OS_ERROR";
    close $file
        or confess "Can not close file $param_ref->{filename} $OS_ERROR";

    return;
}

sub replace_pod { ## no critic (ArgUnpacking)
    my %param_of = validate(
        @_,
        {
            filename          => { type  => SCALAR | SCALARREF, default => $PROGRAM_NAME },
            tag               => { regex => qr{ \A = \w }xms },
            before_code_block => { type  => SCALAR, optional => 1 },
            code_block        => { type  => SCALAR },
            after_code_block  => { type  => SCALAR, optional => 1 },
            indent            => { regex => qr{ \A \d+ \z }xms, default => 1 },
            on_verbose        => { type  => CODEREF, optional => 1 },
        },
    );

    BLOCK: for my $block ( qw(before_code_block code_block after_code_block) ) {
        defined $param_of{$block}
            or next BLOCK;
        $param_of{$block} =~ m{ ^ = }xms
            and confess "A Pod tag is not allowed in $block";
    }

    _close_data;

    # clone
    my %block_of = (
        before => $param_of{before_code_block},
        code   => $param_of{code_block},
        after  => $param_of{after_code_block},
    );

    _format_block( \%block_of );

    for my $line ( @{ $block_of{code} } ) {
        $line = q{ } x $param_of{indent} . $line;
    }

    # \t to indent, trim EOL
    my @block = map { ## no critic (ComplexMappings)
        my $value = $_;
        $value =~ s{ \t }{ q{ } x $param_of{indent} }xmsge;
        $value =~ s{ \s+ \z }{}xms;
        $value;
    } (
        @{ $block_of{before} || [] },
        @{ $block_of{code} },
        @{ $block_of{after} || [] },
    );

    my $current_content = _read_file( \%param_of );
    if ( ! $current_content ) {
        _on_verbose( \%param_of, 'Empty file detected' );
        return;
    }
    my ($newline) = $current_content =~ m{ ( \r\n | [\n\r] ) }xms;
    $current_content =~ s{ \r\n | [\n\r] }{\n}xmsg;
    my ($newlines_at_eof) = $current_content =~ m{ ( \n+ ) \z }xms;
    $newlines_at_eof = length +( $newlines_at_eof || q{} );
    $current_content =~ s{ \n+ \z }{}xms;
    my @content = split m{ \n }xms, $current_content;

    # replace Pod
    my $is_found;
    my $index = 0;
    LINE: while ( $index < @content ) {
        my $line = $content[$index];
        if ( $is_found ) {
            if ( $line =~ m{ \A = \w }xms ) { # stop deleting on next tag
                $is_found = ();
                last LINE;
            }
            splice @content, $index, 1; # delete current line
            redo LINE;
        }
        if ( $line =~ m{ \A \Q$param_of{tag}\E \z }xms ) {
            $is_found++;
            splice @content, $index + 1, 0, q{}, @block, q{};
            $index += 1 + @block + 1;
        }
        $index++;
    }

    # check changes
    my $new_content = join "\n", @content;
    if ( $newlines_at_eof ) {
        # restore current_content too
        for my $content ( $current_content, $new_content ) {
            $content .= "\n" x $newlines_at_eof;
        }
        _on_verbose( \%param_of, "$newlines_at_eof newline(s) at EOF detected" );
    }
    else {
        _on_verbose( \%param_of, 'No newline at EOF detected' );
    }
    if ( $new_content eq $current_content ) {
        _on_verbose( \%param_of, 'Equal content - nothing to do' );
        return;
    }

    $new_content =~ s{ \n }{$newline}xmsg;
    _write_file( \%param_of, $new_content );

    return;
}

sub trim_lines {
    my ($text, $indent) = @_;

    if (! $indent) {
        $text =~ s{ \s+    }{ }xmsg;
        $text =~ s{ \A \s+ }{}xms;
        $text =~ s{ \s+ \z }{}xms;
        return $text;
    }
    $indent =~ m{ \A [1-9] \d* \z }xms
        or confess "Indent $indent is not a positive integer";

    # measure the first line
    ($indent) = $text =~ m{ \A ( (?: [ ]{$indent} )+ ) }xms;
    $indent = length $indent;

    $text =~ s{ ^ [ ]{$indent} }{}xmsg;
    $text =~ s{ [ ]+ $         }{}xmsg;

    return $text;
}

# $Id: $

1;

__END__

=pod

=head1 NAME

Getopt::Long::DescriptivePod - write usage to Pod

=head1 VERSION

0.04

=head1 SYNOPSIS

    use Getopt::Long::Descriptive;
    use Getopt::Long::DescriptivePod;

    my ($opt, $usage) = describe_options(
        '%c %o',
        [ 'help|h|?', 'help' ],
        ...
    );

    if ( 'during development and test or ...' ) {
        replace_pod({
            tag        => '=head1 USAGE',
            code_block => $usage->text,
        });
    }

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

C<Getopt::Long::Descriptive> is a excellent way
to write parameters and usage at the same time.

This module allows to write Pod at the same time too.
The idea is to write the usage in the Pod of the current script
during development or test.

=head1 SUBROUTINES/METHODS

=head2 sub replace_pod

Write the Pod for your script and the Pod.
Put a section into that Pod
like C<=head1 USAGE>
or C<=head2 special usage for foo bar>.
No matter what is inside of that section
but no line looks like a Pod tag beginning with C<=>.

A tabulator will be changed to "indent" whitespaces.
In code_block, before_code_block and after_code_block Pod tags are not allowed.

Run this subroutine and the usage is in the Pod.

    replace_pod({
        tag => '=head1 USAGE',

        # the usage as block of code
        code_block => $usage->text,

        # optional text before that usage
        before_code_block => $multiline_text,

        # optional text after that usage
        after_code_block => $multiline_text,

        # optional if ident 1 is not enough
        indent => 4,

        # for testing or batch
        # the default filename is $PROGRAM_NAME ($0)
        filename => $filename; # or \$content_of_file,

        # optional to find out why the module has done nothing
        on_verbose => sub { my $message = shift; ... },
    });

=head2 sub trim_lines

There are two ways of trimming.

=head3 trim all whitespace

    my ($opt, $usage) = describe_options(
        ...
        [ 'verbose|v', trim_lines( <<'EOT' ) ],
            Print extra stuff.
            And here I show, how to work
            with lots of lines as floating text.
    EOT
        ...
    );

=head3 trim blocks of whitespace in Pod

The 2nd parameter of trim_lines if the given indent.
Then C<trim_lines> measures the indent of every first line.

    e.g. 2nd parameter of trim_lines = 4
    text indent | count of removed whitespace
    ------------+----------------------------
    0 .. 3      | 0
    4 .. 7      | 4
    8 .. 11     | 8
    ...         | ...

    replace_pod({
        before_code_block => trim_lines( <<'EOT', 4 ),
            floating text
            (removes 2 * 4 space of evey line)

                some_code;
    EOT
        after_code_block => trim_lines( <<'EOT', 4 ),
            some_code(
                'removes 2 * 4 space of evey line',
            );

    EOT
    ...
    });

=head1 DIAGNOSTICS

Confesses on false subroutine parameters.

See parameter on_verbose.

Confesses on write file.

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Carp|Carp>

L<English|English>

L<Params::Validate|Params::Validate>

L<Sub::Exporter|Sub::Exporter>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

C<__END__> in the script stops the compiler and provides the DATA file handle.
After call of C<replace_pod> the DATA file handle is closed.

Runs not on C<perl -e> calls or anything else with no real file name.

=head1 SEE ALSO

L<Getopt::Long::Descriptive|Getopt::Long::Descriptive>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 - 2016,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
