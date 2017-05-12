package JMAP::Tester::Logger::Null;
$JMAP::Tester::Logger::Null::VERSION = '0.014';
use Moo;
with 'JMAP::Tester::Logger';

use namespace::clean;

sub log_jmap_request  {}
sub log_jmap_response {}

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

version 0.014

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
