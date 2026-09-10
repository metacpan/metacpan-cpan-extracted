package Koha::QA::Security::TemplateFilters;

use Modern::Perl;
use base 'Koha::QA::Base';

=head1 NAME

Koha::QA::Security::TemplateFilters - Detect and fix missing filters in Template Toolkit files

=head1 SYNOPSIS

  use Koha::QA::Security::TemplateFilters;

  # With a file
  my $checker = Koha::QA::Security::TemplateFilters->new({file => $file_path});

  # Or with content directly
  my $checker = Koha::QA::Security::TemplateFilters->new({content => $template_content});

  my $is_valid = $checker->check;
  my @errors = $checker->errors;

  # Get fixed content
  my $fixed_content = $checker->fix;

=head1 DESCRIPTION

This module provides functionality to detect and automatically fix missing
filters in Template Toolkit template files.
It helps ensure that variables are properly escaped to prevent XSS vulnerabilities.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::Security::TemplateFilters->new({file => $file_path});

Creates a new TemplateFilters checker instance.

=head2 check

  my $is_valid = $checker->check;

Checks the file for missing filters.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each containing:
  - error: The type of error (asset_must_be_raw, missing_filter, wrong_html_filter, extra_filter_not_needed)
  - line: The line where the error was found
  - line_number: The line number where the error was found

=head2 fix

  my $fixed_content = $checker->fix;

Returns the content with the correct (guessed) filters applied.

=cut

our @tt_directives = (
    qr{^\s*INCLUDE},
    qr{^\s*USE},
    qr{^\s*IF},
    qr{^\s*UNLESS},
    qr{^\s*ELSE},
    qr{^\s*ELSIF},
    qr{^\s*END},
    qr{^\s*SET},
    qr{^\s*WHILE},
    qr{^\s*FOR},
    qr{^\s*FOREACH},
    qr{^\s*MACRO},
    qr{^\s*SWITCH},
    qr{^\s*CASE},
    qr{^\s*PROCESS},
    qr{^\s*DEFAULT},
    qr{^\s*TRY},
    qr{^\s*CATCH},
    qr{^\s*BLOCK},
    qr{^\s*FILTER},
    qr{^\s*STOP},
    qr{^\s*NEXT},
    qr{^\s*LAST},
    qr{^\s*WRAPPER},
);

our @tt_methods = (
    qr{\.push\(},
    qr{\.delete\(},
);

sub check {
    my ($self) = @_;

    my $result = $self->_process_tt_content;

    $self->{_errors}        = $result->{errors};
    $self->{_fixed_content} = $result->{new_content};

    return @{ $result->{errors} } ? 0 : 1;
}

sub fix {
    my ($self) = @_;

    # If we haven't checked yet, check first
    $self->check unless exists $self->{_fixed_content};
    return $self->{_fixed_content};
}

sub _process_tt_content {
    my ($self) = @_;
    my ( $use_raw, $has_use_raw );
    my ( @errors, @new_lines, $line_number );
    my $content = $self->content;
    for my $line ( split "\n", $content ) {
        my $new_line = $line;
        $line_number++;
        if ( $line =~ m{\[%[^%]+%\]} ) {

            # handle exceptions first
            if ( $line =~ m{\|\s*\$raw} ) {    # Is the file use the raw filter?
                $use_raw = 1;
            }

            # Do we have Asset without the raw filter?
            if ( $line =~ m{^\s*\[% Asset} && $line !~ m{\|\s*\$raw} ) {
                push @errors,
                    {
                    error       => 'asset_must_be_raw',
                    message     => 'The Asset Template::Toolkit plugin must be escaped using the $raw filter',
                    line        => $line,
                    line_number => $line_number
                    };
                $new_line =~ s/\)\s*%]/) | \$raw %]/;
                $use_raw = 1;
                push @new_lines, $new_line;
                next;
            }

            $has_use_raw++
                if $line =~ m{\[%(\s|-|~)*USE raw(\s|-|~)*%\]};    # Does [% Use raw %] exist?

            my ( $error, $message );
            while ( $line =~ m{<a href="([^"]+)}g ) {
                my $to_uri_escape = $1;
                while (
                    $to_uri_escape =~ m{
                        \[%
                        (?<pre_chomp>(\s|\-|~)*)
                        (?<tt_block>[^%\-~]+)
                        (?<post_chomp>(\s|\-|~)*)
                        %\]}gmxs
                    )
                {
                    ( $new_line, $error, $message ) =
                        @{ $self->_process_tt_block( $new_line, { %+, filter => 'uri' } ) }{qw{new_line error message}};
                    push @errors, {
                        error       => $error,
                        message     => $message,
                        line        => $line,
                        line_number => $line_number,
                    } if $error;
                }
            }

            # Loop on TT blocks
            while (
                $line =~ m{
                    \[%
                    (?<pre_chomp>(\s|\-|~)*)
                    (?<tt_block>[^%\-~]+)
                    (?<post_chomp>(\s|\-|~)*)
                    %\]}gmxs
                )
            {
                ( $new_line, $error, $message ) =
                    @{ $self->_process_tt_block( $new_line, \%+ ) }{qw{new_line error message}};
                push @errors, { error => $error, message => $message, line => $line, line_number => $line_number }
                    if $error;
            }

            push @new_lines, $new_line;
        } else {
            push @new_lines, $new_line;
        }

    }

    # Adding [% USE raw %] on top if the filter is used
    @new_lines = ( '[% USE raw %]', @new_lines )
        if $use_raw and not $has_use_raw;

    my $new_content = join "\n", @new_lines;
    return { errors => \@errors, new_content => $new_content };
}

