package Devel::FindAmpersand;

use strict;
use B::FindAmpersand ();

END {
    B::FindAmpersand::compile()->();
}

1;

__END__

=head1 NAME

Devel::FindAmpersand - Report exactly where Perl sawampersand

=head1 SYNOPSIS

    use Devel::FindAmpersand ();

=head1 DESCRIPTION

Use this module only during development and wait for your script to
finish. It will report where your script gets infected by a
sawampersand operation.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

Devel::SawAmpersand, B::FindAmpersand

