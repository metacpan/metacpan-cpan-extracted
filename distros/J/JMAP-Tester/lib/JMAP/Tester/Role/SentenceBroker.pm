package JMAP::Tester::Role::SentenceBroker;
$JMAP::Tester::Role::SentenceBroker::VERSION = '0.018';
use Moo::Role;

requires 'client_ids_for_items';
requires 'sentence_for_item';
requires 'paragraph_for_items';

requires 'strip_json_types';

requires 'abort_callback';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Role::SentenceBroker

=head1 VERSION

version 0.018

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
