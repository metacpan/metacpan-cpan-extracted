package HTML::String::TT;

use strictures 1;

BEGIN {
    if ($INC{"Template.pm"} and !$INC{"UNIVERSAL/ref.pm"}) {
        warn "Template was loaded before we could load UNIVERSAL::ref"
             ." - this means you're probably going to get weird errors."
             ." To avoid this, use HTML::String::TT before loading Template."
    }
    require UNIVERSAL::ref;
}

use HTML::String;
use HTML::String::TT::Directive;
use Safe::Isa;
use Template;
use Template::Parser;
use Template::Stash;

BEGIN {
  my $orig_blessed = Template::Stash->can('blessed');
  no warnings 'redefine';
  *Template::Stash::blessed = sub ($) {
    my $val = $orig_blessed->($_[0]);
    return undef if defined($val) and $val eq 'HTML::String::Value';
    return $val;
  };
}

sub new {
    shift;
    Template->new(
        PARSER => Template::Parser->new(
            FACTORY => 'HTML::String::TT::Directive'
        ),
        STASH => Template::Stash->new,
        FILTERS => { no_escape => sub {
            $_[0]->$_isa('HTML::String::Value')
                ? HTML::String::Value->new(map $_->[0], @{$_[0]->{parts}})
                : HTML::String::Value->new($_)
        } },
        (ref($_[0]) eq 'HASH' ? %{$_[0]} : @_)
    );
}

1;

__END__

=head1 NAME

HTML::String::TT - HTML string auto-escaping for L<Template Toolkit|Template> 

=head1 SYNOPSIS

  my $tt = HTML::String::TT->new(\%normal_tt_args);

or, if you're using L<Catalyst::View::TT>:

  use HTML::String::TT; # needs to be loaded before TT to work

  __PACKAGE__->config(
    CLASS => 'HTML::String::TT',
  );

Then, in your template -

  <h1>
    [% title %] <-- this will be automatically escaped
  </h1>
  <div id="main">
    [% some_html | no_escape %] <-- this won't
  </div>
  [% html_var = '<foo>'; html_var %] <-- this won't anyway

(but note that the C<content> key in wrappers shouldn't need this).

=head1 DESCRIPTION

L<HTML::String::TT> is a wrapper for L<Template Toolkit|Template> that
installs the following overrides:

=over 4

=item * The directive generator is replaced with
L<HTML::String::TT::Directive> which ensures L<HTML::String::Overload> is
active for the template text.

=item * The stash is forced to be L<Template::Stash> since
L<Template::Stash::XS> gets utterly confused if you hand it an object.

=item * A filter C<no_escape> is added to mark outside data that you don't
want to be escaped.

=back

The override happens to B<all> of the plain strings in your template, so
even things declared within directives such as

  [% html_var = '<h1>' %]

will not be escaped, but any string coming from anywhere else will be. This
can be a little bit annoying when you then pass it to things that don't
respond well to overloaded objects, but is essential to L<HTML::String>'s
policy of "always fail closed" - I'd rather it throws an exception than
lets a value through unescaped, and if you care about your HTML not having
XSS (cross site scripting) vulnerabilities then I hope you'll agree.

We mark a number of TT internals namespaces as "don't escape when called by
these", since TT has a tendency to do things like

  open FH, "< $name";

which really don't work if it gets converted to C<&quot; $name> while you
aren't looking.

Additionally, since TT often calls C<ref> to decide e.g.
if something is a string or a glob, it's important that L<UNIVERSAL::ref>
is loaded before TT is. We check to see if the latter is loaded and the
former not, and warn loudly that you're probably going to get weird errors.

This warning is not joking. "Probably" is optimistic. Load this module first.

=head1 FILTERS

=head2 no_escape

The C<no_escape> filter marks the filtered input to not be escaped,
so that you can provide HTML chunks from externally and still render them
within the TT code.

=head1 AUTHORS

See L<HTML::String> for authors.

=head1 COPYRIGHT AND LICENSE

See L<HTML::String> for the copyright and license.

=cut
