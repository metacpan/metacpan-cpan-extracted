package Lemonldap::NG::Common::Conf::Backends::File;

use strict;
use Lemonldap::NG::Common::Conf::Constants;    #inherits
use JSON;
use Encode;

our $VERSION = '2.0.9';
our $initDone;

sub Lemonldap::NG::Common::Conf::_lock {
    my ( $self, $cfgNum ) = @_;
    return "$self->{dirName}/lmConf.lock";
}

sub Lemonldap::NG::Common::Conf::_file {
    my ( $self, $cfgNum ) = @_;
    return "$self->{dirName}/lmConf-$cfgNum.json";
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
      map { /^lmConf-(\d+)(?:\.js(?:on))?$/ ? ( $1 + 0 ) : () } @conf;
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
    unless ( open F, ">" . $self->_lock ) {
        $Lemonldap::NG::Common::Conf::msg .=
          "Unable to lock (" . $self->_lock . ") \n";
        return 0;
    }
    print F $$;
    close F;
    return 1;
}

sub isLocked {
    my $self = shift;
    -e $self->_lock;
}

sub unlock {
    my $self = shift;
    unlink $self->_lock;
    1;
}

sub store {
    my ( $self, $fields ) = @_;
    my $mask = umask;
    umask( oct('0027') );
    unless ( open FILE, '>', $self->_file( $fields->{cfgNum} ) ) {
        $Lemonldap::NG::Common::Conf::msg = "Open file failed: $! \n";
        $self->unlock;
        return UNKNOWN_ERROR;
    }
    binmode(FILE);
    my $json_options = {
        allow_nonref => 1,
        (
            $self->{prettyPrint}
            ? (
                pretty    => 1,
                canonical => 1
              )
            : ()
        )
    };
    my $f = to_json( $fields, $json_options );
    print FILE $f;
    close FILE;
    umask($mask);
    return $fields->{cfgNum};
}

sub load {
    my ( $self, $cfgNum, $fields ) = @_;
    my ( $f, $filename );
    if ( -e $self->_file($cfgNum) ) {
        $filename = $self->_file($cfgNum);
    }
    elsif ( -e "$self->{dirName}/lmConf-$cfgNum.js" ) {
        $filename = "$self->{dirName}/lmConf-$cfgNum.js";
    }
    if ($filename) {
        local $/ = '';
        my $ret;
        unless ( open FILE, '<', $filename ) {
            $Lemonldap::NG::Common::Conf::msg .= "Read error: $!$@";
            return undef;
        }
        binmode FILE;
        $f = join( '', <FILE> );
        eval { $ret = from_json( $f, { allow_nonref => 1 } ) };
        if ($@) {
            print STDERR "$@\n";
            $Lemonldap::NG::Common::Conf::msg .=
              "JSON fails to read file: $@ \n";
            return undef;
        }
        return $ret;
    }

    # Old format
    elsif ( -e "$self->{dirName}/lmConf-$cfgNum" ) {
        open FILE, '<', "$self->{dirName}/lmConf-$cfgNum" or die "$!$@";
        local $/ = "";
        unless ( open FILE, '<', $self->{dirName} . "/lmConf-$cfgNum" ) {
            $Lemonldap::NG::Common::Conf::msg .= "Open file failed: $! \n";
            return undef;
        }
        while (<FILE>) {
            my ( $k, $v ) = split /\n\s+/;
            chomp $k;
            $v =~ s/\n*$//;
            if ($fields) {
                $f->{$k} = $v if ( grep { $_ eq $k } @$fields );
            }
            else {
                $f->{$k} = $v;
            }
        }
        close FILE;
        require Lemonldap::NG::Common::Conf::Serializer;
        return $self->unserialize($f);
    }
    else {
        $Lemonldap::NG::Common::Conf::msg .=
          "Unable to find configuration file";
        return undef;
    }
}

sub delete {
    my ( $self, $cfgNum ) = @_;
    my $file = $self->_file($cfgNum);
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
