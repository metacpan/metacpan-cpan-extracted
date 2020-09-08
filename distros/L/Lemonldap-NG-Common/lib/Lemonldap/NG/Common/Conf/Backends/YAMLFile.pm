package Lemonldap::NG::Common::Conf::Backends::YAMLFile;

use strict;
use Lemonldap::NG::Common::Conf::Constants;    #inherits
use YAML qw();
use Encode;

our $VERSION = '2.0.9';
our $initDone;
$YAML::Numify = 1;

sub Lemonldap::NG::Common::Conf::_yamlLock {
    my ( $self, $cfgNum ) = @_;
    return "$self->{dirName}/lmConf.yamlLock";
}

sub Lemonldap::NG::Common::Conf::_yamlFile {
    my ( $self, $cfgNum ) = @_;
    return "$self->{dirName}/lmConf-$cfgNum.yaml";
}

sub prereq {
    my $self = shift;
    unless ( $self->{dirName} ) {
        $Lemonldap::NG::Common::Conf::msg .=
          "'dirName' is required in 'File' configuration type ! \n";
        return 0;
    }
    unless ( -d $self->{dirName} ) {
        $Lemonldap::NG::Common::Conf::msg .=
          "Directory \"$self->{dirName}\" does not exist ! \n";
        return 0;
    }
    1;
}

sub available {
    my $self = shift;
    opendir D, $self->{dirName};
    my @conf = readdir(D);
    closedir D;
    @conf =
      sort { $a <=> $b }
      map { /lmConf-(\d+)\.yaml/ ? ( $1 + 0 ) : () } @conf;
    return @conf;
}

sub lastCfg {
    my $self  = shift;
    my @avail = $self->available;
    return $avail[$#avail];
}

sub lock {
    my $self = shift;
    if ( $self->isLocked ) {
        sleep 2;
        return 0 if ( $self->isLocked );
    }
    unless ( open F, ">" . $self->_yamlLock ) {
        $Lemonldap::NG::Common::Conf::msg .=
          "Unable to lock (" . $self->_yamlLock . ") \n";
        return 0;
    }
    print F $$;
    close F;
    return 1;
}

sub isLocked {
    my $self = shift;
    -e $self->_yamlLock;
}

sub unlock {
    my $self = shift;
    unlink $self->_yamlLock;
    1;
}

sub store {
    my ( $self, $fields ) = @_;
    my $mask = umask;
    umask( oct('0027') );
    unless ( open FILE, '>', $self->_yamlFile( $fields->{cfgNum} ) ) {
        $Lemonldap::NG::Common::Conf::msg = "Open file failed: $! \n";
        $self->unlock;
        return UNKNOWN_ERROR;
    }
    binmode(FILE);
    my $f = YAML::Dump($fields);
    print FILE $f;
    close FILE;
    umask($mask);
    return $fields->{cfgNum};
}

sub load {
    my ( $self, $cfgNum, $fields ) = @_;
    my ( $f, $filename );
    $filename = $self->_yamlFile($cfgNum);
    local $/ = '';
    my $ret;
    unless ( open FILE, '<', $filename ) {
        $Lemonldap::NG::Common::Conf::msg .= "Read error: $!$@";
        return undef;
    }
    binmode FILE;
    $f = join( '', <FILE> );
    eval { $ret = YAML::Load($f) };
    if ($@) {
        print STDERR "$@\n";
        $Lemonldap::NG::Common::Conf::msg .= "YAML fails to read file: $@ \n";
        return undef;
    }
    foreach ( keys %$ret ) {
        if ( $_ =~ $boolKeys ) {
            $ret->{$_} = $ret->{$_} ? 1 : 0;
        }
    }
    return $ret;
}

sub delete {
    my ( $self, $cfgNum ) = @_;
    my $file = $self->_yamlFile($cfgNum);
    if ( -e $file ) {
        my $res = unlink($file);
        $Lemonldap::NG::Common::Conf::msg .= $! unless ($res);
        return $res;
    }
    else {
        $Lemonldap::NG::Common::Conf::msg .=
          "Unable to delete conf $cfgNum, no such file";
        return 0;
    }
}

1;
__END__
