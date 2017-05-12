package Kwiki::PreformattedBlocks;
use Kwiki::Plugin -Base;
our $VERSION = '0.11';

const class_id => 'preformatted_blocks';

sub register {
    my $registry = shift;
    $registry->add(wafl => pre => 'Kwiki::PreformattedBlocks::Wafl');
}

package Kwiki::PreformattedBlocks::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    join '',
      qq{<pre class="formatter_pre">\n},
      $self->block_text,
      "</pre>\n";
}

__DATA__

=head1 NAME 

Kwiki::PreformattedBlocks - Kwiki Preformatted Blocks Plugin

=head1 SYNOPSIS

    .pre
    sub to_html {
        join '',
          qq{<pre class="formatter_pre">\n},
          $self->block_text,
          "</pre>\n";
    }
    .pre

=head1 DESCRIPTION

Mark blocks of preformatted text without indenting.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
