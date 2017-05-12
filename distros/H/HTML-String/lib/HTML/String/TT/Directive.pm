package HTML::String::TT::Directive;

use strictures 1;
use HTML::String::Overload ();
use Data::Munge;
use B qw(perlstring);
use base qw(Template::Directive);

sub template {
    return byval {
        s/sub {/sub { package HTML::String::TT::_TMPL; use HTML::String::Overload { ignore => { q{Template::Provider} => 1, q{Template::Directive} => 1, q{Template::Document} => 1, q{Template::Plugins} => 1 } };/;
    } Template::Directive::pad(shift->SUPER::template(@_), 2);
}

# TT code does &text(), no idea why

sub textblock {
    my ($self, $text) = @_;
    return $Template::Directive::OUTPUT.' '.$self->text($text).';';
}

# https://rt.perl.org/rt3/Ticket/Display.html?id=49594

sub text {
    my ($class, $text) = @_;

    # We need to turn everything into escapes, including wide chars
    # that will end up as e.g. \342\200\223 if 'use utf8' isn't in
    # scope or \x{...} if it is. So we run it through perlstring first
    # so everything is already a backslash escape sequence (because the
    # exact same bug can apply to wide chars in place), and then hit
    # it with an ugly regexp to turn it into e.g.
    #
    #   "<li>foo "."\342".""."\200".""."\223"." bar.</li>"
    #
    # which then gets overload::constant'ed appropriately.

    # The first two lines of the s! were assembled from the escape sequences
    # table in "Quote and Quote-like Operators" in perlop by Lucas Mai, then
    # the . handles any other single character escape (\$, \@, \\ etc.)

    my $str = perlstring $text;
    $str =~ s!
      \\ ( [abefnrt] | c. | o \{ [0-7]+ \} | x (?: \{ [[:xdigit:]]+ \}
           | [[:xdigit:]]{1,2} ) | N \{ [^{}]* \} | [0-7]{1,3}
           | . )
      !"."\\$1"."!xg;

    return $str;
}

1;

__END__

=head1 NAME

HTML::String::TT::Directive - L<Template::Directive> overrides to forcibly escape HTML strings

=head1 SYNOPSIS

This is not user serviceable, and is documented only for your edification.

Please use L<HTML::String::TT> as this module could change, be renamed, or
if I figure out a better way of implementing the functionality disappear
entirely at any moment.

=head1 METHODS

=head2 template

We override this top-level method in order to pretend two things to the
perl subroutine definition that TT has generated - firstly,

  package HTML::String::TT::_TMPL;

to ensure that no packages marked to be ignored are the current one when
the template code is executed. Secondly,

  use HTML::String::Overload { ignore => { ... } };

where the C<...> contains a list of TT internal packages to ignore so that
things actually work. This list is not duplicated here since it may also
change without warning.

Additionally, the hashref option to L<HTML::String::Overload> is not
documented there since I'm not yet convinced that's a public API either.

=head2 text

Due to a perl bug (L<https://rt.perl.org/rt3/Ticket/Display.html?id=49594>)
we overload this method to change

  "<foo>\n<bar>"

into

  "<foo>"."\n"."<bar>"

since any string containing a backslash escape doesn't get marked as HTML.
Since we don't want to escape things that backslash escapes are normally
used for, this isn't really a problem for us.

=head2 textblock

For no reason I can comprehend at all, L<Template::Directive>'s C<textblock>
method calls C<&text> instead of using a method call so we have to override
this as well.

=head1 AUTHORS

See L<HTML::String> for authors.

=head1 COPYRIGHT AND LICENSE

See L<HTML::String> for the copyright and license.

=cut
