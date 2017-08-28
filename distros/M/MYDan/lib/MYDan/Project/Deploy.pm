package MYDan::Project::Deploy;

use strict;
use warnings;

$|++;

use MYDan::Util::OptConf;
my ( %o, %api ); 
BEGIN{ 
    %o = MYDan::Util::OptConf->load()->dump('project');
    %api = MYDan::Util::OptConf->load()->dump('api');
};

sub new
{
    my ( $class, %self ) =  @_;

    die "name undef" unless $self{name};
    bless \%self, ref $class || $class;
}

sub conf
{
    my $this = shift;

    my $conf = eval{ YAML::XS::LoadFile "$o{deploy}/$this->{name}" };
    die "load conf: $@" if $@;
    $conf->{repo} ||= "$api{addr}/download/package/$this->{name}";
    $conf->{version} = shift;

    return $conf;
}

1;
