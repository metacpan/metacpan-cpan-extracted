package FreePAN::Plugin;
use Spoon::Plugin -Base;
our $VERSION = '0.01';
const class_title_prefix => 'FreePAN';
use Cwd qw(abs_path);
sub plugin_directory {
    abs_path($self->hub->config->base . '/' . super);
}

__END__

=head1 NAME

FreePAN::Plugin - FreePAN Plugin base

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
