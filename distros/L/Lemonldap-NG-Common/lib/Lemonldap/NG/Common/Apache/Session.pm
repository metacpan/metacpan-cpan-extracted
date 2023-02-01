## @file
# Add get_key_from_all_sessions() function to Apache::Session modules.
# This file is used by Lemonldap::NG::Manager::Status and by the
# purgeCentralCache script.
#
# Warning, this works only with SQL databases, simple or Berkeley files (not
# for Apache::Session::Memcached for example)
package Lemonldap::NG::Common::Apache::Session;

use strict;
use AutoLoader 'AUTOLOAD';
use Apache::Session;
use base qw(Apache::Session);
use Lemonldap::NG::Common::Apache::Session::Serialize::JSON;
use Lemonldap::NG::Common::Apache::Session::Store;
use Lemonldap::NG::Common::Apache::Session::Lock;

our $VERSION = '2.0.6';

sub _load {
    my ( $backend, $func ) = @_;
    unless ( $backend->can('populate') ) {
        eval "require $backend";
        die $@ if ($@);
    }
    return $func ? $backend->can($func) : 0;
}

sub populate {
    my $self    = shift;
    my $backend = $self->{args}->{backend};
    _load($backend);
    $backend .= "::populate";
    {
        no strict 'refs';
        $self = $self->$backend(@_);
    }
    if ( $backend =~
/^Apache::Session::(?:(?:Postgre|Redi)s|S(?:QLite3|ybase)|(?:My|No)SQL|F(?:ile|lex)|Cassandra|Oracle|LDAP)/
        and !$self->{args}->{useStorable} )
    {
        $self->{serialize} =
          \&Lemonldap::NG::Common::Apache::Session::Serialize::JSON::serialize;
        $self->{unserialize} =
          \&Lemonldap::NG::Common::Apache::Session::Serialize::JSON::unserialize;
        if ( $backend =~ /^Apache::Session::LDAP/ ) {
            $self->{unserialize} =
              \&Lemonldap::NG::Common::Apache::Session::Serialize::JSON::unserializeBase64;
        }
    }
    if ( $self->{args}->{generateModule} ) {
        my $generate = $self->{args}->{generateModule};
        eval "require $generate";
        die $@ if ($@);
        $self->{generate} = \&{ $generate . "::generate" };
        $self->{validate} = \&{ $generate . "::validate" };
    }
    if ( $self->{args}->{setId} ) {
        $self->{generate} = \&setId;
        $self->{validate} = sub { 1 };
    }

    # If cache is configured, use our specific object store module
    if ( $> and $self->{args}->{localStorage} ) {
        $self->{args}->{object_store} = $self->{object_store};
        $self->{object_store} =
          Lemonldap::NG::Common::Apache::Session::Store->new($self);
        $self->{args}->{lock_manager} = $self->{lock_manager};
        $self->{lock_manager} =
          Lemonldap::NG::Common::Apache::Session::Lock->new($self);
    }
    return $self;
}

__END__

sub setId {
    my $session = shift;
    $session->{data}->{_session_id} = $session->{args}->{setId};
}

sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = splice @_;
    unless ( $args->{backend} ) {
        die "SearchOn called without backend. " . join( ', ', caller(0) );
    }

    return $args->{backend}->searchOn( $args, $selectField, $value, @fields )
      if ( _load( $args->{backend}, 'searchOn' ) );
    my %res = ();
    $class->get_key_from_all_sessions(
        $args,
        sub {
            my $entry = shift;
            my $id    = shift;
            return undef
              unless ( $entry->{$selectField}
                and $entry->{$selectField} eq $value );
            if (@fields) {
                $res{$id}->{$_} = $entry->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $entry;
            }
            undef;
        }
    );
    return \%res;
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = splice @_;
    return $args->{backend}
      ->searchOnExpr( $args, $selectField, $value, @fields )
      if ( _load( $args->{backend}, 'searchOnExpr' ) );
    $value = quotemeta($value);
    $value =~ s/\\\*/\.\*/g;
    $value = qr/^$value$/;
    my %res = ();
    $class->get_key_from_all_sessions(
        $args,
        sub {
            my $entry = shift;
            my $id    = shift;
            return undef unless ( $entry->{$selectField} =~ $value );
            if (@fields) {
                $res{$id}->{$_} = $entry->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $entry;
            }
            undef;
        }
    );
    return \%res;
}

