package FreePAN::Template;
use Spoon::Template::TT2 -Base;
our $VERSION = '0.01';

sub template_path {
    [$self->hub->config->base . '/templates']
}

sub compile_dir {
    $self->hub->config->base . '/plugin/template/cache';
}

__END__

=head1 NAME

FreePAN::Template - FreePAN Template

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
