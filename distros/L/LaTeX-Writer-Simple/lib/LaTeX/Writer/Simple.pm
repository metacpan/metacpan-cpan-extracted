package LaTeX::Writer::Simple;
$LaTeX::Writer::Simple::VERSION = '0.02';
use warnings;
use strict;

use base 'Exporter';

our @EXPORT = (qw/document p/);
our @EXPORT_OK = (qw/_c _e/);

### Commands creation ;)
sub _def {
    my ($name, $sub) = @_;
    
    no strict 'refs';
    my $x = "LaTeX::Writer::Simple::$name";
    *$x = $sub;
    push @EXPORT, $name;
}

my @nl_commands = (qw/part chapter section subsection subsubsection caption/);    
for my $c (@nl_commands) {
    _def($c, sub { _c($c, @_)."\n" });
}

my @inline_commands = (qw/label Ref pageRef/);    
for my $c (@inline_commands) {
    _def($c, sub { _c($c, @_) });
}

my %abbr_inline_commands = (it => 'textit',
                            bf => 'textbf',
                            tt => 'texttt');
for my $c (keys %abbr_inline_commands) {
    my $cc = $abbr_inline_commands{$c};
    _def($c,  sub { _c($cc, @_) });
    _def($cc, sub { _c($cc, @_) });
}

my @envs = (qw/center flushleft flushright/);
for my $c (@envs) {
    _def($c, sub { _e($c, @_) });
}


=head1 NAME

LaTeX::Writer::Simple - A module to help writing LaTeX file.

=head1 SYNOPSIS

LaTeX::Writer::Simple provides a programmatically interface to write LaTeX files
from within Perl.

    use LaTeX::Writer::Simple;

    my $foo = document( { -title => {Document Title},
                        })

    print $foo;

=head1 EXPORT

By default the module exports the following LaTeX functions:

=head2 part

=head2 chapter

=head2 section

=head2 subsection

=head2 subsubsection

=head2 caption

=head2 texttt

=head2 textit

=head2 textbf

=head2 it

=head2 tt

=head2 label

=head2 Ref

=head2 pageRef

=head2 bf

=head2 center

=head2 flushleft

=head2 flushright

=head2 p

=cut

sub p {
    return join("\n\n", @_)."\n\n";
}

=head2 document

=cut

sub document {
    my $conf = { documentclass => 'article',
                 title => '',
                 date => '\today',
                 author => '',
                 maketitle => 1,
                 options => [],
                 packages => { url => 1,
                               graphicx => 1,
                               inputenc => ['utf8'],
                               babel => ['english']},
               };

    $conf = _merge($conf, shift(@_)) if ref $_[0];
    
    my $ops = (ref($conf->{options}) eq "ARRAY")?join(",",@{$conf->{options}}):$conf->{options};
    my $latex_document = "\\documentclass[$ops]\{$conf->{documentclass}}\n";

    for my $package_name (keys %{$conf->{packages}}) {
        if (ref($conf->{packages}{$package_name}) eq "ARRAY") {
            $latex_document .= "\\usepackage[".join(",",@{$conf->{packages}{$package_name}})."]{$package_name}\n";
        } else {
            if ($conf->{packages}{$package_name}) {
                $latex_document .= "\\usepackage{$package_name}\n";
            }   
        }
    }

    if (ref($conf->{author}) eq "ARRAY") {
        $conf->{author} = join(' \and ', @{$conf->{author}});
    }
    for (qw/title date author/) {
        $latex_document .= "\\$_\{$conf->{$_}}\n";
    }

    $latex_document .= "\\begin{document}\n";
    $latex_document .= "\\maketitle\n" if $conf->{maketitle};
    $latex_document .= join("\n", @_);
    $latex_document .= "\\end{document}\n";
    return $latex_document;
}

## Auxiliary functions...

sub _c {
    my $command = shift;
    my $opt_args = (ref($_[0]) eq "ARRAY")?shift(@_):"";
    my $args = @_?join("", map "{$_}", @_):"";
    
    $opt_args = '['.join(",",@$opt_args).']' if ($opt_args);
    
    return "\\$command$opt_args$args"
}

sub _merge {
    my ($defaults, $options) = @_;
    
    for my $key (keys %$options) {
        if ((exists $defaults->{$key})  &&
            (ref $defaults->{$key}  eq "HASH") &&
            (ref $options->{$key} eq "HASH")) {
                $defaults->{$key} = _merge($defaults->{$key}, $options->{$key})
        } else {
            $defaults->{$key} = $options->{$key};
        }
    }
    return $defaults;
}

sub _e {
    my $name = shift;
    return "\\begin{$name}\n".join("\n",@_)."\n\\end{$name}"
}

=head1 AUTHOR

Alberto Simoes, C<< <ambs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-writer-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-Writer-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::Writer::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LaTeX-Writer-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LaTeX-Writer-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LaTeX-Writer-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/LaTeX-Writer-Simple>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alberto Simoes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of LaTeX::Writer::Simple
