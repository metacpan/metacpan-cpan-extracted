package HTML::TabbedExamples::Generate;

use strict;
use warnings;

use 5.014;

our $VERSION = '0.0.6';

use MooX 'late';

use CGI ();
use Text::VimColor;

use Carp ();

has _default_syntax => (is => 'ro', isa => 'Str', init_arg => 'default_syntax');
has _main_pre_css_classes => (is => 'ro', isa => 'ArrayRef[Str]',
    default => sub {
        return [qw(code)];
    },
    init_arg => 'main_pre_css_classes',
);

sub _calc_post_code
{
    my $self = shift;
    my $ex_spec = shift;

    my $pre_code = $ex_spec->{code};

    if ($ex_spec->{no_syntax})
    {
        return "<pre>\n" . CGI::escapeHTML($pre_code) . "</pre>\n";
    }
    else
    {
        my $syntax = ($ex_spec->{syntax} || $self->_default_syntax);

        my $code = <<"EOF";
#!/usr/bin/perl

use strict;
use warnings;

$pre_code
EOF

        my $tvc = Text::VimColor->new(
            string => \$code,
            filetype => $syntax,
        );

        return
            qq|<pre class="|
                . join(' ', map { CGI::escapeHTML($_) }
                    @{$self->_main_pre_css_classes}, $syntax
                )
            . qq|">\n|
            . ($tvc->html() =~ s{(class=")syn}{$1}gr)
            . qq|\n</pre>\n|
            ;

    }
}

sub render
{
    my ($self, $args) = @_;

    my $examples = $args->{'examples'};
    my $id_base = $args->{'id_base'};

    my $ret_string = '';

    my @lis;
    my @codes;

    foreach my $ex_spec (@$examples)
    {
        my $id = $id_base . '__' . $ex_spec->{id};
        my $label = $ex_spec->{label};

        my $esc_id = CGI::escapeHTML($id);
        my $esc_label = CGI::escapeHTML($label);

        my $post_code = $self->_calc_post_code($ex_spec);

        push @lis, qq[<li><a href="#$esc_id">$esc_label</a></li>\n];
        push @codes, qq[<div id="$esc_id">$post_code</div>];
    }

    return
        qq{<div class="tabs">\n}
            . qq{<ul>\n}
                . join("\n", @lis)
            . qq{\n</ul>\n}
            . join("\n", @codes) .
        qq{</div>\n}
        ;
}

sub html_with_title
{
    my ($self, $args) = @_;

    my $id_base = $args->{'id_base'}
        or Carp::confess("id_base not specified.");
    my $title = $args->{'title'}
        or Carp::confess("title not specified.");

    return
        qq[<h3 id="] . CGI::escapeHTML($id_base)
        . qq[">] . CGI::escapeHTML($title) . qq[</h3>\n\n]
        . $self->render($args)
        ;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

HTML::TabbedExamples::Generate - generate syntax-highlighted examples for
codes with a markup compatible with jQueryUI's tab widgets.

=head1 VERSION

version 0.0.6

=head1 SYNOPSIS

        use HTML::TabbedExamples::Generate;

        use strict;
        use warnings;

        # Examples generator:
        my $ex_gen = HTML::TabbedExamples::Generate->new(
            {
                default_syntax => 'perl',
            }
        );

        print $ex_gen->html_with_title(
            {
                title => "Copying a file",
                id_base => "copying_a_file",
                examples =>
                [
                    {
                        id => "io_all",
                        label => "IO-All",
                        code => <<'EOF',
        use IO::All;

        my ($source_filename, $dest_filename) = @_;
        io->file($source_filename) > io->file($dest_filename);
        EOF

                    },
                    {
                        id => "core",
                        label => "Core Perl",
                        code => <<'EOF',
        use File::Copy qw(copy);

        my ($source_filename, $dest_filename) = @_;

        copy($source_filename, $dest_filename);
        EOF
                    },
                ],
            }
        );

        print $ex_gen->html_with_title(
            {
                title => "Overwriting a file with text",
                id_base => "overwrite_a_file",
                examples =>
                [
                    {
                        id => "io_all",
                        label => "IO-All",
                        code => <<'EOF',
        use IO::All;

        io->file("output.txt")->utf8->print("Hello World!\n");
        EOF

                    },
                    {
                        id => "core",
                        label => "Core Perl",
                        code => <<'EOF',
        use autodie;

        open my $out, '>:encoding(utf8)', "output.txt";
        print {$out} "Hello World!\n";
        close($out);
        EOF
                    },
                ],
            }
        );

=head1 METHODS

=head2 my $obj = HTML::TabbedExamples::Generate->new({ default_syntax => "perl", main_pre_css_classes => [qw( code my_example1 )]})

Returns a new object with a default_syntax for the examples, and some classes
to add for the main pre tag. Default C<'main_pre_css_classes'> value is only
the class C<'code'>.

=head2 my $html_markup_string = $obj->render({ examples => \@examples, id_base => 'my_example_id'})

Renders some examples. C<'id_base'> is the prefix to prepend to the classes’
IDs. C<'examples'> points to an array-ref of examples, which are hash-refs
cotnaining:

=over 4

=item * label

The tab's label.

=item * no_syntax

If true, disable syntax highlighting.

=item * syntax

If true, override the default_syntax

=back

=head2 my $html_markup_string = $obj->html_with_title({ title => 'My title to escape', %ARGS })

Same arguments as render() with the addition of C<'title'> which is a title
to be placed inside an C<< <h3>..</h3> >> tag, which will be escaped.
Returns the complete markup.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-TabbedExamples-Generate or by
email to bug-html-tabbedexamples-generate@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc HTML::TabbedExamples::Generate

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/HTML-TabbedExamples-Generate>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/HTML-TabbedExamples-Generate>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-TabbedExamples-Generate>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/HTML-TabbedExamples-Generate>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/HTML-TabbedExamples-Generate>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/HTML-TabbedExamples-Generate>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/HTML-TabbedExamples-Generate>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-TabbedExamples-Generate>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-TabbedExamples-Generate>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::TabbedExamples::Generate>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-tabbedexamples-generate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-TabbedExamples-Generate>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://bitbucket.org/shlomif/perl-HTML-TabbedExamples-Generate>

  hg clone ssh://hg@bitbucket.org/shlomif/perl-HTML-TabbedExamples-Generate

=cut
