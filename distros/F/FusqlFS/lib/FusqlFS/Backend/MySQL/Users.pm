use strict;
use 5.010;

package FusqlFS::Backend::MySQL::Users;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

our @USER_PRIVILEGES = (
    'Select'            ,
    'Insert'            ,
    'Update'            ,
    'Delete'            ,
    'Create'            ,
    'Drop'              ,
    'Reload'            ,
    'Shutdown'          ,
    'Process'           ,
    'File'              ,
    'Grant'             ,
    'References'        ,
    'Index'             ,
    'Alter'             ,
    'Show db'           ,
    'Super'             ,
    'Create tmp table'  ,
    'Lock tables'       ,
    'Execute'           ,
    'Repl slave'        ,
    'Repl client'       ,
    'Create view'       ,
    'Show view'         ,
    'Create routine'    ,
    'Alter routine'     ,
    'Create user'       ,
    'Event'             ,
    'Trigger'           ,
    'Create tablespace' ,
);
our @TABLE_PRIVILEGES = (
    'Select'      ,
    'Insert'      ,
    'Update'      ,
    'Delete'      ,
    'Create'      ,
    'Drop'        ,
    'Grant'       ,
    'References'  ,
    'Index'       ,
    'Alter'       ,
    'Create view' ,
    'Show view'   ,
    'Trigger'     ,
);
our @COLUMN_PRIVILEGES = (
    'Select'     ,
    'Insert'     ,
    'Update'     ,
    'References' ,
);
our @ROUTINE_PRIVILEGES = (
    'Execute'       ,
    'Alter routine' ,
    'Grant'         ,
);

sub init
{
    my $self = shift;
    $self->{list_expr} = $self->expr("SELECT CONCAT(User, '\@', Host) FROM mysql.user");
    $self->{get_expr} = $self->expr("SELECT * FROM mysql.user WHERE User = ? AND Host = ?");
    $self->{create_expr} = q{CREATE USER '%(User)$s'@'%(Host)$s'};
    $self->{drop_expr} = q{DROP USER '%(User)$s'@'%(Host)$s'};
    $self->{rename_expr} = q{RENAME USER '%(User)$s'@'%(Host)$s' TO '%(NewUser)$s'@'%(NewHost)$s'};
}

sub list
{
    my $self = shift;
    return $self->all_col($self->{list_expr})||[];
}

sub get
{
    my $self = shift;
    my ($user, $host) = split(/@/, shift, 2);
    return unless $user || $host;

    my $data = $self->one_row($self->{get_expr}, $user, $host);
    return unless $data;

    my @privileges = ();
    my %result = ();
    while (my ($name, $value) = each %$data) {
        if ($name =~ /_priv$/) {
            $name =~ s/_priv$//;
            $name =~ s/_/ /g;
            push @privileges, $name if $value == 'Y';
        } else {
            $result{$name} = $value;
        }
    }
    $result{privileges} = \@privileges;

    return $self->dump(\%result);
}

sub create
{
    my $self = shift;
    my ($user, $host) = split(/@/, shift, 2);
    return unless $user || $host;

    $self->do($self->{create_expr}, {User => $user, Host => $host});
}

sub drop
{
    my $self = shift;
    my ($user, $host) = split(/@/, shift, 2);
    return unless $user || $host;

    $self->do($self->{drop_expr}, {User => $user, Host => $host});
}

sub rename
{
    my $self = shift;
    my ($user, $host) = split(/@/, shift, 2);
    my ($newuser, $newhost) = split(/@/, shift, 2);

    $self->do($self->{rename_expr}, {User => $user, Host => $host, NewUser => $newuser, NewHost => $newhost});
}

sub store
{
    my $self = shift;
    my ($user, $host) = split(/@/, shift, 2);
    return unless $user || $host;

    my $priv_re = join('|', @USER_PRIVILEGES);
    $priv_re = qr/^$priv_re$/i;

    my $data = $self->validate(shift, {
        max_connections      => qr/^\d+$/,
        max_questions        => qr/^\d+$/,
        max_updates          => qr/^\d+$/,
        max_user_connections => qr/^\d+$/,
        priviledges          => ['ARRAY', sub{ [ grep { $_ =~ $priv_re } @$_ ] }],
    }) or return;

    $data->{User} = $user;
    $data->{Host} = $host;
    $data->{privileges} = join ',', @{$data->{privileges}};

    $self->do(q{REVOKE ALL ON *.* FROM '%(User)$s'@'%(Host)$s'}, {User => $user, Host => $host});
    $self->do(q{GRANT %(privileges)$s ON *.* TO '%(User)$s'@'%(Host)$s' WITH MAX_QUERIES_PER_HOUR %(max_questions)$d MAX_UPDATES_PER_HOUR %(max_updates)$d MAX_CONNECTIONS_PER_HOUR %(max_connections)$d MAX_USER_CONNECTIONS %(max_user_connections)$d}, $data);
}

__END__

