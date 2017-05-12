#!perl

use strict;
use warnings;
use EnvDir 'envdir', -clean;

my ($dir, @cmd) = @ARGV;

unless ( $dir and -d $dir ) {
    usage();
    exit 111;
}

shift @cmd if scalar @cmd and $cmd[0] eq '--';
if ( scalar @cmd == 0 ) {
    usage();
    exit 111;
}

my $guard = envdir($dir);
system(@cmd) == 0 or exit $?;

# functions
sub usage {
    warn "envdir.pl: usage: envdir dir child\n";
}

__END__

=encoding utf-8

=head1 NAME

envdir.pl - Perl implementation of envdir(8)

=head1 SYNOPSIS

envdir.pl dir child

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Yoshihiro Sasaki E<lt>ysasaki at cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yoshihiro Sasaki E<lt>ysasaki at cpan.orgE<gt>

=cut
