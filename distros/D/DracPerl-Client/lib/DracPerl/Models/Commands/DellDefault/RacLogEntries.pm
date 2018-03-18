package DracPerl::Models::Commands::DellDefault::RacLogEntries;
use XML::Rabbit::Root;

has_xpath_object_list 'list' => '/root/racLogEntries/racLogEntry' =>
    'DracPerl::Models::Abstract::RacLogEntry';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::DellDefault::RacLogEntries - Return all log entries of the Remote Access Controller (RAC)

=head1 ATTRIBUTES

=head2 list

An array of L<DracPerl::Models::Abstract::RacLogEntry>

=cut