package DracPerl::Models::Abstract::EventLogEntry;
use XML::Rabbit;

has_xpath_value 'severity'        => './severity';
has_xpath_value 'date_time'       => './dateTime';
has_xpath_value 'date_time_order' => './dateTimeOrder';
has_xpath_value 'description'     => './description';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::EventLogEntry - Model for log entry

=head1 ATTRIBUTES

=head2 severity

The severity of the log entry, 'Normal'/'Critical'

=head2 date_time

The date time of the log entry in the format : 
'Day Mon DD YYYY HH:MM:SS'
eg : 'Sun Aug 14 2016 14:06:09'

=head2 date_time_order

The date time of the log entry with additional precision for ordering
Under the format : 
'YYYYMMDDHHMMSS.XXXXXX'
eg '20160814140609.000000'

=head2 description

The text of the log entry

eg : 'Drive 3 is installed'

=cut