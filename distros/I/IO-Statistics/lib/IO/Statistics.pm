package IO::Statistics;
use 5.008;
use strict;
use warnings;
use PerlIO::via::dynamic '0.10';
our $VERSION = '0.13';

=head1 NAME

IO::Statistics - Transparently perform statistics on IO handles

=head1 SYNOPSIS

 use IO::Statistics;

 my ($read, $write) = (0, 0);
 IO::Statistics->count (\$read, \$write, \*STDOUT);

 # alternatively:
 my $ios = IO::Statistics->new (\$read, \$write);
 $ios->via (\*STDOUT);

 print "fooo";
 print "bkzlfdlkf\n";

 END {
    print "read $read bytes read, wrote $write bytes\n";
 }

=head1 DESCRIPTION

This module allows you to count IO activity on a file handle transparently.

=cut

sub new {
    my ($class, $read, $write) = @_;
    my %map = (translate => $write, untranslate => $read);

    return PerlIO::via::dynamic->new
	( use_read => 1,
	  map { my $ref = $map{$_};
		$ref ? ($_ => sub { $$ref += length ($_[1])}) : ()
	    } keys %map);

}

sub count {
    my ($class, $read, $write, @handle) = @_;
    my $ios = $class->new ($read, $write);
    die "more than one handle not supported yet" if $#handle > 0;
    $ios->via ($_) for @handle;
}

=head1 BUGS

Using this IO layer on a global filehandle might result in segfault on
C<perl_destruct>.

=head1 TEST COVERAGE

 ----------------------------------- ------ ------ ------ ------ ------ ------
 File                                  stmt branch   cond    sub   time  total
 ----------------------------------- ------ ------ ------ ------ ------ ------
 blib/lib/IO/Statistics.pm            100.0  100.0    n/a  100.0  100.0  100.0
 Total                                100.0  100.0    n/a  100.0  100.0  100.0
 ----------------------------------- ------ ------ ------ ------ ------ ------

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
