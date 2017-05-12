package HTML::String::Overload;

use strictures 1;
use HTML::String::Value;
use B::Hooks::EndOfScope;
use overload ();

sub import {
    my ($class, @opts) = @_;
    overload::constant q => sub {
        HTML::String::Value->new($_[1], @opts);
    };
    on_scope_end { __PACKAGE__->unimport };
}

sub unimport {
    overload::remove_constant('q');
}

1;

__END__

=head1 NAME

HTML::String::Overload - Use constant overloading with L<HTML::String>

=head1 SYNOPSIS

  use HTML::String::Overload;
  
  my $html = '<h1>'; # marked as HTML
  
  no HTML::String::Overload;

  my $text = '<h1>'; # not touched
  
  my $html = do {
    use HTML::String::Overload;
  
    '<h1>'; # marked as HTML
  };
  
  my $text = '<h1>'; # not touched

=head1 DESCRIPTION

This module installs a constant overload for strings - see
L<overload/Overloading constants> in overload.pm's docs for how that works.

On import, we both set up the overload, and use L<B::Hooks::EndOfScope> to
register a callback that will remove it again at the end of the block; you
can remove it earlier by unimporting the module using C<no>.

=head1 CAVEATS

Due to a perl bug (L<https://rt.perl.org/rt3/Ticket/Display.html?id=49594>),
you can't use backslash escapes in a string to be marked as HTML, so

  use HTML::String::Overload;
  
  my $html = "<h1>\n<div>foo</div>\n</h1>";

will not be marked as HTML - instead you need to write

  my $html = '<h1>'."\n".'<div>foo</div>'."\n".'</h1>';

which is annoying, so consider just using L<HTML::String> and doing

  my $html = html("<h1>\n<div>foo</div>\n</h1>");

in that case.

The import method we provide does actually take extra options for constructing
your L<HTML::String::Value> objects but I'm not yet convinced that's a correct
public API, so use that feature at your own risk (the only example of this is
in L<HTML::String::TT::Directive>, which is definitely not user serviceable).

=head1 AUTHORS

See L<HTML::String> for authors.

=head1 COPYRIGHT AND LICENSE

See L<HTML::String> for the copyright and license.

=cut