sub _process_tt_block {
    my ( $self, $line, $params ) = @_;
    my $tt_block   = $params->{tt_block};
    my $pre_chomp  = $params->{pre_chomp};
    my $post_chomp = $params->{post_chomp};
    my $filter     = $params->{filter} || 'html';
    my ( $error, $message );

    return { new_line => $line, error => $error, message => $message }
        if

        # It's a TT directive, no filters needed
        grep { $tt_block =~ $_ } @tt_directives

        # It's a TT method
        or grep { $tt_block =~ $_ } @tt_methods

        # It is a comment
        or $tt_block =~ m{^\#}

        # Already escaped with a special filter
        # We could escape it but should be safe
        or $tt_block =~ m{\s?\|\s?\$KohaDates[^\|]*$}
        or $tt_block =~ m{\s?\|\s?\$KohaTimes[^\|]*$}
        or $tt_block =~ m{\s?\|\s?\$Price[^\|]*$}
        or $tt_block =~ m{\s?\|\s?\$HtmlTags[^\|]*$}
        or $tt_block =~ m{\s?\|\s?\$HtmlId[^\|]*$}

        # Already escaped correctly with raw
        or $tt_block =~ m{\|\s?\$raw}

        # Assignment, maybe we should require to use SET (?)
        or ( $tt_block =~ m{=} and not $tt_block =~ m{\s\|\s} )

        # Already has url or uri filter
        or $tt_block =~ m{\|\s?ur(l|i)}

        # Already has trim filter
        or $tt_block =~ m{\|\s?trim}

        # Already has safe_url filter
        or $tt_block =~ m{\|\s?safe_url}

        # Specific for [% foo UNLESS bar %]
        or $tt_block =~ m{^(?<before>\S+)\s+UNLESS\s+(?<after>\S+)};

    $pre_chomp =
          $pre_chomp
        ? $pre_chomp =~ m|-|
            ? q|- |
            : $pre_chomp =~ m|~| ? q|~ |
            : q| |
        : q| |;
    $post_chomp =
          $post_chomp
        ? $post_chomp =~ m|-|
            ? q| -|
            : $post_chomp =~ m|~| ? q| ~|
            : q| |
        : q| |;

    my $new_line = $line;
    if (   $tt_block =~ m{\s?\|\s?\$KohaDates[^\|]*\|.*$}
        or $tt_block =~ m{\s?\|\s?\$Price[^\|]*\|.*$}
        or $tt_block =~ m{\s?\|\s?\$HtmlTags[^\|]*\|.*$} )
    {
        $tt_block =~ s/\s*\|\s*(uri|url|html)\s*$//;    # Could be another filter...
        $new_line =~ s{
            \[%
            \s*$pre_chomp\s*
            \Q$tt_block\E\s*\|\s*(uri|url|html)
            \s*$post_chomp\s*
            %\]
        }{[%$pre_chomp$tt_block$post_chomp%]}xms;

        return {
            new_line => $new_line,
            error    => 'extra_filter_not_needed',
            message  => q{KohaDates, Price and HtmlTags don't need to be escaped},
        };
    }

    if (
        # Use the uri filter is needed
        # If html filtered or not filtered
        $filter ne 'html' and ( $tt_block !~ m{\|}
            or ( $tt_block =~ m{\|\s?html} and not $tt_block =~ m{\|\s?html_entity} )
            or $tt_block !~ m{\s*|\s*(uri|url)} )
        )
    {
        $tt_block =~ s/^\s*|\s*$//g;        # trim
        $tt_block =~ s/\s*\|\s*html\s*//;
        $new_line =~ s{
                \[%
                \s*$pre_chomp\s*
                \Q$tt_block\E(\s*\|\s*html)?
                \s*$post_chomp\s*
                %\]
            }{[%$pre_chomp$tt_block | uri$post_chomp%]}xms;

        $error   = 'wrong_html_filter';
        $message = q{Wrong html filter, uri or url must be used instead of html};
    } elsif (
        $tt_block !~ m{\|\s?html}    # already has html filter
        )
    {
        $tt_block =~ s/^\s*|\s*$//g;    # trim
        $new_line =~ s{
            \[%
            \s*$pre_chomp\s*
            \Q$tt_block\E
            \s*$post_chomp\s*
            %\]
        }{[%$pre_chomp$tt_block | html$post_chomp%]}xms;

        $error   = 'missing_filter';
        $message = q{Missing filter, the variable is not escaped and might cause XSS vulnerabilities};

    }
    return {
        new_line => $new_line,
        error    => $error,
        message  => $message,
    };
}

1;

=head1 AUTHORS

Jonathan Druart <jonathan.druart@bugs.koha-community.org>

=head1 COPYRIGHT

Copyright 2026 Koha Development Team

=head1 LICENSE

This file is part of Koha.

Koha is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

=cut
