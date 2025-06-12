use v5.14.0;
package JMAP::Tester::Logger::Null 0.104;

use Moo;
with 'JMAP::Tester::Logger';

use namespace::clean;

sub log_jmap_request  {}
sub log_jmap_response {}

sub log_misc_request  {}
sub log_misc_response {}

sub log_upload_request  {}
sub log_upload_response {}

sub log_download_request  {}
sub log_download_response {}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Logger::Null

=head1 VERSION

version 0.104

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
