package Kwiki::Autoformat;
use strict;
use warnings;

use Kwiki::Plugin -Base;
use Kwiki::Installer -mixin;

our $VERSION = 0.03;

const class_title => 'Text autoformat';
const class_id => 'autoformat';

sub register {
    my $registry = shift;
    $registry->add(wafl => auto => 'Kwiki::Autoformat::Wafl');
    $registry->add(wafl => autoformat => 'Kwiki::Autoformat::Wafl');
}

package Kwiki::Autoformat::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    require Text::Autoformat;
    my $text = Text::Autoformat::autoformat($self->block_text);
    $text =~ s/\n+//s;
    return "<pre>$text</pre>";
}

package Kwiki::Autoformat;

__DATA__

=head1 NAME 

Kwiki::Autoformat - Autoformat preformatted text

=head1 SYNOPSIS

 $ cpan Kwiki::Autoformat
 $ cd /path/to/kwiki
 $ echo "Kwiki::Autoformat" >> plugins
 $ kwiki -update

=head1 DESCRIPTION

This formats preformatted text using Damian Conway's magical L<Text::Autoformat> with the default options:

    .auto
    In comp.lang.perl.misc you wrote:
    : > <CN = Clooless Noobie> writes:
    : > CN> PERL sux because:
    : > CN>    * It doesn't have a switch statement and you have to put $
    : > CN>signs in front of everything
    : > ...
    .auto

=head1 AUTHORS

Ian Langworth <langworth.com>

=head1 SEE ALSO

L<Kwiki>, L<Text::Autoformat>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