sub searchLt {
    my ( $class, $args, $selectField, $value, @fields ) = splice @_;
    return $args->{backend}->searchLt( $args, $selectField, $value, @fields )
      if ( _load( $args->{backend}, 'searchLt' ) );
    my %res = ();
    $class->get_key_from_all_sessions(
        $args,
        sub {
            my $entry = shift;
            my $id    = shift;
            return undef unless ( $entry->{$selectField} < $value );
            if (@fields) {
                $res{$id}->{$_} = $entry->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $entry;
            }
            undef;
        }
    );
    return \%res;
}

sub get_key_from_all_sessions {
    my $class = shift;

    my ( $args, $data ) = @_;
    my $backend = $args->{backend};
    if ( _load( $backend, 'get_key_from_all_sessions' ) ) {
        return $backend->get_key_from_all_sessions( $args, $data );
    }
    if ( $args->{useStorable} ) {
        require Storable;
        $args->{unserialize} = \&Storable::thaw;
    }
    else {
        $args->{unserialize} =
          \&Lemonldap::NG::Common::Apache::Session::Serialize::JSON::_unserialize;
    }

    # For now, Apache::Session::MariaDB doesn't exists.
    # Apache::Session::Browseable::MariaDB has its own get_key_from_all_sessions
    if ( $backend =~
/^Apache::Session::(SQLite\d?|MySQL|MySQL::NoLock|Postgres|Oracle|Sybase|Informix)$/
      )
    {
        return $class->_dbiGKFAS( $1, @_ );
    }
    elsif ( $backend =~ /^Apache::Session::(File|PHP|DBFile|LDAP)$/ ) {
        no strict 'refs';
        my $tmp = "_${1}GKFAS";
        return $class->$tmp(@_);
    }
    else {
        die "$backend can not provide session exploration";
    }
}

sub decodeThaw64 {
    require MIME::Base64;
    my $s = shift;
    return Storable::thaw( MIME::Base64::decode_base64($s) );
}

sub _dbiGKFAS {
    my ( $class, $type, $args, $data ) = @_;
    my $next;
    if ( $type !~ /(?:MySQL)/ ) {
        $next = \&decodeThaw64;
        if ( $args->{useStorable} ) {
            $args->{unserialize} = $next;
        }
    }

    my $dbh =
      DBI->connect( $args->{DataSource}, $args->{UserName}, $args->{Password} )
      or die("$!$@");
    my $sth = $dbh->prepare('SELECT id,a_session from sessions');
    $sth->execute;
    my %res;
    while ( my @row = $sth->fetchrow_array ) {
        eval {
            if ( ref($data) eq 'CODE' ) {
                my $tmp =
                  &$data( $args->{unserialize}->( $row[1], $next ), $row[0] );
                $res{ $row[0] } = $tmp if ( defined($tmp) );
            }
            elsif ($data) {
                $data = [$data] unless ( ref($data) );
                my $tmp = $args->{unserialize}->( $row[1], $next );
                $res{ $row[0] }->{$_} = $tmp->{$_} foreach (@$data);
            }
            else {
                $res{ $row[0] } = $args->{unserialize}->( $row[1], $next );
            }
        };
        if ($@) {
            print STDERR "Error in session $row[0]\n";
            delete $res{ $row[0] };
        }
    }
    return \%res;
}

sub _FileGKFAS {
    my ( $class, $args, $data ) = @_;
    $args->{Directory} ||= '/tmp';

    unless ( opendir DIR, $args->{Directory} ) {
        die "Cannot open directory $args->{Directory}\n";
    }
    my @t =
      grep { -f "$args->{Directory}/$_" and /^[A-Za-z0-9@\-]+$/ } readdir(DIR);
    closedir DIR;
    my %res;
    for my $f (@t) {
        open F, '<', "$args->{Directory}/$f";
        eval {
            my $row = join '', <F>;
            if ( ref($data) eq 'CODE' ) {
                eval { $res{$f} = &$data( $args->{unserialize}->($row), $f ); };
                if ($@) {
                    $res{$f} = &$data( undef, $f );
                }
            }
            elsif ($data) {
                $data = [$data] unless ( ref($data) );
                my $tmp;
                eval { $tmp = $args->{unserialize}->($row); };
                if ($@) {
                    $res{$f}->{$_} = undef foreach (@$data);
                }
                else {
                    $res{$f}->{$_} = $tmp->{$_} foreach (@$data);
                }
            }
            else {
                eval { $res{$f} = $args->{unserialize}->($row); };
            }
        };
        if ($@) {
            print STDERR "Error in session $f\n";
            delete $res{$f};
        }
    }
    return \%res;
}

