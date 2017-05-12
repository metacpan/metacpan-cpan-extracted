package HTML::Strip::Whitespace;

use strict;
use warnings;

package HTML::Strip::Whitespace::State;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

sub to_array
{
    my $v = shift;
    return (ref($v) eq "ARRAY" ? (@$v) : $v);
}

sub initialize
{
    my $self = shift;
    my %args = (@_);
    $self->{'prev'} = undef;
    $self->{'next'} = undef;
    $self->{'this'} = undef;
    $self->{'parser'} =
        HTML::TokeParser::Simple->new(
            to_array($args{'parser_args'})
        );

    $self->{'strip_newlines'} = $args{'strip_newlines'} || 0;
    $self->{'out_fh'} = $args{'out_fh'};

    # Get the first element to initialize the parser
    # Otherwise the first call to next_state would return undef;
    $self->next_state();

    return 0;
}

sub next_state
{
    my $self = shift;
    ($self->{'prev'}, $self->{'this'}, $self->{'next'}) =
        ($self->{'this'}, $self->{'next'}, $self->{'parser'}->get_token());
    if (!defined($self->{'this'}))
    {
        return undef;
    }
    return 1;
}

sub prev
{
    my $self = shift;
    return $self->{'prev'};
}

sub next
{
    my $self = shift;
    return $self->{'next'};
}

sub this
{
    my $self = shift;
    return $self->{'this'};
}

sub text_strip
{
    my $self = shift;

    # my $p = $self->prev();
    # my $n = $self->next();

    my $text = $self->this()->as_is();

    $text =~ s{([\s\n]+)}{($1 =~ /\n/) ? "\n" : " "}eg;

    return $text;
}

my %preserving_start_tags =
(
    'pre' => 1,
);

sub is_preserving_start_tag
{
    my $self = shift;
    my $t = $self->this();
    if ($t->is_start_tag() &&
        exists($preserving_start_tags{$t->get_tag()})
       )
    {
        return $t->get_tag();
    }
    return undef;
}

sub handle_text
{
    my $state = shift;

    if ($state->this->is_text())
    {
        $state->out($state->text_strip());
        return 0;
    }
    else
    {
        return 1;
    }
}

sub out
{
    my $self = shift;
    my $what = shift;
    my $out_fh = $self->{'out_fh'};

    if (ref($out_fh) eq "CODE")
    {
        &{$out_fh}($what);
    }
    elsif (ref($out_fh) eq "SCALAR")
    {
        $$out_fh .= $what;
    }
    elsif (ref($out_fh) eq "GLOB")
    {
        print {*{$out_fh}} $what;
    }

    return 0;
}

sub out_this
{
    my $state = shift;
    $state->out($state->this()->as_is());
}

sub process
{
    my $state = shift;

    my $tag_type;

    while ($state->next_state())
    {
        if (! $state->handle_text())
        {
            # Text was handled
        }
        # If it's a preserving start tag, preserve all the text inside it.
        # This is for example, a <pre> tag in which the spaces matter.
        elsif ($tag_type = $state->is_preserving_start_tag())
        {
            my $do_once = 1;
            while ($do_once || $state->next_state())
            {
                $do_once = 0;
                $state->out_this();
                last if ($state->this()->is_end_tag($tag_type))
            }
        }
        else
        {
            $state->out_this();
        }
    }

    # Return 0 on success.
    return 0;
}

package HTML::Strip::Whitespace;

use 5.008;
use strict;
use warnings;

use HTML::TokeParser::Simple;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::Strip::Whitespace ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	html_strip_whitespace
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} });

@EXPORT = qw(

);

$VERSION = '0.1.8';

# Preloaded methods go here.

sub html_strip_whitespace
{
    my %args = (@_);
    my $source = $args{'source'} or
        die "source argument not specified.";
    my $strip_newlines = $args{'strip_newlines'} || 0;
    my $out_fh = $args{'out'} or
        die "out argument not specified.";
    my $state =
        HTML::Strip::Whitespace::State->new(
            'parser_args' => $source,
            'strip_newlines' => $strip_newlines,
            'out_fh' => $out_fh,
        );

    return $state->process();
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

HTML::Strip::Whitespace - Perl extension for stripping whitespace out of
HTML.

=head1 SYNOPSIS

    use HTML::Strip::Whitespace qw(html_strip_whitespace);

    my $html = <<"EOF";
    <html>
    <body>

    <p>
        Hello there!
    </p>

    </body>
    </html>
    EOF
    my $buffer = "";

    html_strip_whitespace(
        'source' => \$html,
        'out' => \$buffer
        );

=head1 DESCRIPTION

This module tries to strip as much whitespace from an HTML as it can
without eliminating valid whitespace (like the one inside <pre>).

To use it call the function C<HTML::Strip::Whitespace::html_strip_whitespace>,
with named parameters. C<source> is the HTML::TokeParser source for the
HTML. C<out> can be a reference to a buffer which will be filled with the
stripped HTML, or alternatively a reference to a sub-routine or a file handle
that will output it.

=head1 FUNCTIONS

=head2 html_strip_whitespace(source => $src, out => $out, strip_newlinews => $strip)

C<source> is the HTML::TokeParser source for the
HTML. C<out> can be a reference to a buffer which will be filled with the
stripped HTML, or alternatively a reference to a sub-routine or a file handle
that will output it.

=head1 LINKS

=over 4

=item * Homepage

L<http://web-cpan.shlomifish.org/modules/HTML-Strip-Whitespace/>

=item * Bitbucket.org (Mercurial) Repository

L<http://bitbucket.org/shlomif/perl-html-strip-whitespace>

=back

=head1 SEE ALSO

HTML Tidy with its Perl binding, which probably does a better and faster job
of performing this task.

L<HTML::Clean> is a module which also aims to optimise the size of HTML.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> (E-mail C<shlomif@cpan.org> ).

=head1 COPYRIGHT & LICENSE

Copyright 2004 by Shlomi Fish

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
