package HTML::Template::Compiled::Plugin::Comma;

# $Id: Comma.pm 3 2007-07-08 07:06:51Z hagy $

use strict;
use warnings;
our $VERSION = '0.01';

HTML::Template::Compiled->register(__PACKAGE__);

sub register {
    my ($class) = @_;
    my %plugs = (
        escape => {
            COMMA => \&commify,
        },
    );
    return \%plugs;
}

sub commify {
    local $_  = shift;
    1 while s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
    return $_;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HTML::Template::Compiled::Plugin::Comma - HTC Plugin to commify numbers

=head1 SYNOPSIS

  use HTML::Template::Compiled::Plugin::Comma;
  my $htc = HTML::Template::Compiled->new(
      plugin => [qw(HTML::Template::Compiled::Plugin::Comma)],
      ...
  );
  $htc->param( costs => 10000 );
  $htc->output;
  ---
      
      This item costs <TMPL_VAR costs ESCAPE=COMMA> dollar.

      # Output:
      # This item costs 10,000 dollar.
      
=head1 DESCRIPTION

HTML::Template::Compiled::Plugin::Comma is a plugin for HTC, which allows
you to commify your numbers in templates. This would be especially useful
for prices.

=head1 METHODS

register 
    gets called by HTC

=head1 SEE ALSO

C<HTML::Template::Compiled>, "perldoc -q comma"

=head1 AUTHOR

hagy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by hagy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
