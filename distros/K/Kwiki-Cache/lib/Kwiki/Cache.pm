package Kwiki::Cache;
use Kwiki::Plugin -Base;
use Digest::MD5;
our $VERSION = '0.11';

const class_id => 'cache';
const class_title => 'Generic Cache';

sub process {
    my $closure = shift;
    my $cache_name = Digest::MD5::md5_hex(join '!@#$', @_);
    my $path = $self->plugin_directory;
    my $io = io->catfile($path, $cache_name)->assert;
    unless ($io->exists) {
        $io->lock->mode('>>')->open;
        if ($io->empty) {
            $io->print(&$closure);
        }
        $io->close;
    }
    $io->scalar;
}

__DATA__

=head1 NAME 

Kwiki::Cache - Kwiki Cache Plugin

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
