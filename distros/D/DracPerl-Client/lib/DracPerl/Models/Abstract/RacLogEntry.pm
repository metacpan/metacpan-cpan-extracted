package DracPerl::Models::Abstract::RacLogEntry;
use XML::Rabbit;

has_xpath_value 'source'          => './source';
has_xpath_value 'date_time'       => './dateTime';
has_xpath_value 'id' => './dateTimeOrder';
has_xpath_value 'description'     => './description';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::RacLogEntry - Model for Remot Access Controller log entry

=head1 ATTRIBUTES

=head2 source

The source responsible for creating the entry

eg : 'idrac_discovery[1572]'
eg : 'os[123]'
eg : 'fullfw[485]'

=head2 date_time

The date time of the log entry in the format : 
'YYYY Mon  DD HH:MM:SS'

eg : '2016 Nov  1 21:26:40'

=head2 id

An auto incremented ID, used for the order of logs
eg '00002'

=head2 description

The text of the log entry

eg : 'Power Supply 1: CRC error detected'

=cut