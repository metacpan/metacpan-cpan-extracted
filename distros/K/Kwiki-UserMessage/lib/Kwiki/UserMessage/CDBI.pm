package Kwiki::UserMessage::CDBI;
use base 'Class::DBI';
use CLASS;

CLASS->table("user_message");
CLASS->columns(Primary => "id");
CLASS->columns(Others  => qw(sender receiver ts subject body));

CLASS->set_sql(create_table => "CREATE TABLE user_message (id INTEGER PRIMARY KEY, sender, receiver, ts, subject, body)");

sub dbinit {
    my ($self) = @_;
    my $sth = $self->sql_create_table;
    $sth->execute;
}


1;