sub _PHPGKFAS {
    require Apache::Session::Serialize::PHP;
    my ( $class, $args, $data ) = @_;

    my $directory = $args->{SavePath} || '/tmp';
    unless ( opendir DIR, $args->{SavePath} ) {
        die "Cannot open directory $args->{SavePath}\n";
    }
    my @t =
      grep { -f "$args->{SavePath}/$_" and /^sess_[A-Za-z0-9@\-]+$/ }
      readdir(DIR);
    closedir DIR;
    my %res;
    for my $f (@t) {
        open F, '<', "$args->{SavePath}/$f";
        my $row = join '', <F>;
        if ( ref($data) eq 'CODE' ) {
            $res{$f} =
              &$data( Apache::Session::Serialize::PHP::unserialize($row), $f );
        }
        elsif ($data) {
            $data = [$data] unless ( ref($data) );
            my $tmp = Apache::Session::Serialize::PHP::unserialize($row);
            $res{$f}->{$_} = $tmp->{$_} foreach (@$data);
        }
        else {
            $res{$f} = Apache::Session::Serialize::PHP::unserialize($row);
        }
    }
    return \%res;
}

sub _DBFileGKFAS {
    my ( $class, $args, $data ) = @_;

    if ( !tied %{ $class->{dbm} } ) {
        my $rv = tie %{ $class->{dbm} }, 'DB_File', $args->{FileName};
        if ( !$rv ) {
            die "Could not open dbm file " . $args->{FileName} . ": $!";
        }
    }

    my %res;
    foreach my $k ( keys %{ $class->{dbm} } ) {
        eval {
            if ( ref($data) eq 'CODE' ) {
                $res{$k} =
                  &$data( $args->{unserialize}->( $class->{dbm}->{$k} ), $k );
            }
            elsif ($data) {
                $data = [$data] unless ( ref($data) );
                my $tmp = $args->{unserialize}->( $class->{dbm}->{$k} );
                $res{$k}->{$_} = $tmp->{$_} foreach (@$data);
            }
            else {
                $res{$k} = $args->{unserialize}->( $class->{dbm}->{$k} );
            }
        };
        if ($@) {
            print STDERR "Error in session $k\n";
            delete $res{$k};
        }
    }
    return \%res;
}

sub _LDAPGKFAS {
    my ( $class, $args, $data ) = @_;
    $args->{ldapObjectClass}      ||= 'applicationProcess';
    $args->{ldapAttributeId}      ||= 'cn';
    $args->{ldapAttributeContent} ||= 'description';

    my $ldap = Apache::Session::Store::LDAP::ldap( { args => $args } );
    my $msg  = $ldap->search(
        base   => $args->{ldapConfBase},
        filter => '(objectClass=' . $args->{ldapObjectClass} . ')',
        attrs  => [ $args->{ldapAttributeId}, $args->{ldapAttributeContent} ],
    );

    $ldap->unbind();
    $ldap->disconnect();

    Apache::Session::Store::LDAP->logError($msg) if ( $msg->code );

    my %res;

    foreach my $entry ( $msg->entries ) {
        my ( $k, $v ) = (
            $entry->get_value( $args->{ldapAttributeId} ),
            $entry->get_value( $args->{ldapAttributeContent} )
        );
        eval { $v = $args->{unserialize}->( $v, \&decodeThaw64 ); };
        next if ($@);
        if ( ref($data) eq 'CODE' ) {
            $res{$k} = &$data( $v, $k );
        }
        elsif ($data) {
            $data = [$data] unless ( ref($data) );
            my $tmp = $v;
            $res{$k}->{$_} = $tmp->{$_} foreach (@$data);
        }
        else {
            $res{$k} = $v;
        }
    }
    return \%res;
}

1;
