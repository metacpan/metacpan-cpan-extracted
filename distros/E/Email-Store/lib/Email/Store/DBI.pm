package Email::Store::DBI;
use base 'Class::DBI';
require Class::DBI::DATA::Schema;

sub import { 
    my ($self, @params) = @_; 
    if (@params) {
        $self->set_db(Main => @params);
        $self->translate(mysql => $self->__driver);
        if ($self->__driver =~ /SQLite/) {
            $self->db_Main->{sqlite_handle_binary_nulls} = 1;
        }
    }
}

my %map = ( # Why SQL::Translator doesn't provide this I don't know
    mysql => "MySQL",
    Pg    => "PostgresQL"
);

sub translate {
    my ($self, $from, $to) = @_;
    $from = exists $map{$from} ? $map{$from} : $from;
    $to   = exists $map{$to}   ? $map{$to}   : $to;
    Class::DBI::DATA::Schema->import(
        ($from eq $to) ? () :
            (translate => [$from => $to ],
             cache => "emailstore_sqlcache"
            )
    );
}

1;

=head1 NAME

Email::Store::DBI - Database backend to Email::Store

=head1 DESCRIPTION

This class is a subclass of L<Class::DBI> and contains means for
C<Email::Store>-based programs to register what DSN they wish to use. It
also provides for building database tables from schemas embedded in the
DATA section of plug-in modules, using L<Class::DBI::DATA::Schema>.

=cut
