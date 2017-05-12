package Kwiki::HtmlBlocks;
use Kwiki::Plugin -Base;
our $VERSION = '0.11';

const class_id => 'html_blocks';

sub register {
    my $registry = shift;
    $registry->add(wafl => html => 'Kwiki::HtmlBlocks::Wafl');
}

package Kwiki::HtmlBlocks::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    $self->block_text;
}

__DATA__

=head1 NAME 

Kwiki::HtmlBlocks - Kwiki HTML Blocks Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
