package HTML::Template::Compiled::Plugin::LineBreak;

# $Id: LineBreak.pm 25 2008-03-10 12:00:34Z hagy $

use strict;
use warnings;
our $VERSION = '0.02';

HTML::Template::Compiled->register(__PACKAGE__);

sub register {
    my ($class) = @_;
    my %plugs = (
        escape => {
            LINEBREAK => \&html_line_break,
            BR        => \&html_line_break,
        },
    );
    return \%plugs;
}

sub html_line_break {
    local $_  = shift;

    defined or return;

#   s|(\r?\n)|<br />$1|g;
    s|\x0D\x0A|<br />\r\n|g and return $_;  # for \r\n  CRLF    WIN
    s|\x0D|<br />\r|g       and return $_;  # for \r    CR      MAC
    s|\x0A|<br />\n|g       and return $_;  # for \n    LF      UNIX
    return $_;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HTML::Template::Compiled::Plugin::LineBreak
        - HTC Plugin to replaces any newlines with <br> HTML tags.

=head1 SYNOPSIS

  use HTML::Template::Compiled::Plugin::LineBreak;
  my $htc = HTML::Template::Compiled->new(
      plugin => [qw(HTML::Template::Compiled::Plugin::LineBreak)],
      ...
  );
  $htc->param( note => "foo1\nfoo2\n" );
  $htc->output;
  ---
      
      <TMPL_VAR note ESCAPE=BR>

      # Output:
      # foo1<br>
      # foo2<br>

      have the same effect
      <TMPL_VAR note ESCAPE=LINEBREAK>

=head1 DESCRIPTION

HTML::Template::Compiled::Plugin::LineBreak is a plugin for HTC, which 
allows you to replaces any newlines with E<lt>brE<gt> HTML tags, thus 
preserving the line breaks of the original text in the HTML output.
This would be especially useful for multiline message.

=head1 METHODS

register 
    gets called by HTC

=head1 SEE ALSO

C<HTML::Template::Compiled>

=head1 AUTHOR

hagy E<lt>hagy@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by hagy E<lt>hagy@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
