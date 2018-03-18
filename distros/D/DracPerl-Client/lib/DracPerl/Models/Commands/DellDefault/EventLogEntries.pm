package DracPerl::Models::Commands::DellDefault::EventLogEntries;
use XML::Rabbit::Root;

has_xpath_object_list 'list' => '/root/eventLogEntries/eventLogEntry' =>
    'DracPerl::Models::Abstract::EventLogEntry';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::DellDefault::EventLogEntries - Return each system log entry

=head1 ATTRIBUTES

=head2 list

An array of L<DracPerl::Models::Abstract::EventLogEntry>

=cut