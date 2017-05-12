package IniConf;

use strict;
use Config::IniFiles;

use vars       qw($VERSION @ISA);
$VERSION = '1.03';
@ISA         = qw(Config::IniFiles);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = new Config::IniFiles( @_ );
    return undef unless defined $self;

    bless ($self, $class);
    return $self;
}
1;
